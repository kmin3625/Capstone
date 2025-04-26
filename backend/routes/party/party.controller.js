const db = require('../../server/db');
const Notification = require('../notification/notification.controller.js');

exports.party = (req, res) => {
    db.query('SELECT * FROM Party', function (err, rows, fields) {
      if (!err) {
        res.send(rows); // response send rows
      } else {
        console.log('err : ' + err);
        res.send(err); // response send err
      }
    }); 
  }

  exports.getparty = (req, res) => {
    const BuildNum = req.query.BuildNum;
    // PartyState가 1인 경우만 조회
    const query = 'SELECT * FROM Party WHERE BuildNum = ? AND PartyState = 1';

    db.query(query, [BuildNum], (error, results, fields) => {
      if (error) {
        console.log(error);
        res.status(500).send('Internal Server Error');
      } else {
        res.status(200).json(results);
      }
    });
}

exports.makeparty = (req, res) => {
  const { PartyCa, EndTime, PartyTitle, PartyContent, People, BuildNum, StudentID, NickName } = req.body;
  const startTime = new Date();

  const query1 = `INSERT INTO Party (PartyCa, EndTime, PartyTitle, PartyContent, People, StartTime, BuildNum, CurPeople, PartyState) VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1)`;

  if (new Date(EndTime) > startTime && People > 0) {
    db.query(query1, [PartyCa, EndTime, PartyTitle, PartyContent, People, startTime, BuildNum], (err, result) => {
      if (err) {
        res.status(500).send('Database error: ' + err);
        return;
      }

      const partyID = result.insertId;

      const query2 = `INSERT INTO Party_People (PartyID, StudentID, NickName, Permission, ChatState) VALUES (?, ?, ?, 1, 1)`;
      db.query(query2, [partyID, StudentID, NickName], (err, result) => {
        if (err) {
          res.status(500).send('Database error: ' + err);
          return;
        }
        res.send('Post created successfully with ID: ' + partyID);
      });
    });
  } else {
    res.status(400).send('Invalid EndTime or People');
  }
}

exports.joinparty = (req, res) => {
  const { PartyID, StudentID, NickName } = req.body;

  // 먼저 해당 PartyID에 동일한 StudentID와 NickName의 조합이 존재하는지 확인
  const sqlCheckExists = `
      SELECT * FROM Party_People WHERE PartyID = ? AND StudentID = ? AND NickName = ?;
  `;
  db.query(sqlCheckExists, [PartyID, StudentID, NickName], (err, checkResults) => {
      if (err) {
          res.status(500).send('Database error on checking party member: ' + err);
          return;
      }
      if (checkResults.length > 0) {
          res.status(409).send('Member with this StudentID and NickName already exists in the party.');
          return;
      }

      // Party 테이블에서 CurPeople과 People 값을 조회
      const sqlSelect = `
          SELECT CurPeople, People FROM Party WHERE PartyID = ?;
      `;
      db.query(sqlSelect, [PartyID], (err, results) => {
          if (err) {
              res.status(500).send('Database error on party retrieval: ' + err);
              return;
          }
          if (results.length === 0) {
              res.status(404).send('Party not found');
              return;
          }

          const { CurPeople, People } = results[0];

          // 현재 인원이 최대 인원에 도달한 경우
          if (CurPeople >= People) {
              const sqlUpdateState = `
                  UPDATE Party
                  SET PartyState = 0
                  WHERE PartyID = ?;
              `;
              db.query(sqlUpdateState, [PartyID], (err, result) => {
                  if (err) {
                      res.status(500).send('Error updating party state: ' + err);
                      return;
                  }
                  res.status(400).send('모집이 마감되었습니다.');
              });
              return;
          }

          // Party_People 테이블에 데이터 추가
          const sqlInsert = `
              INSERT INTO Party_People (PartyID, StudentID, NickName, Permission, ChatState)
              VALUES (?, ?, ?, 0, 1);
          `;
          db.query(sqlInsert, [PartyID, StudentID, NickName], (err, result) => {
              if (err) {
                  res.status(500).send('Error adding user to party: ' + err);
                  return;
              }

              // Party 테이블의 CurPeople 업데이트
              const sqlUpdate = `
                  UPDATE Party
                  SET CurPeople = CurPeople + 1
                  WHERE PartyID = ?;
              `;
              db.query(sqlUpdate, [PartyID], (err, result) => {
                  if (err) {
                      res.status(500).send('Error updating party count: ' + err);
                      return;
                  }

                  // 만약 마지막 참가자라면 PartyState를 0으로 변경
                  if (CurPeople + 1 === People) {
                      const sqlUpdateState = `
                          UPDATE Party
                          SET PartyState = 0
                          WHERE PartyID = ?;
                      `;
                      db.query(sqlUpdateState, [PartyID], (err, result) => {
                          if (err) {
                              res.status(500).send('Error updating party state: ' + err);
                              return;
                          }
                          // 파티 모집이 마감되면 해당 파티에 참가한 사용자들에게 FCM 알림을 보냅니다.
                          Notification.sendClosingNotification(PartyID);
                          res.status(200).send('User added to party successfully and party is now closed');
                      });
                  } else {
                      res.status(200).send('User added to party successfully');
                  }
              });
          });
      });
  });
}

exports.partydeadline = (req, res) => {
  const { PartyID, StudentID } = req.body;

  // 먼저 사용자의 권한 확인
  const permissionQuery = 'SELECT Permission FROM Party_People WHERE PartyID = ? AND StudentID = ?';
  db.query(permissionQuery, [PartyID, StudentID], (error, results) => {
      if (error) {
          return res.status(500).send('Database error: ' + error);
      }
      // Permission이 1인지 확인
      if (results.length > 0 && results[0].Permission === 1) {
          // 권한이 있는 경우, PartyState를 0으로 업데이트
          const updateQuery = 'UPDATE Party SET PartyState = 0 WHERE PartyID = ?';
          db.query(updateQuery, [PartyID], (updateError, updateResults) => {
              if (updateError) {
                  return res.status(500).send('Failed to update party state: ' + updateError);
              }
              res.send('Party state updated successfully.');

              // 파티 모집이 마감되면 해당 파티에 참가한 사용자들에게 FCM 알림을 보냅니다.
              Notification.sendClosingNotification(PartyID);
          });
      } else {
          // 권한이 없는 경우, 에러 메시지 반환
          res.status(403).send('Not authorized to close this party.');
      }
  });
}

exports.getpartypeople = (req, res) => {
    const { PartyID } = req.query;

    if (!PartyID) {
        return res.status(400).send('PartyID is required');
    }

    const sqlQuery = `
        SELECT pp.StudentID, u.Nickname, u.Profile
        FROM Party_People pp
        INNER JOIN User u ON pp.StudentID = u.StudentID
        WHERE pp.PartyID = ?  AND pp.ChatState = 1;
    `;

    db.query(sqlQuery, [PartyID], (error, results) => {
        if (error) {
            return res.status(500).send('Database error while retrieving party members: ' + error);
        }
        if (results.length === 0) {
            return res.status(404).send('No members found for this party.');
        } else {
            res.status(200).json(results);
        }
    });
};

exports.getpartypeopleprofile = (req, res) => {

    const { PartyID, StudentID } = req.query;
    
    if (!PartyID || !StudentID) {
        return res.status(400).send('Both PartyID and StudentID are required');
    }

    const sqlQuery = `
        SELECT u.Profile
        FROM User u
        INNER JOIN Party_People pp ON u.StudentID = pp.StudentID
        WHERE pp.PartyID = ? AND pp.StudentID = ?;
    `;
  
    db.query(sqlQuery, [PartyID, StudentID], (error, results) => {
        if (error) {
            console.log('Error while getting image:', err);
            res.status(500).send('Failed to get image.');
            return;
        }
  
        if (results.length > 0) {
            const imageData = results[0].Profile; // 이미지 데이터 추출
            res.status(200).send(imageData); // 클라이언트에 이미지 데이터 전송
        } else {
            res.status(404).send('Image not found.');
        }
    });
  }
  exports.getuserinfo = (req, res) => {
    console.log('1');
    const { StudentID } = req.query;
    
    if (!StudentID) {
      return res.status(400).send('StudentID is required');
      console.log('2');
    }
    console.log('3');
    const sqlQuery = `
      SELECT Gender, Age, Major, Introduce
      FROM User
      WHERE StudentID = ?;
    `;
    console.log('4');
    db.query(sqlQuery, [StudentID], (error, results) => {
      if (error) {
        console.log('Error while retrieving user info:', error);
        res.status(500).send('Failed to get user info.');
        return;
      }
  
      if (results.length > 0) {
        res.status(200).json(results[0]); // 유저 정보 전송
      } else {
        res.status(404).send('User not found.');
      }
    });
  };
