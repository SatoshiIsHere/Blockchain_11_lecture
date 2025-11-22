// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/quiz/05_problem.sol";

contract Quiz5VulnerabilityTest is Test {
    VotingEscrowBugExample public votingEscrow;

    function setUp() public {
        votingEscrow = new VotingEscrowBugExample();
        console.log(unicode"초기화 완료");
    }

    function testVulnerability1_MissingVersionInTypehash() public pure {
        console.log(unicode"\n=== 취약점 1: DOMAIN_TYPEHASH에 'version' 누락 ===");
        console.log("");
        console.log(unicode"현재 DOMAIN_TYPEHASH:");
        console.log("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
        console.log("");
        console.log(unicode"문제점: 'string version' 필드 누락");
        console.log("");
        console.log(unicode"컨트랙트에 있는 것:");
        console.log("- name = 'VotingEscrow'");
        console.log("- version = '1.0'");
        console.log("");
        console.log(unicode"올바른 DOMAIN_TYPEHASH:");
        console.log("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    function testVulnerability2_TypehashEncodingMismatch() public pure {
        console.log(unicode"\n=== 취약점 2: Typehash-Encoding 불일치 ===");
        console.log("");
        console.log(unicode"DOMAIN_TYPEHASH는 3개 필드 정의:");
        console.log("  (name, chainId, verifyingContract)");
        console.log("");
        console.log(unicode"하지만 getDomainSeparator()는 4개 필드 인코딩:");
        console.log("  abi.encode(");
        console.log("    DOMAIN_TYPEHASH,");
        console.log("    keccak256(bytes(name)),");
        console.log(unicode"    keccak256(bytes(version)),  // 추가 필드!");
        console.log("    block.chainid,");
        console.log("    address(this)");
        console.log("  )");
        console.log("");
        console.log(unicode"Typehash 정의와 실제 인코딩이 불일치");
    }

    function testVulnerability3_WrongFieldOrdering() public pure {
        console.log(unicode"\n=== 취약점 3: 필드 순서 오류 ===");
        console.log("");
        console.log(unicode"EIP-712는 구조체 필드를 알파벳 순서로 요구");
        console.log("");
        console.log(unicode"올바른 순서:");
        console.log("  1. chainId");
        console.log("  2. name");
        console.log("  3. verifyingContract");
        console.log("  4. version");
        console.log("");
        console.log(unicode"현재 구현:");
        console.log(unicode"  name, chainId, verifyingContract (version 누락)");
        console.log("");
        console.log(unicode"version 추가 시 올바른 알파벳 순서:");
        console.log("  EIP712Domain(uint256 chainId,string name,address verifyingContract,string version)");
    }

    function testImpact_SignatureVerificationFailure() public view {    
        console.log(unicode"\n=== 영향: 서명 검증 실패 ===");
        console.log("");
        
        bytes32 calculatedDomain = votingEscrow.getDomainSeparator();
        console.log(unicode"계산된 domain separator:");
        console.logBytes32(calculatedDomain);
        
        bytes32 correctTypehash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        
        bytes32 correctDomain = keccak256(
            abi.encode(
                correctTypehash,
                keccak256(bytes(votingEscrow.name())),
                keccak256(bytes(votingEscrow.version())),
                block.chainid,
                address(votingEscrow)
            )
        );
        
        console.log("");
        console.log(unicode"올바른 domain separator (typehash에 version 포함):");
        console.logBytes32(correctDomain);
        
        console.log("");
        assertTrue(calculatedDomain != correctDomain);
        console.log(unicode"Domain separator가 일치하지 않음!");
        console.log("");
        console.log(unicode"영향:");
        console.log(unicode"- 오프체인 서명이 온체인에서 검증 안 됨");
        console.log(unicode"- Permit 함수 실패");
        console.log(unicode"- 위임 메커니즘 작동 안 됨");
        console.log(unicode"- 모든 EIP-712 기반 기능 DoS");
    }

    function testImpact_PermitDoS() public pure {
        console.log(unicode"\n=== 영향: Permit 함수 DoS ===");
        console.log("");
        console.log(unicode"시나리오:");
        console.log(unicode"1. 사용자가 올바른 EIP-712로 오프체인 서명");
        console.log(unicode"2. 사용자가 서명을 컨트랙트에 제출");
        console.log(unicode"3. 컨트랙트가 domain separator 계산 (잘못됨)");
        console.log(unicode"4. 서명 검증 실패");
        console.log(unicode"5. 트랜잭션 revert");
        console.log("");
        console.log(unicode"결과: 모든 permit/위임 기능 사용 불가");
        console.log("");
        console.log(unicode"영향받는 기능 예시:");
        console.log(unicode"- ERC20 Permit (가스 없는 승인)");
        console.log(unicode"- 투표 위임");
        console.log(unicode"- 메타 트랜잭션");
        console.log(unicode"- 모든 타입 데이터 서명");
    }
}

