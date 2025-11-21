// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SecurityToken is ERC20 {
    
    bytes32 public constant COMMON_STOCK = bytes32("COMMON");
    bytes32 public constant PREFERRED_STOCK = bytes32("PREFERRED");
    bytes32 public constant RESTRICTED_STOCK = bytes32("RESTRICTED");
    
    address public owner;
    address public transferAgent;
    
    mapping(address => bool) public accreditedInvestors;
    
    mapping(bytes32 => mapping(address => uint256)) public balanceOfByPartition;
    
    mapping(address => uint256) public lockupUntil;
    
    mapping(address => bool) public operators;
    
    struct Document {
        bytes32 docHash;
        uint256 timestamp;
        string uri;
    }
    
    mapping(bytes32 => Document) public documents;
    
    bool public transfersEnabled;
    
    event TransferByPartition(
        bytes32 indexed partition,
        address operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
    
    event PartitionChanged(
        bytes32 indexed fromPartition,
        bytes32 indexed toPartition,
        uint256 value
    );
    
    event DocumentUpdated(
        bytes32 indexed name,
        string uri,
        bytes32 documentHash
    );
    
    event InvestorAccredited(address indexed investor);
    event InvestorRevoked(address indexed investor);
    event OperatorAuthorized(address indexed operator);
    event OperatorRevoked(address indexed operator);
    event TransfersEnabled(bool enabled);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == owner, "Not authorized operator");
        _;
    }
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        owner = msg.sender;
        transferAgent = msg.sender;
        operators[msg.sender] = true;
        accreditedInvestors[msg.sender] = true;
        
        _mint(msg.sender, initialSupply);
        balanceOfByPartition[COMMON_STOCK][msg.sender] = initialSupply;
        
        transfersEnabled = true;
    }
    
    function addAccreditedInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = true;
        emit InvestorAccredited(investor);
    }
    
    function removeAccreditedInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = false;
        emit InvestorRevoked(investor);
    }
    
    function authorizeOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit OperatorAuthorized(operator);
    }
    
    function revokeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit OperatorRevoked(operator);
    }
    
    function setLockupPeriod(address investor, uint256 until) external onlyOwner {
        lockupUntil[investor] = until;
    }
    
    function setTransfersEnabled(bool enabled) external onlyOwner {
        transfersEnabled = enabled;
        emit TransfersEnabled(enabled);
    }
    
    function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external onlyOwner {
        documents[name] = Document({
            docHash: documentHash,
            timestamp: block.timestamp,
            uri: uri
        });
        
        emit DocumentUpdated(name, uri, documentHash);
    }
    
    function getDocument(bytes32 name) external view returns (string memory, bytes32, uint256) {
        Document memory doc = documents[name];
        return (doc.uri, doc.docHash, doc.timestamp);
    }
    
    function canTransfer(
        address from,
        address to,
        uint256 value
    ) public view returns (bool, string memory) {
        if (!transfersEnabled) {
            return (false, "Transfers are disabled");
        }
        
        if (!accreditedInvestors[from]) {
            return (false, "Sender not accredited");
        }
        
        if (!accreditedInvestors[to]) {
            return (false, "Recipient not accredited");
        }
        
        if (block.timestamp < lockupUntil[from]) {
            return (false, "Tokens are locked");
        }
        
        if (balanceOf(from) < value) {
            return (false, "Insufficient balance");
        }
        
        return (true, "Transfer allowed");
    }
    
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bytes32) {
        (bool allowed, string memory reason) = canTransfer(msg.sender, to, value);
        require(allowed, reason);
        
        require(balanceOfByPartition[partition][msg.sender] >= value, "Insufficient partition balance");
        
        balanceOfByPartition[partition][msg.sender] -= value;
        balanceOfByPartition[partition][to] += value;
        
        _transfer(msg.sender, to, value);
        
        emit TransferByPartition(partition, msg.sender, msg.sender, to, value, data);
        
        return partition;
    }
    
    function operatorTransferByPartition(
        bytes32 partition,
        address from,
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOperator returns (bytes32) {
        (bool allowed, string memory reason) = canTransfer(from, to, value);
        require(allowed, reason);
        
        require(balanceOfByPartition[partition][from] >= value, "Insufficient partition balance");
        
        balanceOfByPartition[partition][from] -= value;
        balanceOfByPartition[partition][to] += value;
        
        _transfer(from, to, value);
        
        emit TransferByPartition(partition, msg.sender, from, to, value, data);
        
        return partition;
    }
    
    function changePartition(
        bytes32 fromPartition,
        bytes32 toPartition,
        uint256 value
    ) external onlyOperator {
        require(balanceOfByPartition[fromPartition][msg.sender] >= value, "Insufficient partition balance");
        
        balanceOfByPartition[fromPartition][msg.sender] -= value;
        balanceOfByPartition[toPartition][msg.sender] += value;
        
        emit PartitionChanged(fromPartition, toPartition, value);
    }
    
    function issueByPartition(
        bytes32 partition,
        address investor,
        uint256 value
    ) external onlyOwner {
        require(accreditedInvestors[investor], "Investor not accredited");
        
        _mint(investor, value);
        balanceOfByPartition[partition][investor] += value;
        
        emit TransferByPartition(partition, msg.sender, address(0), investor, value, "");
    }
    
    function redeemByPartition(
        bytes32 partition,
        uint256 value
    ) external {
        require(balanceOfByPartition[partition][msg.sender] >= value, "Insufficient partition balance");
        
        balanceOfByPartition[partition][msg.sender] -= value;
        _burn(msg.sender, value);
        
        emit TransferByPartition(partition, msg.sender, msg.sender, address(0), value, "");
    }
    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        (bool allowed, string memory reason) = canTransfer(msg.sender, to, amount);
        require(allowed, reason);
        
        uint256 remaining = amount;
        if (balanceOfByPartition[COMMON_STOCK][msg.sender] >= remaining) {
            balanceOfByPartition[COMMON_STOCK][msg.sender] -= remaining;
            balanceOfByPartition[COMMON_STOCK][to] += remaining;
        } else if (balanceOfByPartition[PREFERRED_STOCK][msg.sender] >= remaining) {
            balanceOfByPartition[PREFERRED_STOCK][msg.sender] -= remaining;
            balanceOfByPartition[PREFERRED_STOCK][to] += remaining;
        } else if (balanceOfByPartition[RESTRICTED_STOCK][msg.sender] >= remaining) {
            balanceOfByPartition[RESTRICTED_STOCK][msg.sender] -= remaining;
            balanceOfByPartition[RESTRICTED_STOCK][to] += remaining;
        }
        
        return super.transfer(to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        (bool allowed, string memory reason) = canTransfer(from, to, amount);
        require(allowed, reason);
        
        uint256 remaining = amount;
        if (balanceOfByPartition[COMMON_STOCK][from] >= remaining) {
            balanceOfByPartition[COMMON_STOCK][from] -= remaining;
            balanceOfByPartition[COMMON_STOCK][to] += remaining;
        } else if (balanceOfByPartition[PREFERRED_STOCK][from] >= remaining) {
            balanceOfByPartition[PREFERRED_STOCK][from] -= remaining;
            balanceOfByPartition[PREFERRED_STOCK][to] += remaining;
        } else if (balanceOfByPartition[RESTRICTED_STOCK][from] >= remaining) {
            balanceOfByPartition[RESTRICTED_STOCK][from] -= remaining;
            balanceOfByPartition[RESTRICTED_STOCK][to] += remaining;
        }
        
        return super.transferFrom(from, to, amount);
    }
    
    function getPartitionBalance(bytes32 partition, address account) external view returns (uint256) {
        return balanceOfByPartition[partition][account];
    }
    
    function isAccredited(address investor) external view returns (bool) {
        return accreditedInvestors[investor];
    }
    
    function isOperator(address operator) external view returns (bool) {
        return operators[operator];
    }
}

