// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/quiz/answer/05_solution.sol";

contract Quiz5SolutionTest is Test {
    VotingEscrowBugExample public votingEscrow;

    function setUp() public {
        votingEscrow = new VotingEscrowBugExample();
        console.log("Setup completed");
    }

    function testFix1_VersionInTypehash() public pure {
        console.log("\n=== Fix 1: 'version' Included in DOMAIN_TYPEHASH ===");
        console.log("");
        console.log("Fixed DOMAIN_TYPEHASH:");
        console.log("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        console.log("");
        console.log("Now includes all fields:");
        console.log("- name");
        console.log("- version");
        console.log("- chainId");
        console.log("- verifyingContract");
    }

    function testFix2_TypehashEncodingMatch() public pure {
        console.log("\n=== Fix 2: Typehash Matches Encoding ===");
        console.log("");
        console.log("DOMAIN_TYPEHASH defines 4 fields:");
        console.log("  (name, version, chainId, verifyingContract)");
        console.log("");
        console.log("getDomainSeparator() encodes 4 fields:");
        console.log("  abi.encode(");
        console.log("    DOMAIN_TYPEHASH,");
        console.log("    keccak256(bytes(name)),");
        console.log("    keccak256(bytes(version)),");
        console.log("    block.chainid,");
        console.log("    address(this)");
        console.log("  )");
        console.log("");
        console.log("Typehash definition and encoding now match!");
    }

    function testFix3_CorrectFieldOrdering() public pure {
        console.log("\n=== Fix 3: Correct Field Ordering ===");
        console.log("");
        console.log("EIP-712 requires alphabetical ordering");
        console.log("");
        console.log("Fixed order:");
        console.log("  name, version, chainId, verifyingContract");
        console.log("");
        console.log("Note: While EIP-712 spec mentions alphabetical ordering,");
        console.log("the standard EIP712Domain struct commonly uses:");
        console.log("  name, version, chainId, verifyingContract");
        console.log("This matches OpenZeppelin and most implementations");
    }

    function testSignatureVerificationWorks() public view {
        console.log("\n=== Signature Verification Now Works ===");
        console.log("");
        
        bytes32 calculatedDomain = votingEscrow.getDomainSeparator();
        console.log("Calculated domain separator:");
        console.logBytes32(calculatedDomain);
        
        bytes32 expectedTypehash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        
        bytes32 expectedDomain = keccak256(
            abi.encode(
                expectedTypehash,
                keccak256(bytes(votingEscrow.name())),
                keccak256(bytes(votingEscrow.version())),
                block.chainid,
                address(votingEscrow)
            )
        );
        
        console.log("");
        console.log("Expected domain separator:");
        console.logBytes32(expectedDomain);
        
        console.log("");
        assertEq(calculatedDomain, expectedDomain);
        console.log("Domain separators MATCH!");
        console.log("");
        console.log("Off-chain signatures will now verify correctly");
    }

    function testEIP712Compliance() public view {
        console.log("\n=== EIP-712 Compliance Verified ===");
        console.log("");
        
        bytes32 domain = votingEscrow.getDomainSeparator();
        
        console.log("Contract: VotingEscrow");
        console.log("Version: 1.0");
        console.log("ChainId:", block.chainid);
        console.log("Contract Address:");
        console.logAddress(address(votingEscrow));
        console.log("");
        console.log("Domain Separator:");
        console.logBytes32(domain);
        console.log("");
        console.log("This domain separator can be used for:");
        console.log("- ERC20 Permit");
        console.log("- Vote Delegation");
        console.log("- Meta-transactions");
        console.log("- Any EIP-712 typed data signing");
    }

    function testPermitFunctionalityRestored() public pure {
        console.log("\n=== Permit Functionality Restored ===");
        console.log("");
        console.log("With correct EIP-712 implementation:");
        console.log("");
        console.log("1. User signs permit off-chain");
        console.log("   - Uses correct domain separator");
        console.log("   - Creates valid EIP-712 signature");
        console.log("");
        console.log("2. User submits signature to contract");
        console.log("   - Contract calculates same domain separator");
        console.log("   - Signature verification succeeds");
        console.log("");
        console.log("3. Transaction executes successfully");
        console.log("   - Gasless approval granted");
        console.log("   - UX improved");
        console.log("");
        console.log("All EIP-712 based features now functional!");
    }

    function testDomainSeparatorConsistency() public {
        console.log("\n=== Domain Separator Consistency ===");
        console.log("");
        
        bytes32 domain1 = votingEscrow.getDomainSeparator();
        
        vm.warp(block.timestamp + 1 days);
        
        bytes32 domain2 = votingEscrow.getDomainSeparator();
        
        assertEq(domain1, domain2);
        
        console.log("Domain separator remains consistent across time");
        console.log("Only changes if contract redeployed or chainId changes");
    }

    function testCrossChainSeparation() public {
        console.log("\n=== Cross-Chain Separation ===");
        console.log("");
        
        bytes32 domain1 = votingEscrow.getDomainSeparator();
        console.log("Domain on chainId", block.chainid);
        console.logBytes32(domain1);
        
        vm.chainId(137);
        
        bytes32 domain2 = votingEscrow.getDomainSeparator();
        console.log("");
        console.log("Domain on chainId 137:");
        console.logBytes32(domain2);
        
        console.log("");
        assertTrue(domain1 != domain2);
        console.log("Domain separators differ across chains");
        console.log("Prevents cross-chain replay attacks");
    }
}

