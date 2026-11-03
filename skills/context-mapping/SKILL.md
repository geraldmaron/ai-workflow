---
name: context-mapping
description: >-
  Maps an unfamiliar codebase, service, or integration before anyone changes
  it: parts, owners, dependencies, boundaries, and unknowns, each tagged
  with how it was observed. Use when inheriting or taking over a system,
  before touching code whose neighbours you do not know, or when asked what
  depends on what. Not for entering a new role (org-entry), past decisions
  (research), or a one-line change whose neighbours do not matter.
license: Apache-2.0
metadata:
  version: 0.5.0
---

# Context mapping

Produces a short map a stranger with your access could act from: what may
be changed, what must not be touched, whom to ask, and what nobody knows
yet.

## Scope and stand-down

Engage when acting inside a system you did not build and do not hold in
your head, and a wrong assumption about a relationship would cost real
work.

Stand down, in one line, when you already hold the map, or when the task is
too small to be endangered. Test: name the relationship assumptions the
task rests on. If there are none, or all would survive a challenge,
proceed without the map.

## 1. Build the map

One short document, readable in a few minutes, using the skeleton in
[references/map-template.md](references/map-template.md): entities, typed
relationships, obligations, boundaries, unknowns.

Relationship types are closed: owns, depends-on, feeds, blocks,
supersedes. A relationship that fits none is two of them, or an unknown.
No untyped arrows.

## 2. Tag every fact with how you know it

- **read**: you inspected the thing itself (the code, the config, the
  schema, the running system's state).
- **ran**: you executed it and observed the behavior.
- **was-told: <who or which document>**: a person or a document asserted
  it. A design document is `was-told`, not `read`, because it describes the
  thing rather than being it.
- **inferred**: concluded from naming, layout, or resemblance. Allowed, and
  always visible.

A relationship the task leans on is upgraded to `read` or `ran` of the
thing itself, or it moves to unknowns. Conflicting sources are recorded as
a conflict with both named, never silently resolved.

## 3. Unknowns are the spine

Zero unknowns is a red flag. Classify each:

- **not-yet-looked**: a place to look exists; nobody has.
- **looked-and-unclear**: examined, still ambiguous; say what was examined.
- **unknowable-from-here**: needs access, authority, or a person this work
  lacks; name which.

Promote an unknown to a fact only with evidence from step 2.

## 4. Date it, and refresh what you lean on

The map carries an as-of date. When the gap is wide or the system moves
fast, the first step of new work is a refresh of the relationships the task
leans on. Record drift; keep superseded entries visible.

The map is the user's artifact. Keep it as plain text where the user keeps
documents. If this environment cannot write files, put the map in the
response and say so.

## 5. The stranger test

Read the finished map as someone with your access and none of your
context. Every place you silently supply knowledge is a missing line.

## Example

Two entries from a map of an inherited billing service:

```
Relationships
- invoicing-worker depends-on rates-cache: stale rates produce wrong totals
  [seen: ran; stopped the cache in staging, totals fell to zero]
- rates-cache feeds reporting-export: nightly CSV
  [seen: was-told: ARCHITECTURE.md, 2024; conflicts with code, which reads
  rates from the database directly: read]

Unknowns
- Who is paged when invoicing-worker fails [not-yet-looked: alert routing config]
- Whether reporting-export has consumers outside finance [unknowable-from-here:
  needs the finance team]
```

The architecture document said one thing and the code did another. The
map records both and marks the document as a claim, not an observation.

## Before finishing

- Every relationship typed from the closed set.
- Every entity, relationship, and obligation tagged with how it was seen;
  conflicts recorded as conflicts.
- Relationships the task leans on are `read` or `ran`, or listed as
  unknown.
- Unknowns present and classified.
- As-of date present; stale ground the task touches refreshed.
- Stranger test done; additions made.

A check that was skipped says `not done: <reason>`.

## Works with

- research (internal history mode) explains why something is the way it
  is; this skill
  records what is.
- org-entry owns the people and decision map of a new role; this skill owns
  the technical one.
- implementation-verification takes the map's dependency list as the blast
  radius for a change.

Each is optional. This skill works alone.
