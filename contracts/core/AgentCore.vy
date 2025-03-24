# @version ^0.3.3
# @title Agent Core Contract
# @notice Core contract for the Oasis Protocol AI Agent
# @dev Implements the IAgentCore interface

from vyper.interfaces import ERC20

# Import interfaces
import interfaces.IAgentCore as IAgentCore
import interfaces.IMemoryStorage as IMemoryStorage
import interfaces.IOracleInterface as IOracleInterface
import interfaces.IMCPIntegration as IMCPIntegration
import interfaces.IUserAuth as IUserAuth

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
tasks: public(HashMap[bytes32, IAgentCore.TaskInfo])
user_tasks: public(HashMap[address, DynArray[bytes32, 100]])
task_ids: public(DynArray[bytes32, 1000])

# Callback function selectors
process_llm_callback_selector: public(bytes4)
process_mcp_callback_selector: public(bytes4)

@external
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
    self.owner = msg.sender
    self.memory_storage = _memory_storage
    self.oracle_interface = _oracle_interface
    self.mcp_integration = _mcp_integration
    self.user_auth = _user_auth
    
    # Set callback function selectors
    self.process_llm_callback_selector = method_id("process_llm_callback(bytes32,String[1024])")
    self.process_mcp_callback_selector = method_id("process_mcp_callback(bytes32,String[1024])")

@external
def create_task(prompt: String[1024]) -> bytes32:
    """
    @notice Create a new task for the agent to process
    @param prompt The user's prompt or request
    @return task_id The ID of the created task
    """
    # Check if user is active
    user_auth: IUserAuth.IUserAuth = IUserAuth.IUserAuth(self.user_auth)
    assert user_auth.is_user_active(msg.sender), "User not active"
    
    # Generate task ID
    task_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(len(self.task_ids), bytes32),
        convert(msg.sender, bytes32)
    ))
    
    # Create task
    task: IAgentCore.TaskInfo = IAgentCore.TaskInfo({
        id: task_id,
        owner: msg.sender,
        prompt: prompt,
        status: TASK_STATUS_PENDING,
        created_at: block.timestamp,
        completed_at: 0,
        result: ""
    })
    
    # Store task
    self.tasks[task_id] = task
    self.task_ids.append(task_id)
    self.user_tasks[msg.sender].append(task_id)
    
    # Store prompt in memory
    memory_storage: IMemoryStorage.IMemoryStorage = IMemoryStorage.IMemoryStorage(self.memory_storage)
    tags: DynArray[String[32], 10] = []
    tags.append("prompt")
    memory_storage.store_memory(prompt, 2, tags, True)
    
    # Emit event
    log TaskCreated(task_id, msg.sender, prompt, block.timestamp)
    
    return task_id

@external
def get_task(task_id: bytes32) -> IAgentCore.TaskInfo:
    """
    @notice Get the status of a task
    @param task_id The ID of the task
    @return TaskInfo The task information
    """
    assert task_id in self.task_ids, "Task not found"
    task: IAgentCore.TaskInfo = self.tasks[task_id]
    assert task.owner == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return task

@external
def process_task(task_id: bytes32) -> bool:
    """
    @notice Process a task (move it forward in execution)
    @param task_id The ID of the task to process
    @return completed Whether the task is now completed
    """
    assert task_id in self.task_ids, "Task not found"
    task: IAgentCore.TaskInfo = self.tasks[task_id]
    assert task.owner == msg.sender or msg.sender == self.owner, "Not authorized"
    assert task.status == TASK_STATUS_PENDING or task.status == TASK_STATUS_PROCESSING, "Task not processable"
    
    # Update task status to processing
    if task.status == TASK_STATUS_PENDING:
        task.status = TASK_STATUS_PROCESSING
        self.tasks[task_id] = task
        log TaskStatusUpdated(task_id, TASK_STATUS_PROCESSING, block.timestamp)
    
    # If task is in processing state, send to LLM
    if task.status == TASK_STATUS_PROCESSING:
        oracle: IOracleInterface.IOracleInterface = IOracleInterface.IOracleInterface(self.oracle_interface)
        
        # Request LLM completion
        oracle.request_llm_completion(
            task.prompt,
            self,
            self.process_llm_callback_selector
        )
        
        return False
    
    return task.status == TASK_STATUS_COMPLETED

@external
def process_llm_callback(request_id: bytes32, result: String[1024]):
    """
    @notice Callback function for LLM completion
    @param request_id The oracle request ID
    @param result The LLM result
    """
    # Only oracle can call this
    assert msg.sender == self.oracle_interface, "Only oracle can call"
    
    # Find the task associated with this request
    # In a real implementation, we would store a mapping from request_id to task_id
    # For simplicity, we'll assume the request_id is the task_id
    task_id: bytes32 = request_id
    
    # Check if task exists
    assert task_id in self.task_ids, "Task not found"
    task: IAgentCore.TaskInfo = self.tasks[task_id]
    
    # Process the LLM result
    # Check if we need to call MCP for browser actions
    if "BROWSER_ACTION:" in result:
        # Extract browser action data
        action_data: String[1024] = result
        
        # Request MCP action
        mcp: IMCPIntegration.IMCPIntegration = IMCPIntegration.IMCPIntegration(self.mcp_integration)
        mcp.request_firefox_action(
            action_data,
            self,
            self.process_mcp_callback_selector
        )
    else:
        # No browser action needed, complete the task
        self._complete_task(task_id, result)

@external
def process_mcp_callback(request_id: bytes32, result: String[1024]):
    """
    @notice Callback function for MCP actions
    @param request_id The MCP request ID
    @param result The MCP result
    """
    # Only MCP integration can call this
    assert msg.sender == self.mcp_integration, "Only MCP can call"
    
    # Find the task associated with this request
    # In a real implementation, we would store a mapping from request_id to task_id
    # For simplicity, we'll assume the request_id is the task_id
    task_id: bytes32 = request_id
    
    # Check if task exists
    assert task_id in self.task_ids, "Task not found"
    
    # Complete the task with the MCP result
    self._complete_task(task_id, result)

@internal
def _complete_task(task_id: bytes32, result: String[1024]):
    """
    @notice Internal function to complete a task
    @param task_id The ID of the task
    @param result The result of the task
    """
    task: IAgentCore.TaskInfo = self.tasks[task_id]
    
    # Update task
    task.status = TASK_STATUS_COMPLETED
    task.completed_at = block.timestamp
    task.result = result
    self.tasks[task_id] = task
    
    # Store result in memory
    memory_storage: IMemoryStorage.IMemoryStorage = IMemoryStorage.IMemoryStorage(self.memory_storage)
    tags: DynArray[String[32], 10] = []
    tags.append("result")
    memory_storage.store_memory(result, 2, tags, True)
    
    # Emit event
    log TaskCompleted(task_id, result, block.timestamp)

@external
def get_task_result(task_id: bytes32) -> String[1024]:
    """
    @notice Get the result of a completed task
    @param task_id The ID of the task
    @return result The result of the task
    """
    assert task_id in self.task_ids, "Task not found"
    task: IAgentCore.TaskInfo = self.tasks[task_id]
    assert task.owner == msg.sender or msg.sender == self.owner, "Not authorized"
    assert task.status == TASK_STATUS_COMPLETED, "Task not completed"
    
    return task.result

@external
def get_user_tasks(user: address) -> DynArray[bytes32, 100]:
    """
    @notice Get all tasks for a user
    @param user The address of the user
    @return task_ids Array of task IDs
    """
    assert user == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return self.user_tasks[user]
