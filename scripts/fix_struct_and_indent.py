#!/usr/bin/env python3
"""
Vyperコントラクトの構造体定義とインデント問題を修正するスクリプト
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

def fix_struct_definitions(file_path):
    """構造体定義の問題を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # ファイル名から推測されるインターフェース名
    file_name = os.path.basename(file_path)
    interface_name = os.path.splitext(file_name)[0]
    
    # インターフェースファイルの場合、構造体定義を直接追加
    if file_path.endswith('.vy') and 'interfaces' in file_path:
        # 既存の構造体定義を探す
        struct_match = re.search(r'struct (\w+):', content)
        if struct_match:
            struct_name = struct_match.group(1)
            # 他のファイルでこの構造体を使用している場合の修正
            updated_content = content
        else:
            updated_content = content
    else:
        # 非インターフェースファイルの場合、構造体の使用を修正
        # 例: IMemoryStorage.MemoryEntry -> MemoryEntry
        updated_content = re.sub(
            r'(\w+)\.(\w+) is not a type',
            r'\2 is not a type',
            content
        )
        
        # 構造体の使用を修正
        updated_content = re.sub(
            r'(\w+)\.(\w+)(\)|\})',
            r'\2\3',
            updated_content
        )
        
        # 構造体型の参照を修正
        updated_content = re.sub(
            r'HashMap\[\w+, (\w+)\.(\w+)\]',
            r'HashMap[\1, \2]',
            updated_content
        )
    
    # インデントの問題を修正
    lines = updated_content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        fixed_lines.append(line)
        
        # 関数定義の後に必ずインデントされたブロックがあることを確認
        if line.strip().startswith('def ') and line.strip().endswith(':'):
            # 次の行がない、または次の行がインデントされていない場合
            if i + 1 >= len(lines) or not lines[i + 1].startswith('    '):
                # パス文を追加
                fixed_lines.append('    pass')
        
        i += 1
    
    updated_content = '\n'.join(fixed_lines)
    
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
        if fix_struct_definitions(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
