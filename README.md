# Myrdal - 汎用AIエージェント

Myrdalは、OpenAI Assistants APIを活用した汎用AIエージェントで、ブラウザを操作しながらWebタスクを実行できます。Chainlinkのexternal adaptorとして機能し、ブロックチェーンからの要求に応じてさまざまなタスクを自律的に実行します。

## 特徴

- **OpenAI Assistants API**: 高度な言語モデルによる自然言語理解と指示の実行
- **ブラウザ操作**: DockerコンテナでFirefoxブラウザを操作し、Webタスクを実行
- **Chainlink統合**: スマートコントラクトからのリクエストを処理するexternal adaptorとして機能
- **自律的動作**: 複雑なタスクを自動的に分解し、段階的に実行

## セットアップ

### 前提条件

- Docker
- OpenAI API Key

### インストール手順

1. リポジトリをクローン
   ```
   git clone https://github.com/yourusername/myrdal.git
   cd myrdal
   ```

2. .envファイルを作成し、OpenAI APIキーを設定
   ```
   OPENAI_API_KEY=sk-your-api-key
   ```

3. Dockerイメージをビルド
   ```
   docker build -t myrdal .
   ```

4. コンテナを実行
   ```
   docker run -p 8080:8080 -p 8081:8081 --env-file .env myrdal
   ```

## 使用方法

### API エンドポイント

#### Myrdalエージェント (ポート8080)

- **テストエンドポイント**: `/test`
  ```
  curl -X POST http://localhost:8080/test \
    -H "Content-Type: application/json" \
    -d '{"command": "Amazonで最新のiPhoneの価格を調べて"}'
  ```

#### Chainlink Adaptor (ポート8081)

- **メインエンドポイント**: `/`
  ```
  curl -X POST http://localhost:8081/ \
    -H "Content-Type: application/json" \
    -d '{
      "id": "1",
      "data": {
        "command": "Amazonで最新のiPhoneの価格を調べて"
      }
    }'
  ```

### スマートコントラクトからの利用

スマートコントラクトから以下のようにMyrdalを呼び出すことができます：

```solidity
// Oracle Interface
function requestData(string calldata command) external returns (bytes32 requestId);

// 呼び出し例
bytes32 requestId = oracle.requestData("Amazonで最新のiPhoneの価格を調べて");
```

## アーキテクチャ

Myrdalは以下のコンポーネントで構成されています：

1. **Myrdalエージェント**: OpenAI Assistants APIを使用したAIエージェント
2. **ブラウザ操作モジュール**: Playwrightを使用したブラウザ自動操作
3. **Chainlinkアダプター**: スマートコントラクトからのリクエストを処理するアダプター

## ライセンス

MIT