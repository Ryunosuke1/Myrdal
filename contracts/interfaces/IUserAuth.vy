# @version ^0.4.1
# @title User Authentication Interface
# @notice Interface for the User Authentication contract

struct UserInfo:
    address: address
    registered_at: uint256
    active: bool
    privacy_level: uint8  # 1: Standard, 2: Enhanced, 3: Maximum
    payment_balance: uint256


# インポートパスを修正
# カスタムインターフェースのインポート
# IIUserAuthインターフェースを直接定義
# @notice Register a new user
# @param privacy_level The desired privacy level
# @return success Whether the registration was successful
def register_user(privacy_level: uint8) -> bool: nonpayable

# @notice Check if a user is registered and active
# @param user The address of the user to check
# @return is_active Whether the user is registered and active
def is_user_active(user: address) -> bool: view

# @notice Get user information
# @param user The address of the user
# @return UserInfo The user information
def get_user_info(user: address) -> UserInfo: view

# @notice Update user privacy level
# @param new_privacy_level The new privacy level
# @return success Whether the update was successful
def update_privacy_level(new_privacy_level: uint8) -> bool: nonpayable

# @notice Add funds to user balance
# @return success Whether the deposit was successful
def add_funds() -> bool: payable

# @notice Withdraw funds from user balance
# @param amount The amount to withdraw
# @return success Whether the withdrawal was successful
def withdraw_funds(amount: uint256) -> bool: nonpayable

# @notice Deactivate user account
# @return success Whether the deactivation was successful
def deactivate_account() -> bool: nonpayable

# @notice Reactivate user account
# @return success Whether the reactivation was successful
def reactivate_account() -> bool: nonpayable
