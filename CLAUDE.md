# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is **not an application** — it is a Claude Code **plugin** (`superpowers-extended-cc`, an agentic skills framework) plus the **optimization workbench** used to produce it. Two distinct trees:

- **`plugin/`** — the shippable artifact (skills, agents, hooks, commands). This is what gets installed. Plugin manifest: `plugin/.claude-plugin/plugin.json` (name `superpowers-extended-cc`, currently v5.5.0).
- **Repo root** — measurement/deploy/verification tooling that operates *on* `plugin/` but is not part of the installable plugin. Marketplace entry: `.claude-plugin/marketplace.json` (marketplace name `superpowers-cc-extended`, points `source: ./plugin`).

The repo name (`superpowers-cc-extended`) and the plugin name (`superpowers-extended-cc`) differ deliberately — the plugin keeps the upstream name to stay a drop-in replacement.

## The core optimization thesis (read before editing skills)

Only **one file is injected into every conversation**: `plugin/skills/using-superpowers/SKILL.md` (the SessionStart hook cats exactly this file — see `plugin/hooks/session-start`). Everything else loads on-demand via the `Skill` tool and costs zero tokens until invoked.

Consequences that govern most edits here:
- The always-on file and the **skill-registry descriptions** (the `description:` frontmatter of every `SKILL.md`, surfaced in the registry) are the only things with an always-on token cost. Keep them tight.
- Per `writing-skills` doctrine, a `description:` states **WHEN to use** the skill (third person, trigger-only) — **never** a workflow summary. `apply-cso.mjs` enforces this for the skills/commands that historically violated it.
- Edits to discipline content (the skill bodies) must be **behavior-preserving and additive** — the claim is that no inherited discipline is *removed or altered*; permitted changes are trigger-only `description:` rewrites and *appended* cross-references. The always-on `using-superpowers` file is the sole exception (deliberately trimmed of non-Claude-Code platform text under the token gate). `measure.mjs`'s `diff` gate enforces this: it fails if any inherited skill body stops being an additive superset of its `pristine-baseline` version.

## Baseline anchoring

Correctness is measured against the git tag **`pristine-baseline`** (the unmodified upstream v5.5.0 copy), not a hardcoded file list. `deploy.sh` and `tokens-delta.mjs` diff against this tag, so they never go stale as files change.

## Common commands

All root scripts are Node ESM (`node X.mjs`) or bash. The repo uses `gpt-tokenizer` (real cl100k BPE tokens, not char estimates).

```bash
# Measure the corpus + structural lint (writes reports/<name>.json; refuses to clobber w/o --force)
node measure.mjs measure plugin <name>

# Compare two reports against the pre-registered threshold
# (PASS = always-on cut >= 30% AND lint regressions <= 0 AND inherited skill bodies preserved additive-only)
node measure.mjs diff baseline <name>

# Quantify the 7 rewritten registry descriptions (−124 tok). NOTE: this is only the savings side —
# the 8 new skills add +380 and 3 agents +111 to the always-on registry; net always-on is −39 (see README).
node tokens-delta.mjs

# Apply the trigger-only description rewrite (idempotent)
node apply-cso.mjs

# Deploy validated changes into the live local install — DRY-RUN by default
bash deploy.sh                 # preview against auto-detected install path
bash deploy.sh --apply         # write (backs up each file first)
bash deploy.sh --cache <path>  # override target install path
bash deploy.sh --apply --force # also overwrite files that differ from pristine

# Adversarial test battery for the model-routing enforcement hook
# (exit 0 = ALLOW dispatch, exit 2 = BLOCK dispatch)
bash test-dispatch-guard.sh
```

### Plugin test suites (under `plugin/tests/`)

These require the `claude` CLI on PATH (they invoke Claude Code and assert on behavior):

```bash
bash plugin/tests/claude-code/run-skill-tests.sh   # skill behavior suite (--verbose, -t <test>, --timeout)
bash plugin/tests/skill-triggering/run-all.sh      # does each skill trigger from its description?
bash plugin/tests/explicit-skill-requests/run-all.sh
```

`measure.mjs`'s structural `lint()` runs without an LLM and is the fast gate: it checks every `SKILL.md` for valid frontmatter (`name:`/`description:`), balanced code fences, and resolvable `references/`/`shared/`/`@`-include links. Run `measure` before/after any skill edit and keep lint regressions at 0.

## Plugin structure (`plugin/`)

- **`skills/<name>/SKILL.md`** — each skill. May have `references/` and a shared `skills/shared/`. Skills cross-reference via `REQUIRED BACKGROUND:` so invoking one surfaces related ones.
- **`agents/`** — three tier agents for `orchestration-routing` to dispatch to: `sp-mechanical` (haiku/low), `sp-standard` (sonnet/medium), `sp-deep` (opus/high). The main loop's own thinking/effort is user-controlled; these only affect delegated work.
- **`hooks/`** — `hooks.json` registers the SessionStart injection; `run-hook.cmd` is a cross-platform polyglot wrapper (cmd.exe finds bash on Windows, no-op `:` on Unix) so hook scripts can be extensionless. `hooks/examples/` holds the opt-in enforcement hooks (model-routing dispatch guard, user-gate revalidation, stop-deflection guard, etc.).
- **`commands/`** — slash-command wrappers around skills.
- Other dot-dirs (`.codex-plugin/`, `.cursor-plugin/`, `.opencode/`) are cross-platform mirrors; CC work lives in the directories above.

## Cross-platform note

Primary dev shell is PowerShell on Windows; a Bash tool is also available. The hook layer is engineered for Windows (`run-hook.cmd` resolves Git-for-Windows bash). When editing hooks, preserve the extensionless-script + polyglot-wrapper pattern — it exists specifically to dodge Claude Code's Windows `.sh` auto-detection.
