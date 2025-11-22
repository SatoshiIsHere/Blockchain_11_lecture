# =============================================================================
# 금융ISAC 서버 취약점 분석 스크립트 주요 점검 항목
# Version: 2018.1.4
# =============================================================================

# =============================================================================
# 네트워크 서비스 보안
# =============================================================================

# SRV-001, SRV-002: SNMP 커뮤니티 스트링 점검
# - 점검 내용: SNMP 서비스 실행 여부 및 community string 설정 확인
# - 취약점: public/private 등 기본 커뮤니티 스트링 사용 시 시스템 정보 노출
# - 위험도: 중
# - 조치방법: 
#   1) SNMP 서비스 비활성화 또는
#   2) 복잡한 커뮤니티 스트링 설정
#   3) SNMP v3 사용 권장 (암호화 지원)
#   4) 접근 가능 IP 제한 (hosts.allow/deny)

# SRV-004, SRV-005, SRV-006: SMTP 보안 설정
# - 점검 내용: Sendmail 서비스 설정 확인
# - SRV-004: Sendmail 서비스 실행 여부
# - SRV-005: PrivacyOptions 설정 (noexpn, novrfy 등)
# - SRV-006: LogLevel 설정 (로깅 레벨 적절성)
# - 취약점: 
#   - EXPN/VRFY 명령으로 계정 정보 노출
#   - 불충분한 로깅으로 공격 추적 어려움
# - 위험도: 중
# - 조치방법:
#   /etc/mail/sendmail.cf 설정:
#   O PrivacyOptions=authwarnings,noexpn,novrfy
#   O LogLevel=9

# SRV-007: Sendmail 버전 정보 노출
# - 점검 내용: SMTP 배너에서 버전 정보 노출 여부
# - 취약점: 버전 정보 노출 시 알려진 취약점 공격 가능
# - 위험도: 낮
# - 조치방법:
#   /etc/mail/sendmail.cf 설정:
#   O SmtpGreetingMessage=$j Sendmail; $b

# SRV-008: SMTP 서비스 거부 공격 대응
# - 점검 내용: DoS 방어 설정 확인
# - 취약점: 무제한 연결/메시지 허용 시 서비스 거부 공격 가능
# - 위험도: 중
# - 조치방법:
#   /etc/mail/sendmail.cf 설정:
#   O MaxDaemonChildren=50
#   O ConnectionRateThrottle=3
#   O MinFreeBlocks=1000
#   O MaxHeadersLength=32768
#   O MaxMessageSize=10485760

# SRV-009: 스팸 릴레이 차단
# - 점검 내용: /etc/mail/access 파일 설정 확인
# - 취약점: Open Relay 설정 시 스팸 발송 중계지로 악용
# - 위험도: 높음
# - 조치방법:
#   /etc/mail/access 파일에 허용할 도메인만 지정
#   예: example.com RELAY
#       REJECT (기본값)

# SRV-010: SMTP 확장 명령어 제한
# - 점검 내용: EXPN, VRFY 명령 차단 여부
# - 취약점: EXPN/VRFY로 메일링 리스트 및 계정 정보 수집
# - 위험도: 중
# - 조치방법:
#   /etc/mail/sendmail.cf:
#   O PrivacyOptions=noexpn,novrfy

# =============================================================================
# FTP 서비스 보안
# =============================================================================

# SRV-011: FTP 사용자 제한
# - 점검 내용: ftpusers 파일에 시스템 계정 등록 여부
# - 취약점: root, bin, sys 등 시스템 계정의 FTP 접속 허용
# - 위험도: 높음
# - 조치방법:
#   /etc/ftpusers (또는 /etc/vsftpd/ftpusers)에 추가:
#   root
#   bin
#   daemon
#   sys
#   adm
#   lp
#   shutdown
#   halt
#   mail

# SRV-012: .netrc 파일 보안
# - 점검 내용: 홈 디렉토리의 .netrc 파일 권한 및 내용
# - 취약점: .netrc에 FTP 계정 정보가 평문으로 저장됨
# - 위험도: 중
# - 조치방법:
#   1) .netrc 파일 삭제 권장
#   2) 불가피한 경우 권한 600으로 설정 (chmod 600 ~/.netrc)

# SRV-013: FTP 배너 설정
# - 점검 내용: FTP 접속 시 경고 메시지 설정 여부
# - 취약점: 법적 조치를 위한 경고 메시지 부재
# - 위험도: 낮
# - 조치방법:
#   vsftpd: /etc/vsftpd/vsftpd.conf
#   banner_file=/etc/vsftpd/banner.txt
#   
#   ProFTPD: /etc/proftpd.conf
#   DisplayConnect /etc/proftpd/welcome.msg

# SRV-161: FTP 계정 제한
# - 점검 내용: FTP 계정 제한 설정 재확인
# - 취약점: 불필요한 계정의 FTP 접근 허용
# - 위험도: 중
# - 조치방법: SRV-011과 동일

# SRV-167: FTP 서비스 구동 점검
# - 점검 내용: FTP 서비스 실행 여부
# - 취약점: 불필요한 FTP 서비스 실행
# - 위험도: 중
# - 조치방법:
#   1) SFTP/SCP 사용 권장
#   2) 서비스 중지: systemctl stop vsftpd

# SRV-146: FTP 계정 쉘 제한
# - 점검 내용: FTP 전용 계정의 쉘 설정
# - 취약점: FTP 계정으로 쉘 접근 가능
# - 위험도: 중
# - 조치방법:
#   /etc/passwd에서 FTP 계정의 쉘을 /bin/false로 설정
#   예: ftpuser:x:1001:1001::/home/ftpuser:/bin/false

# =============================================================================
# NFS 및 파일 공유 보안
# =============================================================================

# SRV-014, SRV-015: NFS 공유 설정
# - 점검 내용: /etc/exports 파일 점검
# - 취약점: 
#   - everyone 공유 시 누구나 접근 가능
#   - 쓰기 권한 부여 시 파일 변조 가능
# - 위험도: 높음
# - 조치방법:
#   /etc/exports 설정 예:
#   /home/share 192.168.1.0/24(ro,sync,no_root_squash)
#   - 특정 IP/네트워크만 허용
#   - ro (읽기 전용) 권장
#   - root_squash 옵션 사용

# =============================================================================
# RPC 및 레거시 서비스 보안
# =============================================================================

# SRV-016: 불필요한 RPC 서비스
# - 점검 내용: 위험한 RPC 서비스 실행 여부
# - 취약점: rpc.cmsd, rpc.ttdbserverd, sadmind 등은 알려진 취약점 다수
# - 위험도: 높음
# - 조치방법:
#   1) 서비스 중지 및 비활성화
#   2) rpcbind 서비스 중지 (필요 시)
#   systemctl stop rpcbind
#   systemctl disable rpcbind

# SRV-017: automountd 서비스
# - 점검 내용: 자동 마운트 데몬 실행 여부
# - 취약점: 불필요한 파일 시스템 자동 마운트
# - 위험도: 낮
# - 조치방법:
#   systemctl stop autofs
#   systemctl disable autofs

# SRV-065: NIS/NIS+ 서비스
# - 점검 내용: NIS 서비스 실행 여부
# - 취약점: NIS는 암호화되지 않은 구형 프로토콜
# - 위험도: 높음
# - 조치방법:
#   1) LDAP으로 대체 권장
#   2) 서비스 중지: systemctl stop ypbind

# =============================================================================
# 위험한 네트워크 서비스
# =============================================================================

# SRV-019: tftp, talk 서비스
# - 점검 내용: TFTP, talk 등 위험한 서비스 실행 여부
# - 취약점:
#   - TFTP: 인증 없이 파일 전송
#   - talk: 암호화되지 않은 메시징
# - 위험도: 중
# - 조치방법:
#   /etc/xinetd.d/tftp 및 /etc/xinetd.d/talk에서
#   disable = yes 설정

# SRV-025, SRV-035: r 계열 서비스 점검
# - 점검 내용: rlogin, rsh, rexec 실행 여부 및 .rhosts 파일
# - 취약점:
#   - 암호화되지 않은 통신
#   - .rhosts 설정 시 패스워드 없이 접근 가능
#   - IP 스푸핑에 취약
# - 위험도: 높음
# - 조치방법:
#   1) SSH로 대체 필수
#   2) .rhosts, hosts.equiv 파일 삭제
#   3) 서비스 비활성화:
#      chkconfig rlogin off
#      chkconfig rsh off
#      chkconfig rexec off

# SRV-030: finger 서비스
# - 점검 내용: finger 서비스 실행 여부
# - 취약점: 사용자 정보 (로그인명, 홈디렉토리, 최종 로그인 등) 노출
# - 위험도: 중
# - 조치방법:
#   /etc/xinetd.d/finger에서 disable = yes

# SRV-036: DoS 공격에 취약한 서비스
# - 점검 내용: echo, discard, daytime, chargen 서비스
# - 취약점: 
#   - amplification attack 가능
#   - 서비스 거부 공격에 악용
# - 위험도: 중
# - 조치방법:
#   /etc/xinetd.d/에서 해당 서비스 disable

# SRV-158: Telnet 서비스 차단
# - 점검 내용: Telnet 서비스 실행 여부
# - 취약점: 
#   - 패스워드 평문 전송
#   - 세션 스니핑 가능
# - 위험도: 높음
# - 조치방법:
#   1) SSH로 대체 필수
#   2) 서비스 중지: systemctl stop telnet.socket

# =============================================================================
# 터미널 접근 제어
# =============================================================================

# SRV-026: 원격 터미널 접속 시 Root 직접 로그인 제한
# - 점검 내용: /etc/securetty 및 SSH 설정
# - 취약점: root 직접 로그인 허용 시 브루트포스 공격 대상
# - 위험도: 높음
# - 조치방법:
#   1) /etc/securetty에 console만 남기고 삭제
#   2) /etc/ssh/sshd_config:
#      PermitRootLogin no
#   3) 일반 사용자로 로그인 후 su/sudo 사용 권장

# SRV-159: 세션 타임아웃 설정
# - 점검 내용: TMOUT 환경 변수 및 SSH 타임아웃 설정
# - 취약점: 무제한 세션 유지 시 세션 하이재킹 위험
# - 위험도: 중
# - 조치방법:
#   1) /etc/profile 또는 /etc/bashrc:
#      export TMOUT=600  # 10분
#   2) /etc/ssh/sshd_config:
#      ClientAliveInterval 300
#      ClientAliveCountMax 0

# SRV-027: 접근 제어 파일 설정
# - 점검 내용: hosts.allow, hosts.deny 파일 설정
# - 취약점: TCP Wrapper 미설정 시 모든 IP 접근 허용
# - 위험도: 중
# - 조치방법:
#   /etc/hosts.deny: ALL: ALL
#   /etc/hosts.allow: 
#   sshd: 192.168.1.0/255.255.255.0
#   sshd: 10.0.0.0/255.0.0.0

# =============================================================================
# 웹 서버 보안 (Apache)
# =============================================================================

# SRV-039~047: 웹 서버 보안 설정
# - 점검 내용: Apache 설정 파일 점검

# SRV-040: 디렉토리 인덱싱(Indexes) 비활성화
# - 취약점: 디렉토리 목록 노출로 파일 구조 파악
# - 위험도: 중
# - 조치방법:
#   httpd.conf:
#   Options -Indexes

# SRV-042: .htaccess 사용 제한
# - 취약점: 분산 설정 파일로 인한 보안 정책 우회
# - 위험도: 중
# - 조치방법:
#   httpd.conf:
#   <Directory /var/www/html>
#     AllowOverride None
#   </Directory>

# SRV-043: CGI 디렉토리 위치 및 권한
# - 취약점: CGI 스크립트 실행으로 인한 시스템 명령 실행
# - 위험도: 높음
# - 조치방법:
#   1) CGI 사용 최소화
#   2) ScriptAlias로 특정 디렉토리만 지정
#   3) 권한: chown root:root cgi-bin; chmod 755

# SRV-044: 업로드 파일 크기 제한
# - 취약점: 대용량 파일 업로드로 인한 디스크 DoS
# - 위험도: 중
# - 조치방법:
#   httpd.conf:
#   LimitRequestBody 10485760  # 10MB

# SRV-045: 웹 프로세스 권한 (nobody 등)
# - 취약점: root 권한으로 웹 서버 실행 시 침해 시 전체 시스템 장악
# - 위험도: 높음
# - 조치방법:
#   httpd.conf:
#   User apache  (또는 nobody)
#   Group apache (또는 nobody)

# SRV-046: DocumentRoot 위치
# - 취약점: 시스템 디렉토리를 DocumentRoot로 설정 시 시스템 파일 노출
# - 위험도: 높음
# - 조치방법:
#   DocumentRoot를 /var/www/html 등 별도 디렉토리로 지정

# SRV-047: 심볼릭 링크 제한
# - 취약점: 심볼릭 링크를 통한 시스템 파일 접근
# - 위험도: 중
# - 조치방법:
#   httpd.conf:
#   Options -FollowSymLinks

# SRV-148: 웹 서버 정보 노출
# - 취약점: ServerTokens로 서버 버전/OS 정보 노출
# - 위험도: 낮
# - 조치방법:
#   httpd.conf:
#   ServerTokens Prod
#   ServerSignature Off

# =============================================================================
# WAS 보안 (Tomcat)
# =============================================================================

# SRV-060: Tomcat Manager 접근 제한
# - 점검 내용: tomcat-users.xml 설정
# - 취약점: 
#   - 기본 패스워드 사용
#   - Manager 앱 공개 노출
# - 위험도: 높음
# - 조치방법:
#   1) tomcat-users.xml:
#      <user username="admin" password="강력한패스워드" roles="manager-gui"/>
#   2) Manager 앱 IP 제한:
#      conf/Catalina/localhost/manager.xml에서
#      <Valve className="org.apache.catalina.valves.RemoteAddrValve"
#             allow="192\.168\.1\.\d+"/>
#   3) 불필요 시 Manager 앱 삭제

# =============================================================================
# DNS 서비스 보안
# =============================================================================

# SRV-061~066: DNS 서비스 보안

# SRV-061, SRV-063: Zone Transfer 제한
# - 취약점: 모든 DNS 레코드 정보 유출
# - 위험도: 중
# - 조치방법:
#   named.conf:
#   zone "example.com" {
#     type master;
#     allow-transfer { 192.168.1.2; };  # 보조 DNS만
#   };

# SRV-062: 버전 정보 숨김
# - 취약점: BIND 버전 정보로 알려진 취약점 공격
# - 위험도: 낮
# - 조치방법:
#   named.conf:
#   options {
#     version "Not Disclosed";
#   };

# SRV-064: DNS Source Port Randomization
# - 취약점: DNS Cache Poisoning 공격
# - 위험도: 높음
# - 조치방법:
#   BIND 9.5 이상 사용 (자동 적용)

# SRV-066: Recursion 제한
# - 취약점: DNS Amplification DDoS 공격에 악용
# - 위험도: 중
# - 조치방법:
#   named.conf:
#   options {
#     recursion no;  # 권한 있는 DNS 서버인 경우
#     allow-recursion { 192.168.1.0/24; };  # 재귀 쿼리 필요 시
#   };

# =============================================================================
# 계정 및 패스워드 보안
# =============================================================================

# SRV-068: 패스워드 복잡도 및 최소 길이
# - 점검 내용: /etc/shadow 파일 및 PAM 설정
# - 취약점: 단순 패스워드로 브루트포스 공격 성공 가능
# - 위험도: 높음
# - 조치방법:
#   /etc/pam.d/system-auth:
#   password requisite pam_pwquality.so retry=3 minlen=8 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1
#   (최소 8자, 숫자/대문자/소문자/특수문자 각 1개 이상)

# SRV-070: 동일 UID 사용 금지
# - 점검 내용: UID 중복 사용 여부
# - 취약점: 동일 UID 사용 시 권한 혼동 및 추적 어려움
# - 위험도: 중
# - 조치방법:
#   awk -F: '{print $3}' /etc/passwd | sort | uniq -d
#   중복 UID 발견 시 변경

# SRV-074: 패스워드 최대 사용 기간
# - 점검 내용: 패스워드 만료 정책
# - 취약점: 장기간 동일 패스워드 사용 시 유출 위험 증가
# - 위험도: 중
# - 조치방법:
#   /etc/login.defs:
#   PASS_MAX_DAYS 90
#   PASS_MIN_DAYS 1
#   PASS_WARN_AGE 7

# SRV-075, 076: 패스워드 최소 길이 및 복잡도
# - 점검 내용: login.defs 설정
# - 취약점: SRV-068과 유사
# - 위험도: 높음
# - 조치방법: SRV-068 참조

# SRV-077: 패스워드 파일 보호
# - 점검 내용: /etc/passwd에 패스워드 저장 여부
# - 취약점: /etc/passwd는 모든 사용자가 읽을 수 있음
# - 위험도: 높음
# - 조치방법:
#   pwconv 명령으로 shadow 패스워드 적용
#   /etc/passwd에서 패스워드 필드가 'x'인지 확인

# SRV-127: 로그인 시도 제한
# - 점검 내용: 로그인 실패 횟수 제한
# - 취약점: 무제한 로그인 시도로 브루트포스 공격 가능
# - 위험도: 높음
# - 조치방법:
#   /etc/pam.d/system-auth:
#   auth required pam_faillock.so preauth silent audit deny=5 unlock_time=900
#   (5회 실패 시 15분 잠금)

# SRV-142: Root 계정 외 UID 0 금지
# - 점검 내용: UID 0을 가진 계정 확인
# - 취약점: UID 0은 root 권한이므로 추가 계정 존재 시 보안 위험
# - 위험도: 높음
# - 조치방법:
#   awk -F: '($3 == 0) {print $1}' /etc/passwd
#   root 외 계정 발견 시 삭제

# SRV-143: 사용자 계정 점검
# - 점검 내용: 모든 계정의 UID 확인
# - 취약점: 불필요한 계정 존재
# - 위험도: 중
# - 조치방법: 사용하지 않는 계정 삭제

# SRV-160: 불필요한 계정 점검
# - 점검 내용: 장기간 미접속 계정 확인
# - 취약점: 방치된 계정으로 침입 가능
# - 위험도: 중
# - 조치방법:
#   lastlog 명령으로 확인 후 90일 이상 미접속 계정 삭제/잠금

# SRV-164: 그룹 계정 공유 금지
# - 점검 내용: 빈 그룹 확인
# - 취약점: 공용 그룹 계정 사용 시 책임 추적 불가
# - 위험도: 낮
# - 조치방법: 개인별 계정 사용 원칙

# SRV-165: 시스템 계정 쉘 제한
# - 점검 내용: daemon, bin, sys 등의 쉘 설정
# - 취약점: 시스템 계정으로 로그인 가능
# - 위험도: 중
# - 조치방법:
#   /etc/passwd에서 시스템 계정의 쉘을 /sbin/nologin 또는 /bin/false로 변경

# =============================================================================
# 파일 및 디렉토리 권한
# =============================================================================

# SRV-081: Crontab 파일 권한
# - 점검 내용: /var/spool/cron 디렉토리 및 파일 권한
# - 취약점: 다른 사용자가 cron 작업 수정 가능
# - 위험도: 중
# - 조치방법:
#   chown root:root /var/spool/cron
#   chmod 700 /var/spool/cron

# SRV-082: 주요 디렉토리 권한
# - 점검 내용: /usr, /bin, /sbin, /etc, /var 권한
# - 취약점: 시스템 디렉토리 권한 부적절 시 파일 변조 가능
# - 위험도: 높음
# - 조치방법:
#   chmod 755 /usr /bin /sbin /etc /var

# SRV-083: 시스템 시작 파일 권한
# - 점검 내용: /etc/rc*.d, /etc/init.d 파일 소유자 및 권한
# - 취약점: 시작 스크립트 변조 시 부팅 시 악성 코드 실행
# - 위험도: 높음
# - 조치방법:
#   chown root:root /etc/rc*.d/* /etc/init.d/*
#   chmod 755 /etc/rc*.d/* /etc/init.d/*

# SRV-084: /etc/passwd 권한
# - 점검 내용: passwd 파일 권한
# - 취약점: 쓰기 권한 부여 시 계정 정보 변조
# - 위험도: 높음
# - 조치방법:
#   chmod 644 /etc/passwd

# SRV-085: /etc/shadow 권한
# - 점검 내용: shadow 파일 권한
# - 취약점: 읽기 권한 부여 시 패스워드 해시 유출
# - 위험도: 높음
# - 조치방법:
#   chmod 400 /etc/shadow (또는 000)

# SRV-086: /etc/hosts 권한
# - 점검 내용: hosts 파일 권한
# - 취약점: 쓰기 권한 부여 시 DNS 스푸핑
# - 위험도: 중
# - 조치방법:
#   chmod 644 /etc/hosts

# SRV-087: 컴파일러 접근 제한
# - 점검 내용: cc, gcc 실행 파일 권한
# - 취약점: 일반 사용자가 루트킷 컴파일 가능
# - 위험도: 중
# - 조치방법:
#   chmod 750 /usr/bin/gcc /usr/bin/cc
#   또는 일반 사용자 그룹에서 제거

# SRV-088: xinetd.conf, inetd.conf 권한
# - 점검 내용: 슈퍼데몬 설정 파일 권한
# - 취약점: 설정 파일 변조 시 서비스 설정 조작
# - 위험도: 중
# - 조치방법:
#   chmod 600 /etc/xinetd.conf /etc/inetd.conf

# SRV-089: syslog.conf 권한
# - 점검 내용: 로그 설정 파일 권한
# - 취약점: 로그 설정 조작으로 로그 기록 방해
# - 위험도: 중
# - 조치방법:
#   chmod 644 /etc/syslog.conf /etc/rsyslog.conf

# SRV-091: SetUID/SetGID 파일 점검
# - 점검 내용: 불필요한 SetUID 파일 존재 여부
# - 취약점: SetUID 파일 취약점 시 권한 상승 공격
# - 위험도: 높음
# - 조치방법:
#   1) 불필요한 SetUID 제거:
#      find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \;
#   2) 필요한 경우만 SetUID 유지
#   3) 주기적으로 점검

# SRV-092: 홈 디렉토리 소유자 및 권한
# - 점검 내용: 사용자 UID와 홈 디렉토리 소유자 일치 여부
# - 취약점: 소유자 불일치 시 다른 사용자가 접근 가능
# - 위험도: 중
# - 조치방법:
#   chown -R username:username /home/username
#   chmod 700 /home/username

# SRV-093: World Writable 파일
# - 점검 내용: 누구나 쓰기 가능한 파일 존재 여부
# - 취약점: 중요 파일 변조 가능
# - 위험도: 높음
# - 조치방법:
#   find / -type f -perm -002 -exec ls -l {} \;
#   발견 시 chmod o-w 적용

# SRV-094: Crontab에서 참조하는 파일 권한
# - 점검 내용: cron 작업이 실행하는 스크립트 권한
# - 취약점: 스크립트 변조 시 예약된 시간에 악성 코드 실행
# - 위험도: 높음
# - 조치방법:
#   cron 스크립트 소유자를 root로, 권한을 700으로 설정

# SRV-095: 소유자 없는 파일
# - 점검 내용: nouser, nogroup 파일 존재 여부
# - 취약점: 삭제된 계정의 파일로 취약점 존재 가능
# - 위험도: 중
# - 조치방법:
#   find / -nouser -o -nogroup -exec ls -l {} \;
#   발견 시 삭제 또는 소유자 변경

# SRV-096: 홈 디렉토리 숨김 파일
# - 점검 내용: .profile, .bashrc 등 설정 파일 권한
# - 취약점: 환경 변수 조작으로 악성 명령 실행
# - 위험도: 중
# - 조치방법:
#   chmod 644 ~/.profile ~/.bashrc
#   다른 사용자 쓰기 권한 제거

# SRV-099: /etc/services 파일 변조
# - 점검 내용: services 파일 권한 및 변조 여부
# - 취약점: 포트 번호 조작으로 서비스 방해
# - 위험도: 중
# - 조치방법:
#   chmod 644 /etc/services
#   주기적으로 무결성 검사 (AIDE, Tripwire)

# SRV-100: X Server 접근 통제
# - 점검 내용: xterm 등 X 관련 파일 권한
# - 취약점: X11 포워딩으로 화면 캡처 가능
# - 위험도: 중
# - 조치방법:
#   1) X11Forwarding no (/etc/ssh/sshd_config)
#   2) xhost - 명령으로 접근 제한

# SRV-144: /dev 디렉토리 파일 점검
# - 점검 내용: /dev에 일반 파일 존재 여부
# - 취약점: 백도어 파일 숨기기 용도로 악용
# - 위험도: 높음
# - 조치방법:
#   find /dev -type f -exec ls -l {} \;
#   정상 디바이스 파일 외 발견 시 삭제

# SRV-145: 홈 디렉토리 위치
# - 점검 내용: /home 이외의 위치 사용 여부
# - 취약점: 시스템 디렉토리에 홈 설정 시 접근 제어 어려움
# - 위험도: 낮
# - 조치방법: /home 아래로 홈 디렉토리 통일

# =============================================================================
# 로그 및 감사
# =============================================================================

# SRV-107: at 명령 접근 제어
# - 점검 내용: at.allow, at.deny 파일 설정
# - 취약점: 예약 작업을 통한 권한 상승
# - 위험도: 중
# - 조치방법:
#   /etc/at.allow 파일 생성 후 허용할 사용자만 추가
#   (at.allow가 있으면 at.deny는 무시됨)

# SRV-108: 로그 파일 권한
# - 점검 내용: /var/log 디렉토리 및 파일 권한
# - 취약점: 로그 파일 삭제/수정으로 증거 인멸
# - 위험도: 중
# - 조치방법:
#   chown root:root /var/log/*
#   chmod 640 /var/log/*

# SRV-112: Cron 로깅
# - 점검 내용: cron 작업 로그 설정 여부
# - 취약점: cron을 통한 공격 추적 불가
# - 위험도: 낮
# - 조치방법:
#   /etc/syslog.conf (또는 rsyslog.conf):
#   cron.* /var/log/cron

# SRV-114: 로그인 실패 기록
# - 점검 내용: loginlog 파일 존재 및 설정
# - 취약점: 로그인 실패 기록 부재로 브루트포스 공격 탐지 불가
# - 위험도: 중
# - 조치방법:
#   /etc/login.defs:
#   FAILLOG_ENAB yes
#   LOG_UNKFAIL_ENAB yes

# SRV-115: 시스템 로그 파일 접근 권한
# - 점검 내용: 로그 파일 권한 적절성 재확인
# - 취약점: SRV-108과 동일
# - 위험도: 중
# - 조치방법: SRV-108 참조

# SRV-162: su 로그 기록
# - 점검 내용: su 명령 사용 로그 설정
# - 취약점: su 사용 기록 부재로 권한 상승 추적 불가
# - 위험도: 중
# - 조치방법:
#   /etc/syslog.conf (또는 rsyslog.conf):
#   authpriv.* /var/log/secure

# SRV-168: Syslog 설정
# - 점검 내용: syslog.conf 설정 적절성
# - 취약점: 불충분한 로그 수집
# - 위험도: 중
# - 조치방법:
#   /etc/rsyslog.conf 예시:
#   *.info;mail.none;authpriv.none;cron.none /var/log/messages
#   authpriv.* /var/log/secure
#   mail.* /var/log/maillog
#   cron.* /var/log/cron

# =============================================================================
# 환경 및 설정
# =============================================================================

# SRV-118: 최신 보안 패치 적용
# - 점검 내용: OS 버전 및 패치 레벨 확인
# - 취약점: 알려진 보안 취약점 존재
# - 위험도: 높음
# - 조치방법:
#   yum update -y (RHEL/CentOS)
#   apt update && apt upgrade -y (Ubuntu/Debian)

# SRV-121: PATH 환경 변수
# - 점검 내용: 현재 디렉토리(.)가 PATH에 포함되었는지
# - 취약점: 현재 디렉토리의 악성 실행 파일 실행 가능
# - 위험도: 중
# - 조치방법:
#   /etc/profile 및 사용자 .profile에서
#   PATH에 '.'를 제거 또는 맨 뒤에 배치

# SRV-122: Root 계정 umask 설정
# - 점검 내용: Root의 umask 값
# - 취약점: 느슨한 umask로 인한 파일 권한 노출
# - 위험도: 중
# - 조치방법:
#   /root/.bashrc (또는 /etc/profile):
#   umask 027
#   (소유자: 모든 권한, 그룹: 읽기/실행, 기타: 없음)

# SRV-130: 사용자 umask 설정
# - 점검 내용: 일반 사용자의 umask 값
# - 취약점: SRV-122와 유사
# - 위험도: 중
# - 조치방법:
#   /etc/profile:
#   umask 022
#   (소유자: 모든 권한, 그룹: 읽기/실행, 기타: 읽기/실행)

# SRV-131: su 명령 제한
# - 점검 내용: wheel 그룹 등을 이용한 su 명령 제한
# - 취약점: 모든 사용자가 su 명령 사용 가능
# - 위험도: 중
# - 조치방법:
#   /etc/pam.d/su:
#   auth required pam_wheel.so use_uid
#   /etc/group:
#   wheel:x:10:root,adminuser

# SRV-132~133: Cron 사용 제한
# - 점검 내용: cron.allow, cron.deny 파일 설정
# - 취약점: 예약 작업을 통한 지속적 공격
# - 위험도: 중
# - 조치방법:
#   /etc/cron.allow 파일 생성 후 허용할 사용자만 추가
#   (cron.allow가 있으면 cron.deny는 무시됨)

# SRV-106: hosts.lpd 파일
# - 점검 내용: LPD 접근 제어 파일 설정
# - 취약점: LPD 서비스를 통한 무단 인쇄 작업
# - 위험도: 낮
# - 조치방법:
#   /etc/hosts.lpd에 허용할 호스트만 추가

# SRV-163: 배너 설정
# - 점검 내용: /etc/motd, /etc/issue 경고 메시지
# - 취약점: 법적 조치를 위한 경고 메시지 부재
# - 위험도: 낮
# - 조치방법:
#   /etc/issue, /etc/motd에 경고 문구 작성:
#   "본 시스템은 인가된 사용자만 접근 가능합니다.
#    모든 활동은 기록되며 법적 조치의 증거로 사용될 수 있습니다."

# =============================================================================
# OS별 특화 설정
# =============================================================================

# SRV-033: DMI 서비스 (Solaris)
# - 점검 내용: Solaris DMI 데몬 실행 여부
# - 취약점: 불필요한 관리 데몬
# - 위험도: 낮
# - 조치방법:
#   /etc/rc3.d/S77dmi를 /etc/rc3.d/s77dmi로 이름 변경 (비활성화)

# SRV-134: Stack 실행 방지 (Solaris)
# - 점검 내용: noexec_user_stack 설정
# - 취약점: 스택 버퍼 오버플로우 공격
# - 위험도: 높음
# - 조치방법:
#   /etc/system:
#   set noexec_user_stack=1

# SRV-135: TCP Sequence Number 예측 방지
# - 점검 내용: TCP_STRONG_ISS 설정
# - 취약점: TCP 시퀀스 번호 예측으로 세션 하이재킹
# - 위험도: 높음
# - 조치방법:
#   /etc/default/inetinit:
#   TCP_STRONG_ISS=2

# =============================================================================
# 점검 스크립트 사용법
# =============================================================================

# 1. 스크립트 실행 권한 부여
#    chmod +x fsi_unix.sh

# 2. root 권한으로 실행
#    sudo ./fsi_unix.sh

# 3. 결과 파일 생성
#    hostname-s-YYYYMMDD.xml

# 4. 결과 분석
#    생성된 XML 파일을 취약점 점검 도구로 분석

# =============================================================================
# 주의사항
# =============================================================================

# 1. 본 스크립트는 점검 목적으로만 사용하며, 자동 조치 기능은 없습니다.
# 2. 운영 서버에서 실행 시 부하가 발생할 수 있으므로 주의하세요.
# 3. find 명령 등이 실행되므로 완료까지 시간이 소요될 수 있습니다.
# 4. 조치 전 반드시 백업을 수행하세요.
# 5. 서비스 중지/설정 변경 시 업무 영향도를 사전에 확인하세요.
