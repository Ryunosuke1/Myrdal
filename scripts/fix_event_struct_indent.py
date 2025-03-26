#!/usr/bin/env python3
"""
Vyperコントラクトのイベントとstruct定義のインデント問題を修正するスクリプト
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

def fix_indentation(file_path):
    """イベントとstruct定義のインデントを修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 更新されたコンテンツを格納する変数
    updated_content = []
    
    # 行ごとに処理
    lines = content.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # イベント定義を検出
        if line.strip().startswith('event ') and line.strip().endswith(':'):
            updated_content.append(line)
            
            # 次の行からイベントのフィールドを処理
            i += 1
            while i < len(lines) and lines[i].strip() and not lines[i].strip().startswith('#') and not lines[i].strip().startswith('event ') and not lines[i].strip().startswith('struct ') and not lines[i].strip().startswith('def '):
                # インデントを追加
                updated_content.append('    ' + lines[i].strip())
                i += 1
            
            # 空行を追加
            if i < len(lines):
                updated_content.append('')
        
        # 構造体定義を検出
        elif line.strip().startswith('struct ') and line.strip().endswith(':'):
            updated_content.append(line)
            
            # 次の行から構造体のフィールドを処理
            i += 1
            while i < len(lines) and lines[i].strip() and not lines[i].strip().startswith('#') and not lines[i].strip().startswith('event ') and not lines[i].strip().startswith('struct ') and not lines[i].strip().startswith('def '):
                # インデントを追加
                updated_content.append('    ' + lines[i].strip())
                i += 1
            
            # 空行を追加
            if i < len(lines):
                updated_content.append('')
        
        else:
            updated_content.append(line)
            i += 1
    
    # 更新されたコンテンツを文字列に変換
    updated_content_str = '\n'.join(updated_content)
    
    # 変更があった場合のみファイルを更新
    if content != updated_content_str:
        with open(file_path, 'w') as file:
            file.write(updated_content_str)
        return True
    return False

def main():
    """メイン関数"""
    vyper_files = find_vyper_files(CONTRACTS_DIR)
    updated_count = 0
    
    for file_path in vyper_files:
        if fix_indentation(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
