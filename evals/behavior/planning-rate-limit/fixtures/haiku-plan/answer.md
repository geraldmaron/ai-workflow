# Implementation plan: per-user rate limiting (100 req/min, reject over limit)

**Note:** The working directory is an empty git repo with no tracked files, so this plan is based on your description. Check the assumptions in section 1 against the real codebase before starting.

## 1. Assumptions and open questions

Decide these first, because they change the design:

- **Identity:** Is the user ID available from verified auth middleware on every rate-limited route? The limiter must run after auth, and keying on IP is not the plan.
- **Scope:** Which routes count? I'd limit all authenticated API routes and exclude health checks and preflight `OPTIONS`. Unauthenticated routes need a separate decision, since keying them by IP adds another write load to Postgres.
- **Burst tolerance:** A fixed one-minute window allows up to 200 requests across a window boundary (100 at the end of one minute, 100 at the start of the next). If that's unacceptable, use the sliding-window approximation in section 3.
- **Failure policy:** If Postgres is slow or down, does the API fail open (allow requests) or fail closed (reject them)? I recommend fail open with a short timeout, plus an alert.
- **Peak request rate:** Every request becomes a Postgres write, so the peak rate sets the write load. Get a realistic number before committing.
- **Batch or expensive endpoints:** Should any endpoint consume more than one unit?
- **Stack details:** Express version (4 and 5 differ in async error handling), the existing error response format, and the logging and metrics stack.

## 2. Storage design

- One table keyed by `(user_id, window_start)` with a `count` column. Use a single clock source for window start, either Postgres `now()` or a truncated timestamp, so the three instances agree on window boundaries.
- Mark the table `UNLOGGED`. Rate-limit counters are disposable: a crash resets them, which is acceptable, and it avoids most of the WAL cost of the write volume.
- Add an index on `window_start` so the cleanup job can delete old windows efficiently.
- Cleanup: a periodic job (or `pg_cron`) deletes windows older than a couple of minutes, in batches. Without it the table grows with every active user every minute.

## 3. Algorithm

- **Primary option (fixed window):** One atomic upsert per request, inserting the row for the current window or incrementing its count, and returning the new count. Allow the request if the count is at or below 100; otherwise reject. Because the increment is a single statement, concurrent requests across all three instances can't overshoot the limit.
- **Sliding-window option:** In the same round trip, read the previous window's count and weight it by the fraction of the previous window still inside the last 60 seconds. Still one statement, slightly more complex, and it smooths the boundary burst.
- **Rejected:**
  - *Per-instance in-memory limits:* With three instances behind a load balancer, each one sees a fraction of a user's traffic, so the limit is wrong.
  - *Sticky sessions:* Fragile, and it breaks when an instance restarts.
  - *Read-then-write with `SELECT ... FOR UPDATE`:* Two round trips and more lock contention than the upsert.

## 4. Express integration

- Mount the limiter as middleware after authentication and before the routes it covers.
- Make the limiter async-safe. On Express 4, wrap it so database errors reach the fail-open handler instead of hanging the request.
- Set a statement timeout on the limiter's query, so a slow database can't add unbounded latency. Start around 50–100 ms and tune it from metrics.
- Make the limit and window configurable through environment variables, with defaults of 100 and 60 seconds.

## 5. Response contract

- **Rejected requests:** Return `429` with a `Retry-After` header giving the seconds until the window resets, and a body in the API's existing error format.
- **Allowed requests:** Optionally include the standard `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` headers. Clients find these useful, and they make the limit visible during testing.
- Document the contract for API consumers, including the 429 behavior and retry guidance.

## 6. Rollout

1. **Migration and cleanup job** in staging, with the table and cleanup verified.
2. **Limiter module** and unit tests for the window math, the fail-open path, and the config defaults.
3. **Shadow mode:** Compute the decision and log or metric "would reject," but don't enforce. Run this in staging, then production, to see how many real users would be affected.
4. **Enforce** for a small slice of traffic if your deployment supports it, then fully.
5. **Monitor:** rejection rate per user (watch for legitimate heavy users), limiter latency (p50/p99), fail-open count, and Postgres CPU, connections, and write rate.

## 7. Testing

- **Concurrency test against real Postgres:** Fire, say, 150 simultaneous requests for one user and assert exactly 100 are allowed. This is the test that proves the atomicity claim.
- **Multi-instance test:** Run three app processes behind a simple round-robin, send a user's traffic through all of them, and check that the total allowed is 100.
- **Boundary test:** Verify the reset behavior at the window edge.
- **Failure test:** Stop or slow the database and confirm the fail-open policy and the timeout.
- **Load test:** Measure the added latency and the database load at your expected peak.

## 8. Main risks

- **Write amplification:** The limiter adds one write per request to the same database that serves the application. This is the biggest risk. Measure it in the load test, and size the connection pool to account for the extra queries.
- **Hot rows:** A single very active user contends on one row. The transactions are tiny, so this is usually fine, but watch lock waits.
- **Cleanup lag:** If the cleanup job stops, the table grows and the index slows down. Alert on table size.
- **Shared accounts:** If many people or services share one user ID, 100 per minute may be too tight. That's a product question to settle before enforcing.

If you answer the open questions in section 1, I can turn this into a concrete ticket breakdown, or check it against the real codebase once you point me at it.