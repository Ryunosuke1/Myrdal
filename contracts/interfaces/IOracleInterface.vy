# @version ^0.4.1
# @title Oracle Interface Contract
# @notice Interface for the Oracle contract that connects to external services

struct OracleRequest:
    id: bytes32
    requester: address
    data: String[1024]
    callback_address: address
    callback_function_selector: bytes4
    timestamp: uint256
    fulfilled: bool
    result: String[1024]


# インポートパスを修正
# カスタムインターフェースのインポート
# IIOracleInterfaceインターフェースを直接定義
# @notice Request data from an external LLM service
# @param prompt The prompt to send to the LLM
# @param callback_address The address to call when the result is ready
# @param callback_function_selector The function selector to call
# @return request_id The ID of the oracle request
def request_llm_completion(prompt: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32: nonpayable

# @notice Check if an oracle request has been fulfilled
# @param request_id The ID of the request to check
# @return fulfilled Whether the request has been fulfilled
def is_request_fulfilled(request_id: bytes32) -> bool: view

# @notice Get the result of a fulfilled oracle request
# @param request_id The ID of the request
# @return result The result of the oracle request
def get_request_result(request_id: bytes32) -> String[1024]: view

# @notice Fulfill an oracle request (called by the oracle)
# @param request_id The ID of the request to fulfill
# @param result The result data
    def fulfill_request(request_id: bytes32, result: String[1024]): nonpayable
    
    # @notice Cancel an oracle request
    # @param request_id The ID of the request to cancel
    def cancel_request(request_id: bytes32): nonpayable
    pass
