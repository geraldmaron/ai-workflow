# Internal history mode

For questions about a company's own past where no single record states
the answer. Companies rarely document a decision; they leave traces of it.
Reconstruct from the traces, then confirm against a system that would have
had to change if the reconstruction were true.

## Name the evidence before searching

| Hunting | Look first | What settles it |
|---|---|---|
| A decision | Ticket state change, doc revision, announcement post | A dated statement from someone with authority to make it |
| Why it was built this way | The original proposal, the design doc's first version, the constraint in the ticket | The constraint, with whether it still holds stated separately |
| The real owner | Who is paged, who approves changes, who answers questions now | The approver of the last few changes, not the chart |
| A policy's origin | The policy's first version, the incident before it | An incident review dated just before the policy appeared |
| Why it was killed | Planning docs for the period, budget or headcount changes, shared calendars | The budget or priority document, not a recollection |

## Build a chronology

Order everything found by timestamp, not by search rank. Anchor on the
earliest known date and bracket searches around it. The chronology shows
where the decision happened even when its content is missing from every
trace.

## Search the workspace's own words

Zero results usually means the wrong vocabulary. Find the local codename,
abbreviation, or former name first, then search again. Search the words of
the objection ("this will break billing") rather than the words of the
decision; objections are vivid and searchable. Include archived and
renamed channels.

Search operators differ by tool. Use whatever the workspace's search
supports for scoping by channel, author, and date range; the examples
below are one tool's syntax and must be adapted.

```
in:#channel from:@person before:2024-03-01 after:2024-02-01 "exact phrase" -noiseword
```

## Work the quieter layers

In rough order of reliability: ticket change logs (who moved it, when,
why); version-control history (blame the line, read the change, read its
review); document version history (diff the first version against the
current one; the deleted paragraph is often the finding); calendars (a
meeting's attendee list is a list of candidates for who was in the room,
not proof of who decided); configuration, flags, alert routing, and
on-call rotations (these name real owners).

## Read the whole thread, then check what came after

Never quote a thread read only from the top. After finding a decision,
search the same terms forward until the system of record confirms the
current state; a reversal reuses the original's vocabulary. Check whether
the person stating the decision had authority to make it. A thread that
ends unresolved is a pointer to a smaller, unrecorded conversation.

## Ask a person

When the written record runs out, or when motive matters and the record
gives only the outcome. Ask for the story ("what was going on when you
shipped that?"), not the rationale. Bring the trace you found and ask
whether the constraint it names was ever resolved. Let them give their
account before offering any hypothesis of your own. Ask who disagreed; the
person who lost the argument remembers the reasoning best. Prefer the
person who has since left the team. Treat every answer as one memory at
one moment.

If this environment cannot reach people, write down the exact questions
and who should be asked, and mark the affected findings unconfirmed.

## Confirm against a system of record

A thread and a memory are claims. Before relying on anything, confirm it in
the system that would have had to change if the claim were true: the code,
the configuration, the contract, the tracker, the ledger. A system of
record confirms what happened; it rarely confirms why. Keep the motive
labeled as inference unless a dated document states it.

## Finding block

```
Finding:    <what was recovered, one sentence>
Source:     <ticket / change / document / calendar / person>, with an identifier a reader can follow
Date:       <what the source says, and its kind: happened | recorded | last checked>
Confirmed:  system of record | person who was present | both | unconfirmed
Motive:     stated in <source> | inferred from <what> | unknown
Superseded: no | yes, see <where the later change is recorded>
```

File the finding where the next person will look (the project's docs, a
runbook, the originating ticket) with the evidence and the date recovered.
If filing is not possible here, say so and give the text to file.
