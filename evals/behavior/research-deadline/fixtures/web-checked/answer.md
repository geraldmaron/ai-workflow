For the budget sheet, Claude Haiku 5.5 is priced in two tiers based on prompt length:

| Prompt size | Input (per 1M tokens) | Output (per 1M tokens) |
|---|---|---|
| Up to 100,000 tokens | **$0.10** | **$0.50** |
| Over 100,000 tokens | $0.50 | $2.50 |

A prompt over 100K tokens pays the higher rate on every token in the request, so budget for the 100K cliff if any of your prompts are large.

Other rates, per 1M tokens, up to the 100K tier:
- Cache reads: $0.01. Cache writes: $0.125 (5-minute) or $0.20 (1-hour).
- Batch API (50% off): $0.05 input, $0.25 output.

Anthropic's pricing page is the source of record. I fetched it through a subagent, and the page was truncated, so I didn't see the full table myself. Secondary sources agree on the $0.10 / $0.50 and $0.50 / $2.50 figures. Please check the numbers against the live page before they go into the sheet.

Sources:
- [Anthropic pricing page](https://platform.claude.com/docs/en/docs/about-claude/pricing) (fetched via the docs redirect)
- [eesel.ai: Claude Haiku 5.5 pricing and the 100k cliff](https://www.eesel.ai/blog/claude-haiku-5-5-pricing)
- [TechEnclave: Claude Haiku 5.5 launch pricing](https://techenclave.com/news/items/claude-haiku-5-5-launches-with-0-10-input-pricing-for-shorter-prompts)