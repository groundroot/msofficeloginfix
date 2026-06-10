#!/usr/bin/env bash
# Fix-OrgAccountError-Mac.sh
# "Another account from your organization is already signed in on this device" 오류 해결 (macOS)
#
# 사용법:
#   chmod +x Fix-OrgAccountError-Mac.sh
#   ./Fix-OrgAccountError-Mac.sh

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; GRAY='\033[0;90m'; RESET='\033[0m'

step() { echo -e "\n${CYAN}[$( date '+%H:%M:%S' )] $1${RESET}"; }
done_msg() { echo -e "  ${GREEN}완료${RESET}"; }
skip_msg() { echo -e "  ${GRAY}건너뜀 (항목 없음)${RESET}"; }

echo -e "${YELLOW}============================================================${RESET}"
echo -e "${YELLOW}  Microsoft 조직 계정 오류 해결 스크립트 (macOS)${RESET}"
echo -e "${YELLOW}  'Another account from your organization is already signed in'${RESET}"
echo -e "${YELLOW}============================================================${RESET}"

# ------------------------------------------------------------------
# 1단계: 관련 앱 종료
# ------------------------------------------------------------------
step "1/5  Office / Teams / OneDrive 프로세스 종료 중..."

APPS=(
    "Microsoft Outlook"
    "Microsoft Word"
    "Microsoft Excel"
    "Microsoft PowerPoint"
    "Microsoft OneNote"
    "Microsoft Teams"
    "Microsoft Teams (work or school)"
    "OneDrive"
)

for app in "${APPS[@]}"; do
    if pgrep -x "$app" &>/dev/null; then
        pkill -x "$app" && echo -e "  ${GRAY}종료: $app${RESET}" || true
    fi
done
sleep 2
done_msg

# ------------------------------------------------------------------
# 2단계: Keychain 정리
# ------------------------------------------------------------------
step "2/5  Keychain에서 Microsoft 관련 항목 삭제 중..."

KEYCHAIN_PATTERNS=(
    "microsoft"
    "office"
    "msteams"
    "onedrive"
    "adal"
    "msal"
    "com.microsoft"
)

deleted=0
for pattern in "${KEYCHAIN_PATTERNS[@]}"; do
    # 인터넷 패스워드 항목 삭제
    while security find-internet-password -s "*${pattern}*" &>/dev/null 2>&1; do
        security delete-internet-password -s "*${pattern}*" &>/dev/null 2>&1 || break
        (( deleted++ )) || true
    done
    # 일반 패스워드 항목 삭제
    while security find-generic-password -a "*${pattern}*" &>/dev/null 2>&1; do
        security delete-generic-password -a "*${pattern}*" &>/dev/null 2>&1 || break
        (( deleted++ )) || true
    done
done

# security 명령으로 직접 삭제 (서비스명 기준)
MS_SERVICES=(
    "Microsoft Office Identities Cache 2"
    "Microsoft Office Identities Cache 3"
    "Microsoft Office Ticket Cache"
    "com.microsoft.adalcache"
    "com.microsoft.MSALCache"
    "MSTeams"
    "OneDrive"
    "MicrosoftOffice"
)

for svc in "${MS_SERVICES[@]}"; do
    if security find-generic-password -s "$svc" &>/dev/null 2>&1; then
        security delete-generic-password -s "$svc" &>/dev/null 2>&1 && \
            echo -e "  ${GRAY}삭제: $svc${RESET}" || true
    fi
done

done_msg

# ------------------------------------------------------------------
# 3단계: MSAL / ADAL 토큰 캐시 삭제
# ------------------------------------------------------------------
step "3/5  MSAL / ADAL 토큰 캐시 삭제 중..."

TOKEN_PATHS=(
    "$HOME/Library/Application Support/Microsoft/OneAuth"
    "$HOME/Library/Application Support/com.microsoft.adalcache"
    "$HOME/Library/Caches/com.microsoft.adalcache"
    "$HOME/Library/Caches/com.microsoft.MSALCache"
    "$HOME/Library/Application Support/Microsoft/Teams/Network Persistent State"
    "$HOME/Library/Application Support/Microsoft/Teams/Cookies"
)

for path in "${TOKEN_PATHS[@]}"; do
    if [ -e "$path" ]; then
        rm -rf "$path" && echo -e "  ${GRAY}삭제: $path${RESET}"
    fi
done
done_msg

# ------------------------------------------------------------------
# 4단계: Teams / Office / OneDrive 캐시 정리
# ------------------------------------------------------------------
step "4/5  앱 캐시 폴더 정리 중..."

CACHE_PATHS=(
    # Microsoft Teams
    "$HOME/Library/Application Support/Microsoft/Teams"
    "$HOME/Library/Caches/com.microsoft.teams"
    "$HOME/Library/Caches/com.microsoft.teams2"
    # Microsoft Office
    "$HOME/Library/Caches/com.microsoft.Word"
    "$HOME/Library/Caches/com.microsoft.Excel"
    "$HOME/Library/Caches/com.microsoft.Powerpoint"
    "$HOME/Library/Caches/com.microsoft.Outlook"
    "$HOME/Library/Caches/com.microsoft.onenote.mac"
    "$HOME/Library/Group Containers/UBF8T346G9.Office/Microsoft Office Licensing"
    "$HOME/Library/Group Containers/UBF8T346G9.Office/Identity"
    # OneDrive
    "$HOME/Library/Caches/com.microsoft.OneDrive"
    "$HOME/Library/Application Support/OneDrive"
)

for path in "${CACHE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        rm -rf "${path:?}/"* 2>/dev/null && echo -e "  ${GRAY}정리: $path${RESET}" || true
    fi
done
done_msg

# ------------------------------------------------------------------
# 5단계: DNS 캐시 플러시
# ------------------------------------------------------------------
step "5/5  DNS 캐시 플러시 중..."

sudo dscacheutil -flushcache 2>/dev/null || true
sudo killall -HUP mDNSResponder 2>/dev/null || true
done_msg

# ------------------------------------------------------------------
# 완료 메시지
# ------------------------------------------------------------------
echo -e "\n${GREEN}============================================================${RESET}"
echo -e "${GREEN}  정리 완료!${RESET}"
echo -e "${GREEN}============================================================${RESET}"
cat <<'EOF'

다음 단계:
  1. Mac을 재시작하세요 (강력 권장)
  2. Office 앱을 열고 사용할 계정으로 새로 로그인하세요
  3. 문제가 지속되면 https://myaccount.microsoft.com 에서
     기기 등록을 해제한 후 다시 시도하세요

EOF
