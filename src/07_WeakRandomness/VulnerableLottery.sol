// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableLottery {
    address public owner;
    uint256 public ticketPrice = 0.1 ether;
    uint256 public prizePool;
    
    mapping(address => bool) public hasTicket;
    address[] public participants;
    
    event TicketPurchased(address indexed player);
    event WinnerSelected(address indexed winner, uint256 prize);
    
    constructor() {
        owner = msg.sender;
    }
    
    function buyTicket() public payable {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(!hasTicket[msg.sender], "Already has ticket");
        
        hasTicket[msg.sender] = true;
        participants.push(msg.sender);
        prizePool += msg.value;
        
        emit TicketPurchased(msg.sender);
    }
    
    function draw() public {
        require(msg.sender == owner, "Only owner");
        require(prizePool > 0, "No prize pool");
        require(participants.length > 0, "No participants");
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender
        )));
        
        uint256 winnerIndex = randomNumber % participants.length;
        address winner = participants[winnerIndex];
        
        uint256 prize = prizePool;
        prizePool = 0;
        delete participants;
        
        payable(winner).transfer(prize);
        emit WinnerSelected(winner, prize);
    }
    
    function getPrizePool() public view returns (uint256) {
        return prizePool;
    }
    
    function getParticipantsCount() public view returns (uint256) {
        return participants.length;
    }
}

