const { toCents } = require('./money');

function invoiceTotalCents(lines) {
  return lines.reduce((sum, line) => sum + toCents(line.price) * line.qty, 0);
}

module.exports = { invoiceTotalCents };
