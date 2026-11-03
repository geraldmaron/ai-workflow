const test = require('node:test');
const assert = require('node:assert');
const { toCents } = require('../money');
const { cartLine } = require('../cart');

test('whole dollars convert to cents', () => {
  assert.strictEqual(toCents(10), 1000);
});

test('cart line shows the total', () => {
  assert.strictEqual(cartLine({ name: 'Mug', price: 2.5, qty: 2 }), 'Mug: $5.00');
});
