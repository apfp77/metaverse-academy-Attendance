# JSON 파일 경로
$scriptPath = $PSScriptRoot
$jsonFile = Join-Path $scriptPath "response.json"


# JSON 파일을 읽어서 객체로 변환
$jsonData = Get-Content $jsonFile | ConvertFrom-Json


$scriptPath = $PSScriptRoot
$OutputEncoding = [ System.Text.Encoding]::UTF8   

# 각 항목을 반복 처리
foreach ($item in $jsonData) {
    $attendStart = $item.attendStart
    $attendEnd = $item.attendEnd
    
		$20spaces = ' ' * 20
		$startFormat = "{0,-20}"  # 입실 시간을 20자리에 맞춤
    $endFormat = "{0,-20}"    # 퇴실 시간을 20자리에 맞춤
    if ($attendStart -and $attendEnd) {
        Write-Host "입실: $attendStart " -ForegroundColor Cyan -NoNewline
        Write-Host "퇴실: $attendEnd" -ForegroundColor Red
    } elseif ($attendStart) {
        Write-Host "입실: $attendStart " -ForegroundColor Cyan -NoNewline
        Write-Host "퇴실: $20spaces" -ForegroundColor Red
    } elseif ($attendEnd) {
        Write-Host "입실: $20spaces" -ForegroundColor Cyan -NoNewline
        Write-Host "퇴실: $attendEnd" -ForegroundColor Red
    } else {
        Write-Host "입실: $20spaces" -ForegroundColor Cyan -NoNewline
        Write-Host "퇴실:" -ForegroundColor Red
    }
}
