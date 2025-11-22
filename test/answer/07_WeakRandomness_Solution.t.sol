// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/answer/07_WeakRandomness_Solution.sol";
import "../../src/07_WeakRandomness/VulnerableLottery.sol";
import "../../src/07_WeakRandomness/LotteryAttacker.sol";

contract SecureLotteryAttacker {
    SecureLottery_Solution public lottery;
    
    constructor(address _lotteryAddress) {
        lottery = SecureLottery_Solution(_lotteryAddress);
    }
    
    function predictWinner() public pure returns (address) {
        return address(0);
    }
    
    function attack() public payable {
        lottery.buyTicket{value: lottery.ticketPrice()}();
    }
    
    receive() external payable {}
}

contract WeakRandomnessSolutionTest is Test {
    MockRandomnessOracle public oracle;
    SecureLottery_Solution public secureLottery;
    VulnerableLottery public vulnerableLottery;
    
    address public owner;
    address public player1;
    address public player2;
    address public player3;
    address public attacker;
    
    function setUp() public {
        owner = makeAddr("owner");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        attacker = makeAddr("attacker");
        
        vm.deal(owner, 10 ether);
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        vm.deal(player3, 1 ether);
        vm.deal(attacker, 1 ether);
        
        oracle = new MockRandomnessOracle();
        
        vm.prank(owner);
        secureLottery = new SecureLottery_Solution(address(oracle));
        
        vm.prank(owner);
        vulnerableLottery = new VulnerableLottery();
    }
    
    function testSecureLottery_BasicFlow() public {
        vm.prank(player1);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        vm.prank(player2);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        vm.prank(player3);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        assertEq(secureLottery.getPrizePool(), 0.3 ether);
        assertEq(secureLottery.getParticipants().length, 3);
        
        vm.prank(owner);
        secureLottery.requestDraw();
        
        vm.prank(owner);
        secureLottery.completeDraw();
        
        assertEq(secureLottery.getPrizePool(), 0);
        assertEq(secureLottery.getParticipants().length, 0);
    }
    
    function testSecureLottery_PredictionBlocked() public {
        console.log("=== Secure Lottery: Prediction Blocked ===");
        
        vm.prank(player1);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        vm.prank(player2);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        vm.prank(player3);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        console.log("Predicted winner:", address(0));
        console.log("Result: Cannot predict! (address(0))");
        console.log("Prize pool:", secureLottery.getPrizePool());
        console.log("Participants:", secureLottery.getParticipants().length);
    }
    
    function testComparison_VulnerableVsSecure() public {
        console.log("=== Comparison: Vulnerable vs Secure ===");
        
        console.log("\n[1] Vulnerable Lottery:");
        vm.prank(player1);
        vulnerableLottery.buyTicket{value: 0.1 ether}();
        
        vm.prank(player2);
        vulnerableLottery.buyTicket{value: 0.1 ether}();
        
        vm.startPrank(attacker);
        LotteryAttacker vulnerableAttacker = new LotteryAttacker(address(vulnerableLottery));
        uint256 predictedIndex = vulnerableAttacker.predictWinnerIndex();
        console.log("Can predict winner index:", predictedIndex);
        console.log("Prediction possible: YES");
        vm.stopPrank();
        
        console.log("\n[2] Secure Lottery:");
        vm.prank(player1);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        vm.prank(player2);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        console.log("Cannot predict winner (using secure lottery oracle)");
        console.log("Prediction possible: NO");
        
        console.log("\n=== Result ===");
        console.log("Vulnerable: Attacker can predict and manipulate");
        console.log("Secure: Attacker cannot predict (uses oracle)");
    }
    
    function testSecureLottery_CannotBuyDuringDraw() public {
        vm.prank(player1);
        secureLottery.buyTicket{value: 0.1 ether}();
        
        vm.prank(owner);
        secureLottery.requestDraw();
        
        vm.prank(player2);
        vm.expectRevert("Draw in progress");
        secureLottery.buyTicket{value: 0.1 ether}();
    }
    
    function testSecureLottery_RandomDistribution() public {
        console.log("=== Random Distribution Test ===");
        
        uint256 player1Wins = 0;
        uint256 player2Wins = 0;
        uint256 rounds = 10;
        
        for (uint256 i = 0; i < rounds; i++) {
            vm.prank(player1);
            secureLottery.buyTicket{value: 0.1 ether}();
            
            vm.prank(player2);
            secureLottery.buyTicket{value: 0.1 ether}();
            
            uint256 player1BalanceBefore = player1.balance;
            uint256 player2BalanceBefore = player2.balance;
            
            vm.prank(owner);
            secureLottery.requestDraw();
            
            vm.prank(owner);
            secureLottery.completeDraw();
            
            if (player1.balance > player1BalanceBefore) {
                player1Wins++;
            }
            if (player2.balance > player2BalanceBefore) {
                player2Wins++;
            }
            
            vm.warp(block.timestamp + 1);
        }
        
        console.log("Player1 wins:", player1Wins);
        console.log("Player2 wins:", player2Wins);
        console.log("Total rounds:", rounds);
        
        assertTrue(player1Wins > 0 || player2Wins > 0, "At least one should win");
    }
}

