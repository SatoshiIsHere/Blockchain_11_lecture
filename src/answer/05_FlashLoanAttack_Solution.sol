// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SecurePool_Solution {
    IERC20 public token;
    uint256 public tokenPrice = 1 ether;
    uint256 public constant MAX_TRADE_SIZE = 1000 ether;
    
    mapping(address => uint256) public tokenBalances;
    
    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensSold(address indexed seller, uint256 amount);
    event PriceUpdated(uint256 newPrice);
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function buyTokens() public payable {
        require(msg.value > 0, "Must send ETH");
        require(msg.value <= MAX_TRADE_SIZE, "Exceeds max trade size");
        
        uint256 tokensToReceive = (msg.value * 1 ether) / tokenPrice;
        require(token.transfer(msg.sender, tokensToReceive), "Transfer failed");
        tokenBalances[msg.sender] += tokensToReceive;
        
        updatePrice();
        emit TokensPurchased(msg.sender, tokensToReceive);
    }
    
    function sellTokens(uint256 amount) public {
        require(amount <= MAX_TRADE_SIZE, "Exceeds max trade size");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        uint256 ethToReceive = (amount * tokenPrice) / 1 ether;
        if (tokenBalances[msg.sender] >= amount) {
            tokenBalances[msg.sender] -= amount;
        }
        
        payable(msg.sender).transfer(ethToReceive);
        updatePrice();
        emit TokensSold(msg.sender, amount);
    }
    
    function updatePrice() internal {
        uint256 poolBalance = address(this).balance;
        uint256 tokenSupply = token.balanceOf(address(this));
        
        if (tokenSupply > 0) {
            tokenPrice = (poolBalance * 1 ether) / tokenSupply;
            emit PriceUpdated(tokenPrice);
        }
    }
    
    function getPrice() public view returns (uint256) {
        return tokenPrice;
    }
    
    receive() external payable {}
}

