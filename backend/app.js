const express = require("express");
const cors = require("cors");
const path = require("node:path");
const swaggerUi = require("swagger-ui-express");
const openApiSpecification = require("./swagger");
const db = require("./db_config");

const app = express();

app.use(express.json());
app.use(cors());
app.use("/uploads", express.static(path.join(__dirname, "upload")));

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(openApiSpecification));
app.get("/api-docs.json", (req, res) => {
  res.json(openApiSpecification);
});

app.use("/api/auth", require("./module/auth/auth_routes"));
app.use("/api/users", require("./module/user/user_routes"));
app.use("/api/assets", require("./module/asset/asset_routes"));
app.use("/api/borrows", require("./module/borrow/borrow_route"));

app.use((err, req, res, next) => {
  console.error("Unhandled Error:", err);
  res.status(err.status || 500).json({
    message: err.message || "Internal Server Error",
  });
});

const PORT = 3000;
async function startServer() {
  try {
    await db.query("SELECT 1");
  } catch (error) {
    console.error("Unable to connect to the database:", error.message);
    try {
      await db.end();
    } catch (closeError) {
      console.error("Unable to close the database pool:", closeError.message);
    }
    process.exitCode = 1;
    return;
  }

  app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`Swagger UI running on http://localhost:${PORT}/api-docs`);
  });
}

startServer();
