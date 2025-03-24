# Myrdal AIエージェント アーキテクチャ設計

## 概要

Myrdalは、Oasis Protocolのプライバシー機能を活用した汎用AIエージェントです。長期記憶機能を持ち、コーディングからAmazonでの買い物、オンライン動画での調べ物まで幅広いタスクを実行できます。Chainlinkとの統合によりMCPを実行でき、成果物はFileverseで提供します。

## システムアーキテクチャ

Myrdalのシステムは以下の主要コンポーネントで構成されています：

### 1. オンチェーンコンポーネント（Vyperで実装）

#### コアコントラクト
- **MyrdalCore.vy**: エージェントの中核となるコントラクト。ユーザーからのリクエスト処理、タスク管理、LLMとの連携、MCPとの連携を担当。
- **MemoryStorage.vy**: 長期記憶を管理するコントラクト。ユーザーとの対話履歴や学習した情報を暗号化して保存。
- **UserAuth.vy**: ユーザー認証と権限管理を行うコントラクト。プライバシーレベルの設定や支払い処理も担当。

#### オラクルとMCP連携
- **OracleInterface.vy**: 外部のLLMサービスと連携するためのオラクルコントラクト。
- **MCPIntegration.vy**: Model Context Protocolとの連携を行うコントラクト。Firefox操作やpyppeteerなどの外部操作を可能に。
- **ChainlinkMCP.vy**: Chainlinkを介してMCPを実行するためのコントラクト。

#### Fileverse連携
- **FileverseIntegration.vy**: 成果物をFileverseで提供するためのコントラクト。

### 2. オフチェーンコンポーネント

#### MCPサーバー
- **firefox_mcp_server.py**: Seleniumを使用してFirefoxブラウザを操作するMCPサーバー。
- **pyppeteer_mcp_server.py**: pyppeteerを使用してChromiumブラウザを操作するMCPサーバー。
- **mcp_oracle.py**: スマートコントラクトとMCPサーバーを連携するオラクル。

#### Chainlink統合
- **chainlink_adapter.py**: Chainlinkノードと連携するアダプター。
- **chainlink_job_spec.json**: Chainlinkジョブ仕様。

#### Fileverse連携
- **fileverse_uploader.py**: Fileverseにファイルをアップロードするモジュール。
- **fileverse_manager.py**: Fileverseでのファイル管理を行うモジュール。

### 3. エージェントループ実装

Myrdalは以下の6つのステップからなるエージェントループを実装します：

1. **イベント分析**: ユーザーからのメッセージやツールの実行結果を分析
2. **ツール選択**: 最適なツールを戦略的に選択
3. **実行待ち**: 選択されたツールが実行環境で実行
4. **反復**: 上記のステップを繰り返し
5. **結果提出**: ユーザーに結果を報告
6. **待機**: 次のタスクに備えて待機

## データフロー

1. ユーザーがMyrdalCoreコントラクトにタスクを送信
2. MyrdalCoreがタスクを分析し、必要なアクションを決定
3. 必要に応じてLLMサービスにプロンプトを送信（OracleInterface経由）
4. ブラウザ操作が必要な場合、MCPIntegrationを通じてMCPサーバーにリクエスト
5. プログラミングタスクの場合、ChainlinkMCPを通じてChainlinkノードにリクエスト
6. 成果物が生成されたら、FileverseIntegrationを通じてFileverseにアップロード
7. 結果をユーザーに返却

## セキュリティとプライバシー

Oasis Protocolの「Sapphire」パラタイムを活用し、以下のプライバシー保護機能を実装：

1. **エンドツーエンド暗号化**: ユーザーのリクエストと結果を暗号化
2. **機密計算**: コントラクト内の処理を機密環境で実行
3. **アクセス制御**: ユーザー自身のデータにのみアクセス可能な権限管理
4. **プライバシー保護ストレージ**: 長期記憶データの暗号化保存

## 拡張性と将来の展望

1. **UI開発**: より使いやすいユーザーインターフェースの開発
2. **機能拡張**: より多くのツールとの統合
3. **パフォーマンス最適化**: 応答速度の向上とコスト削減
4. **多言語サポート**: 様々な言語への対応
