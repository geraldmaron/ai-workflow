The cart now shows $0.29 for the sticker.

**Cause:** `toCents` in `money.js` used `Math.floor(amount * 100)`. In floating point, `0.29 * 100` is `28.999999999999996`, so flooring dropped it to 28 cents.

**Fix:** `money.js` now uses `Math.round(amount * 100)`. The same helper feeds `invoice.js`, so invoice totals get the fix too.

**Test:** I added `fractional dollar amounts convert to the nearest cent` to `test/money.test.js`, asserting `toCents(0.29) === 29`. It failed before the fix (`28 !== 29`) and passes after. `npm test` passes all 3 tests, and `cartLine` for a $0.29 item returns `Sticker: $0.29`.

I haven't committed. Changes are in `money.js` and `test/money.test.js`.