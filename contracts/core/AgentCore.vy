# @version ^0.4.1
# @title Agent Core Contract
# @notice Core contract for the Oasis Protocol AI Agent
# @dev Implements the IAgentCore interface

from interfaces import ERC20

# Import interfaces
# インポートパスを修正
# カスタムインターフェースのインポート
# IAgentCoreインターフェースを直接定義
# インポートパスを修正
# カスタムインターフェースのインポート
# IMemoryStorageインターフェースを直接定義
# インポートパスを修正
# カスタムインターフェースのインポート
# IOracleInterfaceインターフェースを直接定義
# インポートパスを修正
# カスタムインターフェースのインポート
# IMCPIntegrationインターフェースを直接定義
# インポートパスを修正
# カスタムインターフェースのインポート
# IUserAuthインターフェースを直接定義

# Task status constants
TASK_STATUS_PENDING: constant(uint8) = 1
TASK_STATUS_PROCESSING: constant(uint8) = 2
TASK_STATUS_COMPLETED: constant(uint8) = 3
TASK_STATUS_FAILED: constant(uint8) = 4

# Events
event TaskCreated:
    task_id: bytes32
    owner: address
    prompt: String[1024]
    timestamp: uint256


event TaskStatusUpdated:
    task_id: bytes32
    status: uint8
    timestamp: uint256


event TaskCompleted:
    task_id: bytes32
    result: String[1024]
    timestamp: uint256


# State variables
owner: public(address)
memory_storage: public(address)
oracle_interface: public(address)
mcp_integration: public(address)
user_auth: public(address)

# Task storage
tasks: public(HashMap[IAgentCore, TaskInfo])
user_tasks: public(HashMap[address, DynArray[bytes32, 100]])
task_ids: public(DynArray[bytes32, 1000])

# Callback function selectors
process_llm_callback_selector: public(bytes4)
process_mcp_callback_selector: public(bytes4)

@deploy
def __init__(
_memory_storage: address,
_oracle_interface: address,
_mcp_integration: address,
_user_auth: address
):
"""
@notice Initialize the Agent Core contract
@param _memory_storage Address of the Memory Storage contract
@param _oracle_interface Address of the Oracle Interface contract
@param _mcp_integration Address of the MCP Integration contract
@param _user_auth Address of the User Authentication contract
"""
owner = sender
memory_storage = _memory_storage
oracle_interface = _oracle_interface
mcp_integration = _mcp_integration
user_auth = _user_auth

# Set callback function selectors
process_llm_callback_selector = method_id("process_llm_callback(bytes32,String[1024])")
process_mcp_callback_selector = method_id("process_mcp_callback(bytes32,String[1024])")

@external
def create_task(prompt: String[1024]) -> bytes32:
    """
@notice Create a new task for the agent to process
@param prompt The user's prompt or request
@return task_id The ID of the created task
"""
# Check if user is active
user_auth: IUserAuth
user_auth = IUserAuth(user_auth)
assert is_user_active(sender), "User not active"

# Generate task ID
task_id: bytes32

task_id = keccak256(concat(
convert(timestamp, bytes32),
convert(len(task_ids), bytes32),
convert(sender, bytes32)
))

# Create task
task: TaskInfo

task = TaskInfo(id=task_id, owner=sender, prompt=prompt, status=TASK_STATUS_PENDING, created_at=timestamp, completed_at=0, result="")

# Store task
tasks[task_id] = task
task_ids.append(task_id)
user_tasks[sender].append(task_id)

# Store prompt in memory
memory_storage: IMemoryStorage

memory_storage = IMemoryStorage(memory_storage)
tags: DynArray[String[32], 10] = []
append("prompt")
store_memory(prompt, 2, tags, True)

# Emit event
log TaskCreated(task_id, sender, prompt, timestamp)

return task_id

@external
def get_task(task_id: bytes32) -> TaskInfo:
    """
@notice Get the status of a task
@param task_id The ID of the task
@return TaskInfo The task information
"""
assert task_id in task_ids, "Task not found"
task: TaskInfo
task = tasks[task_id]
assert owner == sender or sender == owner, "Not authorized"

return task

@external
def process_task(task_id: bytes32) -> bool:
    """
@notice Process a task (move it forward in execution)
@param task_id The ID of the task to process
@return completed Whether the task is now completed
"""
assert task_id in task_ids, "Task not found"
task: TaskInfo
task = tasks[task_id]
assert owner == sender or sender == owner, "Not authorized"
assert status == TASK_STATUS_PENDING or status == TASK_STATUS_PROCESSING, "Task not processable"

# Update task status to processing
if status == TASK_STATUS_PENDING:
    status = TASK_STATUS_PROCESSING
tasks[task_id] = task
log TaskStatusUpdated(task_id, TASK_STATUS_PROCESSING, timestamp)

# If task is in processing state, send to LLM
if status == TASK_STATUS_PROCESSING:
    oracle: IOracleInterface

    oracle = IOracleInterface(oracle_interface)

# Request LLM completion
request_llm_completion(
prompt,
self,
process_llm_callback_selector
)

return False

return status == TASK_STATUS_COMPLETED

@external
def process_llm_callback(request_id: bytes32, result: String[1024]):
    """
    @notice Callback function for LLM completion
    @param request_id The oracle request ID
    @param result The LLM result
    """
    # Only oracle can call this
    assert sender == oracle_interface, "Only oracle can call"
    
    # Find the task associated with this request
    # In a real implementation, we would store a mapping from request_id to task_id
    # For simplicity, we'll assume the request_id is the task_id
    task_id: bytes32
    task_id = request_id
    
    # Check if task exists
    assert task_id in task_ids, "Task not found"
    task: TaskInfo
    task = tasks[task_id]
    
    # Process the LLM result
    # Check if we need to call MCP for browser actions
    if "BROWSER_ACTION:" in result:
        # Extract browser action data
        action_data: String[1024]
        action_data = result
        
        # Request MCP action
        mcp: IMCPIntegration
        mcp = IMCPIntegration(mcp_integration)
        request_firefox_action(
            action_data,
            self,
            process_mcp_callback_selector
        )
    else:
        # No browser action needed, complete the task
        _complete_task(task_id, result)

@external
def process_mcp_callback(request_id: bytes32, result: String[1024]):
    """
    @notice Callback function for MCP actions
    @param request_id The MCP request ID
    @param result The MCP result
    """
    # Only MCP integration can call this
    assert sender == mcp_integration, "Only MCP can call"
    
    # Find the task associated with this request
    # In a real implementation, we would store a mapping from request_id to task_id
    # For simplicity, we'll assume the request_id is the task_id
    task_id: bytes32
    task_id = request_id
    
    # Check if task exists
    assert task_id in task_ids, "Task not found"
    
    # Complete the task with the MCP result
    _complete_task(task_id, result)

@internal
def _complete_task(task_id: bytes32, result: String[1024]):
    """
    @notice Internal function to complete a task
    @param task_id The ID of the task
    @param result The result of the task
    """
    task: TaskInfo
    task = tasks[task_id]
    
    # Update task
    status = TASK_STATUS_COMPLETED
    completed_at = timestamp
    result = result
    tasks[task_id] = task
    
    # Store result in memory
    memory_storage: IMemoryStorage
    memory_storage = IMemoryStorage(memory_storage)
    tags: DynArray[String[32], 10]
    tags = []
    append("result")
    store_memory(result, 2, tags, True)
    
    # Emit event
    log TaskCompleted(task_id, result, timestamp)

@external
def get_task_result(task_id: bytes32) -> String[1024]:
    """
@notice Get the result of a completed task
@param task_id The ID of the task
@return result The result of the task
"""
assert task_id in task_ids, "Task not found"
task: TaskInfo
task = tasks[task_id]
assert owner == sender or sender == owner, "Not authorized"
assert status == TASK_STATUS_COMPLETED, "Task not completed"

return result

@external
def get_user_tasks(user: address) -> DynArray[bytes32, 100]:
    """
@notice Get all tasks for a user
@param user The address of the user
@return task_ids Array of task IDs
"""
assert user == sender or sender == owner, "Not authorized"

return user_tasks[user]
