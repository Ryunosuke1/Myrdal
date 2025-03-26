# @version ^0.4.1
# @title Agent Core Interface
# @notice Interface for the Agent Core contract

struct TaskInfo:
    id: bytes32
    owner: address
    prompt: String[1024]
    status: uint8
    created_at: uint256
    completed_at: uint256
    result: String[1024]


# インポートパスを修正
# カスタムインターフェースのインポート
# IIAgentCoreインターフェースを直接定義
# @notice Create a new task for the agent to process
# @param prompt The user's prompt or request
# @return task_id The ID of the created task
def create_task(prompt: String[1024]) -> bytes32: nonpayable

# @notice Get the status of a task
# @param task_id The ID of the task
# @return TaskInfo The task information
def get_task(task_id: bytes32) -> TaskInfo: view

# @notice Process a task (move it forward in execution)
# @param task_id The ID of the task to process
# @return completed Whether the task is now completed
def process_task(task_id: bytes32) -> bool: nonpayable

# @notice Get the result of a completed task
# @param task_id The ID of the task
# @return result The result of the task
def get_task_result(task_id: bytes32) -> String[1024]: view

# @notice Get all tasks for a user
# @param user The address of the user
# @return task_ids Array of task IDs
def get_user_tasks(user: address) -> DynArray[bytes32, 100]: view
