const path = require("path");
const db = require('../../server/db');
const Notification = require('../notification/notification.controller.js');

exports.signup = (req, res) => {
    const { StudentID, NickName, UID, Email, Gender, Age, Password, Token } = req.body;

    if (!StudentID || !NickName || !UID || !Email || !Gender || !Age || !Password || !Token) {
        return res.status(400).send('All fields are required.');
    }
    // 사용자 입력 정보를 User 테이블에 저장
    const sqlInsert = `
        INSERT INTO User (StudentID, Nickname, UID, Email, Gender, Age, Password, Token)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    `;

    db.query(sqlInsert, [StudentID, NickName, UID, Email, Gender, Age, Password, Token], (error, results) => {
        if (error) {
            if (error.code === 'ER_DUP_ENTRY') {
                return res.status(409).send('User already exists with the same StudentID or Email.');
            }
            return res.status(500).send('Database error during the registration process: ' + error);
        }
        res.status(201).send('User registered successfully.');
    });
};

exports.uid = (req, res) => {
    const { uid } = req.query; // UID를 쿼리 파라미터로 받음
    const token = req.headers.authorization; // Authorization 헤더에서 토큰을 받음

    if (!uid) {
        return res.status(400).send("UID is required");
    }

    if (!token) {
        return res.status(401).send("Token is required");
    }

    // User 테이블에서 UID를 이용해 StudentID와 Nickname 가져오기
    const query = 'SELECT StudentID, Nickname FROM User WHERE UID = ?';
    db.query(query, [uid], (err, results) => {
        if (err) {
            return res.status(500).send('Database error: ' + err.message);
        }
        if (results.length === 0) {
            return res.status(404).send("User not found");
        }

        const studentID = results[0].StudentID;
        // StudentID와 토큰을 이용해 Token 테이블 업데이트
        const updateQuery = 'UPDATE User SET Token = ? WHERE StudentID = ?';
        db.query(updateQuery, [token, studentID], (updateErr, updateResults) => {
            if (updateErr) {
                return res.status(500).send('Token update error: ' + updateErr.message);
            }

            res.json(results[0]); // 조회된 사용자 정보 반환
        });
    });
};

exports.saveUserName = (req, res) => {
  console.log('1');
  const { studentID, nickname, age, gender, email, Newnickname } = req.body; // 요청에서 사용자 정보 추출

  // Party 테이블에서 해당 studentID에 해당하는 닉네임을 새로운 닉네임으로 업데이트
  const updatePartyQuery = 'UPDATE User SET NickName = ? WHERE StudentID = ?';
  console.log('2');
  db.query(updatePartyQuery, [Newnickname, studentID], (updatePartyErr, updatePartyResult) => {
      console.log('3');
      
      if (updatePartyErr) {
          console.log('Error while updating Party:', updatePartyErr);
          res.status(500).send('Failed to update Party.');
          return;
      }

      // user 테이블에 사용자 정보 업데이트
      const updateUserInfoQuery = 'UPDATE User SET Nickname = ?, Age = ?, Gender = ?, Email = ? WHERE StudentID = ?';
      console.log('4');
      db.query(updateUserInfoQuery, [Newnickname, age, gender, email, studentID], (updateUserInfoErr, updateUserInfoResult) => {
          console.log('5');
          if (updateUserInfoErr) {
              console.log('Error while updating user info:', updateUserInfoErr);
              res.status(500).send('Failed to update user info.');
              return;
          }
          
          res.status(200).send('User info updated successfully!');
      });
  });
};

exports.saveUserAge = (req, res) => {
  console.log('1');
  const { studentID, nickname, age, gender, email } = req.body; // 요청에서 사용자 정보 추출

  // Party 테이블에서 해당 studentID에 해당하는 닉네임을 새로운 닉네임으로 업데이트
  const updatePartyQuery = 'UPDATE User SET Age = ? WHERE StudentID = ?';
  console.log('2');
  db.query(updatePartyQuery, [age, studentID], (updatePartyErr, updatePartyResult) => {
      console.log('3');
      
      if (updatePartyErr) {
          console.log('Error while updating Party:', updatePartyErr);
          res.status(500).send('Failed to update Party.');
          return;
      }

      // user 테이블에 사용자 정보 업데이트
      const updateUserInfoQuery = 'UPDATE User SET Nickname = ?, Age = ?, Gender = ?, Email = ? WHERE StudentID = ?';
      console.log('4');
      db.query(updateUserInfoQuery, [nickname, age, gender, email, studentID], (updateUserInfoErr, updateUserInfoResult) => {
          console.log('5');
          if (updateUserInfoErr) {
              console.log('Error while updating user info:', updateUserInfoErr);
              res.status(500).send('Failed to update user info.');
              return;
          }
          
          res.status(200).send('User info updated successfully!');
      });
  });
};

exports.saveUserIntro = (req, res) => {
  console.log('1');
  const { studentID, nickname, age, gender, email, introduce } = req.body; // 요청에서 사용자 정보 추출

  // Party 테이블에서 해당 studentID에 해당하는 닉네임을 새로운 닉네임으로 업데이트
  const updatePartyQuery = 'UPDATE User SET Introduce = ? WHERE StudentID = ?';
  console.log('2');
  db.query(updatePartyQuery, [introduce, studentID], (updatePartyErr, updatePartyResult) => {
      console.log('3');
      
      if (updatePartyErr) {
          console.log('Error while updating Party:', updatePartyErr);
          res.status(500).send('Failed to update Party.');
          return;
      }

      // user 테이블에 사용자 정보 업데이트
      const updateUserInfoQuery = 'UPDATE User SET Nickname = ?, Age = ?, Gender = ?, Email = ?, Introduce = ? WHERE StudentID = ?';
      console.log('4');
      db.query(updateUserInfoQuery, [nickname, age, gender, email, introduce, studentID], (updateUserInfoErr, updateUserInfoResult) => {
          console.log('5');
          if (updateUserInfoErr) {
              console.log('Error while updating user info:', updateUserInfoErr);
              res.status(500).send('Failed to update user info.');
              return;
          }
          
          res.status(200).send('User info updated successfully!');
      });
  });
};

exports.getUserInfo = (req, res) => {
  const studentID = req.body.studentID; // 요청에서 studentID를 가져옴
  const query = `SELECT nickname, age, gender, introduce, major FROM User WHERE studentID = ${studentID}`; // 해당 studentID에 해당하는 사용자의 닉네임, 나이, 성별을 가져오는 쿼리
  
  db.query(query, (err, rows, fields) => { // 쿼리 실행
      if (!err) {
          if (rows.length > 0) {
              const { nickname, age, gender, introduce, major } = rows[0]; // 첫 번째 행의 닉네임, 나이, 성별 가져오기
              res.send({ nickname, age, gender, introduce, major }); // 닉네임, 나이, 성별을 응답으로 보냄
          } else {
              res.status(404).send('User not found'); // 해당 studentID에 해당하는 사용자를 찾을 수 없는 경우 404 에러 응답
          }
      } else {
          console.log('Error while fetching user info:', err);
          res.status(500).send('Failed to get user info.'); // 실패 시 응답
      }
  });
};

exports.saveUserGender = (req, res) => {
  console.log('1');
  const { studentID, nickname, age, gender, email} = req.body; // 요청에서 사용자 정보 추출

  // Party 테이블에서 해당 studentID에 해당하는 닉네임을 새로운 닉네임으로 업데이트
  const updatePartyQuery = 'UPDATE User SET Gender = ? WHERE StudentID = ?';
  console.log('2');
  db.query(updatePartyQuery, [gender, studentID], (updatePartyErr, updatePartyResult) => {
      console.log('3');
      
      if (updatePartyErr) {
          console.log('Error while updating Party:', updatePartyErr);
          res.status(500).send('Failed to update Party.');
          return;
      }

      // user 테이블에 사용자 정보 업데이트
      const updateUserInfoQuery = 'UPDATE User SET Nickname = ?, Age = ?, Gender = ?, Email = ? WHERE StudentID = ?';
      console.log('4');
      db.query(updateUserInfoQuery, [nickname, age, gender, email, studentID], (updateUserInfoErr, updateUserInfoResult) => {
          console.log('5');
          if (updateUserInfoErr) {
              console.log('Error while updating user info:', updateUserInfoErr);
              res.status(500).send('Failed to update user info.');
              return;
          }
          
          res.status(200).send('User info updated successfully!');
      });
  });
};

exports.uploadImageToServer = (req, res) => {
  const studentID = req.body.studentID;
  const imageData = req.body.imageData; // 클라이언트에서 보낸 이미지 데이터

  // 이미지 데이터를 longblob 형태로 업로드하는 쿼리 실행
  const uploadImageQuery = 'UPDATE User SET Profile = ? WHERE StudentID = ?';
  db.query(uploadImageQuery, [imageData, studentID], (err, result) => {
      if (err) {
          console.log('Error while uploading image:', err);
          res.status(500).send('Failed to upload image.');
          return;
      }

      res.status(200).send('Image uploaded successfully!');
  });
};

exports.getImageFromServer = (req, res) => {
  const studentID = req.body.studentID;

  // 해당 사용자의 프로필 이미지를 가져오는 쿼리 실행
  const getImageQuery = 'SELECT Profile FROM User WHERE StudentID = ?';
  db.query(getImageQuery, [studentID], (err, result) => {
      if (err) {
          console.log('Error while getting image:', err);
          res.status(500).send('Failed to get image.');
          return;
      }

      if (result.length > 0) {
          const imageData = result[0].Profile; // 이미지 데이터 추출
          res.status(200).send(imageData); // 클라이언트에 이미지 데이터 전송
      } else {
          res.status(404).send('Image not found.');
      }
  });
};

exports.saveUserMajor = (req, res) => {
    console.log('1');
    const { studentID, major} = req.body; // 요청에서 사용자 정보 추출
  
    // Party 테이블에서 해당 studentID에 해당하는 닉네임을 새로운 닉네임으로 업데이트
    const updatePartyQuery = 'UPDATE User SET Major = ? WHERE StudentID = ?';
    console.log('2');
    db.query(updatePartyQuery, [major, studentID], (updatePartyErr, updatePartyResult) => {
        console.log('3');
        
        if (updatePartyErr) {
            console.log('Error while updating Party:', updatePartyErr);
            res.status(500).send('Failed to update Party.');
            return;
        }
  
        // user 테이블에 사용자 정보 업데이트
        const updateUserInfoQuery = 'UPDATE User SET Major = ? WHERE StudentID = ?';
        console.log('4');
        db.query(updateUserInfoQuery, [major, studentID], (updateUserInfoErr, updateUserInfoResult) => {
            console.log('5');
            if (updateUserInfoErr) {
                console.log('Error while updating user info:', updateUserInfoErr);
                res.status(500).send('Failed to update user info.');
                return;
            }
            
            res.status(200).send('User info updated successfully!');
        });
    });
  };

// 회원 탈퇴 API
exports.withdraw = (req, res) => {
    const { studentID, password } = req.body;

    // 먼저 사용자가 존재하는지 확인
    const checkUserQuery = 'SELECT * FROM User WHERE StudentID = ? AND Password = ?';
    db.query(checkUserQuery, [studentID, password], (checkUserErr, checkUserResult) => {
        if (checkUserErr) {
            console.log('Error while checking user:', checkUserErr);
            res.status(500).send('Failed to check user.');
            return;
        }

        if (checkUserResult.length === 0) {
            // 사용자 존재하지 않음
            res.status(404).send('User not found or incorrect password.');
            return;
        }

        // 사용자가 존재하면 삭제
        const deleteUserQuery = 'DELETE FROM User WHERE StudentID = ?';
        db.query(deleteUserQuery, [studentID], (deleteUserErr, deleteUserResult) => {
            if (deleteUserErr) {
                console.log('Error while deleting user:', deleteUserErr);
                res.status(500).send('Failed to delete user.');
                return;
            }

            res.status(200).send('User deleted successfully!');
        });
    });
};

exports.user = (req, res) => {
    db.query('SELECT * FROM user', function (err, rows, fields) {
      if (!err) {
        res.send(rows); // response send rows11
      } else {
        console.log('err : ' + err);
        res.send(err); // response send err
      }
    });
  
  }

  exports.getNotiState = (req, res) => {
    const { StudentID } = req.query; // StudentID를 쿼리 파라미터로 받음
  
    console.log('Received StudentID:', StudentID);
  
    if (!StudentID) {
      return res.status(400).send('StudentID is required');
    }
  
    const query = 'SELECT NotiState FROM User WHERE StudentID = ?';
    db.query(query, [StudentID], (err, results) => {
      if (err) {
        return res.status(500).send('Database error: ' + err.message);
      }
      if (results.length === 0) {
        return res.status(404).send('StudentID not found');
      }
  
      res.json(results[0]); // 조회된 NotiState 반환
    });
  };

exports.updateNotiState = (req, res) => {
    console.log('1');
    const { StudentID, NotiState } = req.body; // 요청에서 studentID와 notiState 추출
  
    if (!StudentID || NotiState === undefined) {
      return res.status(400).send('StudentID and NotiState are required');
    }
  
    // User 테이블에서 해당 StudentID의 NotiState 업데이트
    const updateQuery = 'UPDATE User SET NotiState = ? WHERE StudentID = ?';
    console.log('2');
    db.query(updateQuery, [NotiState, StudentID], (updateErr, updateResult) => {
      console.log('3');
      if (updateErr) {
        console.log('Error while updating NotiState:', updateErr);
        res.status(500).send('Failed to update NotiState.');
        return;
      }
  
      if (updateResult.affectedRows === 0) {
        console.log('StudentID not found');
        res.status(404).send('StudentID not found');
        return;
      }
  
      res.status(200).send('NotiState updated successfully!');
    });
  };

  exports.logoutToken = (req, res) => {
    const { StudentID } = req.body; // StudentID를 요청 본문에서 받음

    console.log('Received StudentID:', StudentID);

    if (!StudentID) {
      return res.status(400).send('StudentID is required');
    }

    // User 테이블에서 StudentID에 해당하는 Token 값을 NULL로 업데이트
    const query = 'UPDATE User SET Token = NULL WHERE StudentID = ?';
    db.query(query, [StudentID], (err, results) => {
      if (err) {
        return res.status(500).send('Database error: ' + err.message);
      }
      if (results.affectedRows === 0) {
        return res.status(404).send('StudentID not found');
      }

      res.send('Logout successful, token set to NULL');
    });
};

exports.getAllNotices = (req, res) => {
    const sqlQuery = 'SELECT * FROM Notice ORDER BY NoticeDate DESC';

    db.query(sqlQuery, (error, results) => {
        if (error) {
            return res.status(500).send('공지사항 조회 중 데이터베이스 오류가 발생했습니다: ' + error);
        }
        res.status(200).json(results);
    });
};
