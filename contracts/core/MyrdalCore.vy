# @version ^0.3.7

"""
@title MyrdalCore - Oasis Protocol上の汎用AIエージェントコア
@author Myrdal Team
@notice このコントラクトはOasis Protocolの「Sapphire」パラタイムを活用した
       機密スマートコントラクトとして実装されています
"""

# インターフェースのインポート
from vyper.interfaces import ERC20
import interfaces.IMemoryStorage as IMemoryStorage
import interfaces.IOracleInterface as IOracleInterface
import interfaces.IMCPIntegration as IMCPIntegration
import interfaces.IChainlinkMCP as IChainlinkMCP
import interfaces.IFileverseIntegration as IFileverseIntegration
import interfaces.IUserAuth as IUserAuth

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
@external
def __init__(
    _memory_storage: address,
    _oracle_interface: address,
    _mcp_integration: address,
    _chainlink_mcp: address,
    _fileverse_integration: address,
    _user_auth: address
):
    self.owner = msg.sender
    self.paused = False
    
    self.memory_storage = IMemoryStorage(_memory_storage)
    self.oracle_interface = IOracleInterface(_oracle_interface)
    self.mcp_integration = IMCPIntegration(_mcp_integration)
    self.chainlink_mcp = IChainlinkMCP(_chainlink_mcp)
    self.fileverse_integration = IFileverseIntegration(_fileverse_integration)
    self.user_auth = IUserAuth(_user_auth)
    
    self.next_task_id = 1
    self.next_result_id = 1

# 修飾子
@internal
def _only_owner() -> bool:
    assert msg.sender == self.owner, "Only owner"
    return True

@internal
def _not_paused() -> bool:
    assert not self.paused, "Contract is paused"
    return True

@internal
def _only_task_owner(task_id: bytes32) -> bool:
    assert self.tasks[task_id].user == msg.sender, "Not task owner"
    return True

# 管理者機能
@external
def set_memory_storage(_memory_storage: address):
    self._only_owner()
    self.memory_storage = IMemoryStorage(_memory_storage)

@external
def set_oracle_interface(_oracle_interface: address):
    self._only_owner()
    self.oracle_interface = IOracleInterface(_oracle_interface)

@external
def set_mcp_integration(_mcp_integration: address):
    self._only_owner()
    self.mcp_integration = IMCPIntegration(_mcp_integration)

@external
def set_chainlink_mcp(_chainlink_mcp: address):
    self._only_owner()
    self.chainlink_mcp = IChainlinkMCP(_chainlink_mcp)

@external
def set_fileverse_integration(_fileverse_integration: address):
    self._only_owner()
    self.fileverse_integration = IFileverseIntegration(_fileverse_integration)

@external
def set_user_auth(_user_auth: address):
    self._only_owner()
    self.user_auth = IUserAuth(_user_auth)

@external
def pause():
    self._only_owner()
    self.paused = True

@external
def unpause():
    self._only_owner()
    self.paused = False

# タスク管理機能
@external
def create_task(prompt: String[1024]) -> bytes32:
    self._not_paused()
    
    # ユーザー認証
    assert self.user_auth.authenticate_user(msg.sender), "Authentication failed"
    
    # タスクIDを生成
    task_id: bytes32 = keccak256(concat(
        convert(msg.sender, bytes32),
        convert(block.timestamp, bytes32),
        convert(self.next_task_id, bytes32)
    ))
    
    # プライバシーレベルを取得
    privacy_level: uint8 = self.user_auth.get_privacy_level(msg.sender)
    
    # タスク情報を保存
    self.tasks[task_id] = TaskInfo({
        id: task_id,
        user: msg.sender,
        prompt: prompt,
        status: TASK_STATUS_PENDING,
        created_at: block.timestamp,
        completed_at: 0,
        result_id: empty(bytes32),
        privacy_level: privacy_level
    })
    
    # エージェントループ状態を初期化
    self.agent_loop_states[task_id] = AgentLoopState({
        current_step: AGENT_STEP_ANALYZE,
        current_tool: "",
        current_request_id: empty(bytes32),
        iteration_count: 0,
        last_updated: block.timestamp
    })
    
    # ユーザーのタスクリストに追加
    user_task_list: DynArray[bytes32, 100] = self.user_tasks[msg.sender]
    user_task_list.append(task_id)
    self.user_tasks[msg.sender] = user_task_list
    
    self.next_task_id += 1
    
    # タスク作成イベントを発行
    log TaskCreated(task_id, msg.sender, prompt, block.timestamp)
    
    # タスク処理を開始
    self._process_task(task_id)
    
    return task_id

@internal
def _process_task(task_id: bytes32):
    # タスクステータスを処理中に更新
    self.tasks[task_id].status = TASK_STATUS_PROCESSING
    log TaskStatusUpdated(task_id, TASK_STATUS_PROCESSING, block.timestamp)
    
    # エージェントループを開始
    self._agent_loop_analyze(task_id)

@external
def cancel_task(task_id: bytes32) -> bool:
    self._only_task_owner(task_id)
    
    # 完了済みタスクはキャンセル不可
    assert self.tasks[task_id].status != TASK_STATUS_COMPLETED, "Task already completed"
    
    # タスクステータスをエラーに更新
    self.tasks[task_id].status = TASK_STATUS_ERROR
    log TaskStatusUpdated(task_id, TASK_STATUS_ERROR, block.timestamp)
    
    return True

@external
def get_task_status(task_id: bytes32) -> uint8:
    return self.tasks[task_id].status

@external
def get_task_result(task_id: bytes32) -> (String[1024], DynArray[String[256], 10], DynArray[bytes32, 10]):
    self._only_task_owner(task_id)
    
    # タスクが完了していることを確認
    assert self.tasks[task_id].status == TASK_STATUS_COMPLETED, "Task not completed"
    
    result_id: bytes32 = self.tasks[task_id].result_id
    result: TaskResult = self.task_results[result_id]
    
    return result.content, result.file_urls, result.memory_ids

# エージェントループ実装
@internal
def _agent_loop_analyze(task_id: bytes32):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    agent_loop.current_step = AGENT_STEP_ANALYZE
    agent_loop.last_updated = block.timestamp
    self.agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_ANALYZE, 
        agent_loop.current_tool, 
        agent_loop.iteration_count, 
        block.timestamp
    )
    
    # タスク情報を取得
    task: TaskInfo = self.tasks[task_id]
    
    # LLMにタスク分析を依頼
    prompt: String[1024] = concat(
        "タスク分析: ", 
        task.prompt, 
        "\n\n現在のステップ: 分析\n次に実行すべきツールを選択してください。"
    )
    
    request_id: bytes32 = self.oracle_interface.request_llm_completion(
        prompt, 
        self.address, 
        method_id("process_llm_analyze_callback(bytes32,bytes32,String[1024])")
    )
    
    # リクエストIDを保存
    agent_loop.current_request_id = request_id
    self.agent_loop_states[task_id] = agent_loop

@external
def process_llm_analyze_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert msg.sender == address(self.oracle_interface), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    assert agent_loop.current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    self._agent_loop_select_tool(task_id, result)

@internal
def _agent_loop_select_tool(task_id: bytes32, analysis_result: String[1024]):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    agent_loop.current_step = AGENT_STEP_SELECT_TOOL
    agent_loop.last_updated = block.timestamp
    self.agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_SELECT_TOOL, 
        agent_loop.current_tool, 
        agent_loop.iteration_count, 
        block.timestamp
    )
    
    # LLMにツール選択を依頼
    task: TaskInfo = self.tasks[task_id]
    
    prompt: String[1024] = concat(
        "タスク: ", 
        task.prompt, 
        "\n\n分析結果: ", 
        analysis_result,
        "\n\n現在のステップ: ツール選択\n利用可能なツール: LLM, MCP, Chainlink, Fileverse\n最適なツールを選択してください。"
    )
    
    request_id: bytes32 = self.oracle_interface.request_llm_completion(
        prompt, 
        self.address, 
        method_id("process_llm_select_tool_callback(bytes32,bytes32,String[1024])")
    )
    
    # リクエストIDを保存
    agent_loop.current_request_id = request_id
    self.agent_loop_states[task_id] = agent_loop

@external
def process_llm_select_tool_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert msg.sender == address(self.oracle_interface), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    assert agent_loop.current_request_id == request_id, "Invalid request ID"
    
    # 選択されたツールを保存
    agent_loop.current_tool = result
    self.agent_loop_states[task_id] = agent_loop
    
    # 次のステップに進む
    self._agent_loop_execute_tool(task_id, result)

@internal
def _agent_loop_execute_tool(task_id: bytes32, selected_tool: String[1024]):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    agent_loop.current_step = AGENT_STEP_WAIT_EXECUTION
    agent_loop.last_updated = block.timestamp
    self.agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_WAIT_EXECUTION, 
        agent_loop.current_tool, 
        agent_loop.iteration_count, 
        block.timestamp
    )
    
    # タスク情報を取得
    task: TaskInfo = self.tasks[task_id]
    
    # ツールに基づいて実行
    if "LLM" in selected_tool:
        # LLMツールを実行
        request_id: bytes32 = self.oracle_interface.request_llm_completion(
            task.prompt, 
            self.address, 
            method_id("process_llm_execution_callback(bytes32,bytes32,String[1024])")
        )
        agent_loop.current_request_id = request_id
        self.agent_loop_states[task_id] = agent_loop
        
    elif "MCP" in selected_tool:
        # MCPツールを実行
        request_id: bytes32 = self.mcp_integration.request_mcp_action(
            0,  # Firefox
            task.prompt, 
            self.address, 
            method_id("process_mcp_execution_callback(bytes32,bytes32,String[1024])")
        )
        agent_loop.current_request_id = request_id
        self.agent_loop_states[task_id] = agent_loop
        
    elif "Chainlink" in selected_tool:
        # Chainlinkツールを実行
        request_id: bytes32 = self.chainlink_mcp.request_code_execution(
            task.prompt, 
            "python", 
            self.address, 
            method_id("process_chainlink_execution_callback(bytes32,bytes32,String[1024])")
        )
        agent_loop.current_request_id = request_id
        self.agent_loop_states[task_id] = agent_loop
        
    elif "Fileverse" in selected_tool:
        # Fileverseツールを実行
        request_id: bytes32 = self.fileverse_integration.store_file(
            task.prompt, 
            "result.txt", 
            "text/plain", 
            self.address, 
            method_id("process_fileverse_execution_callback(bytes32,bytes32,String[256])")
        )
        agent_loop.current_request_id = request_id
        self.agent_loop_states[task_id] = agent_loop
        
    else:
        # 不明なツールの場合はLLMにフォールバック
        request_id: bytes32 = self.oracle_interface.request_llm_completion(
            task.prompt, 
            self.address, 
            method_id("process_llm_execution_callback(bytes32,bytes32,String[1024])")
        )
        agent_loop.current_request_id = request_id
        self.agent_loop_states[task_id] = agent_loop

# 各ツールからのコールバック処理
@external
def process_llm_execution_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert msg.sender == address(self.oracle_interface), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    assert agent_loop.current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    self._agent_loop_iterate(task_id, result)

@external
def process_mcp_execution_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert msg.sender == address(self.mcp_integration), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    assert agent_loop.current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    self._agent_loop_iterate(task_id, result)

@external
def process_chainlink_execution_callback(request_id: bytes32, task_id: bytes32, result: String[1024]):
    # コールバックの検証
    assert msg.sender == address(self.chainlink_mcp), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    assert agent_loop.current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    self._agent_loop_iterate(task_id, result)

@external
def process_fileverse_execution_callback(request_id: bytes32, task_id: bytes32, file_url: String[256]):
    # コールバックの検証
    assert msg.sender == address(self.fileverse_integration), "Invalid caller"
    
    # エージェントループ状態を取得
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    assert agent_loop.current_request_id == request_id, "Invalid request ID"
    
    # 次のステップに進む
    self._agent_loop_iterate(task_id, file_url)

@internal
def _agent_loop_iterate(task_id: bytes32, execution_result: String[1024]):
    # エージェントループ状態を更新
    agent_loop: AgentLoopState = self.agent_loop_states[task_id]
    agent_loop.current_step = AGENT_STEP_ITERATE
    agent_loop.iteration_count += 1
    agent_loop.last_updated = block.timestamp
    self.agent_loop_states[task_id] = agent_loop
    
    log AgentLoopUpdated(
        task_id, 
        AGENT_STEP_ITERATE, 
        agent_loop.current_tool, 
        agent_loop.iteration_count, 
        block.timestamp
    )
    
    # 実行結果をメモリに保存
    memory_id: bytes32 = self.memory_storage.store_memory(
        execution_result,
        1,  # 優先度: 中
        [agent_loop.current_tool, convert(agent_loop.iteration_count, String[32])]
    )
    
    # 反復回数が一定以上、または結果が十分な場合は完了
    if agent_loop.iteration_count >= 5 or len(execution_result) > 500:
        self._agent_loop_submit_results(task_id, execution_result, [memory_id])
    else:
        # 次の分析ステップに戻る
        self._agent_loop_analyze(task_id)

@internal
def _agent_loop_submit_results(task_id: bytes32, final_result: String[1024], memory_ids: DynArray[bytes32, 10]):
    # エージェントループ状態を<response clipped><NOTE>To save on context only part of this file has been shown to you. You should retry this tool after you have searched inside the file with `grep -n` in order to find the line numbers of what you are looking for.</NOTE>