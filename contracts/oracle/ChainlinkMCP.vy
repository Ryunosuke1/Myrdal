# @version ^0.4.1
# @title ChainlinkMCP - Chainlinkを介したMCP実行コントラクト
# @author Myrdal Team
# @notice このコントラクトはChainlinkを使用してMCPアクションを実行するためのインターフェースを提供します

# インポートパスを修正
# カスタムインターフェースのインポート
# IMCPIntegrationインターフェースを直接定義

# イベント定義
event ChainlinkRequestSent:
    request_id: bytes32
    task_id: bytes32
    job_id: bytes32


event ChainlinkResponseReceived:
    request_id: bytes32
    task_id: bytes32
    result_hash: bytes32


# ストレージ変数
owner: public(address)
mcp_integration: public(address)
chainlink_token: public(address)
oracle: public(address)
job_id: public(bytes32)
fee: public(uint256)
requests: public(HashMap[bytes32, bytes32])  # request_id -> task_id

# コンストラクタ
@deploy
def __init__(_mcp_integration: address, _chainlink_token: address, _oracle: address, _job_id: bytes32, _fee: uint256):
    """
    @notice ChainlinkMCPコントラクトを初期化します
    @param _mcp_integration MCPインテグレーションコントラクトのアドレス
    @param _chainlink_token Chainlinkトークンのアドレス
    @param _oracle Chainlinkオラクルのアドレス
    @param _job_id ChainlinkジョブID
    @param _fee Chainlinkリクエストの手数料
    """
    owner = sender
    mcp_integration = _mcp_integration
    chainlink_token = _chainlink_token
    oracle = _oracle
    job_id = _job_id
    fee = _fee

# 管理者関数
@external
def set_job_id(_job_id: bytes32) -> bool:
    """
@notice ジョブIDを設定します
@param _job_id 新しいジョブID
@return 成功したかどうか
"""
assert sender == owner, "Only owner can set job ID"
job_id = _job_id
return True

@external
def set_fee(_fee: uint256) -> bool:
    """
@notice 手数料を設定します
@param _fee 新しい手数料
@return 成功したかどうか
"""
assert sender == owner, "Only owner can set fee"
fee = _fee
return True

@external
def set_oracle(_oracle: address) -> bool:
    """
@notice オラクルアドレスを設定します
@param _oracle 新しいオラクルアドレス
@return 成功したかどうか
"""
assert sender == owner, "Only owner can set oracle"
oracle = _oracle
return True

# MCP実行リクエスト関数
@external
def requestMCPExecution(task_id: bytes32, action: String[100], params: String[1024]) -> bool:
    """
@notice MCPアクションの実行をリクエストします
@param task_id タスクID
@param action 実行するアクション
@param params アクションのパラメータ
@return 成功したかどうか
"""
# MCPインテグレーションからの呼び出しか確認
assert sender == mcp_integration, "Only MCP integration can request execution"

# Chainlinkトークンの承認
# ERC20インターフェースをインライン定義
interface ERC20:
    def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable
ERC20(chainlink_token).transferFrom(sender, self, fee)

# Chainlinkオラクルへのリクエスト
# インポートパスを修正
# カスタムインターフェースのインポート
# IChainlinkOracleインターフェースを直接定義
# データのエンコード（実際の実装ではより複雑なエンコーディングが必要）
data: bytes32
data = keccak256(concat(
task_id,
convert(action, bytes32),
convert(params, bytes32)
))

# リクエストの送信
request_id: bytes32

request_id = ChainlinkOracle(oracle).request(job_id, self, data)

# リクエストIDとタスクIDのマッピングを保存
requests[request_id] = task_id

# イベントの発行
log ChainlinkRequestSent(request_id, task_id, job_id)

return True

# Chainlinkコールバック関数
@external
def fulfill(request_id: bytes32, result: bytes32) -> bool:
    """
@notice Chainlinkからの結果を受け取ります
@param request_id リクエストID
@param result 結果データ
@return 成功したかどうか
"""
# オラクルからの呼び出しか確認
assert sender == oracle, "Only oracle can fulfill"

# リクエストIDからタスクIDを取得
task_id: bytes32

task_id = requests[request_id]
assert task_id != empty(bytes32), "Request ID not found"

# MCPインテグレーションに結果を送信
# インポートパスを修正
# カスタムインターフェースのインポート
# IMCPIntegrationインターフェースを直接定義
MCPIntegration(mcp_integration).receive_mcp_result(task_id, result)

# イベントの発行
log ChainlinkResponseReceived(request_id, task_id, result)

return True
