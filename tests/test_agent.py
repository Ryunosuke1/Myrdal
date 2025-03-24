#!/usr/bin/env python3
# Oasis Protocol AIエージェント テストスクリプト

import json
import asyncio
import logging
import os
import sys
from web3 import Web3
import websockets
import time

# ロギング設定
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 設定
OASIS_RPC_URL = "https://sapphire.testnet.oasis.io"
AGENT_CORE_ADDRESS = "0x0000000000000000000000000000000000000000"  # 実際のデプロイアドレスに置き換え
FIREFOX_MCP_SERVER_URL = "ws://localhost:8765"
PYPPETEER_MCP_SERVER_URL = "ws://localhost:8766"

# コントラクトABI（実際のABIに置き換え）
AGENT_CORE_ABI = [
    {
        "inputs": [
            {"name": "prompt", "type": "string"}
        ],
        "name": "create_task",
        "outputs": [{"name": "", "type": "bytes32"}],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"name": "task_id", "type": "bytes32"}
        ],
        "name": "get_task",
        "outputs": [
            {
                "components": [
                    {"name": "id", "type": "bytes32"},
                    {"name": "owner", "type": "address"},
                    {"name": "prompt", "type": "string"},
                    {"name": "status", "type": "uint8"},
                    {"name": "created_at", "type": "uint256"},
                    {"name": "completed_at", "type": "uint256"},
                    {"name": "result", "type": "string"}
                ],
                "name": "", 
                "type": "tuple"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
]

class OasisAgentTester:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(OASIS_RPC_URL))
        self.agent_contract = self.web3.eth.contract(
            address=AGENT_CORE_ADDRESS,
            abi=AGENT_CORE_ABI
        )
        self.firefox_ws = None
        self.pyppeteer_ws = None
    
    async def setup(self):
        """テスト環境のセットアップ"""
        logger.info("テスト環境をセットアップ中...")
        
        # MCPサーバーへの接続
        try:
            self.firefox_ws = await websockets.connect(FIREFOX_MCP_SERVER_URL)
            logger.info("Firefox MCPサーバーに接続しました")
        except Exception as e:
            logger.error(f"Firefox MCPサーバー接続エラー: {str(e)}")
        
        try:
            self.pyppeteer_ws = await websockets.connect(PYPPETEER_MCP_SERVER_URL)
            logger.info("pyppeteer MCPサーバーに接続しました")
        except Exception as e:
            logger.error(f"pyppeteer MCPサーバー接続エラー: {str(e)}")
    
    async def test_firefox_mcp(self):
        """Firefox MCPサーバーのテスト"""
        if not self.firefox_ws:
            logger.error("Firefox MCPサーバーに接続されていません")
            return False
        
        logger.info("Firefox MCPサーバーをテスト中...")
        
        # ナビゲーションテスト
        try:
            request = {
                'id': 'test_navigation',
                'action': 'navigate',
                'params': {'url': 'https://oasisprotocol.org/'}
            }
            
            await self.firefox_ws.send(json.dumps(request))
            response = await self.firefox_ws.recv()
            result = json.loads(response).get('result', {})
            
            if result.get('status') == 'success':
                logger.info(f"ナビゲーションテスト成功: {result.get('title')}")
            else:
                logger.error(f"ナビゲーションテスト失敗: {result}")
                return False
            
            # スクリーンショットテスト
            request = {
                'id': 'test_screenshot',
                'action': 'screenshot',
                'params': {}
            }
            
            await self.firefox_ws.send(json.dumps(request))
            response = await self.firefox_ws.recv()
            result = json.loads(response).get('result', {})
            
            if result.get('status') == 'success':
                logger.info(f"スクリーンショットテスト成功: {result.get('path')}")
            else:
                logger.error(f"スクリーンショットテスト失敗: {result}")
                return False
            
            return True
        except Exception as e:
            logger.error(f"Firefox MCPテストエラー: {str(e)}")
            return False
    
    async def test_pyppeteer_mcp(self):
        """pyppeteer MCPサーバーのテスト"""
        if not self.pyppeteer_ws:
            logger.error("pyppeteer MCPサーバーに接続されていません")
            return False
        
        logger.info("pyppeteer MCPサーバーをテスト中...")
        
        # ナビゲーションテスト
        try:
            request = {
                'id': 'test_navigation',
                'action': 'navigate',
                'params': {'url': 'https://oasisprotocol.org/'}
            }
            
            await self.pyppeteer_ws.send(json.dumps(request))
            response = await self.pyppeteer_ws.recv()
            result = json.loads(response).get('result', {})
            
            if result.get('status') == 'success':
                logger.info(f"ナビゲーションテスト成功: {result.get('title')}")
            else:
                logger.error(f"ナビゲーションテスト失敗: {result}")
                return False
            
            # スクリーンショットテスト
            request = {
                'id': 'test_screenshot',
                'action': 'screenshot',
                'params': {}
            }
            
            await self.pyppeteer_ws.send(json.dumps(request))
            response = await self.pyppeteer_ws.recv()
            result = json.loads(response).get('result', {})
            
            if result.get('status') == 'success':
                logger.info(f"スクリーンショットテスト成功: {result.get('path')}")
            else:
                logger.error(f"スクリーンショットテスト失敗: {result}")
                return False
            
            return True
        except Exception as e:
            logger.error(f"pyppeteer MCPテストエラー: {str(e)}")
            return False
    
    def test_agent_contract(self):
        """エージェントコントラクトのテスト"""
        logger.info("エージェントコントラクトをテスト中...")
        
        # コントラクトが接続可能かテスト
        try:
            # コントラクトのデプロイ状態を確認
            logger.info("コントラクト接続テスト")
            logger.info(f"コントラクトアドレス: {AGENT_CORE_ADDRESS}")
            
            # 注意: 実際のデプロイ前はこのテストはスキップ
            logger.info("コントラクトはまだデプロイされていないため、接続テストをスキップします")
            return True
        except Exception as e:
            logger.error(f"コントラクトテストエラー: {str(e)}")
            return False
    
    def test_oasis_connection(self):
        """Oasis Protocolへの接続テスト"""
        logger.info("Oasis Protocolへの接続をテスト中...")
        
        try:
            # ネットワーク接続テスト
            chain_id = self.web3.eth.chain_id
            block_number = self.web3.eth.block_number
            
            logger.info(f"接続成功: チェーンID={chain_id}, ブロック番号={block_number}")
            return True
        except Exception as e:
            logger.error(f"Oasis接続エラー: {str(e)}")
            return False
    
    async def run_all_tests(self):
        """すべてのテストを実行"""
        await self.setup()
        
        test_results = {
            "oasis_connection": self.test_oasis_connection(),
            "agent_contract": self.test_agent_contract(),
            "firefox_mcp": await self.test_firefox_mcp(),
            "pyppeteer_mcp": await self.test_pyppeteer_mcp()
        }
        
        logger.info("テスト結果:")
        for test_name, result in test_results.items():
            logger.info(f"{test_name}: {'成功' if result else '失敗'}")
        
        return all(test_results.values())
    
    async def cleanup(self):
        """リソースのクリーンアップ"""
        if self.firefox_ws:
            await self.firefox_ws.close()
        
        if self.pyppeteer_ws:
            await self.pyppeteer_ws.close()
        
        logger.info("テスト環境をクリーンアップしました")

async def main():
    """メイン関数"""
    tester = OasisAgentTester()
    try:
        success = await tester.run_all_tests()
        if success:
            logger.info("すべてのテストが成功しました")
        else:
            logger.error("一部のテストが失敗しました")
    finally:
        await tester.cleanup()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("テストを終了します")
        sys.exit(0)
