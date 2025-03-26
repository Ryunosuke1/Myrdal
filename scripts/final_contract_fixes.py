#!/usr/bin/env python3
"""
Vyperコントラクトの最終修正スクリプト
インポート問題とインデント問題を解決します
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

def fix_imports_and_indents(file_path):
    """インポートとインデントの問題を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # カスタムインターフェースのインポートを修正
    updated_content = re.sub(
        r'from vyper\.interfaces import (\w+) as \1',
        r'# カスタムインターフェースのインポート\n# \1インターフェースを直接定義',
        content
    )
    
    # インデントの問題を修正
    lines = updated_content.split('\n')
    i = 0
    fixed_lines = []
    
    while i < len(lines):
        line = lines[i]
        fixed_lines.append(line)
        
        # 関数定義の後にインデントがない場合
        if line.strip().startswith('def ') and line.strip().endswith(':'):
            # 次の行がインデントされていない場合、インデントを追加
            if i + 1 < len(lines) and not lines[i + 1].startswith('    '):
                # コメントや空行でない場合のみインデントを追加
                if i + 1 < len(lines) and lines[i + 1].strip() and not lines[i + 1].strip().startswith('#'):
                    fixed_lines.append('    ' + lines[i + 1])
                    i += 2
                    continue
        
        # インポート後の不適切なインデントを修正
        if line.strip().startswith('from ') or line.strip().startswith('import '):
            # 次の行が不適切にインデントされている場合
            if i + 1 < len(lines) and lines[i + 1].startswith('    '):
                # インデントを削除
                fixed_lines.append(lines[i + 1].lstrip())
                i += 2
                continue
        
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
        if fix_imports_and_indents(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
