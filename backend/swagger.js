const swaggerJsdoc = require("swagger-jsdoc");

const openApiSpecification = swaggerJsdoc({
  definition: {
    openapi: "3.0.3",
    info: {
      title: "Mobile Application Development API",
      version: "1.0.0",
      description: "API documentation for authentication, user, asset, and borrow endpoints.",
    },
    servers: [
      {
        url: "http://localhost:3000",
        description: "Local development server",
      },
    ],
  },
  apis: [
    "./module/auth/auth_routes.js",
    "./module/user/user_routes.js",
    "./module/asset/asset_routes.js",
    "./module/borrow/borrow_route.js",
  ],
});

module.exports = openApiSpecification;
