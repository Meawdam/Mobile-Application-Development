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

The API base URL is `http://localhost:3000`. After starting the backend, use [Swagger UI](http://localhost:3000/api-docs) to try the endpoints. The generated OpenAPI document is available at [http://localhost:3000/api-docs.json](http://localhost:3000/api-docs.json).

### Authentication and response conventions

Most protected endpoints require the JWT returned by `POST /api/auth/login`:

```http
Authorization: Bearer <token>
```

Tokens expire after one day. New registrations always receive the `user` role. Endpoints marked **Admin** require an admin token. Public asset browsing accepts an optional token; when signed in, the current user's own assets are excluded from the available-assets list. An approved asset can be viewed publicly; its owner and admins can also view their unapproved assets.

Successful list responses generally use `{ "data": [...] }`; single-record responses use `{ "data": {...} }`. Errors use `{ "message": "..." }`. Common status codes are `400` for invalid input or state, `401` for a missing token, `403` for an invalid token or insufficient access, `404` when a record is not found or is not visible to the caller, and `409` when a concurrent or current state prevents the operation.

### Endpoint reference

#### Authentication

| Method and path | Access | Request | Result |
| --- | --- | --- | --- |
| `POST /api/auth/register` | Public | JSON: `username`, `email`, `password`, `phone_num` | `201`; `{ message, data: { id, username, email, phone_num, role } }`. Username/email must be unique; phone number is at most 10 characters. |
| `POST /api/auth/login` | Public | JSON: `email`, `password` | `200`; `{ message, token, user }`. Invalid credentials return `401`. |
| `GET /api/auth/me` | User | — | `200`; `{ user }` from the JWT claims. |

#### Assets

| Method and path | Access | Request | Result |
| --- | --- | --- | --- |
| `GET /api/assets` | Public, optional token | Query: `q` searches name, description, and pickup point (up to 100 characters) | `200`; available approved assets that are ready and within their lending window. |
| `GET /api/assets/all` | Admin | — | `200`; all assets, including pending or rejected assets. |
| `GET /api/assets/mine` | User | — | `200`; assets owned by the caller. |
| `GET /api/assets/:id` | Public, optional token | Path: asset ID | `200`; approved asset details. Owner/admin can also view unapproved assets; otherwise hidden or missing assets return `404`. |
| `POST /api/assets` | User | `multipart/form-data`: `name`, `description`, `image`, `down_payment`, `price`, `pickup_point`, `return_before` | `201`; submitted asset with `approval: pending`. Images must be JPEG, PNG, GIF, or WebP and no larger than 5 MB. |
| `PATCH /api/assets/:id` | Owner | JSON: `name`, `description`, `down_payment`, `price`, `pickup_point`, `return_before` | `200`; updates the asset. Currently borrowed assets cannot be edited. |
| `DELETE /api/assets/:id` | Owner | Path: asset ID | `200`; deletes the asset if it has no borrow history. Borrowed assets or assets with history return `409`. |
| `PATCH /api/assets/:id/approve` | Admin | JSON: `approval` (`approved` or `not approve`), optional `approval_message` | `200`; updates the moderation state. A rejection requires a reason (up to 500 characters). |

`return_before` is the asset owner's lending end date. Amounts accept non-negative values with up to two decimal places. Asset creation returns an image path such as `/uploads/<generated-name>.png`.

#### Borrows

All borrow endpoints require a signed-in user unless marked Admin.

| Method and path | Access | Request | Result |
| --- | --- | --- | --- |
| `GET /api/borrows/all` | Admin | — | `200`; all borrow records. |
| `GET /api/borrows/my` | User | — | `200`; records where the caller is the borrower. |
| `GET /api/borrows/lending` | User | — | `200`; records for assets owned by the caller. |
| `GET /api/borrows/:id` | Borrower, asset owner, or Admin | Path: borrow ID | `200`; borrow details. Other users receive `403`. |
| `POST /api/borrows` | User | JSON: `asset_id`, `pickup_date`, `return_date` | `201`; creates an unpaid `requested` record. Dates use `YYYY-MM-DD`, include both endpoints in `rental_days`, and must fit within `return_before`. |
| `PATCH /api/borrows/:id/approve` | Asset owner | Path: borrow ID | `200`; changes an unpaid request to `approved`. |
| `PATCH /api/borrows/:id/reject` | Asset owner | JSON: `reason` (required, up to 500 characters) | `200`; rejects an unpaid request. |
| `PATCH /api/borrows/:id/cancel` | Borrower | Path: borrow ID | `200`; cancels an unpaid request. |
| `POST /api/borrows/:id/pay` | Borrower | Path: borrow ID | `200`; deducts the total from the wallet and marks the asset borrowed. Payment is allowed while the request is `requested` or `approved`. |
| `PATCH /api/borrows/:id/return` | Borrower | Path: borrow ID | `200`; requests return and waits for owner confirmation. |
| `PATCH /api/borrows/:id/confirm-return` | Asset owner | Path: borrow ID | `200`; confirms a pending return. An eligible deposit refund is queued for admin processing. |

Borrow records include the price and deposit snapshots from request time (`price_per_day`, `rental_amount`, `deposit_amount`, and `total_amount`). `status` can be `requested`, `approved`, `borrowed`, `returned_pending`, `returned_confirmed`, or `rejected`; cancellation also uses `rejected`. `payment_status` can be `unpaid`, `paid`, `refunded`, or `forfeited`. After the planned return date passes, the scheduler forfeits the deposit to the asset owner if the return has not been confirmed.

#### Wallet

| Method and path | Access | Request | Result |
| --- | --- | --- | --- |
| `GET /api/wallet` | User | — | `200`; `{ data: { balance } }`. |
| `POST /api/wallet/top-up` | User | JSON: `amount` (positive, up to two decimal places; maximum 1,000,000 in the app's currency) | `200`; `{ message, data: { balance, topped_up } }`. |

The top-up endpoint credits the wallet and records a ledger entry directly; it is not connected to a payment gateway.

#### Users (Admin)

All user-management endpoints require an admin token.

| Method and path | Request | Result |
| --- | --- | --- |
| `GET /api/users` | — | `200`; list of users with suspension state and borrow summary counts. |
| `GET /api/users/:id` | Path: user ID | `200`; one user record and summary counts. |
| `GET /api/users/:id/activities` | Query: optional `category` (`rental`, `finance`, `admin`), `limit` (1–100, default 50), `offset` (default 0) | `200`; `{ data: [...] }` activity records. |
| `PATCH /api/users/:id/suspension` | JSON: `is_suspended` (boolean); `reason` required when true (up to 500 characters) | `200`; suspends or reactivates the account. Reactivation clears the reason. Suspended accounts cannot use protected endpoints. |

#### Admin dashboard and transactions

All endpoints in this group require an admin token.

| Method and path | Request | Result |
| --- | --- | --- |
| `GET /api/admin/dashboard` | — | `200`; asset counts, borrow volume for the last seven days, and finance totals. |
| `GET /api/admin/transactions` | Query filters: `type`, `status`, `search`; pagination: `limit` (1–100, default 50), `offset` (default 0) | `200`; `{ data: [...], pagination: { limit, offset, total } }`. Types: `wallet_top_up`, `rental_payment`, `deposit_hold`, `deposit_forfeiture`, `deposit_refund`. Statuses: `pending`, `completed`, `released`. |
| `POST /api/admin/transactions/:id/refund` | Path: transaction ID | `200`; processes a pending deposit refund once and credits the borrower's wallet. A non-pending refund returns `409`. |

### Example requests

Register and log in:

```http
POST /api/auth/register
Content-Type: application/json

{"username":"jane_doe","email":"jane@example.com","password":"strong-password","phone_num":"0812345678"}
```

```http
POST /api/auth/login
Content-Type: application/json

{"email":"jane@example.com","password":"strong-password"}
```

Create a borrow request using the returned token:

```http
POST /api/borrows
Authorization: Bearer <token>
Content-Type: application/json

{"asset_id":4,"pickup_date":"2026-11-14","return_date":"2026-11-16"}
```

### Testing

From the `backend` directory, `npm test` runs Node's built-in test runner (`node --test`). API endpoints can be exercised through Swagger UI or with an HTTP client. The test command currently discovers no backend test files, so it reports zero tests until test files are added.

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
