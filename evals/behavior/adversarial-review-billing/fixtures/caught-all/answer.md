The biggest problem is that the plan can charge customers twice, and step 5 makes that likely.

**1. Double charges (critical)**
- **Step 5 runs two charging systems at once.** For a week, the old cron and the new workers both charge the same invoices at 02:00 unless something stops them. "Compare the results" doesn't prevent that. Run the new workers in shadow mode (decide and log, but don't call the charge endpoint) or have the old cron skip any invoice the queue has claimed. Don't let both charge.
- **Step 3 retries after a timeout, and a timeout doesn't mean the charge failed.** The processor may have captured the money before the response was lost. A retry then charges again. Every charge needs an idempotency key derived from the invoice (for example, invoice ID plus billing period), not from the attempt. Confirm the processor honors keys and for how long.
- **A crash between the charge and the Postgres update causes the same problem.** The invoice stays unpaid, so the redelivered message charges it again. Record "charge attempted" before calling the processor, and reconcile any "unknown" state against the processor before retrying.
- **SQS standard queues are at-least-once.** Duplicate deliveries happen even without failures. The visibility timeout must exceed the worst-case charge plus DB write time, or two workers will process the same invoice.
- **The worker should re-check the invoice before charging.** It may have been paid, voided, refunded, or disputed since the 02:00 snapshot.

**2. Rate limit headroom**
- The arithmetic is right (42,000 / 80 = 525 s), but 80/s uses 80% of the account's 100/s. That leaves 20/s for everything else, including the old cron in week one. Together they can exceed 100/s and get 429s.
- What does a 429 do in the plan? If it counts as a failed attempt, five 429s in a row send a healthy invoice to the DLQ. Rate-limit errors need backoff, not a retry that burns an attempt.
- "20/s per worker" needs real concurrency. At 1s latency, one worker needs about 20 calls in flight. If each worker is single-threaded, the actual throughput is far lower. Measure it.
- The 9-minute estimate covers only the happy path. Add retries, timeouts, and backoff, then check the result against the one-hour window and against projected growth.

**3. Failure handling**
- **A processor outage burns every message's attempts.** If the processor is down for 20 minutes, all 42,000 messages can hit 5 attempts and land in the DLQ. Add a circuit breaker that pauses the consumers, or delay retries instead of counting them.
- **Declines are not timeouts.** A declined card is a terminal result, not a retryable error. Retrying it five times may hurt you with the processor and card networks. Route declines to a separate path.
- **The DLQ has no owner.** Write down who processes it, how messages get redriven, and that DLQ retention is at least as long as the main queue's.
- **The scheduler is the same single point of failure as the cron box.** If it dies after enqueuing half the invoices, the plan has the same "half billed" problem it was meant to fix. Make enqueueing idempotent and restartable.

**4. Monitoring and verification**
- DLQ depth above zero and error rate above 1% don't catch a stalled queue. Add queue age (oldest message), and a morning check that compares invoices due with invoices charged and paid.
- "Compare the two systems" needs a definition. Compare both against the processor's settlement report, not against each other. Otherwise you can't tell which system is wrong.

**5. Rollback**
- Keep the cron path behind a flag, for weeks after the switch, not just until it's off. Write the rollback steps down before the cutover.

**What I'd bring to the team:** the idempotency design (items 1a–1c) and a decision on shadow mode versus live parallel running. Those two decide whether week one is safe at all, and the rest can be worked out after.