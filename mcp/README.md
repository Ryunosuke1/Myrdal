# Myrdal MCPサーバー実装

このディレクトリには、Myrdalエージェントで使用するMCPサーバーの実装が含まれています。

## 概要

MCPサーバーは、Model Context Protocol（MCP）を使用してブラウザ操作機能を提供します。Chromiumブラウザを操作し、様々なタスクを自動化することができます。

## ファイル構成

- `mcp_server.py`: MCPサーバーのメイン実装
- `chainlink_adapter.py`: Chainlinkノードとの連携
- `fileverse_manager.py`: ファイル管理とアップロード

## 依存関係

- Python 3.8以上
- pyppeteer
- aiohttp
- web3

## インストール

```bash
pip install -r requirements.txt
```

## 使用方法

### サーバーの起動

```bash
python mcp_server_main.py
```

### Dockerでの実行

```bash
docker build -t myrdal-mcp-server .
docker run -d -p 8080:8080 --name myrdal-mcp myrdal-mcp-server
```

## API

MCPサーバーは以下のAPIエンドポイントを提供します：

- `/navigate`: 指定したURLに移動
- `/screenshot`: スクリーンショットを取得
- `/click`: 要素をクリック
- `/type`: テキストを入力
- `/evaluate`: JavaScriptを実行

## 設定

`.env`ファイルで以下の環境変数を設定できます：

```
MCP_SERVER_PORT=8080
HEADLESS=true
BROWSER_ARGS=--no-sandbox,--disable-setuid-sandbox
```

## Chainlinkとの連携

`chainlink_adapter.py`を使用して、Chainlinkノードと連携することができます。これにより、オンチェーンからMCPアクションを実行することが可能になります。

## Fileverseとの連携

`fileverse_manager.py`を使用して、タスクの成果物をFileverseにアップロードすることができます。
