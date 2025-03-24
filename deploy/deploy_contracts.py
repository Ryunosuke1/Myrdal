#!/usr/bin/env python3
# Oasis Protocol AIエージェント デプロイスクリプト

import json
import logging
import os
import sys
from web3 import Web3
import time

# ロギング設定
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 設定
OASIS_RPC_URL = "https://sapphire.testnet.oasis.io"
PRIVATE_KEY = "0x0000000000000000000000000000000000000000000000000000000000000000"  # 実際の秘密鍵に置き換え

# コントラクトパス
CONTRACT_PATHS = {
    "UserAuth": "/home/ubuntu/oasis-agent/contracts/auth/UserAuth.vy",
    "MemoryStorage": "/home/ubuntu/oasis-agent/contracts/memory/MemoryStorage.vy",
    "OracleInterface": "/home/ubuntu/oasis-agent/contracts/oracle/OracleInterface.vy",
    "MCPIntegration": "/home/ubuntu/oasis-agent/contracts/mcp/MCPIntegration.vy",
    "AgentCore": "/home/ubuntu/oasis-agent/contracts/core/AgentCore.vy"
}

class OasisAgentDeployer:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(OASIS_RPC_URL))
        self.account = self.web3.eth.account.from_key(PRIVATE_KEY)
        self.deployed_contracts = {}
    
    def compile_contract(self, contract_name, contract_path):
        """Vyperコントラクトをコンパイル"""
        logger.info(f"{contract_name}コントラクトをコンパイル中...")
        
        try:
            # 注意: 実際の環境ではvyperコマンドラインツールを使用
            # ここではモック実装
            logger.info(f"コントラクトパス: {contract_path}")
            logger.info("コンパイル成功（モック）")
            
            # モックのバイトコードとABI
            bytecode = "0x123456"  # 実際のバイトコード
            abi = []  # 実際のABI
            
            return {
                "bytecode": bytecode,
                "abi": abi
            }
        except Exception as e:
            logger.error(f"コンパイルエラー: {str(e)}")
            return None
    
    def deploy_contract(self, contract_name, contract_path, constructor_args=None):
        """コントラクトをデプロイ"""
        logger.info(f"{contract_name}コントラクトをデプロイ中...")
        
        # コントラクトのコンパイル
        compiled = self.compile_contract(contract_name, contract_path)
        if not compiled:
            return None
        
        try:
            # コントラクトオブジェクトの作成
            contract = self.web3.eth.contract(
                abi=compiled["abi"],
                bytecode=compiled["bytecode"]
            )
            
            # コンストラクタ引数の処理
            if constructor_args is None:
                constructor_args = []
            
            # トランザクション作成
            construct_txn = contract.constructor(*constructor_args).build_transaction({
                'from': self.account.address,
                'nonce': self.web3.eth.get_transaction_count(self.account.address),
                'gas': 2000000,
                'gasPrice': self.web3.eth.gas_price
            })
            
            # トランザクション署名
            signed_txn = self.web3.eth.account.sign_transaction(construct_txn, self.account.key)
            
            # トランザクション送信
            tx_hash = self.web3.eth.send_raw_transaction(signed_txn.rawTransaction)
            
            # トランザクション確認待ち
            tx_receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash)
            
            # デプロイされたコントラクトアドレス
            contract_address = tx_receipt.contractAddress
            
            logger.info(f"{contract_name}コントラクトをデプロイしました: {contract_address}")
            
            # デプロイされたコントラクト情報を保存
            self.deployed_contracts[contract_name] = {
                "address": contract_address,
                "abi": compiled["abi"]
            }
            
            return contract_address
        except Exception as e:
            logger.error(f"デプロイエラー: {str(e)}")
            return None
    
    def deploy_all_contracts(self):
        """すべてのコントラクトをデプロイ"""
        logger.info("すべてのコントラクトをデプロイ中...")
        
        # UserAuthコントラクトのデプロイ
        service_fee = 1000000000000000  # 0.001 ETH
        user_auth_address = self.deploy_contract("UserAuth", CONTRACT_PATHS["UserAuth"], [service_fee])
        if not user_auth_address:
            logger.error("UserAuthコントラクトのデプロイに失敗しました")
            return False
        
        # MemoryStorageコントラクトのデプロイ
        memory_storage_address = self.deploy_contract("MemoryStorage", CONTRACT_PATHS["MemoryStorage"], [user_auth_address])
        if not memory_storage_address:
            logger.error("MemoryStorageコントラクトのデプロイに失敗しました")
            return False
        
        # OracleInterfaceコントラクトのデプロイ
        oracle_address = self.account.address  # オラクルアドレス（実際の環境では別のアドレス）
        oracle_interface_address = self.deploy_contract("OracleInterface", CONTRACT_PATHS["OracleInterface"], [user_auth_address, oracle_address])
        if not oracle_interface_address:
            logger.error("OracleInterfaceコントラクトのデプロイに失敗しました")
            return False
        
        # MCPIntegrationコントラクトのデプロイ
        mcp_oracle_address = self.account.address  # MCPオラクルアドレス（実際の環境では別のアドレス）
        mcp_integration_address = self.deploy_contract("MCPIntegration", CONTRACT_PATHS["MCPIntegration"], [user_auth_address, mcp_oracle_address])
        if not mcp_integration_address:
            logger.error("MCPIntegrationコントラクトのデプロイに失敗しました")
            return False
        
        # AgentCoreコントラクトのデプロイ
        agent_core_address = self.deploy_contract("AgentCore", CONTRACT_PATHS["AgentCore"], [
            memory_storage_address,
            oracle_interface_address,
            mcp_integration_address,
            user_auth_address
        ])
        if not agent_core_address:
            logger.error("AgentCoreコントラクトのデプロイに失敗しました")
            return False
        
        logger.info("すべてのコントラクトのデプロイが完了しました")
        return True
    
    def save_deployment_info(self, output_file):
        """デプロイ情報をJSONファイルに保存"""
        logger.info(f"デプロイ情報を{output_file}に保存中...")
        
        try:
            with open(output_file, 'w') as f:
                json.dump(self.deployed_contracts, f, indent=2)
            
            logger.info(f"デプロイ情報を{output_file}に保存しました")
            return True
        except Exception as e:
            logger.error(f"デプロイ情報の保存エラー: {str(e)}")
            return False

def main():
    """メイン関数"""
    deployer = OasisAgentDeployer()
    
    # コントラクトのデプロイ
    success = deployer.deploy_all_contracts()
    
    if success:
        # デプロイ情報の保存
        deployer.save_deployment_info("/home/ubuntu/oasis-agent/deployment_info.json")
        logger.info("デプロイが成功しました")
    else:
        logger.error("デプロイに失敗しました")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("デプロイを終了します")
        sys.exit(0)
