# Myrdal On Chain AI Agent - 実装ドキュメント

## 概要
Myrdal On Chain AI Agentは、ブロックチェーン上で動作する汎用AIエージェントです。Vyperで実装されたスマートコントラクトとNext.jsフロントエンドで構成され、Norway Rail Vyのデザインを参考にしたNordic Minimalismスタイルのインターフェースを提供します。

## 主要コンポーネント

### コントラクト
- **MyrdalCore.vy**: メインコントラクト。タスク管理、MCP統合、メモリストレージ、オラクル連携などの機能を提供
- 実装言語: Vyper 0.4.1

### フロントエンド
- **Next.js**: Reactベースのフレームワーク
- **wagmi**: Ethereumウォレット連携ライブラリ（Metamask対応）
- **Nordic Minimalism**: Norway Rail Vyのデザインを参考にしたUIスタイル

## 機能一覧

### タスク管理
- タスクの作成、処理、完了
- タスク情報の取得
- ユーザー別タスクリストの管理

### MCP (Model Context Protocol) 統合
- Firefoxブラウザアクションのリクエスト
- pyppeteerアクションのリクエスト
- MCPリクエスト結果の取得

### メモリストレージ
- メモリエントリの保存
- タグベースのメモリ検索
- ユーザー別メモリリストの管理

### オラクル連携
- 外部LLMサービスへのリクエスト
- オラクルリクエスト結果の取得

### 管理機能
- MCPオラクルアドレスの設定
- コントラクトの一時停止/再開
- オーナーシップの移転

## デプロイ方法
1. Vyperコントラクト（contracts/enhanced/MyrdalCore.vy）をデプロイ
2. デプロイされたコントラクトアドレスをフロントエンドの設定に反映
3. フロントエンドをビルドしてデプロイ

詳細な手順は `DEPLOYMENT.md` を参照してください。

## 技術的詳細

### コントラクト構造
- **イベント**: TaskCreated, TaskCompleted, TaskProcessing, MCPRequestCreated, MemoryStored, OracleRequestCreated
- **構造体**: TaskInfo, MCPRequest, MemoryEntry, OracleRequest
- **ストレージ変数**: tasks, user_tasks, mcp_requests, memories, memory_tags, oracle_requests

### フロントエンドとの連携
- ABIとバイトコードを使用してコントラクトと対話
- wagmiライブラリによるMetamask連携
- カスタムフックによるコントラクト機能へのアクセス

## 拡張性と将来の開発
- 追加のMCPプロバイダー対応
- 高度なメモリ検索アルゴリズム
- マルチチェーン対応
- ユーザー認証の強化

## 注意事項
- コントラクトのデプロイには十分なガス量が必要
- MCPオラクルアドレスは実際の運用環境に合わせて設定が必要
- メモリストレージの暗号化機能は追加の実装が必要

## ライセンス
このプロジェクトはMITライセンスの下で公開されています。
