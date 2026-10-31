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

> **Note:** Running the backend requires `backend/app.js`. If this file does not exist, add a backend entry point before selecting Run backend.
