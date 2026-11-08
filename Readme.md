# Project Setup Guide

## Prerequisites

- [Git](https://git-scm.com/) to clone the project
- [Node.js and npm](https://nodejs.org/) to install and run the backend
- [Flutter SDK](https://docs.flutter.dev/get-started/install) to install dependencies and run the frontend
- A Flutter-supported device or emulator if you want to run the frontend

Make sure these tools are available from your terminal:

```powershell
git --version
node --version
npm --version
flutter --version
```

## 1. Clone the project

Open PowerShell or a terminal and clone the project:

```powershell
git clone https://github.com/Meawdam/Mobile-Application-Development.git
cd Mobile-Application-Development
```

## 2. Install the CLI

Run the following commands from the project root:

```powershell
cd cli
npm link
cd ..
```

`npm link` registers the `prod` command so it can be used from your terminal. After installation, run the CLI commands from the project root.

## 3. Install dependencies

```powershell
prod i
```

Or use the full command:

```powershell
prod install
```

The CLI first installs the backend dependencies with `npm install`, then installs the frontend dependencies with `flutter pub get`. If either step fails, the command stops and displays an error.

## 4. Run the frontend or backend

```powershell
prod run
```

Use the up/down arrow keys to select **Run frontend** or **Run backend**, then press Enter. This menu requires an interactive terminal.

## CLI commands

| Command | Result |
| --- | --- |
| `prod i` | Installs the backend and frontend dependencies |
| `prod install` | Same as `prod i` |
| `prod run` | Opens a menu to select the frontend or backend using the arrow keys |
| `prod --help` | Displays command usage |

| `prod run` menu option | Command used by the CLI |
| --- | --- |
| Run frontend | Runs `flutter run` in the `frontend` directory |
| Run backend | Runs `nodemon app.js` using `npm run dev` in the `backend` directory |

## API documentation

After starting the backend, open [http://localhost:3000/api-docs](http://localhost:3000/api-docs) to browse and try the API endpoints in Swagger UI. The OpenAPI specification is also available at [http://localhost:3000/api-docs.json](http://localhost:3000/api-docs.json).

## Database update and features

For an existing database, apply
`backend/migrations/20261106_change_return_before_to_date.sql` using a database
account with `ALTER TABLE` privileges. `return_before` is a date-only value;
using `DATE` instead of `TIMESTAMP` also supports dates beyond 2038. New
databases should use the schema in `backend/borrow.sql`. If an asset already
has a zero date, update it to its intended date; the original date cannot be
recovered from that stored value.

The configured database account does not have permission to alter tables, so
schema migrations must be applied using a database account with `ALTER TABLE`
privileges.

Login uses an email address (`POST /api/auth/login` with `email` and `password`).
Asset listings support `GET /api/assets?q=search-term`, matching the asset name,
description, and pickup point. A return confirmed after the asset's
`return_before` date stores a fine equal to `price` for each overdue calendar
day and returns the amount as `fine_amount`.

Run backend tests from the `backend` directory with `npm test`.
