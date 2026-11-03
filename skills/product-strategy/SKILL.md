---
name: product-strategy
description: >-
  Use for where-to-play or bet-selection calls, annual planning, an
  inherited strategy deck, or a board ask for "our strategy". A strategy
  kernel: diagnosis, guiding policy, and the actions it implies. Not for
  sequencing known work (implementation-planning), OKRs (metric-design),
  or a bounded X-or-Y choice (decision-framing).
license: Apache-2.0
metadata:
  version: 0.2.1
---

# Product strategy

If no obstacle is named and nothing was given up, there is no strategy in
the room yet. This skill produces the kernel and the record of what it
rejects.

## Scope and stand-down

Engage when a real allocation follows: money, headcount, or attention will
move, and a wrong direction costs a cycle or more.

Stand down, in one line, when the obstacle is already named and agreed and
the missing artifact is a sequenced roadmap (help with the roadmap), when
the decision is made and funded (help execute), or when the situation is
too new to diagnose (build the map first). If it is unclear whether the
stakes warrant the method and someone can be asked, ask one question.

## 1. Name the artifact

Vision (where we are going over years), strategy (which obstacle we will
overcome and what we give up), roadmap (what we are building now), goals
(how we will know). Write the answer at the top:

```
Artifact:   strategy | vision | roadmap | goals
Asked for:  <what the requester said>
Delivering: <what this document is>, because <one clause>
```

If the ask was "strategy" and the need is a roadmap, say so in that block
and then produce the roadmap or hand off; do not stop at the diagnosis of
the request.

## 2. Diagnose the inherited document, if there is one

Six tells, each reported as defect plus consequence: no stated obstacle;
goals dressed as strategy ("grow ARR 40 percent"); no causal story from
initiative to goal; no tradeoff (every segment still in scope); actions
that coexist rather than reinforce; and a policy a competitor could state
the opposite of ("focus on quality" fails; "be worse at breadth to be
undeniable at one workflow" passes).

```
[defect: <tell>] <what the document says> -> <what it costs>
```

Skip this step for a first strategy with nothing to inherit.

## 3. Write the diagnosis

One paragraph, causal, with the crux isolated and the real constraints
named (distribution, unit economics, a platform dependency, a sales motion
that cannot sell this).

```
Diagnosis:    <one paragraph, one crux>
Falsified by: <the observation that would show this is not the obstacle>
Evidence:     <what supports it> [cited] | [unverified: what would settle it]
```

Contested facts about market, competitors, or customers need evidence. If
nothing outside can be read here, mark them `[unverified]` and proceed.

## 4. Write the guiding policy

```
Because <diagnosis in one clause>, we will <approach>,
which means we will not <named thing>.
Advantage: <asset or position>, durable because <why it is not copyable in a quarter>
```

The "will not" names something real that someone wants: currently funded
work, or for a first budget, a credible alternative that has advocates.
A sacrifice nobody was asking for is a slogan. The advantage is a
distribution asset, a data or workflow position, a cost structure, a
customer relationship, or a regulatory or integration position; "execute
better" is not one.

## 5. Derive the actions

Three to five, each traceable to the policy. Check whether they reinforce
each other: remove one and see if the others weaken. If they do not, say
whether they are deliberate parallel bets or a wishlist with a cover page.
Name the constrained resource (usually one: engineering capacity,
leadership attention, cash) and show the allocation. An even split is
allowed when the choice was already made at a higher level; say so.

| Action | Traces to policy via | Reinforces | Share of <constrained resource> |
|---|---|---|---|

## 6. What would have to be true

For each major bet, list the conditions that would have to hold. Mark each
known (with evidence) or assumed (with what breaks if false). For the top
one or two assumed conditions, name the cheapest test, an owner, and when
it reports.

```
[known]   <condition> | evidence: <what>
[assumed] <condition> | breaks: <what fails> | test: <cheapest> | owner: <role> | reports: <when>
```

## 7. The anti-strategy line

```
Worse at:         <capability or segment>
Not served well:  <who>
Reverse if:       <the observation that would justify reopening this>
```

## Example

```
Artifact:   strategy
Asked for:  "our strategy for next year"
Delivering: strategy, because the current doc lists initiatives with no obstacle

Diagnosis:    Mid-market teams churn in month four because onboarding
              assumes a dedicated admin they do not have; enterprise accounts
              retain because they have one. Growth spend is going to the
              segment that churns.
Falsified by: Month-four churn in mid-market staying flat for cohorts that
              had a named admin.
Evidence:     cohort retention by segment, Q1 to Q3 [cited: analytics export
              2026-10-20]; admin presence per account [unverified: not tracked]

Because mid-market churns on admin-free onboarding, we will make the
product self-administering for teams under 50 seats, which means we will
not fund the enterprise SSO roadmap this year.
Advantage: our in-product setup data on 4,000 mid-market accounts, durable
because competitors sell through admins and do not collect it.

Worse at:         enterprise procurement requirements
Not served well:  accounts over 500 seats
Reverse if:       enterprise pipeline value exceeds mid-market ARR for two quarters
```

## Before finishing

- Artifact named and matches the need.
- Diagnosis falsifiable; contested facts cited or marked.
- Policy names a real thing it rules out; advantage is not effort.
- Three to five actions; coherence checked and the result stated.
- Constrained resource named; allocation shown.
- Assumed conditions carry a breakage, a test, an owner, a date.
- Anti-strategy line present.
- Strongest objection in its own words; if none was voiced, say who should
  be asked.
- Pre-mortem: the most likely failure story, one paragraph.

A check that was skipped says `not done: <reason>`.

## Failure modes

- Diagnosing the market instead of your position in it.
- A policy so abstract every existing action still qualifies.
- Editing last year's document and inheriting last year's diagnosis.
- A stated tradeoff that budget and headcount never moved to match.

## Works with

- research feeds the diagnosis with evidence.
- adversarial-review challenges the kernel before a board sees it or budget
  moves away from a funded team.
- metric-design chooses the metrics that track the strategy;
  requirements-structuring specifies what gets built.

Each is optional. This skill works alone.
