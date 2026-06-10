# MS Office / Microsoft 365 조직 계정 오류 해결 스크립트

## 오류 증상

Microsoft 365 (Office, Teams, OneDrive 등) 로그인 시 아래 오류가 발생하는 경우 이 스크립트로 해결합니다.

> **한국어**  
> 조직의 다른 계정이 이미 이 장치에 로그인되어 있습니다. 다른 계정으로 다시 시도하세요.

> **English**  
> Another account from your organization is already signed in on this device. Try again with a different account.

## 원인

- Windows Credential Manager 또는 macOS Keychain에 만료·충돌된 계정 토큰이 남아 있음
- WAM(Web Account Manager) 또는 MSAL/ADAL 캐시 충돌
- 동일 기기에 여러 조직 계정이 혼재

---

## Windows 사용법

### 방법 1: 더블클릭 실행 (권장)

1. `windows/Fix-OrgAccountError.bat` 파일을 **우클릭 → 관리자 권한으로 실행**

### 방법 2: PowerShell 직접 실행

```powershell
# PowerShell을 관리자 권한으로 열고 실행:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\windows\Fix-OrgAccountError.ps1
```

### Windows 스크립트가 하는 작업

| 단계 | 내용 |
|------|------|
| 1 | Office / Teams / OneDrive 프로세스 종료 |
| 2 | Windows Credential Manager에서 Microsoft 자격증명 삭제 |
| 3 | WAM(Web Account Manager) 토큰 캐시 초기화 |
| 4 | 레지스트리 Office Identity 캐시 삭제 |
| 5 | Office / Teams / OneDrive 로컬 캐시 폴더 정리 |
| 6 | 관련 Windows 서비스 재시작 |

---

## macOS 사용법

```bash
# 터미널에서 실행
chmod +x macos/Fix-OrgAccountError-Mac.sh
./macos/Fix-OrgAccountError-Mac.sh
```

### macOS 스크립트가 하는 작업

| 단계 | 내용 |
|------|------|
| 1 | Office / Teams / OneDrive 프로세스 종료 |
| 2 | Keychain에서 Microsoft 관련 항목 삭제 |
| 3 | MSAL / ADAL 토큰 캐시 삭제 |
| 4 | Teams / Office / OneDrive 캐시 폴더 정리 |
| 5 | DNS 캐시 플러시 |

---

## 실행 후 조치

1. PC/Mac 재시작 (권장)
2. Office 앱 실행 후 **사용할 계정으로 새로 로그인**
3. 문제가 지속되면 [Microsoft 계정 포털](https://myaccount.microsoft.com)에서 기기 등록 해제 후 재시도

## 주의사항

- 스크립트 실행 후 저장하지 않은 Office 작업은 **손실될 수 있습니다** — 먼저 저장하세요
- 회사 관리형 기기(Intune/MDM)의 경우 IT 관리자에게 문의하세요
- 스크립트는 파일을 삭제하지 않으며, 인증 캐시·토큰만 정리합니다
