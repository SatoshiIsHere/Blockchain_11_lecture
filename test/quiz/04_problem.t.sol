// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/quiz/04_problem.sol";

contract MockAggregatorV3 is AggregatorV3Interface {
    int256 private price;
    uint256 private updatedAt;
    uint80 private roundId;
    
    constructor(int256 _price, uint256 _updatedAt) {
        price = _price;
        updatedAt = _updatedAt;
        roundId = 1;
    }
    
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (roundId, price, 0, updatedAt, roundId);
    }
    
    function updatePrice(int256 _price, uint256 _updatedAt) external {
        price = _price;
        updatedAt = _updatedAt;
        roundId++;
    }
}

contract Quiz4VulnerabilityTest is Test {
    ChainlinkDataConsumer public consumer;
    
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant CBBTC = 0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf;

    function setUp() public {
        consumer = new ChainlinkDataConsumer();
        
        console.log(unicode"초기화 완료");
        console.log(unicode"허용된 지연:", consumer.allowedPriceUpdateDelay());
    }

    function testVulnerability1_UniformHeartbeatAssumption() public pure {
        console.log(unicode"\n=== 취약점 1: 모든 피드에 동일한 Heartbeat 적용 ===");
        console.log(unicode"allowedPriceUpdateDelay가 모든 피드에 3600초 (1시간) 고정");
        console.log("");
        console.log(unicode"코드 분석:");
        console.log("uint256 public allowedPriceUpdateDelay = 3600; // Fixed for all");
        console.log("");
        console.log(unicode"문제점:");
        console.log(unicode"- STETH/USD (0xCfE...4a8) 1시간마다 업데이트 -> 3600s OK");
        console.log(unicode"- cbBTC/USD (0xf40...D54) 24시간마다 업데이트 -> 3600s 너무 짧음");
        console.log("");
        console.log(unicode"시나리오:");
        console.log(unicode"1. T=0: cbBTC 업데이트, 가격 $95,000");
        console.log(unicode"2. T=1h (3601s): staleness 체크 실패");
        console.log(unicode"3. 다음 23시간 동안 0 반환");
        console.log(unicode"4. T=24h: 새 업데이트 도착, 반복");
        console.log("");
        console.log(unicode"영향: cbBTC 가격이 95.8%의 시간 동안 0 반환 (23/24시간)");
        console.log(unicode"* 잘못된 청산");
        console.log(unicode"* 대출/AMM 프로토콜 DoS");
        console.log(unicode"* 차익거래 공격");
    }

    function testVulnerability2_ReturnsZeroInsteadOfRevert() public pure {
        console.log(unicode"\n=== 취약점 2: Revert 대신 0 반환 ===");
        console.log("");
        console.log(unicode"데이터가 stale일 때 0 반환:");
        console.log("if (block.timestamp - updatedAt > allowedPriceUpdateDelay) {");
        console.log("    return 0;  // BAD: Silent failure");
        console.log("}");
        console.log("");
        console.log(unicode"문제점: 0이 유효한 가격으로 해석될 수 있음");
        console.log(unicode"- AMM에서 0으로 나누기");
        console.log(unicode"- Vault에서 잘못된 가격 책정");
        console.log(unicode"- 조합 가능한 시스템에서 조용한 실패");
        console.log(unicode"- 자연스러운 staleness 중 griefing 공격");
        console.log("");
        console.log(unicode"0 반환 대신 명시적으로 revert해야 함");
        console.log(unicode"Fail-fast 원칙 위배");
    }

    function testVulnerability2_MissingValidation() public pure {
        console.log(unicode"\n=== 취약점 3: 불완전한 검증 ===");
        console.log("");
        console.log(unicode"함수가 updatedAt staleness만 체크");
        console.log(unicode"누락된 검증:");
        console.log("- roundId > 0");
        console.log("- answeredInRound >= roundId");
        console.log(unicode"- price > 0 (음수가 아닌 자산의 경우)");
        console.log("");
        console.log(unicode"불완전한 검증은 잘못된 데이터 사용으로 이어짐");
    }

    function testExploit_ArbitrageOpportunity() public pure {
        console.log(unicode"\n=== 공격: Null 윈도우 중 차익거래 ===");
        console.log("");
        console.log(unicode"시나리오: cbBTC 가격 변화가 있는 변동성 시장");
        console.log("");
        console.log(unicode"T=0: cbBTC 오라클 업데이트, 가격 = $95,000");
        console.log(unicode"T=1h: Staleness 체크 실패 (>3600s), 0 반환");
        console.log(unicode"T=2h: 시장 가격 $98,000로 상승 (+3%)");
        console.log(unicode"      오라클 아직 업데이트 안 됨 (24시간 heartbeat)");
        console.log(unicode"      함수는 여전히 0 반환");
        console.log("");
        console.log(unicode"프로토콜에 미치는 영향:");
        console.log(unicode"- 대출: cbBTC 운영 중단 (DoS)");
        console.log(unicode"- AMM: 스왑 처리 불가");
        console.log(unicode"- Vault: 출금 차단");
        console.log(unicode"- 공격자: 23시간 윈도우 차익거래 악용");
        console.log("");
        console.log(unicode"결과: cbBTC 의존 프로토콜 95.8% 다운타임");
    }
}

