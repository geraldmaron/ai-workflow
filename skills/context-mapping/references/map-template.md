# Context map template

Short enough to read in a few minutes. Small systems fill it thinly; that
is correct.

```
Context map: <system>
As of: <date>   Mapped by: <who>   For: <the task this map serves>

Entities
- <name>: <what it is, one clause> [seen: read | ran | was-told: <who/doc> | inferred]

Relationships   (typed; one per line)
- <A> owns <B> [seen: ...]
- <A> depends-on <B>: <what breaks if B changes> [seen: ...]
- <A> feeds <B>: <what flows> [seen: ...]
- <A> blocks <B>: <until what> [seen: ...]
- <A> supersedes <B>: <since when; what still reads B> [seen: ...]

Obligations     (what a part owes, and to whom)
- <entity> owes <what> to <whom>: <source of the obligation> [seen: ...]

Boundaries      (outside this map, on purpose)
- <thing>: <why out of scope for this task>

Unknowns        (each classified)
- <question> [not-yet-looked | looked-and-unclear: <what was examined> | unknowable-from-here: <who or what is needed>]
```

Relationship types are closed: owns, depends-on, feeds, blocks, supersedes.
A relationship that fits none is two of them, or an unknown.
