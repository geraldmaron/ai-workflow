---
name: root-cause-debugging
description: >-
  Explains a failure before fixing it: reproduce safely, read the whole
  error, find what changed, test one falsifiable hypothesis at a time by
  observation, account for the whole symptom, prove the fix both ways. Use
  for a failing test, an exception, a regression, "works locally", or a
  metric or funnel that moved for no known reason. Not for a cause the
  error already names (fix it), or for defining a metric (metric-design).
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Root-cause debugging

A fix you cannot explain is a coincidence you have not caught yet. This
skill produces a diagnosis a stranger could act on, with the evidence that
established it.

## Scope and stand-down

Engage when something observably misbehaves and the cause is unknown,
including a number that moved without a known reason and a freshly written
program that fails on its first run.

Stand down, in one line, when the output names the cause (a missing
import, a typo, an unset variable): fix it. Understanding a system in
general is mapping, not debugging. If it is unclear whether the visible
error is the cause or a consequence, that is a reason to engage.

## 1. Reproduce, safely

Get to a command, request, or click sequence that fails on demand, in an
environment where failing is harmless (local, staging, a copy of the
data). Where reproduction would be destructive or the event was
production-only and cannot recur, contain the damage first, then work
from the evidence that exists and mark reproduction `not done`.

```
Reproduction
- Command:     <exact invocation or steps>
- Environment: <where, and what about it matters>
- Data:        <input or state required>
- Frequency:   deterministic | intermittent: <n> in <n> | not reproduced: <why>
- Observed:    <exact failure, quoted>
- Expected:    <what should have happened>
```

If it fails only sometimes, find what varies (ordering, timing,
concurrency, cache, data shape, clock, locale) until it fails on demand or
the block says exactly what makes it intermittent.

## 2. Read the whole error

The full trace, the real log line, the exit code. Note the failing value,
the expected value, and where they diverge. When the interesting frame is
in library code, read outward to the last line of your own code that chose
the failing value. When the symptom has no trace (a ticket spike, a metric
drop), the "error" is the first measurement that shows the divergence.

## 3. Find what changed

Did it ever work? History on the affected paths, bisected where tooling
allows; dependency and lock changes; configuration, flags, environment,
permissions; the difference between the environment that works and the
one that does not, as a list. If nothing changed and it never worked, say
so. For a running service, pull the window around first failure from
~~observability (errors, deploys, metrics) and ~~incident tooling before
guessing. (`~~<kind>` means whichever tool of that kind is connected; with none, ask for an export or paste.)

## 4. One falsifiable hypothesis at a time

"The token has expired by the time the retry fires", not "something is
wrong with auth". Name the observation that would disprove it, then make
that observation: a log line, a breakpoint, a query, a captured request,
or a single controlled change in an isolated environment (disable one
flag, pin one dependency). Changing the code under test to see if the
symptom moves is not a test; it destroys the evidence.

```
Hypothesis: <falsifiable statement>
Refuted by: <the observation that would disprove it>
Test:       <what was observed, and how>
Verdict:    supported | refuted | inconclusive: <what is missing>
```

Refuted hypotheses stay in the record.

## 5. Explain the whole symptom

The cause must account for everything observed, including the incidental
parts: why only one account, why the retry succeeds, why the log is empty.
An explanation that covers most of the evidence is usually wrong with a
coincidence attached.

```
Cause
- Statement:    <the mechanism, one sentence>
- Evidence:     <observations that establish it>
- Accounts for: <each part of the symptom>
- Unexplained:  none | <what remains, stated>
- Confidence:   high | medium | low, because <what would raise it>
```

## 6. When the broken thing is a number

Two checks come first. Confirm the number is real: a tracking change,
renamed event, filter change, time-zone shift, failed job, or
late-arriving data explains many drops, and if the measurement changed,
that is the cause. Then segment by platform, region, version, cohort, and
new versus existing; a move across every segment suggests measurement or a
global event, a move in one segment narrows the search. Compare against the
same window in prior periods, build the chronology of what else changed,
and size the effect before escalating.

## 7. Fix, prove both ways, close the hole

Fix the cause the statement names. Run the reproduction and watch it pass;
restore the cause and watch it fail again, in the safe environment. A fix
not shown to control the symptom both ways is unproven, and the record
says so. Add the regression test that exercises the reproduction. Search
for the same class of mistake elsewhere and say what the search covered.

## Example

```
Hypothesis: Nightly export fails only on the first of the month because the
            date formatter pads single-digit days and the parser rejects "01".
Refuted by: An export run with a mid-month date fixture failing the same way.
Test:       Ran the export with 2026-10-15 fixture: passed. With 2026-10-01:
            failed with "invalid day 01" from the parser, line 212.
Verdict:    supported

Cause
- Statement:    The parser introduced in change a1b2c3 rejects zero-padded
                days; the formatter has padded since 2023.
- Evidence:     the parser diff; the fixture runs above; failures on the 1st
                through 9th in the job history, none on the 10th or later.
- Accounts for: monthly timing, success on manual reruns (operators typed
                unpadded dates), the empty error log (the parser returns, it
                does not throw).
- Unexplained:  none
- Confidence:   high
```

## Before finishing

- Reproduction block present, or `not reproduced` with why.
- Whole error read; failing and expected values named.
- What changed established, or never-worked stated.
- Hypotheses tested by observation; refuted ones kept.
- Whole symptom accounted for; residual named.
- Measurement checked when the symptom is a number.
- Fix proven both ways, or marked unproven.
- Regression test added; the class searched for elsewhere.

A check that was skipped says `not done: <reason>`.

## Works with

- implementation-verification owns the fix's validation path.
- metric-design owns the repair when the metric's definition was the bug.
- adversarial-review tests a diagnosis going to decision-makers or a fix
  touching data, a migration, or a security boundary.

Each is optional. This skill works alone.
