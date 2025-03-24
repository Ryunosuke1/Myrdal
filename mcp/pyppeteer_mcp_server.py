#!/usr/bin/env python3
# Model Context Protocol (MCP) サーバー実装
# pyppeteer操作機能を提供するMCPサーバー

import json
import asyncio
import websockets
import logging
from pyppeteer import launch
import os
import sys
import time
from web3 import Web3

# ロギング設定
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# MCPサーバー設定
MCP_SERVER_PORT = 8766
OASIS_RPC_URL = "https://sapphire.testnet.oasis.io"
MCP_INTEGRATION_CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000"  # 実際のデプロイアドレスに置き換え

class PyppeteerMCPServer:
    def __init__(self):
        self.web3 = Web3(Web3.HTTPProvider(OASIS_RPC_URL))
        self.browser = None
        self.page = None
    
    async def initialize_browser(self):
        """pyppeteerブラウザを初期化"""
        logger.info("pyppeteerブラウザを初期化中...")
        self.browser = await launch(headless=True)
        self.page = await self.browser.newPage()
        logger.info("pyppeteerブラウザの初期化完了")
    
    async def handle_client(self, websocket, path):
        """WebSocketクライアントからのリクエストを処理"""
        if not self.browser:
            await self.initialize_browser()
            
        async for message in websocket:
            logger.info(f"受信メッセージ: {message}")
            try:
                request = json.loads(message)
                action = request.get('action')
                params = request.get('params', {})
                request_id = request.get('id', '')
                
                result = await self.execute_action(action, params)
                
                # 結果をクライアントに送信
                response = {
                    'id': request_id,
                    'success': True,
                    'result': result
                }
                await websocket.send(json.dumps(response))
                
                # スマートコントラクトにも結果を送信
                await self.send_result_to_contract(request_id, result)
                
            except Exception as e:
                logger.error(f"エラー発生: {str(e)}")
                error_response = {
                    'id': request.get('id', ''),
                    'success': False,
                    'error': str(e)
                }
                await websocket.send(json.dumps(error_response))
    
    async def execute_action(self, action, params):
        """ブラウザアクションを実行"""
        if action == 'navigate':
            return await self.navigate_to(params.get('url', ''))
        elif action == 'click':
            return await self.click_element(params.get('selector', ''))
        elif action == 'input':
            return await self.input_text(params.get('selector', ''), params.get('text', ''))
        elif action == 'get_content':
            return await self.get_page_content()
        elif action == 'screenshot':
            return await self.take_screenshot()
        elif action == 'execute_script':
            return await self.execute_script(params.get('script', ''))
        elif action == 'wait_for_selector':
            return await self.wait_for_selector(params.get('selector', ''), params.get('timeout', 30000))
        elif action == 'wait_for_navigation':
            return await self.wait_for_navigation()
        else:
            raise ValueError(f"不明なアクション: {action}")
    
    async def navigate_to(self, url):
        """指定URLに移動"""
        logger.info(f"URLに移動: {url}")
        await self.page.goto(url, {'waitUntil': 'networkidle0'})
        return {'status': 'success', 'title': await self.page.title(), 'url': self.page.url}
    
    async def click_element(self, selector):
        """要素をクリック"""
        logger.info(f"要素をクリック: {selector}")
        try:
            await self.page.waitForSelector(selector, {'visible': True, 'timeout': 10000})
            await self.page.click(selector)
            return {'status': 'success', 'element': selector}
        except Exception as e:
            logger.error(f"クリック失敗: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    async def input_text(self, selector, text):
        """テキスト入力"""
        logger.info(f"テキスト入力: {selector}, {text}")
        try:
            await self.page.waitForSelector(selector, {'visible': True, 'timeout': 10000})
            await self.page.focus(selector)
            await self.page.evaluate(f'(el) => el.value = ""', await self.page.$(selector))
            await self.page.type(selector, text)
            return {'status': 'success', 'element': selector, 'text': text}
        except Exception as e:
            logger.error(f"入力失敗: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    async def get_page_content(self):
        """ページコンテンツを取得"""
        logger.info("ページコンテンツを取得")
        content = await self.page.content()
        title = await self.page.title()
        return {
            'status': 'success', 
            'title': title,
            'url': self.page.url,
            'html': content
        }
    
    async def take_screenshot(self):
        """スクリーンショットを撮影"""
        logger.info("スクリーンショットを撮影")
        screenshot_path = f"/tmp/pyppeteer_screenshot_{int(time.time())}.png"
        await self.page.screenshot({'path': screenshot_path, 'fullPage': True})
        return {'status': 'success', 'path': screenshot_path}
    
    async def execute_script(self, script):
        """JavaScriptを実行"""
        logger.info(f"JavaScriptを実行: {script[:50]}...")
        try:
            result = await self.page.evaluate(script)
            return {'status': 'success', 'result': str(result)}
        except Exception as e:
            logger.error(f"スクリプト実行失敗: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    async def wait_for_selector(self, selector, timeout):
        """セレクタが表示されるまで待機"""
        logger.info(f"セレクタ待機: {selector}, タイムアウト: {timeout}ms")
        try:
            await self.page.waitForSelector(selector, {'visible': True, 'timeout': timeout})
            return {'status': 'success', 'element': selector}
        except Exception as e:
            logger.error(f"セレクタ待機失敗: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    async def wait_for_navigation(self):
        """ナビゲーション完了まで待機"""
        logger.info("ナビゲーション完了待機")
        try:
            await self.page.waitForNavigation({'waitUntil': 'networkidle0'})
            return {'status': 'success', 'url': self.page.url}
        except Exception as e:
            logger.error(f"ナビゲーション待機失敗: {str(e)}")
            return {'status': 'error', 'message': str(e)}
    
    async def send_result_to_contract(self, request_id, result):
        """結果をスマートコントラクトに送信"""
        logger.info(f"結果をコントラクトに送信: {request_id}")
        # TODO: 実際のコントラクト呼び出し実装
        # ここではモックとして記録のみ
        logger.info(f"コントラクト呼び出し: request_id={request_id}, result={json.dumps(result)[:100]}...")
    
    async def cleanup(self):
        """リソースのクリーンアップ"""
        if self.browser:
            await self.browser.close()
            logger.info("ブラウザを終了しました")

async def main():
    """メイン関数"""
    server = PyppeteerMCPServer()
    try:
        async with websockets.serve(server.handle_client, "localhost", MCP_SERVER_PORT):
            logger.info(f"pyppeteer MCPサーバーを起動しました - ws://localhost:{MCP_SERVER_PORT}")
            await asyncio.Future()  # サーバーを永続的に実行
    finally:
        await server.cleanup()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("サーバーを終了します")
        sys.exit(0)
