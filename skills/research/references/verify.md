# Verify mode

For claims someone will decide, spend, accuse, or publish on. Adds four
rules to the base method.

## Mark every load-bearing claim

On the same line as the claim: money, percentages, dates, durations,
statute references, proper-name assertions, anything the conclusion
would change without.

- `[cite: <source>]` for provided or connected material actually read.
- `[research: <title, publisher, identifier>]` for public material actually
  opened. Never a bare domain.
- `[unverified]` plus one sentence on what would settle it.

Separate a lookup attempt from its result: name the query or document, what
came back, and what was kept. A search that returned nothing is not
evidence that nothing exists.

## Class each source on first use

- **Record**: the thing itself (filing, statute, contract, commit,
  transcript).
- **Derived record**: an official restatement (index, certified extract).
- **Aggregator**: someone's write-up (news, encyclopedia, vendor blog).
- **Inference**: your conclusion, marked every time it appears.

When a date, status, or name is asserted, say which kind of date the
source gives: when it happened, when it was recorded, or when it was last
checked. Authority is claim-specific: a provided export can be stale and a
primary record can correct it. Keep the conflict visible and explain the
choice.

## Look for the refutation

When the evidence admits more than one explanation, state the leading one
and its strongest rival (often "the record is incomplete" or "there is an
innocent explanation"), name what would refute each, and look for that
specifically. Weigh by what survived refutation. If this reversed or
weakened the draft conclusion, say so. When independent records settle the
matter, say that instead; do not manufacture a rival.

## State coverage and quantities

One sentence on what the sources cover (population, geography, period) and
what falls outside. Classify notable absences: not recorded, not yet
collected, or did not happen; an unclassifiable absence stays unknown.

For each material number: source quantities, units, denominator, time
basis, and the calculation. Do not mix gross with net or counts with rates.
Against a threshold, state the boundary rule and the distance from it. A
computed gap is not an order quantity, a budget, or an authorization.

## Finding block

```
Claim:      <the claim being checked>
Verdict:    supported | contradicted | unresolved
Evidence:   <record or derived record> [cite|research: ...], date kind: <happened|recorded|checked>
Independent: <n> sources that could have disagreed | single-source
Rival:      <the strongest other explanation, and what was looked for to refute it> | none needed
Coverage:   <what the evidence covers, and what it does not>
```

## Example

Claim: "Our main competitor holds 40 percent of the market."

```
Claim:      Competitor X holds 40 percent of the <segment> market.
Verdict:    unresolved
Evidence:   X's investor deck, slide 9, "40% share" [research: X Q2 2026
            investor presentation, X investor relations site, opened 2026-10-29],
            date kind: recorded; no denominator or source given on the slide.
            Analyst report cited by the deck not opened [unverified: paywalled].
Independent: single-source; the two news articles found restate the deck.
Rival:      The 40 percent is of X's own addressable definition, not the
            segment as we define it. Looked for: X's segment definition in
            the deck's appendix. Not stated.
Coverage:   Company self-report, one quarter, no third-party measurement.
```
