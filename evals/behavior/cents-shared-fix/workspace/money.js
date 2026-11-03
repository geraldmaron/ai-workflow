// Converts a dollar amount to integer cents.
function toCents(amount) {
  return Math.floor(amount * 100);
}

module.exports = { toCents };
