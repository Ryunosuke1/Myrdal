# @version 0.4.1

"""
@title Myrdal Core Contract
@author Myrdal Team
@notice Core contract for Myrdal On Chain AI Agent
"""

##############################################################################
# Myrdal Core
##############################################################################
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

event OracleRequestCreated:
    request_id: bytes32
    task_id: bytes32
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
    tags: DynArray[String[32], 10]
    encrypted: bool

struct OracleRequest:
    id: bytes32
    task_id: bytes32
    data: String[1024]
    callback_function_selector: bytes4
    timestamp: uint256
    fulfilled: bool
    result: String[1024]

# 定数
TASK_STATUS_PENDING: constant(uint8) = 0
TASK_STATUS_PROCESSING: constant(uint8) = 1
TASK_STATUS_COMPLETED: constant(uint8) = 2
TASK_STATUS_FAILED: constant(uint8) = 3

MCP_TYPE_FIREFOX: constant(uint8) = 1
MCP_TYPE_PYPPETEER: constant(uint8) = 2
MCP_TYPE_OTHER: constant(uint8) = 3

MAX_TAGS: constant(uint256) = 10

# ストレージ変数
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

# MCPオラクルアドレス（実際のデプロイ時に設定）
mcp_oracle_address: public(address)

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

# MCP関連の機能
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
    
    # コールバック関数セレクタ（complete_mcp_request関数のセレクタ）
    # 実際のデプロイ時には正確なセレクタを計算する必要があります
    callback_selector: bytes4 = 0x12345678
    
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
    
    # コールバック関数セレクタ（complete_mcp_request関数のセレクタ）
    # 実際のデプロイ時には正確なセレクタを計算する必要があります
    callback_selector: bytes4 = 0x12345678
    
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

# メモリ関連の機能
@external
def store_memory(content: String[1024], tags: DynArray[String[32], 10], priority: uint8, encrypted: bool) -> bytes32:
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
    for tag in tags:
        tag_memory_list: DynArray[bytes32, 100] = self.memory_tags[tag]
        tag_memory_list.append(memory_id)
        self.memory_tags[tag] = tag_memory_list
    
    # メモリカウントの更新
    self.memory_count += 1
    
    # イベントの発行
    log MemoryStored(memory_id=memory_id, task_id=empty(bytes32), timestamp=block.timestamp)
    
    return memory_id

@external
def store_task_memory(task_id: bytes32, content: String[1024], tags: DynArray[String[32], 10], priority: uint8, encrypted: bool) -> bytes32:
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
    for tag in tags:
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
def search_memories_by_tags(tags: DynArray[String[32], 10], require_all: bool) -> DynArray[bytes32, 100]:
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
        # 注意: Vyper 0.4.1ではrange関数の第2引数に動的な値を使用できないため、
        # 最大10個のタグを処理するようにハードコードします
        for i: uint256 in range(10):
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

# オラクル関連の機能
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
    
    # コールバック関数セレクタ（complete_oracle_request関数のセレクタ）
    # 実際のデプロイ時には正確なセレクタを計算する必要があります
    callback_selector: bytes4 = 0x87654321
    
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

# 管理機能
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