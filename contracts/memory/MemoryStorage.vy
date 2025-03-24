# @version ^0.3.3
# @title Memory Storage Contract
# @notice Contract for storing and retrieving agent memory with privacy features
# @dev Implements the IMemoryStorage interface

import interfaces.IMemoryStorage as IMemoryStorage
import interfaces.IUserAuth as IUserAuth

# Events
event MemoryStored:
    memory_id: bytes32
    owner: address
    timestamp: uint256
    encrypted: bool

event MemoryDeleted:
    memory_id: bytes32
    timestamp: uint256

event MemoryPriorityUpdated:
    memory_id: bytes32
    new_priority: uint8
    timestamp: uint256

# State variables
owner: public(address)
user_auth: public(address)

# Memory storage
memories: public(HashMap[bytes32, IMemoryStorage.MemoryEntry])
user_memories: public(HashMap[address, DynArray[bytes32, 100]])
memory_ids: public(DynArray[bytes32, 1000])
tag_to_memories: public(HashMap[String[32], DynArray[bytes32, 100]])

@external
def __init__(_user_auth: address):
    """
    @notice Initialize the Memory Storage contract
    @param _user_auth Address of the User Authentication contract
    """
    self.owner = msg.sender
    self.user_auth = _user_auth

@external
def store_memory(content: String[1024], priority: uint8, tags: DynArray[String[32], 10], encrypt: bool) -> bytes32:
    """
    @notice Store a new memory entry
    @param content The content to store
    @param priority The priority of the memory (higher = more important)
    @param tags Tags for categorizing the memory
    @param encrypt Whether to encrypt the content
    @return memory_id The ID of the stored memory
    """
    # Check if user is active
    user_auth: IUserAuth.IUserAuth = IUserAuth.IUserAuth(self.user_auth)
    assert user_auth.is_user_active(msg.sender), "User not active"
    
    # Generate memory ID
    memory_id: bytes32 = keccak256(concat(
        convert(block.timestamp, bytes32),
        convert(len(self.memory_ids), bytes32),
        convert(msg.sender, bytes32)
    ))
    
    # Create memory entry
    memory_entry: IMemoryStorage.MemoryEntry = IMemoryStorage.MemoryEntry({
        id: memory_id,
        owner: msg.sender,
        content: content,
        created_at: block.timestamp,
        priority: priority,
        tags: tags,
        encrypted: encrypt
    })
    
    # Store memory
    self.memories[memory_id] = memory_entry
    self.memory_ids.append(memory_id)
    self.user_memories[msg.sender].append(memory_id)
    
    # Store tags mapping
    for i in range(10):
        if i >= len(tags):
            break
        
        tag: String[32] = tags[i]
        self.tag_to_memories[tag].append(memory_id)
    
    # Emit event
    log MemoryStored(memory_id, msg.sender, block.timestamp, encrypt)
    
    return memory_id

@external
@view
def get_memory(memory_id: bytes32) -> IMemoryStorage.MemoryEntry:
    """
    @notice Retrieve a memory entry
    @param memory_id The ID of the memory to retrieve
    @return MemoryEntry The memory entry
    """
    assert memory_id in self.memory_ids, "Memory not found"
    memory_entry: IMemoryStorage.MemoryEntry = self.memories[memory_id]
    assert memory_entry.owner == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return memory_entry

@external
@view
def search_by_tags(tags: DynArray[String[32], 10]) -> DynArray[bytes32, 100]:
    """
    @notice Search for memories by tags
    @param tags Tags to search for
    @return memory_ids Array of memory IDs matching the tags
    """
    result: DynArray[bytes32, 100] = []
    
    # For each tag, find memories and add to result if they belong to the user
    for i in range(10):
        if i >= len(tags):
            break
        
        tag: String[32] = tags[i]
        tag_memories: DynArray[bytes32, 100] = self.tag_to_memories[tag]
        
        for j in range(100):
            if j >= len(tag_memories):
                break
            
            memory_id: bytes32 = tag_memories[j]
            memory_entry: IMemoryStorage.MemoryEntry = self.memories[memory_id]
            
            # Only include memories owned by the user
            if memory_entry.owner == msg.sender:
                # Check if memory_id is already in result
                already_in_result: bool = False
                for k in range(100):
                    if k >= len(result):
                        break
                    
                    if result[k] == memory_id:
                        already_in_result = True
                        break
                
                if not already_in_result:
                    result.append(memory_id)
    
    return result

@external
@view
def get_user_memories(user: address) -> DynArray[bytes32, 100]:
    """
    @notice Get all memories for a user
    @param user The address of the user
    @return memory_ids Array of memory IDs
    """
    assert user == msg.sender or msg.sender == self.owner, "Not authorized"
    
    return self.user_memories[user]

@external
def update_priority(memory_id: bytes32, new_priority: uint8):
    """
    @notice Update the priority of a memory
    @param memory_id The ID of the memory
    @param new_priority The new priority value
    """
    assert memory_id in self.memory_ids, "Memory not found"
    memory_entry: IMemoryStorage.MemoryEntry = self.memories[memory_id]
    assert memory_entry.owner == msg.sender or msg.sender == self.owner, "Not authorized"
    
    # Update priority
    memory_entry.priority = new_priority
    self.memories[memory_id] = memory_entry
    
    # Emit event
    log MemoryPriorityUpdated(memory_id, new_priority, block.timestamp)

@external
def delete_memory(memory_id: bytes32):
    """
    @notice Delete a memory entry
    @param memory_id The ID of the memory to delete
    """
    assert memory_id in self.memory_ids, "Memory not found"
    memory_entry: IMemoryStorage.MemoryEntry = self.memories[memory_id]
    assert memory_entry.owner == msg.sender or msg.sender == self.owner, "Not authorized"
    
    # Remove from tag mappings
    for i in range(10):
        if i >= len(memory_entry.tags):
            break
        
        tag: String[32] = memory_entry.tags[i]
        tag_memories: DynArray[bytes32, 100] = self.tag_to_memories[tag]
        
        # Create new array without the memory_id
        new_tag_memories: DynArray[bytes32, 100] = []
        for j in range(100):
            if j >= len(tag_memories):
                break
            
            if tag_memories[j] != memory_id:
                new_tag_memories.append(tag_memories[j])
        
        self.tag_to_memories[tag] = new_tag_memories
    
    # Clear memory content (privacy feature)
    memory_entry.content = ""
    self.memories[memory_id] = memory_entry
    
    # Emit event
    log MemoryDeleted(memory_id, block.timestamp)
