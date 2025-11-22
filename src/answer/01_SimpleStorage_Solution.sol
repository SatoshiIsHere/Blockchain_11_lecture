// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleStorage_Solution {
    uint256 private storedData;
    
    event DataStored(uint256 indexed data, address indexed setter);
    
    function set(uint256 x) public {
        storedData = x;
        emit DataStored(x, msg.sender);
    }
    
    function get() public view returns (uint256) {
        return storedData;
    }
    
    function increment() public {
        storedData += 1;
        emit DataStored(storedData, msg.sender);
    }

    function decrement() public {
        storedData -= 1;
        emit DataStored(storedData, msg.sender);
    }
}

