# @version ^0.4.1
# @title FileverseIntegration - Fileverseでの成果物提供コントラクト
# @author Myrdal Team
# @notice このコントラクトはFileverseを使用して成果物を提供するためのインターフェースを提供します

# インポートパスを修正
# カスタムインターフェースのインポート
# IUserAuthインターフェースを直接定義

# イベント定義
event FileUploaded:
    task_id: bytes32
    file_hash: bytes32
    metadata: String[1024]
    uploader: address


event FileAccessGranted:
    file_hash: bytes32
    user: address
    grantor: address


# ファイルメタデータ構造体
struct FileMetadata:
    file_hash: bytes32
    uploader: address
    name: String[256]
    description: String[512]
    mime_type: String[64]
    size: uint256
    upload_timestamp: uint256
    task_id: bytes32


# ストレージ変数
owner: public(address)
myrdalCore: public(address)
user_auth: public(address)
fileverse_operators: public(HashMap[address, bool])
task_files: public(HashMap[bytes32, DynArray[bytes32, 100]])
file_metadata: public(HashMap[bytes32, FileMetadata])
user_files: public(HashMap[address, DynArray[bytes32, 100]])
file_access: public(HashMap[bytes32, HashMap[address, bool]])

# コンストラクタ
@deploy
def __init__(_myrdalCore: address, _user_auth: address):
    """
    @notice FileverseIntegrationコントラクトを初期化します
    @param _myrdalCore MyrdalCoreコントラクトのアドレス
    @param _user_auth UserAuthコントラクトのアドレス
    """
    owner = sender
    myrdalCore = _myrdalCore
    user_auth = _user_auth
    fileverse_operators[sender] = True

# 管理者関数
@external
def add_fileverse_operator(operator: address) -> bool:
    """
@notice Fileverseオペレーターを追加します
@param operator オペレーターのアドレス
@return 成功したかどうか
"""
assert sender == owner, "Only owner can add operators"
fileverse_operators[operator] = True
return True

@external
def remove_fileverse_operator(operator: address) -> bool:
    """
@notice Fileverseオペレーターを削除します
@param operator オペレーターのアドレス
@return 成功したかどうか
"""
assert sender == owner, "Only owner can remove operators"
fileverse_operators[operator] = False
return True

# ファイルアップロード記録関数（オフチェーンのFileverseマネージャーから呼び出される）
@external
def record_file_upload(
task_id: bytes32, 
file_hash: bytes32, 
name: String[256], 
description: String[512], 
mime_type: String[64], 
size: uint256
) -> bool:
    """
@notice ファイルのアップロードを記録します
@param task_id タスクID
@param file_hash ファイルハッシュ
@param name ファイル名
@param description ファイルの説明
@param mime_type MIMEタイプ
@param size ファイルサイズ
@return 成功したかどうか
"""
# オペレーターからの呼び出しか確認
assert fileverse_operators[sender], "Only authorized operators can record uploads"

# ファイルメタデータを作成
metadata: FileMetadata

metadata = FileMetadata(
file_hash=file_hash,
uploader=sender,
name=name,
description=description,
mime_type=mime_type,
size=size,
upload_timestamp: timestamp,
task_id=task_id
)

# タスクのファイルリストに追加
task_files[task_id].append(file_hash)

# ファイルのメタデータを保存
file_metadata[file_hash] = metadata

# アップローダーのファイルリストに追加
user_files[sender].append(file_hash)

# アップローダーにアクセス権を付与
file_access[file_hash][sender] = True

# タスク作成者にもアクセス権を付与
# インポートパスを修正
# カスタムインターフェースのインポート
# IMyrdalCoreインターフェースを直接定義
task_owner: address

task_owner = empty(address)
task_owner, _, _, _, _, _ = MyrdalCore(myrdalCore).get_task_details(task_id)

if task_owner != empty(address):
    file_access[file_hash][task_owner] = True
log FileAccessGranted(file_hash, task_owner, sender)

# イベントの発行
metadata_str: String[1024]
metadata_str = concat(
name, 
" (", 
mime_type, 
", ", 
convert(size, String[20]), 
" bytes)"
)
log FileUploaded(task_id, file_hash, metadata_str, sender)

return True

# ファイルアクセス権付与関数
@external
def grant_file_access(file_hash: bytes32, user: address) -> bool:
    """
@notice ファイルへのアクセス権を付与します
@param file_hash ファイルハッシュ
@param user アクセス権を付与するユーザー
@return 成功したかどうか
"""
# ファイルが存在するか確認
assert file_metadata[file_hash].file_hash == file_hash, "File not found"

# 呼び出し元がファイルのアップローダーか所有者か確認
assert file_metadata[file_hash].uploader == sender or sender == owner, "Not authorized"

# ユーザーが有効か確認
user_auth: IUserAuth

user_auth = IUserAuth(user_auth)
assert is_user_active(user), "User not active"

# アクセス権を付与
file_access[file_hash][user] = True

# イベントの発行
log FileAccessGranted(file_hash, user, sender)

return True

# ファイルアクセス権確認関数
@view
@external
def has_file_access(file_hash: bytes32, user: address) -> bool:
    """
@notice ユーザーがファイルへのアクセス権を持っているか確認します
@param file_hash ファイルハッシュ
@param user 確認するユーザー
@return アクセス権を持っているかどうか
"""
return file_access[file_hash][user]

# タスクのファイル一覧取得関数
@view
@external
def get_task_files(task_id: bytes32) -> DynArray[bytes32, 100]:
    """
@notice タスクに関連するファイルの一覧を取得します
@param task_id タスクID
@return ファイルハッシュの配列
"""
return task_files[task_id]

# ユーザーのファイル一覧取得関数
@view
@external
def get_user_files(user: address) -> DynArray[bytes32, 100]:
    """
@notice ユーザーがアップロードしたファイルの一覧を取得します
@param user ユーザーアドレス
@return ファイルハッシュの配列
"""
# 呼び出し元が対象ユーザーか所有者か確認
assert user == sender or sender == owner, "Not authorized"

return user_files[user]

# ファイルのメタデータ取得関数
@view
@external
def get_file_metadata(file_hash: bytes32) -> (String[256], String[512], String[64], uint256, uint256, address, bytes32):
    """
    @notice ファイルのメタデータを取得します
    @param file_hash ファイルハッシュ
    @return name, description, mime_type, size, upload_timestamp, uploader, task_id
    """
    # ファイルが存在するか確認
    metadata: FileMetadata
    metadata = file_metadata[file_hash]
    assert file_hash == file_hash, "File not found"
    
    # アクセス権を確認
    assert file_access[file_hash][sender] or sender == owner, "Not authorized"
    
    return (
        name,
        description,
        mime_type,
        size,
        upload_timestamp,
        uploader,
        task_id
    )
