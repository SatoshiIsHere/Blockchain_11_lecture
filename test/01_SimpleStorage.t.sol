// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/01_SimpleStorage/SimpleStorage.sol";

contract SimpleStorageTest is Test {
    SimpleStorage public simpleStorage;
    address public user1;
    address public user2;
    
    function setUp() public {
        simpleStorage = new SimpleStorage();
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }
    
    function testSetAndGet() public {
        simpleStorage.set(42);
        assertEq(simpleStorage.get(), 42);
    }
    
    function testSetEmitsEvent() public {
        vm.expectEmit();
        emit SimpleStorage.DataStored(100, address(this));
        simpleStorage.set(100);
    }
    
    function testMultipleUsers() public {
        vm.prank(user1);
        simpleStorage.set(10);
        
        vm.prank(user2);
        simpleStorage.set(20);
        
        assertEq(simpleStorage.get(), 20);
    }
    
    function testFuzz_SetValue(uint256 value) public {
        console.log(value);
        simpleStorage.set(value);
        assertEq(simpleStorage.get(), value);
    }
}

