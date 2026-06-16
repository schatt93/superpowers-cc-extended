# Superpowers "auto model selection" — how it works + adversarial test results

## What it is

Two parts:

1. **Routing rules** (`skills/subagent-driven-development/SKILL.md:96-109`) — "use the least
   powerful model that can handle each role":

   | Task signal | Tier | Model |
   |---|---|---|
   | 1-2 files, complete spec (mechanical) | cheap/fast | Haiku |
   | Multi-file, integration, debugging (judgment) | standard | Sonnet |
   | Architecture, design, review, broad understanding | most capable | Opus |

   Plus escalation: a `BLOCKED` subagent gets re-dispatched on a *more* capable model, never a
   silent same-model retry.

2. **Enforcement hook** (`hooks/examples/pre-agent-task-dispatch-validate.sh`) — optional
   `PreToolUse` hook on `Agent`. Reads the in-progress task's `json:metadata`
   (`{"model","subagentType","dispatchBrief"}`), compares to the dispatch, **blocks (exit 2)** on
   mismatch. Specified at plan time by `writing-plans`.

This maps onto the saved preference `feedback_model_routing` (Sonnet=writing, Opus=research/audit,
Haiku=mechanical).

## Wiring (copy-paste — apply yourself; not auto-installed)

Add to `~/.claude/settings.json` or a project `.claude/settings.local.json`. Point `command` at the
installed hook (version path will change on update):

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Agent", "hooks": [
        { "type": "command",
          "command": "bash \"$HOME/.claude/plugins/cache/superpowers-extended-cc-marketplace/superpowers-extended-cc/5.5.0/hooks/examples/pre-agent-task-dispatch-validate.sh\"",
          "async": false } ] }
    ]
  }
}
```

Disable anytime: env `SUPERPOWERS_DISPATCH_GUARD=0`.

## Adversarial test results

**Deterministic battery (`test-dispatch-guard.sh`): 14/14 pass.** The hook does what it says —
blocks model/subtype/brief mismatches, allows matches, catches an omitted `model` field, fails
open on malformed metadata / missing transcript, respects the escape hatch.

**Adversarial code review verdict: advisory nudge, NOT trustworthy enforcement.** Key findings:

| # | Class | Finding (relevance for a cooperative single operator) |
|---|---|---|
| 1 | false-block | **Exact string match on model.** Plan alias `"haiku"` vs a full id `claude-haiku-4-5`, or an **omitted** model (inherits default), wrongly blocks legitimate dispatches. *Most likely real-world friction.* |
| 2 | no-op | **Synthetic task-id counter ≠ real ids.** On resumed sessions or non-integer/UUID task ids, `TaskCreate`/`TaskUpdate` don't reconcile → metadata reads empty → guard silently allows everything. *It just won't fire in common cases.* |
| 3 | fail-open | **Fails open on any error** (ERR trap + `2>/dev/null` + `\|\| echo {}`). Missing `python3`/`jq` (e.g. another machine) → silently off. |
| 4 | bypass | **Coordinator controls every keyed input** — mark task completed then dispatch, rewrite the description fence, or `SUPERPOWERS_DISPATCH_GUARD=0`. Fine for cooperative use; means it's not a hard gate. |
| 5 | robustness | Full-transcript slurp + regex re-scan on every Agent call; non-greedy fence regex matches the first of multiple fences. |

## Bottom line

- **Adopt the routing RULES** — they're sound and match your existing preference. The cost win is
  real (Haiku ≈ ⅓ Sonnet; reserve Opus for judgment/audit).
- **Treat the hook as optional advisory**, not the enforcement superpowers bills it as. For your
  cooperative single-operator use the security bypasses don't matter, but the **false-blocks (#1)**
  and **silent no-op (#2)** do — it may nag on valid dispatches and miss real ones.
- If you want it reliable, the highest-value fix is **model-alias normalization** (#1); deciding
  fail-closed vs fail-open (#3) is a real tradeoff (enforcement strength vs blocking work on
  transient errors).
