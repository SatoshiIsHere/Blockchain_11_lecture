// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRouter {
    function swap(address tokenIn, address tokenOut, uint256 amount) external returns (uint256);
}

contract SwapHandler {
    address immutable DEX_ROUTER = 0xE592427A0AEcE92d63e1c0f18F8F157C05861564;

    function getRouterAddress() public view returns (address) {
        return DEX_ROUTER;
    }
}

contract LoanManager {
    SwapHandler public swapHandler;
    
    constructor(address _swapHandler) {
        require(_swapHandler != address(0), "Invalid SwapHandler");
        swapHandler = SwapHandler(_swapHandler);
    }

    function executeFlashLoan(address tokenA, address tokenB, uint256 amount) external returns (uint256) {
        address router = swapHandler.getRouterAddress();
        
        IERC20(tokenA).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenA).approve(router, amount);
        
        uint256 amountOut = IRouter(router).swap(tokenA, tokenB, amount);
        
        IERC20(tokenB).transfer(msg.sender, amountOut);
        
        return amountOut;
    }
}

