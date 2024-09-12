# JSON 파일 경로
$scriptPath = $PSScriptRoot

$jsonFile = Join-Path $scriptPath "cccd.json"

# JSON 파일을 읽어서 객체로 변환
$content = Get-Content -Encoding utf8 $jsonFile
$jsonData = $content | ConvertFrom-Json

# 첫 번째 항목의 ccCd 값을 추출
$firstCcCd = $jsonData.requireReportList[0].ccCd

# 값을 텍스트 파일로 저장 (bat 파일로 반환하기 위해)
$firstCcCd | Out-File "ccCdResult.txt"