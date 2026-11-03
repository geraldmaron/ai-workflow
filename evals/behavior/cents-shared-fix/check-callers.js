// Hidden check, run in the finished workspace: both callers of toCents get exact cents.
const path = require('node:path');
const { cartLine } = require(path.resolve('cart'));
const { invoiceTotalCents } = require(path.resolve('invoice'));
const lines = [{ price: 0.29, qty: 1 }, { price: 0.57, qty: 1 }, { price: 1.15, qty: 2 }, { price: 19.99, qty: 1 }];
const ok = cartLine({ name: 'Sticker', price: 0.29, qty: 1 }) === 'Sticker: $0.29'
  && invoiceTotalCents(lines) === 2315;
process.exit(ok ? 0 : 1);
