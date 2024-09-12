#!/bin/zsh

# 스크립트 디렉토리 설정
SCRIPT_DIR="${0:A:h}"

# 사용자 정보 파일 읽기
source "${SCRIPT_DIR}/userinfo.txt"

# 쿠키 파일 경로
COOKIE_FILE="${SCRIPT_DIR}/cookies.txt"

# JSON 응답 파일 경로
RESPONSE_FILE="${SCRIPT_DIR}/response.json"
MILEAGE_FILE="${SCRIPT_DIR}/total_mileage.json"
CCCD_FILE="${SCRIPT_DIR}/cccd.json"

# 날짜 형식 설정
DATE_FORMAT="%Y-%m-%d %H:%M:%S"

# 출석 시간 설정
DAY_START="09:30:01"
DAY_END="18:29:59"

# 출석 상태 초기화
ATTENDANCE=0
TARDINESS=0
EARLY_DEPARTURE=0
ABSENCE=0

# 로그인 및 데이터 가져오기
curl -s -c "$COOKIE_FILE" -X GET "https://mtvs.kr"
curl -b "$COOKIE_FILE" -s -X POST "https://mtvs.kr/login" -H "Content-Type: application/x-www-form-urlencoded" -d "userId=$userId&passwd=$passwd" -c "$COOKIE_FILE"
curl -b "$COOKIE_FILE" -s -o "$MILEAGE_FILE" -X GET "https://mtvs.kr/student/mypage/totalMileage"
curl -b "$COOKIE_FILE" -s -o "$CCCD_FILE" -X GET "https://mtvs.kr/student/mypage/curriculum"

# ccCd 추출
ccCd=$(jq -r '.requireReportList[0].ccCd' "$CCCD_FILE")

# 출석 데이터 가져오기
curl -b "$COOKIE_FILE" -s -o "$RESPONSE_FILE" -X GET "https://mtvs.kr/student/offline/attend?ccCd=$ccCd"

# JSON 파싱 및 출석 처리
jq -c '.[]' "$RESPONSE_FILE" | while read -r item; do
    attendStart=$(echo "$item" | jq -r '.attendStart')
    attendEnd=$(echo "$item" | jq -r '.attendEnd')
    
    if [[ "$attendStart" != "null" && "$attendEnd" != "null" ]]; then
        start=$(date -j -f "$DATE_FORMAT" "$attendStart" "+%H:%M:%S" 2>/dev/null)
        end=$(date -j -f "$DATE_FORMAT" "$attendEnd" "+%H:%M:%S" 2>/dev/null)
        
        if [[ -n "$start" && -n "$end" ]]; then
            if [[ "$start" < "$DAY_START" && "$DAY_END" < "$end" ]]; then
                ((ATTENDANCE++))
            elif [[ "$DAY_START" < "$start" ]]; then
                if [[ "$DAY_END" < "$end" ]]; then
                    ((TARDINESS++))
                else
                    ((EARLY_DEPARTURE++))
                fi
            elif [[ "$end" < "$DAY_END" ]]; then
                ((EARLY_DEPARTURE++))
            fi
        else
            ((ABSENCE++))
        fi
    elif [[ "$attendStart" != "null" ]]; then
        start_date=$(date -j -f "$DATE_FORMAT" "$attendStart" "+%Y-%m-%d" 2>/dev/null)
        if [[ -n "$start_date" && "$start_date" != $(date "+%Y-%m-%d") ]]; then
            ((ABSENCE++))
        fi
    else
        ((ABSENCE++))
    fi
done

# 결과 출력
jq -c '.[]' "$RESPONSE_FILE" | while read -r item; do
    attendStart=$(echo "$item" | jq -r '.attendStart')
    attendEnd=$(echo "$item" | jq -r '.attendEnd')
    
    if [[ "$attendStart" != "null" && "$attendEnd" != "null" ]]; then
        printf "\033[36m입실: %s \033[0m" "$attendStart"
        start=$(date -j -f "$DATE_FORMAT" "$attendStart" "+%H:%M:%S" 2>/dev/null)
        end=$(date -j -f "$DATE_FORMAT" "$attendEnd" "+%H:%M:%S" 2>/dev/null)
        if [[ -n "$start" && -n "$end" && "$start" < "$DAY_START" && "$DAY_END" < "$end" ]]; then
            printf "\033[31m퇴실: %s\033[0m \033[32m✅\033[0m\n" "$attendEnd"
        else
            printf "\033[31m퇴실: %s\033[0m\n" "$attendEnd"
        fi
    elif [[ "$attendStart" != "null" ]]; then
        printf "\033[36m입실: %s \033[0m\033[31m퇴실: %20s\033[0m\n" "$attendStart" "-"
    elif [[ "$attendEnd" != "null" ]]; then
        printf "\033[36m입실: %20s \033[0m\033[31m퇴실: %s\033[0m\n" "-" "$attendEnd"
    else
        printf "\033[36m입실: %20s \033[0m\033[31m퇴실: %20s\033[0m\n" "-" "-"
    fi
done

echo
printf "\033[36m출석: %d, \033[0m" $ATTENDANCE
printf "\033[31m지각: %d, \033[0m" $TARDINESS
printf "\033[35m조퇴: %d, \033[0m" $EARLY_DEPARTURE
printf "\033[31m결석: %d\033[0m\n" $ABSENCE

echo -n "예상 지원금: "
sum=$((ATTENDANCE * 5 + ((TARDINESS + EARLY_DEPARTURE) * 5 - ((TARDINESS + EARLY_DEPARTURE) / 3 * 5))))
if (( sum > 100 )); then
    sum=100
fi
printf "\033[32m%d 만원\033[0m\n" $sum

echo
printf "\033[32m마이페이지 마일리지: %s\033[0m\n" "$(cat "$MILEAGE_FILE")"
echo
echo "\033[33m방학, 대체공휴일, 최대 출석일 수, 결석 등의 이유로 정확하지 않을 수 있습니다. 마일리지와 금액을 비교해 주세요.\033[0m"
