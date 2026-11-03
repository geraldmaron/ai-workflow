## Implementation plan

Use a shared PostgreSQL-backed counter so all three Express instances enforce the same limit.

### 1. Define the rate-limit contract

- Limit: 100 requests per authenticated user per minute.
- Identity: use the stable user ID from the verified authentication context—not IP address, email, or session ID.
- Requests above the limit receive:
  - HTTP `429 Too Many Requests`
  - `Retry-After` indicating when the current window resets
  - A consistent JSON error body
- Decide which requests count:
  - Recommended: count requests after authentication but before expensive business logic.
  - Usually exclude health checks, metrics, and unauthenticated login/signup endpoints unless explicitly required.

### 2. Choose the PostgreSQL algorithm

For the stated requirement, use a fixed one-minute window:

- Derive a UTC window key, for example the minute containing the current timestamp.
- Store one counter per `(user_id, window_start)`.
- Atomically increment the counter with PostgreSQL’s `INSERT ... ON CONFLICT DO UPDATE`.
- Only allow the request if the resulting count is `≤ 100`.

This works across all three instances because PostgreSQL provides the shared atomicity and row-level locking.

Be aware that fixed windows allow a burst near a minute boundary—for example, 100 requests at `12:00:59` and another 100 at `12:01:00`. If that is unacceptable, use a sliding-window implementation with smaller time buckets, such as ten six-second buckets, at the cost of more database reads and writes.

### 3. Add a rate-limit table

Create a table containing approximately:

- `user_id`
- `window_start`
- `request_count`
- timestamps for creation/update if useful

Add a composite primary key or unique constraint on:

- `(user_id, window_start)`

Use an appropriate type for `user_id` matching the users table. The window key should be normalized consistently to UTC.

### 4. Implement the Express middleware

Place the middleware in the authenticated API pipeline:

1. Authentication verifies the token/session.
2. Middleware extracts the authenticated user ID.
3. Middleware calculates the current window.
4. Middleware atomically increments or creates the user/window counter.
5. If the new count exceeds 100:
   - Return `429`.
   - Do not execute the route handler.
6. Otherwise, call `next()`.

The increment and limit decision must happen in one database statement or transaction. A separate “read count, then update count” sequence is race-prone across instances.

Consider whether rejected requests should increment the counter. Recommended behavior: once the count reaches 100, subsequent requests are rejected without increasing the stored value beyond 100. This keeps counters bounded and makes metrics easier to interpret.

### 5. Handle database failures explicitly

Since PostgreSQL is part of request admission:

- Choose and document a failure mode.
- Recommended for protected APIs: fail closed if the rate-limit check cannot be completed, returning `503 Service Unavailable`, rather than silently disabling the limit.
- Set a short database statement timeout for the rate-limit query.
- Use the existing connection pool and ensure rate-limit queries cannot exhaust it.
- Avoid opening a separate transaction for every check unless necessary.

If availability is more important than strict enforcement, fail open instead, but emit a high-severity alert whenever rate limiting is bypassed.

### 6. Return useful headers and errors

For successful and rejected requests, consider returning:

- `RateLimit-Limit: 100`
- `RateLimit-Remaining: remaining count`
- `RateLimit-Reset: Unix timestamp or seconds until reset`

For rejected requests:

- `Retry-After: seconds until the next window`
- A stable error code such as `RATE_LIMIT_EXCEEDED`

Ensure the application’s error-handling middleware does not overwrite the intended `429` response.

### 7. Add cleanup and retention

The table will grow indefinitely unless old windows are removed.

Options:

- Periodically delete rows older than a small retention period, such as one or two hours.
- Run cleanup through an existing scheduled-job mechanism or one controlled worker.
- Add an index on `window_start` to support deletion.
- If traffic is very high, consider time-based partitioning later.

Cleanup is not part of correctness, but it is necessary for operational stability.

### 8. Account for PostgreSQL contention

The hot row is per user per minute, so contention is normally limited to users sending many concurrent requests.

Validate:

- The atomic upsert uses the composite key.
- The query has no unnecessary joins.
- The pool has enough capacity for the added query volume.
- The database can sustain approximately one additional write per accepted request.
- High-volume users do not create lock queues that affect unrelated application traffic.

If the API has very high traffic, PostgreSQL-only limiting may become expensive. At that point, a dedicated distributed counter store would usually be preferable, but it is not necessary for the initial design if PostgreSQL capacity is adequate.

### 9. Test the behavior

Include tests for:

- First request in a window.
- Exactly 100 requests allowed.
- Request 101 rejected.
- Counter reset in the next minute.
- Multiple users having independent limits.
- Concurrent requests from the same user, verifying no more than 100 succeed.
- Requests distributed across all three instances.
- Missing or invalid authenticated user identity.
- PostgreSQL timeout or outage behavior.
- Correct `429`, `Retry-After`, and rate-limit headers.
- Cleanup of expired rows.

Load-test concurrent traffic across all instances to verify the database constraint—not application-local state—controls the result.

### 10. Roll out safely

A practical rollout:

1. Add the table and indexes.
2. Deploy middleware in observe-only mode, recording what would have been rejected.
3. Compare projected limits against real user traffic and identify legitimate high-volume clients.
4. Add dashboards and alerts.
5. Enable enforcement behind a feature flag.
6. Roll out gradually by API route, user cohort, or percentage of traffic.
7. Monitor PostgreSQL latency, pool utilization, lock waits, `429` rates, and false positives.

The key design decision is that the rate-limit check must be an atomic PostgreSQL operation keyed by authenticated user ID and UTC minute; instance-local memory would not enforce the limit correctly behind the load balancer.