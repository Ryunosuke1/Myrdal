# Myrdalエージェント - セキュリティとプライバシー設計

## 1. Oasis Protocolのプライバシー機能の活用

### 1.1 Sapphireパラタイムの利用

Oasis Protocolの「Sapphire」パラタイムを活用し、機密スマートコントラクト（Confidential Smart Contract）として実装します。これにより以下の利点が得られます：

- **実行の機密性**: コントラクトの実行内容がブロックチェーン上で公開されない
- **状態の機密性**: コントラクトの状態データが暗号化されて保存される
- **入出力の機密性**: コントラクトへの入力と出力が保護される

### 1.2 TEE（Trusted Execution Environment）の活用

Sapphireパラタイムが提供するTEE内でコントラクトを実行することで、以下の保護を実現します：

- **メモリ保護**: 実行中のメモリ内容が他のプロセスから隔離される
- **コード整合性**: 実行されるコードが改ざんされていないことを保証
- **リモート証明**: クライアントがTEEの真正性を検証可能

## 2. データ暗号化戦略

### 2.1 オンチェーンデータの暗号化

```vyper
# 暗号化関数（Sapphireパラタイム内で実行）
@internal
def encrypt_data(data: String[1024], user_public_key: bytes32) -> bytes:
    # Sapphireの暗号化機能を使用
    return sapphire_encrypt(data, user_public_key)

# 復号関数（Sapphireパラタイム内で実行）
@internal
def decrypt_data(encrypted_data: bytes, user: address) -> String[1024]:
    # ユーザー認証後に復号
    assert msg.sender == user, "Unauthorized"
    return sapphire_decrypt(encrypted_data)
```

### 2.2 長期記憶の暗号化

MemoryStorageコントラクトでは、ユーザーの長期記憶を暗号化して保存します：

```vyper
# メモリの暗号化保存
@external
def store_encrypted_memory(content: String[1024], priority: uint8, tags: DynArray[String[32], 10]) -> bytes32:
    # コンテンツを暗号化
    encrypted_content: bytes = self.encrypt_data(content, self.user_public_keys[msg.sender])
    
    # メモリIDを生成
    memory_id: bytes32 = keccak256(concat(
        convert(msg.sender, bytes32),
        convert(block.timestamp, bytes32),
        convert(self.next_memory_id, bytes32)
    ))
    
    # 暗号化されたメモリを保存
    self.memories[memory_id] = MemoryEntry({
        id: memory_id,
        user: msg.sender,
        content: "",  # 平文は保存しない
        encrypted_content: encrypted_content,
        is_encrypted: True,
        priority: priority,
        created_at: block.timestamp,
        last_accessed: block.timestamp,
        access_count: 0,
        tags: tags
    })
    
    self.next_memory_id += 1
    return memory_id
```

## 3. アクセス制御と認証

### 3.1 ユーザー認証システム

UserAuthコントラクトでユーザー認証と権限管理を実装します：

```vyper
# ユーザー登録
@external
def register_user(public_key: bytes32) -> bool:
    assert self.users[msg.sender].user == ZERO_ADDRESS, "User already registered"
    
    self.users[msg.sender] = UserInfo({
        user: msg.sender,
        active: True,
        privacy_level: DEFAULT_PRIVACY_LEVEL,
        balance: 0,
        created_at: block.timestamp,
        last_active: block.timestamp,
        task_count: 0
    })
    
    self.user_public_keys[msg.sender] = public_key
    return True

# ユーザー認証
@internal
def authenticate_user(user: address) -> bool:
    assert self.users[user].active, "User not active"
    self.users[user].last_active = block.timestamp
    return True
```

### 3.2 機能ごとのアクセス制御

各コントラクトで機能ごとのアクセス制御を実装します：

```vyper
# アクセス制御修飾子
@internal
def only_owner() -> bool:
    assert msg.sender == self.owner, "Only owner"
    return True

@internal
def only_authorized() -> bool:
    assert self.authorized[msg.sender], "Not authorized"
    return True

@internal
def only_task_owner(task_id: bytes32) -> bool:
    assert self.tasks[task_id].user == msg.sender, "Not task owner"
    return True
```

## 4. プライバシーレベルの実装

ユーザーごとにプライバシーレベルを設定し、データの取り扱いを制御します：

```vyper
# プライバシーレベル定数
PRIVACY_LEVEL_PUBLIC: constant(uint8) = 0
PRIVACY_LEVEL_PROTECTED: constant(uint8) = 1
PRIVACY_LEVEL_PRIVATE: constant(uint8) = 2
PRIVACY_LEVEL_CONFIDENTIAL: constant(uint8) = 3

# プライバシーレベル設定
@external
def set_privacy_level(level: uint8) -> bool:
    assert level <= PRIVACY_LEVEL_CONFIDENTIAL, "Invalid privacy level"
    self.users[msg.sender].privacy_level = level
    return True

# プライバシーレベルに基づくデータ処理
@internal
def process_data_with_privacy(data: String[1024], user: address) -> String[1024]:
    privacy_level: uint8 = self.users[user].privacy_level
    
    if privacy_level == PRIVACY_LEVEL_PUBLIC:
        return data
    elif privacy_level == PRIVACY_LEVEL_PROTECTED:
        # 一部の機密情報をマスク
        return self.mask_sensitive_data(data)
    elif privacy_level == PRIVACY_LEVEL_PRIVATE:
        # データを暗号化して返す
        return "[Encrypted data]"
    else:  # PRIVACY_LEVEL_CONFIDENTIAL
        # データを完全に隔離
        return "[Confidential data]"
```

## 5. セキュアなオラクル連携

### 5.1 LLMオラクルのセキュリティ

OracleInterfaceコントラクトでLLMサービスとの安全な連携を実装します：

```vyper
# セキュアなLLMリクエスト
@external
def request_secure_llm_completion(
    prompt: String[1024], 
    callback_address: address, 
    callback_function_selector: bytes4
) -> bytes32:
    # ユーザー認証
    assert self.user_auth.authenticate_user(msg.sender), "Authentication failed"
    
    # リクエストIDを生成
    request_id: bytes32 = keccak256(concat(
        convert(msg.sender, bytes32),
        convert(block.timestamp, bytes32),
        convert(self.next_request_id, bytes32)
    ))
    
    # プライバシーレベルに基づいてプロンプトを処理
    privacy_level: uint8 = self.user_auth.get_privacy_level(msg.sender)
    processed_prompt: String[1024] = prompt
    
    if privacy_level >= PRIVACY_LEVEL_PROTECTED:
        # 機密情報をマスク
        processed_prompt = self.mask_sensitive_info(prompt)
    
    # リクエストを保存
    self.requests[request_id] = LLMRequest({
        id: request_id,
        user: msg.sender,
        prompt: processed_prompt,
        callback_address: callback_address,
        callback_function_selector: callback_function_selector,
        created_at: block.timestamp,
        fulfilled: False,
        result: ""
    })
    
    self.next_request_id += 1
    
    # オラクルにリクエストを送信
    self._send_to_oracle(request_id, processed_prompt)
    
    return request_id
```

### 5.2 MCPオラクルのセキュリティ

MCPIntegrationコントラクトでMCPサーバーとの安全な連携を実装します：

```vyper
# セキュアなMCPリクエスト
@external
def request_secure_mcp_action(
    server_id: uint256,
    action_data: String[1024],
    callback_address: address,
    callback_function_selector: bytes4
) -> bytes32:
    # ユーザー認証
    assert self.user_auth.authenticate_user(msg.sender), "Authentication failed"
    
    # リクエストIDを生成
    request_id: bytes32 = keccak256(concat(
        convert(msg.sender, bytes32),
        convert(block.timestamp, bytes32),
        convert(self.next_request_id, bytes32)
    ))
    
    # アクションデータを検証
    assert self._validate_action_data(action_data), "Invalid action data"
    
    # リクエストを保存
    self.requests[request_id] = MCPRequest({
        id: request_id,
        user: msg.sender,
        server_id: server_id,
        action_data: action_data,
        callback_address: callback_address,
        callback_function_selector: callback_function_selector,
        created_at: block.timestamp,
        fulfilled: False,
        result: ""
    })
    
    self.next_request_id += 1
    
    # MCPサーバーにリクエストを送信
    self._send_to_mcp_server(request_id, server_id, action_data)
    
    return request_id
```

## 6. セキュリティ監査と脆弱性対策

### 6.1 コントラクトセキュリティ対策

- **再入攻撃対策**: 状態変更を関数の最後に行う、またはリエントランシーガードを使用
- **整数オーバーフロー対策**: SafeMathパターンの使用
- **アクセス制御**: 適切な認証と権限チェック
- **ガス制限対策**: ループの制限とガス効率の最適化

### 6.2 オフチェーンセキュリティ対策

- **MCPサーバーのセキュリティ**: サーバーアクセス制限とリクエスト検証
- **Chainlinkノードのセキュリティ**: 安全なコード実行環境とリソース制限
- **Fileverseアップローダーのセキュリティ**: ファイル検証とマルウェアスキャン

## 7. 緊急時対応計画

### 7.1 緊急停止機能

```vyper
# 緊急停止フラグ
paused: public(bool)

# 緊急停止修飾子
@internal
def not_paused() -> bool:
    assert not self.paused, "Contract is paused"
    return True

# 緊急停止関数
@external
def pause():
    assert msg.sender == self.owner, "Only owner"
    self.paused = True

# 再開関数
@external
def unpause():
    assert msg.sender == self.owner, "Only owner"
    self.paused = False
```

### 7.2 アップグレード機能

プロキシパターンを使用して、コントラクトのアップグレードを可能にします：

```vyper
# 実装コントラクトアドレス
implementation: public(address)

# アップグレード関数
@external
def upgrade(new_implementation: address):
    assert msg.sender == self.owner, "Only owner"
    assert new_implementation != ZERO_ADDRESS, "Invalid implementation"
    self.implementation = new_implementation
```
