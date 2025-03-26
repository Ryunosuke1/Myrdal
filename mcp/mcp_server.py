# Myrdal Agent - MCP Server Implementation

import asyncio
import json
import os
from pyppeteer import launch
from aiohttp import web

class MCPBrowserServer:
    def __init__(self):
        self.browser = None
        self.page = None
        
    async def initialize(self):
        # Dockerコンテナ内での実行を検出
        in_docker = os.environ.get('DOCKER_CONTAINER', 'false').lower() == 'true'
        
        launch_args = {
            'headless': in_docker,  # Docker内ではヘッドレスモード
            'args': [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-accelerated-2d-canvas',
                '--disable-gpu'
            ]
        }
            
        self.browser = await launch(**launch_args)
        self.page = await self.browser.newPage()
        print("Browser initialized")
        
    async def navigate(self, url):
        await self.page.goto(url, {'waitUntil': 'networkidle0'})
        return await self.page.content()
        
    async def screenshot(self, selector=None, full_page=False):
        if selector:
            element = await self.page.querySelector(selector)
            return await element.screenshot()
        return await self.page.screenshot({'fullPage': full_page})
        
    async def click(self, selector):
        await self.page.click(selector)
        return True
        
    async def type(self, selector, text):
        await self.page.type(selector, text)
        return True
        
    async def evaluate(self, script):
        return await self.page.evaluate(script)
        
    async def get_console_logs(self):
        # コンソールログを取得するためのイベントリスナー設定
        logs = []
        self.page.on('console', lambda msg: logs.append(msg.text))
        return logs
        
    async def close(self):
        if self.browser:
            await self.browser.close()

class MCPServer:
    def __init__(self):
        self.app = web.Application()
        self.browser_server = MCPBrowserServer()
        self.setup_routes()
        
    def setup_routes(self):
        self.app.router.add_post('/navigate', self.handle_navigate)
        self.app.router.add_post('/screenshot', self.handle_screenshot)
        self.app.router.add_post('/click', self.handle_click)
        self.app.router.add_post('/type', self.handle_type)
        self.app.router.add_post('/evaluate', self.handle_evaluate)
        self.app.on_startup.append(self.on_startup)
        self.app.on_shutdown.append(self.on_shutdown)
        
    async def on_startup(self, app):
        await self.browser_server.initialize()
        
    async def on_shutdown(self, app):
        await self.browser_server.close()
        
    async def handle_navigate(self, request):
        data = await request.json()
        url = data.get('url')
        if not url:
            return web.json_response({'error': 'URL is required'}, status=400)
        
        try:
            content = await self.browser_server.navigate(url)
            return web.json_response({'success': True, 'content': content})
        except Exception as e:
            return web.json_response({'error': str(e)}, status=500)
            
    async def handle_screenshot(self, request):
        data = await request.json()
        selector = data.get('selector')
        full_page = data.get('full_page', False)
        
        try:
            screenshot = await self.browser_server.screenshot(selector, full_page)
            return web.Response(body=screenshot, content_type='image/png')
        except Exception as e:
            return web.json_response({'error': str(e)}, status=500)
            
    async def handle_click(self, request):
        data = await request.json()
        selector = data.get('selector')
        if not selector:
            return web.json_response({'error': 'Selector is required'}, status=400)
        
        try:
            result = await self.browser_server.click(selector)
            return web.json_response({'success': result})
        except Exception as e:
            return web.json_response({'error': str(e)}, status=500)
            
    async def handle_type(self, request):
        data = await request.json()
        selector = data.get('selector')
        text = data.get('text')
        if not selector or text is None:
            return web.json_response({'error': 'Selector and text are required'}, status=400)
        
        try:
            result = await self.browser_server.type(selector, text)
            return web.json_response({'success': result})
        except Exception as e:
            return web.json_response({'error': str(e)}, status=500)
            
    async def handle_evaluate(self, request):
        data = await request.json()
        script = data.get('script')
        if not script:
            return web.json_response({'error': 'Script is required'}, status=400)
        
        try:
            result = await self.browser_server.evaluate(script)
            return web.json_response({'success': True, 'result': result})
        except Exception as e:
            return web.json_response({'error': str(e)}, status=500)
            
    def run(self):
        port = int(os.environ.get('MCP_SERVER_PORT', 8080))
        web.run_app(self.app, port=port)

if __name__ == '__main__':
    server = MCPServer()
    server.run()
