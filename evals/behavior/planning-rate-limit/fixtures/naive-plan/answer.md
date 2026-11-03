Here's the plan:

- Install express-rate-limit.
- Add it as middleware with windowMs set to 60000 and max set to 100.
- Use the user ID from the session as the key so limits are per user.
- Deploy and watch the logs.
