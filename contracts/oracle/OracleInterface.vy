# @version ^0.3.3
# @title Oracle Interface Contract
# @notice Contract for connecting to external LLM services and data sources
# @dev Implements the IOracleInterface interface

import interfaces.IOracleInterface as IOracleInterface
import interfaces.IUserAuth as IUserAuth

# Events
event OracleRequestSent:
    request_id: bytes32
    requester: address
    data: String[1024]
    timestamp: uint256

event OracleRequestFulfilled:
    request_id: bytes32
    result: String[1024]
    timestamp: uint256

event OracleRequestCancelled:
    request_id: bytes32
    timestamp: uint256

# State variables
owner: public(address)
user_auth: public(address)
oracle_address: public(address)  # Address authorized to fulfill requests

# Request storage
requests: public(HashMap[bytes32, IOracleInterface.OracleRequest])
request_ids: public(DynArray[bytes32, 1000])

@external
def __init__(_user_auth: address, _oracle_address: address):
    """
    @notice Initialize the Oracle Interface contract
    @param _user_auth Address of the User Authentication contract
    @param _oracle_address Address authorized to fulfill oracle requests
    """
    self.owner = msg.sender
    self.user_auth = _user_auth
    self.oracle_address = _oracle_address

@external
def request_llm_completion(prompt: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:
    """
    @notice Request data from an external LLM service
    @param prompt The prompt to send to the LLM
    @param callback_address The address to call when the result is ready
    @param callback_function_selector The function selector to call
    @return request_id The ID of the oracle request
    """
    # Check if user is active
    user_auth: IUserAuth.IUserAuth = IUserAuth.IUserAuth(self.user_auth)
    assert user_auth.is_user_active(msg.sender), "User not active"
    
    # Generate request ID
    request_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(len(self.request_ids), bytes32),
        convert(msg.sender, bytes32)
    ))
    
    # Create request
    request: IOracleInterface.OracleRequest = IOracleInterface.OracleRequest({
        id: request_id,
        requester: msg.sender,
        data: prompt,
        callback_address: callback_address,
        callback_function_selector: callback_function_selector,
        timestamp: block.timestamp,
        fulfilled: False,
        result: ""
    })
    
    # Store request
    self.requests[request_id] = request
    self.request_ids.append(request_id)
    
    # Emit event
    log OracleRequestSent(request_id, msg.sender, prompt, block.timestamp)
    
    # In a real implementation, we would emit an event that an off-chain oracle would listen for
    # The oracle would then call the fulfill_request function with the result
    
    return request_id

@external
@view
def is_request_fulfilled(request_id: bytes32) -> bool:
    """
    @notice Check if an oracle request has been fulfilled
    @param request_id The ID of the request to check
    @return fulfilled Whether the request has been fulfilled
    """
    assert request_id in self.request_ids, "Request not found"
    return self.requests[request_id].fulfilled

@external
@view
def get_request_result(request_id: bytes32) -> String[1024]:
    """
    @notice Get the result of a fulfilled oracle request
    @param request_id The ID of the request
    @return result The result of the oracle request
    """
    assert request_id in self.request_ids, "Request not found"
    request: IOracleInterface.OracleRequest = self.requests[request_id]
    assert request.fulfilled, "Request not fulfilled"
    
    # Only requester or owner can get result
    assert request.requester == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return request.result

@external
def fulfill_request(request_id: bytes32, result: String[1024]):
    """
    @notice Fulfill an oracle request (called by the oracle)
    @param request_id The ID of the request to fulfill
    @param result The result data
    """
    # Only authorized oracle can fulfill requests
    assert msg.sender == self.oracle_address or msg.sender == self.owner, "Not authorized oracle"
    
    # Check if request exists and is not fulfilled
    assert request_id in self.request_ids, "Request not found"
    request: IOracleInterface.OracleRequest = self.requests[request_id]
    assert not request.fulfilled, "Request already fulfilled"
    
    # Update request
    request.fulfilled = True
    request.result = result
    self.requests[request_id] = request
    
    # Emit event
    log OracleRequestFulfilled(request_id, result, block.timestamp)
    
    # Call callback function
    raw_call(
        request.callback_address,
        concat(
            request.callback_function_selector,
            convert(request_id, bytes32),
            convert(len(result), bytes32),
            convert(result, bytes32)
        )
    )

@external
def cancel_request(request_id: bytes32):
    """
    @notice Cancel an oracle request
    @param request_id The ID of the request to cancel
    """
    # Check if request exists and is not fulfilled
    assert request_id in self.request_ids, "Request not found"
    request: IOracleInterface.OracleRequest = self.requests[request_id]
    assert not request.fulfilled, "Request already fulfilled"
    
    # Only requester or owner can cancel
    assert request.requester == msg.sender or msg.sender == self.owner, "Not authorized"
    
    # Mark as fulfilled but with empty result
    request.fulfilled = True
    request.result = ""
    self.requests[request_id] = request
    
    # Emit event
    log OracleRequestCancelled(request_id, block.timestamp)

@external
def update_oracle_address(new_oracle_address: address):
    """
    @notice Update the authorized oracle address
    @param new_oracle_address The new oracle address
    """
    assert msg.sender == self.owner, "Only owner can update oracle address"
    self.oracle_address = new_oracle_address
