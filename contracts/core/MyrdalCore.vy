# @version ^0.4.1

"""
@title MyrdalCore - Oasis Protocol上の汎用AIエージェントコア
@author Myrdal Team
@notice このコントラクトはOasis Protocolの「Sapphire」パラタイムを活用した
機密スマートコントラクトとして実装されています
"""

# インターフェースのインポート
from interfaces import ERC20
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
# IChainlinkMCPインターフェースを直接定義
# インポートパスを修正
# カスタムインターフェースのインポート
# IFileverseIntegrationインターフェースを直接定義
# インポートパスを修正
# カスタムインターフェースのインポート
# IUserAuthインターフェースを直接定義

# 構造体定義
struct TaskInfo:
    id: bytes32
    user: address
    prompt: String[1024]
    status: uint8  # 0: 未処理, 1: 処理中, 2: 完了, 3: エラー
    created_at: uint256
    completed_at: uint256
    result_id: bytes32
    privacy_level: uint8


struct TaskResult:
    id: bytes32
    content: String[1024]
    file_urls: DynArray[String[256], 10]
    memory_ids: DynArray[bytes32, 10]


struct AgentLoopState:
    current_step: uint8  # 1: 分析, 2: ツール選択, 3: 実行待ち, 4: 反復, 5: 結果提出, 6: 待機
    current_tool: String[64]
    current_request_id: bytes32
    iteration_count: uint256
    last_updated: uint256


# イベント定義
event TaskCreated:
    task_id: indexed(bytes32)
    user: indexed(address)
    prompt: String[1024]
    created_at: uint256


event TaskStatusUpdated:
    task_id: indexed(bytes32)
    status: uint8
    updated_at: uint256


event TaskCompleted:
    task_id: indexed(bytes32)
    result_id: bytes32
    completed_at: uint256


event AgentLoopUpdated:
    task_id: indexed(bytes32)
    current_step: uint8
    current_tool: String[64]
    iteration_count: uint256
    updated_at: uint256


# 定数
TASK_STATUS_PENDING: constant(uint8) = 0
TASK_STATUS_PROCESSING: constant(uint8) = 1
TASK_STATUS_COMPLETED: constant(uint8) = 2
TASK_STATUS_ERROR: constant(uint8) = 3

AGENT_STEP_ANALYZE: constant(uint8) = 1
AGENT_STEP_SELECT_TOOL: constant(uint8) = 2
AGENT_STEP_WAIT_EXECUTION: constant(uint8) = 3
AGENT_STEP_ITERATE: constant(uint8) = 4
AGENT_STEP_SUBMIT_RESULTS: constant(uint8) = 5
AGENT_STEP_STANDBY: constant(uint8) = 6

# ストレージ変数
owner: public(address)
paused: public(bool)

memory_storage: public(IMemoryStorage)
oracle_interface: public(IOracleInterface)
mcp_integration: public(IMCPIntegration)
chainlink_mcp: public(IChainlinkMCP)
fileverse_integration: public(IFileverseIntegration)
user_auth: public(IUserAuth)

tasks: public(HashMap[bytes32, TaskInfo])
task_results: public(HashMap[bytes32, TaskResult])
agent_loop_states: public(HashMap[bytes32, AgentLoopState])

user_tasks: public(HashMap[address, DynArray[bytes32, 100]])
next_task_id: uint256
next_result_id: uint256

# 初期化
@deploy
def __init__(
_memory_storage: address,
_oracle_interface: address,
_mcp_integration: address,
_chainlink_mcp: address,
_fileverse_integration: address,
_user_auth: address
):
    owner = sender
    paused = False

memory_storage = IMemoryStorage(_memory_storage)
oracle_interface = IOracleInterface(_oracle_interface)
mcp_integration = IMCPIntegration(_mcp_integration)
chainlink_mcp = IChainlinkMCP(_chainlink_mcp)
fileverse_integration = IFileverseIntegration(_fileverse_integration)
user_auth = IUserAuth(_user_auth)

next_task_id = 1
next_result_id = 1

# 修飾子
@internal
def _only_owner() -> bool:
    pass
assert sender == owner, "Only owner"
return True

@internal
def _not_paused() -> bool:
    pass
assert not paused, "Contract is paused"
return True

@internal
def _only_task_owner(task_id: bytes32) -> bool:
    pass
assert tasks[task_id].user == sender, "Not task owner"
return True

# 管理者機能
@external
def set_memory_storage(_memory_storage: address):
    _only_owner()
    memory_storage = IMemoryStorage(_memory_storage)

@external
def set_oracle_interface(_oracle_interface: address):
    _only_owner()
    oracle_interface = IOracleInterface(_oracle_interface)

@external
def set_mcp_integration(_mcp_integration: address):
    _only_owner()
    mcp_integration = IMCPIntegration(_mcp_integration)

@external
def set_chainlink_mcp(_chainlink_mcp: address):
    _only_owner()
    chainlink_mcp = IChainlinkMCP(_chainlink_mcp)

@external
def set_fileverse_integration(_fileverse_integration: address):
    _only_owner()
    fileverse_integration = IFileverseIntegration(_fileverse_integration)

@external
def set_user_auth(_user_auth: address):
    _only_owner()
    user_auth = IUserAuth(_user_auth)

@external
def pause():
    _only_owner()
    paused = True

@external
def unpause():
    _only_owner()
    paused = False

# タスク管理機能
@external
def create_task(prompt: String[1024]) -> bytes32:
    pass
_not_paused()

# ユーザー認証
assert user_auth.authenticate_user(sender), "Authentication failed"

# タスクIDを生成
task_id: bytes32

task_id = keccak256(concat(
convert(sender, bytes32),
convert(timestamp, bytes32),
convert(next_task_id, bytes32)
))

# プライバシーレベルを取得
privacy_level: uint8

privacy_level = user_auth.get_privacy_level(sender)

# タスク情報を保存
tasks[task_id] = TaskInfo(
    id=task_id,
    user=sender,
    prompt=prompt,
    status=TASK_STATUS_PENDING,
    created_at=timestamp,
    completed_at=0,
    result_id=empty(bytes32),
    privacy_level=privacy_level
)

# エージェントループ状態を初期化
agent_loop_states[task_id] = AgentLoopState(
    current_step=AGENT_STEP_ANALYZE,
    current_tool="",
    current_request_id=empty(bytes32),
    iteration_count=0,
    last_updated=timestamp
)

# ユーザーのタスクリストに追加
user_task_list: DynArray[bytes32, 100] = user_tasks[sender]
append(task_id)
user_tasks[sender] = user_task_list

next_task_id += 1

# タスク作成イベントを発行
log TaskCreated(task_id, sender, prompt, timestamp)

# タスク処理を開始
_process_task(task_id)

return task_id

@internal
def _process_task(task_id: bytes32):
    # タスクステータスを処理中に更新
    tasks[task_id].status = TASK_STATUS_PROCESSING
    log TaskStatusUpdated(task_id, TASK_STATUS_PROCESSING, timestamp)
    
    # エージェントループを開始
    _agent_loop_analyze(task_id)

@external
def cancel_task(task_id: bytes32) -> bool:
    pass
_only_task_owner(task_id)

# 完了済みタスクはキャンセル不可
assert tasks[task_id].status != TASK_STATUS_COMPLETED, "Task already completed"

# タスクステータスをエラーに更新
tasks[task_id].status = TASK_STATUS_ERROR
log TaskStatusUpdated(task_id, TASK_STATUS_ERROR, timestamp)

return True

@external
def get_task_status(task_id: bytes32) -> uint8:
    pass
return tasks[task_id].status

@external
def get_task_result(task_id: bytes32) -> (String[1024], DynArray[String[256], 10], DynArray[bytes32, 10]):
    _only_task_owner(task_id)
    
    # タスクが完了していることを確認
    assert tasks[task_id].status == TASK_STATUS_COMPLETED, "Task not completed"
    
    result_id: bytes32
    result_id = tasks[task_id].result_id
    result: TaskResult
    result = task_results[result_id]
    
    return content, file_urls, memory_ids

# エージェントループ実装
@internal
def _agent_loop_analyze(task_id: bytes32):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    current_step = AGENT_STEP_ANALYZE
    last_updated = timestamp
    agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_ANALYZE, 
        current_tool, 
        iteration_count, 
        timestamp
    )
    
    # タスク情報を取得
    task: TaskInfo
    task = tasks[task_id]
    
    # LLMにタスク分析を依頼
    prompt: String[1024]
    prompt = concat(
        "タスク分析: ", 
        prompt, 
        "\n\n現在のステップ: 分析\n次に実行すべきツールを選択してください。"
    )
    
    request_id: bytes32
    request_id = oracle_interface.request_llm_completion(
        prompt, 
        address, 
        method_id("process_llm_analyze_callback(bytes32,bytes32,String[1024])")
    )
    
    # リクエストIDを保存
    current_request_id = request_id
    agent_loop_states[task_id] = agent_loop

@external
def process_llm_analyze_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert sender == address(oracle_interface), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    assert current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    _agent_loop_select_tool(task_id, result)

@internal
def _agent_loop_select_tool(task_id: bytes32, analysis_result: String[1024]):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    current_step = AGENT_STEP_SELECT_TOOL
    last_updated = timestamp
    agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_SELECT_TOOL, 
        current_tool, 
        iteration_count, 
        timestamp
    )
    
    # LLMにツール選択を依頼
    task: TaskInfo
    task = tasks[task_id]
    
    prompt: String[1024]
    prompt = concat(
        "タスク: ", 
        prompt, 
        "\n\n分析結果: ", 
        analysis_result,
        "\n\n現在のステップ: ツール選択\n利用可能なツール: LLM, MCP, Chainlink, Fileverse\n最適なツールを選択してください。"
    )
    
    request_id: bytes32
    request_id = oracle_interface.request_llm_completion(
        prompt, 
        address, 
        method_id("process_llm_select_tool_callback(bytes32,bytes32,String[1024])")
    )
    
    # リクエストIDを保存
    current_request_id = request_id
    agent_loop_states[task_id] = agent_loop

@external
def process_llm_select_tool_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert sender == address(oracle_interface), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    assert current_request_id == request_id, "Invalid request ID"
    
    # 選択されたツールを保存
    current_tool = result
    agent_loop_states[task_id] = agent_loop
    
    # 次のステップに進む
    _agent_loop_execute_tool(task_id, result)

@internal
def _agent_loop_execute_tool(task_id: bytes32, selected_tool: String[1024]):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    current_step = AGENT_STEP_WAIT_EXECUTION
    last_updated = timestamp
    agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_WAIT_EXECUTION, 
        current_tool, 
        iteration_count, 
        timestamp
    )
    
    # タスク情報を取得
    task: TaskInfo
    task = tasks[task_id]
    
    # ツールに基づいて実行
    if "LLM" in selected_tool:
        # LLMツールを実行
        request_id: bytes32
        request_id = oracle_interface.request_llm_completion(
            prompt, 
            address, 
            method_id("process_llm_execution_callback(bytes32,bytes32,String[1024])")
        )
        current_request_id = request_id
        agent_loop_states[task_id] = agent_loop
        
    elif "MCP" in selected_tool:
        # MCPツールを実行
        request_id: bytes32
        request_id = mcp_integration.request_mcp_action(
            0,  # Firefox
            prompt, 
            address, 
            method_id("process_mcp_execution_callback(bytes32,bytes32,String[1024])")
        )
        current_request_id = request_id
        agent_loop_states[task_id] = agent_loop
        
    elif "Chainlink" in selected_tool:
        # Chainlinkツールを実行
        request_id: bytes32
        request_id = chainlink_mcp.request_code_execution(
            prompt, 
            "python", 
            address, 
            method_id("process_chainlink_execution_callback(bytes32,bytes32,String[1024])")
        )
        current_request_id = request_id
        agent_loop_states[task_id] = agent_loop
        
    elif "Fileverse" in selected_tool:
        # Fileverseツールを実行
        request_id: bytes32
        request_id = fileverse_integration.store_file(
            prompt, 
            "txt", 
            "text/plain", 
            address, 
            method_id("process_fileverse_execution_callback(bytes32,bytes32,String[256])")
        )
        current_request_id = request_id
        agent_loop_states[task_id] = agent_loop
        
    else:
        # 不明なツールの場合はLLMにフォールバック
        request_id: bytes32
        request_id = oracle_interface.request_llm_completion(
            prompt, 
            address, 
            method_id("process_llm_execution_callback(bytes32,bytes32,String[1024])")
        )
        current_request_id = request_id
        agent_loop_states[task_id] = agent_loop

# 各ツールからのコールバック処理
@external
def process_llm_execution_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert sender == address(oracle_interface), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    assert current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    _agent_loop_iterate(task_id, result)

@external
def process_mcp_execution_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert sender == address(mcp_integration), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    assert current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    _agent_loop_iterate(task_id, result)

@external
def process_chainlink_execution_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert sender == address(chainlink_mcp), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    assert current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    _agent_loop_iterate(task_id, result)

@external
def process_fileverse_execution_callback(request_id: bytes32, task_id: bytes32, file_url: String[256]):
    # コールバックの検証
    assert sender == address(fileverse_integration), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    assert current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    _agent_loop_iterate(task_id, file_url)

@internal
def _agent_loop_iterate(task_id: bytes32, execution_result: String[1024]):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState
    agent_loop = agent_loop_states[task_id]
    current_step = AGENT_STEP_ITERATE
    iteration_count += 1
    last_updated = timestamp
    agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_ITERATE, 
        current_tool, 
        iteration_count, 
        timestamp
    )
    
    # 実行結果をメモリに保存
    memory_id: bytes32
    memory_id = memory_storage.store_memory(
        execution_result,
        1,  # 優先度: 中
        [current_tool, convert(iteration_count, String[32])]
    )
    
    # 反復回数が一定以上、または結果が十分な場合は完了
    if iteration_count >= 5 or len(execution_result) > 500:
        _agent_loop_submit_results(task_id, execution_result, [memory_id])
    else:
        # 次の分析ステップに戻る
        _agent_loop_analyze(task_id)

@internal
def _agent_loop_submit_results(task_id: bytes32, final_result: String[1024], memory_ids: DynArray[bytes32, 10]):
    pass
    # エージェントループ状態を<response clipped><NOTE>To save on context only part of this file has been shown to you. You should retry this tool after you have searched inside the file with `grep -n` in order to find the line numbers of what you are looking for.</NOTE>