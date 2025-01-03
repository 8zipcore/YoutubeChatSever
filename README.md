## 🛠️ 개발 환경
- Vapor / Xcode 15.2 / Render
- PostgreSQL / DBeaver / Render / Supabase Storage

## 🗂️ DB Table 설계

### User

- 사용자 테이블

| 컬럼명 | 데이터 타입 | 설명|
|-------|-------|-------|
id | UUID |사용자 고유 ID
name | String | 사용자 이름
description | String | 사용자 상태메세지
image | String | 사용자 프로필 이미지 URL
background_image | String | 사용자 배경 이미지 URL

### ChatRoom
- 채팅방 테이블

| 컬럼명 | 데이터 타입 | 설명 |
|-------|-------|-------|
id | UUID | 채팅방 고유 ID
description | String | 채팅방 설명
image | String | 채팅방 이미지 URL
enter_code | String | 채팅방 비밀번호
host_id | UUID | 채팅방 host ID
participant_ids | [UUID] | 채팅방 참가자 ID 목록
enter_times | [String:Double] | ID별 채팅방 참가 시간
all_participant_ids | [UUID] | 채팅방에 참여했던 모든 참가자 ID 목록
chat_options | [Int] | 채팅방 옵션
categories | [String] | 채팅방 관련 해시태그
last_chat_time | Double | 마지막 채팅 시간

### ChatRoomMessage
- 채팅방 메세지 테이블

| 컬럼명 | 데이터 타입 | 설명 |
|-------|-------|-------|
id | UUID | 메세지 고유 ID
chatroom_id | UUID | 채팅방 ID
sender_id | UUID | 발신자 ID
type | Int | 채팅 타입
text | String | 채팅 메세지
timestamp | Double | 채팅 발신 시간

### ChatRoomYoutube

- 채팅방 유튜브 테이블
- 테이블명은 ChatRoomID_youtube로 설정.

| 컬럼명 | 데이터 타입 | 설명 |
|-------|-------|-------|
id | UUID | 동영상 고유 ID
youtube_id | String | 유튜브 동영상 ID
user_id | String | 발신자 ID
title | String | 동영상 제목
uploader | String | 동영상 업로더 이름
thumbnail | String | 썸네일 URL
duration | Double | 동영상 재생 시간
start_time | Double | 동영상 시작 시간
end_time | Double | 동영상 종료 시간
upload_time | Double | 동영상 추가 시간

### Category
- 해시태그 테이블

| 컬럼명 | 데이터 타입 | 설명 |
|-------|-------|-------|
id | UUID | 카테고리 고유 ID
name | String | 카테고리 이름
count | Int | 카테고리 추가 횟수
chat_room_ids | [UUID] | 해당 카테고리 추가한 채팅방 ID 목록

