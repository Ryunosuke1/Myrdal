# @version ^0.4.1
# @title Oracle Interface Contract
# @notice Contract for connecting to external LLM services and data sources
# @dev Implements the IOracleInterface interface

# インポートパスを修正
# カスタムインターフェースのインポート
# IOracleInterfaceインターフェースを直接定義
# インポートパスを修正
# カスタムインターフェースのインポート
# IUserAuthインターフェースを直接定義

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


# オラクルリクエストの構造体
struct OracleRequest:
    id: bytes32
    owner: address
    task_id: bytes32
    query: String[1024]
    status: uint8
    created_at: uint256
    completed_at: uint256
    result: String[1024]


# Request storage
requests: public(HashMap[bytes32, OracleRequest])
request_ids: public(DynArray[bytes32, 1000])

@deploy
def __init__(_user_auth: address, _oracle_address: address):
    """
    @notice Initialize the Oracle Interface contract
    @param _user_auth Address of the User Authentication contract
    @param _oracle_address Address authorized to fulfill oracle requests
    """
    owner = sender
    user_auth = _user_auth
    oracle_address = _oracle_address

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
user_auth_contract: address
# user_auth_contract already contains the address
if not is_user_active(sender):
        raise "User not active"

# Generate request ID
request_id: bytes32
request_id = keccak256(concat(
convert(timestamp, bytes32),
convert(len(request_ids), bytes32),
convert(sender, bytes32)
))

# Create request
request: OracleRequest

request = OracleRequest(id=request_id, requester=sender, data=prompt, callback_address=callback_address, callback_function_selector=callback_function_selector, timestamp=timestamp, fulfilled=False, result="")

# Store request
requests[request_id] = request
request_ids.append(request_id)

# Emit event
log OracleRequestSent(request_id, sender, prompt, timestamp)

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
assert request_id in request_ids, "Request not found"
return requests[request_id].fulfilled

@external
@view
def get_request_result(request_id: bytes32) -> String[1024]:
    """
@notice Get the result of a fulfilled oracle request
@param request_id The ID of the request
@return result The result of the oracle request
"""
assert request_id in request_ids, "Request not found"
req: OracleRequest
req = requests[request_id]
assert fulfilled, "Request not fulfilled"

# Only requester or owner can get result
assert requester == sender or sender == owner, "Not authorized"

return result

@external
def fulfill_request(request_id: bytes32, result: String[1024]):
    """
    @notice Fulfill an oracle request (called by the oracle)
    @param request_id The ID of the request to fulfill
    @param result The result data
    """
    # Only authorized oracle can fulfill requests
    assert sender == oracle_address or sender == owner, "Not authorized oracle"
    
    # Check if request exists and is not fulfilled
    assert request_id in request_ids, "Request not found"
    request: OracleRequest
    request = requests[request_id]
    assert not fulfilled, "Request already fulfilled"
    
    # Update request
    fulfilled = True
    result = result
    requests[request_id] = request
    
    # Emit event
    log OracleRequestFulfilled(request_id, result, timestamp)
    
    # Call callback function
    raw_call(
        callback_address,
        concat(
            callback_function_selector,
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
    assert request_id in request_ids, "Request not found"
    request: OracleRequest
    request = requests[request_id]
    assert not fulfilled, "Request already fulfilled"
    
    # Only requester or owner can cancel
    assert requester == sender or sender == owner, "Not authorized"
    
    # Mark as fulfilled but with empty result
    fulfilled = True
    result = ""
    requests[request_id] = request
    
    # Emit event
    log OracleRequestCancelled(request_id, timestamp)

@external
def update_oracle_address(new_oracle_address: address):
    """
    @notice Update the authorized oracle address
    @param new_oracle_address The new oracle address
    """
    assert sender == owner, "Only owner can update oracle address"
    oracle_address = new_oracle_address
