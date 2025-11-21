// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/02_UpgradableContract/SimpleStorageV1.sol";
import "../src/02_UpgradableContract/SimpleStorageV2.sol";

contract DeployV1 is Script {
    function run() external returns (address proxy, address implementation) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SimpleStorageV1 implementationV1 = new SimpleStorageV1();
        console.log("V1 Implementation deployed at:", address(implementationV1));
        
        bytes memory initData = abi.encodeWithSelector(
            SimpleStorageV1.initialize.selector
        );
        
        ERC1967Proxy proxyContract = new ERC1967Proxy(
            address(implementationV1),
            initData
        );
        console.log("Proxy deployed at:", address(proxyContract));
        
        vm.stopBroadcast();
        
        return (address(proxyContract), address(implementationV1));
    }
}

contract UpgradeToV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SimpleStorageV2 implementationV2 = new SimpleStorageV2();
        console.log("V2 Implementation deployed at:", address(implementationV2));
        
        SimpleStorageV1 proxy = SimpleStorageV1(proxyAddress);
        proxy.upgradeToAndCall(address(implementationV2), "");
        
        console.log("Upgraded proxy to V2");
        console.log("Proxy address (unchanged):", proxyAddress);
        
        vm.stopBroadcast();
    }
}

contract TestUpgrade is Script {
    function run() external {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        
        SimpleStorageV2 storageV2 = SimpleStorageV2(proxyAddress);
        
        console.log("Testing upgraded contract...");
        console.log("Current stored data:", storageV2.get());
        console.log("Current counter:", storageV2.getCounter());
        
        try storageV2.increment() {
            console.log("Increment successful!");
            console.log("New stored data:", storageV2.get());
            console.log("New counter:", storageV2.getCounter());
        } catch {
            console.log("Increment failed - upgrade may not have succeeded");
        }
    }
}

