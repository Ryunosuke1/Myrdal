# Myrdalエージェント - コンポーネント間連携フロー設計

## 1. 全体データフロー

```
ユーザー → MyrdalCore → [MemoryStorage, OracleInterface, MCPIntegration, ChainlinkMCP, FileverseIntegration] → 外部サービス
```

## 2. リクエスト処理フロー

### 2.1 タスク作成と処理
1. ユーザーがMyrdalCoreにタスクを送信
2. MyrdalCoreがタスクを分析し、必要なアクションを決定
3. タスク情報をMemoryStorageに保存
4. タスク処理を開始（非同期）
5. タスクIDをユーザーに返却

### 2.2 LLM連携フロー
1. MyrdalCoreがLLM処理が必要と判断
2. OracleInterfaceにプロンプトを送信
3. OracleInterfaceが外部LLMサービスにリクエスト
4. 結果を受け取り、MyrdalCoreにコールバック
5. MyrdalCoreが次のアクションを決定

### 2.3 MCP連携フロー
1. MyrdalCoreがブラウザ操作が必要と判断
2. MCPIntegrationに操作リクエストを送信
3. MCPIntegrationがMCPサーバーにリクエスト
4. 結果を受け取り、MyrdalCoreにコールバック
5. MyrdalCoreが次のアクションを決定

### 2.4 Chainlink連携フロー
1. MyrdalCoreがプログラミングタスクが必要と判断
2. ChainlinkMCPにコード実行リクエストを送信
3. ChainlinkMCPがChainlinkノードにリクエスト
4. 結果を受け取り、MyrdalCoreにコールバック
5. MyrdalCoreが次のアクションを決定

### 2.5 Fileverse連携フロー
1. MyrdalCoreが成果物の保存が必要と判断
2. FileverseIntegrationにファイル保存リクエストを送信
3. FileverseIntegrationがFileverseにファイルをアップロード
4. 結果（ファイルURL）を受け取り、MyrdalCoreにコールバック
5. MyrdalCoreがURLをユーザーに返却

## 3. コンポーネント間インターフェース

### 3.1 MyrdalCore ↔ MemoryStorage
```
MyrdalCore → MemoryStorage:
- store_memory(content, priority, tags, encrypt)
- get_memory(memory_id)
- search_by_tags(tags)
- get_user_memories(user)
- update_priority(memory_id, new_priority)
- delete_memory(memory_id)

MemoryStorage → MyrdalCore:
- memory_stored(memory_id)
```

### 3.2 MyrdalCore ↔ OracleInterface
```
MyrdalCore → OracleInterface:
- request_llm_completion(prompt, callback_address, callback_function_selector)
- is_request_fulfilled(request_id)
- get_request_result(request_id)
- cancel_request(request_id)

OracleInterface → MyrdalCore:
- process_llm_callback(request_id, result)
```

### 3.3 MyrdalCore ↔ MCPIntegration
```
MyrdalCore → MCPIntegration:
- request_firefox_action(action_data, callback_address, callback_function_selector)
- request_pyppeteer_action(action_data, callback_address, callback_function_selector)
- request_mcp_action(server_id, action_data, callback_address, callback_function_selector)
- is_request_fulfilled(request_id)
- get_request_result(request_id)
- cancel_request(request_id)

MCPIntegration → MyrdalCore:
- process_mcp_callback(request_id, result)
```

### 3.4 MyrdalCore ↔ ChainlinkMCP
```
MyrdalCore → ChainlinkMCP:
- request_code_execution(code, language, callback_address, callback_function_selector)
- is_request_fulfilled(request_id)
- get_request_result(request_id)
- cancel_request(request_id)

ChainlinkMCP → MyrdalCore:
- process_chainlink_callback(request_id, result)
```

### 3.5 MyrdalCore ↔ FileverseIntegration
```
MyrdalCore → FileverseIntegration:
- store_file(file_content, file_name, file_type, callback_address, callback_function_selector)
- get_file_url(file_id)
- is_request_fulfilled(request_id)
- cancel_request(request_id)

FileverseIntegration → MyrdalCore:
- process_fileverse_callback(request_id, file_url)
```

## 4. エージェントループの実装

### 4.1 イベント分析
```
function analyze_events(task_id: bytes32) -> EventAnalysisResult:
    task = get_task(task_id)
    user_messages = get_user_messages(task_id)
    execution_results = get_execution_results(task_id)
    return analyze(task, user_messages, execution_results)
```

### 4.2 ツール選択
```
function select_tool(task_id: bytes32, analysis: EventAnalysisResult) -> ToolSelection:
    available_tools = get_available_tools()
    task_planning = get_task_planning(task_id)
    relevant_knowledge = get_relevant_knowledge(analysis)
    return select_optimal_tool(analysis, available_tools, task_planning, relevant_knowledge)
```

### 4.3 実行待ち
```
function wait_for_execution(task_id: bytes32, tool_selection: ToolSelection) -> ExecutionResult:
    request_id = execute_tool(tool_selection)
    while not is_request_fulfilled(request_id):
        wait(POLLING_INTERVAL)
    return get_request_result(request_id)
```

### 4.4 反復
```
function iterate(task_id: bytes32):
    while not is_task_completed(task_id):
        analysis = analyze_events(task_id)
        tool = select_tool(task_id, analysis)
        result = wait_for_execution(task_id, tool)
        add_execution_result(task_id, result)
```

### 4.5 結果提出
```
function submit_results(task_id: bytes32):
    results = compile_results(task_id)
    deliverables = prepare_deliverables(task_id)
    send_message_to_user(results, deliverables)
```

### 4.6 待機
```
function enter_standby(task_id: bytes32):
    mark_task_completed(task_id)
    wait_for_new_tasks()
```
