// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface AggregatorV3Interface {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract ChainlinkDataConsumer {
    uint256 public allowedPriceUpdateDelay = 3600;
    
    mapping(address => AggregatorV3Interface) public priceFeeds;
    
    constructor() {
        priceFeeds[0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84] = AggregatorV3Interface(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
        priceFeeds[0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf] = AggregatorV3Interface(0xf403C135812eF27F5403ca0A5BEea4988f8caD54);
    }
    
    function getChainlinkDataFeedLatestAnswer(address token) external view returns (int256) {
        (, int256 price, , uint256 updatedAt, ) = priceFeeds[token].latestRoundData();
        
        if (block.timestamp - updatedAt > allowedPriceUpdateDelay) {
            return 0;
        }
        
        return price;
    }
}

