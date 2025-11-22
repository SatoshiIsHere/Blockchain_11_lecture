// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/quiz/02_problem.sol";

contract Quiz2VulnerabilityTest is Test {
    PiggyBank public piggyBank;
    address public owner;
    address public user = address(0x1234);

    function setUp() public {
        owner = address(this);
        piggyBank = new PiggyBank();
        
        vm.deal(address(piggyBank), 10 ether);
        
        console.log("Setup completed");
        console.log("PiggyBank balance:", address(piggyBank).balance);
        console.log("Owner address:", piggyBank.owner());
    }

    function testVulnerability_OwnerNotPayable() public view {
        console.log("\n=== Vulnerability: Owner declared as non-payable ===");
        
        address ownerAddr = piggyBank.owner();
        console.log("Owner address:", ownerAddr);
        console.log("Owner is declared as 'address' not 'address payable'");
        
        uint256 contractBalance = address(piggyBank).balance;
        console.log("Contract balance:", contractBalance);
        
        console.log("This requires explicit payable casting: payable(msg.sender)");
        console.log("Better practice: declare owner as 'address payable' from the start");
        console.log("And use constructor for explicit initialization");
    }

    function testVulnerability_StateVariableInitialization() public view {
        console.log("\n=== Vulnerability: State variable initialization ===");
        
        console.log("Owner initialized as msg.sender at declaration");
        console.log("This sets owner during contract creation");
        console.log("But owner is not payable, causing issues with selfdestruct");
        
        address ownerAddr = piggyBank.owner();
        assertEq(ownerAddr, address(this));
        
        console.log("Owner should be payable to receive funds from selfdestruct");
    }

    function testDeposit() public {
        console.log("\n=== Deposit Test ===");
        
        uint256 balanceBefore = address(piggyBank).balance;
        console.log("Balance before:", balanceBefore);
        
        vm.deal(user, 5 ether);
        vm.prank(user);
        (bool success, ) = address(piggyBank).call{value: 1 ether}("");
        require(success, "Deposit failed");
        
        uint256 balanceAfter = address(piggyBank).balance;
        console.log("Balance after:", balanceAfter);
        
        assertEq(balanceAfter - balanceBefore, 1 ether);
        
        console.log("Deposits work correctly via receive() function");
    }
}

