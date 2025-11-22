// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../src/quiz/answer/03_solution.sol";

contract MockEnchantedSpirit is ERC20 {
    constructor() ERC20("Enchanted Spirit", "ESP") {
        _mint(msg.sender, 1000000 ether);
    }

    function accruedMagic(address holder) external view returns (uint256) {
        return balanceOf(holder) * 10;
    }
}

contract MaliciousToken is ERC20 {
    address public attacker;

    constructor(address _attacker) ERC20("Malicious Token", "MAL") {
        attacker = _attacker;
        _mint(_attacker, 1000000 ether);
    }

    function transferFrom(address, address, uint256 amount) public override returns (bool) {
        _mint(attacker, amount * 2);
        return true;
    }

    function accruedMagic(address) external pure returns (uint256) {
        return 0;
    }
}

contract Quiz3SolutionTest is Test {
    SpiritHarvestVault public vault;
    MockEnchantedSpirit public token;
    address public owner;
    address public user = address(0x1234);
    address public attacker = address(0x5678);

    function setUp() public {
        owner = address(this);
        vault = new SpiritHarvestVault();
        token = new MockEnchantedSpirit();
        
        vault.addWhitelistedToken(address(token));
        
        token.transfer(user, 1000 ether);
        
        console.log("Setup completed");
        console.log("User token balance:", token.balanceOf(user));
    }

    function testFix1_TokenWhitelist() public {
        console.log("\n=== Fix 1: Token Whitelist Enforced ===");
        
        MaliciousToken malToken = new MaliciousToken(attacker);
        
        vm.startPrank(attacker);
        malToken.approve(address(vault), 100 ether);
        
        vm.expectRevert("Token not whitelisted");
        vault.lockSpirits(address(malToken), 100 ether, 1);
        
        console.log("Malicious token rejected by whitelist");
        
        vm.stopPrank();
    }

    function testFix1_OnlyOwnerCanWhitelist() public {
        console.log("\n=== Fix 1: Only Owner Can Whitelist ===");
        
        MockEnchantedSpirit newToken = new MockEnchantedSpirit();
        
        vm.prank(attacker);
        vm.expectRevert("Not owner");
        vault.addWhitelistedToken(address(newToken));
        
        console.log("Non-owner cannot whitelist tokens");
        
        vault.addWhitelistedToken(address(newToken));
        assertTrue(vault.whitelistedTokens(address(newToken)));
        
        console.log("Owner can whitelist tokens");
    }

    function testFix2_TransferFromUser() public {
        console.log("\n=== Fix 2: Uses transferFrom to Pull From User ===");
        
        vm.startPrank(user);
        
        uint256 userBalanceBefore = token.balanceOf(user);
        uint256 vaultBalanceBefore = token.balanceOf(address(vault));
        
        console.log("User balance before:", userBalanceBefore);
        console.log("Vault balance before:", vaultBalanceBefore);
        
        token.approve(address(vault), 100 ether);
        vault.lockSpirits(address(token), 100 ether, 1);
        
        uint256 userBalanceAfter = token.balanceOf(user);
        uint256 vaultBalanceAfter = token.balanceOf(address(vault));
        
        console.log("User balance after:", userBalanceAfter);
        console.log("Vault balance after:", vaultBalanceAfter);
        
        assertEq(userBalanceBefore - userBalanceAfter, 100 ether);
        assertEq(vaultBalanceAfter - vaultBalanceBefore, 100 ether);
        
        console.log("Correctly pulls tokens from user using transferFrom");
        
        vm.stopPrank();
    }

    function testFix3_MinimumMoons() public {
        console.log("\n=== Fix 3: Minimum Lock Period Enforced ===");
        
        vm.startPrank(user);
        token.approve(address(vault), 100 ether);
        
        vm.expectRevert("Lock period too short");
        vault.lockSpirits(address(token), 100 ether, 0);
        
        console.log("Cannot lock with 0 moons");
        
        vault.lockSpirits(address(token), 100 ether, 1);
        console.log("Can lock with minimum 1 moon");
        
        vm.stopPrank();
    }

    function testFix4_CannotOverwriteWithShorterPeriod() public {
        console.log("\n=== Fix 4: Cannot Shorten Lock Period ===");
        
        vm.startPrank(user);
        token.approve(address(vault), 200 ether);
        
        console.log("First lock: 100 tokens for 12 moons");
        vault.lockSpirits(address(token), 100 ether, 12);
        
        uint256 firstUnlockTime = vault.unlockTime(user, address(token));
        console.log("First unlock time:", firstUnlockTime);
        
        vm.warp(block.timestamp + 30 days);
        
        console.log("Attempting second lock with shorter period (1 moon)");
        vm.expectRevert("Cannot shorten lock period");
        vault.lockSpirits(address(token), 50 ether, 1);
        
        console.log("Cannot overwrite with shorter lock period");
        
        vm.stopPrank();
    }

    function testFix4_CanExtendLockPeriod() public {
        console.log("\n=== Fix 4: Can Extend Lock Period ===");
        
        vm.startPrank(user);
        token.approve(address(vault), 200 ether);
        
        vault.lockSpirits(address(token), 100 ether, 1);
        uint256 firstUnlockTime = vault.unlockTime(user, address(token));
        console.log("First unlock time:", firstUnlockTime);
        
        vault.lockSpirits(address(token), 50 ether, 12);
        uint256 secondUnlockTime = vault.unlockTime(user, address(token));
        console.log("Second unlock time (extended):", secondUnlockTime);
        
        assertTrue(secondUnlockTime > firstUnlockTime);
        
        console.log("Can extend lock period with subsequent locks");
        
        vm.stopPrank();
    }

    function testCompleteFlow() public {
        console.log("\n=== Complete Secure Flow ===");
        
        vm.startPrank(user);
        token.approve(address(vault), 100 ether);
        
        vault.lockSpirits(address(token), 100 ether, 1);
        console.log("Locked 100 tokens for 1 moon");
        
        uint256 spirits = vault.spirits(user, address(token));
        console.log("Spirits locked:", spirits);
        
        vm.expectRevert("Cursed");
        vault.freeSpirits(address(token));
        console.log("Cannot unlock before time");
        
        vm.warp(block.timestamp + 30 days);
        
        vault.freeSpirits(address(token));
        console.log("Successfully unlocked after lock period");
        
        uint256 finalBalance = token.balanceOf(user);
        console.log("Final user balance:", finalBalance);
        
        assertEq(finalBalance, 1000 ether);
        
        vm.stopPrank();
    }

    function testMultipleLocks() public {
        console.log("\n=== Multiple Locks With Increasing Periods ===");
        
        vm.startPrank(user);
        token.approve(address(vault), 300 ether);
        
        vault.lockSpirits(address(token), 100 ether, 1);
        console.log("First lock: 100 tokens for 1 moon");
        
        vault.lockSpirits(address(token), 100 ether, 2);
        console.log("Second lock: 100 tokens for 2 moons (extended)");
        
        vault.lockSpirits(address(token), 100 ether, 3);
        console.log("Third lock: 100 tokens for 3 moons (extended again)");
        
        uint256 totalSpirits = vault.spirits(user, address(token));
        console.log("Total spirits:", totalSpirits);
        
        assertEq(totalSpirits, 300 ether);
        
        vm.warp(block.timestamp + 90 days);
        
        vault.freeSpirits(address(token));
        console.log("All spirits freed after final lock period");
        
        assertEq(token.balanceOf(user), 1000 ether);
        
        vm.stopPrank();
    }
}

