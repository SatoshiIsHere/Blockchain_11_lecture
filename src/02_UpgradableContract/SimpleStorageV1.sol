// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SimpleStorageV1 is UUPSUpgradeable, OwnableUpgradeable {
    uint256 private storedData;
    
    event DataStored(uint256 indexed data, address indexed setter);

    // constructor() {
    //     __Ownable_init(msg.sender);
    // }
    
    function initialize() public initializer {
        __Ownable_init(msg.sender);
    }
    
    function set(uint256 x) public {
        storedData = x;
        emit DataStored(x, msg.sender);
    }
    
    function get() public view returns (uint256) {
        return storedData;
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

