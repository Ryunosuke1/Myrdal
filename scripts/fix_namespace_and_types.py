#!/usr/bin/env python3
"""
Vyperコントラクトの名前空間衝突と型参照問題を修正するスクリプト
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

def fix_namespace_and_types(file_path):
    """名前空間衝突と型参照問題を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 更新されたコンテンツ
    updated_content = content
    
    # ファイル名から推測されるコントラクト名
    file_name = os.path.basename(file_path)
    contract_name = os.path.splitext(file_name)[0]
    
    # MCPIntegration.vyの修正
    if contract_name == "MCPIntegration":
        # 名前空間衝突の修正（変数名の変更）
        updated_content = re.sub(
            r'request: MCPRequest\nrequest =',
            r'req: MCPRequest\nreq =',
            updated_content
        )
        
        updated_content = re.sub(
            r'request_id: bytes32\nrequest_id =',
            r'req_id: bytes32\nreq_id =',
            updated_content
        )
        
        # IUserAuth型の修正
        updated_content = re.sub(
            r'user_auth: IUserAuth',
            r'user_auth_contract: address',
            updated_content
        )
        
        updated_content = re.sub(
            r'user_auth = IUserAuth\(user_auth\)',
            r'# user_auth_contract already contains the address',
            updated_content
        )
    
    # OracleInterface.vyの修正
    elif contract_name == "OracleInterface":
        # 名前空間衝突の修正（変数名の変更）
        updated_content = re.sub(
            r'request: OracleRequest\nrequest =',
            r'req: OracleRequest\nreq =',
            updated_content
        )
        
        # IUserAuth型の修正
        updated_content = re.sub(
            r'user_auth: IUserAuth',
            r'user_auth_contract: address',
            updated_content
        )
        
        updated_content = re.sub(
            r'user_auth = IUserAuth\(user_auth\)',
            r'# user_auth_contract already contains the address',
            updated_content
        )
    
    # ChainlinkMCP.vyの修正
    elif contract_name == "ChainlinkMCP":
        # モジュールインポートの修正
        updated_content = re.sub(
            r'from interfaces import ERC20',
            r'from vyper.interfaces import ERC20',
            updated_content
        )
    
    # FileverseIntegration.vyの修正
    elif contract_name == "FileverseIntegration":
        # 構造体初期化の修正
        updated_content = re.sub(
            r'metadata = FileMetadata\(\{',
            r'metadata = FileMetadata(',
            updated_content
        )
        
        updated_content = re.sub(
            r'file_hash: file_hash,',
            r'file_hash=file_hash,',
            updated_content
        )
        
        updated_content = re.sub(
            r'name: name,',
            r'name=name,',
            updated_content
        )
        
        updated_content = re.sub(
            r'description: description,',
            r'description=description,',
            updated_content
        )
        
        updated_content = re.sub(
            r'file_type: file_type,',
            r'file_type=file_type,',
            updated_content
        )
        
        updated_content = re.sub(
            r'size: size,',
            r'size=size,',
            updated_content
        )
        
        updated_content = re.sub(
            r'uploader: sender,',
            r'uploader=sender,',
            updated_content
        )
        
        updated_content = re.sub(
            r'upload_time: timestamp,',
            r'upload_time=timestamp,',
            updated_content
        )
        
        updated_content = re.sub(
            r'task_id: task_id',
            r'task_id=task_id',
            updated_content
        )
        
        updated_content = re.sub(
            r'\}\)',
            r')',
            updated_content
        )
        
        # ローカル変数の初期化問題を修正
        updated_content = re.sub(
            r'metadata_str: String\[1024\] = concat\(',
            r'metadata_str: String[1024]\nmetadata_str = concat(',
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
        if fix_namespace_and_types(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
