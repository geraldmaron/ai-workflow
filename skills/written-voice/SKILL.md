---
name: written-voice
description: >-
  Rewrites or drafts prose for other people in one plain, direct voice:
  decision first, no hype, claims only as strong as the evidence, no
  machine tells. Use for specs, proposals, status updates, announcements,
  READMEs, and reports, or when asked to make something sound less like a
  robot wrote it. Not for commit messages (commit-and-pr), chat replies, or
  what the document should decide.
license: Apache-2.0
metadata:
  version: 0.6.0
---

# Written voice

Produces prose a reader can act on after the first screen, with every
claim no stronger than what was observed.

## Scope and stand-down

Engage when someone other than the author will read the text and act on
it, and when bringing several documents into one voice.

Stand down, in one line, for text that is not a deliverable: chat replies,
code comments, commit messages, quick answers. When an external template
dictates the format (a legal filing, a grant form, a regulator's template),
fill it honestly and apply only the claims rules in step 3.

When the document ships under a named person's byline, read two or three
samples of their writing first if any are available. A construction that
is their habit stays, hype included, and the record says so. If no samples
exist, apply the house voice and say that too.

## 1. Name the reader

Two lines kept with the draft: who reads this and what they decide or do
because of it, and the one sentence they would keep. If the first has no
answer, the text is a note to self; stand down. If the second cannot be
written yet, the thinking is not done.

## 2. Write in the voice

- Decision or outcome first. A reader who stops after three sentences
  leaves with the right conclusion.
- Plain words, short paragraphs, headings that state what the section
  says, numbered steps for sequences. Contractions are fine.
- No hype unless defined and evidenced in the same passage. The word list
  is in [references/ai-tells.md](references/ai-tells.md).
- One recommendation where the document recommends, with alternatives as
  considered and not chosen. A document asked to compare neutrally for
  someone else's decision compares; it does not recommend.
- Tables only for comparisons with shared criteria.
- Facts, inferences, and recommendations visibly distinct.

## 3. Claims discipline

Applies to all prose, including text this skill otherwise stands down
from. Complete, tested, passing, verified, deployed, and working mean
observed. Believed-but-unverified is written as such. Load-bearing facts
carry a citation, `[unverified]`, or `[assumed]`. Failures are stated where
the reader will see them.

## 4. Shape and tells

- Genre skeletons (spec, proposal, status, announcement, README, decision
  log, handoff): [references/genre-shapes.md](references/genre-shapes.md).
  Internal working documents open with the standard header in
  [references/presentation.md](references/presentation.md). Announcements,
  READMEs, and decision-log entries do not; their first line is their
  content.
- Machine tells and their budgets:
  [references/ai-tells.md](references/ai-tells.md). Run the checker on the
  final text:

  ```bash
  python3 <skill folder>/scripts/voice-check.py draft.md
  ```

  If Python or a shell is unavailable, read the final text against the
  tells list by hand and say so in the record. Every flagged line is fixed
  or kept on purpose.

## 5. Unifying existing prose

1. Extract the keep-sentence first.
2. Reorder before rewording: decision to the top.
3. Sweep hype and stacked hedges.
4. Re-check every done, tested, or working claim. Better prose must not
   launder an unverified claim.
5. Preserve meaning conservatively. Flag ambiguity rather than resolving it
   with a fluent guess.

## Example

Before (the kind of text this skill rewrites):

```
We're excited to share that after careful consideration we've made the
decision to migrate our robust authentication platform to a new provider.
This isn't just an upgrade, it's a transformation. Users may experience
brief interruptions.
```

After, as an announcement:

> On 12 November, staff login moves to the company single sign-on. You will
> sign in with your directory password instead of the admin app password.
> Nothing else changes. Login may be unavailable for up to ten minutes
> between 06:00 and 06:30 UTC that day. Questions go to #admin-app.

What changed: the change, who, and when are the first sentence; the
reader's action is explicit; hype and the negate-then-correct construction
are gone; the interruption is a stated window, not a vague warning.

## Before finishing

- Reader and their action named; keep-sentence written.
- Decision on top; three-sentence test passes.
- Hype swept, or survivors defined and evidenced.
- Done means observed; facts marked; failures visible.
- Genre skeleton followed; dropped sections dropped on purpose.
- Checker run, or the manual pass stated; flagged lines fixed or kept on
  purpose.

A check that was skipped says `not done: <reason>`.

## Works with

- decision-framing settles a contested choice; this skill then writes it.
- artifact-quality owns the rendered file (layout, charts, export); this
  skill owns the words. Where both apply, the artifact's design system
  wins on presentation and this skill's rules win on prose.
- commit-and-pr owns commit messages and pull request bodies.

Each is optional. This skill works alone.
