# @version ^0.3.3
# @title Memory Storage Interface
# @notice Interface for the Memory Storage contract

struct MemoryEntry:
    id: bytes32
    owner: address
    content: String[1024]
    created_at: uint256
    priority: uint8
    tags: DynArray[String[32], 10]
    encrypted: bool

interface IMemoryStorage:
    # @notice Store a new memory entry
    # @param content The content to store
    # @param priority The priority of the memory (higher = more important)
    # @param tags Tags for categorizing the memory
    # @param encrypt Whether to encrypt the content
    # @return memory_id The ID of the stored memory
    def store_memory(content: String[1024], priority: uint8, tags: DynArray[String[32], 10], encrypt: bool) -> bytes32: nonpayable
    
    # @notice Retrieve a memory entry
    # @param memory_id The ID of the memory to retrieve
    # @return MemoryEntry The memory entry
    def get_memory(memory_id: bytes32) -> MemoryEntry: view
    
    # @notice Search for memories by tags
    # @param tags Tags to search for
    # @return memory_ids Array of memory IDs matching the tags
    def search_by_tags(tags: DynArray[String[32], 10]) -> DynArray[bytes32, 100]: view
    
    # @notice Get all memories for a user
    # @param user The address of the user
    # @return memory_ids Array of memory IDs
    def get_user_memories(user: address) -> DynArray[bytes32, 100]: view
    
    # @notice Update the priority of a memory
    # @param memory_id The ID of the memory
    # @param new_priority The new priority value
    def update_priority(memory_id: bytes32, new_priority: uint8): nonpayable
    
    # @notice Delete a memory entry
    # @param memory_id The ID of the memory to delete
    def delete_memory(memory_id: bytes32): nonpayable
