# Authoring skills

This repository owns every skill in `skills/`. Each skill is a folder with
`SKILL.md` and any references or scripts it needs, in the open
[Agent Skills](https://agentskills.io/specification) format. A folder must
work on its own when deployed: relative links only, no dependency on this
checkout, on a sibling skill, or on a particular host's tools.

## What a skill is for

A skill carries what a session does not already have: a house output
shape, the boundary that says when not to engage, and the specific ways
the task goes wrong. It does not re-teach method the model already knows.
Rules that must hold in every session (verification before "done", no
secrets in commits, claims only as strong as the evidence) live in
`core/GLOBAL.md`, not in a skill; a skill may apply such a rule to its own
output in a line, never restate the policy.

## Shape of a SKILL.md

```
---
name: <matches the folder; kebab-case>
description: >-
  Use when <the situations, symptoms, and words a person uses, including the
  casual ones: "fix it", "plan this">. <The deliverable, named in a few words,
  no steps.> Not for <the nearest exclusions, naming the sibling skill that
  owns each>.
license: Apache-2.0
metadata:
  version: <semver>
---

# <Title>

<One or two sentences: what this produces.>

## Scope and stand-down       (required; lint checks for the heading)
## <Numbered steps>           (imperative; literal output shapes in code blocks)
## Example                    (a filled shape, not a template, when it changes behavior)
## Before finishing           (a short checklist; a skipped item says `not done: <reason>`)
## Failure modes              (optional; the specific ways this task goes wrong)
## Works with                 (siblings by name, each optional; "This skill works alone.")
```

Keep the body well under 200 lines. Move long templates or mode-specific
rules to `references/`, one level deep, linked from the body. The
description is the only text a host loads before the skill fires, so it
carries the triggers and the exclusions; lint warns above 520 characters
per skill and 8,000 for the whole catalog, because hosts truncate the
listing.

The description says when to load the skill, not how it works. A
description that lists the steps gets followed in place of the body: the
session does the summary and never reads the procedure. Name the
deliverable; leave the method to the body. Older descriptions that open
with the method move to this form the next time their skill is edited;
run the routing eval when you move one.

## Write the form the failure needs

Write a skill, or a change to one, only after a `bare` run fails at the
thing it is for (see Validation). If the run without the skill already does
it, there is nothing to fix. Then pick the form by the kind of failure the
baseline showed:

| Baseline failure | Form that fixes it |
|---|---|
| Output has the wrong shape (verdict buried, questions last, no scope line) | A recipe: the output's parts, in order, as a literal shape in a code block |
| A required element is missing from output it already produces | A required slot in that shape |
| Knows the rule, skips it under pressure (no test, "done" without running it) | A short prohibition plus the excuses the baseline gave and the reply to each |
| Behavior should depend on a condition | A conditional on something observable ("if a spec exists, cite it") |

Prohibitions ("don't restate the spec") get negotiated and make shape
problems worse; keep them for the third row. Do not add nuance clauses
("unless it matters"): a real exception becomes its own conditional. An
exemption clause ("this limit doesn't apply to code") does not scope; if
part of the output must be exempt, restructure so the rule cannot reach it.

## What not to write

- Justification for the method ("it exists because..."), or the same rule
  stated in a step, a gates list, and a record. State it once.
- Closing records that recite every gate. The checklist is enough.
- Enforcement commentary. Nothing in a SKILL.md enforces anything; a hook
  or a lint rule does, and lives in `extras/` or `scripts/`.
- Host tool or vendor names (lint rejects them). Say "if this environment
  can read outside material" and name what was not done when it cannot.
- Bibliographies. Method lineage lives once in `PROFILES.md`.
- Machine tells in the skill's own prose; models imitate the style of their
  instructions. Lint runs the written-voice checker and warns.

## Composition

Name siblings in "Works with" by skill name, with when the handoff
happens. Every handoff is optional and the skill works without it. When
two skills shape one deliverable, the one whose output shape the
deliverable follows writes the closing checklist; the other adds one line.

## Validation

`scripts/skills lint` checks frontmatter, naming, portability, the
stand-down heading, length, the description budgets, and vocabulary
overlap between descriptions. `scripts/skills catalog` regenerates
`CATALOG.md`. `evals/routing.tsv` holds requests with the skill that
should fire; keep it current when a description changes, and add a case
for any pair lint reports as overlapping. The model-judged run
(`scripts/evals`) measures label selection only and is optional.

For behavior, `evals/behavior/<scenario>/` holds a prompt, an optional
seeded workspace, and checks for the traps planted in it. `scripts/evals
--behavior --live` runs each scenario with no skills (`bare`: no user
settings, plugins, or global instructions; the harness's built-in skills
remain) and with this library (`library`), on Claude Haiku and Sonnet and
on Codex when installed, three runs each by default. `--targets=hermes:default`
adds a local model through Hermes Agent, in a scratch Hermes home with no
plugins, memory, or `skills.external_dirs`. It records harness,
model, arm, runs, per-check pass rates, and which skills fired in ignored
`local/evals/behavior/last-run.tsv`, with every transcript and diff beside
it. Without `--live` it re-scores the recorded `fixtures/`, and fails when a
fixture scores differently from its `expect` file or a check is never seen
both passing and failing; CI runs that mode. When a live answer is scored
wrong, fix the check and add the answer as a fixture. Write a new skill only
for a trap the `bare` arm misses. A copied file is not evidence that a skill
loads.

## Ownership

Edit the source here and deploy whole folders. Deployment refuses a
same-name directory it does not own; `--adopt` transfers ownership after a
backup.
