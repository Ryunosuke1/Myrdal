# @version ^0.3.3
# @title MCP Integration Contract
# @notice Contract for integrating with Model Context Protocol
# @dev Implements the IMCPIntegration interface

import interfaces.IMCPIntegration as IMCPIntegration
import interfaces.IUserAuth as IUserAuth

# MCP Action Types
MCP_ACTION_FIREFOX: constant(uint8) = 1
MCP_ACTION_PYPPETEER: constant(uint8) = 2
MCP_ACTION_OTHER: constant(uint8) = 3

# Events
event MCPRequestSent:
    request_id: bytes32
    requester: address
    action_type: uint8
    action_data: String[1024]
    timestamp: uint256

event MCPRequestFulfilled:
    request_id: bytes32
    result: String[1024]
    timestamp: uint256

event MCPRequestCancelled:
    request_id: bytes32
    timestamp: uint256

# State variables
owner: public(address)
user_auth: public(address)
mcp_oracle_address: public(address)  # Address authorized to fulfill requests

# MCP Server registry
mcp_servers: public(HashMap[uint256, address])
mcp_server_count: public(uint256)

# Request storage
requests: public(HashMap[bytes32, IMCPIntegration.MCPRequest])
request_ids: public(DynArray[bytes32, 1000])

@external
def __init__(_user_auth: address, _mcp_oracle_address: address):
    """
    @notice Initialize the MCP Integration contract
    @param _user_auth Address of the User Authentication contract
    @param _mcp_oracle_address Address authorized to fulfill MCP requests
    """
    self.owner = msg.sender
    self.user_auth = _user_auth
    self.mcp_oracle_address = _mcp_oracle_address
    self.mcp_server_count = 0

@external
def request_firefox_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:
    """
    @notice Request a Firefox browser action
    @param action_data The action data (JSON format)
    @param callback_address The address to call when the result is ready
    @param callback_function_selector The function selector to call
    @return request_id The ID of the MCP request
    """
    # Check if user is active
    user_auth: IUserAuth.IUserAuth = IUserAuth.IUserAuth(self.user_auth)
    assert user_auth.is_user_active(msg.sender), "User not active"
    
    # Generate request ID
    request_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(len(self.request_ids), bytes32),
        convert(msg.sender, bytes32),
        convert(MCP_ACTION_FIREFOX, bytes32)
    ))
    
    # Create request
    request: IMCPIntegration.MCPRequest = IMCPIntegration.MCPRequest({
        id: request_id,
        requester: msg.sender,
        action_type: MCP_ACTION_FIREFOX,
        action_data: action_data,
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
    log MCPRequestSent(request_id, msg.sender, MCP_ACTION_FIREFOX, action_data, block.timestamp)
    
    # In a real implementation, we would emit an event that an off-chain MCP oracle would listen for
    # The oracle would then call the fulfill_request function with the result
    
    return request_id

@external
def request_pyppeteer_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:
    """
    @notice Request a pyppeteer action
    @param action_data The action data (JSON format)
    @param callback_address The address to call when the result is ready
    @param callback_function_selector The function selector to call
    @return request_id The ID of the MCP request
    """
    # Check if user is active
    user_auth: IUserAuth.IUserAuth = IUserAuth.IUserAuth(self.user_auth)
    assert user_auth.is_user_active(msg.sender), "User not active"
    
    # Generate request ID
    request_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(len(self.request_ids), bytes32),
        convert(msg.sender, bytes32),
        convert(MCP_ACTION_PYPPETEER, bytes32)
    ))
    
    # Create request
    request: IMCPIntegration.MCPRequest = IMCPIntegration.MCPRequest({
        id: request_id,
        requester: msg.sender,
        action_type: MCP_ACTION_PYPPETEER,
        action_data: action_data,
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
    log MCPRequestSent(request_id, msg.sender, MCP_ACTION_PYPPETEER, action_data, block.timestamp)
    
    return request_id

@external
def request_mcp_action(server_id: uint256, action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:
    """
    @notice Request an action from another MCP server
    @param server_id The ID of the MCP server
    @param action_data The action data (JSON format)
    @param callback_address The address to call when the result is ready
    @param callback_function_selector The function selector to call
    @return request_id The ID of the MCP request
    """
    # Check if user is active
    user_auth: IUserAuth.IUserAuth = IUserAuth.IUserAuth(self.user_auth)
    assert user_auth.is_user_active(msg.sender), "User not active"
    
    # Check if server exists
    assert server_id < self.mcp_server_count, "Server not found"
    
    # Generate request ID
    request_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(len(self.request_ids), bytes32),
        convert(msg.sender, bytes32),
        convert(MCP_ACTION_OTHER, bytes32),
        convert(server_id, bytes32)
    ))
    
    # Create request
    request: IMCPIntegration.MCPRequest = IMCPIntegration.MCPRequest({
        id: request_id,
        requester: msg.sender,
        action_type: MCP_ACTION_OTHER,
        action_data: action_data,
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
    log MCPRequestSent(request_id, msg.sender, MCP_ACTION_OTHER, action_data, block.timestamp)
    
    return request_id

@external
@view
def is_request_fulfilled(request_id: bytes32) -> bool:
    """
    @notice Check if an MCP request has been fulfilled
    @param request_id The ID of the request to check
    @return fulfilled Whether the request has been fulfilled
    """
    assert request_id in self.request_ids, "Request not found"
    return self.requests[request_id].fulfilled

@external
@view
def get_request_result(request_id: bytes32) -> String[1024]:
    """
    @notice Get the result of a fulfilled MCP request
    @param request_id The ID of the request
    @return result The result of the MCP request
    """
    assert request_id in self.request_ids, "Request not found"
    request: IMCPIntegration.MCPRequest = self.requests[request_id]
    assert request.fulfilled, "Request not fulfilled"
    
    # Only requester or owner can get result
    assert request.requester == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return request.result

@external
def fulfill_request(request_id: bytes32, result: String[1024]):
    """
    @notice Fulfill an MCP request (called by the MCP oracle)
    @param request_id The ID of the request to fulfill
    @param result The result data
    """
    # Only authorized MCP oracle can fulfill requests
    assert msg.sender == self.mcp_oracle_address or msg.sender == self.owner, "Not authorized oracle"
    
    # Check if request exists and is not fulfilled
    assert request_id in self.request_ids, "Request not found"
    request: IMCPIntegration.MCPRequest = self.requests[request_id]
    assert not request.fulfilled, "Request already fulfilled"
    
    # Update request
    request.fulfilled = True
    request.result = result
    self.requests[request_id] = request
    
    # Emit event
    log MCPRequestFulfilled(request_id, result, block.timestamp)
    
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
    @notice Cancel an MCP request
    @param request_id The ID of the request to cancel
    """
    # Check if request exists and is not fulfilled
    assert request_id in self.request_ids, "Request not found"
    request: IMCPIntegration.MCPRequest = self.requests[request_id]
    assert not request.fulfilled, "Request already fulfilled"
    
    # Only requester or owner can cancel
    assert request.requester == msg.sender or msg.sender == self.owner, "Not authorized"
    
    # Mark as fulfilled but with empty result
    request.fulfilled = True
    request.result = ""
    self.requests[request_id] = request
    
    # Emit event
    log MCPRequestCancelled(request_id, block.timestamp)

@external
def register_mcp_server(server_address: address) -> uint256:
    """
    @notice Register a new MCP server
    @param server_address The address of the MCP server
    @return server_id The ID of the registered server
    """
    assert msg.sender == self.owner, "Only owner can register servers"
    
    server_id: uint256 = self.mcp_server_count
    self.mcp_servers[server_id] = server_address
    self.mcp_server_count += 1
    
    return server_id

@external
def update_mcp_oracle_address(new_oracle_address: address):
    """
    @notice Update the authorized MCP oracle address
    @param new_oracle_address The new MCP oracle address
    """
    assert msg.sender == self.owner, "Only owner can update oracle address"
    self.mcp_oracle_address = new_oracle_address
