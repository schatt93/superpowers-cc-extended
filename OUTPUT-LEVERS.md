# Output-token levers (ranked)

Output tokens cost ~5x input. Levers, biggest first. **A skill/hook cannot set #1 or #2** —
they're harness/user-only (hooks get effort read-only). #3 and #4 are the automatable parts.

1. **Output style** — BIGGEST lever, your config. The active "explanatory" style mandates verbose
   insight blocks and "may exceed length constraints". For token-sensitive work, switch to a terser
   style: `/output-style default` (interactive) or set `outputStyle` in settings.json. Trade-off:
   loses the educational commentary.
2. **Reasoning effort** — your config. Lower = less internal reasoning spend. `/effort low|medium|high`,
   `--effort`, or `effortLevel` in settings.json. Raise only for hard tasks; drop for routine work.
3. **`concise-output` skill** (this workspace) — results-first, structured-over-prose, and (the big
   sub-lever) capped/shaped subagent returns. Subagent-validated ~65% reduction on a sample task.
   The only one a *skill* can drive.
4. **Per-dispatch model + effort** (`orchestration-routing` + `sp-mechanical`/`sp-standard`/`sp-deep`) —
   a cheaper tier generates fewer reasoning tokens. Route mechanical work to haiku/low.

Recommended combo for cost-sensitive sessions: terser output style (#1) + effort matched to task (#2)
+ `concise-output` active (#3) + tiered dispatch (#4).
