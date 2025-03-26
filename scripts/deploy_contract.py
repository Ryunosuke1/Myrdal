#!/usr/bin/env python3
"""
Myrdalコントラクトのデプロイスクリプト
"""

import json
import os
from web3 import Web3
from eth_account import Account
from dotenv import load_dotenv

# .envファイルから環境変数を読み込む
load_dotenv()

# 環境変数から秘密鍵を取得
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
if not PRIVATE_KEY:
    raise ValueError("環境変数PRIVATE_KEYが設定されていません。.envファイルを確認してください。")

# RPC URLの設定
# Unichain Testnet (Sepolia)
UNICHAIN_SEPOLIA_RPC_URL = "https://unichain-sepolia.drpc.org"
# Linea Mainnet
LINEA_MAINNET_RPC_URL = "https://rpc.linea.build"

# デプロイ先のネットワークを選択
# "testnet" または "mainnet"
NETWORK = "testnet"

# ネットワークに応じたRPC URLを設定
if NETWORK == "testnet":
    RPC_URL = UNICHAIN_SEPOLIA_RPC_URL
else:
    RPC_URL = LINEA_MAINNET_RPC_URL

# Web3インスタンスの初期化
w3 = Web3(Web3.HTTPProvider(RPC_URL))

# アカウントの設定
account = Account.from_key(PRIVATE_KEY)
print(f"デプロイアドレス: {account.address}")

# コントラクトのバイトコードとABIの読み込み
with open("build/contracts/MyrdalCore.bin", "r") as f:
    bytecode = f.read().strip()

with open("build/contracts/MyrdalCore.abi.json", "r") as f:
    abi = json.load(f)

# コントラクトのデプロイ
def deploy_contract():
    # コントラクトインスタンスの作成
    MyrdalCore = w3.eth.contract(abi=abi, bytecode=bytecode)
    
    # トランザクションの作成
    nonce = w3.eth.get_transaction_count(account.address)
    
    # コントラクトデプロイトランザクションの構築
    transaction = MyrdalCore.constructor().build_transaction({
        'from': account.address,
        'nonce': nonce,
        'gas': 3000000,
        'gasPrice': w3.eth.gas_price,
    })
    
    # トランザクションの署名
    signed_txn = w3.eth.account.sign_transaction(transaction, PRIVATE_KEY)
    
    # トランザクションの送信
    tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
    print(f"トランザクションハッシュ: {tx_hash.hex()}")
    
    # トランザクションの完了を待機
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    
    # デプロイされたコントラクトアドレスの取得
    contract_address = tx_receipt.contractAddress
    print(f"コントラクトアドレス: {contract_address}")
    
    # フロントエンド用の設定ファイルを更新
    update_frontend_config(contract_address)
    
    return contract_address

def update_frontend_config(contract_address):
    """フロントエンドの設定ファイルを更新"""
    # useMyrdalContract.tsファイルのパス
    file_path = "frontend/hooks/useMyrdalContract.ts"
    
    # ファイルの内容を読み込む
    with open(file_path, "r") as f:
        content = f.read()
    
    # コントラクトアドレスを更新
    updated_content = content.replace(
        "const CONTRACT_ADDRESS = '0x0000000000000000000000000000000000000000'",
        f"const CONTRACT_ADDRESS = '{contract_address}'"
    )
    
    # 更新した内容をファイルに書き込む
    with open(file_path, "w") as f:
        f.write(updated_content)
    
    print(f"フロントエンド設定ファイルを更新しました: {file_path}")

if __name__ == "__main__":
    print(f"Myrdalコントラクトを{NETWORK}にデプロイします...")
    contract_address = deploy_contract()
    print(f"デプロイが完了しました！")
    print(f"次のステップ: フロントエンドをビルドしてデプロイしてください。")
