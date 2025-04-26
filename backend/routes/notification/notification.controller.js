const db = require('../../server/db');
const admin = require('firebase-admin');
const serviceAccount = require('../../server/capstone_admin_apk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// 파티 마감시 알림을 보내는 함수
const sendClosingNotification = (partyID) => {
  const fcmQuery = `
        SELECT pp.StudentID, u.Token, p.PartyTitle
        FROM Party_People pp
        INNER JOIN User u ON pp.StudentID = u.StudentID
        INNER JOIN Party p ON pp.PartyID = p.PartyID
        WHERE pp.PartyID = ?
          AND pp.ChatState = 1
          AND u.NotiState IN (0, 2);
    `;
  db.query(fcmQuery, [partyID], (error, results) => {
    if (error) {
      console.error('Error getting user tokens:', error);
      return;
    }
    if (results.length === 0) {
      console.log('No users found for partyID:', partyID);
      return;
    }

    console.log('Users found for partyID:', partyID, results);

    results.forEach((row) => {
      const { StudentID, Token, PartyTitle } = row;
      if (Token) {
        sendPushNotification(Token, PartyTitle, '파티가 마감되었습니다.', partyID);
      }
    });
  });
};

// FCM 알림을 보내는 함수
const sendChatNotification = (chatID) => {
  const getJoinIdQuery = `
        SELECT JoinID
        FROM Chatting
        WHERE ChatID = ?
        ORDER BY ChatTime DESC
        LIMIT 1;
  `;

  db.query(getJoinIdQuery, [chatID], (error, results) => {
    if (error) {
      console.error('Error getting JoinID:', error);
      return;
    }

    if (results.length === 0) {
      console.log('No JoinID found for chatID:', chatID);
      return;
    }

    const joinID = results[0].JoinID;

    console.log('JoinID found for chatID:', chatID, joinID);

    const getPartyIdQuery = `
            SELECT PartyID
            FROM Party_People
            WHERE JoinID = ?;
    `;

    db.query(getPartyIdQuery, [joinID], (error, results) => {
      if (error) {
        console.error('Error getting PartyID:', error);
        return;
      }

      if (results.length === 0) {
        console.log('No PartyID found for JoinID:', joinID);
        return;
      }

      const partyID = results[0].PartyID;

      console.log('PartyID found for JoinID:', joinID, partyID);

      const getLatestChatQuery = `
                SELECT NickName, ChatData
                FROM Chatting
                WHERE ChatID = ?
                ORDER BY ChatTime DESC
                LIMIT 1;
      `;

      db.query(getLatestChatQuery, [chatID], (error, chatResults) => {
        if (error) {
          console.error('Error getting latest chat:', error);
          return;
        }

        if (chatResults.length === 0) {
          console.log('No chat data found for chatID:', chatID);
          return;
        }

        const { NickName, ChatData } = chatResults[0];

        const getUserTokensQuery = `
                    SELECT u.Token
                    FROM Party_People pp
                    INNER JOIN User u ON pp.StudentID = u.StudentID
                    WHERE pp.PartyID = ?
                      AND pp.ChatState = 1
                      AND u.NotiState IN (0, 1);
        `;

        db.query(getUserTokensQuery, [partyID], (error, userResults) => {
          if (error) {
            console.error('Error getting user tokens:', error);
            return;
          }

          if (userResults.length === 0) {
            console.log('No users found for PartyID:', partyID);
            return;
          }

          console.log('Users found for PartyID:', partyID, userResults);

          userResults.forEach((row) => {
            const { Token } = row;
            if (Token) {
              sendPushNotification(Token, NickName, ChatData, partyID);
            }
          });
        });
      });
    });
  });
};

// FCM 알림을 보내는 함수
const sendPushNotification = (token, title, body, partyID) => {
  const message = {
    notification: {
      title: title,
      body: body
    },
    data: {
      partyID: partyID.toString() // partyID를 data에 포함시킴
    },
    token: token
  };

  admin.messaging().send(message)
    .then((response) => {
      console.log('Successfully sent message:', response);
    })
    .catch((error) => {
      console.log('Error sending message:', error);
    });
};

module.exports = {
  sendClosingNotification, sendChatNotification
};
