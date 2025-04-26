const express = require('express');
const router = express.Router();
const controller = require('./user.controller');

router.post('/signup', controller.signup);
router.get('/uid', controller.uid);

// 사용자 정보 저장 엔드포인트
router.post('/saveusername', controller.saveUserName);

router.post('/saveuserage', controller.saveUserAge);

router.post('/saveusergender', controller.saveUserGender);

router.post('/saveuserintro', controller.saveUserIntro);

router.post('/uploadprofile', controller.uploadImageToServer);

router.post('/getprofile', controller.getImageFromServer);

router.post('/saveusermajor', controller.saveUserMajor);

router.post('/withdraw', controller.withdraw);
// 사용자 정보 가져오는 엔드포인트
router.post('/userinfo', controller.getUserInfo);

router.post('/updatenotistate', controller.updateNotiState);//사용자 알림상태

router.get('/getnotistate', controller.getNotiState); // GET 요청으로 변경

router.post('/logouttoken', controller.logoutToken); // POST 요청으로 변경

router.get('/getallnotices', controller.getAllNotices);

router.get('/', controller.user);

module.exports = router; //테스트
