#!/usr/bin/env python3
"""
Vyperコントラクトのインポートパスとインデントを修正するスクリプト
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

def fix_import_paths(content, file_path):
    """インポートパスを修正"""
    # ファイルの相対位置を取得
    rel_path = os.path.relpath(file_path, CONTRACTS_DIR)
    contract_dir = os.path.dirname(rel_path)
    
    # インポートパスを修正
    lines = content.split('\n')
    updated_lines = []
    
    for line in lines:
        if line.strip().startswith('import interfaces.'):
            # 現在のディレクトリからinterfacesディレクトリへの相対パスを計算
            depth = len(contract_dir.split(os.sep))
            rel_import_path = '../' * depth if depth > 0 else ''
            
            # インポートパスを修正
            updated_line = line.replace('import interfaces.', f'import {rel_import_path}interfaces.')
            updated_lines.append(updated_line)
        else:
            updated_lines.append(line)
    
    return '\n'.join(updated_lines)

def fix_indentation(content):
    """インデントの問題を修正"""
    # インターフェースのインポート後のインデントを修正
    lines = content.split('\n')
    i = 0
    updated_lines = []
    
    while i < len(lines):
        line = lines[i]
        updated_lines.append(line)
        
        # インポート文の後に不適切なインデントがある場合
        if line.strip().startswith('import') and i + 1 < len(lines) and lines[i + 1].startswith('    '):
            # インデントを削除して新しい文として扱う
            updated_lines.append(lines[i + 1].lstrip())
            i += 2
        else:
            i += 1
    
    # 関数定義の後にインデントがない場合の修正
    content = '\n'.join(updated_lines)
    pattern = r'(def \w+\([^)]*\):[^\n]*)\n([^\s])'
    replacement = r'\1\n    \2'
    content = re.sub(pattern, replacement, content)
    
    return content

def fix_vyper_file(file_path):
    """ファイルのインポートパスとインデントを修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 修正を適用
    updated_content = content
    updated_content = fix_import_paths(updated_content, file_path)
    updated_content = fix_indentation(updated_content)
    
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
        if fix_vyper_file(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
