# Method profiles

The techniques the skills share, each stated once. A skill that uses a
profile restates its rule in one or two lines inline, because every skill
folder must work on its own when deployed. This file is for maintainers: it
is the one place a technique's definition and lineage live, and it replaces
the per-skill bibliographies that used to sit in `references/sources.md`.

Lineage names where a technique comes from. Reading the source is never
required to follow a skill.

## Stand-down

Engage only when being wrong is expensive and the request is not already
clear. When the method is not applied, say so in one line and answer
directly. A method that fires on every request trains the reader to ignore
it where it matters.

Used by: every skill.
Lineage: house rule, from observed over-triggering.

## Evidence markers

Load-bearing claims carry their support on the same line: a citation to
material actually opened, `[unverified]` with what would settle it, or
`[assumed]` with the safe default. Never cite what was not opened. Never
narrate a search, a render, an interview, or a check that did not happen;
name what went unseen instead.

Used by: research, intake, requirements-structuring,
decision-framing, context-mapping, written-voice, product-strategy,
org-entry, metric-design, impact-measurement, customer-discovery,
artifact-quality, implementation-verification.
Lineage: ICD 203, *Analytic Standards* (ODNI); W3C PROV-DM.

## Observed, not inferred

Say how each fact was obtained: read, ran, was told by whom, or inferred
from structure. "Done", "tested", "passing", and "verified" mean observed,
never expected or remembered.

Used by: implementation-verification, context-mapping, root-cause-debugging,
artifact-quality, written-voice, commit-and-pr.
Lineage: Beck, *Test-Driven Development*; Naur, "Programming as Theory
Building".

## Rival hypotheses and disconfirmation

Before concluding, state at least two explanations that fit the evidence,
name what would refute each, and look for that specifically. Weigh by what
survived refutation, not by how much confirmed it. Refuted hypotheses stay
in the record.

Used by: research, root-cause-debugging, adversarial-review,
decision-framing, customer-discovery, impact-measurement.
Lineage: Heuer, *Psychology of Intelligence Analysis*; Popper, *The Logic
of Scientific Discovery*; Agans, *Debugging*.

## Falsifiable statements

A diagnosis, hypothesis, or assumption is written so that one observation
could prove it wrong, and that observation is named next to it.

Used by: root-cause-debugging, product-strategy, customer-discovery,
metric-design, decision-framing.
Lineage: Popper; Rumelt, *Good Strategy / Bad Strategy*; Martin and
Lafley, *Playing to Win*.

## One recommendation, then its strongest objection

Give one recommendation, first, addressed to the person who decides. Under
its own heading, state the strongest case against it in the words its
advocate would use. Alternatives appear as considered and not chosen.

Used by: decision-framing, written-voice, product-strategy,
research, adversarial-review, impact-measurement.
Lineage: Minto, *The Pyramid Principle*; Heuer; house rule.

## Pre-mortem

Assume the recommendation was adopted and failed. Write the most likely
specific story of how, the early signal that would show it, and whether
anything cheap now makes the failure survivable. A generic pre-mortem was
not performed.

Used by: decision-framing, adversarial-review, launch-readiness,
product-strategy, org-entry, research.
Lineage: Klein, "Performing a Project Premortem", HBR 2007.

## Independent reviewer

Self-review in the author's context rarely corrects reasoning; a reviewer
without that context, or findings anchored to external checks, does.

Used by: adversarial-review.
Lineage: Huang et al., "Large Language Models Cannot Self-Correct
Reasoning Yet", ICLR 2024 (arXiv:2310.01798).

## Reversibility sets the weight

Class a change as reversible, costly to reverse, or one-way, and scale
process to the class. Reversible work starts now and carries its
assumptions with it. One-way work earns the full method. When unsure,
class upward.

Used by: decision-framing, launch-readiness, intake,
implementation-verification, commit-and-pr.
Lineage: Bezos, Amazon shareholder letter 1997 (Type 1 and Type 2
decisions); Forsgren, Humble and Kim, *Accelerate*.

## Earned questions

Before handing a question back, check whether it can be settled from held
material, something reachable, or one bounded pass. Hand back only what
needs authority, access, or a decision the researcher lacks, and say which.
Everything else proceeds on a labeled assumption.

Used by: intake, requirements-structuring, research, context-mapping.
Lineage: Schein, *Humble Inquiry*; Gause and Weinberg, *Exploring
Requirements*.

## Literal output shapes

Where a deliverable has a shape (a record, a brief, a map, a commit
message), the skill gives the shape as a code block and the output follows
it exactly. A line that was not done says `not done: <reason>` rather than
disappearing.

Used by: every skill that produces a deliverable.
Lineage: Nygard, "Documenting Architecture Decisions" (ADR shape); house
rule.

## Failure-mode catalog

Each skill names the specific ways its task goes wrong, as a short list a
reader can check against, not as general caution.

Used by: every skill, in its closing checks.
Lineage: Dekker, *The Field Guide to Understanding Human Error*; Reason,
*Managing the Risks of Organizational Accidents*.

## Domain lineage by skill

Sources specific to one skill, kept for maintainers. Not loaded at run time.

- adversarial-review: Zenko, *Red Team*; Kahneman and Klein, "Conditions
  for Intuitive Expertise" (2009).
- artifact-quality: Tufte, *The Visual Display of Quantitative
  Information*; Cleveland, *The Elements of Graphing Data*; Bringhurst,
  *The Elements of Typographic Style*; WCAG.
- customer-discovery: Torres, *Continuous Discovery Habits*; Fitzpatrick,
  *The Mom Test*; Portigal, *Interviewing Users*; Glaser and Strauss on
  saturation.
- impact-measurement: Kahneman, *Thinking, Fast and Slow*; Rubin (1974) on
  counterfactuals.
- implementation-verification: Fowler, *Refactoring*; Humble and Farley,
  *Continuous Delivery*; Nygard, *Release It!*.
- intake: Allen, *Getting Things Done*; Grice, "Logic and Conversation";
  Gause and Weinberg, *Are Your Lights On?*.
- launch-readiness: Beyer et al., *Site Reliability Engineering*
  (release engineering, postmortems).
- metric-design: Amplitude, *The North Star Playbook*; Wodtke, *Radical
  Focus*; Rodden, Hutchinson and Fu (HEART); Goodhart; Kohavi, Tang and Xu,
  *Trustworthy Online Controlled Experiments*.
- org-entry: Watkins, *The First 90 Days* (STARS); Kotter, *Power and
  Influence*; Cross and Parker, *The Hidden Power of Social Networks*.
- product-strategy: Rumelt; Martin and Lafley; Doerr, *Measure What
  Matters*.
- requirements-structuring: IEEE 29148; Wiegers and Beatty, *Software
  Requirements*; Gilb, *Competitive Engineering*; Amazon PR/FAQ practice.
- research: Heuer and Pherson, *Structured Analytic
  Techniques*; Groves and Lyberg, "Total Survey Error"; Gebru et al.,
  "Datasheets for Datasets"; Records in Contexts (ICA).
- root-cause-debugging: Zeller, *Why Programs Fail*; Agans.
- written-voice: Gopen and Swan, "The Science of Scientific Writing";
  Williams and Bizup, *Style*; Orwell, "Politics and the English Language";
  Mayer, *Multimedia Learning*; Kobak et al. on LLM vocabulary spikes;
  WikiProject AI Cleanup, "Signs of AI writing".
