#!/usr/bin/env python3
"""
Vyperコントラクトの最終修正スクリプト
制御構造のインデントとローカル変数の初期化問題を修正します
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

def fix_control_structures_and_variables(file_path):
    """制御構造のインデントとローカル変数の初期化問題を修正"""
    with open(file_path, 'r') as file:
        content = file.read()
    
    # 更新されたコンテンツを格納する変数
    updated_lines = []
    
    # 行ごとに処理
    lines = content.split('\n')
    i = 0
    in_function = False
    
    while i < len(lines):
        line = lines[i]
        
        # 関数定義を検出
        if (line.strip().startswith('def ') and line.strip().endswith(':')) or \
           (line.strip().startswith('@') and i + 1 < len(lines) and lines[i+1].strip().startswith('def ')):
            in_function = True
            updated_lines.append(line)
            
            # デコレータがある場合は次の行も追加
            if line.strip().startswith('@') and i + 1 < len(lines) and lines[i+1].strip().startswith('def '):
                i += 1
                updated_lines.append(lines[i])
        
        # 制御構造（if, for, while）を検出
        elif in_function and (line.strip().startswith('if ') or line.strip().startswith('for ') or line.strip().startswith('while ')) and line.strip().endswith(':'):
            updated_lines.append(line)
            
            # 次の行がインデントされていない場合
            if i + 1 < len(lines) and not lines[i+1].startswith(' ' * (len(line) - len(line.lstrip()) + 4)):
                # 次の行をインデントして追加
                next_line = lines[i+1]
                updated_lines.append(' ' * (len(line) - len(line.lstrip()) + 4) + next_line.lstrip())
                i += 2
                continue
        
        # コンストラクタ本体のインデント
        elif line.strip() == ')' and i + 1 < len(lines) and not lines[i+1].startswith('    '):
            updated_lines.append(line)
            
            # 次の行がコンストラクタ本体の開始と思われる場合
            if i + 1 < len(lines) and '=' in lines[i+1] and not lines[i+1].strip().startswith('#'):
                # インデントを追加
                updated_lines.append('    ' + lines[i+1].lstrip())
                i += 2
                continue
        
        # ローカル変数の初期化問題を修正
        elif in_function and ':' in line and '=' in line and not line.strip().startswith('#'):
            # 変数宣言と初期化を分離
            var_parts = line.split('=', 1)
            var_decl = var_parts[0].strip()
            var_init = var_parts[1].strip()
            
            # 型指定がある場合
            if ':' in var_decl:
                var_name = var_decl.split(':', 1)[0].strip()
                var_type = var_decl.split(':', 1)[1].strip()
                
                # 変数宣言のみを追加
                updated_lines.append(line.replace('=', '').replace(var_init, '').rstrip())
                
                # 初期化を別の行に
                indent = len(line) - len(line.lstrip())
                updated_lines.append(' ' * indent + var_name + ' = ' + var_init)
                
                i += 1
                continue
            else:
                updated_lines.append(line)
        
        else:
            updated_lines.append(line)
        
        # 関数の終了を検出
        if in_function and line.strip() == '' and i + 1 < len(lines) and not lines[i+1].startswith('    '):
            in_function = False
        
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
        if fix_control_structures_and_variables(file_path):
            updated_count += 1
            print(f"修正: {file_path}")
    
    print(f"合計 {len(vyper_files)} ファイル中 {updated_count} ファイルを修正しました")

if __name__ == "__main__":
    main()
