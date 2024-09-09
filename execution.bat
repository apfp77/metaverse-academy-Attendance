@echo off

set "BASE_DIR=%~dp0"

setlocal enabledelayedexpansion

for /f "tokens=1* delims==" %%A in (%BASE_DIR%userinfo.txt) do (
    set "key=%%A"
    set "value=%%B"

		if "!key!"=="userId" set "userId=!value!"
    if "!key!"=="passwd" set "passwd=!value!"
)

echo.

curl -s -c %BASE_DIR%cookies.txt -X GET "https://mtvs.kr"

curl -b %BASE_DIR%cookies.txt -s -X POST "https://mtvs.kr/login" -H "Content-Type: application/x-www-form-urlencoded" -d "userId=!userId!&passwd=!passwd!" -c %BASE_DIR%cookies.txt

echo.

curl -b %BASE_DIR%cookies.txt -s -o %BASE_DIR%cccd.json -X GET "https://mtvs.kr/student/mypage/curriculum"

powershell -ExecutionPolicy RemoteSigned -File %BASE_DIR%cccd.ps1

for /f "delims=" %%i in ('powershell -command "Get-Content -Path ccCdResult.txt -Raw -Encoding UTF8"') do set ccCd=%%i

curl -b %BASE_DIR%cookies.txt -s -o %BASE_DIR%response.json -X GET "https://mtvs.kr/student/offline/attend?ccCd=!ccCd!"


powershell -ExecutionPolicy RemoteSigned -File %BASE_DIR%parse.ps1

endlocal

pause