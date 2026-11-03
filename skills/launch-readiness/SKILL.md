---
name: launch-readiness
description: >-
  Gates a customer-visible launch or rollout: a tier by blast radius and
  reversibility, cross-functional work scoped to the tier, an exposure
  sequence with a rehearsed kill switch, go/no-go criteria with one named
  decider, and a review against the metric registered before launch. Use
  for a launch, rollout, pricing or terms change, or GA step. Not for
  whether to build it (product-strategy) or the announcement (written-voice).
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Launch readiness

Launches fail from mismatched resourcing more than from bad execution: a
minor feature gets a six-week campaign, or a major bet goes out as a
Tuesday message. This skill produces a tier, a scoped plan, a kill switch,
and a go/no-go record.

## Scope and stand-down

Engage when a change reaches people outside the team and getting it wrong
is not trivially reversible: a new product or market, a customer-visible
feature, a pricing or terms change, a migration users will feel, a GA step
from beta. A routine release that happens to carry a terms or data change
is in scope for that change.

Stand down, in one line, for internal changes behind a flag, bug fixes in
a standing release train, copy fixes, and anything whose rollback is one
deploy and whose blast radius is one screen: those follow the team's
normal release process. Say which tier you judged it and leave it to that
process. Whether to build the thing at all is not this skill's question.

## 1. Tier first

| Tier | Definition | Lead time | Who calls go/no-go |
|---|---|---|---|
| 1 | New product or market, press-worthy, major revenue or brand exposure, or an irreversible change to pricing, terms, or data | 4 to 6 weeks | A named executive |
| 2 | A change customers will notice, reversible within hours | 1 to 2 weeks | Product and engineering leads, one named as tiebreaker |
| 3 | Minor, incremental, reversible in one step | Release notes | Normal release process; this skill stands down |

```
Tier: <launch>
- Tier:              <1 | 2>
- Blast radius:      <who is affected, how many>
- Reversibility:     <what undoes it, how long>
- Irreversible parts: <migration, pricing, public commitment> | none
- Decider:           <name or role>
- Re-tier if:        <the scope change that moves this up>
```

Re-tier when scope changes mid-build. A launch that grows from tier 3 to
tier 1 without picking up the process is the common way this fails while
looking followed.

## 2. Scope the work to the tier

| Workstream | Tier 1 | Tier 2 |
|---|---|---|
| Sales enablement | Deck, battlecard, training | One-pager |
| Support | Runbook, staffed escalation | Updated help docs |
| Legal and privacy | Required, before build completes | If data handling or terms change |
| Marketing | Campaign, launch page | Announcement |
| Pricing and billing | Sign-off | If touched |
| Localization | Complete before launch | Where markets are live |
| Security review | Required | If new attack surface |
| Instrumentation | Metric registered and firing pre-production | Metric registered and firing |

Every skipped workstream is a recorded decision with a name on it. Where a
specialist owner exists, the launch holds on their answer; if they cannot
be reached, the decider accepts that risk explicitly on the record. Where
no owner exists, do the check and record the line `unreviewed by a
specialist`. Never record a sign-off nobody gave.

## 3. Choose exposure and the kill switch

Exposure increases in this order: dark launch (code live, traffic off);
internal dogfood; opt-in beta with named users; percentage ramp to real
users; general availability. Tier 1 and most tier 2 launches pass through
dogfood and a ramp at least. Going straight to GA is how a tier 1 failure
becomes a tier 1 incident.

```
Kill switch: <launch>
- What flips:      <flag, config, or deploy>
- Who can flip it: <people or on-call role, access confirmed>
- Time to effect:  <decision to users unaffected>
- Rehearsed:       yes, <date> | no: <why>
- Leaves behind:   <data or state rollback does not undo, and who owns it> | none
```

A rollback that exists only as "we would revert the deploy" and was never
run is a finding. If there is no way to turn it off, that changes the tier.

## 4. Criteria and decider before launch week

One named person decides. Criteria are written before launch week, each
with how it is observed and what a red result triggers (delay, roll back,
ship with a named mitigation).

```
Go/no-go: <launch>
- Tier / Decider:   <tier> / <name or role>
- Decision:         go | go with mitigations | delay | no-go
- Criteria:         <criterion>: green | red, via <where>, red triggers <action>
- Skipped work:     <workstream, decided by, why> | none
- Kill switch:      rehearsed yes | no; time to effect <duration>
- Metric:           <success metric, baseline, review date>
- Dissent:          <strongest objection and who raised it> | asked, none raised
- Pre-mortem:       <most likely failure story, two sentences>
- Conditions:       <what must stay true after launch> | none
```

A go with no dissent and no conditions usually means the meeting did not
happen. Ask for the objection before closing the record.

## 5. Review against the registered metric

Thirty to ninety days after, by tier. Compare against the metric registered
before launch, never one chosen afterwards. If the registered metric turns
out wrong, that is a finding, not a substitution. The review lands on one
of iterate, hold, or roll back, and names what would have been visible
before launch. Read the metric from ~~product analytics and the incident
record from ~~observability, not from someone's summary. (`~~<kind>` means whichever tool of that kind is connected; with none, ask for an export or paste.)

## Example

```
Kill switch: customer data-model migration
- What flips:      read path flag `billing.v2_reads`; write path cannot be flipped
                   once the backfill finishes
- Who can flip it: billing on-call (access confirmed 14 Oct), platform lead
- Time to effect:  under a minute for reads
- Rehearsed:       yes, 16 Oct in staging
- Leaves behind:   rows written after cutover exist only in the v2 schema;
                   rollback needs the reverse backfill job (owner: billing
                   data), about two hours
```

The irreversible write path is what makes this tier 1, whatever the
feature looks like to customers.

## Before finishing

- Tier block present, with re-tier trigger.
- Workstreams scoped; every skip recorded with a name.
- Specialist lines signed by their owner, or `unreviewed by a specialist`,
  or risk accepted by the decider on record.
- Exposure sequence chosen; skipped stages justified.
- Kill switch block present, rehearsal stated.
- Criteria written before launch week; one decider named.
- Metric, baseline, and review date fixed before launch.
- Dissent and pre-mortem recorded.

A check that was skipped says `not done: <reason>`.

## Works with

- metric-design defines the success metric when none exists; this skill
  consumes it. A tier 2 launch with no metric registers a minimal one and
  says so.
- written-voice owns the announcement and release notes.
- adversarial-review tests the go/no-go record for a tier 1 launch.

Each is optional. This skill works alone.
