// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/answer/01_SimpleStorage_Solution.sol";

contract SimpleStorageSolutionTest is Test {
    SimpleStorage_Solution public simpleStorage;
    
    function setUp() public {
        simpleStorage = new SimpleStorage_Solution();
    }
    
    function testIncrement() public {
        simpleStorage.set(10);
        assertEq(simpleStorage.get(), 10);
        
        simpleStorage.increment();
        assertEq(simpleStorage.get(), 11);
        
        simpleStorage.increment();
        assertEq(simpleStorage.get(), 12);
    }
    
    function testIncrementEmitsEvent() public {
        simpleStorage.set(5);
        
        vm.expectEmit(true, true, false, true);
        emit SimpleStorage_Solution.DataStored(6, address(this));
        simpleStorage.increment();
    }
}

