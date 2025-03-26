import os
from web3 import Web3
from vyper import compile_code

# Oasis Testnet設定
OASIS_TESTNET_RPC = "https://testnet.oasis.dev/"
CHAIN_ID = 42261  # Oasis Testnetのchain ID

def load_contract_source():
    """コントラクトのソースコードを読み込む"""
    contract_path = os.path.join('contracts', 'enhanced', 'MyrdalCore.vy')
    with open(contract_path, 'r') as file:
        return file.read()

def compile_contract(source_code):
    """Vyperコントラクトをコンパイル"""
    compiled = compile_code(
        source_code,
        ['abi', 'bytecode'],
        output_formats=['combined_json']
    )
    return compiled['abi'], compiled['bytecode']

def deploy_contract(w3, abi, bytecode, deployer_address):
    """コントラクトをデプロイ"""
    contract = w3.eth.contract(abi=abi, bytecode=bytecode)
    
    # デプロイトランザクションの作成
    tx = contract.constructor().build_transaction({
        'from': deployer_address,
        'nonce': w3.eth.get_transaction_count(deployer_address),
        'gas': 4000000,
        'gasPrice': w3.eth.gas_price,
        'chainId': CHAIN_ID
    })
    
    return tx

def main():
    # Web3インスタンスの作成
    w3 = Web3(Web3.HTTPProvider(OASIS_TESTNET_RPC))
    print(f"Connected to Oasis Testnet: {w3.is_connected()}")

    # プライベートキーの設定（環境変数から取得）
    private_key = os.getenv('DEPLOYER_PRIVATE_KEY')
    if not private_key:
        raise ValueError("DEPLOYER_PRIVATE_KEY environment variable not set")

    # アカウントの設定
    account = w3.eth.account.from_key(private_key)
    deployer_address = account.address
    print(f"Deployer address: {deployer_address}")

    try:
        # コントラクトのコンパイルとデプロイ
        source = load_contract_source()
        abi, bytecode = compile_contract(source)
        
        # デプロイトランザクションの作成
        tx = deploy_contract(w3, abi, bytecode, deployer_address)
        
        # トランザクションの署名
        signed_tx = w3.eth.account.sign_transaction(tx, private_key)
        
        # トランザクションの送信と待機
        tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        print(f"Deployment transaction sent. Hash: {tx_hash.hex()}")
        
        # トランザクションの完了を待機
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        contract_address = tx_receipt['contractAddress']
        
        print(f"Contract deployed successfully!")
        print(f"Contract address: {contract_address}")
        
        # デプロイ情報の保存
        with open('deployment_info.txt', 'w') as f:
            f.write(f"Network: Oasis Testnet\n")
            f.write(f"Contract Address: {contract_address}\n")
            f.write(f"Deployer Address: {deployer_address}\n")
            f.write(f"Transaction Hash: {tx_hash.hex()}\n")
            f.write(f"Block Number: {tx_receipt['blockNumber']}\n")
            f.write(f"Gas Used: {tx_receipt['gasUsed']}\n")

    except Exception as e:
        print(f"Deployment failed: {str(e)}")
        raise

if __name__ == "__main__":
    main()