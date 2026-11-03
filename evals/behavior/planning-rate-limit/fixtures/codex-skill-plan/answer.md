Plan: Add a shared, per-user limit of 100 accepted API requests per minute, enforced consistently across all three Express instances using PostgreSQL.

Approach: Use a PostgreSQL-backed fixed calendar-minute counter keyed by `(user_id, window_start)`. Each request performs one atomic upsert that increments only while the count is below 100; the result determines whether Express continues or returns `429`. This avoids per-instance limits and works across the load balancer. A rolling 60-second window would be more precise but requires a more complex data model.

Constraints:

- “100 requests per minute per user, then reject.”
- “It's Express on Node”
- “three instances behind a load balancer”
- “Postgres is our only datastore.”

Decide first:

- Fixed calendar minute or rolling 60-second window? Default: fixed calendar minute.
- Which routes count? Default: all authenticated API requests, excluding health/readiness endpoints.
- What happens if PostgreSQL is unavailable? Default: return `503` for protected API requests rather than bypassing the limit.
- Should rejected requests consume quota? Default: no; only accepted requests increment the counter.
- Does the limit apply per authenticated user ID, not IP address? Default: yes.

Out of scope:

- Anonymous/IP-based limiting.
- Different limits by plan, endpoint, or organization.
- Distributed caching or adding Redis.
- Quota dashboards or billing usage reporting.

Task 1: Define the rate-limit data model and retention policy.

Touches: PostgreSQL migrations, database schema documentation.

Provides: A table keyed by `(user_id, window_start)` with an integer request count and a primary key or unique constraint on that pair.

Done when: A migration creates the table and constraint; inserting two rows for the same user and minute is impossible; the schema supports cleanup of old minute buckets.

Task 2: Implement an atomic database operation for consuming one request.

Touches: Database access layer or repository module.

Uses: The table from Task 1.

Provides: `consumeRateLimit(userId, limit) -> { allowed, count, windowStart }`.

Done when:

- Concurrent calls for the same user and minute cannot allow more than 100 requests.
- Calls for different users do not affect one another.
- The database—not application-instance clocks—determines the current minute.
- The operation returns `allowed: false` after the 100th accepted request without incrementing the count for rejected requests.
- A database error is surfaced distinctly from a normal rate-limit rejection.

Task 3: Add authenticated Express middleware at the correct pipeline boundary.

Touches: Authentication middleware ordering, API route registration, rate-limit middleware.

Uses: `consumeRateLimit`.

Provides: Middleware that receives the authenticated user ID, checks the limit before the protected handler, and calls `next()` only when allowed.

Done when:

- An unauthenticated request is handled by the existing authentication behavior.
- Requests from the same user are counted across all three instances.
- Requests from different users have independent limits.
- Health and readiness endpoints are excluded according to the decision above.
- The middleware cannot run before user identity is available.

Task 4: Define the rejection and failure responses.

Touches: HTTP error handling, API response conventions, observability middleware.

Uses: The middleware result from Task 3.

Done when:

- Request 1–100 in a minute proceed normally.
- Request 101 returns HTTP `429`.
- The `429` response includes a stable error shape and `Retry-After` indicating when the current fixed window ends.
- Rejected requests do not execute the downstream handler.
- PostgreSQL failures return the chosen `503` behavior and are distinguishable from `429`.
- Responses do not expose database details.

Task 5: Add cleanup and operational safeguards.

Touches: Scheduled maintenance job or database maintenance process, metrics and logging.

Uses: The rate-limit table from Task 1.

Done when:

- Buckets older than the configured retention period are deleted without blocking normal request traffic.
- Cleanup is safe to run repeatedly and does not delete the active window.
- Metrics distinguish allowed requests, rejected requests, database errors, and cleanup failures.
- Logs use user identifiers safely and do not emit sensitive request data.
- Connection-pool capacity and query latency are monitored under concurrent load.

Task 6: Verify behavior under distributed and failure conditions.

Touches: Unit tests, integration tests, multi-instance or load-test setup.

Uses: Tasks 2–5.

Done when:

- A test sends 101 requests for one user through multiple application instances and observes exactly 100 accepted requests and one `429`.
- Requests straddling a minute boundary follow the documented fixed-window behavior.
- Concurrent requests cannot exceed the limit.
- A second user remains unaffected when the first user reaches the limit.
- Retry behavior matches the `Retry-After` value.
- Database unavailability produces the selected failure response.
- Existing authenticated API behavior remains unchanged below the limit.

Not covered by any check: none. The main risks—concurrency, cross-instance consistency, minute-boundary behavior, database failure, and retry semantics—are assigned above.

Rollout: Deploy the migration first, then the application change; monitor 429 volume, database latency, pool saturation, and error rates before enabling the middleware for all protected routes.