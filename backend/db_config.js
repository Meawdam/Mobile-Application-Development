const mysql = require("mysql2/promise");

const db = mysql.createPool({
  host: "localhost",
  user: "borrow",
  password: "oHhautd1nsLtvNRw",
  database: "borrow",
});


module.exports = db;