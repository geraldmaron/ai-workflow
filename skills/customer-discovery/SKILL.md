---
name: customer-discovery
description: >-
  Plans, runs, and synthesizes customer interviews whose findings will be
  spent on a build or cut decision: a falsifiable assumption first, coverage
  of churned, closed-lost, and never-activated users, questions about past
  behavior only, saturation per segment, findings labeled observed,
  reported, or opinion. Use for validating a problem, a weekly interview
  habit, or a pile of interview notes. Not for usability tests, surveys, or
  desk research (research).
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Customer discovery

Discovery fails in two places: questions that collect compliments about a
future that does not exist, and synthesis that mines transcripts for the
solution someone already chose. This skill produces tagged findings with
the disconfirming evidence recorded.

## Scope and stand-down

Engage when a build, cut, or prioritization decision depends on whether a
need is real, what shape it has, or who has it.

Stand down, in one line, when behavioral data already answers the question
(logs say four percent complete the flow; interviews can say why, not
whether), when the change is cheap to ship behind a flag and the users'
cost of trying it is also low, or when leadership has committed
irreversibly and the research can only decorate it.

## 1. Frame before recruiting

```
Outcome:            <the one outcome this round serves>
Assumption at risk: <a behavioral claim about a named segment>
Falsified by:       <what several interviews in that segment would have to show>
Instrument:         interview | prototype test | fake door | concierge | instrumentation
```

Interviews populate the opportunity layer (needs, pains, desires seen in
people's lives). Validating a drawn solution is an assumption test and
needs a different instrument. "Users want better reporting" fails this
block; "operations managers in accounts over 50 seats rebuild this report
by hand weekly" passes.

## 2. Recruit against survivorship

The friendly, engaged, available users an account manager introduces
exclude everyone whose experience would change your mind. State coverage
for every segment, including zeros:

| Segment | Why it changes conclusions | Where |
|---|---|---|
| Churned | The only people who can say what was intolerable | Exit list, 30 to 90 days out, account owner off the call |
| Closed-lost | The alternative that won and the real criteria | Pipeline; verify the stated loss reason |
| Signed up, never activated | Where promise and product diverge | Analytics cohort |
| Power users | Workarounds are unmet needs made visible | Usage percentile |
| Non-adopters in the target profile | Whether the problem is even top five | Cold outreach, communities |

```
[segment: <name>] n=<count> | reached via <how> | skipped because <reason, if 0>
```

Screen on what people did last, plus any attribute that defines the
population (role, jurisdiction, accessibility need, purchasing authority).

## 3. Ask about the past, not the future

| Do not ask | Ask instead |
|---|---|
| "Would you use a tool that does X?" | "Walk me through the last time you did X." |
| "Do you think this is a good idea?" | "What have you tried to fix this?" |
| "How often does this happen?" | "When did it last happen? And before that?" |
| "Would you pay for this?" | "What do you spend on this today, in money, tools, or people?" |
| "What features do you want?" | "What is the most frustrating part of this?" |

Chase specifics until you have a date, a tool name, or a number. Redirect a
compliment once ("kind of you; tell me what you did last week"); treat
compliments as noise, not as evidence against the topic. Talk under a
third of the time. Look for a commitment that costs the speaker something:
time, a referral, budget, a calendar slot. Take verbatim notes. A
future-intent question is allowed only when marked as such and justified.

If nobody can be reached from here, deliver the frame, segments, and
question set, mark affected claims `[unverified: no interview access]`,
and never write a quote nobody said.

## 4. Volume and saturation

Patterns appear around five or six interviews per segment per opportunity.
Stop a segment when two or three consecutive interviews add no new theme.
Saturation is per segment and per question; reframing the opportunity
resets the count. It says a need exists and what shape it has, never what
share of the base has it.

```
[saturation: <segment>] n=<count> | last <k> added <n> new themes | saturated | not saturated
```

## 5. Synthesize across the whole corpus

Map each interview within a day. Extract observations as atomic notes with
their source. Tag themes across the whole corpus for this question,
including the interviews that contradict the story. Separate the need from
the requested solution. Count supporting and disconfirming interviews per
theme and label the evidence:

- `[observed]`: behavior you or the instrumentation saw.
- `[reported]`: a specific past episode with a date, tool, or number.
- `[opinion]`: a preference, prediction, or generality. Never supports a
  build decision alone.

```
[observed|reported|opinion] <finding, one sentence>
  supports:    <n> interviews across <segments>
  disconfirms: <n> interviews, <segment>: <what they showed> | none found after looking
  sizing:      unknown until instrumented | <measure that would size it>
```

## Example

```
[reported] Operations managers at 50-plus-seat accounts rebuild the weekly
           utilization report by hand from two exports.
  supports:    7 interviews (churned 3, power users 4); each named the day
               and the spreadsheet
  disconfirms: 2 interviews, never-activated: had not reached the report;
               1 interview, power user: uses a connector we did not know about
  sizing:      unknown until instrumented; count accounts exporting both
               reports within 24 hours
```

## Before finishing

- Frame block present; instrument matches the question.
- Coverage stated for every segment, zeros included.
- Questions are about past episodes; any future-intent question marked.
- Every quote came from a conversation that happened.
- Saturation claimed per segment, or not claimed.
- Whole corpus tagged, contradictions included.
- Every finding labeled; disconfirmation looked for, not just absent.
- No qualitative count presented as a share of the base.

A check that was skipped says `not done: <reason>`.

## Works with

- research owns desk research on a market or competitor.
- metric-design sizes what was found; requirements-structuring specifies
  what to build from it.
- adversarial-review tests a finding about to justify a multi-quarter
  build, especially one from a friendly sample.

Each is optional. This skill works alone.
