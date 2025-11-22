// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/answer/06_TxOriginPhishing_Solution.sol";
import "../../src/06_TxOriginPhishing/PhishingAttacker.sol";
import "../../src/06_TxOriginPhishing/VulnerableWallet.sol";

contract SecurePhishingAttacker {
    SecureWallet_Solution public wallet;
    address public attacker;
    
    constructor(address _walletAddress) {
        wallet = SecureWallet_Solution(_walletAddress);
        attacker = msg.sender;
    }
    
    function attack() public {
        uint256 amount = wallet.getBalance();
        wallet.withdraw(payable(attacker), amount);
    }
    
    receive() external payable {}
}

contract TxOriginPhishingSolutionTest is Test {
    SecureWallet_Solution public secureWallet;
    VulnerableWallet public vulnerableWallet;
    SecurePhishingAttacker public secureAttacker;
    PhishingAttacker public vulnerableAttacker;
    
    address public owner;
    address public attacker;
    
    function setUp() public {
        owner = makeAddr("owner");
        attacker = makeAddr("attacker");
        
        vm.deal(owner, 10 ether);
        vm.deal(attacker, 1 ether);
        
        vm.prank(owner, owner);
        secureWallet = new SecureWallet_Solution();
        
        vm.prank(owner, owner);
        secureWallet.deposit{value: 5 ether}();
        
        vm.prank(owner, owner);
        vulnerableWallet = new VulnerableWallet();
        
        vm.prank(owner, owner);
        vulnerableWallet.deposit{value: 5 ether}();
        
        vm.prank(attacker);
        secureAttacker = new SecurePhishingAttacker(address(secureWallet));
        
        vm.prank(attacker);
        vulnerableAttacker = new PhishingAttacker(address(vulnerableWallet));
    }
    
    function testSecureWallet_OwnerCanWithdraw() public {
        vm.prank(owner, owner);
        secureWallet.withdraw(payable(owner), 1 ether);
        
        assertEq(secureWallet.getBalance(), 4 ether);
    }
    
    function testSecureWallet_PhishingBlocked() public {
        console.log("=== Secure Wallet Test ===");
        console.log("Wallet balance before:", secureWallet.getBalance());
        console.log("Owner:", owner);
        console.log("Attacker:", attacker);
        
        vm.prank(address(secureAttacker), owner);
        vm.expectRevert("Not owner");
        secureAttacker.attack();
        
        console.log("\n=== After Attack Attempt ===");
        console.log("Wallet balance:", secureWallet.getBalance());
        console.log("Attacker balance:", attacker.balance);
        
        assertEq(secureWallet.getBalance(), 5 ether);
        assertEq(attacker.balance, 1 ether);
    }
    
    function testComparison_VulnerableVsSecure() public {
        console.log("=== Comparison Test ===");
        
        console.log("\n[1] Vulnerable Wallet Attack:");
        uint256 vulnerableBalanceBefore = vulnerableWallet.getBalance();
        uint256 attackerBalanceBefore = attacker.balance;
        
        vm.prank(address(vulnerableAttacker), owner);
        vulnerableAttacker.attack();
        
        console.log("Vulnerable wallet balance:", vulnerableBalanceBefore, "->", vulnerableWallet.getBalance());
        console.log("Attacker gained:", attacker.balance - attackerBalanceBefore, "ETH");
        console.log("Attack result: SUCCESS");
        
        assertEq(vulnerableWallet.getBalance(), 0);
        assertEq(attacker.balance - attackerBalanceBefore, 5 ether);
        
        console.log("\n[2] Secure Wallet Attack:");
        uint256 secureBalanceBefore = secureWallet.getBalance();
        uint256 attackerBalance2 = attacker.balance;
        
        vm.prank(address(secureAttacker), owner);
        vm.expectRevert("Not owner");
        secureAttacker.attack();
        
        console.log("Secure wallet balance:", secureBalanceBefore, "->", secureWallet.getBalance());
        console.log("Attacker gained:", attacker.balance - attackerBalance2, "ETH");
        console.log("Attack result: BLOCKED");
        
        assertEq(secureWallet.getBalance(), 5 ether);
        assertEq(attacker.balance, attackerBalance2);
    }
    
    function testSecureWallet_OnlyOwnerCanWithdraw() public {
        vm.prank(attacker);
        vm.expectRevert("Not owner");
        secureWallet.withdraw(payable(attacker), 1 ether);
        
        assertEq(secureWallet.getBalance(), 5 ether);
    }
}

