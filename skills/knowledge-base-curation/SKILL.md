---
name: knowledge-base-curation
description: >-
  Proposes moves, renames, and archiving for a personal knowledge base of
  notes: stray and untitled files, notes in the wrong zone, active notes
  that have gone stale. Produces a short checklist a person ticks; nothing
  is moved by this skill. Use for a one-off or recurring tidy of a notes
  vault or notes folder. Not for files a mechanical rule already sorts, not
  for source code, and not for redesigning the vault's layout.
license: Apache-2.0
metadata:
  version: 0.2.0
---

# Knowledge base curation

Produces a digest of at most fifteen proposed moves, each one line, each
reversible, for a person to approve. Deletion is never proposed.

## Scope and stand-down

Engage for a pass over a knowledge base with a structure worth protecting:
named zones for active work, an inbox, an archive. A notes folder inside a
code repository qualifies; the code does not.

Stand down, in one line, when nothing qualifies ("no candidates this pass"
is a healthy result), when a mechanical rule already owns the location
(propose a change to the rule instead), and when the request is really
about the layout itself (renaming zones, changing what a folder means).
That is a decision made separately, before the next pass.

## 1. Sweep the places strays collect

- The root, for anything that is not the top-level index and not in a
  zone.
- Untitled or default-named files, in any zone.
- The inbox, for anything that has sat longer than "just captured"
  describes.
- Files whose neighbours say they are in the wrong place.

## 2. Judge by content

Open every candidate. A filename is a claim about contents, often wrong.

- Real content under a default name gets a proposed name from its first
  heading or subject, and a destination in the zone the content belongs
  to.
- An empty shell gets proposed for the archive, unless it looks like a
  template or a deliberate placeholder, in which case leave it and say so.
- Before proposing a move, check for links to the file. A move that would
  break links says so on its line, so the person can fix them or decline.

## 3. Stale-check the active zones

Judge by content, not by modification date. A project note for work that
shipped or died is stale; a periodic note whose window closed and that
nothing references is a candidate; a guide superseded by a newer one is
stale even if edited recently. If it is unclear whether a note is still
true or still relied on, it is not a candidate. Checking whether the
content is still correct against the outside world is research, not
curation.

## 4. The digest

```
Curation digest <date>
- [ ] MOVE: "<path from root>" -> "<path from root>" | <zone by role>: <one-line reason>
- [ ] MOVE: ...
Skipped: <files that could not be opened or judged, with the reason> | none
Declined earlier: <proposals left unticked on two reviewed digests> | none
```

Paths are relative to the knowledge-base root, never absolute. A rename is
a move within the same folder. Name the destination by role ("the reading
zone") only when the path is not yet decided. At most fifteen lines,
highest value first, where value means: breaks something if left (a stale
guide people follow) before clutter (an empty shell).

A proposal left unticked on two digests the person reviewed is not
proposed a third time; it is listed under "declined earlier" so the next
pass knows. A digest nobody reviewed does not count as declined.

Example:

```
Curation digest 2026-10-29
- [ ] MOVE: "Untitled 4.md" -> "Areas/Reading/Notes on distributed consensus.md": real content; first heading names the subject
- [ ] MOVE: "Projects/Q1 vendor migration/plan.md" -> "Archive/Projects/Q1 vendor migration/plan.md": project shipped in March; nothing links here
- [ ] MOVE: "Guides/Deploy checklist (old).md" -> "Archive/Guides/Deploy checklist (old).md": superseded by "Guides/Deploy checklist.md"; two notes still link to the old one, fix links first
Skipped: "Inbox/scan-0412.pdf" (image-only, could not read)
Declined earlier: none
```

## 5. Stop

The skill ends at the digest. Moves happen only when a person ticks a line
and something else applies it.

## Before finishing

- Root, untitled files, and inbox swept, or skips stated.
- Every candidate opened; nothing proposed on filename alone.
- Active zones stale-checked by content.
- Links checked for every proposed move.
- Fifteen lines or fewer, highest value first, or "no candidates".
- Nothing moved, renamed, or deleted.

A check that was skipped says `not done: <reason>`.

## Works with

- research checks whether a note's content is still correct.
- decision-framing owns a change to the vault's layout.

Each is optional. This skill works alone.
