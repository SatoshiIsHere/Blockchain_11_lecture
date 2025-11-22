// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/answer/04_BridgeHack_Solution.sol";
import "../../src/04_BridgeHack/BridgeAttacker.sol";

contract BridgeHackSolutionTest is Test {
    SecureBridge_Solution public bridgeChainA;
    SecureBridge_Solution public bridgeChainB;
    BridgeAttacker public attacker;
    
    address public validator;
    address public attackerAddress;
    uint256 public validatorPrivateKey;
    
    function setUp() public {
        validatorPrivateKey = 0x1234;
        validator = vm.addr(validatorPrivateKey);
        
        attackerAddress = makeAddr("attacker");
        
        bridgeChainA = new SecureBridge_Solution(validator);
        bridgeChainB = new SecureBridge_Solution(validator);
        attacker = new BridgeAttacker();
        
        vm.deal(address(bridgeChainA), 100 ether);
        vm.deal(address(bridgeChainB), 100 ether);
        vm.deal(attackerAddress, 1 ether);
    }
    
    function testSecureBridge_ReplayBlocked() public {
        bytes32 withdrawalId = keccak256(abi.encodePacked("withdrawal_secure"));
        uint256 amount = 50 ether;
        
        vm.chainId(1);
        bytes32 messageHashA = keccak256(abi.encodePacked(
            attackerAddress,
            amount,
            withdrawalId,
            block.chainid
        ));
        bytes32 ethSignedMessageHashA = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashA)
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPrivateKey, ethSignedMessageHashA);
        bytes memory signatureA = abi.encodePacked(r, s, v);
        
        console.log("=== Secure Bridge Test ===");
        console.log("Chain A (chainId=1) balance before:", address(bridgeChainA).balance);
        console.log("Chain B (chainId=56) balance before:", address(bridgeChainB).balance);
        console.log("Attacker balance before:", attackerAddress.balance);
        
        vm.startPrank(attackerAddress);
        
        bridgeChainA.withdraw(attackerAddress, amount, withdrawalId, signatureA);
        console.log("\n[SUCCESS] Withdrew on Chain A");
        
        vm.chainId(56);
        
        vm.expectRevert("Invalid signature");
        bridgeChainB.withdraw(attackerAddress, amount, withdrawalId, signatureA);
        console.log("[BLOCKED] Chain B rejected the same signature!");
        
        vm.stopPrank();
        
        console.log("\n=== After Attack Attempt ===");
        console.log("Chain A balance after:", address(bridgeChainA).balance);
        console.log("Chain B balance after:", address(bridgeChainB).balance);
        console.log("Attacker balance after:", attackerAddress.balance);
        
        assertEq(address(bridgeChainA).balance, 50 ether);
        assertEq(address(bridgeChainB).balance, 100 ether);
        assertEq(attackerAddress.balance, 51 ether);
    }
}

