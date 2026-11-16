const MAX_ASSET_AMOUNT_CENTS = 9_999_999_999;
const MAX_STORED_AMOUNT_CENTS = 999_999_999_999;

function parseAmountCents(value) {
  const raw =
    typeof value === "string"
      ? value.trim()
      : typeof value === "number" && Number.isFinite(value)
        ? String(value)
        : "";
  if (!/^\d+(?:\.\d{1,2})?$/.test(raw)) {
    return null;
  }

  const [whole, fraction = ""] = raw.split(".");
  const cents = Number(whole) * 100 + Number(fraction.padEnd(2, "0"));
  return Number.isSafeInteger(cents) ? cents : null;
}

function formatAmountCents(cents) {
  if (!Number.isSafeInteger(cents) || cents < 0) {
    throw new RangeError("Amount cents must be a non-negative safe integer");
  }
  return `${Math.floor(cents / 100)}.${String(cents % 100).padStart(2, "0")}`;
}

function amountCentsToNumber(cents) {
  return Number(formatAmountCents(cents));
}

module.exports = {
  MAX_ASSET_AMOUNT_CENTS,
  MAX_STORED_AMOUNT_CENTS,
  amountCentsToNumber,
  formatAmountCents,
  parseAmountCents,
};
