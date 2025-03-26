# @version 0.4.1

"""
@title Myrdal Core Contract
@author Myrdal Team
@notice Core contract for Myrdal On Chain AI Agent
"""

# イベント定義
event TaskCreated:
    task_id: bytes32
    creator: address
    prompt: String[1024]
    timestamp: uint256

event TaskCompleted:
    task_id: bytes32
    result: String[1024]
    timestamp: uint256

# 構造体定義
struct TaskInfo:
    id: bytes32
    creator: address
    prompt: String[1024]
    result: String[1024]
    created_at: uint256
    completed_at: uint256
    status: uint8

# 定数
TASK_STATUS_PENDING: constant(uint8) = 0
TASK_STATUS_PROCESSING: constant(uint8) = 1
TASK_STATUS_COMPLETED: constant(uint8) = 2
TASK_STATUS_FAILED: constant(uint8) = 3

# ストレージ変数
owner: public(address)
paused: public(bool)
tasks: HashMap[bytes32, TaskInfo]
user_tasks: HashMap[address, DynArray[bytes32, 100]]
task_count: public(uint256)
task_exists: HashMap[bytes32, bool]

@deploy
def __init__():
    """
    @notice コントラクトの初期化
    """
    self.owner = msg.sender
    self.paused = False
    self.task_count = 0

@external
def create_task(prompt: String[1024]) -> bytes32:
    """
    @notice 新しいタスクを作成
    @param prompt タスクのプロンプト
    @return task_id 作成されたタスクのID
    """
    assert not self.paused, "Contract is paused"
    
    # タスクIDの生成
    task_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(msg.sender, bytes32),
        convert(self.task_count, bytes32)
    ))
    
    # タスク情報の作成
    task: TaskInfo = TaskInfo(
        id=task_id,
        creator=msg.sender,
        prompt=prompt,
        result="",
        created_at=block.timestamp,
        completed_at=0,
        status=TASK_STATUS_PENDING
    )
    
    # タスクの保存
    self.tasks[task_id] = task
    self.task_exists[task_id] = True
    
    # ユーザーのタスクリストに追加
    user_task_list: DynArray[bytes32, 100] = self.user_tasks[msg.sender]
    user_task_list.append(task_id)
    self.user_tasks[msg.sender] = user_task_list
    
    # タスクカウントの更新
    self.task_count += 1
    
    # イベントの発行
    log TaskCreated(task_id=task_id, creator=msg.sender, prompt=prompt, timestamp=block.timestamp)
    
    return task_id

@external
def complete_task(task_id: bytes32, result: String[1024]) -> bool:
    """
    @notice タスクを完了としてマーク
    @param task_id タスクID
    @param result タスクの結果
    @return success 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can complete tasks"
    assert self.task_exists[task_id], "Task not found"
    assert self.tasks[task_id].status == TASK_STATUS_PENDING or self.tasks[task_id].status == TASK_STATUS_PROCESSING, "Task already completed or failed"
    
    # タスク情報の更新
    task: TaskInfo = self.tasks[task_id]
    task.result = result
    task.completed_at = block.timestamp
    task.status = TASK_STATUS_COMPLETED
    self.tasks[task_id] = task
    
    # イベントの発行
    log TaskCompleted(task_id=task_id, result=result, timestamp=block.timestamp)
    
    return True

@external
@view
def get_task(task_id: bytes32) -> TaskInfo:
    """
    @notice タスク情報を取得
    @param task_id タスクID
    @return task タスク情報
    """
    assert self.task_exists[task_id], "Task not found"
    return self.tasks[task_id]

@external
@view
def get_user_tasks(user: address) -> DynArray[bytes32, 100]:
    """
    @notice ユーザーのタスクリストを取得
    @param user ユーザーアドレス
    @return task_ids タスクIDのリスト
    """
    return self.user_tasks[user]

@external
def pause() -> bool:
    """
    @notice コントラクトを一時停止
    @return success 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can pause"
    self.paused = True
    return True

@external
def unpause() -> bool:
    """
    @notice コントラクトの一時停止を解除
    @return success 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can unpause"
    self.paused = False
    return True

@external
def transfer_ownership(new_owner: address) -> bool:
    """
    @notice オーナーシップを移転
    @param new_owner 新しいオーナー
    @return success 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can transfer ownership"
    assert new_owner != empty(address), "New owner cannot be zero address"
    self.owner = new_owner
    return True
