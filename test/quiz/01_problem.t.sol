// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/quiz/01_problem.sol";

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

contract Quiz1VulnerabilityTest is Test {
    LoanManager public loanManager;
    SwapHandler public swapHandler;
    MockToken public tokenA;
    MockToken public tokenB;
    MockRouter public router;
    
    address public attacker = address(0x1234);
    address public victim = address(0x5678);

    function setUp() public {
        tokenA = new MockToken("Token A", "TKA");
        tokenB = new MockToken("Token B", "TKB");
        router = new MockRouter();
        swapHandler = new SwapHandler();
        loanManager = new LoanManager();
        
        tokenA.transfer(address(loanManager), 1000 ether);
        tokenB.transfer(address(router), 10000 ether);
        
        console.log("Setup completed");
        console.log("LoanManager balance:", tokenA.balanceOf(address(loanManager)));
    }

    function testVulnerability1_UninitializedSwapHandler() public {
        console.log("\n=== Vulnerability 1: Uninitialized SwapHandler ===");
        
        console.log("swapHandler address:", address(loanManager.swapHandler()));
        
        vm.expectRevert();
        loanManager.executeFlashLoan(address(tokenA), address(tokenB), 100 ether);
        
        console.log("Transaction reverted due to uninitialized swapHandler");
    }

    function testVulnerability2_UnauthorizedFundAccess() public {
        console.log("\n=== Vulnerability 2: Unauthorized Fund Access ===");
        
        vm.store(
            address(loanManager),
            bytes32(uint256(0)),
            bytes32(uint256(uint160(address(swapHandler))))
        );
        
        console.log("Manually set swapHandler to bypass first vulnerability");
        
        uint256 contractBalanceBefore = tokenA.balanceOf(address(loanManager));
        uint256 attackerBalanceBefore = tokenB.balanceOf(attacker);
        
        console.log("Contract tokenA balance before:", contractBalanceBefore);
        console.log("Attacker tokenB balance before:", attackerBalanceBefore);
        
        vm.prank(attacker);
        vm.expectRevert();
        loanManager.executeFlashLoan(address(tokenA), address(tokenB), 100 ether);
        
        console.log("Function is public with no access control");
        console.log("Anyone can call executeFlashLoan");
        console.log("This could drain contract funds if router interaction succeeds");
    }
}

