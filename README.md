# superpowers-extended-cc — token optimization (validated draft, NOT deployed)

A workspace copy of the active `superpowers-extended-cc` v5.5.0 plugin, optimized for
per-conversation token cost without losing context. The live install is **untouched**.

## Result (real cl100k tokens)

| Always-on surface (injected every conversation) | Before | After | Saved |
|---|---|---|---|
| `using-superpowers/SKILL.md` (SessionStart hook) | 1,302 | 896 | **−406 (−31.2%)** |
| 7 skill descriptions (skills registry) | 300 | 176 | **−124 (−41%)** |
| **Total recurring saving / conversation** | | | **~530 tokens** |

Structural lint: 0→0 regressions. Verbatim-preserved blocks (EXTREMELY-IMPORTANT gate, Red-Flags
table, Skill-Priority/Types, SUBAGENT-STOP) are byte-identical; Instruction-Priority is preserved
but trimmed of non-Claude-Code filenames (GEMINI.md/AGENTS.md). Triggering behavior independently
judged **preserved-and-improved**.

> Counts are cl100k — a proxy whose **percentages are tokenizer-invariant** (absolute integers differ
> on Claude). Recurring per-conversation saving = 406 (body) + 124 (descriptions) = **530 tok**; the
> corpus total drops 535 tok (a near-coincidence, not the same quantity).

## Added skills (from the Engineering Developer Guidebook)

Four new on-demand skills + Tier-1 pointers, all validated (subagent RED→GREEN, disjoint triggering confirmed):

| Skill | Purpose |
|---|---|
| `writing-tests` | The five-path coverage model (Happy/Bad/Bumpy/Chaos/Death), boundary-only mocking, no stubs/tautologies, mutation-strength bar |
| `adversarial-audit` | Parallel red-team of a design/claim/product on non-overlapping, evidence-required attack lenses |
| `e2e-testing` | Full-journey tests across real boundaries; five paths at system scale + load/soak/chaos + device matrix |
| `concise-output` | Output-token discipline: results-first, structured-over-prose, capped/shaped subagent returns (~5x input price) |

Tier-1 edits point `test-driven-development`, `verification-before-completion`, and `requesting-code-review` at these.

**Always-on ledger:** Tier-0 + CSO = −530 tok; +195 tok for the 4 new descriptions = **net −335 tok/conversation**. New skill bodies are on-demand only. **Output side:** `concise-output` cuts *generated* tokens — subagent-validated ~65% on a sample task, substance intact.

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
- `deploy.sh` — deploy the 8 changed files **+ 3 new skills** into the live install. **Dry-run by default; pass `--apply`.** Backs up + only overwrites known-pristine files; creates new skills if absent; auto-detects the active version.

## Deploy later (3 paths — not mutually exclusive)

- **In-place:** `bash deploy.sh` (dry-run) then `bash deploy.sh --apply` → savings live next `/clear`. Wiped by `/plugin update`; just re-run.
- **Fork:** push `plugin/` to a fork of pcvelz/superpowers, re-point the marketplace install.
- **Upstream PR:** contribute to pcvelz/superpowers; you get it back via normal updates once merged.

> Note: a `~/.claude/skills` override does NOT work for the Tier-0 win — the SessionStart hook
> reads the plugin's own file path, not the skills registry.
