# Myrdalエージェント - データモデル設計

## 1. スマートコントラクトのデータ構造

### 1.1 MyrdalCore

```vyper
# タスク情報
struct TaskInfo:
    id: bytes32
    user: address
    prompt: String[1024]
    status: uint8  # 0: 未処理, 1: 処理中, 2: 完了, 3: エラー
    created_at: uint256
    completed_at: uint256
    result_id: bytes32
    privacy_level: uint8

# タスク結果
struct TaskResult:
    id: bytes32
    content: String[1024]
    file_urls: DynArray[String[256], 10]
    memory_ids: DynArray[bytes32, 10]

# エージェントループ状態
struct AgentLoopState:
    current_step: uint8  # 1: 分析, 2: ツール選択, 3: 実行待ち, 4: 反復, 5: 結果提出, 6: 待機
    current_tool: String[64]
    current_request_id: bytes32
    iteration_count: uint256
    last_updated: uint256
```

### 1.2 MemoryStorage

```vyper
# メモリエントリ
struct MemoryEntry:
    id: bytes32
    user: address
    content: String[1024]
    encrypted_content: bytes
    is_encrypted: bool
    priority: uint8
    created_at: uint256
    last_accessed: uint256
    access_count: uint256
    tags: DynArray[String[32], 10]
```

### 1.3 OracleInterface

```vyper
# LLMリクエスト
struct LLMRequest:
    id: bytes32
    user: address
    prompt: String[1024]
    callback_address: address
    callback_function_selector: bytes4
    created_at: uint256
    fulfilled: bool
    result: String[1024]
```

### 1.4 MCPIntegration

```vyper
# MCPリクエスト
struct MCPRequest:
    id: bytes32
    user: address
    server_id: uint256  # 0: Firefox, 1: pyppeteer, 2+: その他
    action_data: String[1024]
    callback_address: address
    callback_function_selector: bytes4
    created_at: uint256
    fulfilled: bool
    result: String[1024]
```

### 1.5 ChainlinkMCP

```vyper
# Chainlinkコード実行リクエスト
struct ChainlinkRequest:
    id: bytes32
    user: address
    code: String[1024]
    language: String[32]  # "python", "javascript", etc.
    callback_address: address
    callback_function_selector: bytes4
    created_at: uint256
    fulfilled: bool
    result: String[1024]
```

### 1.6 FileverseIntegration

```vyper
# Fileverseファイル保存リクエスト
struct FileverseRequest:
    id: bytes32
    user: address
    file_hash: bytes32
    file_name: String[256]
    file_type: String[64]
    callback_address: address
    callback_function_selector: bytes4
    created_at: uint256
    fulfilled: bool
    file_url: String[256]
```

### 1.7 UserAuth

```vyper
# ユーザー情報
struct UserInfo:
    user: address
    active: bool
    privacy_level: uint8
    balance: uint256
    created_at: uint256
    last_active: uint256
    task_count: uint256
```

## 2. オフチェーンデータ構造

### 2.1 MCPサーバー

```python
# MCPリクエスト
class MCPRequest:
    def __init__(self, request_id, action_type, action_data):
        self.request_id = request_id  # bytes32
        self.action_type = action_type  # str: "navigate", "click", "input", etc.
        self.action_data = action_data  # dict: {"url": "...", "selector": "...", etc.}
        self.created_at = time.time()
        self.status = "pending"  # "pending", "processing", "completed", "error"
        self.result = None

# MCPレスポンス
class MCPResponse:
    def __init__(self, request_id, success, data=None, error=None):
        self.request_id = request_id  # bytes32
        self.success = success  # bool
        self.data = data  # dict: {"content": "...", "screenshot": "...", etc.}
        self.error = error  # str
        self.completed_at = time.time()
```

### 2.2 Chainlinkアダプター

```python
# Chainlinkリクエスト
class ChainlinkRequest:
    def __init__(self, request_id, code, language):
        self.request_id = request_id  # bytes32
        self.code = code  # str
        self.language = language  # str: "python", "javascript", etc.
        self.created_at = time.time()
        self.status = "pending"  # "pending", "processing", "completed", "error"
        self.result = None
        self.logs = []

# Chainlinkレスポンス
class ChainlinkResponse:
    def __init__(self, request_id, success, output=None, error=None):
        self.request_id = request_id  # bytes32
        self.success = success  # bool
        self.output = output  # str
        self.error = error  # str
        self.execution_time = 0  # float: seconds
        self.completed_at = time.time()
```

### 2.3 Fileverseアップローダー

```python
# Fileverseリクエスト
class FileverseRequest:
    def __init__(self, request_id, file_content, file_name, file_type):
        self.request_id = request_id  # bytes32
        self.file_content = file_content  # bytes
        self.file_name = file_name  # str
        self.file_type = file_type  # str: "text/plain", "application/pdf", etc.
        self.file_hash = None  # bytes32
        self.created_at = time.time()
        self.status = "pending"  # "pending", "uploading", "completed", "error"

# Fileverseレスポンス
class FileverseResponse:
    def __init__(self, request_id, success, file_url=None, error=None):
        self.request_id = request_id  # bytes32
        self.success = success  # bool
        self.file_url = file_url  # str
        self.error = error  # str
        self.completed_at = time.time()
```

## 3. イベントとコールバック

### 3.1 MyrdalCore

```vyper
# イベント
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

# コールバック
@external
def process_llm_callback(request_id: bytes32, result: String[1024]):
    # LLMからの結果を処理

@external
def process_mcp_callback(request_id: bytes32, result: String[1024]):
    # MCPからの結果を処理

@external
def process_chainlink_callback(request_id: bytes32, result: String[1024]):
    # Chainlinkからの結果を処理

@external
def process_fileverse_callback(request_id: bytes32, file_url: String[256]):
    # Fileverseからの結果を処理
```

### 3.2 MemoryStorage

```vyper
# イベント
event MemoryStored:
    memory_id: indexed(bytes32)
    user: indexed(address)
    priority: uint8
    created_at: uint256

event MemoryAccessed:
    memory_id: indexed(bytes32)
    user: indexed(address)
    accessed_at: uint256

event MemoryDeleted:
    memory_id: indexed(bytes32)
    user: indexed(address)
    deleted_at: uint256
```

### 3.3 OracleInterface

```vyper
# イベント
event LLMRequestCreated:
    request_id: indexed(bytes32)
    user: indexed(address)
    created_at: uint256

event LLMRequestFulfilled:
    request_id: indexed(bytes32)
    fulfilled_at: uint256
```

### 3.4 MCPIntegration

```vyper
# イベント
event MCPRequestCreated:
    request_id: indexed(bytes32)
    user: indexed(address)
    server_id: uint256
    created_at: uint256

event MCPRequestFulfilled:
    request_id: indexed(bytes32)
    fulfilled_at: uint256
```

### 3.5 ChainlinkMCP

```vyper
# イベント
event ChainlinkRequestCreated:
    request_id: indexed(bytes32)
    user: indexed(address)
    language: String[32]
    created_at: uint256

event ChainlinkRequestFulfilled:
    request_id: indexed(bytes32)
    fulfilled_at: uint256
```

### 3.6 FileverseIntegration

```vyper
# イベント
event FileverseRequestCreated:
    request_id: indexed(bytes32)
    user: indexed(address)
    file_hash: bytes32
    created_at: uint256

event FileverseRequestFulfilled:
    request_id: indexed(bytes32)
    file_url: String[256]
    fulfilled_at: uint256
```
