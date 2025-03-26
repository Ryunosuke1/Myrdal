#!/usr/bin/env python3
"""
Vyperコントラクトの最終修正スクリプト
関数スコープの変数名修正、モジュールインポート修正、構文エラー修正
"""

import os
import re
from pathlib import Path

# プロジェクトのルートディレクトリ
ROOT_DIR = Path(__file__).parent.parent
CONTRACTS_DIR = ROOT_DIR / "contracts"

def find_vyper_files(directory):
    """指定されたディレクトリ内のすべての.vyファイルを再帰的に検索"""
    vyper_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.vy'):
                vyper_files.append(os.path.join(root, file))
    return vyper_files

def fix_final_issues(file_path):
    """最終的な問題を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 更新されたコンテンツ
    updated_content = content
    
    # ファイル名から推測されるコントラクト名
    file_name = os.path.basename(file_path)
    contract_name = os.path.splitext(file_name)[0]
    
    # MCPIntegration.vyの修正
    if contract_name == "MCPIntegration":
        # 関数内の変数名を一意にする
        updated_content = re.sub(
            r'def request_firefox_action\(.*?\).*?:.*?# Generate request ID\s+req_id: bytes32\s+req_id = keccak256\(concat\(',
            r'def request_firefox_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Generate request ID\n    firefox_req_id: bytes32\n    firefox_req_id = keccak256(concat(',
            updated_content, 
            flags=re.DOTALL
        )
        
        updated_content = re.sub(
            r'def request_chrome_action\(.*?\).*?:.*?# Generate request ID\s+req_id: bytes32\s+req_id = keccak256\(concat\(',
            r'def request_chrome_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Generate request ID\n    chrome_req_id: bytes32\n    chrome_req_id = keccak256(concat(',
            updated_content, 
            flags=re.DOTALL
        )
        
        updated_content = re.sub(
            r'def request_safari_action\(.*?\).*?:.*?# Generate request ID\s+req_id: bytes32\s+req_id = keccak256\(concat\(',
            r'def request_safari_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Generate request ID\n    safari_req_id: bytes32\n    safari_req_id = keccak256(concat(',
            updated_content, 
            flags=re.DOTALL
        )
        
        # user_auth_contractの修正
        updated_content = re.sub(
            r'def request_firefox_action\(.*?\).*?:.*?# Check if user is active\s+user_auth_contract: address',
            r'def request_firefox_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Check if user is active',
            updated_content, 
            flags=re.DOTALL
        )
        
        updated_content = re.sub(
            r'def request_chrome_action\(.*?\).*?:.*?# Check if user is active\s+user_auth_contract: address',
            r'def request_chrome_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Check if user is active',
            updated_content, 
            flags=re.DOTALL
        )
        
        updated_content = re.sub(
            r'def request_safari_action\(.*?\).*?:.*?# Check if user is active\s+user_auth_contract: address',
            r'def request_safari_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Check if user is active',
            updated_content, 
            flags=re.DOTALL
        )
        
        # requestの修正
        updated_content = re.sub(
            r'def request_firefox_action\(.*?\).*?:.*?# Create request\s+request: MCPRequest',
            r'def request_firefox_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Create request\n    firefox_request: MCPRequest',
            updated_content, 
            flags=re.DOTALL
        )
        
        updated_content = re.sub(
            r'def request_chrome_action\(.*?\).*?:.*?# Create request\s+request: MCPRequest',
            r'def request_chrome_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Create request\n    chrome_request: MCPRequest',
            updated_content, 
            flags=re.DOTALL
        )
        
        updated_content = re.sub(
            r'def request_safari_action\(.*?\).*?:.*?# Create request\s+request: MCPRequest',
            r'def request_safari_action(action_data: String[1024], callback_address: address, callback_function_selector: bytes4) -> bytes32:\n    pass\n    # Create request\n    safari_request: MCPRequest',
            updated_content, 
            flags=re.DOTALL
        )
    
    # OracleInterface.vyの修正
    elif contract_name == "OracleInterface":
        # assertの修正
        updated_content = re.sub(
            r'assert is_user_active\(sender\), "User not active"',
            r'if not is_user_active(sender):\n        raise "User not active"',
            updated_content
        )
    
    # ChainlinkMCP.vyの修正
    elif contract_name == "ChainlinkMCP":
        # モジュールインポートの修正
        updated_content = re.sub(
            r'from vyper.interfaces import ERC20',
            r'# ERC20インターフェースをインライン定義\ninterface ERC20:\n    def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable',
            updated_content
        )
    
    # FileverseIntegration.vyの修正
    elif contract_name == "FileverseIntegration":
        # 構造体初期化の修正（キーワード引数の一貫性）
        updated_content = re.sub(
            r'mime_type: mime_type,',
            r'mime_type=mime_type,',
            updated_content
        )
    
    # MemoryStorage.vyの修正
    elif contract_name == "MemoryStorage":
        # インデントの修正
        updated_content = re.sub(
            r'for j: uint256 in range\(100\):\s+if j >= len\(tag_memories\):\nbreak',
            r'for j: uint256 in range(100):\n    if j >= len(tag_memories):\n        break',
            updated_content
        )
    
    # 変更があった場合のみファイルを更新
    if content != updated_content:
        with open(file_path, 'w') as file:
            file.write(updated_content)
        return True
    return False

def main():
    """メイン関数"""
    vyper_files = find_vyper_files(CONTRACTS_DIR)
    updated_count = 0
    
    for file_path in vyper_files:
        if fix_final_issues(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
