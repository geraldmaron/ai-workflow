---
name: implementation-planning
description: >-
  Use when asked to plan or sequence known work before building it:
  "write an implementation plan", "how would you build X", "plan this
  out", a change across several files or services. A task plan with the
  questions to decide first and a done-check on every task. Not for whether
  to build it (decision-framing), the spec (requirements-structuring), or a
  rollout (launch-readiness).
license: Apache-2.0
metadata:
  version: 0.1.0
---

# Implementation planning

Produces a plan a person who has not seen the conversation can build from:
the decisions they cannot make alone, in the order they are needed, with a
check that says when each piece is done.

## Scope and stand-down

Engage when the work is known but has more than one step that could go in
the wrong order, or more than one person or session will carry it out.

Stand down, in one line, when the change is one obvious step: do it and
prove it instead. When the open question is whether to build at all, or
what to build, name that and hand it to the sibling that owns it before
planning around a guess.

## 1. Read before planning

Read the code, spec, or request the plan rests on. Copy the constraints
the request states (versions, limits, datastores, deadlines) word for word;
the plan is judged against them. A fact the plan depends on and you did not
observe is marked `[assumed]`.

## 2. Put the questions first

List the questions whose answer would change the plan, above the tasks.
Each carries the default the plan assumes until someone answers. A question
that changes nothing, or that you can settle by reading, does not go here.
If there are none, write `Decide first: none`.

## 3. Cut the tasks

- Each task ends in a working state someone could check. Setup, config, and
  docs fold into the task whose deliverable needs them.
- Split only where a reviewer could reject one task and accept its
  neighbor.
- Order by dependency, and put the task that tests the riskiest assumption
  as early as the order allows.

## 4. Fill each task

Use this shape for every task:

```
Task N: <the deliverable, as an outcome>
  Touches:  <files, tables, services, or components>
  Uses:     <names and signatures it relies on from earlier tasks> | nothing
  Provides: <names and signatures later tasks rely on> | nothing
  Done when: <the command or observation, and the result that means pass>
```

The check belongs to the task. A testing section at the end is a plan whose
tasks have no definition of done.

## 5. Name what no task tests

Below the tasks, list up to five inputs or failure modes the request
implies but no task's check exercises: concurrency, the store being down,
empty or huge input, a retry, a second caller. For each, add its check to
the task that owns the code and keep the line here as the reviewer's list.

## 6. Cut it to proportion

A plan records decisions. A line that decides nothing ("handle edge
cases", "add tests", "TBD") is a gap: decide it or move it to the questions.
Code the signature and the check already determine is a transcript: delete
it. A code block appears only for an algorithm nothing else pins down.

## The plan's shape

```
Plan: <the goal in one sentence>
Approach: <two or three sentences: the design, and the alternative rejected and why>
Constraints: <from the request, verbatim, one per line>
Decide first: <question - default assumed until answered> | none
Out of scope: <deliberate exclusions, one line each> | none

Task 1: ...
Task 2: ...

Not covered by any check: <up to five, each pointing at the task that now tests it> | none
Rollout: <one line, or "hand to launch-readiness">
```

## Example

"Add a CSV export of a customer's invoices to the admin app."

```
Plan: Admins download one customer's invoices as CSV from the customer page.
Approach: Stream rows from the existing invoices query into the response.
  Rejected: a background job and emailed file; the largest customer has
  4,000 invoices, which streams in under a second [assumed; check in Task 1].
Constraints: No new dependencies. Admin routes require the admin role.
Decide first: Include voided invoices? - default: exclude.
Out of scope: Export of all customers. Scheduled exports.

Task 1: GET /admin/customers/:id/invoices.csv returns the customer's invoices.
  Touches:  routes/admin.js, queries/invoices.js
  Uses:     listInvoices(customerId) - existing
  Provides: invoicesToCsv(rows) -> string
  Done when: npm test passes a test that requests the route for a fixture
             customer and gets a header row plus 3 data rows; the
             4,000-invoice fixture responds in under 1 s.
Task 2: An Export CSV button on the customer page downloads the file.
  Touches:  views/customer.html
  Uses:     the Task 1 route
  Provides: nothing
  Done when: clicking it in the running app saves <customer>-invoices.csv
             that opens in a spreadsheet with the same rows as the page.

Not covered by any check: a non-admin calling the route (Task 1 now tests
  403); commas and quotes in descriptions (Task 1 now tests escaping).
Rollout: ships behind no flag; read-only and admin-only.
```

## Before finishing

- Constraints copied verbatim; every requirement maps to a task.
- Questions sit above the tasks, each with its default.
- Every task has Touches, Uses, Provides, and Done when.
- Names and signatures match between the tasks that provide and use them.
- No line decides nothing; no code the check already determines.

A check that was skipped says `not done: <reason>`.

## Works with

- requirements-structuring when the spec is still in someone's head.
- decision-framing for a question in "Decide first" that is expensive to
  reverse.
- implementation-verification while each task is built and checked.
- launch-readiness when the plan ends in a customer-visible rollout.
- adversarial-review to challenge the finished plan before work starts.

Each is optional. This skill works alone.
