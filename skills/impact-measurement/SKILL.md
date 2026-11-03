---
name: impact-measurement
description: >-
  Turns your own work into evidence a skeptic can check: calibrate to the
  real rubric, reconstruct the period from records, write each claim as one
  evidence line with baseline, result, source, and an honest contribution
  verb, and include cancelled work. Use for a self-review, promotion packet,
  calibration submission, or contested stakeholder update. Not for product
  metrics (metric-design) or a routine status note.
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Impact measurement

The claim that survives a calibration room is the one a stranger can check
without talking to you. This skill produces evidence lines first and prose
second.

## Scope and stand-down

Engage when your work will be weighed by someone who can say no or "not
yet", or when reconstructing a period you did not instrument.

Stand down, in one line, for a status note or a routine board update built
from approved numbers (write it), and while the period is still open
(answer: start a weekly log, one line each with date, what changed, link).
Formal statistical claims are out of scope; a packet is not a study.

## 1. Calibrate to the real rubric

Get the level guide, the calibration rubric, recent successful packets at
the target level, and the gaps your manager has named. Extract the scope
word for the level being judged (team, multi-team, organization), the two
or three dimensions that decide it, and the implicit disqualifier (one big
project and nothing else; influence confined to your team). Write claims
at the scope being judged, in the rubric's vocabulary. If the rubric is
not obtainable, name the substitute and mark the calibration
`[unverified]`.

## 2. Two readers, when there are two

A manager knows the context and wants judgment and trajectory, including
the hard parts named. A committee has never met you and wants evidence
mapped to rubric lines, with one sentence of business framing before any
project name. Build both from one evidence base when a committee exists;
otherwise write for the reader you have.

## 3. Reconstruct from records kept without you in mind

Needed when the period was not logged. In order: your calendar (where time
went, not proof of contribution); your own writing (documents, decisions,
tickets, review history); dashboards with a fixed date range; other
people's records (retrospectives, incident reviews, launch posts) where
being named is stronger than anything you write. Build a chronology: date,
what you did, what changed, where the proof lives. A metric that moved
before your change shipped is not yours.

## 4. One evidence line per claim

```
Claim:        <what changed, at the rubric's scope>
Baseline:     <before value, date, how obtained> | none recoverable: <why>
Result:       <after value, date, same instrument>
Method:       measured | reconstructed | reasoned estimate: <one clause>
Source:       <level 1-5>: <link, document, or person>
Contribution: led | drove | contributed | influenced: <the counterfactual, one clause>
Confounds:    <what else could have moved this> | none identified
```

Source levels, strongest first: (1) a query or fixed-range view anyone can
rerun; (2) a dated document with your name in the company's system; (3)
someone else's record naming you; (4) a named corroborator who knows they
are cited; (5) your own description, which is a claim, not evidence. A
load-bearing claim rests on level 3 or better; one resting on level 4 is
labeled as corroborated testimony; one resting on level 5 is downgraded in
language or its source obtained before the period closes.

A qualitative outcome (a decision reversed, an exclusion removed) gets a
line too, with the documented before and after in place of numbers and no
invented price.

## 5. Attribution

Led (you owned the outcome; the record names you), drove (it would not
have happened without you; name the specific thing), contributed (a
defined part, sized), influenced (you changed what someone else decided;
their before state). Name the counterfactual, not a percentage share.
Credit collaborators by name; they are your corroborators. Align with
others claiming the same win before the cycle.

## 6. Prevented cost and changed decisions

Evidence the decision, not the imagined outcome: the plan of record and
what changed it, from documents. Where a size helps, anchor to a real
internal price (loaded cost, a vendor quote, the last comparable
incident), give a range at one significant figure with the assumption
attached, and label the method `reasoned estimate`. Skip probability-times-
cost theater.

## 7. Cancelled and failed work

A rubric answer, not a gap. Write the bet and why it was reasonable, the
signal you caught and when, what you recommended, what was saved or
learned, and what changed in how the team decides. Never let it surface
first from someone else.

## Example

```
Claim:        Reversed the plan to build a custom export service; the team
              adopted the existing warehouse connector (multi-team scope).
Baseline:     Plan of record, 3 March: two quarters, four engineers
              [level 2: planning doc v3, unedited since 3 March]
Result:       Connector live 21 April; export service cancelled 10 March
              [level 3: platform quarterly review, slide 7, names the analysis]
Method:       reconstructed: planning doc versions and the review deck
Source:       level 2 and 3 as above; corroborator: platform lead (level 4, notified)
Contribution: drove: the comparison memo of 6 March was the artifact the
              decision cites
Confounds:    the connector team's own roadmap already listed export for Q3
```

## Before finishing

- Rubric obtained or substitute marked; scope word named.
- Reader(s) identified; one evidence base.
- Chronology built where the period was not logged; contradictions stated.
- Every load-bearing claim has a full evidence line.
- Sources at level 3 or better, or the claim's language downgraded.
- Contribution verbs match their proof.
- Estimates labeled reasoned, ranged, anchored.
- Cancelled or failed work present, or its absence stated.
- The strongest case that you are overclaiming, in its own words, and the
  answer to it.
- Corroborators know they are cited.

A check that was skipped says `not done: <reason>`.

## Works with

- written-voice shapes the final documents for each reader.
- artifact-quality checks a packet rendered as a deck or report.
- adversarial-review tests one load-bearing claim before a committee does.

Each is optional. This skill works alone.
