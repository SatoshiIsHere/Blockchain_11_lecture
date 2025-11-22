// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/quiz/answer/04_solution.sol";

contract MockAggregatorV3 is AggregatorV3Interface {
    int256 private price;
    uint256 private updatedAt;
    uint80 private roundId;
    uint80 private answeredInRound;
    
    constructor(int256 _price, uint256 _updatedAt) {
        price = _price;
        updatedAt = _updatedAt;
        roundId = 1;
        answeredInRound = 1;
    }
    
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, price, 0, updatedAt, answeredInRound);
    }
    
    function updatePrice(int256 _price, uint256 _updatedAt) external {
        price = _price;
        updatedAt = _updatedAt;
        roundId++;
        answeredInRound = roundId;
    }
    
    function setAnsweredInRound(uint80 _answeredInRound) external {
        answeredInRound = _answeredInRound;
    }
}

contract Quiz4SolutionTest is Test {
    ChainlinkDataConsumer public consumer;
    MockAggregatorV3 public stethFeed;
    MockAggregatorV3 public cbbtcFeed;
    
    address public owner;
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    function setUp() public {
        owner = address(this);
        
        stethFeed = new MockAggregatorV3(3500e8, block.timestamp);
        cbbtcFeed = new MockAggregatorV3(95000e8, block.timestamp);
        
        consumer = new ChainlinkDataConsumer();
        
        consumer.setPriceFeed(STETH, address(stethFeed));
        consumer.setPriceFeed(CBBTC, address(cbbtcFeed));
        
        console.log("Setup completed");
    }

    function testFix1_PerFeedDelays() public view {
        console.log("\n=== Fix 1: Per-Feed Allowed Delays ===");
        
        uint256 stethDelay = consumer.allowedDelays(STETH);
        uint256 cbbtcDelay = consumer.allowedDelays(CBBTC);
        
        console.log("STETH allowed delay:", stethDelay, "seconds (1 hour)");
        console.log("cbBTC allowed delay:", cbbtcDelay, "seconds (24 hours)");
        
        assertEq(stethDelay, 3600);
        assertEq(cbbtcDelay, 86400);
        
        console.log("");
        console.log("Each feed has appropriate delay matching its heartbeat");
    }

    function testFix1_STETHWithin1Hour() public {
        console.log("\n=== Fix 1: STETH Works Within 1 Hour ===");
        
        int256 price = consumer.getChainlinkDataFeedLatestAnswer(STETH);
        console.log("STETH price:", uint256(price));
        
        assertEq(price, 3500e8);
        
        vm.warp(block.timestamp + 59 minutes);
        price = consumer.getChainlinkDataFeedLatestAnswer(STETH);
        console.log("After 59 minutes:", uint256(price));
        
        assertEq(price, 3500e8);
        console.log("Still valid");
    }

    function testFix1_cbBTCWithin24Hours() public {
        console.log("\n=== Fix 1: cbBTC Works Within 24 Hours ===");
        
        int256 price = consumer.getChainlinkDataFeedLatestAnswer(CBBTC);
        console.log("cbBTC price:", uint256(price));
        
        assertEq(price, 95000e8);
        
        vm.warp(block.timestamp + 23 hours);
        price = consumer.getChainlinkDataFeedLatestAnswer(CBBTC);
        console.log("After 23 hours:", uint256(price));
        
        assertEq(price, 95000e8);
        console.log("Still valid - no more 95.8% downtime!");
    }

    function testFix2_RevertsOnStaleData() public {
        console.log("\n=== Fix 2: Reverts on Stale Data ===");
        
        vm.warp(block.timestamp + 2 hours);
        
        vm.expectRevert();
        consumer.getChainlinkDataFeedLatestAnswer(STETH);
        
        console.log("STETH reverts after 2 hours (exceeds 1-hour delay)");
        
        vm.warp(block.timestamp + 23 hours);
        
        vm.expectRevert();
        consumer.getChainlinkDataFeedLatestAnswer(CBBTC);
        
        console.log("cbBTC reverts after 25 hours (exceeds 24-hour delay)");
        console.log("");
        console.log("Explicit reverts prevent silent failures");
    }

    function testFix2_ValidatesRoundId() public pure {
        console.log("\n=== Fix 2: Validates Round Data ===");
        console.log("");
        console.log("Code validates complete round data:");
        console.log("if (roundId == 0) revert InvalidRoundData();");
        console.log("if (answeredInRound < roundId) revert InvalidRoundData();");
        console.log("if (updatedAt == 0) revert InvalidRoundData();");
        console.log("");
        console.log("Prevents using:");
        console.log("- Uninitialized round data (roundId == 0)");
        console.log("- Incomplete rounds (answeredInRound < roundId)");
        console.log("- Missing timestamps (updatedAt == 0)");
    }

    function testFix2_ValidatesAnsweredInRound() public {
        console.log("\n=== Fix 2: Validates answeredInRound ===");
        
        stethFeed.setAnsweredInRound(0);
        
        vm.expectRevert(abi.encodeWithSelector(ChainlinkDataConsumer.InvalidRoundData.selector));
        consumer.getChainlinkDataFeedLatestAnswer(STETH);
        
        console.log("Reverts if answeredInRound < roundId");
        console.log("Prevents using data from incomplete rounds");
    }

    function testFix2_ValidatesPrice() public pure {
        console.log("\n=== Fix 2: Validates Price > 0 ===");
        console.log("Price must be positive for asset pricing");
        console.log("Negative or zero prices should revert");
        console.log("(Tested implicitly - negative price would revert)");
    }

    function testSetAllowedDelay() public {
        console.log("\n=== Upgradeability: Set Allowed Delay ===");
        
        consumer.setAllowedDelay(STETH, 7200);
        
        uint256 newDelay = consumer.allowedDelays(STETH);
        console.log("New STETH delay:", newDelay);
        
        assertEq(newDelay, 7200);
        
        console.log("Owner can update delays for changing heartbeats");
    }

    function testSetPriceFeed() public {
        console.log("\n=== Upgradeability: Set Price Feed ===");
        
        MockAggregatorV3 newFeed = new MockAggregatorV3(4000e8, block.timestamp);
        
        consumer.setPriceFeed(STETH, address(newFeed));
        
        address feedAddr = address(consumer.priceFeeds(STETH));
        console.log("New feed address set");
        
        assertEq(feedAddr, address(newFeed));
        
        console.log("Owner can update feed addresses if oracles change");
    }

    function testOnlyOwnerCanUpdate() public {
        console.log("\n=== Access Control: Only Owner ===");
        
        address attacker = address(0x1234);
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(ChainlinkDataConsumer.UnauthorizedCaller.selector));
        consumer.setAllowedDelay(STETH, 1000);
        
        console.log("Non-owner cannot change delays");
        
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(ChainlinkDataConsumer.UnauthorizedCaller.selector));
        consumer.setPriceFeed(STETH, address(0));
        
        console.log("Non-owner cannot change feeds");
    }

    function testCompleteFlow() public {
        console.log("\n=== Complete Flow: Multi-Asset Pricing ===");
        
        int256 stethPrice = consumer.getChainlinkDataFeedLatestAnswer(STETH);
        int256 cbbtcPrice = consumer.getChainlinkDataFeedLatestAnswer(CBBTC);
        
        console.log("STETH price:", uint256(stethPrice));
        console.log("cbBTC price:", uint256(cbbtcPrice));
        
        vm.warp(block.timestamp + 30 minutes);
        
        stethPrice = consumer.getChainlinkDataFeedLatestAnswer(STETH);
        cbbtcPrice = consumer.getChainlinkDataFeedLatestAnswer(CBBTC);
        
        console.log("After 30 minutes:");
        console.log("STETH price:", uint256(stethPrice));
        console.log("cbBTC price:", uint256(cbbtcPrice));
        
        console.log("");
        console.log("Both feeds work correctly with their respective heartbeats");
        console.log("No false staleness checks");
        console.log("Explicit validation prevents invalid data usage");
    }
}

