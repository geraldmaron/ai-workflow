---
name: research
description: >-
  Finds out what is true and returns a sourced brief, in one of three
  modes: look something up or compare options from primary sources; verify
  a contested claim, number, or timeline against records; or reconstruct
  why a company did something from tickets, history, docs, and people. Use
  for "find out", "is this still current", "check whether that's true",
  "why was this built this way", "who actually owns this". Not for deciding
  what to do with the facts (decision-framing).
license: Apache-2.0
metadata:
  version: 1.0.0
---

# Research

Produces a brief a reader can act on without redoing the work: the answer,
the findings with their sources, what was inferred, and what is still open.

## Scope and stand-down

Engage when the answer is not in hand, the reader will act on it, and more
than one source could be consulted.

Stand down, in one line, when one authoritative source settles it (answer
with that citation), when a system of record answers directly (the tracker
for status, the repository for behavior, the dashboard for a number), or
when the reader wants speed over certainty (answer from held knowledge,
marked `[unverified]`).

## 1. Pick the mode and fix the question

Write one line: the question, who acts on the answer, the as-of date it
must be current for, and the mode.

- **Look up.** How does X work, what are the options, what is current
  advice. Sources: official documentation, standards, maintainers' own
  text.
- **Verify.** Someone claims X; are the numbers true; does the timeline
  hold. Sources: the record itself, independent of the claimant. Rules in
  [references/verify.md](references/verify.md).
- **Internal history.** Why was this built this way; who really owns it;
  why was the project killed. Sources: ticket history, version control,
  document revisions, calendars, and people. Rules in
  [references/internal-history.md](references/internal-history.md).

A question can change mode midway: a look-up that finds two sources
disagreeing becomes a verify. Say so when it happens.

## 2. Read, then cite

- Prefer the source closest to the thing. An aggregator, a blog post, or a
  summary is a lead to the primary, not a substitute.
- Cite only what was opened in this session, on the same line as the claim.
  A search result title is not a source. If nothing outside can be read,
  say so and mark the affected claims `[unverified]`.
- Date anything that changes: versions, prices, limits, owners, what is
  recommended.
- Set a budget before starting (sources, time) and stop there, or when the
  next source would not change the answer. Say which.
- Copies of one upstream are one source. Count as corroboration only
  sources that could have disagreed.
- For internal history, read the record where it lives: ~~project tracker
  history, ~~knowledge base revisions, ~~chat threads. (`~~<kind>` means whichever tool of that kind is connected; with none, ask for an export or paste.)

## 3. Separate findings from conclusions

- **Finding**: what a named source says, with its citation.
- **Inference**: what follows from the findings, marked as yours.
- **Recommendation**: only if asked, and then exactly one.

Where sources disagree, keep both and say which is more direct, more
recent, or more competent on this point. Silence in the record is not
confirmation; if a conclusion rests on silence, mark it as inference.

## 4. The brief

```
Question:  <one line, as-of date, mode>
Answer:    <two or three sentences a reader could act on>
Findings:
- <finding> [<source: title, publisher or system, identifier, date opened>]
Inferences:
- <what follows, marked as inference>
Open:      <what was not found, and what would settle it> | none
Sources:   <n> read; not reachable: <which, why> | none
Confidence: high | medium | low, because <one clause>
```

Verify and internal-history modes add the fields their reference files
name (source class, independence, the finding block with its date kind).
A worked look-up is in [references/example.md](references/example.md).

## Before finishing

- Mode and as-of date stated.
- Every load-bearing finding has a source that was opened, or
  `[unverified]` with what would settle it.
- Findings, inferences, and any recommendation labeled, not blended.
- Disagreements kept, not averaged.
- Open items say what would settle them.
- The answer at the top matches the findings.

A check that was skipped says `not done: <reason>`.

## Failure modes

- Citing the nearest thing, or a page never opened.
- Treating a summary as the thing it summarizes.
- Reading no results as "it did not happen".
- Stopping at the first coherent story when a second fits the evidence.
- Answering from memory on something that changed since training.

## Works with

- decision-framing takes the brief when the question was really a choice.
- adversarial-review tests what breaks if a finding is wrong.
- context-mapping records what a system is now; this skill explains how it
  got that way.
- written-voice shapes the brief when it ships as a document.

Each is optional. This skill works alone.
