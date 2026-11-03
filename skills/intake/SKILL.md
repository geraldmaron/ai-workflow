---
name: intake
description: >-
  Turns a long, messy, or contradictory request into one brief: the primary
  outcome, constraints, decisions already made, open questions, and a
  parking lot for tangents. Use when a brain dump, forwarded thread, or
  pile of notes carries several asks at once and work is about to start.
  Not for a single clear ask, and not for a message that is thinking aloud
  with no ask yet.
license: Apache-2.0
metadata:
  version: 0.4.0
---

# Intake

Produces a short brief the requester can correct in one glance, then a plan
that follows dependency and risk rather than the order things were
mentioned.

## Scope and stand-down

Engage when a request carries several concerns, corrections, or implied
outcomes at once and something is about to be built or decided on it.

Stand down, in one line, when the request is a single clear ask (do it), or
when the message is thinking aloud with no ask (engage the thinking, do not
invent a plan). If it is unclear whether there is an ask, say what you read
as the ask in one sentence and let the requester correct it.

## 1. Read everything, then extract

Read the whole message before structuring it. Late corrections change
early conclusions. Then fill these lists:

- **Primary outcome.** The one thing that, delivered, means the request was
  handled. Often not the first thing mentioned. If two outcomes carry equal
  weight and the requester gave no tiebreak, keep both and say so.
- **Secondary outcomes.** Asked for, real, subordinate.
- **Constraints.** Stated limits (deadline, tools, budget, "don't touch X")
  and implied ones (expertise level, environment, complaints about past
  approaches). Mark implied ones `(implied)`.
- **Decided.** Decisions already made. Build on them. If the same material
  shows a decision is unsafe or impossible, surface that at the top rather
  than relitigating it unannounced or complying unannounced.
- **Superseded.** Self-corrections. A later statement replaces an earlier
  one when it comes from the same person or from someone with authority
  over the point. When two speakers conflict and neither supersedes the
  other, record the conflict as a blocker or an assumption, not as settled.

Anything the plan leans on that the message does not settle is `[assumed]`
with a safe, reversible default. Expensive-to-undo guesses are blockers.

## 2. Parking lot

Tangents stay visible, one line each, in words the requester will
recognize. Never discarded, never chased. Promote one only if it turns out
to be load-bearing, and say so.

## 3. Ask only what you must

Ask the requester only when the answer would change what gets built and
cannot be found in the message, the material already in hand, or one
bounded look (one search or one document, a few minutes). Everything else
proceeds on a labeled assumption. Zero blockers is the common honest case.

## 4. Readback or proceed

When misreading would cost more than a pause (long, expensive, or hard to
reverse), show the brief before heavy work and ask for corrections. In an
unattended run, where nobody can answer, proceed on the labeled
assumptions and ship the brief with the result. Cheap, reversible work
starts immediately with the brief attached. Say which mode you chose, in
one line.

## Output

```
Intake
- Primary outcome:   <one sentence>
- Also wanted:       <secondary outcomes, one line each> | none
- Constraints:       <explicit and implied, implied marked (implied)>
- Decided:           <decisions the plan builds on> | none
- Superseded:        "<late statement>" replaces "<early statement>" | none
- Assumptions:       <each [assumed], with its default> | none
- Parking lot:       <tangents, one line each> | empty
- Blocked on you:    <true blockers only> | none, proceeding
- Mode:              proceeding | readback first, because <one clause>
- Plan:              <numbered steps, critical path first>
```

## Example

Forwarded thread: Monday, the product lead writes "ship the export as CSV
only, Friday." Wednesday, an engineer replies "we should do JSON too, it's
easy." Thursday, the product lead writes "fine, JSON as well, but Friday
still holds." The requester adds "also someone should look at why the
dashboard is slow."

```
Intake
- Primary outcome:   Export ships Friday in CSV and JSON.
- Also wanted:       none
- Constraints:       Friday deadline; no scope beyond the two formats (implied)
- Decided:           CSV format (product lead, Monday)
- Superseded:        "JSON as well" (product lead, Thursday) replaces "CSV only" (Monday)
- Assumptions:       [assumed] JSON uses the same field set as CSV
- Parking lot:       dashboard slowness
- Blocked on you:    none, proceeding
- Mode:              proceeding; the work is reversible before Friday
- Plan:              1. CSV export  2. JSON export sharing the field set  3. Tests for both
```

The engineer's Wednesday message did not supersede anything on its own; the
product lead's Thursday reply did.

## Before finishing

- Whole message read; supersessions resolved by authority, not by position.
- One primary outcome, or two with equal weight stated.
- Implied constraints written down and marked.
- Decided items built on, or a conflict with them surfaced at the top.
- Every tangent in the parking lot.
- Every question to the requester passes the test in step 3.
- Mode stated.

A check that was skipped says `not done: <reason>` rather than disappearing.

## Works with

- requirements-structuring takes the brief when the next artifact is a spec
  or ticket with acceptance criteria.
- decision-framing takes any blocker that is really an open decision.
- research or customer-discovery take over when the "messages"
  are evidence to be established, not asks to be extracted.

Each is optional. This skill works alone.
