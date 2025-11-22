// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../src/02_UpgradableContract/SimpleStorageV1.sol";
import "../../src/answer/02_UpgradableContract_Solution.sol";

contract UpgradableContractSolutionTest is Test {
    SimpleStorageV1 public implementationV1;
    SimpleStorageV2_Wrong_Solution public implementationV2Wrong;
    ERC1967Proxy public proxy;
    SimpleStorageV1 public wrappedProxyV1;
    SimpleStorageV2_Wrong_Solution public wrappedProxyV2Wrong;
    
    address public owner;
    
    function setUp() public {
        owner = address(this);
        
        implementationV1 = new SimpleStorageV1();
        
        proxy = new ERC1967Proxy(
            address(implementationV1),
            abi.encodeCall(implementationV1.initialize, ())
        );
        
        wrappedProxyV1 = SimpleStorageV1(address(proxy));
    }
    
    function testWrongUpgrade_DataCorrupted() public {
        wrappedProxyV1.set(100);
        assertEq(wrappedProxyV1.get(), 100);
        
        implementationV2Wrong = new SimpleStorageV2_Wrong_Solution();
        wrappedProxyV1.upgradeToAndCall(address(implementationV2Wrong), "");
        
        wrappedProxyV2Wrong = SimpleStorageV2_Wrong_Solution(address(proxy));
        
        uint256 storedValue = wrappedProxyV2Wrong.get();
        uint256 counterValue = wrappedProxyV2Wrong.getCounter();
        
        console.log("Expected storedData: 100");
        console.log("Actual storedData:  ", storedValue);
        console.log("Expected counter:    0");
        console.log("Actual counter:     ", counterValue);
        
        assertEq(counterValue, 100);
        assertEq(storedValue, 0);
    }
}

