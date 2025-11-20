// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/05_FlashLoanAttack/VulnerablePool.sol";
import "../src/05_FlashLoanAttack/FlashLoanProvider.sol";
import "../src/05_FlashLoanAttack/FlashLoanAttacker.sol";

contract MockToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MockToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }
}

contract FlashLoanAttackTest is Test {
    MockToken public token;
    VulnerablePool public pool;
    FlashLoanProvider public flashLoanProvider;
    FlashLoanAttacker public flashLoanAttacker;
    
    address public owner;
    address public user;
    address public attacker;
    
    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        attacker = makeAddr("attacker");
        
        token = new MockToken(1000000 ether);
        pool = new VulnerablePool(address(token));
        flashLoanProvider = new FlashLoanProvider(address(token));
        
        token.transfer(address(pool), 100000 ether);
        token.transfer(address(flashLoanProvider), 500000 ether);
        token.transfer(user, 10000 ether);
        token.transfer(attacker, 1000 ether);
        
        vm.deal(address(pool), 20000 ether);
        vm.deal(user, 10 ether);
        vm.deal(attacker, 1 ether);
    }
    
    function testPoolBuyTokens() public {
        vm.prank(user);
        pool.buyTokens{value: 1 ether}();
        
        assertGt(pool.tokenBalances(user), 0);
    }
    
    function testPoolSellTokens() public {
        vm.startPrank(user);
        token.approve(address(pool), 50 ether);
        pool.sellTokens(50 ether);
        vm.stopPrank();
        
        assertGt(user.balance, 10 ether);
    }
    
    function testPriceUpdate() public {
        uint256 initialPrice = pool.getPrice();
        assertEq(initialPrice, 1 ether);
        
        vm.prank(user);
        pool.buyTokens{value: 10 ether}();
        
        pool.updatePrice();
        
        uint256 newPrice = pool.getPrice();
        assertTrue(newPrice != initialPrice);
    }
    
    function testFlashLoanAttack() public {
        uint256 loanAmount = 10000 ether;
        
        vm.startPrank(attacker);
        flashLoanAttacker = new FlashLoanAttacker(
            address(flashLoanProvider),
            payable(address(pool)),
            address(token)
        );
        
        uint256 attackerTokensBefore = token.balanceOf(attacker);
        uint256 attackerEthBefore = attacker.balance;
        
        console.log("=== Before Flash Loan Attack ===");
        console.log("Pool price:", pool.getPrice());
        console.log("Attacker tokens:", attackerTokensBefore);
        console.log("Attacker ETH:", attackerEthBefore);
        
        flashLoanAttacker.attack{value: 0.1 ether}(loanAmount);
        
        flashLoanAttacker.withdraw();
        vm.stopPrank();
        
        uint256 attackerTokensAfter = token.balanceOf(attacker);
        uint256 attackerEthAfter = attacker.balance;
        
        console.log("\n=== After Flash Loan Attack ===");
        console.log("Pool price:", pool.getPrice());
        console.log("Attacker tokens:", attackerTokensAfter);
        console.log("Attacker ETH:", attackerEthAfter);
        
        assertGt(attackerTokensAfter, attackerTokensBefore);
    }
}

