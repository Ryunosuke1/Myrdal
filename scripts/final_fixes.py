#!/usr/bin/env python3
"""
Vyperコントラクトの最終修正スクリプト
構造体型参照、コンストラクタ、インデント問題を修正します
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

def fix_contract_issues(file_path):
    """コントラクトの問題を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 更新されたコンテンツ
    updated_content = content
    
    # 1. 構造体型参照の修正
    # IUserAuth.UserInfo -> UserInfo など
    updated_content = re.sub(
        r'(\w+)\.(\w+)([^a-zA-Z0-9_])',
        r'\2\3',
        updated_content
    )
    
    # 2. コンストラクタに@deploy修飾子を追加
    updated_content = re.sub(
        r'@external\s+def __init__',
        r'@deploy\ndef __init__',
        updated_content
    )
    
    # 3. インデント問題の修正
    lines = updated_content.split('\n')
    fixed_lines = []
    i = 0
    in_function = False
    
    while i < len(lines):
        line = lines[i]
        
        # 関数定義の開始を検出
        if re.match(r'^\s*def\s+\w+\s*\(.*\):', line):
            in_function = True
            fixed_lines.append(line)
            
            # 次の行がインデントされていない場合、passを追加
            if i + 1 < len(lines) and not lines[i + 1].startswith('    '):
                fixed_lines.append('    pass')
            
        # インデントされた行がある場合、関数内のコードブロックとして処理
        elif in_function and line.startswith('    '):
            fixed_lines.append(line)
            
            # 関数内のコードブロックの終了を検出
            if i + 1 < len(lines) and not lines[i + 1].startswith('    '):
                in_function = False
        
        # 予期しないインデントを修正
        elif line.startswith('    ') and not in_function:
            fixed_lines.append(line.lstrip())
        
        else:
            fixed_lines.append(line)
            if line.strip() == '':
                in_function = False
        
        i += 1
    
    updated_content = '\n'.join(fixed_lines)
    
    # 4. 構造体定義を直接追加
    # 各コントラクトファイルに必要な構造体を直接定義
    if 'UserAuth.vy' in file_path:
        struct_def = """
# ユーザー情報の構造体
struct UserInfo:
    id: bytes32
    address: address
    name: String[100]
    email: String[100]
    created_at: uint256
    last_login: uint256
    role: uint8
    is_active: bool
"""
        updated_content = re.sub(r'# User storage', struct_def + '\n# User storage', updated_content)
    
    elif 'MemoryStorage.vy' in file_path:
        struct_def = """
# メモリエントリの構造体
struct MemoryEntry:
    id: bytes32
    owner: address
    task_id: bytes32
    content: String[1024]
    tags: DynArray[String[50], 10]
    created_at: uint256
    is_public: bool
"""
        updated_content = re.sub(r'# Memory storage', struct_def + '\n# Memory storage', updated_content)
    
    elif 'MCPIntegration.vy' in file_path:
        struct_def = """
# MCPリクエストの構造体
struct MCPRequest:
    id: bytes32
    owner: address
    task_id: bytes32
    prompt: String[1024]
    status: uint8
    created_at: uint256
    completed_at: uint256
    result: String[1024]
"""
        updated_content = re.sub(r'# Request storage', struct_def + '\n# Request storage', updated_content)
        # HashMap[IMCPIntegration, MCPRequest] を修正
        updated_content = re.sub(
            r'HashMap\[IMCPIntegration, MCPRequest\]',
            r'HashMap[bytes32, MCPRequest]',
            updated_content
        )
    
    elif 'OracleInterface.vy' in file_path:
        struct_def = """
# オラクルリクエストの構造体
struct OracleRequest:
    id: bytes32
    owner: address
    task_id: bytes32
    query: String[1024]
    status: uint8
    created_at: uint256
    completed_at: uint256
    result: String[1024]
"""
        updated_content = re.sub(r'# Request storage', struct_def + '\n# Request storage', updated_content)
        # HashMap[IOracleInterface, OracleRequest] を修正
        updated_content = re.sub(
            r'HashMap\[IOracleInterface, OracleRequest\]',
            r'HashMap[bytes32, OracleRequest]',
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
        if fix_contract_issues(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
