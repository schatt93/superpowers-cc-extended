# Superpowers token optimization — design & decision record

**Date:** 2026-06-16
**Target:** `superpowers-extended-cc` v5.5.0 (active install), working copy under `plugin/`.
**Goal (reframed after audit):** fewer tokens, reasoning **preserved**, skill **triggering improved**. (NOT "more reasoning by cutting tokens" — see audit.)

## How loading actually works (verified)

- The SessionStart hook (`plugin/hooks/session-start:18`) `cat`s **exactly one** file into every
  conversation: `skills/using-superpowers/SKILL.md` (1,302 real cl100k tokens). Re-injected on
  `startup|clear|compact`.
- Every other skill loads **on-demand** via the `Skill` tool. Cost = 0 unless invoked.
- `skills/shared/*` is **pointer-only** (no auto-transclusion). `GEMINI.md:2` hard-`@`-includes
  `references/gemini-tools.md`.

## Scope (post adversarial audit)

The original "full 16-skill rework" was dropped: ~98% of the corpus is on-demand, so body-compressing
the other 15 skills optimizes tokens that are rarely spent, and compressing discipline-skill bodies
risks behavior regression (their rationalization redundancy is load-bearing).

**IN scope:**
1. **Tier-0 rewrite** of `skills/using-superpowers/SKILL.md` — the only recurring cost.
   - CUT: multi-platform "How to Access Skills", "Platform Adaptation", `references/` pointers.
   - RESTRUCTURE: the 28-line graphviz flowchart → numbered list (preserving every node).
   - PRESERVE VERBATIM: `<EXTREMELY-IMPORTANT>` gate, `<SUBAGENT-STOP>`, Instruction-Priority
     (minus non-CC filenames), Red-Flags table, Skill Priority, Skill Types, User Instructions.
2. **Corpus-wide CSO sharpening** — tighten the `description:` frontmatter of all 16 SKILL.md for
   better triggering. Frontmatter only; **no body edits**.
3. **Measurement hardening** — done (`measure.mjs`): real tokenizer, exact always-on contract,
   `diff` pass/fail vs threshold, structural lint, no-overwrite guard.

**OUT of scope / dropped:** Tier-1/Tier-2 body rework as a token play; `shared/` de-dup (nothing to
dedup + would add cost); deleting `gemini-tools.md` (live `@`-include); prose→table on argued
discipline prose.

## Success contract (pre-registered)

- Always-on real-token reduction **≥ 30%** (1,302 → ≤ 911).
- Structural-lint regressions **≤ 0** (baseline = 0 issues).
- Every protected block byte-identical post-edit (grep gate).
- Triggering spot-check: optimized `using-superpowers` still drives skill-check-before-acting.

## Safety / deploy

- All work in git'd workspace (`f647c54` = pristine baseline). Every edit is a revertible diff.
- Live install untouched. Deploy decision (fork vs `~/.claude/skills` override) deferred until the
  measured delta is in.
