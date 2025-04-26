const db = require('../../server/db'); //1


exports.getChatList = (req, res) => {
    const { studentID } = req.query;

    const query = `
        SELECT P.PartyID, P.PartyTitle,
               (SELECT COUNT(*) FROM Party_People WHERE PartyID = P.PartyID AND ChatState = 1) AS ParticipantCount,
               (SELECT ChatData FROM Chatting WHERE ChatID = P.PartyID ORDER BY ChatTime DESC LIMIT 1) AS LastMessage,
               P.PartyCa
        FROM Party_People PP 
        INNER JOIN Party P ON PP.PartyID = P.PartyID
        WHERE PP.StudentID = ? AND PP.ChatState = 1
    `;

    db.query(query, [studentID], (err, rows) => {
        if (!err) {
            res.status(200).json(rows);
        } else {
            console.error(err);
            res.status(500).json({ message: "Internal server error" });
        }
    });
};

exports.getMessage = (req, res) => {
    const { ChatID } = req.query; // 요청에서 ChatID를 가져옴
  
    if (!ChatID) {
        return res.status(400).send('ChatID is required');
    }
  
    const sqlQuery = `
        SELECT * FROM Chatting
        WHERE ChatID = ?
        ORDER BY ChatNum ASC;
    `;
  
    db.query(sqlQuery, [ChatID], (error, results) => {
        if (error) {
            res.status(500).send('Database error while retrieving messages: ' + error);
            return;
        }
        res.status(200).json(results);
    });
  }

  exports.sendMessage = (req, res) => {
    const { partyID, studentID } = req.query;
    const { joinID, chatData, ChatID } = req.body; // 변경된 부분: ChatID 추가

    // 해당 partyID에 대해 해당 studentID가 존재하는지 확인
    db.query('SELECT * FROM Party_People WHERE PartyID = ? AND StudentID = ?', [ChatID, studentID], (err, rows) => {
        if (!err) {
            if (rows.length > 0 || true) { // 채팅방에 참가한 사용자인 경우에만 메시지 전송
                const nickname = req.body.nickName; // 클라이언트에서 받은 닉네임
                const currentTime = new Date().toISOString(); // 현재 시간을 UTC 포맷으로 변환

                const query = 'INSERT INTO Chatting (JoinID, ChatData, ChatTime, ChatID, NickName) VALUES (?, ?, ?, ?, ?)';
                // partyID를 ChatID로 사용하여 저장
                db.query(query, [joinID, chatData, currentTime, ChatID, nickname], (err, result) => { // 변경된 부분: partyID 대신 ChatID 사용
                    if (!err) {
                        res.status(201).json({ message: "Message sent successfully", chat: result });
                    } else {
                        console.error(err);
                        res.status(500).json({ message: "Internal server error" });
                    }
                });
            } else {
                res.status(403).json({ message: "User is not authorized to send message in this chat room" });
            }
        } else {
            console.error(err);
            res.status(500).json({ message: "Internal server error" });
        }
    });
};

exports.getParticipants = (req, res) => {
    const { partyID } = req.params;

    const query = `
        SELECT NickName, Permission
        FROM Party_People
        WHERE PartyID = ? AND ChatState = 1;
    `;

    db.query(query, [partyID], (err, rows) => {
        if (!err) {
            res.status(200).json(rows);
        } else {
            console.error(err);
            res.status(500).json({ message: "Internal server error" });
        }
    });
};

exports.getParticipantDetails = (req, res) => {
    const { partyID, nickname } = req.params;

    const query = `
        SELECT PP.NickName, PP.Permission, U.Major, U.Gender, U.Age, U.Introduce, U.Profile
        FROM Party_People PP
        INNER JOIN User U ON PP.StudentID = U.StudentID
        WHERE PP.PartyID = ? AND PP.NickName = ? AND PP.ChatState = 1;
    `;

    db.query(query, [partyID, nickname], (err, rows) => {
        if (!err) {
            if (rows.length > 0) {
                res.status(200).json(rows[0]); // 첫 번째 결과를 반환
            } else {
                res.status(404).json({ message: "Participant not found" });
            }
        } else {
            console.error(err);
            res.status(500).json({ message: "Internal server error" });
        }
    });
};

exports.getchatpeopleprofile = (req, res) => {

    const { PartyID, NickName } = req.query;

    if (!PartyID || !NickName) {
        return res.status(400).send('Both PartyID and NickName are required');
    }

    const sqlQuery = `
        SELECT u.Profile
        FROM User u
        INNER JOIN Party_People pp ON u.StudentID = pp.StudentID
        WHERE pp.PartyID = ? AND pp.NickName = ?;
    `;

    db.query(sqlQuery, [PartyID, NickName], (error, results) => {
        if (error) {
            console.log('Error while getting image:', error);
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
};

exports.deletechat = (req, res) => {
    const { PartyID, StudentID } = req.body;

    if (!PartyID || !StudentID) {
        return res.status(400).send('Both PartyID and StudentID are required.');
    }

    db.getConnection((err, connection) => {
        if (err) {
            console.error('Error getting database connection:', err);
            return res.status(500).send('Database connection error');
        }

        connection.beginTransaction(err => {
            if (err) {
                connection.release();
                console.error('Error starting transaction:', err);
                return res.status(500).send('Error starting transaction');
            }

            const updateChatStateQuery = `
                UPDATE Party_People
                SET ChatState = 0
                WHERE PartyID = ? AND StudentID = ?;
            `;
            connection.query(updateChatStateQuery, [PartyID, StudentID], (err, chatStateResults) => {
                if (err) {
                    connection.rollback(() => {
                        connection.release();
                        console.error('Error updating chat state:', err);
                        return res.status(500).send('Database error while updating chat state: ' + err);
                    });
                } else if (chatStateResults.affectedRows === 0) {
                    connection.rollback(() => {
                        connection.release();
                        return res.status(404).send('No matching party or student found.');
                    });
                } else {
                    const decreaseCurPeopleQuery = `
                        UPDATE Party
                        SET CurPeople = CASE 
                                            WHEN CurPeople > 0 THEN CurPeople - 1 
                                            ELSE CurPeople 
                                        END
                        WHERE PartyID = ?;
                    `;
                    connection.query(decreaseCurPeopleQuery, [PartyID], (err) => {
                        if (err) {
                            connection.rollback(() => {
                                connection.release();
                                console.error('Error decreasing current people count:', err);
                                return res.status(500).send('Database error while decreasing people count: ' + err);
                            });
                        } else {
                            connection.commit(err => {
                                if (err) {
                                    connection.rollback(() => {
                                        connection.release();
                                        console.error('Error committing transaction:', err);
                                        return res.status(500).send('Error committing transaction');
                                    });
                                } else {
                                    connection.release();
                                    res.status(200).send('Chat state updated and current people count decreased successfully.');
                                }
                            });
                        }
                    });
                }
            });
        });
    });
};

exports.getJoinID = (req, res) => {
    const { partyID, studentID } = req.query;

    const query = `
        SELECT JoinID
        FROM Party_People
        WHERE PartyID = ? AND StudentID = ?
    `;

    db.query(query, [partyID, studentID], (err, rows) => {
        if (!err) {
            if (rows.length > 0) {
                res.status(200).json(rows[0].JoinID); // JoinID 반환
            } else {
                res.status(404).json({ message: "JoinID not found for the given party and student" });
            }
        } else {
            console.error(err);
            res.status(500).json({ message: "Internal server error" });
        }
    });
};

exports.getNickName = (req, res) => {
    const { studentID } = req.query;

    const query = `
        SELECT NickName
        FROM Party_People
        WHERE StudentID = ?
    `;

    db.query(query, [studentID], (err, rows) => {
        if (!err) {
            if (rows.length > 0) {
                res.status(200).json({ nickName: rows[0].NickName });
            } else {
                res.status(404).json({ message: "Nickname not found for the given student ID" });
            }
        } else {
            console.error(err);
            res.status(500).json({ message: "Internal server error" });
        }
    });
};

exports.reportChat = (req, res) => {
    const { ChatID_R, StudentID, ReportCa, ReportCo, NickName } = req.body;

    const reportQuery = `
        INSERT INTO Report (ChatID_R, StudentID, ReportCa, ReportCo, NickName)
        VALUES (?, ?, ?, ?, ?)
    `;

    const updateProblemNumQuery = `
        UPDATE User
        SET ProblemNum = ProblemNum + 1
        WHERE NickName = ?
    `;

    db.query(reportQuery, [ChatID_R, StudentID, parseInt(ReportCa), ReportCo, NickName], (err, result) => {
        if (!err) {
            db.query(updateProblemNumQuery, [NickName], (err, updateResult) => {
                if (!err) {
                    res.status(201).json({ message: "Report submitted successfully and ProblemNum updated" });
                } else {
                    console.error(err);
                    res.status(500).json({ message: "Report submitted, but failed to update ProblemNum" });
                }
            });
        } else {
            console.error(err);
            res.status(500).json({ message: "Internal server error" });
        }
    });
};