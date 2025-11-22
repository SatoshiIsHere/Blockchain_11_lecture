// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract ChainlinkDataConsumer {
    error StalePriceFeed(uint256 updatedAt);
    error InvalidRoundData();
    error InvalidPrice();
    error UnauthorizedCaller();
    
    address public owner;
    
    mapping(address => AggregatorV3Interface) public priceFeeds;
    mapping(address => uint256) public allowedDelays;
    
    constructor() {
        owner = msg.sender;
        
        address steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        address cbbtc = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;
        
        priceFeeds[steth] = AggregatorV3Interface(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
        priceFeeds[cbbtc] = AggregatorV3Interface(0xf403C135812eF27F5403ca0A5BEea4988f8caD54);
        
        allowedDelays[steth] = 3600;
        allowedDelays[cbbtc] = 86400;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert UnauthorizedCaller();
        _;
    }
    
    function setAllowedDelay(address token, uint256 delay) external onlyOwner {
        allowedDelays[token] = delay;
    }
    
    function setPriceFeed(address token, address feed) external onlyOwner {
        priceFeeds[token] = AggregatorV3Interface(feed);
    }
    
    function getChainlinkDataFeedLatestAnswer(address token) external view returns (int256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeeds[token].latestRoundData();
        
        if (roundId == 0) revert InvalidRoundData();
        if (answeredInRound < roundId) revert InvalidRoundData();
        if (updatedAt == 0) revert InvalidRoundData();
        if (price <= 0) revert InvalidPrice();
        
        uint256 allowedDelay = allowedDelays[token];
        if (block.timestamp - updatedAt > allowedDelay) {
            revert StalePriceFeed(updatedAt);
        }
        
        return price;
    }
}

