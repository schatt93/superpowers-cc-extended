# superpowers-cc-extended

A **token-optimized, capability-extended** fork of [`pcvelz/superpowers`](https://github.com/pcvelz/superpowers) (`superpowers-extended-cc`) — an agentic skills framework for Claude Code. Same battle-tested discipline (brainstorming, TDD, debugging, planning, code review), with a **leaner always-on footprint** and new skills for thorough testing, adversarial auditing, E2E, output economy, smart dispatch, and org engineering standards.

> Based on `superpowers-extended-cc` by pcvelz (itself a fork of `obra/superpowers`). MIT licensed. Optimizations + extensions by schatt93.

## Install

```bash
claude plugin marketplace add schatt93/superpowers-cc-extended
claude plugin install superpowers-extended-cc@superpowers-cc-extended
```

Or in a session:

```
/plugin marketplace add schatt93/superpowers-cc-extended
/plugin install superpowers-extended-cc@superpowers-cc-extended
```

> It keeps the plugin name `superpowers-extended-cc` (a drop-in replacement). If you already have the upstream plugin installed, uninstall it first to avoid a name clash.

## Why this fork

**1. Leaner always-on context.** Only one file is injected into *every* conversation (`using-superpowers`, via the SessionStart hook). It was rewritten **−31.2%** (1302→896 tok — cut Claude-Code-irrelevant multi-platform sections, flowchart→list) and 7 registry descriptions were tightened (−124 tok), with **zero loss of Claude-Code behavior** (independently, adversarially audited: only non-CC platform text was dropped — every Red-Flags row, the rationalization block, and the skill-priority rules are byte-preserved, and inherited skill bodies change only by *appended* cross-references, never deletions). This release also *adds* the 8 new skills' + 3 agents' descriptions to the always-on registry (+491 tok), so the **net always-on change is −39 tok** — a smaller always-on footprint *while* shipping 11 new capabilities.

**2. New capabilities** (each skill *body* is on-demand — zero cost until invoked; their descriptions are the registry cost already counted in the −39 net above). Each is authored to the `writing-skills` doctrine and **validated**: all are structurally checked (lint-clean, balanced fences, resolvable links, trigger-only descriptions), and the four capability skills (`writing-tests`, `e2e-testing`, `adversarial-audit`, `orchestration-routing`) also pass live triggering tests (`plugin/tests/skill-triggering`). The `*-standards` and `concise-output` skills are contextual/support skills, exercised via cross-references rather than first-response triggering:

| Skill | What it does |
|---|---|
| `writing-tests` | The five-path coverage model (Happy / Bad / Bumpy / Chaos / Death), boundary-only mocking, no stubs/tautologies, mutation-strength bar |
| `e2e-testing` | Full-journey tests across real boundaries; five paths at system scale + load/soak/chaos + device matrix |
| `adversarial-audit` | Parallel red-team of a design, claim, or finished product on non-overlapping, evidence-required attack lenses |
| `concise-output` | Output-token discipline: results-first, structured-over-prose, capped/shaped subagent returns (~5× input price) |
| `orchestration-routing` | Smart dispatch: pick execution shape (inline / agent / parallel / Workflow) + compute tier per task |
| `architecture-standards` | Org architecture: UDF/BLoC, hexagonal/DDD/CQRS, saga+outbox/effectively-once, L4/L7/BGP, DLQ |
| `delivery-standards` | Org delivery/ops: blue-green/canary, OAuth2.1 token-exchange, RTO/RPO tiers, split-brain |
| `compliance-standards` | Org compliance/supply-chain: OPA policy-as-code, SBOM, Cosign signing + admission control |

**3. Model + effort routing.** Three tier agents — `sp-mechanical` (haiku), `sp-standard` (sonnet), `sp-deep` (opus) — let `orchestration-routing` send each delegated task to the cheapest tier that can do it. The agent's **model** is baked into its frontmatter; **effort** is the tier's intended reasoning level, passed at dispatch (advisory — Claude Code doesn't read an `effort:` field from an agent file). Main-loop thinking/effort stays user-controlled; the skill *advises*, it can't auto-set it.

## Full skill set

Inherited from upstream + the above. Grouped:

- **Process:** `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `orchestration-routing`
- **Discipline:** `test-driven-development`, `writing-tests`, `e2e-testing`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `adversarial-audit`, `concise-output`
- **Standards (org):** `architecture-standards`, `delivery-standards`, `compliance-standards`
- **Lifecycle:** `using-git-worktrees`, `finishing-a-development-branch`, gate skills (`specifying-gates`, `checking-gates`)
- **Meta:** `writing-skills`, `using-superpowers`

## How it works

- **Always-on (every conversation):** the `using-superpowers` bootstrap + the skill *registry* (each skill's name + one-line description). This is what makes Claude *aware* of the skills and when to use them — so descriptions are kept tight.
- **On-demand:** a skill's full body loads only when invoked via the `Skill` tool. Most of the framework costs **zero tokens** until used.
- **Discovery:** Claude checks the registry on every task; the right skill triggers from its description. Skills cross-reference each other (`REQUIRED BACKGROUND:`) so invoking one surfaces related ones.

## Usage

Skills trigger automatically from their descriptions — start a task and the relevant discipline kicks in (e.g. "build X" → brainstorming → planning → TDD). You can also invoke any skill explicitly with the `Skill` tool / `/`-command. The `(org)` standards skills fire at design, release, and CI/supply-chain time; your project's `CLAUDE.md` always overrides them.

## Development

This repo is also the optimization workspace:

- `plugin/` — the installable plugin (skills, agents, hooks, commands).
- `measure.mjs` — token + structural-lint + body-preservation harness. `node measure.mjs measure plugin <name>` then `node measure.mjs diff baseline <name>`. The `diff` gate fails unless the always-on cut ≥30%, lint regressions ≤0, **and** every inherited skill body is still an additive superset of its `pristine-baseline` version (no discipline silently removed).
- `deploy.sh` — apply the optimized files into a live local install (dry-run by default; `--apply`).
- `docs/`, `OUTPUT-LEVERS.md`, `MODEL-ROUTING.md` — design record, output-token levers, and model/effort routing notes.
- Git tag `pristine-baseline` marks the unmodified upstream copy (history is scrubbed of build artifacts).

## Credits & license

Fork of [pcvelz/superpowers](https://github.com/pcvelz/superpowers), itself a fork of [obra/superpowers](https://github.com/obra/superpowers). MIT — see `plugin/LICENSE`.
