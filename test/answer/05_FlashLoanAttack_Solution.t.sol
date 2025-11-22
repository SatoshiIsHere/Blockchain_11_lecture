// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/answer/05_FlashLoanAttack_Solution.sol";
import "../../src/05_FlashLoanAttack/FlashLoanProvider.sol";
import "../../src/05_FlashLoanAttack/FlashLoanAttacker.sol";

contract MockToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MockToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }
}

contract SecureFlashLoanAttacker {
    FlashLoanProvider public flashLoanProvider;
    SecurePool_Solution public pool;
    IERC20 public token;
    address public owner;
    
    constructor(address _flashLoanProvider, address payable _pool, address _token) {
        flashLoanProvider = FlashLoanProvider(_flashLoanProvider);
        pool = SecurePool_Solution(_pool);
        token = IERC20(_token);
        owner = msg.sender;
    }
    
    function attack(uint256 loanAmount) external payable {
        require(msg.sender == owner, "Only owner");
        flashLoanProvider.flashLoan(loanAmount, "");
    }
    
    function executeOperation(uint256 amount, uint256 fee, bytes calldata) external {
        require(msg.sender == address(flashLoanProvider), "Only flash loan provider");
        
        token.approve(address(pool), amount);
        pool.sellTokens(amount);
        
        uint256 ethToSpend = address(this).balance / 2;
        pool.buyTokens{value: ethToSpend}();
        
        uint256 repayAmount = amount + fee;
        require(token.transfer(address(flashLoanProvider), repayAmount), "Repay failed");
    }
    
    receive() external payable {}
}

contract FlashLoanAttackSolutionTest is Test {
    MockToken public token;
    SecurePool_Solution public securePool;
    FlashLoanProvider public flashLoanProvider;
    SecureFlashLoanAttacker public attacker;
    
    address public owner;
    address public user;
    address public attackerAddress;
    
    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        attackerAddress = makeAddr("attacker");
        
        token = new MockToken(1000000 ether);
        securePool = new SecurePool_Solution(address(token));
        flashLoanProvider = new FlashLoanProvider(address(token));
        
        token.transfer(address(securePool), 100000 ether);
        token.transfer(address(flashLoanProvider), 500000 ether);
        token.transfer(user, 10000 ether);
        token.transfer(attackerAddress, 1000 ether);
        
        vm.deal(address(securePool), 20000 ether);
        vm.deal(user, 10 ether);
        vm.deal(attackerAddress, 1 ether);
    }
    
    function testSecurePool_NormalTrade() public {
        vm.startPrank(user);
        securePool.buyTokens{value: 1 ether}();
        assertGt(securePool.tokenBalances(user), 0);
        vm.stopPrank();
    }
    
    function testSecurePool_TradeLimit() public {
        vm.deal(user, 2000 ether);
        vm.startPrank(user);
        vm.expectRevert("Exceeds max trade size");
        securePool.buyTokens{value: 1500 ether}();
        vm.stopPrank();
    }
    
    function testSecurePool_FlashLoanBlocked() public {
        console.log("=== Before Attack ===");
        console.log("Pool price:", securePool.getPrice());
        console.log("Attacker tokens:", token.balanceOf(attackerAddress));
        
        vm.startPrank(attackerAddress);
        attacker = new SecureFlashLoanAttacker(
            address(flashLoanProvider),
            payable(address(securePool)),
            address(token)
        );
        
        uint256 loanAmount = 10000 ether;
        
        vm.expectRevert("Exceeds max trade size");
        attacker.attack{value: 1 ether}(loanAmount);
        vm.stopPrank();
        
        console.log("\n=== After Failed Attack ===");
        console.log("Pool price:", securePool.getPrice());
        console.log("Attacker tokens:", token.balanceOf(attackerAddress));
        
        assertEq(securePool.getPrice(), 1 ether);
        assertEq(token.balanceOf(attackerAddress), 1000 ether);
    }
    
    function testSecurePool_MultipleSmallTrades() public {
        vm.deal(user, 3000 ether);
        vm.startPrank(user);
        
        for (uint i = 0; i < 5; i++) {
            securePool.buyTokens{value: 500 ether}();
        }
        
        assertGt(securePool.tokenBalances(user), 0);
        vm.stopPrank();
    }
}

