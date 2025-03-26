#!/usr/bin/env python3
"""
Vyperコントラクトの関数定義後のインデント問題を修正するスクリプト
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

def fix_function_indentation(file_path):
    """関数定義後のインデントを修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 更新されたコンテンツを格納する変数
    updated_lines = []
    
    # 行ごとに処理
    lines = content.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]
        updated_lines.append(line)
        
        # 関数定義を検出
        if (line.strip().startswith('def ') and line.strip().endswith(':')) or \
           (line.strip().startswith('@') and i + 1 < len(lines) and lines[i+1].strip().startswith('def ') and lines[i+1].strip().endswith(':')):
            
            # デコレータがある場合は次の行に進む
            if line.strip().startswith('@'):
                updated_lines.append(lines[i+1])
                i += 1
            
            # 次の行がインデントされていない場合
            if i + 1 < len(lines) and not lines[i+1].startswith('    '):
                # ドキュメント文字列の場合
                if i + 1 < len(lines) and lines[i+1].strip().startswith('"""'):
                    # ドキュメント文字列をインデント
                    j = i + 1
                    while j < len(lines) and not lines[j].strip().endswith('"""'):
                        updated_lines.append('    ' + lines[j])
                        j += 1
                    
                    # 終了の三重引用符もインデント
                    if j < len(lines):
                        updated_lines.append('    ' + lines[j])
                        i = j
                else:
                    # 通常のコードブロックの場合、passを追加
                    updated_lines.append('    pass')
        
        i += 1
    
    # 更新されたコンテンツを文字列に変換
    updated_content = '\n'.join(updated_lines)
    
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
        if fix_function_indentation(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
