const socketIo = require('socket.io');
const db = require('../db'); // DB 연결
const moment = require('moment-timezone'); // moment-timezone 라이브러리 추가
const Notification = require('../../routes/notification/notification.controller');

module.exports = function(server) {
  const io = socketIo(server, {
    cors: {
      origin: '*', // 모든 출처에서의 요청을 허용합니다. 필요에 따라 특정 출처로 변경할 수 있습니다.
      methods: ['GET', 'POST'],
      allowedHeaders: ['Content-Type'],
    },
    pingInterval: 10000, // 10초마다 ping 메시지 전송
    pingTimeout: 5000, // 5초 동안 응답이 없으면 타임아웃 처리
  });

  io.on('connection', (socket) => {
    console.log('a user connected');

    socket.on('join room', (room) => {
      socket.join(room);
      console.log(`user joined room: ${room}`);
    });

    socket.on('leave room', (room) => {
      socket.leave(room);
      console.log(`user left room: ${room}`);
    });

    socket.on('chat message', (msg) => {
      const { ChatID, studentID, joinID, chatData, nickName } = msg;
      const currentTime = moment().tz('Asia/Seoul').format('YYYY-MM-DD HH:mm:ss'); // 현재 시간을 한국 시간으로 변환

      const query = 'INSERT INTO Chatting (JoinID, ChatData, ChatTime, ChatID, NickName) VALUES (?, ?, ?, ?, ?)';
      
      db.query(query, [joinID, chatData, currentTime, ChatID, nickName], (err, result) => {
        if (err) {
          console.error(err);
          socket.emit('error', 'Failed to send message');
        } else {
          io.in(ChatID).emit('chat message', {
            ChatID,
            sender: nickName,
            content: chatData,
            time: currentTime // 한국 시간으로 변환된 시간 전송
          });
          io.emit('refresh chat rooms'); // 채팅방 목록을 업데이트하는 이벤트 발생
          Notification.sendChatNotification(ChatID)
        }
      });
    });

    socket.on('disconnect', () => {
      console.log('user disconnected');
    });
  });
};
