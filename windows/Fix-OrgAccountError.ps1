#Requires -RunAsAdministrator
<#
.SYNOPSIS
    "Another account from your organization is already signed in on this device" 오류 해결

.DESCRIPTION
    Windows Credential Manager, WAM 토큰, 레지스트리 캐시, Office/Teams/OneDrive 캐시를 정리합니다.
    실행 전 저장하지 않은 Office 작업을 먼저 저장하세요.
#>

$ErrorActionPreference = 'SilentlyContinue'

function Write-Step {
    param([string]$Message)
    Write-Host "`n[$([System.DateTime]::Now.ToString('HH:mm:ss'))] $Message" -ForegroundColor Cyan
}

function Write-Done  { Write-Host "  완료" -ForegroundColor Green }
function Write-Skip  { Write-Host "  건너뜀 (항목 없음)" -ForegroundColor DarkGray }

Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Microsoft 조직 계정 오류 해결 스크립트" -ForegroundColor Yellow
Write-Host "  'Another account from your organization is already signed in'" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

# ------------------------------------------------------------------
# 1단계: 관련 프로세스 종료
# ------------------------------------------------------------------
Write-Step "1/6  Office / Teams / OneDrive 프로세스 종료 중..."

$processes = @(
    'OUTLOOK', 'WINWORD', 'EXCEL', 'POWERPNT', 'ONENOTE',
    'MSPUB', 'MSACCESS', 'LYNC', 'Teams', 'OneDrive',
    'ms-teams', 'msedgewebview2'
)

foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Stop-Process -Name $proc -Force
        Write-Host "  종료: $proc" -ForegroundColor DarkGray
    }
}
Start-Sleep -Seconds 2
Write-Done

# ------------------------------------------------------------------
# 2단계: Windows Credential Manager 정리
# ------------------------------------------------------------------
Write-Step "2/6  Windows Credential Manager에서 Microsoft 자격증명 삭제 중..."

$credPatterns = @(
    'MicrosoftOffice*',
    'Microsoft_OC*',
    'microsoftoffice*',
    'MS.Teams*',
    'msteams*',
    'OneDrive*',
    'MicrosoftOneDrive*',
    'ADAuthority*',
    'live:*',
    'MicrosoftAccount:*',
    'AAD:*'
)

$deleted = 0
foreach ($pattern in $credPatterns) {
    $creds = cmdkey /list | Select-String $pattern.Replace('*','')
    if ($creds) {
        # cmdkey 방식
        $creds | ForEach-Object {
            if ($_ -match 'Target:\s*(.+)') {
                cmdkey /delete:$($Matches[1].Trim()) | Out-Null
                $deleted++
            }
        }
    }
}

# PowerShell CredentialManager 모듈이 있으면 추가 정리
if (Get-Module -ListAvailable -Name CredentialManager) {
    Import-Module CredentialManager
    Get-StoredCredential | Where-Object {
        $_.Target -match 'Microsoft|Office|Teams|OneDrive|MicrosoftOffice|AAD|live\.'
    } | Remove-StoredCredential
}

if ($deleted -gt 0) { Write-Host "  $deleted 개 자격증명 삭제됨" -ForegroundColor DarkGray }
Write-Done

# ------------------------------------------------------------------
# 3단계: WAM (Web Account Manager) 토큰 캐시 삭제
# ------------------------------------------------------------------
Write-Step "3/6  WAM 토큰 캐시 초기화 중..."

$wamPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker",
    "$env:LOCALAPPDATA\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\AC\TokenBroker",
    "$env:LOCALAPPDATA\Microsoft\TokenBroker",
    "$env:LOCALAPPDATA\Microsoft\IdentityCache",
    "$env:LOCALAPPDATA\Microsoft\OneAuth"
)

foreach ($path in $wamPaths) {
    if (Test-Path $path) {
        Remove-Item -Path "$path\*" -Recurse -Force
        Write-Host "  정리: $path" -ForegroundColor DarkGray
    }
}
Write-Done

# ------------------------------------------------------------------
# 4단계: 레지스트리 Office Identity 캐시 삭제
# ------------------------------------------------------------------
Write-Step "4/6  레지스트리 Office Identity 캐시 삭제 중..."

$regPaths = @(
    'HKCU:\Software\Microsoft\Office\16.0\Common\Identity',
    'HKCU:\Software\Microsoft\Office\15.0\Common\Identity',
    'HKCU:\Software\Microsoft\Office\16.0\Common\Internet\WebServiceCache',
    'HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles',
    'HKCU:\Software\Microsoft\Teams'
)

foreach ($reg in $regPaths) {
    if (Test-Path $reg) {
        Remove-Item -Path $reg -Recurse -Force
        Write-Host "  삭제: $reg" -ForegroundColor DarkGray
    }
}
Write-Done

# ------------------------------------------------------------------
# 5단계: Office / Teams / OneDrive 로컬 캐시 정리
# ------------------------------------------------------------------
Write-Step "5/6  로컬 캐시 폴더 정리 중..."

$cachePaths = @(
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\Licensing",
    "$env:LOCALAPPDATA\Microsoft\Office\Licenses",
    "$env:APPDATA\Microsoft\Teams\Cache",
    "$env:APPDATA\Microsoft\Teams\Application Cache",
    "$env:APPDATA\Microsoft\Teams\GPUCache",
    "$env:APPDATA\Microsoft\Teams\databases",
    "$env:APPDATA\Microsoft\Teams\Local Storage",
    "$env:APPDATA\Microsoft\Teams\tmp",
    "$env:LOCALAPPDATA\Microsoft\Teams\SquirrelTemp",
    "$env:LOCALAPPDATA\Microsoft\OneDrive\settings",
    "$env:LOCALAPPDATA\Microsoft\IdentityStore"
)

foreach ($cache in $cachePaths) {
    if (Test-Path $cache) {
        Remove-Item -Path "$cache\*" -Recurse -Force
        Write-Host "  정리: $cache" -ForegroundColor DarkGray
    }
}
Write-Done

# ------------------------------------------------------------------
# 6단계: 관련 서비스 재시작
# ------------------------------------------------------------------
Write-Step "6/6  관련 Windows 서비스 재시작 중..."

$services = @('TokenBroker', 'NgcSvc', 'NgcCtnrSvc', 'KeyIso')

foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Restart-Service -Name $svc -Force
        Write-Host "  재시작: $svc" -ForegroundColor DarkGray
    }
}
Write-Done

# ------------------------------------------------------------------
# 완료 메시지
# ------------------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  정리 완료!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host @"

다음 단계:
  1. PC를 재시작하세요 (강력 권장)
  2. Office 앱을 열고 사용할 계정으로 새로 로그인하세요
  3. 문제가 지속되면 https://myaccount.microsoft.com 에서
     기기 등록을 해제한 후 다시 시도하세요

"@ -ForegroundColor White
