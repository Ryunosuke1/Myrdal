# Myrdal On Chain AI Agent - デプロイガイド

## 前提条件
- Node.js 16以上
- Python 3.8以上
- Vyper 0.4.1
- Metamaskなどのウォレット
- デプロイ先ネットワークのETH（テストネットの場合はテストETH）

## コントラクトのデプロイ

### 1. リポジトリのクローン
```bash
git clone https://github.com/Ryunosuke1/Myrdal.git
cd Myrdal
```

### 2. 依存関係のインストール
```bash
# Python依存関係
pip install -r requirements.txt

# フロントエンド依存関係
cd frontend
npm install
cd ..
```

### 3. コントラクトのコンパイル
```bash
# Vyperコントラクトのコンパイル
vyper -f abi contracts/enhanced/MyrdalCore.vy -o build/contracts/MyrdalCore.abi.json
vyper -f bytecode contracts/enhanced/MyrdalCore.vy -o build/contracts/MyrdalCore.bin
```

### 4. コントラクトのデプロイ
以下のスクリプトを使用してコントラクトをデプロイします：

```bash
# プライベートキーとRPCエンドポイントを設定
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url

# デプロイスクリプトの実行
python scripts/deploy_contract.py
```

デプロイが成功すると、コントラクトアドレスが表示されます。このアドレスをメモしておいてください。

### 5. フロントエンドの設定
`frontend/hooks/useMyrdalContract.ts`ファイルを開き、CONTRACT_ADDRESS変数を更新します：

```typescript
const CONTRACT_ADDRESS = 'デプロイされたコントラクトアドレス';
```

## フロントエンドのデプロイ

### 1. ビルド
```bash
cd frontend
npm run build
```

### 2. デプロイ
お好みのホスティングサービス（Vercel, Netlify, AWS S3など）にデプロイします。

例：Vercelの場合
```bash
npm install -g vercel
vercel
```

## 動作確認

1. デプロイされたフロントエンドにアクセス
2. Metamaskを接続
3. タスクを作成して機能をテスト

## トラブルシューティング

### コントラクトのデプロイに失敗する場合
- ガス量が十分か確認
- プライベートキーが正しいか確認
- RPCエンドポイントが有効か確認

### フロントエンドがコントラクトと接続できない場合
- コントラクトアドレスが正しく設定されているか確認
- ネットワークIDが正しいか確認
- ABIファイルが正しくコピーされているか確認

### その他の問題
- コンソールログを確認
- ネットワーク接続を確認
- Metamaskが最新バージョンか確認

## セキュリティに関する注意事項
- プライベートキーを公開リポジトリにコミットしないでください
- 本番環境では適切なアクセス制御を実装してください
- コントラクトのオーナーシップを安全に管理してください
