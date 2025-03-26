"""
Fileverse Manager for Myrdal MCP Server

This module provides integration with Fileverse for storing and managing files
produced by the Myrdal agent.
"""

import os
import json
import logging
import requests
from dotenv import load_dotenv
from web3 import Web3

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FileverseManager:
    def __init__(self, web3_provider=None):
        """
        Initialize the Fileverse manager.
        
        Args:
            web3_provider: Web3 provider URL (optional)
        """
        self.api_key = os.getenv('FILEVERSE_API_KEY')
        if not self.api_key:
            logger.warning("Fileverse API key not found in environment variables")
            
        # Initialize Web3
        if web3_provider:
            self.web3 = Web3(Web3.HTTPProvider(web3_provider))
        else:
            self.web3 = Web3(Web3.HTTPProvider(os.getenv('WEB3_PROVIDER_URL', 'http://localhost:8545')))
        
        # Load contract ABIs
        self.load_contract_abis()
        
        # Initialize contracts
        self.initialize_contracts()
        
    def load_contract_abis(self):
        """Load contract ABIs from JSON files"""
        try:
            with open('abis/FileverseIntegration.json', 'r') as f:
                self.fileverse_integration_abi = json.load(f)
                
            logger.info("Contract ABIs loaded successfully")
        except Exception as e:
            logger.error(f"Error loading contract ABIs: {e}")
            raise
    
    def initialize_contracts(self):
        """Initialize contract instances"""
        try:
            fileverse_integration_address = os.getenv('FILEVERSE_INTEGRATION_ADDRESS')
            
            if not fileverse_integration_address:
                logger.warning("Contract address not found in environment variables")
                self.fileverse_integration = None
                return
                
            self.fileverse_integration = self.web3.eth.contract(
                address=fileverse_integration_address,
                abi=self.fileverse_integration_abi
            )
            
            logger.info("Contracts initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing contracts: {e}")
            self.fileverse_integration = None
    
    def upload_file(self, file_path, task_id, name=None, description=None, mime_type=None):
        """
        Upload a file to Fileverse and record it on the blockchain.
        
        Args:
            file_path: Path to the file to upload
            task_id: Task ID associated with the file
            name: File name (optional)
            description: File description (optional)
            mime_type: File MIME type (optional)
            
        Returns:
            File hash if successful, None otherwise
        """
        if not self.api_key:
            logger.error("Fileverse API key not available")
            return None
            
        try:
            # Prepare file metadata
            if not name:
                name = os.path.basename(file_path)
                
            if not mime_type:
                # Simple MIME type detection based on extension
                ext = os.path.splitext(file_path)[1].lower()
                if ext == '.pdf':
                    mime_type = 'application/pdf'
                elif ext in ['.jpg', '.jpeg']:
                    mime_type = 'image/jpeg'
                elif ext == '.png':
                    mime_type = 'image/png'
                elif ext in ['.txt', '.md']:
                    mime_type = 'text/plain'
                elif ext == '.json':
                    mime_type = 'application/json'
                else:
                    mime_type = 'application/octet-stream'
            
            # Get file size
            size = os.path.getsize(file_path)
            
            # Upload file to Fileverse
            with open(file_path, 'rb') as f:
                files = {'file': (name, f, mime_type)}
                
                metadata = {
                    'name': name,
                    'description': description or f"File uploaded by Myrdal agent for task {task_id}",
                    'task_id': task_id
                }
                
                headers = {
                    'Authorization': f'Bearer {self.api_key}'
                }
                
                response = requests.post(
                    'https://api.fileverse.io/v1/files',
                    files=files,
                    data={'metadata': json.dumps(metadata)},
                    headers=headers
                )
                
            if response.status_code != 200:
                logger.error(f"Fileverse API error: {response.text}")
                return None
                
            result = response.json()
            file_hash = result.get('hash')
            
            if not file_hash:
                logger.error("File hash not found in Fileverse response")
                return None
                
            logger.info(f"File uploaded to Fileverse: {file_hash}")
            
            # Record file upload on blockchain
            if self.fileverse_integration:
                # Get account to send transaction
                account = self.web3.eth.accounts[0]
                
                # Convert task_id to bytes32 if it's a string
                if isinstance(task_id, str) and task_id.startswith('0x'):
                    task_id_bytes = bytes.fromhex(task_id[2:])
                else:
                    task_id_bytes = self.web3.keccak(text=str(task_id))
                
                # Convert file_hash to bytes32 if it's a string
                if isinstance(file_hash, str) and file_hash.startswith('0x'):
                    file_hash_bytes = bytes.fromhex(file_hash[2:])
                else:
                    file_hash_bytes = self.web3.keccak(text=file_hash)
                
                # Submit record
                tx = self.fileverse_integration.functions.record_file_upload(
                    task_id_bytes,
                    file_hash_bytes,
                    name,
                    description or "",
                    mime_type,
                    size
                ).transact({'from': account})
                
                receipt = self.web3.eth.wait_for_transaction_receipt(tx)
                logger.info(f"File upload recorded on blockchain: {receipt.transactionHash.hex()}")
            
            return file_hash
            
        except Exception as e:
            logger.error(f"Error uploading file: {e}")
            return None
    
    def get_task_files(self, task_id):
        """
        Get files associated with a task.
        
        Args:
            task_id: Task ID
            
        Returns:
            List of file hashes
        """
        if not self.fileverse_integration:
            logger.error("FileverseIntegration contract not initialized")
            return []
            
        try:
            # Convert task_id to bytes32 if it's a string
            if isinstance(task_id, str) and task_id.startswith('0x'):
                task_id_bytes = bytes.fromhex(task_id[2:])
            else:
                task_id_bytes = self.web3.keccak(text=str(task_id))
                
            # Get file hashes
            file_hashes = self.fileverse_integration.functions.get_task_files(task_id_bytes).call()
            
            return file_hashes
            
        except Exception as e:
            logger.error(f"Error getting task files: {e}")
            return []
    
    def get_file_metadata(self, file_hash):
        """
        Get metadata for a file.
        
        Args:
            file_hash: File hash
            
        Returns:
            File metadata
        """
        if not self.fileverse_integration:
            logger.error("FileverseIntegration contract not initialized")
            return None
            
        try:
            # Convert file_hash to bytes32 if it's a string
            if isinstance(file_hash, str) and file_hash.startswith('0x'):
                file_hash_bytes = bytes.fromhex(file_hash[2:])
            else:
                file_hash_bytes = self.web3.keccak(text=file_hash)
                
            # Get file metadata
            name, description, mime_type, size = self.fileverse_integration.functions.get_file_metadata(file_hash_bytes).call()
            
            return {
                'name': name,
                'description': description,
                'mime_type': mime_type,
                'size': size
            }
            
        except Exception as e:
            logger.error(f"Error getting file metadata: {e}")
            return None

# Example usage
if __name__ == "__main__":
    manager = FileverseManager()
    
    # Example: upload a file
    task_id = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    file_path = "example.txt"
    
    # Create example file
    with open(file_path, 'w') as f:
        f.write("This is an example file created by Myrdal agent.")
    
    file_hash = manager.upload_file(
        file_path,
        task_id,
        name="Example File",
        description="This is an example file created by Myrdal agent.",
        mime_type="text/plain"
    )
    
    print(f"File hash: {file_hash}")
    
    # Get task files
    task_files = manager.get_task_files(task_id)
    print(f"Task files: {task_files}")
    
    # Get file metadata
    if file_hash:
        metadata = manager.get_file_metadata(file_hash)
        print(f"File metadata: {metadata}")
    
    # Clean up
    os.remove(file_path)
