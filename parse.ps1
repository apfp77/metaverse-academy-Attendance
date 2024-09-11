# JSON 파일 경로
$scriptPath = $PSScriptRoot
$jsonFile = Join-Path $scriptPath "response.json"


# JSON 파일을 읽어서 객체로 변환
$jsonData = Get-Content $jsonFile | ConvertFrom-Json


$scriptPath = $PSScriptRoot
$OutputEncoding = [ System.Text.Encoding]::UTF8 

$dateFormat = "yyyy-MM-dd HH:mm:ss"
$20spaces = ' ' * 20

$dayStart = [TimeSpan]::Parse("09:30:01")
$dayEnd = [TimeSpan]::Parse("18:29:59")

# 출석
$Attendance=0
# 지각: 
$Tardiness=0
#조퇴: 
$EarlyDeparture=0
#결석: 
$Absence=0

# 출결 처리
foreach ($item in $jsonData) {
    $attendStart = $item.attendStart
    $attendEnd = $item.attendEnd
    
    if ($attendStart -and $attendEnd) {
        $start = [DateTime]::ParseExact($attendStart, $dateFormat, $null).TimeOfDay
        $end = [DateTime]::ParseExact($attendEnd, $dateFormat, $null).TimeOfDay

        if ($start -lt $dayStart -and $dayEnd -lt $end){
            ++$Attendance
        }elseif ($dayStart -lt $start){
            if ($dayEnd -lt $end){
                ++$Tardiness
            }else{
                ++$EarlyDeparture
            }
        }elseif ($end -lt $dayEnd){
            ++$EarlyDeparture
        }
    } elseif ($attendStart) {
        if ((Get-Date).ToShortDateString() -ne ([DateTime]::ParseExact($attendStart, $dateFormat, $null)).ToShortDateString()){
            $Absence++;
        }
    }else {
        $Absence++
    }
}

# 출력 처리
foreach ($item in $jsonData) {
    $attendStart = $item.attendStart
    $attendEnd = $item.attendEnd
    

    if ($attendStart -and $attendEnd) {
        Write-Host "입실: $attendStart " -ForegroundColor Cyan -NoNewline
        $start = [DateTime]::ParseExact($attendStart, $dateFormat, $null).TimeOfDay
        $end = [DateTime]::ParseExact($attendEnd, $dateFormat, $null).TimeOfDay
        if ($start -lt $dayStart -and $dayEnd -lt $end){
            Write-Host "퇴실: $attendEnd" -ForegroundColor Red -NoNewline
            Write-Host " ✅" -ForegroundColor Green
        } else{
            Write-Host "퇴실: $attendEnd" -ForegroundColor Red
        }
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
Write-Host
Write-Host "출석: $Attendance, " -ForegroundColor Cyan -NoNewline
Write-Host "지각: $Tardiness, " -ForegroundColor DarkRed -NoNewline
Write-Host "조퇴: $EarlyDeparture, " -ForegroundColor DarkMagenta -NoNewline
Write-Host "결석: $Absence" -ForegroundColor Red

Write-Host "예상 지원금: " -NoNewline
$sum = $Attendance * 5 + (($Tardiness + $EarlyDeparture) * 5 - ([math]::Floor(($Tardiness + $EarlyDeparture) / 3) * 5))
if (100 -lt $sum){
    $sum = 100
}
Write-Host "$sum 만원"  -ForegroundColor Green
Write-Host
Write-Host "방학, 대체공휴일, 최대 출석일 수, 결석 등의 이유로 정확하지 않을 수 있습니다." -ForegroundColor Yellow
