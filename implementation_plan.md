# Myrdal Contract Implementation Plan

## Phase 1: 構造体の統一とインターフェース統合

### 1. 構造体の更新

#### TaskInfo
```vyper
struct TaskInfo:
    id: bytes32
    owner: address  # creatorからownerに変更
    prompt: String[1024]
    result: String[1024]
    created_at: uint256
    completed_at: uint256
    status: uint8
    mcp_requests: DynArray[bytes32, 10]
    memory_entries: DynArray[bytes32, 10]
    oracle_requests: DynArray[bytes32, 5]
```

#### MCPRequest
```vyper
struct MCPRequest:
    id: bytes32
    requester: address  # 追加
    task_id: bytes32
    action_type: uint8
    action_data: String[1024]
    callback_address: address  # 追加
    callback_function_selector: bytes4
    timestamp: uint256
    fulfilled: bool
    result: String[1024]
```

#### OracleRequest
```vyper
struct OracleRequest:
    id: bytes32
    requester: address  # 追加
    task_id: bytes32
    data: String[1024]
    callback_address: address  # 追加
    callback_function_selector: bytes4
    timestamp: uint256
    fulfilled: bool
    result: String[1024]
```

### 2. インターフェースのインポート有効化

```vyper
from interfaces import IAgentCore
from interfaces import IMCPIntegration
from interfaces import IMemoryStorage
from interfaces import IOracleInterface
```

### 3. 関数シグネチャの更新

#### MCP関連
- request_firefox_action: callback_addressパラメータの追加
- request_pyppeteer_action: callback_addressパラメータの追加
- 新規: request_mcp_action関数の追加
- 新規: cancel_request関数の追加

#### メモリ関連
- store_memory: パラメータの順序調整
- 新規: update_priority関数の追加
- 新規: delete_memory関数の追加

#### オラクル関連
- request_llm_completion: callback_addressパラメータの追加
- 新規: cancel_request関数の追加

## 実装手順

1. インターフェースのインポートを有効化
2. 構造体の定義を更新
3. 既存の関数シグネチャを更新
4. 新規関数を追加
5. エラーチェックとアクセス制御の追加
6. テストの更新と実行

## セキュリティ考慮事項

- コールバックアドレスの検証
- 適切なアクセス制御の実装
- 状態変更時のイベント発行
- リエントランシー対策

## 注意点

- 既存のデータ構造との後方互換性
- ガス最適化
- 適切なエラーメッセージ