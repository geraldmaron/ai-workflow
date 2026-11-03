---
name: implementation-verification
description: >-
  Use when implementing a feature or fix, including a bare "fix it" or
  "make this work", refactoring, changing a schema or interface, or asked
  "is this done". A change plus evidence it works, from the project's own
  checks on the real surface. Not for review or research with no code
  change, throwaway scripts, or release readiness (launch-readiness).
license: Apache-2.0
metadata:
  version: 0.2.1
---

# Implementation verification

Generation is not completion. This skill produces a change plus the
evidence that it works, in a form a reader can check without rerunning it.

## Scope and stand-down

Engage when a change lands in a system with a lifespan: committed, shared,
deployed, or run against real data. Auditing a finished change against its
acceptance criteria counts, even with no new code.

Stand down, in one line, when there is no code change, when the code is
disposable, or when a single mechanical edit is already proved by the
compiler, type checker, or linter (run that and move on). If it is unclear
whether code is disposable, it is not. Scale the depth of each step to the
blast radius; never skip a step because the change feels small.

## 1. Inspect before changing

Read, in order and as far as the change warrants: project instructions and
contributor files; design notes for the area; the code paths touched, read
rather than guessed from names; their tests; manifests and lockfiles; the
check configuration and the commands the project really runs for lint,
type-check, test, build. Then name the blast radius: dependencies touched
and every interface, schema, event, or stored shape the change can affect.

## 2. Reuse before inventing

Prefer, in order: existing project capability, shared utility, framework
pattern, a small local implementation, a new dependency. Search for an
existing version before concluding it is absent, and say what you searched.
Do not create a second variant of something that exists; the exception is
a deliberate side-by-side during a migration, with the retirement of the
old one named. Do not ship placeholders or mocks standing in for essential
logic; a requested incremental slice is fine when it is labeled as one.

## 3. Run the project's validation path

Run the commands the project gates on, not a faster subset, and do not
report a narrower command's result as the broader one's. One block per
check:

```
Check:    <what it verifies>
Command:  <the exact command, or the steps for a manual check>
Result:   pass | fail | not run: <why, and the residual risk>
Observed: <what the output said, one line>
```

A project with no validation path gets the closest real check that exists
and a stated gap; the other steps still run. A pass is reported only for a
check that ran and passed.

## 4. Prove the user-visible outcome

Before implementing, write the outcome as one sentence a non-implementer
could check. After, reproduce it on the surface a user touches, with data
shaped like real data (realistic rows through the real interface count; a
unit test of a helper or a stubbed boundary does not).

```
Outcome:  <the sentence, written before implementing>
Surface:  <interface, endpoint, command, or flow exercised>
Data:     <what was used and how it resembles real data>
Observed: <what happened>
Verdict:  proven | not proven: <what could not be run>
```

For a refactor or dependency bump where nothing visible should change, the
outcome is "behaves identically on <surface>" and the proof is the same
observation before and after.

## 5. Look at rendered output

For a change with visible output, render it and check layout, text
wrapping, empty and error states (first, not last), focus and contrast,
each supported theme, console errors. If nothing here can render it, say
so, name what went uninspected, and mark the step `not done`. Where the
project has screenshot comparison, run it and read the differences; it
does not replace the state and access checks.

## 6. Review the diff before calling it done

Read the full diff as a reviewer would. Remove accidental edits and debug
remnants. Check naming, error handling, security posture, and
compatibility on every touched interface. Compare against the acceptance
criteria line by line. State the residual risk in one sentence. A change
to a schema, security boundary, stored data, or public interface passing
its checks proves it works, not that it should ship; raise that
separately.

## Example

A refactor that replaces a hand-rolled retry loop with the project's shared
retry helper:

```
Check:    unit and integration tests
Command:  npm test
Result:   pass
Observed: 212 passed, 0 failed, 0 skipped

Outcome:  Export requests that hit a transient 503 still complete, with the
          same number of retries and delays as before the change.
Surface:  POST /exports against the staging API with the upstream stubbed to
          fail twice then succeed
Data:     a real tenant's export payload from staging, 1,400 rows
Observed: 3 attempts logged at 0 s, 2 s, 4 s before and after; response
          identical; file row count 1,400 both times
Verdict:  proven
```

## Before finishing

- Project inspected; blast radius named.
- Reuse searched; what was searched and found stated.
- Validation path run; one block per check.
- Outcome observed on the real surface; proof block present.
- Rendered output inspected, or `not done` with what was missed.
- Diff reviewed against acceptance criteria.
- Residual risk stated; `not proven` appears in the summary when it applies.

## Failure modes

- Writing plausible code without reading the project.
- A second helper, component, or config that drifts from the first.
- A green unit test reported as the user-visible outcome.
- Remembering or expecting a result and reporting it as observed.
- A narrower command reported as the project's gate.

## Works with

- root-cause-debugging owns the diagnosis when a check fails for an unknown
  reason; do not patch toward green.
- commit-and-pr owns the commit message and PR body afterwards.
- adversarial-review owns the challenge when the change alters a
  load-bearing decision.

Each is optional. This skill works alone.
