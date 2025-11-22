// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PiggyBank {
    address public owner = msg.sender;
    
    receive() external payable {}
    
    function withdraw() public {
        require(msg.sender == owner, "Not a owner");
        selfdestruct(payable(msg.sender));
    }
    
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not a valid address");
        _;
    }
}