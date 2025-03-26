#!/usr/bin/env python3
"""
Vyperコントラクトの構文を修正するスクリプト
Vyper 0.4.1の新しい構文要件に合わせてコードを更新します
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

def fix_struct_initialization(content):
    """構造体の初期化方法を修正"""
    # 辞書形式の構造体初期化を引数形式に変更
    pattern = r'(\w+)\.(\w+)\(\{([^}]+)\}\)'
    
    def replace_struct(match):
        struct_module = match.group(1)
        struct_name = match.group(2)
        struct_fields = match.group(3)
        
        # フィールドを解析
        fields = []
        for field in struct_fields.split(','):
            if ':' in field:
                name, value = field.split(':', 1)
                fields.append(f"{name.strip()}={value.strip()}")
        
        return f"{struct_module}.{struct_name}({', '.join(fields)})"
    
    return re.sub(pattern, replace_struct, content)

def fix_for_loop_type_annotation(content):
    """for文の型アノテーションを追加"""
    # for i in range(...) を for i: uint256 in range(...) に変更
    pattern = r'for (\w+) in range\('
    replacement = r'for \1: uint256 in range('
    return re.sub(pattern, replacement, content)

def fix_interface_imports(content, file_path):
    """インターフェースのインポート方法を修正"""
    # 相対パスでのインポートを絶対パスに変更
    if 'import interfaces.' in content:
        # ファイルの相対位置に基づいてインポートパスを調整
        rel_path = os.path.relpath(file_path, CONTRACTS_DIR)
        depth = len(Path(rel_path).parts) - 1
        
        if depth > 0:
            # 上位ディレクトリへの参照を追加
            prefix = '../' * depth
            content = re.sub(
                r'import interfaces\.', 
                f'import {prefix}interfaces.', 
                content
            )
    
    return content

def fix_interface_declaration(content):
    """インターフェース宣言の構文を修正"""
    # interface Foo: を from vyper.interfaces import ERC20 のような形式に変更
    lines = content.split('\n')
    result_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # インターフェース宣言を検出
        interface_match = re.match(r'\s*interface (\w+):', line)
        if interface_match:
            interface_name = interface_match.group(1)
            
            # ERC20インターフェースの場合は標準インポートに置き換え
            if interface_name == 'ERC20':
                result_lines.append('from vyper.interfaces import ERC20')
            else:
                # カスタムインターフェースの場合はインポート文に変更
                result_lines.append(f'import interfaces.I{interface_name} as I{interface_name}')
            
            # インターフェース定義の本体をスキップ
            i += 1
            while i < len(lines) and (lines[i].strip() == '' or lines[i].strip().startswith('def ')):
                i += 1
        else:
            result_lines.append(line)
            i += 1
    
    return '\n'.join(result_lines)

def fix_vyper_syntax(file_path):
    """ファイル内のVyper構文を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 各種修正を適用
    updated_content = content
    updated_content = fix_struct_initialization(updated_content)
    updated_content = fix_for_loop_type_annotation(updated_content)
    updated_content = fix_interface_imports(updated_content, file_path)
    updated_content = fix_interface_declaration(updated_content)
    
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
        if fix_vyper_syntax(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
