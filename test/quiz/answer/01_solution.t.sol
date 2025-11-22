// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../src/quiz/answer/01_solution.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 ether);
    }
}

contract MockRouter is IRouter {
    function swap(address tokenIn, address tokenOut, uint256 amount) external returns (uint256) {
        ERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        uint256 amountOut = amount * 2;
        ERC20(tokenOut).transfer(msg.sender, amountOut);
        return amountOut;
    }
}

contract Quiz1AnswerTest is Test {
    LoanManager public loanManager;
    SwapHandler public swapHandler;
    MockToken public tokenA;
    MockToken public tokenB;
    MockRouter public router;
    
    address public user = address(0x1234);
    address public attacker = address(0x5678);

    function setUp() public {
        tokenA = new MockToken("Token A", "TKA");
        tokenB = new MockToken("Token B", "TKB");
        router = new MockRouter();
        swapHandler = new SwapHandler();
        loanManager = new LoanManager(address(swapHandler));
        
        address dexRouter = swapHandler.getRouterAddress();
        vm.etch(dexRouter, address(router).code);
        
        tokenA.transfer(user, 1000 ether);
        tokenB.transfer(dexRouter, 10000 ether);
        
        console.log("Setup completed");
        console.log("User tokenA balance:", tokenA.balanceOf(user));
    }

    function testFix1_SwapHandlerInitialized() public view {
        console.log("\n=== Fix 1: SwapHandler Properly Initialized ===");
        
        address swapHandlerAddr = address(loanManager.swapHandler());
        console.log("swapHandler address:", swapHandlerAddr);
        
        assertTrue(swapHandlerAddr != address(0), "SwapHandler should be initialized");
        assertEq(swapHandlerAddr, address(swapHandler), "SwapHandler should match");
        
        console.log("SwapHandler is properly initialized");
    }

    function testFix1_ConstructorValidation() public {
        console.log("\n=== Fix 1: Constructor Validates SwapHandler ===");
        
        vm.expectRevert("Invalid SwapHandler");
        new LoanManager(address(0));
        
        console.log("Constructor properly rejects zero address");
    }

    function testFix2_UsesUserFunds() public {
        console.log("\n=== Fix 2: Uses User Funds (Not Contract Funds) ===");
        
        uint256 userBalanceBefore = tokenA.balanceOf(user);
        uint256 contractBalanceBefore = tokenA.balanceOf(address(loanManager));
        
        console.log("User tokenA balance before:", userBalanceBefore);
        console.log("Contract tokenA balance before:", contractBalanceBefore);
        
        vm.startPrank(user);
        tokenA.approve(address(loanManager), 100 ether);
        loanManager.executeFlashLoan(address(tokenA), address(tokenB), 100 ether);
        vm.stopPrank();
        
        uint256 userBalanceAfter = tokenA.balanceOf(user);
        uint256 contractBalanceAfter = tokenA.balanceOf(address(loanManager));
        uint256 userTokenBBalance = tokenB.balanceOf(user);
        
        console.log("User tokenA balance after:", userBalanceAfter);
        console.log("Contract tokenA balance after:", contractBalanceAfter);
        console.log("User tokenB balance:", userTokenBBalance);
        
        assertEq(userBalanceBefore - userBalanceAfter, 100 ether);
        assertEq(contractBalanceAfter, contractBalanceBefore);
        assertEq(userTokenBBalance, 200 ether);
        
        console.log("Uses user funds, not contract funds");
    }

    function testFix2_AttackerCannotDrainContractFunds() public {
        console.log("\n=== Fix 2: Attacker Cannot Drain Contract Funds ===");
        
        tokenA.transfer(address(loanManager), 1000 ether);
        
        uint256 contractBalanceBefore = tokenA.balanceOf(address(loanManager));
        console.log("Contract tokenA balance before:", contractBalanceBefore);
        
        vm.startPrank(attacker);
        tokenA.approve(address(loanManager), 100 ether);
        vm.expectRevert();
        loanManager.executeFlashLoan(address(tokenA), address(tokenB), 100 ether);
        vm.stopPrank();
        
        uint256 contractBalanceAfter = tokenA.balanceOf(address(loanManager));
        console.log("Contract tokenA balance after:", contractBalanceAfter);
        
        assertEq(contractBalanceAfter, contractBalanceBefore);
        
        console.log("Attacker cannot drain contract funds");
        console.log("Only uses msg.sender's approved tokens");
    }

    function testNormalOperation() public {
        console.log("\n=== Normal Operation Test ===");
        
        vm.startPrank(user);
        tokenA.approve(address(loanManager), 500 ether);
        
        uint256 amountOut = loanManager.executeFlashLoan(address(tokenA), address(tokenB), 500 ether);
        
        console.log("Swap completed successfully");
        console.log("Amount out:", amountOut);
        
        assertEq(amountOut, 1000 ether);
        assertEq(tokenB.balanceOf(user), 1000 ether);
        
        vm.stopPrank();
    }
}

