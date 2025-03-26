#!/usr/bin/env python3
"""
Vyperコントラクトの最終修正スクリプト（詳細手動修正版）
残りのすべてのコンパイルエラーを修正します
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

def fix_all_remaining_issues(file_path):
    """残りのすべてのコンパイルエラーを修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 更新されたコンテンツ
    updated_content = content
    
    # 1. 関数定義後のインデント問題を修正
    # def で始まり : で終わる行を検出し、次の行にインデントがない場合は追加
    lines = updated_content.split('\n')
    i = 0
    fixed_lines = []
    
    while i < len(lines):
        line = lines[i]
        fixed_lines.append(line)
        
        # 関数定義を検出
        if line.strip().startswith('def ') and line.strip().endswith(':'):
            # 次の行がインデントされていない場合
            if i + 1 < len(lines) and not lines[i+1].startswith('    '):
                # passを追加
                fixed_lines.append('    pass')
        
        # 制御構造（if, for, while）を検出
        elif (line.strip().startswith('if ') or line.strip().startswith('for ') or line.strip().startswith('while ')) and line.strip().endswith(':'):
            # 次の行がインデントされていない場合
            if i + 1 < len(lines) and not lines[i+1].startswith('    '):
                # 次の行をインデントして追加
                fixed_lines.append('    ' + lines[i+1])
                i += 2
                continue
        
        i += 1
    
    updated_content = '\n'.join(fixed_lines)
    
    # 2. ローカル変数の初期化問題を修正
    # 変数宣言と初期化を分離
    updated_content = re.sub(
        r'(\s+)([a-zA-Z_][a-zA-Z0-9_]*): ([a-zA-Z_][a-zA-Z0-9_]*) = (.+)',
        r'\1\2: \3\n\1\2 = \4',
        updated_content
    )
    
    # 3. 特定のファイルに対する追加の修正
    file_name = os.path.basename(file_path)
    
    # MyrdalCore.vyの修正
    if file_name == "MyrdalCore.vy":
        # _agent_loop_submit_resultsの修正
        updated_content = re.sub(
            r'def _agent_loop_submit_results\(task_id: bytes32, final_result: String\[1024\], memory_ids: DynArray\[bytes32, 10\]\):',
            r'def _agent_loop_submit_results(task_id: bytes32, final_result: String[1024], memory_ids: DynArray[bytes32, 10]):\n    pass',
            updated_content
        )
    
    # UserAuth.vyの修正
    elif file_name == "UserAuth.vy":
        # old_levelの修正
        updated_content = re.sub(
            r'old_level: uint8 = users\[sender\]\.privacy_level',
            r'old_level: uint8\nold_level = users[sender].privacy_level',
            updated_content
        )
    
    # MemoryStorage.vyの修正
    elif file_name == "MemoryStorage.vy":
        # for文のインデント修正
        updated_content = re.sub(
            r'for j: uint256 in range\(100\):\nif j >= len\(tag_memories\):\nbreak',
            r'for j: uint256 in range(100):\n    if j >= len(tag_memories):\n        break',
            updated_content
        )
    
    # MCPIntegration.vyの修正
    elif file_name == "MCPIntegration.vy":
        # requestの修正
        updated_content = re.sub(
            r'request: MCPRequest = MCPRequest\((.+)\)',
            r'request: MCPRequest\nrequest = MCPRequest(\1)',
            updated_content
        )
    
    # OracleInterface.vyの修正
    elif file_name == "OracleInterface.vy":
        # requestの修正
        updated_content = re.sub(
            r'request: OracleRequest = OracleRequest\((.+)\)',
            r'request: OracleRequest\nrequest = OracleRequest(\1)',
            updated_content
        )
    
    # ChainlinkMCP.vyの修正
    elif file_name == "ChainlinkMCP.vy":
        # request_idの修正
        updated_content = re.sub(
            r'request_id: bytes32 = ChainlinkOracle\(oracle\)\.request\((.+)\)',
            r'request_id: bytes32\nrequest_id = ChainlinkOracle(oracle).request(\1)',
            updated_content
        )
    
    # FileverseIntegration.vyの修正
    elif file_name == "FileverseIntegration.vy":
        # if文のインデント修正
        updated_content = re.sub(
            r'if task_owner != empty\(address\):\nfile_access\[file_hash\]\[task_owner\] = True',
            r'if task_owner != empty(address):\n    file_access[file_hash][task_owner] = True',
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
        if fix_all_remaining_issues(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
