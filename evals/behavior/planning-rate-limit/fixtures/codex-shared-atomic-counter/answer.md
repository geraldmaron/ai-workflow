## Implementation plan

1. **Define the limiting semantics**

   Use a fixed one-minute window per authenticated user:

   - Limit: 100 accepted requests per user per UTC minute.
   - Request 101 in the same window receives `429 Too Many Requests`.
   - The counter resets at the next minute boundary.

   Note that fixed windows can allow a burst of up to 200 requests across a boundary. If “100 requests in any rolling 60-second period” is required, use a sliding-window design instead.

2. **Identify the user**

   Run rate limiting after authentication middleware so every request has a trusted, canonical `user_id`.

   - Do not use client-supplied user identifiers.
   - Decide whether health checks, internal service calls, webhooks, or admin traffic should be exempt.
   - Define behavior for unauthenticated requests separately, if applicable.

3. **Store counters in PostgreSQL**

   Add a table keyed by user and window:

   - `user_id`
   - `window_start`
   - `request_count`
   - `created_at` / `updated_at`
   - Unique constraint on `(user_id, window_start)`

   Use PostgreSQL time or a consistently computed UTC window so the three Node instances cannot disagree due to clock differences.

4. **Perform an atomic increment**

   Each request should execute one atomic database operation that:

   - Creates the counter row if it does not exist.
   - Increments the count only when it is currently below 100.
   - Returns whether the increment succeeded and the current count.
   - Rejects when the count is already 100.

   The operation must be concurrency-safe under simultaneous requests from different API instances. Avoid a separate “read count, then update count” sequence, since that would allow races.

5. **Place the middleware appropriately**

   Recommended order:

   1. Request correlation/logging
   2. Authentication
   3. Per-user rate-limit check
   4. Route handler

   Do not perform expensive application work before the rate-limit decision.

6. **Return a consistent rejection response**

   For rejected requests:

   - Status: `429 Too Many Requests`
   - Stable JSON error shape, such as an error code indicating rate limiting.
   - Include `Retry-After`, calculated until the next window.
   - Optionally include standard rate-limit headers such as limit, remaining, and reset time.

   Ensure rejected requests do not increment the counter further.

7. **Define database failure behavior**

   Because PostgreSQL is the shared source of truth, decide explicitly what happens if it is unavailable:

   - **Fail closed:** reject requests when the limiter cannot be checked; protects the API but can cause an outage.
   - **Fail open:** allow requests and emit an alert; preserves availability but bypasses the limit.

   For most user-facing APIs, use a configurable policy with fail-closed for sensitive or expensive endpoints and fail-open only where availability is more important.

8. **Add cleanup**

   Old window rows will accumulate. Add a scheduled cleanup job or maintenance task that deletes rows older than a small retention period, for example several hours or a few days.

   Cleanup should be batched and independently observable so it cannot interfere with request handling.

9. **Add observability**

   Track:

   - Requests allowed and rejected by user or endpoint class.
   - Rate-limit database latency and errors.
   - Number of users hitting the limit.
   - Fail-open/fail-closed decisions.
   - PostgreSQL table size and cleanup duration.

   Avoid logging sensitive identifiers directly; hash or otherwise redact user IDs where appropriate.

10. **Test concurrency and deployment behavior**

   Include tests for:

   - 100 successful requests, followed by a 429.
   - Reset at the minute boundary.
   - Multiple users having independent limits.
   - Concurrent requests near the limit.
   - Requests distributed across all three instances.
   - PostgreSQL errors and configured fallback behavior.
   - Correct `Retry-After` and response headers.
   - Cleanup of expired windows.

   Load-test several instances behind the load balancer to confirm that exactly 100 requests are accepted per user per window under contention.

11. **Roll out safely**

   - Deploy the schema and indexes first.
   - Initially run the limiter in shadow mode, recording would-be rejections without blocking.
   - Compare results with expected traffic and identify automation or internal clients that need exemptions.
   - Enable enforcement behind a feature flag.
   - Roll out gradually and monitor 429 rates, database load, and latency.

This design uses PostgreSQL for the shared atomic counter, so behavior remains consistent across all three Express instances without requiring Redis or another datastore.