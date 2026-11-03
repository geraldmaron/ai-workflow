---
name: decision-framing
description: >-
  Frames a decision that is expensive to reverse: the choice in one
  sentence, real options including do-nothing, trade-offs, one
  recommendation, its strongest objection, and a record a reader can audit
  later. Use for buy-or-build, vendor choice, X-or-Y arguments that will
  not settle, or "is it worth delaying to fix". Not for cheap reversible
  picks, and not for gathering the facts first (research).
license: Apache-2.0
metadata:
  version: 0.4.0
---

# Decision framing

Produces a decision record: the choice, who decides, the options actually
considered, consequences concrete enough to be wrong, one recommendation,
and the case against it.

## Scope and stand-down

Engage when a real choice exists, someone will build, buy, commit, or forgo
because of it, and reversing has a cost.

Stand down, in one line, when the decision is already made (help execute),
when the pick is cheap to undo (answer fast and try it), or when only one
option is viable (say why the others are not, in a paragraph, and record
its consequences briefly). If the stakes are unclear and someone can be
asked, ask one question; if nobody can be asked, state the assumption and
proceed.

## 1. Frame before listing options

- **The decision as a choice.** "Choose how X will Y." Not a topic, not a
  conclusion in disguise.
- **Who decides, who is consulted.** If no decider is known, write
  `decider: not established` and frame anyway; the record is then a
  proposal for whoever picks it up.
- **Reversibility.** Reversible (undo costs about what doing cost), costly
  to reverse, or one-way. When unsure, class upward and say so. A cheap
  test that would settle the class is itself an option.
- **Do-nothing as a real option.** Costs that accrue, options that expire,
  risks that grow or shrink.

Separate constraints (falsifiable, they disqualify) from preferences (they
weigh). A preference written as a constraint removes options without anyone deciding to.

## 2. Generate options honestly

Two to five real options, each described in a paragraph its advocate would
sign. At least one is written at equal depth by someone other than the
framer's instinct; often that is do-nothing or the incumbent used harder.
Name options; do not number them. Disqualified options stay visible with
the constraint that removed them.

## 3. Compare concretely

Consequences per option against three to six criteria, stated so they
could be wrong. Facts cited or `[unverified]`; inferences marked;
assumptions `[assumed]`. No invented thresholds: a threshold is sourced or
labeled `chosen by <who>`. Use a table only when the comparison is
contested; otherwise prose.

## 4. Recommend once, then argue against it

One recommendation, addressed to the decider, first in the record. On a
tie, prefer the cheaper-to-reverse option and say so. Then, under its own
heading, the strongest objection in the words its advocate would use, and
the triggers that would reopen the decision.

## 5. Pre-mortem

Assume the recommendation was followed and failed. Write the most likely
specific story, the early signal, and whether anything cheap now makes the
failure survivable. If this weakened the recommendation, say so and revise.

## Output

```
Decision record
- Decision:          <the choice, one sentence>
- Decider:           <who> | not established   Consulted: <who>
- Reversibility:     reversible | costly to reverse | one-way, because <why>
- Do-nothing:        <what happens if no decision is made>
- Options:
    <name>: <essence> | recommended | viable | disqualified by <constraint>
- Recommendation:    <one sentence, to the decider>
- VERDICT:           proposed | accepted | accepted with controls: <which>
                     | needs validation: <what, by whom> | rejected
- Consequences:      <what the chosen path costs>
- Strongest objection: <one line; full text under its own heading above>
- Pre-mortem:        <the failure story, two or three sentences>
- Revisit when:      <concrete triggers>
```

The verdict stays `proposed` until the decider has responded. Every line
is filled or says `not established: <why>`.

## Example

```
Decision record
- Decision:          Choose how the admin app will authenticate staff.
- Decider:           not established (platform lead or security lead; both consulted)
- Reversibility:     costly to reverse; sessions, roles, and audit logs would migrate
- Do-nothing:        Shared passwords continue; the audit finding stays open past Q1.
- Options:
    Hosted identity provider: SSO with the company directory | recommended
    Build on the framework's auth module: local accounts, own MFA | viable
    Keep shared passwords: no work | disqualified by the audit finding
- Recommendation:    Adopt the hosted provider; the audit deadline and the
                     company directory already existing outweigh the vendor cost.
- VERDICT:           proposed
- Consequences:      Annual vendor cost [unverified: quote pending]; vendor outage
                     blocks login.
- Strongest objection: "We are paying a vendor for ten users and taking an
                     outage dependency, when the framework ships MFA in a week
                     of work."
- Pre-mortem:        Six months in, the vendor's price doubles at renewal and
                     the directory sync breaks on a role rename. Early signal:
                     the first sync error in the logs. Cheap now: keep local
                     break-glass accounts.
- Revisit when:      Staff exceeds 50, or the vendor changes pricing tiers.
```

## Before finishing

- Framed as a choice, with decider (or `not established`), reversibility,
  and do-nothing.
- Constraints separated from preferences; disqualifications tied to a
  constraint.
- At least one unfavored option at full depth.
- Consequences concrete; facts marked; no invented thresholds.
- One recommendation; one verdict.
- Strongest objection in its own words.
- Pre-mortem specific, and its effect on the recommendation stated.

A check that was skipped says `not done: <reason>`.

## Works with

- research gathers or verifies the facts first.
- adversarial-review challenges the finished record before it is executed;
  it does not repeat the objection and pre-mortem, it tests them.
- product-strategy owns a where-to-play question; this skill owns a bounded
  choice inside an agreed direction.

Each is optional. This skill works alone.
