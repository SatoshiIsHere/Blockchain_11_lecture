// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/03_TheDAOHack/TheDAO.sol";
import "../src/03_TheDAOHack/DAOAttacker.sol";

contract TheDAOHackTest is Test {
    TheDAO public dao;
    DAOAttacker public attacker;
    
    address public user1;
    address public user2;
    address public attackerOwner;
    
    function setUp() public {
        dao = new TheDAO();
        
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        attackerOwner = makeAddr("attackerOwner");
        
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(attackerOwner, 5 ether);
    }
    
    function testDAODeposit() public {
        vm.prank(user1);
        dao.deposit{value: 1 ether}();
        
        assertEq(dao.getBalance(user1), 1 ether);
        assertEq(dao.getContractBalance(), 1 ether);
    }
    
    function testDAOWithdraw() public {
        vm.prank(user1);
        dao.deposit{value: 1 ether}();
        
        vm.prank(user1);
        dao.withdraw(1 ether);
        
        assertEq(dao.getBalance(user1), 0);
        assertEq(dao.getContractBalance(), 0);
    }
    
    function testReentrancyAttack() public {
        vm.prank(user1);
        dao.deposit{value: 10 ether}();
        
        vm.prank(user2);
        dao.deposit{value: 10 ether}();
        
        assertEq(dao.getContractBalance(), 20 ether);
        
        vm.startPrank(attackerOwner);
        attacker = new DAOAttacker(address(dao));
        attacker.attack{value: 1 ether}();
        vm.stopPrank();
        
        assertLt(dao.getContractBalance(), 1 ether);
        assertGt(attacker.getBalance(), 20 ether);
    }
    
}
