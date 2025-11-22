// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/answer/03_TheDAOHack_Solution.sol";
import "../../src/03_TheDAOHack/DAOAttacker.sol";

contract TheDAOHackSolutionTest is Test {
    FixedBank_Solution public bank;
    DAOAttacker public attacker;
    address public user;
    
    function setUp() public {
        bank = new FixedBank_Solution();
        user = makeAddr("user");
        
        vm.deal(user, 10 ether);
        vm.prank(user);
        bank.deposit{value: 10 ether}();
        
        attacker = new DAOAttacker(address(bank));
        vm.deal(address(attacker), 1 ether);
    }
    
    function testFixedBank_ReentrancyBlocked() public {
        uint256 bankBalanceBefore = address(bank).balance;
        uint256 attackerBalanceBefore = address(attacker).balance;
        
        console.log("=== Before Attack ===");
        console.log("Bank balance:", bankBalanceBefore);
        console.log("Attacker balance:", attackerBalanceBefore);
        
        vm.expectRevert("Transfer failed");
        attacker.attack{value: 1 ether}();
        
        console.log("\n=== After Attack (FAILED) ===");
        console.log("Bank balance:", address(bank).balance);
        console.log("Attacker balance:", address(attacker).balance);
        
        assertEq(address(bank).balance, bankBalanceBefore);
    }
    
    function testFixedBank_NormalWithdraw() public {
        vm.prank(user);
        bank.withdraw(5 ether);
        
        assertEq(address(bank).balance, 5 ether);
        assertEq(bank.balances(user), 5 ether);
    }
}

