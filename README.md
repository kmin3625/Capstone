# 목차
[<u>0. 목표</u>](https://github.com/kmin3625/Capstone#0-%EB%AA%A9%ED%91%9C)

[<u>1. 개요 </u>](https://github.com/kmin3625/Capstone#1-%EA%B0%9C%EC%9A%94)

[<u>2. 팀 소개</u>](https://github.com/kmin3625/Capstone/tree/main#2-%ED%8C%80-%EC%86%8C%EA%B0%9C)

[<u>3. 개발환경</u>](https://github.com/kmin3625/Capstone/tree/main#3-%EA%B0%9C%EB%B0%9C%ED%99%98%EA%B2%BD)

[<u>4. 설계</u>](https://github.com/kmin3625/Capstone/tree/main#4-%EC%84%A4%EA%B3%84)

[<u>5. 주요 기능</u>](https://github.com/kmin3625/Capstone/tree/main#5-%EC%A3%BC%EC%9A%94-%EA%B8%B0%EB%8A%A5)

[<u>6. 앱 실행 영상</u>](https://github.com/kmin3625/Capstone/tree/main#6-%EC%95%B1-%EC%8B%A4%ED%96%89-%EC%98%81%EC%83%81)

[<u>7. 앱 다운로드 링크</u>](https://github.com/kmin3625/Capstone/tree/main#7-%EC%95%B1-%EB%8B%A4%EC%9A%B4%EB%A1%9C%EB%93%9C-%EB%A7%81%ED%81%AC)

## 0. 목표
### 2024년 캡스톤 디자인 과목 수강 및 교내 공학경진대회 참여

(기간: 2024.03.04 - 2024.06.10)

## 1. 개요
### 주제: 학교 지도 기반 소모임 매칭 SNS
- 학교 이메일 인증으로 회원가입 후 로그인이 가능함.
- 학교 지도를 메인화면에 출력하고 지도 위에 모집글 게시판으로 지정한 건물이나 지역을 마커로 표시함. 
- 마커를 터치했을 때 해당 지역의 모집글 게시판으로 연결되며 실시간 소모임 생성 및 가입이 가능함. 
- 소모임을 만들거나 가입했을 경우 채팅 기능을 통해 사용자가 구성원들과의 의사소통과 만남을 가능하게 함.

## 2. 팀 소개 
**팀명**: 파티구함
 
**팀원**: 이규민(팀장), 김종윤, 이민우, 전태민, 심훈
## 3. 개발환경
**프론트엔드 : Flutter(Dart)**

**백엔드: Node-JS(Express)**

**데이터베이스: MySQL**

**서버(백엔드 및 데이터베이스 서버): Oracle Cloud(Ubuntu)**

**개발 도구: Intellij, VSCode, DataGrip, PostMan**

**외부  API 및 기술:  Google Maps Plattform API, Firebase**

 ## 4. 설계
### 간트차트

<img src="https://github.com/user-attachments/assets/5f90ffd0-1db3-474d-932a-ab8a88202d26" width="600" height="200"/>

### 유저 플로우차트

<img src="https://github.com/user-attachments/assets/6cc3e678-7350-4915-b140-e47724035a0f" width="500" height="500"/>

### 화면 구조 설계

<img src="https://github.com/user-attachments/assets/fa0f2a99-a2ed-428c-8bcd-f4bdf9787b3c" width="500" height="300"/>

### 메뉴 구조 설계

<img src="https://github.com/user-attachments/assets/2b7bf5fa-1db2-4d59-8f12-d34c0b259225" width="250" height="500"/>

### DB 설계

<img src="https://github.com/user-attachments/assets/58db94ce-ab48-43a5-8ded-54b088866c20" width="400" height="800"/>

### API 명세서
- /user

<img src="https://github.com/user-attachments/assets/ce61c994-cc89-482d-8feb-b2ef9d3e4259" width="1100" height="700"/>

- /party

<img src="https://github.com/user-attachments/assets/3ae91f00-b06e-42f6-81fa-237657d2b00a" width="1100" height="400"/>

- /chat

<img src="https://github.com/user-attachments/assets/61d21699-bd7c-4df8-b34f-952b77e7d6ec" width="1100" height="450"/>

## 5. 주요 기능

### 회원관리
- 회원가입
- 로그인(자동 로그인), 로그아웃
- 이메일 인증을 통한 개인정보 변경
- 사용자 프로필 입력 및 출력
### 메인 화면
- 오정 캠퍼스, 대덕 캠퍼스 지도 출력
- 지도 위에 특정 지역 마커 표시, 마커 터치 시 해당 지역의 모집글 게시판으로 이동
- 자신의 현재 위치 표기
### 소모임 모집글 게시판
- 소모임 모집글 등록 및 가입
- 모집 마감 및 마감시 알람
- 식사, 놀이, 도움 3가지 카테고리로 모집글 분류
### 채팅
- 채팅방 목록
- 실시간 채팅(Socket.IO로 구현)
- 채팅 알람
- 채팅방 비매너 유저 신고
### 환경설정
- 계정 설정(비밀번호 변경, 다크 모드 설정)
- 알림 설정(모집 마감 알람 설정, 채팅 알람 설정)
- 고객센터(문의하기, 자주하는 질문, 공지사항)

## 6. 앱 실행 영상
<video src="https://github.com/user-attachments/assets/d6a8a1e8-dac2-4a73-b37f-6624b2dc5f48" controls width="600"></video>

## 7. 앱 다운로드 링크
<img src="https://github.com/user-attachments/assets/26a6ee9d-4e70-4677-bf33-008717987fe3" width="400" height="400"/>

<s>QR 코드를 통해 앱을 사용해보세요.</s>

현재 서버를 운용하지 않아 앱을 사용할수 없습니다.
