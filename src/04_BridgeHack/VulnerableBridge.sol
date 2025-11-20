// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableBridge {
    mapping(address => uint256) public deposits;
    mapping(bytes32 => bool) public processedWithdrawals;
    
    address public validator;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, bytes32 withdrawalId);
    
    constructor(address _validator) {
        validator = _validator;
    }
    
    function deposit() public payable {
        require(msg.value > 0, "Must deposit something");
        deposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(
        address user,
        uint256 amount,
        bytes32 withdrawalId,
        bytes memory signature
    ) public {
        require(!processedWithdrawals[withdrawalId], "Already processed");
        require(address(this).balance >= amount, "Insufficient bridge balance");
        
        bytes32 messageHash = keccak256(abi.encodePacked(user, amount, withdrawalId));
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        
        address signer = recoverSigner(ethSignedMessageHash, signature);
        require(signer == validator, "Invalid signature");
        
        processedWithdrawals[withdrawalId] = true;
        
        payable(user).transfer(amount);
        emit Withdrawn(user, amount, withdrawalId);
    }
    
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) 
        internal 
        pure 
        returns (address) 
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");
        
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

