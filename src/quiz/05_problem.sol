// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingEscrowBugExample {
    string public name = "VotingEscrow";
    string public version = "1.0";
    
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );
    
    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }
}

