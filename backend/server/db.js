var mysql = require('mysql2');
const db = mysql.createPool({ 
    host : '',
    user : '',
    password : '',
    database : ''
});

module.exports = db;