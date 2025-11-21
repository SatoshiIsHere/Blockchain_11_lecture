// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/01_SimpleStorage/SimpleStorage.sol";
import "../src/02_UpgradableContract/SimpleStorageV1.sol";
import "../src/02_UpgradableContract/SimpleStorageV2.sol";
import "../src/03_TheDAOHack/TheDAO.sol";
import "../src/03_TheDAOHack/DAOAttacker.sol";
import "../src/04_BridgeHack/VulnerableBridge.sol";
import "../src/04_BridgeHack/BridgeAttacker.sol";
import "../src/05_FlashLoanAttack/FlashLoanProvider.sol";
import "../src/05_FlashLoanAttack/VulnerablePool.sol";
import "../src/05_FlashLoanAttack/FlashLoanAttacker.sol";
import "../src/06_TxOriginPhishing/VulnerableWallet.sol";
import "../src/06_TxOriginPhishing/PhishingAttacker.sol";
import "../src/07_WeakRandomness/VulnerableLottery.sol";
import "../src/07_WeakRandomness/LotteryAttacker.sol";
import "../src/08_SecurityToken/SecurityToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MockToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MockToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }
}

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        
        deploy01_SimpleStorage();
        deploy02_UpgradableContract();
        deploy03_TheDAOHack();
        deploy04_BridgeHack();
        deploy05_FlashLoanAttack();
        deploy06_TxOriginPhishing();
        deploy07_WeakRandomness();
        deploy08_SecurityToken();
        
        vm.stopBroadcast();
    }
    
    function deploy01_SimpleStorage() internal {
        console.log("\n=== 01. SimpleStorage ===");
        SimpleStorage simpleStorage = new SimpleStorage();
        console.log("SimpleStorage deployed at:", address(simpleStorage));
    }
    
    function deploy02_UpgradableContract() internal {
        console.log("\n=== 02. UpgradableContract ===");
        
        SimpleStorageV1 implementation = new SimpleStorageV1();
        console.log("SimpleStorageV1 (implementation):", address(implementation));
        
        bytes memory initData = abi.encodeWithSelector(
            SimpleStorageV1.initialize.selector
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));
        
        SimpleStorageV2 implementationV2 = new SimpleStorageV2();
        console.log("SimpleStorageV2 (implementation):", address(implementationV2));
    }
    
    function deploy03_TheDAOHack() internal {
        console.log("\n=== 03. TheDAOHack ===");
        
        TheDAO dao = new TheDAO();
        console.log("TheDAO deployed at:", address(dao));
        
        DAOAttacker attacker = new DAOAttacker(address(dao));
        console.log("DAOAttacker deployed at:", address(attacker));
    }
    
    function deploy04_BridgeHack() internal {
        console.log("\n=== 04. BridgeHack ===");
        
        address validator = vm.addr(0x1234);
        
        VulnerableBridge bridge = new VulnerableBridge(validator);
        console.log("VulnerableBridge deployed at:", address(bridge));
        console.log("Validator:", validator);
        
        BridgeAttacker attacker = new BridgeAttacker();
        console.log("BridgeAttacker deployed at:", address(attacker));
    }
    
    function deploy05_FlashLoanAttack() internal {
        console.log("\n=== 05. FlashLoanAttack ===");
        
        MockToken token = new MockToken(1000000 ether);
        console.log("MockToken deployed at:", address(token));
        
        VulnerablePool pool = new VulnerablePool(address(token));
        console.log("VulnerablePool deployed at:", address(pool));
        
        FlashLoanProvider provider = new FlashLoanProvider(address(token));
        console.log("FlashLoanProvider deployed at:", address(provider));
        
        FlashLoanAttacker attacker = new FlashLoanAttacker(
            address(provider),
            payable(address(pool)),
            address(token)
        );
        console.log("FlashLoanAttacker deployed at:", address(attacker));
    }
    
    function deploy06_TxOriginPhishing() internal {
        console.log("\n=== 06. TxOriginPhishing ===");
        
        VulnerableWallet wallet = new VulnerableWallet();
        console.log("VulnerableWallet deployed at:", address(wallet));
        
        PhishingAttacker attacker = new PhishingAttacker(address(wallet));
        console.log("PhishingAttacker deployed at:", address(attacker));
    }
    
    function deploy07_WeakRandomness() internal {
        console.log("\n=== 07. WeakRandomness ===");
        
        VulnerableLottery lottery = new VulnerableLottery();
        console.log("VulnerableLottery deployed at:", address(lottery));
        
        LotteryAttacker attacker = new LotteryAttacker(address(lottery));
        console.log("LotteryAttacker deployed at:", address(attacker));
    }
    
    function deploy08_SecurityToken() internal {
        console.log("\n=== 08. SecurityToken ===");
        
        SecurityToken token = new SecurityToken(
            "Example Security Token",
            "EST",
            1000000 * 10**18
        );
        console.log("SecurityToken deployed at:", address(token));
    }
}

contract Deploy01_SimpleStorage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        SimpleStorage simpleStorage = new SimpleStorage();
        console.log("SimpleStorage deployed at:", address(simpleStorage));
        
        vm.stopBroadcast();
    }
}

contract Deploy02_UpgradableContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        SimpleStorageV1 implementation = new SimpleStorageV1();
        console.log("SimpleStorageV1 (implementation):", address(implementation));
        
        bytes memory initData = abi.encodeWithSelector(
            SimpleStorageV1.initialize.selector
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        console.log("Proxy deployed at:", address(proxy));
        
        SimpleStorageV2 implementationV2 = new SimpleStorageV2();
        console.log("SimpleStorageV2 (implementation):", address(implementationV2));
        
        vm.stopBroadcast();
    }
}

contract Deploy03_TheDAOHack is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        TheDAO dao = new TheDAO();
        console.log("TheDAO deployed at:", address(dao));
        
        DAOAttacker attacker = new DAOAttacker(address(dao));
        console.log("DAOAttacker deployed at:", address(attacker));
        
        vm.stopBroadcast();
    }
}

contract Deploy04_BridgeHack is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address validator = vm.addr(0x1234);
        
        vm.startBroadcast(deployerPrivateKey);
        
        VulnerableBridge bridge = new VulnerableBridge(validator);
        console.log("VulnerableBridge deployed at:", address(bridge));
        console.log("Validator:", validator);
        
        BridgeAttacker attacker = new BridgeAttacker();
        console.log("BridgeAttacker deployed at:", address(attacker));
        
        vm.stopBroadcast();
    }
}

contract Deploy05_FlashLoanAttack is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        MockToken token = new MockToken(1000000 ether);
        console.log("MockToken deployed at:", address(token));
        
        VulnerablePool pool = new VulnerablePool(address(token));
        console.log("VulnerablePool deployed at:", address(pool));
        
        FlashLoanProvider provider = new FlashLoanProvider(address(token));
        console.log("FlashLoanProvider deployed at:", address(provider));
        
        FlashLoanAttacker attackerImpl = new FlashLoanAttacker(
            address(provider),
            payable(address(pool)),
            address(token)
        );
        console.log("FlashLoanAttacker deployed at:", address(attackerImpl));
        
        vm.stopBroadcast();
    }
}

contract Deploy06_TxOriginPhishing is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        VulnerableWallet wallet = new VulnerableWallet();
        console.log("VulnerableWallet deployed at:", address(wallet));
        
        PhishingAttacker attacker = new PhishingAttacker(address(wallet));
        console.log("PhishingAttacker deployed at:", address(attacker));
        
        vm.stopBroadcast();
    }
}

contract Deploy07_WeakRandomness is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        VulnerableLottery lottery = new VulnerableLottery();
        console.log("VulnerableLottery deployed at:", address(lottery));
        
        LotteryAttacker attacker = new LotteryAttacker(address(lottery));
        console.log("LotteryAttacker deployed at:", address(attacker));
        
        vm.stopBroadcast();
    }
}

contract Deploy08_SecurityToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        SecurityToken token = new SecurityToken(
            "Example Security Token",
            "EST",
            1000000 * 10**18
        );
        console.log("SecurityToken deployed at:", address(token));
        
        vm.stopBroadcast();
    }
}
