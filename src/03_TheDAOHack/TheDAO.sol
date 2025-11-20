// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TheDAO {
    mapping(address => uint256) public balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        
        unchecked {
            balances[msg.sender] -= _amount;
        }
        emit Withdraw(msg.sender, _amount);
    }
    
    function getBalance(address _user) public view returns (uint256) {
        return balances[_user];
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

