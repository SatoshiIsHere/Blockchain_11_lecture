// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanReceiver {
    function executeOperation(uint256 amount, uint256 fee, bytes calldata params) external;
}

contract FlashLoanProvider {
    IERC20 public token;
    uint256 public constant FEE_PERCENTAGE = 1;
    
    event FlashLoan(address indexed borrower, uint256 amount, uint256 fee);
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function flashLoan(uint256 amount, bytes calldata params) external {
        uint256 balanceBefore = token.balanceOf(address(this));
        uint256 fee = (amount * FEE_PERCENTAGE) / 100;        
        IFlashLoanReceiver(msg.sender).executeOperation(amount, fee, params);

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore + fee, "Flash loan not repaid");
        
        emit FlashLoan(msg.sender, amount, fee);
    }
    
    function deposit(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
}

