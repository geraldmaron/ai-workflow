---
name: org-entry
description: >-
  Plans the first months in a new leadership role, inherited team, or
  reorganized scope: classify the situation (start-up, turnaround, growth,
  realignment, sustaining), verify it against records, map where decisions
  are made, pick early wins that fit the type, and shape a 30/60/90 plan.
  Use for a new role, an inherited product or team, or a first-90-days ask.
  Not for reading a technical system (context-mapping).
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Org entry

New leaders rarely fail on competence. They run the playbook for a
situation they are not in. This skill produces a classification with its
evidence, a decision map, and a plan shaped by the type.

## Scope and stand-down

Engage when you arrive with authority you have not yet earned and the
first months set what you can do afterwards: a new role, an inherited
product or team, a reorg handing you unfamiliar scope, an interim role
that carries real decision rights. A lateral move into a situation you do
not understand counts, even if you know the people.

Stand down, in one line, for a lateral move inside a situation you already
hold, for an advisory engagement with no decision rights (the
classification would be decoration), and for reading a technical system.
If it is unclear what authority you hold and someone can be asked, ask the
person who hired you one question; otherwise write the assumption down.

## 1. Classify, with a rival

| Type | What is true | What it grants you | What kills you here |
|---|---|---|---|
| Start-up | Nothing exists; resources scarce | Latitude, no legacy | Structure too late or too early |
| Turnaround | Everyone knows it is broken | Authority to cut fast | Consulting instead of deciding |
| Accelerated growth | The product works; scale breaks it | Money and headcount | Hiring ahead of the system that manages them |
| Realignment | Success recent; decline not yet visible | Almost nothing; the org thinks it is fine | Announcing change before evidence |
| Sustaining success | Strong org, high bar | Trust you have not earned | Changing things to prove you are needed |

The expensive error is treating a realignment as a turnaround. Classify
each unit of a mixed portfolio separately.

```
Classification: <unit>
- Type:          <one of five>
- Evidence for:  <two or three observations, each with where you saw it>
- Rival type:    <next most plausible, and the one observation for it>
- Grants:        <the authority this type actually gives you here>
- Confidence:    high | medium | low: <what would change it>
```

A block with no rival type is a label, not a classification.

## 2. Verify against records, not the hiring story

The interview narrative is told by the people whose decisions produced the
situation. Check it against: unit economics over eight quarters from the
source system; attrition by team and tenure, with exit reasons; the last
three roadmaps against what shipped; and whether your predecessor was
promoted, moved, or removed, and who decided. A record you cannot reach is
marked `[unverified]` with what would settle it; never describe numbers
you did not open.

## 3. Map the real decision system

```
Decision map: <scope>
- Veto holders:     <who can stop a thing without owning it, and over what>
- Load-bearing:     <whose public backing makes a proposal safe to join>
- Trusted nodes:    <names that recur when you ask five people in unrelated
                     teams who they check with before committing>
- Where it settles: <the room or thread where the call is made>
- Reaction metric:  <the number whose movement causes an unscheduled meeting>
- Unknown:          <what you could not determine, and who would know>
```

If people cannot be asked from here, list the questions and who should be
asked.

## 4. Audit what you inherited

Roadmap first (per item: who asked, what evidence, what breaks if cut),
then senior people (keep, develop, move, or exit, each with a decide-by
date; act on none yet), then product (top three complaint themes, worst
retention cohort, what the last three launches moved). "Nobody knows" is a
finding.

## 5. Early wins that fit the type

An early win is a change the organization already agrees is a win; it buys
credibility to spend later. Pick one visible to the people in the decision
map, achievable in the window, and clearly yours to finish, even when it
was started before you.

| Type | Right kind | Window |
|---|---|---|
| Turnaround | A cut, a shutdown, a fix to the obvious wound | Weeks 2 to 6 |
| Realignment | An evidence artifact that makes the problem undeniable | Weeks 6 to 12 |
| Accelerated growth | Removing a bottleneck people already complain about | Weeks 4 to 8 |
| Start-up | The first thing in a real user's hands | As early as possible |
| Sustaining success | A small improvement to someone else's priority | Weeks 4 to 10 |

A reversible fix to a known problem with approval in hand does not wait
for the window; the window governs changes that spend credibility.

## 6. The 30/60/90

```
30/60/90 | <unit> | type: <type>
- Day 30:    <diagnosed, decided, or learned>
- Day 60:    <presented, acted on, or in place>
- Day 90:    <true about the unit that was not true on day one>
- Early win: <the win, its audience, its window>
- Held back: <what you are not doing yet, and until when>
- Breaking:  <any default restraint you are setting aside, and why> | none
```

Boundaries by type: turnaround diagnoses by day 14, decides by 30, acts
through 60; realignment listens through 45, presents evidence near 60,
proposes between 75 and 90; growth names the constraint by 30 and has an
operating cadence by 60; start-up ships before 30; sustaining learns the
standard by 30 and meets it visibly by 60.

Default restraints outside a turnaround: no reorg, title change, or exit
before day 45; no comparison to a previous employer in a meeting; no new
tooling or ritual in month one; no accepting the inherited roadmap by
silence. Everywhere: do not fix the thing you are best at fixing because
you can see it. Any restraint you break goes in the plan with its reason.

## 7. Re-check the type when

Proposals get polite agreement and no movement (you may be in a
realignment, not a turnaround); people bring you decisions you expected
them to make (decision rights may be missing); your early win landed and
nothing changed in how you are treated (wrong win or wrong audience); you
keep discovering commitments you did not know about (the decision map is
wrong). Each is a prompt to rerun step 1 with the new evidence, not an
automatic reclassification.

## Example

```
Classification: payments platform team
- Type:          realignment
- Evidence for:  revenue flat for six quarters while the market grew (finance
                 export, Q1 2025 to Q2 2026); roadmap shipped 40 percent of
                 plan three cycles running (planning docs vs release notes);
                 predecessor promoted out, not removed (hiring manager, 1:1)
- Rival type:    turnaround; the one observation for it is two senior exits
                 in Q2, but exit notes cite relocation, not the team
- Grants:        almost nothing; the org reads flat revenue as stability
- Confidence:    medium: churn by cohort would settle it [unverified: no
                 analytics access yet]
```

Treating this as a turnaround and cutting in week three would have spent
authority the type does not grant.

## Before finishing

- A classification block per unit, each with a rival type.
- Hiring narrative checked against records; unreachable ones marked.
- Decision map filled, unknowns listed.
- Inheritance audited with decide-by dates.
- Early win chosen for the type, with its audience.
- 30/60/90 block present, with held-back items and any restraint broken.
- Re-check triggers named.
- Pre-mortem: the most likely story in which you are gone in six months.

A check that was skipped says `not done: <reason>`.

## Works with

- context-mapping owns the technical system you inherited.
- research (internal history mode) owns why a specific inherited decision
  was made.
- impact-measurement turns the first months into evidence later.
- product-strategy sets direction once you are trusted.

Each is optional. This skill works alone.
