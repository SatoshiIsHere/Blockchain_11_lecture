// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/02_UpgradableContract/SimpleStorageV1.sol";
import "../src/02_UpgradableContract/SimpleStorageV2.sol";

contract UpgradableContractTest is Test {
    SimpleStorageV1 public implementationV1;
    SimpleStorageV2 public implementationV2;
    ERC1967Proxy public proxy;
    SimpleStorageV1 public wrappedProxyV1;
    SimpleStorageV2 public wrappedProxyV2;
    
    address public owner;
    address public user;
    
    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        
        implementationV1 = new SimpleStorageV1();
        
        proxy = new ERC1967Proxy(
            address(implementationV1),
            abi.encodeCall(implementationV1.initialize, ())
        );
        
        wrappedProxyV1 = SimpleStorageV1(address(proxy));
    }
    
    function testV1BasicFunctions() public {
        wrappedProxyV1.set(42);
        assertEq(wrappedProxyV1.get(), 42);
        
        wrappedProxyV1.set(100);
        assertEq(wrappedProxyV1.get(), 100);
    }
    
    function testUpgradeToV2() public {
        wrappedProxyV1.set(50);
        assertEq(wrappedProxyV1.get(), 50);
        
        implementationV2 = new SimpleStorageV2();
        wrappedProxyV1.upgradeToAndCall(address(implementationV2), "");
        
        wrappedProxyV2 = SimpleStorageV2(address(proxy));
        
        assertEq(wrappedProxyV2.get(), 50);
        
        wrappedProxyV2.increment();
        assertEq(wrappedProxyV2.get(), 51);
        assertEq(wrappedProxyV2.getCounter(), 1);
        
        wrappedProxyV2.increment();
        assertEq(wrappedProxyV2.get(), 52);
        assertEq(wrappedProxyV2.getCounter(), 2);
    }
    
    function testV2IncrementEmitsEvent() public {
        implementationV2 = new SimpleStorageV2();
        wrappedProxyV1.upgradeToAndCall(address(implementationV2), "");
        wrappedProxyV2 = SimpleStorageV2(address(proxy));
        
        wrappedProxyV2.set(10);
        
        vm.expectEmit(true, true, false, true);
        emit SimpleStorageV2.Incremented(11, address(this));
        wrappedProxyV2.increment();
    }
    
    function testUpgradeUnauthorized() public {
        implementationV2 = new SimpleStorageV2();
        
        vm.prank(user);
        vm.expectRevert();
        wrappedProxyV1.upgradeToAndCall(address(implementationV2), "");
    }
}

