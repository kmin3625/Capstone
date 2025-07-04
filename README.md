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

<img src="https://github.com/user-attachments/assets/b6f48615-e5ec-40c5-b4ff-2a39ba7806c1" width="600" height="200"/>

### 유저 플로우차트

<img src="https://github.com/user-attachments/assets/d7daa897-1a28-4867-871b-6921fc0c7328" width="500" height="500"/>

### 화면 구조 설계

<img src="https://github.com/user-attachments/assets/e3f4d466-45ea-46b2-a85c-ffb39cf8c08b" width="500" height="300"/>

### 메뉴 구조 설계

<img src="https://github.com/user-attachments/assets/1dc4b7ab-2ad4-4f69-ae2c-2afb42f0ab51" width="250" height="500"/>

### DB 설계

<img src="https://github.com/user-attachments/assets/e0ab0ebf-16d7-4316-b9c7-d16d6fbcad1b" width="400" height="800"/>

### API 명세서
- /user

<img src="https://github.com/user-attachments/assets/c0f616a6-638a-4da2-b9bd-a193d584d0ac" width="1100" height="700"/>

- /party

<img src="https://github.com/user-attachments/assets/4aab4a17-835d-440e-8da4-3ae4237fc058" width="1100" height="400"/>

- /chat

<img src="https://github.com/user-attachments/assets/40fd0c96-c0ac-44d3-bb7e-2780fda982e8" width="1100" height="450"/>

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
<video src="https://github.com/user-attachments/assets/87066004-e0cc-45dc-b5d1-d6d12dfd8d69" controls width="600"></video>

## 7. 앱 다운로드 링크
<img src="https://github.com/user-attachments/assets/4b3a630e-f5b4-4e50-b8a2-d8f6b856a5de" width="400" height="400"/>

- QR 코드를 통해 앱을 사용해보세요.(한남대 학교 이메일 인증을 통해 사용 가능합니다.)
- test 계정
  1. ID: 20191111 PW: 123456
  2. ID: 20192222 PW: 123456
