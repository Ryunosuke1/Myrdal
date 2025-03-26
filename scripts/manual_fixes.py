#!/usr/bin/env python3
"""
Vyperコントラクトの最終修正スクリプト（手動修正版）
コンストラクタのインデント、ローカル変数の初期化、制御構造のインデントを修正します
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

def manually_fix_contract(file_path):
    """手動でコントラクトを修正"""
    file_name = os.path.basename(file_path)
    
    # MyrdalCore.vyの修正
    if file_name == "MyrdalCore.vy":
        with open(file_path, 'r') as file:
            content = file.read()
        
        # コンストラクタのインデント修正
        content = content.replace(
            "):\nowner = sender\npaused = False",
            "):\n    owner = sender\n    paused = False"
        )
        
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    # UserAuth.vyの修正
    elif file_name == "UserAuth.vy":
        with open(file_path, 'r') as file:
            content = file.read()
        
        # ローカル変数の初期化問題を修正
        content = content.replace(
            "user: UserInfo = UserInfo(",
            "user: UserInfo\nuser = UserInfo("
        )
        
        # if文のインデント修正
        content = content.replace(
            "if users[sender].address != empty(address):\nreturn False",
            "if users[sender].address != empty(address):\n    return False"
        )
        
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    # MemoryStorage.vyの修正
    elif file_name == "MemoryStorage.vy":
        with open(file_path, 'r') as file:
            content = file.read()
        
        # for文とif文のインデント修正
        content = content.replace(
            "for i: uint256 in range(10):\nif i >= len(tags):\nbreak",
            "for i: uint256 in range(10):\n    if i >= len(tags):\n        break"
        )
        
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    # MCPIntegration.vyの修正
    elif file_name == "MCPIntegration.vy":
        with open(file_path, 'r') as file:
            content = file.read()
        
        # ローカル変数の初期化問題を修正
        content = content.replace(
            "request_id: bytes32 = keccak256(",
            "request_id: bytes32\nrequest_id = keccak256("
        )
        
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    # OracleInterface.vyの修正
    elif file_name == "OracleInterface.vy":
        with open(file_path, 'r') as file:
            content = file.read()
        
        # ローカル変数の初期化問題を修正
        content = content.replace(
            "request_id: bytes32 = keccak256(",
            "request_id: bytes32\nrequest_id = keccak256("
        )
        
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    # ChainlinkMCP.vyの修正
    elif file_name == "ChainlinkMCP.vy":
        with open(file_path, 'r') as file:
            content = file.read()
        
        # ローカル変数の初期化問題を修正
        content = content.replace(
            "data: bytes32 = keccak256(",
            "data: bytes32\ndata = keccak256("
        )
        
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    # FileverseIntegration.vyの修正
    elif file_name == "FileverseIntegration.vy":
        with open(file_path, 'r') as file:
            content = file.read()
        
        # 関数定義後のドキュメント文字列のインデント修正
        content = re.sub(
            r'(\) -> bool:\n)"""',
            r'\1    """',
            content
        )
        
        with open(file_path, 'w') as file:
            file.write(content)
        return True
    
    return False

def main():
    """メイン関数"""
    vyper_files = find_vyper_files(CONTRACTS_DIR)
    updated_count = 0
    
    for file_path in vyper_files:
        if manually_fix_contract(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
