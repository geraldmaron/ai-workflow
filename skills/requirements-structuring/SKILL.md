---
name: requirements-structuring
description: >-
  Turns a settled intent into requirements a team can build and test from:
  outcomes, constraints, non-goals, and acceptance criteria a stranger
  could check. Use when writing or tightening a spec, PRD, ticket, or
  change request, or when acceptance reads like "works well". Not for
  deciding whether to build it (decision-framing), diagnosing a slowdown
  (root-cause-debugging), or planning a rollout (launch-readiness).
license: Apache-2.0
metadata:
  version: 0.6.0
---

# Requirements structuring

Produces a requirements document whose every acceptance criterion is an
observation, whose exclusions are written down, and whose open questions
are the ones the author could not settle.

## Scope and stand-down

Engage when work will be built, bought, or committed to on the strength of
this document, and the requirements currently live in conversation or in
someone's head.

Stand down, in one line, when the requirement is small and obvious (a
rename, a config flip, a well-understood fix): state the intent and
proceed. When the real question is whether to build at all, name that
undecided decision at the top and mark the dependent parts contingent
rather than specifying around it.

## 1. Sort into four lists

- **Outcomes.** What is observably true when done. An entry shaped like an
  implementation becomes an outcome by asking why, or a constraint if it
  is mandated.
- **Constraints.** Limits with a source. A limit with no source stays a
  constraint, marked `[unsourced]`, until its owner confirms or drops it.
  Missing provenance is not permission to ignore a limit.
- **Assumptions.** Marked `[assumed]`, each with what would settle it and
  what breaks if it is wrong.
- **Decided.** Attributed decisions already made. An unattributed
  "decision" is an assumption.

Load-bearing facts carry a citation or `[unverified]`.

## 2. Make every criterion checkable

An acceptance criterion is an observation a stranger could make without
asking anyone. Test: could two people reasonably disagree about whether it
is met? If so, it is not a criterion yet.

- "Works well": name the measurement, or record the need and mark its
  acceptance `undecided: <who decides>`. Do not delete the need.
- "Is fast": operation, load, number, and where the number comes from. An
  invented threshold is labeled `chosen by <who>`.
- "Handles errors gracefully": the enumerated failures and what the user
  sees for each.

## 3. Write the non-goals

Deliberate exclusions, one line each with a reason. A non-goal that keeps
being argued is usually an undecided decision filed as an exclusion;
surface it.

## 4. Earn each open question

Before shipping a question: could the author have settled it from material
in hand, something reachable, or one bounded pass? If so, settle it. Each
remaining question names why it is unsettled (authority, access, or a
named person's decision), who answers, and what is blocked.

## 5. Prioritize honestly

Buckets: critical path, now, next, later. Critical path is only what the
outcome is impossible without. If nearly everything lands there, say so
plainly rather than demoting indispensable items to make the list look
balanced. A small migration can be all critical path.

## 6. Pick the shape

Full requirements document, one-page brief, or change-request addendum.
Skeletons in [references/document-shapes.md](references/document-shapes.md).
Drop an unused section by leaving its heading with "none", so the reader
knows it was considered.

## Example

A ticket reads "make search faster." After one conversation with the
owner:

```
Outcome:     Search results for the catalog appear within a time users do not notice.
Constraints: No new infrastructure this quarter [source: platform lead, 14 Oct].
             Existing ranking must not change [unsourced; confirm with search owner].
Assumptions: [assumed] The slow path is the 95th percentile, not the median;
             settled by the latency dashboard, breaks if the median is also slow.
Decided:     Caching is acceptable (platform lead, 14 Oct).
Non-goals:   Ranking quality. Reason: separate project, separate owner.
Acceptance:
  1. 95th percentile catalog search latency under 400 ms at 200 requests
     per second on the staging load profile. Threshold chosen by the search
     owner; current value 1,100 ms.
  2. Cold cache: first query after deploy completes under 2 s.
Open:        Whether results may be up to 60 s stale. Needs the product owner;
             blocks the cache design, not the measurement work.
```

## Before finishing

- Four lists separated; implementations converted to outcomes or justified.
- Every criterion passes the disagree test; thresholds labeled.
- Non-goals stated with reasons.
- Each open question says why, who, and what is blocked.
- Priorities honest; an all-critical list is stated, not disguised.
- Any hidden whether-to-build decision named at the top.

A check that was skipped says `not done: <reason>`.

## Works with

- decision-framing owns an undecided whether-to-build question.
- research owns facts the document depends on.
- adversarial-review challenges the finished document before it is built.
- written-voice shapes the prose for its readers.

Each is optional. This skill works alone.
