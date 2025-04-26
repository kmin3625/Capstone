const db = require('../db'); // db.js 파일에서 설정 가져오기
const cron = require('node-cron');
const Notification = require('../../routes/notification/notification.controller.js'); // Notification 모듈 가져오기

function updatePartyStates() {
    const currentTime = new Date();
    const selectQuery = `
        SELECT PartyID
        FROM Party
        WHERE EndTime < ? AND PartyState != 0
    `;

    db.query(selectQuery, [currentTime], (selectError, selectResults) => {
        if (selectError) {
            console.error('Error selecting parties to update:', selectError);
        } else {
            if (selectResults.length > 0) {
                const partyIds = selectResults.map(row => row.PartyID);
                
                const updateQuery = `
                    UPDATE Party
                    SET PartyState = 0
                    WHERE PartyID IN (?)
                `;
                
                db.query(updateQuery, [partyIds], (updateError, updateResults) => {
                    if (updateError) {
                        console.error('Error updating party states:', updateError);
                    } else {
                        console.log(`${updateResults.affectedRows} parties were updated.`);
                        partyIds.forEach(partyId => {
                            Notification.sendClosingNotification(partyId);
                        });
                    }
                });
            } else {
                console.log('No parties need updating.');
            }
        }
    });
}

// 매분 마다 실행되는 cron job 설정
cron.schedule('* * * * *', updatePartyStates);

module.exports = updatePartyStates;
