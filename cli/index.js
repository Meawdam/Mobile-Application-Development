#!/usr/bin/env node

const { spawn } = require("node:child_process");
const { existsSync } = require("node:fs");
const path = require("node:path");
const readline = require("node:readline");

const projectRoot = path.resolve(__dirname, "..");
const backendDirectory = path.join(projectRoot, "backend");
const frontendDirectory = path.join(projectRoot, "frontend");

function runCommand(command, args, cwd) {
  return new Promise((resolve, reject) => {
    console.log(`\n> ${command} ${args.join(" ")}`);

    const child = spawn(command, args, {
      cwd,
      stdio: "inherit",
      shell: process.platform === "win32",
    });

    child.once("error", reject);
    child.once("exit", (code, signal) => {
      if (signal) {
        resolve(1);
        return;
      }

      resolve(code ?? 1);
    });
  });
}

async function installDependencies() {
  console.log("Installing backend dependencies...");
  const backendExitCode = await runCommand("npm", ["install"], backendDirectory);
  if (backendExitCode !== 0) {
    return backendExitCode;
  }

  console.log("\nInstalling frontend dependencies...");
  return runCommand("flutter", ["pub", "get"], frontendDirectory);
}

function selectApplication() {
  if (!process.stdin.isTTY || !process.stdout.isTTY) {
    return Promise.reject(
      new Error("The run menu requires an interactive terminal."),
    );
  }

  const choices = ["Run frontend", "Run backend"];
  let selectedIndex = 0;

  function renderChoices() {
    process.stdout.write(
      choices
        .map((choice, index) => `${index === selectedIndex ? ">" : " "} ${choice}`)
        .join("\n") + "\n",
    );
  }

  return new Promise((resolve) => {
    console.log("Choose what to run (use the up/down arrows and Enter):");
    renderChoices();

    readline.emitKeypressEvents(process.stdin);
    process.stdin.setRawMode(true);
    process.stdin.resume();

    function finish(choice) {
      process.stdin.off("keypress", onKeypress);
      process.stdin.setRawMode(false);
      process.stdout.write("\n");
      resolve(choice);
    }

    function onKeypress(_input, key) {
      if (key.ctrl && key.name === "c") {
        process.exitCode = 130;
        finish(null);
        return;
      }

      if (key.name === "escape") {
        finish(null);
        return;
      }

      if (key.name === "up" || key.name === "down") {
        selectedIndex =
          (selectedIndex + (key.name === "down" ? 1 : choices.length - 1)) %
          choices.length;
        readline.moveCursor(process.stdout, 0, -choices.length);
        readline.clearScreenDown(process.stdout);
        renderChoices();
        return;
      }

      if (key.name === "return" || key.name === "enter") {
        finish(selectedIndex);
      }
    }

    process.stdin.on("keypress", onKeypress);
  });
}

async function runApplication() {
  const selection = await selectApplication();
  if (selection === null) {
    return process.exitCode ?? 0;
  }

  if (selection === 0) {
    console.log("Starting frontend...");
    return runCommand("flutter", ["run"], frontendDirectory);
  }

  const backendEntryPoint = path.join(backendDirectory, "app.js");
  if (!existsSync(backendEntryPoint)) {
    throw new Error(
      `Backend entry point not found: ${backendEntryPoint}\n` +
        "Add backend/app.js before running the backend.",
    );
  }

  console.log("Starting backend...");
  return runCommand("npm", ["run", "dev"], backendDirectory);
}

function printUsage() {
  console.log(
    [
      "Usage:",
      "  prod i        Install backend and frontend dependencies",
      "  prod install  Install backend and frontend dependencies",
      "  prod run      Choose frontend or backend with the arrow keys",
    ].join("\n"),
  );
}

async function main() {
  const command = process.argv[2];

  if (command === "i" || command === "install") {
    return installDependencies();
  }

  if (command === "run") {
    return runApplication();
  }

  if (!command || command === "--help" || command === "-h") {
    printUsage();
    return 0;
  }

  console.error(`Unknown command: ${command}`);
  printUsage();
  return 1;
}

main()
  .then((exitCode) => {
    process.exitCode = exitCode;
  })
  .catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
