const mysql = require("mysql2");

const db = mysql.createConnection({
  host: "localhost",
  user: "borrow",
  password: "oHhautd1nsLtvNRw",
  database: "borrow",
});


module.exports = db;