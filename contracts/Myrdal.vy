# @version 0.4.1

"""
@title Myrdal Unified Contract
@author Myrdal Team
@notice Core contract for Myrdal On Chain AI Agent combining all functionality
"""

###################################
# Events
###################################

event TaskCreated:
    task_id: bytes32
    creator: address
    prompt: String[1024]
    timestamp: uint256

event TaskCompleted:
    task_id: bytes32
    result: String[1024]
    timestamp: uint256

event TaskProcessing:
    task_id: bytes32
    status: uint8
    timestamp: uint256

event MCPRequestCreated:
    request_id: bytes32
    task_id: bytes32
    action_type: uint8
    timestamp: uint256

event MemoryStored:
    memory_id: bytes32
    task_id: bytes32
    timestamp: uint256

event UserRegistered:
    user: address
    privacy_level: uint8
    timestamp: uint256

event PrivacyLevelUpdated:
    user: address
    old_level: uint8
    new_level: uint8
    timestamp: uint256

event UserDeactivated:
    user: address
    timestamp: uint256

event UserReactivated:
    user: address
    timestamp: uint256

event FundsAdded:
    user: address
    amount: uint256
    timestamp: uint256

event FundsWithdrawn:
    user: address
    amount: uint256
    timestamp: uint256
event OracleRequestCreated:
    request_id: bytes32
    task_id: bytes32
    timestamp: uint256

event FileUploaded:
    task_id: bytes32
    file_hash: bytes32
    metadata: String[1024]
    uploader: address

event FileAccessGranted:
    file_hash: bytes32
    user: address
    grantor: address

###################################
# Structs
###################################

struct TaskInfo:
    id: bytes32
    creator: address
    prompt: String[1024]
    result: String[1024]
    created_at: uint256
    completed_at: uint256
    status: uint8
    mcp_requests: DynArray[bytes32, 10]
    memory_entries: DynArray[bytes32, 10]
    oracle_requests: DynArray[bytes32, 5]

struct MCPRequest:
    id: bytes32
    task_id: bytes32
    action_type: uint8  # 1: Firefox, 2: pyppeteer, 3: other MCP
    action_data: String[1024]
    callback_function_selector: bytes4
    timestamp: uint256
    fulfilled: bool
    result: String[1024]

struct MemoryEntry:
    id: bytes32
    owner: address
    content: String[1024]
    created_at: uint256
    priority: uint8
    tags: DynArray[String[32], 100]
    encrypted: bool

struct UserInfo:
    id: bytes32
    address: address
    name: String[100]
    email: String[100]
    created_at: uint256
    last_login: uint256
    privacy_level: uint8
    payment_balance: uint256
    is_active: bool

struct OracleRequest:
    id: bytes32
    task_id: bytes32
    data: String[1024]
    callback_function_selector: bytes4
    timestamp: uint256
    fulfilled: bool
    result: String[1024]

# ファイルメタデータ構造体
struct FileMetadata:
    file_hash: bytes32
    uploader: address
    name: String[256]
    description: String[512]
    mime_type: String[64]
    size: uint256
    upload_timestamp: uint256
    task_id: bytes32

###################################
# Constants
###################################

TASK_STATUS_PENDING: constant(uint8) = 0
TASK_STATUS_PROCESSING: constant(uint8) = 1
TASK_STATUS_COMPLETED: constant(uint8) = 2
TASK_STATUS_FAILED: constant(uint8) = 3

MCP_TYPE_FIREFOX: constant(uint8) = 1
MCP_TYPE_PYPPETEER: constant(uint8) = 2
MCP_TYPE_OTHER: constant(uint8) = 3

# プライバシーレベル定数
PRIVACY_LEVEL_STANDARD: constant(uint8) = 1
PRIVACY_LEVEL_ENHANCED: constant(uint8) = 2
PRIVACY_LEVEL_MAXIMUM: constant(uint8) = 3

MAX_TAGS: constant(uint256) = 10

###################################
# Storage Variables
###################################

owner: public(address)
paused: public(bool)
tasks: HashMap[bytes32, TaskInfo]
user_tasks: HashMap[address, DynArray[bytes32, 100]]
task_count: public(uint256)
task_exists: HashMap[bytes32, bool]

# MCP関連のストレージ
mcp_requests: HashMap[bytes32, MCPRequest]
mcp_request_count: public(uint256)
mcp_request_exists: HashMap[bytes32, bool]

# メモリ関連のストレージ
memories: HashMap[bytes32, MemoryEntry]
user_memories: HashMap[address, DynArray[bytes32, 100]]
memory_count: public(uint256)
memory_exists: HashMap[bytes32, bool]
memory_tags: HashMap[String[32], DynArray[bytes32, 100]]

# オラクル関連のストレージ
oracle_requests: HashMap[bytes32, OracleRequest]
oracle_request_count: public(uint256)
oracle_request_exists: HashMap[bytes32, bool]
mcp_oracle_address: public(address)

# ユーザー関連のストレージ
users: public(HashMap[address, UserInfo])
user_addresses: public(DynArray[address, 1000])
service_fee: public(uint256)  # Fee for using the service (in wei)

# Fileverse関連のストレージ
fileverse_operators: public(HashMap[address, bool])
task_files: public(HashMap[bytes32, DynArray[bytes32, 100]])
file_metadata: public(HashMap[bytes32, FileMetadata])
user_files: public(HashMap[address, DynArray[bytes32, 100]])
file_access: public(HashMap[bytes32, HashMap[address, bool]])

###################################
# Core Functions
###################################

@deploy
def __init__():
    """
    @notice コントラクトの初期化
    """
    self.owner = msg.sender
    self.paused = False
    self.task_count = 0
    self.mcp_request_count = 0
    self.memory_count = 0
    self.oracle_request_count = 0
    self.mcp_oracle_address = msg.sender  # 初期値としてオーナーを設定

@external
def create_task(prompt: String[1024]) -> bytes32:
    """
    @notice 新しいタスクを作成
    @param prompt タスクのプロンプト
    @return task_id 作成されたタスクのID
    """
    assert not self.paused, "Contract is paused"
    
    # タスクIDの生成
    timestamp_bytes: bytes32 = convert(block.timestamp, bytes32)
    sender_bytes: bytes32 = convert(msg.sender, bytes32)
    count_bytes: bytes32 = convert(self.task_count, bytes32)
    task_id: bytes32 = keccak256(concat(timestamp_bytes, sender_bytes, count_bytes))
    
    # 空の配列の初期化
    empty_mcp_requests: DynArray[bytes32, 10] = []
    empty_memory_entries: DynArray[bytes32, 10] = []
    empty_oracle_requests: DynArray[bytes32, 5] = []
    
    # タスク情報の作成
    task: TaskInfo = TaskInfo(
        id=task_id,
        creator=msg.sender,
        prompt=prompt,
        result="",
        created_at=block.timestamp,
        completed_at=0,
        status=TASK_STATUS_PENDING,
        mcp_requests=empty_mcp_requests,
        memory_entries=empty_memory_entries,
        oracle_requests=empty_oracle_requests
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
def process_task(task_id: bytes32) -> bool:
    """
    @notice タスクを処理（実行を進める）
    @param task_id タスクID
    @return success 成功したかどうか
    """
    assert self.task_exists[task_id], "Task not found"
    assert self.tasks[task_id].status == TASK_STATUS_PENDING, "Task not in pending status"
    
    # タスク情報の更新
    task: TaskInfo = self.tasks[task_id]
    task.status = TASK_STATUS_PROCESSING
    self.tasks[task_id] = task
    
    # イベントの発行
    log TaskProcessing(task_id=task_id, status=TASK_STATUS_PROCESSING, timestamp=block.timestamp)
    
    return True

@external
def cancel_mcp_request(request_id: bytes32) -> bool:
    """
    @notice MCPリクエストをキャンセル
    @param request_id キャンセルするリクエストのID
    @return success キャンセルが成功したかどうか
    """
    # リクエストが存在するかチェック
    assert self.mcp_request_exists[request_id], "Request not found"

    # リクエストが完了していないことを確認
    assert not self.mcp_requests[request_id].fulfilled, "Request already fulfilled"

    # リクエスト情報を取得
    request: MCPRequest = self.mcp_requests[request_id]
    task: TaskInfo = self.tasks[request.task_id]

    # 呼び出し元がタスクの所有者またはコントラクトの所有者であることを確認
    assert task.creator == msg.sender or msg.sender == self.owner, "Not authorized"

    # リクエストを完了状態にマークし、結果を空に設定
    request.fulfilled = True
    request.result = ""
    self.mcp_requests[request_id] = request

    # taskのステータスを更新（必要な場合）
    if task.status == TASK_STATUS_PROCESSING:
        task.status = TASK_STATUS_FAILED
        self.tasks[request.task_id] = task

    return True

@external
def cancel_oracle_request(request_id: bytes32) -> bool:
    """
    @notice オラクルリクエストをキャンセル
    @param request_id キャンセルするリクエストのID
    @return success キャンセルが成功したかどうか
    """
    # リクエストが存在するかチェック
    assert self.oracle_request_exists[request_id], "Request not found"

    # リクエストが完了していないことを確認
    assert not self.oracle_requests[request_id].fulfilled, "Request already fulfilled"

    # リクエスト情報を取得
    request: OracleRequest = self.oracle_requests[request_id]
    task: TaskInfo = self.tasks[request.task_id]

    # 呼び出し元がタスクの所有者またはコントラクトの所有者であることを確認
    assert task.creator == msg.sender or msg.sender == self.owner, "Not authorized"

    # リクエストを完了状態にマークし、結果を空に設定
    request.fulfilled = True
    request.result = ""
    self.oracle_requests[request_id] = request

    # taskのステータスを更新（必要な場合）
    if task.status == TASK_STATUS_PROCESSING:
        task.status = TASK_STATUS_FAILED
        self.tasks[request.task_id] = task

    return True

@external
@payable
def add_funds() -> bool:
    """
    @notice ユーザーの残高に資金を追加
    @return success 入金が成功したかどうか
    """
    # ユーザーが登録済みかチェック
    assert self.users[msg.sender].address != empty(address), "User not registered"

    # 残高に追加
    self.users[msg.sender].payment_balance += msg.value

    # イベントの発行
    log FundsAdded(user=msg.sender, amount=msg.value, timestamp=block.timestamp)

    return True

@external
def withdraw_funds(amount: uint256) -> bool:
    """
    @notice ユーザーの残高から資金を引き出し
    @param amount 引き出す金額
    @return success 引き出しが成功したかどうか
    """
    # ユーザーが登録済みかチェック
    assert self.users[msg.sender].address != empty(address), "User not registered"

    # 残高が十分かチェック
    assert self.users[msg.sender].payment_balance >= amount, "Insufficient balance"

    # 残高を更新
    self.users[msg.sender].payment_balance -= amount

    # 資金を送金
    send(msg.sender, amount)

    # イベントの発行
    log FundsWithdrawn(user=msg.sender, amount=amount, timestamp=block.timestamp)

    return True

@external
def update_service_fee(new_fee: uint256) -> bool:
    """
    @notice サービス手数料を更新
    @param new_fee 新しい手数料
    @return success 更新が成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can update fee"
    self.service_fee = new_fee
    return True

@external
@payable
def withdraw_service_fees() -> bool:
    """
    @notice 累積したサービス手数料を引き出し
    @return success 引き出しが成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can withdraw fees"
    send(self.owner, self.balance)
    return True

###################################
# User Authentication Functions
###################################

@external
def register_user(name: String[100], email: String[100], privacy_level: uint8) -> bool:
    """
    @notice 新しいユーザーを登録
    @param name ユーザー名
    @param email メールアドレス
    @param privacy_level プライバシーレベル
    @return success 登録が成功したかどうか
    """
    # すでに登録済みかチェック
    assert self.users[msg.sender].address == empty(address), "Already registered"

    # プライバシーレベルの検証
    assert privacy_level >= PRIVACY_LEVEL_STANDARD and privacy_level <= PRIVACY_LEVEL_MAXIMUM, "Invalid privacy level"

    # ユーザーIDの生成
    user_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(msg.sender, bytes32)
    ))

    # ユーザー情報の作成
    user: UserInfo = UserInfo(
        id=user_id,
        address=msg.sender,
        name=name,
        email=email,
        created_at=block.timestamp,
        last_login=block.timestamp,
        privacy_level=privacy_level,
        payment_balance=0,
        is_active=True
    )

    # ユーザー情報の保存
    self.users[msg.sender] = user
    self.user_addresses.append(msg.sender)

    # イベントの発行
    log UserRegistered(user=msg.sender, privacy_level=privacy_level, timestamp=block.timestamp)

    return True

@external
@view
def is_user_active(user: address) -> bool:
    """
    @notice ユーザーがアクティブかどうか確認
    @param user ユーザーアドレス
    @return is_active アクティブかどうか
    """
    return self.users[user].is_active

@external
@view
def get_user_info(user: address) -> UserInfo:
    """
    @notice ユーザー情報を取得
    @param user ユーザーアドレス
    @return UserInfo ユーザー情報
    """
    # 本人かオーナーのみ取得可能
    assert user == msg.sender or msg.sender == self.owner, "Not authorized"
    return self.users[user]

@external
def update_privacy_level(new_privacy_level: uint8) -> bool:
    """
    @notice プライバシーレベルを更新
    @param new_privacy_level 新しいプライバシーレベル
    @return success 更新が成功したかどうか
    """
    # ユーザーが登録済みかチェック
    assert self.users[msg.sender].address != empty(address), "User not registered"

    # プライバシーレベルの検証
    assert new_privacy_level >= PRIVACY_LEVEL_STANDARD and new_privacy_level <= PRIVACY_LEVEL_MAXIMUM, "Invalid privacy level"

    # 現在のプライバシーレベルを取得
    old_level: uint8 = self.users[msg.sender].privacy_level

    # プライバシーレベルを更新
    self.users[msg.sender].privacy_level = new_privacy_level

    # イベントの発行
    log PrivacyLevelUpdated(user=msg.sender, old_level=old_level, new_level=new_privacy_level, timestamp=block.timestamp)

    return True

@external
def deactivate_account() -> bool:
    """
    @notice ユーザーアカウントを無効化
    @return success 無効化が成功したかどうか
    """
    # ユーザーが登録済みかチェック
    assert self.users[msg.sender].address != empty(address), "User not registered"

    # アカウントがアクティブかチェック
    assert self.users[msg.sender].is_active, "Account already deactivated"

    # アカウントを無効化
    self.users[msg.sender].is_active = False

    # イベントの発行
    log UserDeactivated(user=msg.sender, timestamp=block.timestamp)

    return True

@external
def reactivate_account() -> bool:
    """
    @notice ユーザーアカウントを再有効化
    @return success 再有効化が成功したかどうか
    """
    # ユーザーが登録済みかチェック
    assert self.users[msg.sender].address != empty(address), "User not registered"

    # アカウントが無効化されているかチェック
    assert not self.users[msg.sender].is_active, "Account already active"

    # アカウントを再有効化
    self.users[msg.sender].is_active = True

    # イベントの発行
    log UserReactivated(user=msg.sender, timestamp=block.timestamp)

    return True

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
def get_task_result(task_id: bytes32) -> String[1024]:
    """
    @notice タスク結果を取得
    @param task_id タスクID
    @return result タスクの結果
    """
    assert self.task_exists[task_id], "Task not found"
    assert self.tasks[task_id].status == TASK_STATUS_COMPLETED, "Task not completed"
    return self.tasks[task_id].result

@external
@view
def get_user_tasks(user: address) -> DynArray[bytes32, 100]:
    """
    @notice ユーザーのタスクリストを取得
    @param user ユーザーアドレス
    @return task_ids タスクIDのリスト
    """
    return self.user_tasks[user]

###################################
# MCP Functions
###################################

@external
def request_firefox_action(task_id: bytes32, action_data: String[1024]) -> bytes32:
    """
    @notice Firefoxブラウザアクションをリクエスト
    @param task_id 関連するタスクID
    @param action_data アクションデータ（JSON形式）
    @return request_id MCPリクエストID
    """
    assert self.task_exists[task_id], "Task not found"
    assert msg.sender == self.owner, "Only owner can request MCP actions"
    
    # リクエストIDの生成
    timestamp_bytes: bytes32 = convert(block.timestamp, bytes32)
    count_bytes: bytes32 = convert(self.mcp_request_count, bytes32)
    request_id: bytes32 = keccak256(concat(timestamp_bytes, task_id, count_bytes))

    # complete_mcp_request(bytes32,string)関数のセレクタを計算
    # keccak256("complete_mcp_request(bytes32,string)")の最初の4バイト
    callback_selector: bytes4 = method_id("complete_mcp_request(bytes32,string)", output_type=bytes4)
    
    # MCPリクエスト情報の作成
    request: MCPRequest = MCPRequest(
        id=request_id,
        task_id=task_id,
        action_type=MCP_TYPE_FIREFOX,
        action_data=action_data,
        callback_function_selector=callback_selector,
        timestamp=block.timestamp,
        fulfilled=False,
        result=""
    )
    
    # リクエストの保存
    self.mcp_requests[request_id] = request
    self.mcp_request_exists[request_id] = True
    
    # タスクのMCPリクエストリストに追加
    task: TaskInfo = self.tasks[task_id]
    task.mcp_requests.append(request_id)
    self.tasks[task_id] = task
    
    # リクエストカウントの更新
    self.mcp_request_count += 1
    
    # イベントの発行
    log MCPRequestCreated(request_id=request_id, task_id=task_id, action_type=MCP_TYPE_FIREFOX, timestamp=block.timestamp)
    
    return request_id

@external
def request_pyppeteer_action(task_id: bytes32, action_data: String[1024]) -> bytes32:
    """
    @notice pyppeteerアクションをリクエスト
    @param task_id 関連するタスクID
    @param action_data アクションデータ（JSON形式）
    @return request_id MCPリクエストID
    """
    assert self.task_exists[task_id], "Task not found"
    assert msg.sender == self.owner, "Only owner can request MCP actions"
    
    # リクエストIDの生成
    timestamp_bytes: bytes32 = convert(block.timestamp, bytes32)
    count_bytes: bytes32 = convert(self.mcp_request_count, bytes32)
    request_id: bytes32 = keccak256(concat(timestamp_bytes, task_id, count_bytes))

    # complete_mcp_request(bytes32,string)関数のセレクタを計算
    # keccak256("complete_mcp_request(bytes32,string)")の最初の4バイト
    callback_selector: bytes4 = method_id("complete_mcp_request(bytes32,string)", output_type=bytes4)
    
    # MCPリクエスト情報の作成
    request: MCPRequest = MCPRequest(
        id=request_id,
        task_id=task_id,
        action_type=MCP_TYPE_PYPPETEER,
        action_data=action_data,
        callback_function_selector=callback_selector,
        timestamp=block.timestamp,
        fulfilled=False,
        result=""
    )
    
    # リクエストの保存
    self.mcp_requests[request_id] = request
    self.mcp_request_exists[request_id] = True
    
    # タスクのMCPリクエストリストに追加
    task: TaskInfo = self.tasks[task_id]
    task.mcp_requests.append(request_id)
    self.tasks[task_id] = task
    
    # リクエストカウントの更新
    self.mcp_request_count += 1
    
    # イベントの発行
    log MCPRequestCreated(request_id=request_id, task_id=task_id, action_type=MCP_TYPE_PYPPETEER, timestamp=block.timestamp)
    
    return request_id

@external
def complete_mcp_request(request_id: bytes32, result: String[1024]) -> bool:
    """
    @notice MCPリクエストを完了としてマーク（オラクルから呼び出される）
    @param request_id リクエストID
    @param result リクエスト結果
    @return success 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can complete MCP requests"
    assert self.mcp_request_exists[request_id], "Request not found"
    assert not self.mcp_requests[request_id].fulfilled, "Request already fulfilled"
    
    # リクエスト情報の更新
    request: MCPRequest = self.mcp_requests[request_id]
    request.fulfilled = True
    request.result = result
    self.mcp_requests[request_id] = request
    
    return True

@external
@view
def is_mcp_request_fulfilled(request_id: bytes32) -> bool:
    """
    @notice MCPリクエストが完了しているか確認
    @param request_id リクエストID
    @return fulfilled 完了しているかどうか
    """
    assert self.mcp_request_exists[request_id], "Request not found"
    return self.mcp_requests[request_id].fulfilled

@external
@view
def get_mcp_request_result(request_id: bytes32) -> String[1024]:
    """
    @notice MCPリクエスト結果を取得
    @param request_id リクエストID
    @return result リクエスト結果
    """
    assert self.mcp_request_exists[request_id], "Request not found"
    assert self.mcp_requests[request_id].fulfilled, "Request not fulfilled"
    return self.mcp_requests[request_id].result

###################################
# Memory Functions
###################################

@external
def store_memory(content: String[1024], tags: DynArray[String[32], 100], priority: uint8, encrypted: bool) -> bytes32:
    """
    @notice メモリを保存
    @param content メモリの内容
    @param tags メモリに関連するタグ
    @param priority メモリの優先度（0-255）
    @param encrypted 暗号化されているかどうか
    @return memory_id 作成されたメモリのID
    """
    assert not self.paused, "Contract is paused"
    
    # メモリIDの生成
    timestamp_bytes: bytes32 = convert(block.timestamp, bytes32)
    sender_bytes: bytes32 = convert(msg.sender, bytes32)
    count_bytes: bytes32 = convert(self.memory_count, bytes32)
    memory_id: bytes32 = keccak256(concat(timestamp_bytes, sender_bytes, count_bytes))
    
    # メモリ情報の作成
    memory: MemoryEntry = MemoryEntry(
        id=memory_id,
        owner=msg.sender,
        content=content,
        created_at=block.timestamp,
        priority=priority,
        tags=tags,
        encrypted=encrypted
    )
    
    # メモリの保存
    self.memories[memory_id] = memory
    self.memory_exists[memory_id] = True
    
    # ユーザーのメモリリストに追加
    user_memory_list: DynArray[bytes32, 100] = self.user_memories[msg.sender]
    user_memory_list.append(memory_id)
    self.user_memories[msg.sender] = user_memory_list
    
    # タグインデックスの更新
    for tag: String[32] in tags:
        tag_memory_list: DynArray[bytes32, 100] = self.memory_tags[tag]
        tag_memory_list.append(memory_id)
        self.memory_tags[tag] = tag_memory_list
    
    # メモリカウントの更新
    self.memory_count += 1
    
    # イベントの発行
    log MemoryStored(memory_id=memory_id, task_id=empty(bytes32), timestamp=block.timestamp)
    
    return memory_id

@external
def store_task_memory(task_id: bytes32, content: String[1024], tags: DynArray[String[32], 100], priority: uint8, encrypted: bool) -> bytes32:
    """
    @notice タスクに関連するメモリを保存
    @param task_id 関連するタスクID
    @param content メモリの内容
    @param tags メモリに関連するタグ
    @param priority メモリの優先度（0-255）
    @param encrypted 暗号化されているかどうか
    @return memory_id 作成されたメモリのID
    """
    assert not self.paused, "Contract is paused"
    assert self.task_exists[task_id], "Task not found"
    
    # メモリIDの生成
    timestamp_bytes: bytes32 = convert(block.timestamp, bytes32)
    sender_bytes: bytes32 = convert(msg.sender, bytes32)
    count_bytes: bytes32 = convert(self.memory_count, bytes32)
    memory_id: bytes32 = keccak256(concat(timestamp_bytes, sender_bytes, count_bytes))
    
    # メモリ情報の作成
    memory: MemoryEntry = MemoryEntry(
        id=memory_id,
        owner=msg.sender,
        content=content,
        created_at=block.timestamp,
        priority=priority,
        tags=tags,
        encrypted=encrypted
    )
    
    # メモリの保存
    self.memories[memory_id] = memory
    self.memory_exists[memory_id] = True
    
    # ユーザーのメモリリストに追加
    user_memory_list: DynArray[bytes32, 100] = self.user_memories[msg.sender]
    user_memory_list.append(memory_id)
    self.user_memories[msg.sender] = user_memory_list
    
    # タスクのメモリリストに追加
    task: TaskInfo = self.tasks[task_id]
    task.memory_entries.append(memory_id)
    self.tasks[task_id] = task
    
    # タグインデックスの更新
    for tag: String[32] in tags:
        tag_memory_list: DynArray[bytes32, 100] = self.memory_tags[tag]
        tag_memory_list.append(memory_id)
        self.memory_tags[tag] = tag_memory_list
    
    # メモリカウントの更新
    self.memory_count += 1
    
    # イベントの発行
    log MemoryStored(memory_id=memory_id, task_id=task_id, timestamp=block.timestamp)
    
    return memory_id

@external
@view
def get_memory(memory_id: bytes32) -> MemoryEntry:
    """
    @notice メモリ情報を取得
    @param memory_id メモリID
    @return memory メモリ情報
    """
    assert self.memory_exists[memory_id], "Memory not found"
    return self.memories[memory_id]

@external
@view
def search_memories_by_tag(tag: String[32]) -> DynArray[bytes32, 100]:
    """
    @notice タグでメモリを検索
    @param tag 検索するタグ
    @return memory_ids メモリIDのリスト
    """
    return self.memory_tags[tag]

@external
@view
def search_memories_by_tags(tags: DynArray[String[32], 100], require_all: bool) -> DynArray[bytes32, 100]:
    """
    @notice 複数のタグでメモリを検索
    @param tags 検索するタグのリスト
    @param require_all 全てのタグに一致する必要があるか（AND検索）
    @return memory_ids メモリIDのリスト
    """
    assert len(tags) > 0, "At least one tag is required"
    
    # 最初のタグに一致するメモリを取得
    result: DynArray[bytes32, 100] = self.memory_tags[tags[0]]
    
    if require_all:
        # 他のタグに一致するメモリとの共通部分を取得
        # 最大100個のタグを処理
        for i: uint256 in range(100):
            # インデックスが範囲外または処理済みの場合はスキップ
            if i == 0 or i >= len(tags):
                continue
                
            tag_memories: DynArray[bytes32, 100] = self.memory_tags[tags[i]]
            new_result: DynArray[bytes32, 100] = []
            
            for memory_id: bytes32 in result:
                for tag_memory_id: bytes32 in tag_memories:
                    if memory_id == tag_memory_id:
                        new_result.append(memory_id)
                        break
            
            result = new_result
    
    return result

@external
@view
def get_user_memories(user: address) -> DynArray[bytes32, 100]:
    """
    @notice ユーザーのメモリリストを取得
    @param user ユーザーアドレス
    @return memory_ids メモリIDのリスト
    """
    return self.user_memories[user]

@external
def delete_memory(memory_id: bytes32) -> bool:
    """
    @notice メモリを削除
    @param memory_id 削除するメモリID
    @return success 成功したかどうか
    """
    assert self.memory_exists[memory_id], "Memory not found"
    memory: MemoryEntry = self.memories[memory_id]
    assert msg.sender == memory.owner or msg.sender == self.owner, "Only owner can delete memory"
    
    # メモリが関連付けられているタスクを検索
    user_task_list: DynArray[bytes32, 100] = self.user_tasks[memory.owner]
    for task_id: bytes32 in user_task_list:
        if self.task_exists[task_id]:
            task: TaskInfo = self.tasks[task_id]
            # タスクのメモリリストから削除
            new_memory_entries: DynArray[bytes32, 10] = []
            for entry_id: bytes32 in task.memory_entries:
                if entry_id != memory_id:
                    new_memory_entries.append(entry_id)
            task.memory_entries = new_memory_entries
            self.tasks[task_id] = task
    
    # タグインデックスから削除
    for tag: String[32] in memory.tags:
        tag_memory_list: DynArray[bytes32, 100] = self.memory_tags[tag]
        new_tag_memory_list: DynArray[bytes32, 100] = []
        for tag_memory_id: bytes32 in tag_memory_list:
            if tag_memory_id != memory_id:
                new_tag_memory_list.append(tag_memory_id)
        self.memory_tags[tag] = new_tag_memory_list
    
    # ユーザーのメモリリストから削除
    user_memory_list: DynArray[bytes32, 100] = self.user_memories[memory.owner]
    new_user_memory_list: DynArray[bytes32, 100] = []
    for user_memory_id: bytes32 in user_memory_list:
        if user_memory_id != memory_id:
            new_user_memory_list.append(user_memory_id)
    self.user_memories[memory.owner] = new_user_memory_list
    
    # メモリの存在フラグを更新
    self.memory_exists[memory_id] = False
    
    return True

###################################
# Oracle Functions
###################################

@external
def request_llm_completion(task_id: bytes32, prompt: String[1024]) -> bytes32:
    """
    @notice 外部LLMサービスからデータをリクエスト
    @param task_id 関連するタスクID
    @param prompt LLMに送信するプロンプト
    @return request_id オラクルリクエストID
    """
    assert self.task_exists[task_id], "Task not found"
    assert msg.sender == self.owner, "Only owner can request LLM completions"
    
    # リクエストIDの生成
    timestamp_bytes: bytes32 = convert(block.timestamp, bytes32)
    count_bytes: bytes32 = convert(self.oracle_request_count, bytes32)
    request_id: bytes32 = keccak256(concat(timestamp_bytes, task_id, count_bytes))

    # complete_oracle_request(bytes32,string)関数のセレクタを計算
    # keccak256("complete_oracle_request(bytes32,string)")の最初の4バイト
    callback_selector: bytes4 = method_id("complete_oracle_request(bytes32,string)", output_type=bytes4)
    
    # オラクルリクエスト情報の作成
    request: OracleRequest = OracleRequest(
        id=request_id,
        task_id=task_id,
        data=prompt,
        callback_function_selector=callback_selector,
        timestamp=block.timestamp,
        fulfilled=False,
        result=""
    )
    
    # リクエストの保存
    self.oracle_requests[request_id] = request
    self.oracle_request_exists[request_id] = True
    
    # タスクのオラクルリクエストリストに追加
    task: TaskInfo = self.tasks[task_id]
    task.oracle_requests.append(request_id)
    self.tasks[task_id] = task
    
    # リクエストカウントの更新
    self.oracle_request_count += 1
    
    # イベントの発行
    log OracleRequestCreated(request_id=request_id, task_id=task_id, timestamp=block.timestamp)
    
    return request_id

@external
def complete_oracle_request(request_id: bytes32, result: String[1024]) -> bool:
    """
    @notice オラクルリクエストを完了としてマーク（オラクルから呼び出される）
    @param request_id リクエストID
    @param result リクエスト結果
    @return success 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can complete oracle requests"
    assert self.oracle_request_exists[request_id], "Request not found"
    assert not self.oracle_requests[request_id].fulfilled, "Request already fulfilled"
    
    # リクエスト情報の更新
    request: OracleRequest = self.oracle_requests[request_id]
    request.fulfilled = True
    request.result = result
    self.oracle_requests[request_id] = request
    
    return True

@external
@view
def is_oracle_request_fulfilled(request_id: bytes32) -> bool:
    """
    @notice オラクルリクエストが完了しているか確認
    @param request_id リクエストID
    @return fulfilled 完了しているかどうか
    """
    assert self.oracle_request_exists[request_id], "Request not found"
    return self.oracle_requests[request_id].fulfilled

@external
@view
def get_oracle_request_result(request_id: bytes32) -> String[1024]:
    """
    @notice オラクルリクエスト結果を取得
    @param request_id リクエストID
    @return result リクエスト結果
    """
    assert self.oracle_request_exists[request_id], "Request not found"
    assert self.oracle_requests[request_id].fulfilled, "Request not fulfilled"
    return self.oracle_requests[request_id].result

###################################
# Admin Functions
###################################

@external
def set_mcp_oracle_address(new_address: address) -> bool:
    """
    @notice MCPオラクルアドレスを設定
    @param new_address 新しいMCPオラクルアドレス
    @return success 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can set MCP oracle address"
    assert new_address != empty(address), "New address cannot be zero address"
    self.mcp_oracle_address = new_address
    return True

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
###################################
# Fileverse Functions
###################################

@external
def add_fileverse_operator(operator: address) -> bool:
    """
    @notice Fileverseオペレーターを追加します
    @param operator オペレーターのアドレス
    @return 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can add operators"
    self.fileverse_operators[operator] = True
    return True

@external
def remove_fileverse_operator(operator: address) -> bool:
    """
    @notice Fileverseオペレーターを削除します
    @param operator オペレーターのアドレス
    @return 成功したかどうか
    """
    assert msg.sender == self.owner, "Only owner can remove operators"
    self.fileverse_operators[operator] = False
    return True

@external
def record_file_upload(
    task_id: bytes32, 
    file_hash: bytes32, 
    name: String[256], 
    description: String[512], 
    mime_type: String[64], 
    size: uint256
) -> bool:
    """
    @notice ファイルのアップロードを記録します
    @param task_id タスクID
    @param file_hash ファイルハッシュ
    @param name ファイル名
    @param description ファイルの説明
    @param mime_type MIMEタイプ
    @param size ファイルサイズ
    @return 成功したかどうか
    """
    # オペレーターからの呼び出しか確認
    assert self.fileverse_operators[msg.sender], "Only authorized operators can record uploads"
    
    # ファイルメタデータを作成
    metadata: FileMetadata = FileMetadata(
        file_hash=file_hash,
        uploader=msg.sender,
        name=name,
        description=description,
        mime_type=mime_type,
        size=size,
        upload_timestamp=block.timestamp,
        task_id=task_id
    )
    
    # タスクのファイルリストに追加
    task_files: DynArray[bytes32, 100] = self.task_files[task_id]
    task_files.append(file_hash)
    self.task_files[task_id] = task_files
    
    # ファイルのメタデータを保存
    self.file_metadata[file_hash] = metadata
    
    # アップローダーのファイルリストに追加
    user_files: DynArray[bytes32, 100] = self.user_files[msg.sender]
    user_files.append(file_hash)
    self.user_files[msg.sender] = user_files
    
    # アップローダーにアクセス権を付与
    self.file_access[file_hash][msg.sender] = True
    
    # タスク作成者にもアクセス権を付与
    task: TaskInfo = self.tasks[task_id]
    if task.creator != empty(address):
        self.file_access[file_hash][task.creator] = True
        log FileAccessGranted(file_hash=file_hash, user=task.creator, grantor=msg.sender)
    
    # イベントの発行
    metadata_str: String[1024] = concat(
        name, 
        " (", 
        mime_type, 
        ", ", 
        uint2str(size), 
        " bytes)"
    )
    log FileUploaded(task_id=task_id, file_hash=file_hash, metadata=metadata_str, uploader=msg.sender)
    
    return True

@external
def grant_file_access(file_hash: bytes32, user: address) -> bool:
    """
    @notice ファイルへのアクセス権を付与します
    @param file_hash ファイルハッシュ
    @param user アクセス権を付与するユーザー
    @return 成功したかどうか
    """
    # ファイルが存在するか確認
    metadata: FileMetadata = self.file_metadata[file_hash]
    assert metadata.file_hash == file_hash, "File not found"
    
    # 呼び出し元がファイルのアップローダーか所有者か確認
    assert metadata.uploader == msg.sender or msg.sender == self.owner, "Not authorized"
    
    # アクセス権を付与
    self.file_access[file_hash][user] = True
    
    # イベントの発行
    log FileAccessGranted(file_hash=file_hash, user=user, grantor=msg.sender)
    
    return True

@view
@external
def has_file_access(file_hash: bytes32, user: address) -> bool:
    """
    @notice ユーザーがファイルへのアクセス権を持っているか確認します
    @param file_hash ファイルハッシュ
    @param user 確認するユーザー
    @return アクセス権を持っているかどうか
    """
    return self.file_access[file_hash][user]

@view
@external
def get_task_files(task_id: bytes32) -> DynArray[bytes32, 100]:
    """
    @notice タスクに関連するファイルの一覧を取得します
    @param task_id タスクID
    @return ファイルハッシュの配列
    """
    return self.task_files[task_id]

@view
@external
def get_user_files(user: address) -> DynArray[bytes32, 100]:
    """
    @notice ユーザーがアップロードしたファイルの一覧を取得します
    @param user ユーザーアドレス
    @return ファイルハッシュの配列
    """
    # 呼び出し元が対象ユーザーか所有者か確認
    assert user == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return self.user_files[user]

@view
@external
def get_file_metadata(file_hash: bytes32) -> (String[256], String[512], String[64], uint256, uint256, address, bytes32):
    """
    @notice ファイルのメタデータを取得します
    @param file_hash ファイルハッシュ
    @return name, description, mime_type, size, upload_timestamp, uploader, task_id
    """
    # ファイルが存在するか確認
    metadata: FileMetadata = self.file_metadata[file_hash]
    assert metadata.file_hash == file_hash, "File not found"
    
    # アクセス権を確認
    assert self.file_access[file_hash][msg.sender] or msg.sender == self.owner, "Not authorized"
    
    return (
        metadata.name,
        metadata.description,
        metadata.mime_type,
        metadata.size,
        metadata.upload_timestamp,
        metadata.uploader,
        metadata.task_id
    )