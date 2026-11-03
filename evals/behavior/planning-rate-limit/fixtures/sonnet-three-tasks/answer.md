Plan: Reject a user's requests with 429 once they exceed 100 in a minute, counted correctly across all three instances.

The repo has no application code (one "base" commit, no files), so everything below about your existing app is `[assumed]`.

**Approach:** Keep a per-user counter in Postgres and bump it atomically on each request, as one `INSERT ... ON CONFLICT DO UPDATE ... RETURNING count` keyed on `(user_id, window_start)`. The window start comes from the database clock, so instance clock skew can't matter. Postgres is the only store shared by all three instances, so it is the only place a single count can live.
- Rejected: an in-memory limiter such as `express-rate-limit`'s default store. Unless the load balancer pins users to instances, each instance counts separately and the real limit becomes up to 300/min.
- Rejected: Redis. It is a new datastore and you said Postgres is the only one.
- The cost is one Postgres write per authenticated request. Task 1 measures whether that's acceptable before anything else is built.

**Constraints:**
- 100 requests per minute per user, then reject
- Express on Node
- Three instances behind a load balancer
- Postgres is the only datastore

**Decide first:**
1. Fixed or sliding window? Default: fixed one-minute window. A user can burst up to 200 requests across a window boundary. A sliding-window counter (current and previous bucket, weighted) fixes that at the cost of a more complex query.
2. If Postgres is unreachable, allow or block requests? Default: fail open and log loudly. Blocking turns a rate-limiter outage into a full API outage.
3. Is the user identified before the limiter runs, and what happens to unauthenticated requests? Default: the limiter runs after auth middleware and keys on the user id. Unauthenticated requests are not limited here, and per-IP limiting is a separate piece of work.
4. Do any endpoints need exemption, such as health checks or webhooks? Default: exempt `/health` only.
5. What is current peak API traffic? Default: under about 500 authenticated requests per second in total, which Postgres can absorb as single-row upserts. Above that, Task 1 will likely fail and the design needs revisiting.

**Out of scope:**
- Per-IP or unauthenticated limiting
- Per-endpoint or tiered limits
- Moving the limiter to the load balancer or an API gateway
- A dashboard for limiter metrics

**Task 1: A Postgres counter that increments atomically and survives load.**
- Touches: a new migration creating `rate_limit_counters(user_id, window_start, count, PRIMARY KEY (user_id, window_start))`, and `lib/rateLimitStore.js`
- Uses: the existing pg pool `[assumed]`
- Provides: `hit(userId) -> Promise<{count: number, windowStart: Date, resetsInSec: number}>`
- Done when:
  - A test fires 250 concurrent `hit()` calls for one user from three separate processes. The returned counts are exactly 1 to 250 with no duplicates or gaps.
  - A load test at your expected peak requests per second shows p99 `hit()` latency under 10 ms on production-like hardware and no pool exhaustion. If it fails, stop and revisit the design before Task 2.

**Task 2: Express middleware that rejects the 101st request in a window.**
- Touches: `middleware/rateLimit.js`, the app's middleware chain after auth
- Uses: `hit(userId)` from Task 1, and `req.user.id` `[assumed]`
- Provides: `rateLimit({limit = 100, exempt = []})`, an Express middleware
- Done when:
  - An integration test sends 100 requests as user A, all returning 200, and the 101st returns 429 with a `Retry-After` header.
  - User B is unaffected during that test.
  - Requests 1 to 100 carry `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset` headers.
  - The first request in the next minute returns 200.
  - If Decide-first #2 is fail-open: with the Postgres pool stopped, requests return 200 and an error is logged.

**Task 3: The limit holds across all three instances, and old rows are cleaned up.**
- Touches: a cleanup job (a scheduled `DELETE FROM rate_limit_counters WHERE window_start < now() - interval '10 minutes'`), deploy config
- Uses: `rateLimit` from Task 2
- Provides: nothing
- Done when:
  - Against a staging environment with all three instances behind the load balancer, 150 requests as one user (spread however the load balancer chooses) return exactly 100 successes and 50 429s.
  - The cleanup job runs on only one instance at a time, via an advisory lock or a single scheduler, and the table row count stays flat over 30 minutes of traffic.

**Not covered by any check:**
- The fixed-window boundary burst of up to 200 requests in about 2 seconds. This is accepted under the default for Decide-first #1. If you choose sliding, Task 1 owns the check.
- A hot row for one very busy user, such as a service account making 1,000 requests per second. Task 1's load test should include one such user. If it serializes badly, exempt service accounts or give them a separate limit.
- Bloat on the counters table from frequent updates and deletes. Task 3's flat row count covers rows, not dead tuples, so check autovacuum settings on this table.
- Retry storms, where clients that get 429 retry immediately. `Retry-After` in Task 2 is the only mitigation here.
- Clients behind a shared account, where one user id is a whole company. The limit applies to them as written.

**Rollout:** Ship with a log-only mode first (count and log what would be rejected, but never return 429) for a few days, then enforce. For anything beyond that, hand it to launch-readiness.