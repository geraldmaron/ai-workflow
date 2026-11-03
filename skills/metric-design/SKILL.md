---
name: metric-design
description: >-
  Use when choosing a North Star, writing or fixing KRs, defining
  "active", or setting success criteria. A metric definition a team can be
  held to, with its counter-metric. Not for explaining why a number moved
  (root-cause-debugging) or evidencing your own work (impact-measurement).
license: Apache-2.0
metadata:
  version: 0.2.1
---

# Metric design

Metric systems fail when nobody in the room can move the number, or when
it can be moved without the product getting better. This skill produces
the parts of a measurement system the request needs, each written down
before it gets a chart.

## Scope and stand-down

Engage when a number is about to carry weight: a target, an objective, a
success criterion, a board slide, or when two people mean different things
by the same word.

Stand down, in one line, for a throwaway measure nobody will be held to,
and for a metric tree before product-market fit, where the numbers are too
small to carry it (definitions are still fine). A number that moved and
nobody knows why is debugging; a number suspected of being gamed is
debugging first and redesign second.

Do only the parts the request needs. A request to define "active" needs
step 5 and perhaps step 4; a North Star request needs steps 1 to 5; a KR
rewrite needs step 6.

## 1. State the value exchange

```
Value exchange: the user gets <X>, and we capture <Y> when they do.
```

Then test each candidate metric: can it rise while X does not happen? Every
proxy can, somewhat; the question is how cheaply. A metric that rises
cheaply without X measures capture, not value. Document the known gap for
a metric kept despite it.

## 2. Pick one output metric, or name another frame

Four tests: rising means users got more of what they came for; this team's
work can plausibly move it; it moves within a planning cycle; it is one
number. Prefer a unit of value and a frequency ("weekly accounts
completing a paid transfer") over a count ("transfers").

```
Output metric: <name>
  value proxy: <why rising means value delivered>
  movable by:  <this team's levers>
  sensitivity: moves within <n> weeks
  rejected:    <candidate>: fails <which test>
Frame: output metric | experience quality (goals, signals, metrics) | funnel stages
```

For experience quality on an existing surface, use goals-signals-metrics
with task success as the output; for a leaky funnel, use stage
decomposition. When another frame is chosen, steps 3 and 4 apply to its
signals or stages instead of to inputs.

## 3. Decompose into three to five inputs

Inputs are leading and ownable, and they relate to the output in a way you
can write down. An exact identity (new activated accounts times first-
transfer rate, plus returning accounts times repeat rate) must reproduce
last period's actuals closely; a causal model may not reconcile exactly
and says so. An input one team cannot move without another is a
dependency, not an input.

```
[input] <name> | owner: <team> | ownable alone: yes | no | last period: <n>
Reconciliation: model <n> vs actual <n> | unreconciled: <no access to actuals; who holds them>
```

Never invent an actual.

## 4. A counter-metric with a threshold for each

Complete "this could be hit while making the product worse by ___" for the
output and each input. The blank names the harm; the counter-metric is the
measure that would show it, instrumented at the same time.

| Pushed | Cheap path | Counter-metric |
|---|---|---|
| Sessions per user | Notification pressure | Mute rate; sessions per task completed |
| Activation rate | Loosening the definition | Week-four retention of the activated cohort |
| Tickets resolved | Closing without solving | Reopen rate |
| Conversion rate | Dark patterns | Refund and chargeback rate; day-30 churn |

```
[counter] <metric> guards <output or input> | stop if <metric> crosses <value> | threshold: agreed by <role> | proposed, pending <role>
```

A counter-metric with no threshold is a comment.

## 5. Define every term

```
Definition: <metric>
  event:        <instrumentation name, not the English description>
  numerator:    <what is counted>
  denominator:  <the eligible population: which accounts, users, seats, or sessions, and why>
  window:       <length>; rolling | calendar
  exclusions:   <internal, bots, test accounts, trials, churned-not-deprovisioned>
  owner:        <role>; lives at: <where>
  changed on:   <date>: <what changed>
```

A definitional change breaks the series; annotate it on the chart. Check
each `event:` against the live schema in ~~product analytics or the
warehouse before calling it defined. (`~~<kind>` means whichever tool of that kind is connected; with none, ask for an export or paste.)

## 6. Key results that are results

Ask "so what?" after each proposed KR until the answer is an outcome. A KR
has a number, a direction, and a baseline:

```
KR: <metric> from <baseline, date> to <target> by <cycle end>
```

If the baseline is unknown but cheaply measurable, measure it now; if it
needs new instrumentation, the cycle's KR is to instrument.

## 7. Instrument before launch; test when it helps

Events and properties are part of done; verify them end to end before
release, including that properties are non-null. Do not run a controlled
experiment when it is underpowered for the expected effect, when
treatment leaks into control, when the outcome outlasts the window, when
the losing arm harms people, or when the decision is already made. Say
which and use a before-and-after with controls instead.

## Example

```
Definition: weekly active team
  event:        project.view OR task.update (web and mobile)
  numerator:    distinct accounts with at least one event by two or more members
  denominator:  paying accounts with two or more provisioned seats at week start
  window:       7 days; calendar week starting Monday
  exclusions:   internal domains, accounts in trial, accounts flagged test
  owner:        product analytics; lives at: metrics/definitions.md
  changed on:   2026-10-29: added the two-member requirement; series annotated

[counter] week-4 retention of newly active teams guards weekly active team
  | stop if it falls below 60 percent | proposed, pending product lead
```

## Before finishing

- Value exchange stated; each kept metric's cheap path documented.
- One output metric or a named frame; rejected candidates with the failing
  test.
- Inputs ownable; relationship written; reconciled or marked with who
  holds the actuals.
- A counter-metric per metric, threshold agreed or marked proposed.
- Every term defined with numerator, denominator, window, exclusions,
  owner.
- KRs have number, direction, baseline.
- Instrumentation verified end to end where a launch is involved.

Only the parts the request needed are expected; say which were out of
scope. A check that was skipped says `not done: <reason>`.

## Works with

- root-cause-debugging explains a number that moved or looks gamed.
- launch-readiness consumes the success metric and its baseline.
- product-strategy's kernel is the input to the value exchange.
- adversarial-review tests a metric about to become a company target.

Each is optional. This skill works alone.
