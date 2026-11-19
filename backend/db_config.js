const mysql = require("mysql2/promise");

const db = mysql.createPool({
  host: "localhost",
  user: "borrow",
  password: "oHhautd1nsLtvNRw",
  database: "borrow",
  // Keep MySQL DATE columns as calendar dates. Returning them as JS Date
  // objects serializes midnight in the server timezone as a shifted UTC date.
  dateStrings: ["DATE"],
});


module.exports = db;
