# 메타버스 아카데미 출결 확인

### 파일 설명

1. userinfo.txt

- 회원의 아이디와 비밀번호를 관리하는 파일입니다
- passwd 설정 시 `!`가 포함된다면 앞에 ^를 작성해주세요
  - (example) test!test -> test^!test
  - (example) test!!!test -> test^!^!^!test

2. cccd.ps1

- cccd.json에서 가장 최근 교육을 추출합니다

3. parse.ps1

- 생성되는 response.json을 기반으로 입실과 퇴실을 출력합니다

4. execution.bat

- 파일들의 흐름을 제어합니다
