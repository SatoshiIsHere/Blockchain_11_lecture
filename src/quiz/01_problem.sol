// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

    function executeFlashLoan(address tokenA, address tokenB, uint256 amount) external {
        address router = swapHandler.getRouterAddress();
        IRouter(router).swap(tokenA, tokenB, amount);
    }
}

