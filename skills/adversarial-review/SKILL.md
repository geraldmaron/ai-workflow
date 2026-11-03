---
name: adversarial-review
description: >-
  Challenges a plan, design, decision, spec, or strategy before anyone
  commits to it: the strongest failure mode, the alternative not taken, the
  assumption doing the work, and one unhedged verdict. Use when asked to
  poke holes, argue the other side, find the weak point, or say why this
  will fail. Not for reviewing a code diff line by line, checking whether
  facts are true (research), or fixing the thing itself.
license: Apache-2.0
metadata:
  version: 0.5.0
---

# Adversarial review

Produces findings that break the artifact and one verdict. Improving the
artifact is a different job, done afterwards by someone else.

## Scope and stand-down

Engage when someone is about to commit to an artifact and being wrong is
expensive: an architecture, data model, or security boundary; a vendor or
build-versus-buy call; a migration; a spec about to be built; a decision
record about to be executed; a strategy about to be funded. A draft
qualifies when its load-bearing choices are already fixed and the author
asks for the challenge now.

Stand down, in one line, on low-stakes reversible work and on drafts whose
core choices are still moving. Code review of a diff is a different
activity; what this skill reviews in code-shaped work is the thinking:
failure modes, alternatives, and the claims the approach rests on.

A reviewer who shares the author's context shares the blind spots. If
you wrote the artifact or helped shape it, hand the review to a reviewer
that has not seen that work (a fresh session, or a different model) when
this environment offers one, giving it the artifact and not your
reasoning. If none is available, run the method yourself, say so in the
verdict, and rest each finding on something outside your own reasoning: a
test, a record, a document, a calculation shown.

## 1. Posture

- Read the artifact as its best advocate would, then break that reading.
  Do not supply missing pieces on the author's behalf; a missing rollback
  plan is a finding, not something to assume.
- Findings are ways the artifact fails, not ways it could be better.
- A clean pass is a valid result. Padding with minor findings hides real
  ones.

## 2. Six challenges

Run each and show the result, even when the result is "nothing found".

1. **Strongest failure mode.** The most likely bad outcome if adopted as
   is, as a concrete story: these inputs, this state, this sequence, this
   wrong result.
2. **Best alternative not chosen.** The strongest option rejected or never
   considered, argued as its advocate would. Do the artifact's rejection
   reasons hold? If the artifact names no alternatives, that is a finding
   only when the choice was contestable.
3. **Load-bearing claims.** Every number, date, and capability the
   conclusion needs: checked against what, or unsupported.
4. **Assumption inversion.** For each assumption, stated or not: if false,
   what breaks, and how would anyone find out in time?
5. **Who bears the cost.** If this is wrong, who pays, and is it the party
   who decided?
6. **Hostile expert.** What would a domain expert who wants this to fail
   notice in five minutes: prior art, numbers that do not add up, missing
   cases.

## 3. Findings

```
<n>. <one-line finding> [fatal | serious | minor]
   Failure:      <concrete bad outcome if unaddressed>
   Evidence:     <what in the artifact, or missing from it, establishes this>
   Smallest fix: <one sentence naming the change; not a design>
```

Fatal blocks acceptance. Serious means accepted-with-controls at best.
Minor does not move the verdict. "Smallest fix" is one sentence; designing
it is out of scope, and if the fix cannot be named in a sentence, say
"not obvious" and leave it.

## 4. Verdict

Exactly one, as the first line of the review, `VERDICT: <one of four>`:

- **Accepted**: all six run, nothing that matters broke.
- **Accepted with controls**: sound if named, checkable controls are
  adopted. List them.
- **Needs validation**: a load-bearing claim must be tested first. Name
  what, how, and who could do it, or `owner: not established`.
- **Rejected**: a fatal finding stands. Name the smallest change that
  reopens the question.

If the artifact carries its own checklist or record, spot-check two claimed
items. A claimed-but-not-done item is a serious finding.

## Example

Review of a proposal to move session storage from the database to an
in-memory cache:

```
VERDICT: Needs validation

Steelman: Session reads dominate database load; the cache cuts median
latency and the team already runs the cache for rate limiting.

1. A cache restart logs every user out at once [serious]
   Failure:      Deploy or node failure clears sessions; thousands of users
                 re-authenticate in the same minute, hitting the identity
                 provider's rate limit.
   Evidence:     Proposal section 3 assumes "restarts are rare"; the deploy
                 log shows four cache restarts last month.
   Smallest fix: Persist sessions to the cache's disk-backed mode or keep a
                 database fallback for reads.

2. Latency claim rests on a benchmark without network hops [minor]
   ...

Challenges 2, 4, 5: run, nothing material. Challenge 3: the "70 percent of
database load is session reads" figure has no source; needs a query
against last week's slow log before this is accepted. Owner: database team.
```

## Before finishing

- Steelman stated in two or three sentences before findings.
- All six challenges run, results shown.
- Each finding has failure, evidence, severity, and a one-sentence fix or
  "not obvious".
- One verdict, first line, unhedged.
- Self-review disclosed when it applies.
- No improvement drift: the review names breakage, not redesign.

## Works with

- research (verify mode) checks whether a contested fact is true; this
  skill asks what breaks if it is false.
- decision-framing and product-strategy produce the records this skill
  challenges; it tests their objection and pre-mortem rather than
  repeating them.
- The commit, implementation, and launch skills name the moments when a
  change touching a security boundary, stored data, or a public interface
  should come here first.

Each is optional. This skill works alone.
