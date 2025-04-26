const express = require('express');//1
const router = express.Router();
const controller = require('./party.controller');

router.get('/', controller.party);

router.get('/getparty', controller.getparty);

router.post('/makeparty', controller.makeparty);

router.post('/joinparty', controller.joinparty);

router.post('/partydeadline', controller.partydeadline);

router.get('/getpartypeople', controller.getpartypeople);
router.post('/getpartypeopleprofile', controller.getpartypeopleprofile);

router.get('/getuserinfo', controller.getuserinfo);

module.exports = router;

