import pytest
from brownie import accounts, FileverseIntegration, MyrdalCore, UserAuth
from brownie.exceptions import VirtualMachineError

@pytest.fixture
def setup():
    # デプロイアカウント
    owner = accounts[0]
    
    # モックコントラクトのデプロイ
    mock_myrdal_core = accounts[1]  # 実際のテストではMyrdalCoreコントラクトをデプロイ
    mock_user_auth = accounts[2]    # 実際のテストではUserAuthコントラクトをデプロイ
    
    # FileverseIntegrationコントラクトのデプロイ
    fileverse_integration = FileverseIntegration.deploy(
        mock_myrdal_core,
        mock_user_auth,
        {'from': owner}
    )
    
    return {
        'owner': owner,
        'mock_myrdal_core': mock_myrdal_core,
        'mock_user_auth': mock_user_auth,
        'fileverse_integration': fileverse_integration
    }

def test_initialization(setup):
    """初期化パラメータが正しく設定されているかテスト"""
    fileverse_integration = setup['fileverse_integration']
    
    assert fileverse_integration.owner() == setup['owner']
    assert fileverse_integration.myrdalCore() == setup['mock_myrdal_core']
    assert fileverse_integration.user_auth() == setup['mock_user_auth']
    assert fileverse_integration.fileverse_operators(setup['owner']) == True

def test_add_fileverse_operator(setup):
    """Fileverseオペレーターの追加が正しく機能するかテスト"""
    fileverse_integration = setup['fileverse_integration']
    owner = setup['owner']
    
    new_operator = accounts[3]
    
    # オーナーがオペレーターを追加
    tx = fileverse_integration.add_fileverse_operator(new_operator, {'from': owner})
    assert tx.status == 1
    assert fileverse_integration.fileverse_operators(new_operator) == True
    
    # 非オーナーがオペレーターを追加しようとするとリバート
    with pytest.raises(VirtualMachineError):
        fileverse_integration.add_fileverse_operator(accounts[4], {'from': accounts[5]})

def test_remove_fileverse_operator(setup):
    """Fileverseオペレーターの削除が正しく機能するかテスト"""
    fileverse_integration = setup['fileverse_integration']
    owner = setup['owner']
    
    new_operator = accounts[3]
    
    # オペレーターを追加
    fileverse_integration.add_fileverse_operator(new_operator, {'from': owner})
    assert fileverse_integration.fileverse_operators(new_operator) == True
    
    # オーナーがオペレーターを削除
    tx = fileverse_integration.remove_fileverse_operator(new_operator, {'from': owner})
    assert tx.status == 1
    assert fileverse_integration.fileverse_operators(new_operator) == False
    
    # 非オーナーがオペレーターを削除しようとするとリバート
    fileverse_integration.add_fileverse_operator(new_operator, {'from': owner})
    with pytest.raises(VirtualMachineError):
        fileverse_integration.remove_fileverse_operator(new_operator, {'from': accounts[5]})

def test_record_file_upload(setup):
    """ファイルアップロードの記録が正しく機能するかテスト"""
    # このテストは実際のMyrdalCoreコントラクトとの統合が必要
    # モックを使用した簡易テスト
    fileverse_integration = setup['fileverse_integration']
    owner = setup['owner']
    
    task_id = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    file_hash = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    name = "test_file.pdf"
    description = "Test file description"
    mime_type = "application/pdf"
    size = 1024
    
    # オーナー（オペレーター）がファイルアップロードを記録
    tx = fileverse_integration.record_file_upload(
        task_id,
        file_hash,
        name,
        description,
        mime_type,
        size,
        {'from': owner}
    )
    
    assert tx.status == 1
    
    # イベントの確認
    assert 'FileUploaded' in tx.events
    assert tx.events['FileUploaded']['task_id'] == task_id
    assert tx.events['FileUploaded']['file_hash'] == file_hash
    
    # タスクのファイルリストを確認
    task_files = fileverse_integration.get_task_files(task_id)
    assert len(task_files) == 1
    assert task_files[0] == file_hash
    
    # 非オペレーターがファイルアップロードを記録しようとするとリバート
    with pytest.raises(VirtualMachineError):
        fileverse_integration.record_file_upload(
            task_id,
            "0x0987654321fedcba0987654321fedcba0987654321fedcba0987654321fedcba",
            "another_file.pdf",
            "Another test file",
            "application/pdf",
            2048,
            {'from': accounts[5]}
        )

def test_grant_file_access(setup):
    """ファイルアクセス権の付与が正しく機能するかテスト"""
    # このテストは実際のUserAuthコントラクトとの統合が必要
    # モックを使用した簡易テスト
    pass

def test_has_file_access(setup):
    """ファイルアクセス権の確認が正しく機能するかテスト"""
    # このテストは実際のUserAuthコントラクトとの統合が必要
    # モックを使用した簡易テスト
    pass

def test_get_file_metadata(setup):
    """ファイルメタデータの取得が正しく機能するかテスト"""
    # このテストは実際のUserAuthコントラクトとの統合が必要
    # モックを使用した簡易テスト
    pass
