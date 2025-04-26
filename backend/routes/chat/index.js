const express = require('express');
const router = express.Router();
const controller = require('./chat.controller');

// 채팅방 화면에 보여주기
router.get('/getChatList', controller.getChatList);

// 채팅방에 참여한 사람들 정보 보이기
router.get('/participants/:partyID', controller.getParticipants);

// 채팅방에서 대화 불러오기
router.get('/getMessage', controller.getMessage);

// 채팅방 대화 보내기
router.post('/sendMessage', controller.sendMessage);

// 채팅방 참가자의 상세 정보 보이기
router.get('/participantdetail/:partyID/:nickname', controller.getParticipantDetails);

// 채팅방 지우기
router.post('/deletechat', controller.deletechat);

// 채팅방 참가자의 JoinID 가져오기
router.get('/getJoinID', controller.getJoinID);

// 해당 학생의 NickName 가져오기
router.get('/getNickName', controller.getNickName);

// 해당 참가자 프로필 가져오기
router.post('/getchatpeopleprofile', controller.getchatpeopleprofile);

// 신고 시 정보 데이터베이스로 보내기
router.post('/reportChat', controller.reportChat);

module.exports = router;