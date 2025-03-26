# @version ^0.4.1
# @title User Authentication Contract
# @notice Contract for user authentication and privacy management
# @dev Implements the IUserAuth interface

# インポートパスを修正
# カスタムインターフェースのインポート
# IUserAuthインターフェースを直接定義

# Privacy level constants
PRIVACY_LEVEL_STANDARD: constant(uint8) = 1
PRIVACY_LEVEL_ENHANCED: constant(uint8) = 2
PRIVACY_LEVEL_MAXIMUM: constant(uint8) = 3

# Events
event UserRegistered:
    user: address
    privacy_level: uint8
    timestamp: uint256


event PrivacyLevelUpdated:
    user: address
    old_level: uint8
    new_level: uint8
    timestamp: uint256


event UserDeactivated:
    user: address
    timestamp: uint256


event UserReactivated:
    user: address
    timestamp: uint256


event FundsAdded:
    user: address
    amount: uint256
    timestamp: uint256


event FundsWithdrawn:
    user: address
    amount: uint256
    timestamp: uint256


# State variables
owner: public(address)
service_fee: public(uint256)  # Fee for using the service (in wei)


# ユーザー情報の構造体
struct UserInfo:
    id: bytes32
    address: address
    name: String[100]
    email: String[100]
    created_at: uint256
    last_login: uint256
    role: uint8
    is_active: bool


# User storage
users: public(HashMap[IUserAuth, UserInfo])
user_addresses: public(DynArray[address, 1000])

@deploy
def __init__(_service_fee: uint256):
    """
    @notice Initialize the User Authentication contract
    @param _service_fee Fee for using the service (in wei)
    """
    owner = sender
    service_fee = _service_fee

@external
def register_user(privacy_level: uint8) -> bool:
    """
@notice Register a new user
@param privacy_level The desired privacy level
@return success Whether the registration was successful
"""
# Check if user is already registered
if users[sender].address != empty(address):
    return False

# Validate privacy level
assert privacy_level >= PRIVACY_LEVEL_STANDARD and privacy_level <= PRIVACY_LEVEL_MAXIMUM, "Invalid privacy level"

# Create user
user: UserInfo
user = UserInfo(address=sender, registered_at=timestamp, active=True, privacy_level=privacy_level, payment_balance=0)

# Store user
users[sender] = user
user_addresses.append(sender)

# Emit event
log UserRegistered(sender, privacy_level, timestamp)

return True

@external
@view
def is_user_active(user: address) -> bool:
    """
@notice Check if a user is registered and active
@param user The address of the user to check
@return is_active Whether the user is registered and active
"""
return users[user].active

@external
@view
def get_user_info(user: address) -> UserInfo:
    """
@notice Get user information
@param user The address of the user
@return UserInfo The user information
"""
# Only the user or the owner can get user info
assert user == sender or sender == owner, "Not authorized"

return users[user]

@external
def update_privacy_level(new_privacy_level: uint8) -> bool:
    """
@notice Update user privacy level
@param new_privacy_level The new privacy level
@return success Whether the update was successful
"""
# Check if user is registered
assert users[sender].address != empty(address), "User not registered"

# Validate privacy level
assert new_privacy_level >= PRIVACY_LEVEL_STANDARD and new_privacy_level <= PRIVACY_LEVEL_MAXIMUM, "Invalid privacy level"

# Get current privacy level
old_level: uint8

old_level = users[sender].privacy_level

# Update privacy level
users[sender].privacy_level = new_privacy_level

# Emit event
log PrivacyLevelUpdated(sender, old_level, new_privacy_level, timestamp)

return True

@external
@payable
def add_funds() -> bool:
    """
@notice Add funds to user balance
@return success Whether the deposit was successful
"""
# Check if user is registered
assert users[sender].address != empty(address), "User not registered"

# Add funds to balance
users[sender].payment_balance += value

# Emit event
log FundsAdded(sender, value, timestamp)

return True

@external
def withdraw_funds(amount: uint256) -> bool:
    """
@notice Withdraw funds from user balance
@param amount The amount to withdraw
@return success Whether the withdrawal was successful
"""
# Check if user is registered
assert users[sender].address != empty(address), "User not registered"

# Check if user has enough balance
assert users[sender].payment_balance >= amount, "Insufficient balance"

# Update balance
users[sender].payment_balance -= amount

# Transfer funds
send(sender, amount)

# Emit event
log FundsWithdrawn(sender, amount, timestamp)

return True

@external
def deactivate_account() -> bool:
    """
@notice Deactivate user account
@return success Whether the deactivation was successful
"""
# Check if user is registered
assert users[sender].address != empty(address), "User not registered"

# Check if user is active
assert users[sender].active, "Account already deactivated"

# Deactivate account
users[sender].active = False

# Emit event
log UserDeactivated(sender, timestamp)

return True

@external
def reactivate_account() -> bool:
    """
@notice Reactivate user account
@return success Whether the reactivation was successful
"""
# Check if user is registered
assert users[sender].address != empty(address), "User not registered"

# Check if user is inactive
assert not users[sender].active, "Account already active"

# Reactivate account
users[sender].active = True

# Emit event
log UserReactivated(sender, timestamp)

return True

@external
def update_service_fee(new_fee: uint256):
    """
    @notice Update the service fee
    @param new_fee The new service fee
    """
    assert sender == owner, "Only owner can update fee"
    service_fee = new_fee

@external
@payable
def withdraw_service_fees():
    """
    @notice Withdraw accumulated service fees
    """
    assert sender == owner, "Only owner can withdraw fees"
    send(owner, balance)
