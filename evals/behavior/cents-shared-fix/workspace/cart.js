const { toCents } = require('./money');

function cartLine(item) {
  const cents = toCents(item.price) * item.qty;
  return `${item.name}: $${(cents / 100).toFixed(2)}`;
}

module.exports = { cartLine };
