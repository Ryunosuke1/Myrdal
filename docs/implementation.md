# Oasis Protocol AIエージェント実装ドキュメント

## 概要

このドキュメントでは、Oasis Protocol上でデプロイする汎用AIエージェントの実装について説明します。このエージェントは、長期記憶機能を持ち、コーディングからAmazonでの買い物、オンライン動画での調べ物まで幅広いタスクを実行できる汎用AIエージェントです。

Oasis Protocolのプライバシー機能を活用し、ユーザーの依頼内容や結果が公開されないよう設計されています。また、Model Context Protocol (MCP)を使用してFirefoxブラウザを操作する機能も実装しています。

## システムアーキテクチャ

システムは以下の主要コンポーネントで構成されています：

### オンチェーンコンポーネント（Vyperで実装）

1. **AgentCore.vy**：エージェントの中核となるコントラクトで、ユーザーからのリクエスト処理、タスク管理、LLMとの連携、MCPとの連携を担当します。

2. **MemoryStorage.vy**：長期記憶を管理するコントラクトで、ユーザーとの対話履歴や学習した情報を暗号化して保存します。タグベースの検索機能も実装しています。

3. **OracleInterface.vy**：外部のLLMサービスと連携するためのオラクルコントラクトで、プロンプトの送信と結果の受信を管理します。

4. **MCPIntegration.vy**：Model Context Protocolとの連携を行うコントラクトで、Firefox操作やpyppeteerなどの外部操作を可能にします。

5. **UserAuth.vy**：ユーザー認証と権限管理を行うコントラクトで、プライバシーレベルの設定や支払い処理も担当します。

### オフチェーンコンポーネント

1. **firefox_mcp_server.py**：Seleniumを使用してFirefoxブラウザを操作するMCPサーバーです。WebSocketインターフェースを提供し、ナビゲーション、クリック、テキスト入力、スクリーンショット撮影などの操作が可能です。

2. **pyppeteer_mcp_server.py**：pyppeteerを使用してChromiumブラウザを操作するMCPサーバーです。より高度なブラウザ自動化機能を提供し、Firefox MCPサーバーと同様のインターフェースを持ちます。

3. **mcp_oracle.py**：スマートコントラクトとMCPサーバーを連携するオラクルです。ブロックチェーン上のイベントをリッスンし、適切なMCPサーバーにリクエストを転送して結果をスマートコントラクトに返します。

## 実装詳細

### Vyperスマートコントラクト

#### AgentCore.vy

エージェントの中核となるコントラクトで、以下の主要機能を提供します：

- `create_task(prompt: String[1024]) -> bytes32`：新しいタスクを作成します
- `get_task(task_id: bytes32) -> TaskInfo`：タスクの情報を取得します
- `process_task(task_id: bytes32) -> bool`：タスクを処理します
- `get_task_result(task_id: bytes32) -> String[1024]`：タスク結果を取得します
- `get_user_tasks(user: address) -> DynArray[bytes32, 100]`：ユーザーのタスク一覧を取得します

内部的には、LLMサービスとMCPサーバーとの連携を行うコールバック関数も実装しています：

- `process_llm_callback(request_id: bytes32, result: String[1024])`
- `process_mcp_callback(request_id: bytes32, result: String[1024])`

#### MemoryStorage.vy

長期記憶を管理するコントラクトで、以下の主要機能を提供します：

- `store_memory(content: String[1024], priority: uint8, tags: DynArray[String[32], 10], encrypt: bool) -> bytes32`：新しいメモリを保存します
- `get_memory(memory_id: bytes32) -> MemoryEntry`：メモリを取得します
- `search_by_tags(tags: DynArray[String[32], 10]) -> DynArray[bytes32, 100]`：タグでメモリを検索します
- `get_user_memories(user: address) -> DynArray[bytes32, 100]`：ユーザーのメモリ一覧を取得します
- `update_priority(memory_id: bytes32, new_priority: uint8)`：メモリの優先度を更新します
- `delete_memory(memory_id: bytes32)`：メモリを削除します

#### OracleInterface.vy

外部のLLMサービスと連携するためのオラクルコントラクトで、以下の主要機能を提供します：

- `request_llm_completion(prompt: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32`：LLM完了リクエストを送信します
- `is_request_fulfilled(request_id: bytes32) -> bool`：リクエストが完了したかを確認します
- `get_request_result(request_id: bytes32) -> String[1024]`：リクエスト結果を取得します
- `fulfill_request(request_id: bytes32, result: String[1024])`：リクエストを完了します（オラクルが呼び出し）
- `cancel_request(request_id: bytes32)`：リクエストをキャンセルします

#### MCPIntegration.vy

Model Context Protocolとの連携を行うコントラクトで、以下の主要機能を提供します：

- `request_firefox_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32`：Firefox操作リクエストを送信します
- `request_pyppeteer_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32`：pyppeteer操作リクエストを送信します
- `request_mcp_action(server_id: uint256, action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32`：その他のMCPサーバーへのリクエストを送信します
- `is_request_fulfilled(request_id: bytes32) -> bool`：リクエストが完了したかを確認します
- `get_request_result(request_id: bytes32) -> String[1024]`：リクエスト結果を取得します
- `fulfill_request(request_id: bytes32, result: String[1024])`：リクエストを完了します（MCPオラクルが呼び出し）
- `cancel_request(request_id: bytes32)`：リクエストをキャンセルします

#### UserAuth.vy

ユーザー認証と権限管理を行うコントラクトで、以下の主要機能を提供します：

- `register_user(privacy_level: uint8) -> bool`：新しいユーザーを登録します
- `is_user_active(user: address) -> bool`：ユーザーがアクティブかを確認します
- `get_user_info(user: address) -> UserInfo`：ユーザー情報を取得します
- `update_privacy_level(new_privacy_level: uint8) -> bool`：プライバシーレベルを更新します
- `add_funds() -> bool`：資金を追加します（payable）
- `withdraw_funds(amount: uint256) -> bool`：資金を引き出します
- `deactivate_account() -> bool`：アカウントを無効化します
- `reactivate_account() -> bool`：アカウントを再有効化します

### MCPサーバー実装

#### firefox_mcp_server.py

Seleniumを使用してFirefoxブラウザを操作するMCPサーバーで、以下の主要機能を提供します：

- `navigate_to(url)`：指定URLに移動します
- `click_element(selector)`：要素をクリックします
- `input_text(selector, text)`：テキストを入力します
- `get_page_content()`：ページコンテンツを取得します
- `take_screenshot()`：スクリーンショットを撮影します
- `execute_script(script)`：JavaScriptを実行します

#### pyppeteer_mcp_server.py

pyppeteerを使用してChromiumブラウザを操作するMCPサーバーで、以下の主要機能を提供します：

- `navigate_to(url)`：指定URLに移動します
- `click_element(selector)`：要素をクリックします
- `input_text(selector, text)`：テキストを入力します
- `get_page_content()`：ページコンテンツを取得します
- `take_screenshot()`：スクリーンショットを撮影します
- `execute_script(script)`：JavaScriptを実行します
- `wait_for_selector(selector, timeout)`：セレクタが表示されるまで待機します
- `wait_for_navigation()`：ナビゲーション完了まで待機します

#### mcp_oracle.py

スマートコントラクトとMCPサーバーを連携するオラクルで、以下の主要機能を提供します：

- `listen_for_events()`：コントラクトイベントをリッスンします
- `process_event(event)`：イベントを処理します
- `execute_firefox_action(request_id, action_data)`：Firefox MCPサーバーでアクションを実行します
- `execute_pyppeteer_action(request_id, action_data)`：pyppeteer MCPサーバーでアクションを実行します
- `send_result_to_contract(request_id, result)`：結果をスマートコントラクトに送信します

### テストとデプロイ

#### test_agent.py

エージェントのテストスクリプトで、以下のテストを実行します：

- Oasis Protocolへの接続テスト
- エージェントコントラクトのテスト
- Firefox MCPサーバーのテスト
- pyppeteer MCPサーバーのテスト

#### deploy_contracts.py

Vyperスマートコントラクトをコンパイルしてデプロイするスクリプトで、以下の機能を提供します：

- Vyperコントラクトのコンパイル
- コントラクトのデプロイ
- デプロイ情報の保存

## プライバシー保護機能

Oasis Protocolの「Sapphire」パラタイムを活用し、以下のプライバシー保護機能を実装しています：

1. **エンドツーエンド暗号化**：ユーザーのリクエストと結果を暗号化
2. **機密計算**：コントラクト内の処理を機密環境で実行
3. **アクセス制御**：ユーザー自身のデータにのみアクセス可能な権限管理
4. **プライバシー保護ストレージ**：長期記憶データの暗号化保存

## 使用方法

### コントラクトのデプロイ

1. 秘密鍵を設定：`deploy_contracts.py`の`PRIVATE_KEY`変数を設定
2. デプロイスクリプトを実行：`python3 deploy_contracts.py`
3. デプロイ情報が`deployment_info.json`に保存されます

### MCPサーバーの起動

1. Firefox MCPサーバーを起動：`python3 firefox_mcp_server.py`
2. pyppeteer MCPサーバーを起動：`python3 pyppeteer_mcp_server.py`
3. MCPオラクルを起動：`python3 mcp_oracle.py`

### エージェントの使用

1. AgentCoreコントラクトの`create_task`関数を呼び出してタスクを作成
2. `get_task`関数でタスクのステータスを確認
3. タスクが完了したら`get_task_result`関数で結果を取得

## 今後の展望

1. **UI開発**：ユーザーフレンドリーなインターフェースの開発
2. **機能拡張**：より多くのMCPサーバーの追加（例：Amazon、YouTube専用のMCP）
3. **パフォーマンス最適化**：ガスコストの最適化とスケーラビリティの向上
4. **セキュリティ強化**：より高度な暗号化とプライバシー保護機能の実装
