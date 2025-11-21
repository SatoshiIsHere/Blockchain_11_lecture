// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/08_SecurityToken/SecurityToken.sol";

contract SecurityTokenTest is Test {
    SecurityToken public token;
    
    address public owner;
    address public investor1;
    address public investor2;
    address public transferAgent;
    address public nonAccredited;
    
    bytes32 public constant COMMON_STOCK = bytes32("COMMON");
    bytes32 public constant PREFERRED_STOCK = bytes32("PREFERRED");
    bytes32 public constant RESTRICTED_STOCK = bytes32("RESTRICTED");
    
    function setUp() public {
        owner = address(this);
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        transferAgent = makeAddr("transferAgent");
        nonAccredited = makeAddr("nonAccredited");
        
        token = new SecurityToken("Security Token", "SEC", 1000000 * 10**18);
        
        token.addAccreditedInvestor(investor1);
        token.addAccreditedInvestor(investor2);
        token.addAccreditedInvestor(transferAgent);
        token.authorizeOperator(transferAgent);
    }
    
    function testInitialState() public view {
        assertEq(token.name(), "Security Token");
        assertEq(token.symbol(), "SEC");
        assertEq(token.totalSupply(), 1000000 * 10**18);
        assertEq(token.balanceOf(owner), 1000000 * 10**18);
        assertEq(token.getPartitionBalance(COMMON_STOCK, owner), 1000000 * 10**18);
        assertTrue(token.isAccredited(owner));
        assertTrue(token.transfersEnabled());
    }
    
    function testAccreditedInvestorManagement() public {
        assertTrue(token.isAccredited(investor1));
        
        token.removeAccreditedInvestor(investor1);
        assertFalse(token.isAccredited(investor1));
        
        token.addAccreditedInvestor(investor1);
        assertTrue(token.isAccredited(investor1));
    }
    
    function testOperatorManagement() public {
        assertTrue(token.isOperator(transferAgent));
        
        token.revokeOperator(transferAgent);
        assertFalse(token.isOperator(transferAgent));
        
        token.authorizeOperator(transferAgent);
        assertTrue(token.isOperator(transferAgent));
    }
    
    function testStandardTransfer() public {
        token.transfer(investor1, 1000 * 10**18);
        
        assertEq(token.balanceOf(investor1), 1000 * 10**18);
        assertEq(token.balanceOf(owner), 999000 * 10**18);
    }
    
    function testTransferRestriction_NonAccredited() public {
        vm.expectRevert("Recipient not accredited");
        token.transfer(nonAccredited, 1000 * 10**18);
    }
    
    function testTransferRestriction_Lockup() public {
        token.setLockupPeriod(owner, block.timestamp + 365 days);
        
        vm.expectRevert("Tokens are locked");
        token.transfer(investor1, 1000 * 10**18);
        
        vm.warp(block.timestamp + 366 days);
        token.transfer(investor1, 1000 * 10**18);
        assertEq(token.balanceOf(investor1), 1000 * 10**18);
    }
    
    function testTransferRestriction_Disabled() public {
        token.setTransfersEnabled(false);
        
        vm.expectRevert("Transfers are disabled");
        token.transfer(investor1, 1000 * 10**18);
        
        token.setTransfersEnabled(true);
        token.transfer(investor1, 1000 * 10**18);
        assertEq(token.balanceOf(investor1), 1000 * 10**18);
    }
    
    function testTransferByPartition() public {
        bytes memory data = "";
        
        token.transferByPartition(COMMON_STOCK, investor1, 1000 * 10**18, data);
        
        assertEq(token.getPartitionBalance(COMMON_STOCK, investor1), 1000 * 10**18);
        assertEq(token.balanceOf(investor1), 1000 * 10**18);
    }
    
    function testOperatorTransferByPartition() public {
        token.transfer(investor1, 5000 * 10**18);
        
        vm.prank(transferAgent);
        bytes memory data = "";
        token.operatorTransferByPartition(COMMON_STOCK, investor1, investor2, 1000 * 10**18, data);
        
        assertEq(token.getPartitionBalance(COMMON_STOCK, investor2), 1000 * 10**18);
        assertEq(token.balanceOf(investor2), 1000 * 10**18);
        assertEq(token.balanceOf(investor1), 4000 * 10**18);
    }
    
    function testIssueByPartition() public {
        token.issueByPartition(PREFERRED_STOCK, investor1, 10000 * 10**18);
        
        assertEq(token.getPartitionBalance(PREFERRED_STOCK, investor1), 10000 * 10**18);
        assertEq(token.balanceOf(investor1), 10000 * 10**18);
        assertEq(token.totalSupply(), 1010000 * 10**18);
    }
    
    function testRedeemByPartition() public {
        uint256 initialSupply = token.totalSupply();
        
        token.redeemByPartition(COMMON_STOCK, 1000 * 10**18);
        
        assertEq(token.getPartitionBalance(COMMON_STOCK, owner), 999000 * 10**18);
        assertEq(token.totalSupply(), initialSupply - 1000 * 10**18);
    }
    
    function testChangePartition() public {
        token.transfer(transferAgent, 10000 * 10**18);
        
        vm.prank(transferAgent);
        token.changePartition(COMMON_STOCK, PREFERRED_STOCK, 10000 * 10**18);
        
        assertEq(token.getPartitionBalance(COMMON_STOCK, transferAgent), 0);
        assertEq(token.getPartitionBalance(PREFERRED_STOCK, transferAgent), 10000 * 10**18);
    }
    
    function testDocumentManagement() public {
        bytes32 docName = bytes32("PROSPECTUS");
        string memory uri = "ipfs://QmProspectus123";
        bytes32 docHash = keccak256("Prospectus content");
        
        token.setDocument(docName, uri, docHash);
        
        (string memory returnedUri, bytes32 returnedHash, uint256 timestamp) = token.getDocument(docName);
        
        assertEq(returnedUri, uri);
        assertEq(returnedHash, docHash);
        assertEq(timestamp, block.timestamp);
    }
    
    function testCanTransfer() public view {
        (bool allowed, string memory reason) = token.canTransfer(owner, investor1, 1000 * 10**18);
        assertTrue(allowed);
        assertEq(reason, "Transfer allowed");
    }
    
    function testCanTransfer_NonAccredited() public view {
        (bool allowed, string memory reason) = token.canTransfer(owner, nonAccredited, 1000 * 10**18);
        assertFalse(allowed);
        assertEq(reason, "Recipient not accredited");
    }
    
    function testMultiplePartitions() public {
        token.issueByPartition(PREFERRED_STOCK, investor1, 5000 * 10**18);
        token.issueByPartition(RESTRICTED_STOCK, investor1, 3000 * 10**18);
        
        assertEq(token.getPartitionBalance(PREFERRED_STOCK, investor1), 5000 * 10**18);
        assertEq(token.getPartitionBalance(RESTRICTED_STOCK, investor1), 3000 * 10**18);
        assertEq(token.balanceOf(investor1), 8000 * 10**18);
    }
    
    function testRegulatoryCompliance() public {
        token.transfer(investor1, 100000 * 10**18);
        
        token.setLockupPeriod(investor1, block.timestamp + 180 days);
        
        vm.startPrank(investor1);
        vm.expectRevert("Tokens are locked");
        token.transfer(investor2, 10000 * 10**18);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 181 days);
        
        vm.prank(investor1);
        token.transfer(investor2, 10000 * 10**18);
        
        assertEq(token.balanceOf(investor2), 10000 * 10**18);
    }
}

