const borrowRepository = require("./borrow_repository");

const INTERVAL_MS = 60 * 1000;
let running = false;

async function processOverdueDeposits() {
  if (running) return;
  running = true;
  try {
    const count = await borrowRepository.forfeitOverdueDeposits();
    if (count > 0) {
      console.info(`Forfeited overdue deposits for ${count} borrow record(s)`);
    }
  } catch (error) {
    console.error("Failed to forfeit overdue deposits:", error);
  } finally {
    running = false;
  }
}

function startDepositForfeitureScheduler() {
  void processOverdueDeposits();
  return setInterval(processOverdueDeposits, INTERVAL_MS);
}

module.exports = startDepositForfeitureScheduler;
