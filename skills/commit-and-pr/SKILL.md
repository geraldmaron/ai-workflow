---
name: commit-and-pr
description: >-
  Shapes a commit or pull request another person will read later: read the
  diff first, one logical change per commit, a message that says why, no
  secrets, a branch off the shared default, and a PR body for a reviewer
  who has not seen the work. Use when committing, branching, or opening a
  PR. Not for scratch commits that will be squashed; a repository's own
  message format wins, the other checks still apply.
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Commit and pull request

Produces commits that can be bisected and reverted on their own, and pull
requests a reviewer can judge from the description.

## Scope and stand-down

Engage before any commit that will outlive the conversation: anything on a
shared branch, anything reviewed, anything someone may bisect or blame.

Stand down, in one line, for scratch commits on a private branch that will
be squashed. Where the repository enforces a message format (a linter, a
template, changelog automation), that format wins over the shape below;
the diff read, scoping, secrets check, and push rule still apply. If it is
unclear whether a change is scratch or shared, treat it as shared.

## 1. Read the diff you are about to commit

The full diff, not a summary. Stage deliberately, by file or hunk, when the
working tree holds more than one concern. Debug prints, commented-out
experiments, unrelated formatting, local config, and generated files get
committed by accident and never survive review well.

## 2. One logical change per commit

If the message needs "and" to describe what changed, check whether it is
two changes. A refactor and a behavior change land separately, refactor
first. Edits that only make sense together (add a column and backfill it)
stay together; the test is whether each commit leaves the tree usable.

## 3. Never commit what cannot be removed

Secrets, tokens, connection strings, real user data. A later deletion does
not remove them from history: say so, treat the secret as compromised, and
say it needs rotation.

## 4. Branch off a shared default

On the default branch with a change that is not trivially yours alone to
push, create a branch first. Where the repository has no branch
convention, name the branch for what it is for, not for a date or a
person.

## 5. The commit message

```
<Imperative summary, about 72 characters, saying what the change does>

<Why it exists: what was happening before, what a reviewer would otherwise
reconstruct from the diff. Skipped only when the subject says everything.>
```

The subject describes the change, not the process ("Reject expired tokens
on refresh", not "fix bug" or "address review"). No attribution trailer
naming an assistant or automated tool. A trailer the repository requires
(a sign-off, an issue reference) is part of its convention and stays.

Example:

```
Reject expired tokens on refresh

The refresh endpoint compared expiry against the session's first token
instead of the one presented, so an old refresh token kept working as long
as a newer one had been issued that day. Compares against the presented
token's own expiry.
```

## 6. The pull request body

Written for a reviewer with no other context. Scale it to the change: a
one-line fix needs the first and last sections only.

```
## What changes and why
## How to verify        <the commands or steps actually run>
## Left out             <deliberately not done, and why>
## Risk and rollback    <what could go wrong, how it is reverted>
## Tested               <what was exercised and what was not>
```

Understating coverage is safe. Overstating it costs the reviewer's trust
on the next description. Link the issue or decision the change came from.

## 7. Commit and push only when asked

Do not push to a shared branch, force-push, or bypass a commit or push gate
on your own judgment. If a gate looks wrong, say so and hand the decision
to whoever owns it.

If the diff cannot be read in this environment (a web editor showing only
a branch comparison, for instance), say so and record which checks were
not possible.

## Before finishing

- Diff read in full before staging was final.
- One logical change, or the split explained.
- No secrets or real user data in the diff.
- Not committed straight to a shared default branch without reason.
- Message shaped as above or as the repository requires.
- PR body shaped as above, scaled to the change, with an honest tested
  line.
- Pushed only because it was asked for.

A check that was skipped says `not done: <reason>`.

## Works with

- implementation-verification runs before this skill; this skill describes
  a change, it does not make it correct.
- adversarial-review runs before the PR opens when the diff touches a
  security boundary, a migration, stored data, or a public interface.

Each is optional. This skill works alone.
