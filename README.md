# superpowers-extended-cc — token optimization (validated draft, NOT deployed)

A workspace copy of the active `superpowers-extended-cc` v5.5.0 plugin, optimized for
per-conversation token cost without losing context. The live install is **untouched**.

## Result (real cl100k tokens)

| Always-on surface (injected every conversation) | Before | After | Saved |
|---|---|---|---|
| `using-superpowers/SKILL.md` (SessionStart hook) | 1,302 | 896 | **−406 (−31.2%)** |
| 7 skill descriptions (skills registry) | 300 | 176 | **−124 (−41%)** |
| **Total recurring saving / conversation** | | | **~530 tokens** |

Structural lint: 0→0 regressions. Protected blocks (EXTREMELY-IMPORTANT gate, Red-Flags
table, Instruction-Priority) byte-identical. Triggering behavior independently judged
**preserved-and-improved**.

## What changed (and why the rest didn't)

An adversarial audit (4 agents) proved a full 16-skill rework was ROI-negative: only ONE file
is force-loaded every conversation (`using-superpowers/SKILL.md`, via `hooks/session-start:18`);
all other skills cost 0 tokens until invoked. So scope collapsed to the two surfaces that are
actually always-on:

1. **Tier-0** — rewrote `using-superpowers/SKILL.md`: cut CC-irrelevant multi-platform sections
   + `references/` pointers; converted the 28-line graphviz flowchart to a numbered list
   (every decision node preserved); kept all discipline content verbatim.
2. **CSO** — rewrote 7 skill `description:` fields to remove the "summarize-the-workflow"
   anti-pattern (which makes the model skip the skill body). Frontmatter only; no body edits.

Dropped as unsafe/ROI-negative: body-compressing the 15 on-demand skills, `shared/` de-dup
(pointer-only, would add cost), deleting `gemini-tools.md` (live `@`-include in `GEMINI.md`).

## Files

- `plugin/` — the optimized plugin (git baseline `f647c54` = pristine; later commits = edits)
- `measure.mjs` — token + lint harness. `node measure.mjs measure plugin <name> --force`, then
  `node measure.mjs diff baseline <name>` (pass/fail vs pre-registered threshold).
- `apply-cso.mjs` / `tokens-delta.mjs` — the CSO edit + its measurement.
- `docs/2026-06-16-tier0-cso-optimization-design.md` — design & decision record.
- `deploy.sh` — copy the 8 changed files into the live install (run deliberately; re-run after updates).

## Deploy later (3 paths — not mutually exclusive)

- **In-place:** `bash deploy.sh` → savings live next `/clear`. Wiped by `/plugin update`; just re-run.
- **Fork:** push `plugin/` to a fork of pcvelz/superpowers, re-point the marketplace install.
- **Upstream PR:** contribute to pcvelz/superpowers; you get it back via normal updates once merged.

> Note: a `~/.claude/skills` override does NOT work for the Tier-0 win — the SessionStart hook
> reads the plugin's own file path, not the skills registry.
