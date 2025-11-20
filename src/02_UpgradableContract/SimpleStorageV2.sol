// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SimpleStorageV2 is UUPSUpgradeable, OwnableUpgradeable {
    uint256 private storedData;
    uint256 public counter;
    
    event DataStored(uint256 indexed data, address indexed setter);
    event Incremented(uint256 newValue, address indexed caller);
    
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
    
    function increment() public {
        storedData += 1;
        counter += 1;
        emit Incremented(storedData, msg.sender);
    }
    
    function getCounter() public view returns (uint256) {
        return counter;
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

