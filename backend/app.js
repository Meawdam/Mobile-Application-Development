const express = require("express");
const cors = require("cors");
const swaggerUi = require("swagger-ui-express");
const openApiSpecification = require("./swagger");
const db = require("./db_config");

const app = express();

app.use(express.json());
app.use(cors());

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(openApiSpecification));
app.get("/api-docs.json", (req, res) => {
  res.json(openApiSpecification);
});

app.use("/api/auth", require("./module/auth/auth_routes"));

app.use((err, req, res, next) => {
  console.error("Unhandled Error:", err);
  res.status(err.status || 500).json({
    message: err.message || "Internal Server Error",
  });
});

const PORT = 3000;
db.connect((error) => {
  if (error) {
    console.error("Unable to connect to the database:", error.message);
    db.destroy();
    process.exitCode = 1;
    return;
  }

  app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
  });
});
