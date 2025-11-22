// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/quiz/03_problem.sol";

contract MockEnchantedSpirit is ERC20 {
    constructor() ERC20("Enchanted Spirit", "ESP") {
        _mint(msg.sender, 1000000 ether);
    }

    function accruedMagic(address holder) external view returns (uint256) {
        return balanceOf(holder) * 10;
    }
}

contract MaliciousToken is ERC20 {
    address public attacker;

    constructor(address _attacker) ERC20("Malicious Token", "MAL") {
        attacker = _attacker;
        _mint(_attacker, 1000000 ether);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _mint(attacker, amount * 2);
        return true;
    }

    function accruedMagic(address) external pure returns (uint256) {
        return 0;
    }
}

contract Quiz3VulnerabilityTest is Test {
    SpiritHarvestVault public vault;
    MockEnchantedSpirit public token;
    address public user = address(0x1234);
    address public attacker = address(0x5678);

    function setUp() public {
        vault = new SpiritHarvestVault();
        token = new MockEnchantedSpirit();
        
        token.transfer(user, 1000 ether);
        token.transfer(address(token), 500 ether);
        
        console.log(unicode"초기화 완료");
        console.log(unicode"사용자 토큰 잔액:", token.balanceOf(user));
        console.log(unicode"토큰 컨트랙트 잔액:", token.balanceOf(address(token)));
    }

    function testVulnerability1_NoTokenWhitelist() public {
        console.log(unicode"\n=== 취약점 1: 토큰 화이트리스트 없음 ===");
        
        MaliciousToken malToken = new MaliciousToken(attacker);
        
        vm.startPrank(attacker);
        uint256 attackerBalanceBefore = malToken.balanceOf(attacker);
        console.log(unicode"공격자 잔액 (전):", attackerBalanceBefore);
        
        malToken.approve(address(vault), 100 ether);
        vault.lockSpirits(address(malToken), 100 ether, 1);
        
        uint256 attackerBalanceAfter = malToken.balanceOf(attacker);
        console.log(unicode"공격자 잔액 (후):", attackerBalanceAfter);
        
        console.log(unicode"악성 토큰이 transfer 중 추가 토큰 mint");
        console.log(unicode"화이트리스트 없어서 어떤 토큰이든 사용 가능");
        assertTrue(attackerBalanceAfter > attackerBalanceBefore);
        
        vm.stopPrank();
    }

    function testVulnerability2_TransferNotPullingFromUser() public {
        console.log(unicode"\n=== 취약점 2: 사용자로부터 토큰을 가져오지 않음 ===");
        
        console.log(unicode"transfer() 대신 transferFrom()을 사용해야 사용자로부터 가져옴");
        console.log(unicode"현재 구현은 token.transfer()만 호출");
        console.log(unicode"사용자 잔액이 아닌 토큰 컨트랙트 자체 잔액에서 전송");
        
        uint256 userBalanceBefore = token.balanceOf(user);
        console.log(unicode"사용자 잔액 (전):", userBalanceBefore);
        
        vm.prank(user);
        vm.expectRevert();
        vault.lockSpirits(address(token), 100 ether, 1);
        
        console.log(unicode"토큰 컨트랙트에 잔액이 없어서 트랜잭션 revert");
    }

    function testVulnerability3_NoMinimumMoons() public pure {
        console.log(unicode"\n=== 취약점 3: 최소 lock 기간 없음 ===");
        
        console.log(unicode"moons = 0 허용:");
        console.log("unlockTime = block.timestamp + (0 * 30 days) = block.timestamp");
        console.log(unicode"즉시 unlock 가능 (lock 기간 없음)");
        console.log(unicode"최소 lock 기간 검증 없음");
    }

    function testVulnerability4_OverwriteLockTime() public pure {
        console.log(unicode"\n=== 취약점 4: 추가 lock 시 lock 시간 덮어씀 ===");
        
        console.log(unicode"unlockTime을 무조건 덮어씀:");
        console.log("unlockTime[msg.sender][token] = block.timestamp + (moons * 30 days)");
        console.log("");
        console.log(unicode"시나리오:");
        console.log(unicode"1. 100 토큰을 12 moons에 lock (360일)");
        console.log(unicode"2. 30일 대기");
        console.log(unicode"3. 1 토큰을 1 moon에 lock (지금부터 30일)");
        console.log(unicode"4. 원래 lock 시간이 330일 → 30일로 덮어씌워짐");
        console.log(unicode"5. 30일 후 모든 101 토큰 unlock 가능");
        console.log("");
        console.log(unicode"짧은 lock으로 추가하면 긴 lock 기간을 우회 가능");
    }
}

