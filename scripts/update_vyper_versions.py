#!/usr/bin/env python3
"""
Vyperコントラクトのバージョン指定を更新するスクリプト
現在のVyperコンパイラ（0.4.1）と互換性を持たせるために
バージョン指定を更新します
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

def update_version(file_path):
    """ファイル内のVyperバージョン指定を更新"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # バージョン指定を検索して置換
    updated_content = re.sub(
        r'# @version \^0\.3\.[0-9]+',
        '# @version ^0.4.1',
        content
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
        if update_version(file_path):
            updated_count += 1
            print(f"更新: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを更新しました")

if __name__ == "__main__":
    main()
