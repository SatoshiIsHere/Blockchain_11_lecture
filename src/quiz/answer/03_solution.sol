// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEnchantedSpirit {
    function accruedMagic(address holder) external view returns (uint256);
}

contract SpiritHarvestVault {
    mapping(address => bool) public whitelistedTokens;
    mapping(address => mapping(address => uint256)) public spirits;
    mapping(address => mapping(address => uint256)) public unlockTime;
    
    address public owner;
    uint256 public constant MIN_LOCK_PERIOD = 1;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    function addWhitelistedToken(address token) external onlyOwner {
        whitelistedTokens[token] = true;
    }
    
    function removeWhitelistedToken(address token) external onlyOwner {
        whitelistedTokens[token] = false;
    }

    function lockSpirits(address token, uint256 amount, uint256 moons) external {
        require(whitelistedTokens[token], "Token not whitelisted");
        require(moons >= MIN_LOCK_PERIOD, "Lock period too short");
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 newUnlockTime = block.timestamp + (moons * 30 days);
        
        if (spirits[msg.sender][token] > 0) {
            require(newUnlockTime >= unlockTime[msg.sender][token], "Cannot shorten lock period");
        }
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        spirits[msg.sender][token] += amount;
        unlockTime[msg.sender][token] = newUnlockTime;
    }

    function freeSpirits(address token) external {
        require(block.timestamp >= unlockTime[msg.sender][token], "Cursed");
        uint256 amount = spirits[msg.sender][token];
        require(amount > 0, "No spirits to free");
        
        spirits[msg.sender][token] = 0;
        unlockTime[msg.sender][token] = 0;
        
        IERC20(token).transfer(msg.sender, amount);
    }

    function viewMagic(address token) external view returns (uint256) {
        return IEnchantedSpirit(token).accruedMagic(address(this));
    }
}

