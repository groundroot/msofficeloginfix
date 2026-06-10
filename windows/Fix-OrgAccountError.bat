@echo off
:: Fix-OrgAccountError.bat
:: "Another account from your organization is already signed in on this device" 오류 해결
:: 관리자 권한으로 실행하세요.

:: 관리자 권한 확인 및 자동 재실행
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 관리자 권한이 필요합니다. 관리자 권한으로 재실행합니다...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: PowerShell 스크립트 실행
echo Microsoft 조직 계정 오류 해결 스크립트를 시작합니다...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-OrgAccountError.ps1"
echo.
echo 완료되었습니다. 아무 키나 누르면 종료됩니다.
pause >nul
