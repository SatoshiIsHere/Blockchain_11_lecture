// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/06_TxOriginPhishing/VulnerableWallet.sol";
import "../src/06_TxOriginPhishing/PhishingAttacker.sol";

contract OwnerContract {
    function callAttacker(PhishingAttacker _attacker) public {
        _attacker.attack();
    }
}

contract TxOriginPhishingTest is Test {
    VulnerableWallet public wallet;
    PhishingAttacker public phishingContract;
    OwnerContract public ownerContract;
    
    address public owner;
    address public attacker;
    
    function setUp() public {
        owner = makeAddr("owner");
        attacker = makeAddr("attacker");
        
        vm.deal(owner, 10 ether);
        vm.deal(attacker, 1 ether);
        
        vm.prank(owner, owner);
        wallet = new VulnerableWallet();
        
        vm.prank(owner, owner);
        wallet.deposit{value: 5 ether}();
        
        ownerContract = new OwnerContract();
        
        vm.prank(attacker);
        phishingContract = new PhishingAttacker(address(wallet));
    }
    
    function testWalletDeposit() public view {
        assertEq(wallet.getBalance(), 5 ether);
        assertEq(wallet.owner(), owner);
    }
    
    function testOwnerCanWithdraw() public {
        vm.prank(owner, owner);
        wallet.withdraw(payable(owner), 1 ether);
        assertEq(wallet.getBalance(), 4 ether);
    }
    
    function testPhishingAttack() public {
        console.log("=== Phishing Attack Demo ===");
        console.log("Wallet balance before:", wallet.getBalance());
        console.log("Wallet owner:", wallet.owner());
        console.log("Attacker address:", attacker);
        console.log("Phishing contract:", address(phishingContract));
        
        uint256 attackerBalanceBefore = attacker.balance;
        
        vm.prank(address(phishingContract), owner);
        phishingContract.attack();
        
        console.log("\n=== After Attack ===");
        console.log("Wallet balance:", wallet.getBalance());
        console.log("Attacker gained:", attacker.balance - attackerBalanceBefore);
        
        assertEq(wallet.getBalance(), 0);
        assertEq(attacker.balance - attackerBalanceBefore, 5 ether);
    }
}

