function toDateOnlyString(value) {
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    const year = value.getFullYear();
    const month = String(value.getMonth() + 1).padStart(2, "0");
    const day = String(value.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }

  if (typeof value === "string") {
    const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(value.trim());
    if (!match) {
      return null;
    }
    const normalized = `${match[1]}-${match[2]}-${match[3]}`;
    const asUtc = new Date(`${normalized}T00:00:00.000Z`);
    if (
      Number.isNaN(asUtc.getTime()) ||
      asUtc.toISOString().slice(0, 10) !== normalized
    ) {
      return null;
    }
    return normalized;
  }

  return null;
}

function todayDateString() {
  return new Date().toISOString().slice(0, 10);
}

function rentalDaysInclusive(pickupDate, returnDate) {
  const start = new Date(`${pickupDate}T00:00:00.000Z`);
  const end = new Date(`${returnDate}T00:00:00.000Z`);
  const days =
    Math.floor((end.getTime() - start.getTime()) / (24 * 60 * 60 * 1000)) + 1;
  return days < 1 ? 1 : days;
}

module.exports = {
  toDateOnlyString,
  todayDateString,
  rentalDaysInclusive,
};
