# @version ^0.3.3
# @title User Authentication Contract
# @notice Contract for user authentication and privacy management
# @dev Implements the IUserAuth interface

import interfaces.IUserAuth as IUserAuth

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

# User storage
users: public(HashMap[address, IUserAuth.UserInfo])
user_addresses: public(DynArray[address, 1000])

@external
def __init__(_service_fee: uint256):
    """
    @notice Initialize the User Authentication contract
    @param _service_fee Fee for using the service (in wei)
    """
    self.owner = msg.sender
    self.service_fee = _service_fee

@external
def register_user(privacy_level: uint8) -> bool:
    """
    @notice Register a new user
    @param privacy_level The desired privacy level
    @return success Whether the registration was successful
    """
    # Check if user is already registered
    if self.users[msg.sender].address != empty(address):
        return False
    
    # Validate privacy level
    assert privacy_level >= PRIVACY_LEVEL_STANDARD and privacy_level <= PRIVACY_LEVEL_MAXIMUM, "Invalid privacy level"
    
    # Create user
    user: IUserAuth.UserInfo = IUserAuth.UserInfo({
        address: msg.sender,
        registered_at: block.timestamp,
        active: True,
        privacy_level: privacy_level,
        payment_balance: 0
    })
    
    # Store user
    self.users[msg.sender] = user
    self.user_addresses.append(msg.sender)
    
    # Emit event
    log UserRegistered(msg.sender, privacy_level, block.timestamp)
    
    return True

@external
@view
def is_user_active(user: address) -> bool:
    """
    @notice Check if a user is registered and active
    @param user The address of the user to check
    @return is_active Whether the user is registered and active
    """
    return self.users[user].active

@external
@view
def get_user_info(user: address) -> IUserAuth.UserInfo:
    """
    @notice Get user information
    @param user The address of the user
    @return UserInfo The user information
    """
    # Only the user or the owner can get user info
    assert user == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return self.users[user]

@external
def update_privacy_level(new_privacy_level: uint8) -> bool:
    """
    @notice Update user privacy level
    @param new_privacy_level The new privacy level
    @return success Whether the update was successful
    """
    # Check if user is registered
    assert self.users[msg.sender].address != empty(address), "User not registered"
    
    # Validate privacy level
    assert new_privacy_level >= PRIVACY_LEVEL_STANDARD and new_privacy_level <= PRIVACY_LEVEL_MAXIMUM, "Invalid privacy level"
    
    # Get current privacy level
    old_level: uint8 = self.users[msg.sender].privacy_level
    
    # Update privacy level
    self.users[msg.sender].privacy_level = new_privacy_level
    
    # Emit event
    log PrivacyLevelUpdated(msg.sender, old_level, new_privacy_level, block.timestamp)
    
    return True

@external
@payable
def add_funds() -> bool:
    """
    @notice Add funds to user balance
    @return success Whether the deposit was successful
    """
    # Check if user is registered
    assert self.users[msg.sender].address != empty(address), "User not registered"
    
    # Add funds to balance
    self.users[msg.sender].payment_balance += msg.value
    
    # Emit event
    log FundsAdded(msg.sender, msg.value, block.timestamp)
    
    return True

@external
def withdraw_funds(amount: uint256) -> bool:
    """
    @notice Withdraw funds from user balance
    @param amount The amount to withdraw
    @return success Whether the withdrawal was successful
    """
    # Check if user is registered
    assert self.users[msg.sender].address != empty(address), "User not registered"
    
    # Check if user has enough balance
    assert self.users[msg.sender].payment_balance >= amount, "Insufficient balance"
    
    # Update balance
    self.users[msg.sender].payment_balance -= amount
    
    # Transfer funds
    send(msg.sender, amount)
    
    # Emit event
    log FundsWithdrawn(msg.sender, amount, block.timestamp)
    
    return True

@external
def deactivate_account() -> bool:
    """
    @notice Deactivate user account
    @return success Whether the deactivation was successful
    """
    # Check if user is registered
    assert self.users[msg.sender].address != empty(address), "User not registered"
    
    # Check if user is active
    assert self.users[msg.sender].active, "Account already deactivated"
    
    # Deactivate account
    self.users[msg.sender].active = False
    
    # Emit event
    log UserDeactivated(msg.sender, block.timestamp)
    
    return True

@external
def reactivate_account() -> bool:
    """
    @notice Reactivate user account
    @return success Whether the reactivation was successful
    """
    # Check if user is registered
    assert self.users[msg.sender].address != empty(address), "User not registered"
    
    # Check if user is inactive
    assert not self.users[msg.sender].active, "Account already active"
    
    # Reactivate account
    self.users[msg.sender].active = True
    
    # Emit event
    log UserReactivated(msg.sender, block.timestamp)
    
    return True

@external
def update_service_fee(new_fee: uint256):
    """
    @notice Update the service fee
    @param new_fee The new service fee
    """
    assert msg.sender == self.owner, "Only owner can update fee"
    self.service_fee = new_fee

@external
@payable
def withdraw_service_fees():
    """
    @notice Withdraw accumulated service fees
    """
    assert msg.sender == self.owner, "Only owner can withdraw fees"
    send(self.owner, self.balance)
