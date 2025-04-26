const express = require('express');
const router = express.Router();
const user = require('./user/index');
const party = require('./party/index');
const chat = require('./chat/index');


router.use('/user', user);
router.use('/party', party);
router.use('/chat', chat);

module.exports = router;

