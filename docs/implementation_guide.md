# Myrdal Agent - Oasis Protocol 実装ガイド

## 概要

このドキュメントは、Oasis Protocol上にデプロイするMyrdalエージェントの実装とデプロイ方法について説明します。Myrdalは、OpenAI Agents SDKをベースとした汎用AIエージェントで、Oasis Protocolのプライバシー保護機能を活用し、多様なタスクを処理できる能力を持っています。

## アーキテクチャ

Myrdalエージェントは以下の2つの主要コンポーネントで構成されています：

### オンチェーンコンポーネント（Vyperで実装）

- **MyrdalCore.vy**: エージェントの中核機能を提供するスマートコントラクト
- **MemoryStorage.vy**: 暗号化された長期記憶を管理
- **UserAuth.vy**: ユーザー認証と権限管理
- **MCPIntegration.vy**: Model Context Protocolとの連携
- **ChainlinkMCP.vy**: Chainlinkを介したMCP実行
- **FileverseIntegration.vy**: 成果物のFileverse提供

### オフチェーンコンポーネント

- **mcp_server.py**: pyppeteerを使用したMCPサーバー実装
- **chainlink_adapter.py**: Chainlinkノードとの連携
- **fileverse_manager.py**: ファイル管理とアップロード

## 前提条件

- Oasis Protocol Sapphireパラダイムの開発環境
- Python 3.8以上
- Node.js 14以上
- Vyper 0.3.7以上
- Brownie（Vyperコントラクトのテスト用）
- Docker（MCPサーバーの実行用）

## インストール手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/Ryunosuke1/Myrdal.git
cd Myrdal
```

### 2. 依存関係のインストール

```bash
# Pythonパッケージのインストール
pip install -r requirements.txt

# Node.jsパッケージのインストール
npm install
```

### 3. 環境設定

`.env`ファイルを作成し、以下の環境変数を設定します：

```
# Oasis Protocol設定
OASIS_RPC_URL=https://sapphire.oasis.io/rpc
OASIS_CHAIN_ID=0x5afe

# Chainlink設定
CHAINLINK_TOKEN_ADDRESS=0x...
CHAINLINK_ORACLE_ADDRESS=0x...
CHAINLINK_JOB_ID=0x...

# Fileverse設定
FILEVERSE_API_KEY=your_api_key
```

## コントラクトのデプロイ

### 1. コントラクトのコンパイル

```bash
brownie compile
```

### 2. コントラクトのデプロイ

```bash
brownie run scripts/deploy.py --network oasis-sapphire
```

デプロイスクリプトは以下の順序でコントラクトをデプロイします：

1. UserAuth.vy
2. MyrdalCore.vy
3. MemoryStorage.vy
4. OracleInterface.vy
5. MCPIntegration.vy
6. ChainlinkMCP.vy
7. FileverseIntegration.vy

## MCPサーバーの実行

### 1. Dockerイメージのビルド

```bash
docker build -t myrdal-mcp-server .
```

### 2. MCPサーバーの起動

```bash
docker run -d -p 8080:8080 --name myrdal-mcp myrdal-mcp-server
```

## テスト

### 1. コントラクトのテスト

```bash
brownie test
```

### 2. MCPサーバーのテスト

```bash
python tests/test_mcp_server.py
```

## 使用方法

### 1. タスクの作成

```javascript
// Web3.jsを使用した例
const myrdalCore = new web3.eth.Contract(MyrdalCoreABI, myrdalCoreAddress);

const taskData = JSON.stringify({
  action: "search_web",
  query: "Oasis Protocol Sapphire",
  callback: "store_results"
});

const tx = await myrdalCore.methods.create_task(taskData).send({
  from: userAddress,
  gas: 500000
});

const taskId = tx.events.TaskCreated.returnValues.task_id;
console.log(`Task created with ID: ${taskId}`);
```

### 2. タスクの実行

```javascript
const tx = await myrdalCore.methods.execute_task(taskId).send({
  from: userAddress,
  gas: 1000000
});

console.log(`Task execution initiated: ${tx.transactionHash}`);
```

### 3. 結果の取得

```javascript
const taskDetails = await myrdalCore.methods.get_task_details(taskId).call();
console.log(`Task status: ${taskDetails[2]}`);

if (taskDetails[2] === "2") { // 完了
  const resultHash = taskDetails[3];
  console.log(`Result hash: ${resultHash}`);
  
  // Fileverseから結果を取得
  const fileverseIntegration = new web3.eth.Contract(FileverseIntegrationABI, fileverseIntegrationAddress);
  const taskFiles = await fileverseIntegration.methods.get_task_files(taskId).call();
  
  console.log(`Task files: ${taskFiles}`);
}
```

## セキュリティとプライバシー

Myrdalエージェントは、Oasis ProtocolのSapphireパラダイムを活用して、以下のセキュリティとプライバシー機能を提供します：

1. **TEE（Trusted Execution Environment）**: スマートコントラクトの実行内容が保護されます
2. **エンドツーエンド暗号化**: ユーザーデータは暗号化されて保存されます
3. **アクセス制御**: ファイルやメモリへのアクセスは厳密に制御されます

## トラブルシューティング

### よくある問題と解決策

1. **コントラクトのデプロイに失敗する**
   - Oasis Sapphireネットワークに十分なトークンがあることを確認してください
   - RPCエンドポイントが正しく設定されていることを確認してください

2. **MCPサーバーが起動しない**
   - Dockerが正しくインストールされていることを確認してください
   - ポート8080が他のプロセスで使用されていないことを確認してください

3. **タスク実行がタイムアウトする**
   - Chainlinkノードが正しく設定されていることを確認してください
   - ガス制限が十分に高く設定されていることを確認してください

## 貢献

バグ報告や機能リクエストは、GitHubリポジトリのIssueセクションで受け付けています。プルリクエストも歓迎します。

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細はLICENSEファイルを参照してください。
