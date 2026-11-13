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

`backend/borrow.sql` is the canonical full schema for a new database. It stores
asset price and deposit with two decimal places, and keeps the calculated borrow
amounts, wallet balance, and transaction ledger at two decimal places as well.
The SQL file creates tables and is not an incremental update for an existing
database; existing databases must be brought in line with this schema before
running the current backend. The historical scripts in `backend/migrations/`
do not include all current schema changes.

Borrow day-system fields (`pickup_date`, `planned_return_date`, `rental_days`)
are added by `backend/migrations/20261112_add_borrow_day_fields.sql`. Borrower
pickup/return dates must stay within the lender's asset `return_before`
(lending end date).

Wallet payments use `users.wallet_balance` and borrow amount snapshots
(`rental_amount`, `deposit_amount`, `total_amount`) from
`backend/migrations/20261112_add_wallet_and_payment_amounts.sql`.
`POST /api/borrows/:id/pay` deducts `total_amount` from the wallet.
After the day in `planned_return_date` passes, any borrow that is not confirmed
returned has its full deposit automatically transferred to the asset owner's
wallet. This also applies while a return request is waiting for owner
confirmation. On-time returns remain eligible for the existing admin-processed
deposit refund.

The configured database account does not have permission to alter tables, so
schema migrations must be applied using a database account with `ALTER TABLE`
privileges.

Login uses an email address (`POST /api/auth/login` with `email` and `password`).
Asset listings support `GET /api/assets?q=search-term`, matching the asset name,
description, and pickup point. `return_before` is the asset owner's lending
window; the borrower's `planned_return_date` is the return deadline used for
deposit forfeiture.

From `backend`, `npm test` runs both the unit tests and the API smoke script.
The smoke script requires a running API, a compatible database, and a seeded
admin account, and creates test data.
