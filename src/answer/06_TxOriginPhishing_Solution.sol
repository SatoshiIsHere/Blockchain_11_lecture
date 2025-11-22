// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SecureWallet_Solution {
    address public owner;
    
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(address payable _to, uint256 _amount) public {
        require(msg.sender == owner, "Not owner");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        _to.transfer(_amount);
        emit Withdrawal(_to, _amount);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

