#!/usr/bin/env python3
"""
Vyperコントラクトのインポート構文を修正するスクリプト（改良版）
Vyper 0.4.1の新しいインポート構文要件に合わせてコードを更新します
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

def fix_import_syntax(file_path):
    """ファイル内のインポート構文を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 相対パスのインポートを修正
    # import ../interfaces.IMemoryStorage as IMemoryStorage -> from .. import interfaces.IMemoryStorage as IMemoryStorage
    updated_content = re.sub(
        r'import \.\./interfaces\.(\w+) as (\w+)',
        r'# インポートパスを修正\nfrom vyper.interfaces import \1 as \2',
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
        if fix_import_syntax(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
