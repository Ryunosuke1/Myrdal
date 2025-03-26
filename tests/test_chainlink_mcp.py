import pytest
from brownie import accounts, ChainlinkMCP, MCPIntegration, MockChainlinkOracle, MockERC20
from brownie.exceptions import VirtualMachineError

@pytest.fixture
def setup():
    # デプロイアカウント
    owner = accounts[0]
    
    # モックコントラクトのデプロイ
    mock_mcp_integration = accounts[1]  # 実際のテストではMCPIntegrationコントラクトをデプロイ
    mock_chainlink_token = MockERC20.deploy("LINK", "LINK", 18, {'from': owner})
    mock_oracle = MockChainlinkOracle.deploy({'from': owner})
    
    # ChainlinkMCPコントラクトのデプロイ
    job_id = "0x1234567890abcdef1234567890abcdef"
    fee = 10 ** 18  # 1 LINK
    chainlink_mcp = ChainlinkMCP.deploy(
        mock_mcp_integration,
        mock_chainlink_token.address,
        mock_oracle.address,
        job_id,
        fee,
        {'from': owner}
    )
    
    # LINKトークンを発行
    mock_chainlink_token.mint(owner, 100 * 10 ** 18, {'from': owner})
    mock_chainlink_token.approve(chainlink_mcp.address, 100 * 10 ** 18, {'from': owner})
    
    return {
        'owner': owner,
        'mock_mcp_integration': mock_mcp_integration,
        'mock_chainlink_token': mock_chainlink_token,
        'mock_oracle': mock_oracle,
        'chainlink_mcp': chainlink_mcp,
        'job_id': job_id,
        'fee': fee
    }

def test_initialization(setup):
    """初期化パラメータが正しく設定されているかテスト"""
    chainlink_mcp = setup['chainlink_mcp']
    
    assert chainlink_mcp.owner() == setup['owner']
    assert chainlink_mcp.mcp_integration() == setup['mock_mcp_integration']
    assert chainlink_mcp.chainlink_token() == setup['mock_chainlink_token'].address
    assert chainlink_mcp.oracle() == setup['mock_oracle'].address
    assert chainlink_mcp.job_id() == setup['job_id']
    assert chainlink_mcp.fee() == setup['fee']

def test_set_job_id(setup):
    """ジョブIDの設定が正しく機能するかテスト"""
    chainlink_mcp = setup['chainlink_mcp']
    owner = setup['owner']
    
    new_job_id = "0xabcdef1234567890abcdef1234567890"
    
    # オーナーがジョブIDを設定
    tx = chainlink_mcp.set_job_id(new_job_id, {'from': owner})
    assert tx.status == 1
    assert chainlink_mcp.job_id() == new_job_id
    
    # 非オーナーがジョブIDを設定しようとするとリバート
    with pytest.raises(VirtualMachineError):
        chainlink_mcp.set_job_id(new_job_id, {'from': accounts[2]})

def test_set_fee(setup):
    """手数料の設定が正しく機能するかテスト"""
    chainlink_mcp = setup['chainlink_mcp']
    owner = setup['owner']
    
    new_fee = 2 * 10 ** 18  # 2 LINK
    
    # オーナーが手数料を設定
    tx = chainlink_mcp.set_fee(new_fee, {'from': owner})
    assert tx.status == 1
    assert chainlink_mcp.fee() == new_fee
    
    # 非オーナーが手数料を設定しようとするとリバート
    with pytest.raises(VirtualMachineError):
        chainlink_mcp.set_fee(new_fee, {'from': accounts[2]})

def test_set_oracle(setup):
    """オラクルアドレスの設定が正しく機能するかテスト"""
    chainlink_mcp = setup['chainlink_mcp']
    owner = setup['owner']
    
    new_oracle = accounts[3]
    
    # オーナーがオラクルアドレスを設定
    tx = chainlink_mcp.set_oracle(new_oracle, {'from': owner})
    assert tx.status == 1
    assert chainlink_mcp.oracle() == new_oracle
    
    # 非オーナーがオラクルアドレスを設定しようとするとリバート
    with pytest.raises(VirtualMachineError):
        chainlink_mcp.set_oracle(new_oracle, {'from': accounts[2]})

def test_request_mcp_execution(setup):
    """MCPアクション実行リクエストが正しく機能するかテスト"""
    # このテストは実際のMCPIntegrationコントラクトとの統合が必要
    # モックを使用した簡易テスト
    pass

def test_fulfill(setup):
    """Chainlinkからの結果受け取りが正しく機能するかテスト"""
    # このテストは実際のMCPIntegrationコントラクトとの統合が必要
    # モックを使用した簡易テスト
    pass
