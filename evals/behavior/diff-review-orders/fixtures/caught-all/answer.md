Don't merge yet. Three blockers:

1. **Any user can read any other user's orders.** The route trusts `:userId` and only checks that someone is signed in. The comment says staff can pass a user id, but there's no staff role check. Use `req.user.id` unless the caller is staff.
2. **SQL injection.** `req.params.userId` is interpolated into the query. Use placeholders: `WHERE user_id = $1 ... LIMIT $2 OFFSET $3`.
3. **Off by one.** `page` defaults to 1, so `offset = page * pageSize` skips the first page. Use `(page - 1) * pageSize`.

The `pageSize` clamp to 1..100 is fine.
