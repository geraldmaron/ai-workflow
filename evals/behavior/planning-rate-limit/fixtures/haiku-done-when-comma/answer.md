# Plan: per-user rate limit, 100 requests/minute, shared across three instances

**Approach:** Store one token bucket per user in a Postgres row and update it with a single atomic upsert, so all three instances see the same count. All timestamps come from Postgres `now()`, so instance clock skew doesn't matter. Rejected alternatives:
- **In-memory per instance:** the load balancer spreads one user across all three, so the effective limit is up to 300/min.
- **Sticky sessions:** depends on LB configuration and breaks when an instance goes away.
- **Fixed-window counter in Postgres:** allows 200 requests across a minute boundary.
- **Redis:** would add a datastore, which you ruled out.

**Constraints (from the request, verbatim):**
- "100 requests per minute per user, then reject."
- "Express on Node."
- "three instances behind a load balancer."
- "Postgres is our only datastore."

**Decide first:**
1. Algorithm: token bucket, capacity 100, refill 100/min. This allows an instant burst of 100, then steady refill. Default: token bucket. Alternative: fixed window per calendar minute, which is simpler but allows a 200-request burst across a boundary.
2. Postgres unreachable: fail open (allow the request, log it, count it). Default: fail open, so a limiter outage doesn't take the API down. Alternative: fail closed.
3. Requests with no user identity (login, health, public routes): not limited. Default: not limited. Per-IP limits would be a separate decision.
4. Do rejected requests cost a token? Default: no.
5. Expected peak request rate across all instances. Default: 500 req/s [assumed]. Tasks 3 and 6 are sized to this number, so it must be confirmed.

**Out of scope:** per-IP or unauthenticated limits; per-endpoint limits; daily quotas; any new datastore; client-side retry behavior beyond the `Retry-After` header.

---

**Task 1: The bucket table exists in every environment.**
- Touches: a new migration in the project's migration directory
- Uses: nothing
- Provides: table `rate_limit_buckets` with `user_id` (primary key, same type as `users.id` [assumed]), `tokens` (fractional), `updated_at` (timestamptz)
- Done when: the migration applies and rolls back cleanly on a fresh local database and on staging, and the table appears in `\d` output.

**Task 2: One atomic call consumes a token or reports denial.**
- Touches: `lib/rateLimitStore.js`, `test/integration/rateLimitStore.test.js`
- Uses: the table from Task 1
- Provides: `consume(userId, {capacity, refillPerSec})` → `{allowed, retryAfterSec}`. It is one statement, all times from `now()`, and the refill rate is a parameter so tests can turn refill off.
- Done when, against a real Postgres:
  - (a) a new user gets `capacity` allowed calls, and the next call is denied;
  - (b) with `refillPerSec: 0`, 150 parallel calls for a brand-new user yield exactly 100 allowed;
  - (c) setting the app's clock one hour off changes no result;
  - (d) after 100 allowed and 1 denied, one second at 1 token/s allows exactly one more, which shows denied calls spent nothing.

**Task 3: The store sustains peak load before any HTTP code depends on it.** This is the riskiest assumption, so it comes early.
- Touches: a throwaway benchmark script under `scripts/`, not shipped
- Uses: `consume` from Task 2
- Provides: nothing
- Done when: against a staging-sized Postgres, `consume` sustains the Decide-first #5 rate for 10 minutes with p99 under 10 ms [assumed] and zero pool-acquire timeouts. If it fails, stop and revisit the approach before Task 4.

**Task 4: Express middleware enforces the limit, mounted after auth.**
- Touches: `middleware/rateLimit.js`, `app.js` (mount order), config
- Uses: `consume` from Task 2
- Provides: the middleware. Denials return 429 with a JSON body and an integer `Retry-After` of at least 1 second, rounded up. Each denial and each fail-open increments a counter and logs one line.
- Done when, with supertest:
  - 100 requests return 200 and the 101st returns 429 with a valid `Retry-After`;
  - a store that throws yields 200 for the request, plus one log line and one counter increment;
  - a request with no user identity passes through unlimited (per Decide-first #3).

**Task 5: Three real instances enforce one shared limit.**
- Touches: staging deployment config (three replicas behind the LB), `scripts/e2e-rate-limit.sh`
- Uses: the middleware from Task 4
- Provides: nothing
- Done when: 150 requests for one user through the staging LB return exactly 100 2xx and 50 429s, and all three instances served some of the 429s. Three instances each allowing 100 would show 300 accepted, which is the failure this catches.

**Task 6: The limit holds at peak and a hot user doesn't slow others.**
- Touches: staging, the load script from Task 5
- Uses: the full stack from Tasks 4–5
- Provides: nothing
- Done when:
  - at the Decide-first #5 rate for 15 minutes, p95 latency added by the limiter stays under 5 ms [assumed] versus a limiter-off baseline, Postgres CPU stays under 60% [assumed], and there are zero pool-acquire timeouts;
  - one user driven at 2× the limit does not raise p95 for a second user at normal rate, which shows the per-user row lock stays local.

---

**Not covered by any check:**
- Rolling deploy with mixed versions: instances without the limiter serve traffic until the rollout finishes, so the limit is not enforced during it. Not tested by any task.
- Real Postgres failover mid-request: Task 4 tests the fail-open path with a throwing stub, not an actual primary switch.
- Client retries count as requests, and every retry spends a token. This is intended under Decide-first #4 but has no check; decide whether to document it.
- Table growth: one row per user, with no cleanup job. Growth is bounded by user count. No check is needed unless user deletion is common.

**Rollout:** Ship behind a flag in log-only mode (count would-be denials, reject nothing) for one week, then enforce. Hand the rollout gate to launch-readiness.

---

I did not read the repository. The plan assumes the existing auth middleware, the migration tool, and the `users.id` type are as described, and those assumptions are marked `[assumed]`. Confirm them before Task 1 is written, and answer the five Decide-first questions, since the defaults are my picks.