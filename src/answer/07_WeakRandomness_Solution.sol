// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRandomnessOracle {
    function requestRandomness() external returns (bytes32 requestId);
    function getRandomness(bytes32 requestId) external view returns (uint256);
}

contract MockRandomnessOracle is IRandomnessOracle {
    mapping(bytes32 => uint256) public randomness;
    uint256 private nonce;
    
    function requestRandomness() external returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce++));
        randomness[requestId] = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp,
            nonce,
            msg.sender
        )));
        return requestId;
    }
    
    function getRandomness(bytes32 requestId) external view returns (uint256) {
        require(randomness[requestId] != 0, "Randomness not ready");
        return randomness[requestId];
    }
}

contract SecureLottery_Solution {
    IRandomnessOracle public oracle;
    address public owner;
    uint256 public ticketPrice = 0.1 ether;
    uint256 public prizePool;
    
    address[] public participants;
    mapping(address => bool) public hasTicket;
    
    bytes32 public pendingRequestId;
    bool public drawInProgress;
    
    event TicketPurchased(address indexed player);
    event RandomnessRequested(bytes32 indexed requestId);
    event WinnerSelected(address indexed winner, uint256 prize);
    
    constructor(address _oracle) {
        oracle = IRandomnessOracle(_oracle);
        owner = msg.sender;
    }
    
    function buyTicket() public payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(!hasTicket[msg.sender], "Already has ticket");
        require(!drawInProgress, "Draw in progress");
        
        hasTicket[msg.sender] = true;
        participants.push(msg.sender);
        prizePool += msg.value;
        
        emit TicketPurchased(msg.sender);
    }
    
    function requestDraw() public {
        require(msg.sender == owner, "Only owner");
        require(participants.length > 0, "No participants");
        require(!drawInProgress, "Draw already in progress");
        
        drawInProgress = true;
        pendingRequestId = oracle.requestRandomness();
        
        emit RandomnessRequested(pendingRequestId);
    }
    
    function completeDraw() public {
        require(msg.sender == owner, "Only owner");
        require(drawInProgress, "No draw in progress");
        
        uint256 randomNumber = oracle.getRandomness(pendingRequestId);
        
        uint256 winnerIndex = randomNumber % participants.length;
        address winner = participants[winnerIndex];
        
        uint256 prize = prizePool;
        prizePool = 0;
        
        for (uint256 i = 0; i < participants.length; i++) {
            hasTicket[participants[i]] = false;
        }
        delete participants;
        
        drawInProgress = false;
        pendingRequestId = bytes32(0);
        
        payable(winner).transfer(prize);
        emit WinnerSelected(winner, prize);
    }
    
    function getPrizePool() public view returns (uint256) {
        return prizePool;
    }
    
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }
}

