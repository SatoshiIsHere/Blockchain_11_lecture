// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEnchantedSpirit {
    function transfer(address to, uint256 amount) external returns (bool);
    function accruedMagic(address holder) external view returns (uint256);
}

contract SpiritHarvestVault {
    mapping(address => mapping(address => uint256)) public spirits;
    mapping(address => mapping(address => uint256)) public unlockTime;

    function lockSpirits(address token, uint256 amount, uint256 moons) external {
        IEnchantedSpirit(token).transfer(address(this), amount);
        spirits[msg.sender][token] += amount;
        unlockTime[msg.sender][token] = block.timestamp + (moons * 30 days);
    }

    function freeSpirits(address token) external {
        require(block.timestamp >= unlockTime[msg.sender][token], "Cursed");
        uint256 amount = spirits[msg.sender][token];
        spirits[msg.sender][token] = 0;
        IEnchantedSpirit(token).transfer(msg.sender, amount);
    }

    function viewMagic(address token) external view returns (uint256) {
        return IEnchantedSpirit(token).accruedMagic(address(this));
    }
}

