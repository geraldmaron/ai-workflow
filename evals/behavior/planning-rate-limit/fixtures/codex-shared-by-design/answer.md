## Implementation plan

1. **Define the user identity**
   - Apply the limit only after authentication.
   - Use a stable user ID from the verified session/JWT—not IP address or client-supplied headers.
   - Decide how unauthenticated requests are handled separately.

2. **Choose a distributed Postgres-backed algorithm**
   - Use a fixed one-minute window keyed by `(user_id, window_start)`.
   - Store counters in a table such as:

     `rate_limit_windows(user_id, window_start, request_count, created_at)`

   - Add a unique constraint on `(user_id, window_start)`.

   This works across all three Express instances because Postgres is the shared source of truth.

3. **Make increment-and-check atomic**
   - For every authenticated request, calculate the current UTC minute window.
   - In a single database transaction or atomic SQL operation:
     - Insert the counter row if it does not exist.
     - Increment the counter.
     - Determine whether the resulting count is greater than 100.
   - Ensure concurrent requests for the same user cannot both pass based on stale counts. Use row-level locking or an atomic `INSERT ... ON CONFLICT DO UPDATE` operation.

4. **Define limit semantics**
   - Requests 1–100 in a window are allowed.
   - Request 101 and subsequent requests in that same window are rejected.
   - Decide whether rejected requests increment the counter. Usually they should not, since the user is already over the limit.
   - Document that this is a fixed-window limit, so a user could make up to 200 requests around a minute boundary. If that is unacceptable, use a sliding-window design instead.

5. **Add Express middleware**
   - Place the middleware after authentication and before expensive application work.
   - For each request:
     - Resolve the authenticated user ID.
     - Perform the Postgres rate-limit check.
     - Continue on success.
     - Return `429 Too Many Requests` on failure.
   - Include:
     - `Retry-After`, indicating seconds until the next window.
     - Optionally `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset`.

6. **Handle database failures explicitly**
   - Do not silently bypass the limit if Postgres is unavailable; that could remove protection during an incident.
   - Choose and document a fail-closed or controlled fallback policy. For a security-sensitive API, fail closed for protected endpoints, while returning a suitable `503` rather than misreporting the request as rate-limited.
   - Set a short database timeout so rate limiting does not consume all request capacity.

7. **Manage table growth**
   - Expire or delete old window rows periodically.
   - Options include:
     - A scheduled cleanup job deleting rows older than a short retention period.
     - Time-based partitioning if volume is high.
   - Add an index supporting cleanup by `window_start`.

8. **Account for transaction and connection load**
   - Every request will issue a write, so size the Postgres connection pool appropriately across all three instances.
   - Measure database latency and lock contention.
   - Avoid holding a transaction open while downstream application logic runs; the rate-limit operation should be short and isolated.

9. **Test distributed behavior**
   - Verify that requests distributed across all three instances share one counter.
   - Test concurrent bursts from the same user.
   - Test users independently receive their own 100-request allowance.
   - Test behavior at the minute boundary, retries after `Retry-After`, authentication failures, and Postgres errors.
   - Load-test both the API and Postgres to confirm the limiter does not become the bottleneck.

10. **Roll out safely**
    - Add metrics for allowed requests, rejected requests, database errors, latency, and counts by endpoint/user cohort.
    - Initially run in shadow mode or log-only mode if production behavior is uncertain.
    - Enable enforcement behind a feature flag, then gradually expand coverage.
    - Document the limit for API consumers and support teams.

For this architecture, the simplest production approach is an atomic per-user, per-minute Postgres counter with a unique key, enforced by authenticated Express middleware and returning `429` with `Retry-After`.