#!/usr/bin/env python3
"""
Vyperコントラクトをコンパイルし、ABIとバイトコードを生成するスクリプト
フロントエンドとの連携のためにABIをJSONファイルとして保存します
"""

import os
import json
import subprocess
from pathlib import Path

# プロジェクトのルートディレクトリ
ROOT_DIR = Path(__file__).parent.parent
CONTRACTS_DIR = ROOT_DIR / "contracts"
BUILD_DIR = ROOT_DIR / "build" / "contracts"
FRONTEND_ABI_DIR = ROOT_DIR / "frontend" / "lib" / "contracts"

# コンパイル対象のコントラクト
# CONTRACTS = [
#     {"path": "core/MyrdalCore.vy", "name": "MyrdalCore"},
#     {"path": "auth/UserAuth.vy", "name": "UserAuth"},
#     {"path": "memory/MemoryStorage.vy", "name": "MemoryStorage"},
#     {"path": "mcp/MCPIntegration.vy", "name": "MCPIntegration"},
#     {"path": "oracle/OracleInterface.vy", "name": "OracleInterface"},
#     {"path": "oracle/ChainlinkMCP.vy", "name": "ChainlinkMCP"},
#     {"path": "fileverse/FileverseIntegration.vy", "name": "FileverseIntegration"},
# ]
CONTRACTS = [
    {"path": "Myrdal.vy", "name": "Myrdal"}
]

def ensure_dir(directory):
    """ディレクトリが存在することを確認し、存在しない場合は作成する"""
    os.makedirs(directory, exist_ok=True)

def compile_contract(contract_path, output_path):
    """Vyperコントラクトをコンパイルし、ABIとバイトコードを生成する"""
    try:
        # vyperコマンドを使用してコンパイル
        abi_result = subprocess.run(
            ["vyper", "-f", "abi", contract_path],
            capture_output=True,
            text=True,
            check=True
        )
        
        bytecode_result = subprocess.run(
            ["vyper", "-f", "bytecode", contract_path],
            capture_output=True,
            text=True,
            check=True
        )
        
        # 結果を解析
        abi = json.loads(abi_result.stdout)
        bytecode = bytecode_result.stdout.strip()
        
        # 結果をJSONファイルとして保存
        output_data = {
            "abi": abi,
            "bytecode": bytecode
        }
        
        with open(output_path, "w") as f:
            json.dump(output_data, f, indent=2)
            
        return True, output_data
    except subprocess.CalledProcessError as e:
        print(f"コンパイルエラー: {e}")
        print(f"stderr: {e.stderr}")
        return False, None
    except Exception as e:
        print(f"エラー: {e}")
        return False, None

def main():
    """メイン関数"""
    # ビルドディレクトリとフロントエンドABIディレクトリを作成
    ensure_dir(BUILD_DIR)
    ensure_dir(FRONTEND_ABI_DIR)
    
    # 各コントラクトをコンパイル
    for contract in CONTRACTS:
        contract_path = CONTRACTS_DIR / contract["path"]
        output_path = BUILD_DIR / f"{contract['name']}.json"
        frontend_abi_path = FRONTEND_ABI_DIR / f"{contract['name']}.json"
        
        print(f"コンパイル中: {contract_path}")
        success, data = compile_contract(contract_path, output_path)
        
        if success:
            print(f"コンパイル成功: {output_path}")
            
            # フロントエンド用にABIのみを保存
            with open(frontend_abi_path, "w") as f:
                json.dump({"abi": data["abi"]}, f, indent=2)
            
            print(f"フロントエンド用ABIを保存: {frontend_abi_path}")
        else:
            print(f"コンパイル失敗: {contract_path}")

if __name__ == "__main__":
    main()
