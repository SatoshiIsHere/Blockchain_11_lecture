// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/quiz/answer/02_solution.sol";

contract Quiz2SolutionTest is Test {
    PiggyBank public piggyBank;
    address payable public owner;
    address public user = address(0x1234);

    function setUp() public {
        owner = payable(address(this));
        piggyBank = new PiggyBank();
        
        vm.deal(address(piggyBank), 10 ether);
        
        console.log("Setup completed");
        console.log("PiggyBank balance:", address(piggyBank).balance);
        console.log("Owner address:", piggyBank.owner());
    }

    function testFix_OwnerIsPayable() public view {
        console.log("\n=== Fix: Owner is payable ===");
        
        address payable ownerAddr = piggyBank.owner();
        console.log("Owner address:", ownerAddr);
        
        assertTrue(ownerAddr != address(0), "Owner should be set");
        assertEq(ownerAddr, owner, "Owner should match deployer");
        
        console.log("Owner is properly set as payable");
    }

    function testFix_ConstructorInitialization() public view {
        console.log("\n=== Fix: Constructor properly initializes owner ===");
        
        address payable ownerAddr = piggyBank.owner();
        assertEq(ownerAddr, owner);
        
        console.log("Constructor sets owner = payable(msg.sender)");
        console.log("This ensures owner can receive funds from selfdestruct");
    }

    function testWithdrawSuccess() public {
        console.log("\n=== Withdraw Success Test ===");
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = address(piggyBank).balance;
        
        console.log("Owner balance before:", ownerBalanceBefore);
        console.log("Contract balance:", contractBalance);
        
        piggyBank.withdraw();
        
        uint256 ownerBalanceAfter = owner.balance;
        console.log("Owner balance after:", ownerBalanceAfter);
        
        assertEq(ownerBalanceAfter - ownerBalanceBefore, contractBalance);
        
        console.log("Withdraw succeeded, funds sent to owner");
    }

    function testWithdrawOnlyOwner() public {
        console.log("\n=== Withdraw Access Control Test ===");
        
        vm.prank(user);
        vm.expectRevert("Not a owner");
        piggyBank.withdraw();
        
        console.log("Only owner can withdraw");
    }

    function testDeposit() public {
        console.log("\n=== Deposit Test ===");
        
        uint256 balanceBefore = address(piggyBank).balance;
        console.log("Balance before:", balanceBefore);
        
        vm.prank(user);
        vm.deal(user, 5 ether);
        (bool success, ) = address(piggyBank).call{value: 1 ether}("");
        require(success, "Deposit failed");
        
        uint256 balanceAfter = address(piggyBank).balance;
        console.log("Balance after:", balanceAfter);
        
        assertEq(balanceAfter - balanceBefore, 1 ether);
        
        console.log("Deposit works correctly");
    }

    function testCompleteFlow() public {
        console.log("\n=== Complete Flow Test ===");
        
        vm.deal(user, 5 ether);
        
        vm.prank(user);
        (bool success, ) = address(piggyBank).call{value: 3 ether}("");
        require(success, "Deposit failed");
        
        console.log("User deposited 3 ether");
        console.log("Contract balance:", address(piggyBank).balance);
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 totalContractBalance = address(piggyBank).balance;
        
        piggyBank.withdraw();
        
        uint256 ownerBalanceAfter = owner.balance;
        
        assertEq(ownerBalanceAfter - ownerBalanceBefore, totalContractBalance);
        
        console.log("Owner withdrew all funds successfully");
        console.log("Final owner balance:", ownerBalanceAfter);
    }

    receive() external payable {}
}

