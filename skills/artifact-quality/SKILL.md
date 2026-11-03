---
name: artifact-quality
description: >-
  Checks a finished document, PDF, deck, spreadsheet, or report before it
  goes to a reader: the rendered file opened and walked surface by surface,
  every chart honest to its data, every diagram true to the system, export
  defects caught. Use when finishing or auditing a static deliverable
  someone else will read. Not for drafts, not for the prose itself
  (written-voice), and not for live interfaces (implementation-verification).
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Artifact quality

The rendered file, seen, is the deliverable. This skill produces an
inspection of it: per-surface, per-figure, per-export, with defects fixed
or accepted on record.

## Scope and stand-down

Engage when the output is a finished static file another person will
read, present, or forward, and a rendering step sits between the source
and what they see. Auditing someone else's finished file counts.

Stand down, in one line, for drafts, working notes, scratch output, and
conversational answers. When speed is explicitly preferred over polish, say
what was skipped. This skill judges the artifact's rendering and honesty of
depiction; whether the words and the argument are right belongs elsewhere.

## 1. One design system

If a template or house pattern exists for this audience, use it and say
so. Otherwise fix the minimum before styling, covering only the elements
the document actually has: grid and margins, type hierarchy, spacing,
tables, captions, numbering, headers and footers, contrast that survives
projection and print. Consistency inside the document matters more than
any single choice.

## 2. Figures honest to what they depict

Check each chart and diagram in this shape, filling only the fields that
apply to its kind:

```
Figure:    <title, where it appears>
Claim:     <what a reader concludes in three seconds>
Data:      <source, period, units, denominator>            (charts)
Scope:     <what system or boundary the diagram claims>     (diagrams)
Axes:      <ranges, baselines, any truncation>              (charts)
Missing:   <how absent data is shown> | none
Read-back: <values read off the rendered figure> | not numeric
Verdict:   honest | corrected: <what changed> | unverified: <why>
```

Charts carry units, period, and source on the figure. No truncated or
doubled axis that manufactures a trend; no precision the data lacks;
missing data shown as missing, never as zero. Diagrams show components,
connections, and boundaries that exist, with a legend where notation is
not self-evident. A four-row table often beats a chart.

## 3. Walk every surface of the rendered output

Open the exported file and inspect every page, slide, or sheet, including
the last ones, where defects concentrate. For a large sheet, scroll the
whole used range. Look for bad breaks, orphaned headings, overflow, blank
or missing surfaces, split tables, low-resolution images, unreadable text
at final size, drift in spacing or hierarchy, and furniture (numbering,
captions, cross-references, contents) that does not match the document.

```
Inspection
- p<n>-<n>: clean
- p<n>:     <defect> -> fixed | accepted: <why>
Renderer:   <how the file was produced and opened>
Surfaces:   <n> of <n> seen
```

Mark a range clean only if every surface in it was seen. If nothing here
can render or open the file, say so, name what went unseen, and mark the
inspection `not done`. Never describe a walkthrough that did not happen.

## 4. Check the export, not the source

Fonts embedded or substituted knowingly; images at the needed resolution;
links and cross-references resolving; text selectable where the medium
allows; file size proportionate; no editing residue carried over by
accident (comments, tracked changes, stale filters). Content hidden on
purpose (speaker notes, calculation columns) stays, and the record says it
is intentional.

Decks: check the smallest text at the size it will be viewed, and that each
slide survives being screenshotted alone. Spreadsheets: numbers are values
or intended formulas, not pasted text; units and precision consistent down
each column; sorting or filtering does not break an implied relationship.
Long reports: check hierarchy at the halfway point against the start.

## Example

```
Figure:    "Request flow", slide 4
Claim:     Requests pass through the gateway, then the auth service, then the API.
Scope:     Production request path for the admin app.
Missing:   none
Read-back: not numeric
Verdict:   corrected: the diagram showed a cache between gateway and auth that
           does not exist in production; removed, legend added for dashed lines.
```

## Before finishing

- Design system or template named.
- Every figure has a block with a verdict.
- Every surface inspected, with the record; unseen surfaces named.
- Furniture checked against the document.
- Each defect fixed or accepted with a reason.
- Export checked on the exported file.
- Residual risk stated.

A check that was skipped says `not done: <reason>`.

## Works with

- written-voice owns the words. On presentation, this skill's design system
  wins; on prose, written-voice wins.
- research owns whether the underlying claims are true; this skill checks
  that the figure depicts the data it cites.
- adversarial-review takes a figure whose claim an outside audience will act
  on (a board, a customer, a regulator).

Each is optional. This skill works alone.
