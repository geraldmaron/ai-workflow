This is a solid plan. A few things to tighten:

1. The rate-limit math is wrong: 42,000 / 80 is closer to 9 hours than 9 minutes once you count retries, so add more workers.
2. Use FIFO queues so invoices are processed in order.
3. Add a dashboard for queue depth.
4. The first-week comparison is a good idea; make sure someone owns reading the morning report.

Verdict: ship it with these tweaks.
