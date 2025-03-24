# @version ^0.3.3
# @title MCP Integration Interface
# @notice Interface for the Model Context Protocol integration contract

struct MCPRequest:
    id: bytes32
    requester: address
    action_type: uint8  # 1: Firefox, 2: pyppeteer, 3: other MCP
    action_data: String[1024]
    callback_address: address
    callback_function_selector: bytes4
    timestamp: uint256
    fulfilled: bool
    result: String[1024]

interface IMCPIntegration:
    # @notice Request a Firefox browser action
    # @param action_data The action data (JSON format)
    # @param callback_address The address to call when the result is ready
    # @param callback_function_selector The function selector to call
    # @return request_id The ID of the MCP request
    def request_firefox_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32: nonpayable
    
    # @notice Request a pyppeteer action
    # @param action_data The action data (JSON format)
    # @param callback_address The address to call when the result is ready
    # @param callback_function_selector The function selector to call
    # @return request_id The ID of the MCP request
    def request_pyppeteer_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32: nonpayable
    
    # @notice Request an action from another MCP server
    # @param server_id The ID of the MCP server
    # @param action_data The action data (JSON format)
    # @param callback_address The address to call when the result is ready
    # @param callback_function_selector The function selector to call
    # @return request_id The ID of the MCP request
    def request_mcp_action(server_id: uint256, action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32: nonpayable
    
    # @notice Check if an MCP request has been fulfilled
    # @param request_id The ID of the request to check
    # @return fulfilled Whether the request has been fulfilled
    def is_request_fulfilled(request_id: bytes32) -> bool: view
    
    # @notice Get the result of a fulfilled MCP request
    # @param request_id The ID of the request
    # @return result The result of the MCP request
    def get_request_result(request_id: bytes32) -> String[1024]: view
    
    # @notice Fulfill an MCP request (called by the MCP oracle)
    # @param request_id The ID of the request to fulfill
    # @param result The result data
    def fulfill_request(request_id: bytes32, result: String[1024]): nonpayable
    
    # @notice Cancel an MCP request
    # @param request_id The ID of the request to cancel
    def cancel_request(request_id: bytes32): nonpayable
