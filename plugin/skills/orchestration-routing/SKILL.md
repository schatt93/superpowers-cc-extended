---
name: orchestration-routing
description: Use when about to delegate or scale work — to pick the right execution shape (inline / one subagent / parallel agents / a Workflow) AND the right compute tier (model + effort) for the task. Routes to the sp-mechanical/standard/deep agents.
---

# Orchestration Routing

Match execution shape and compute to the task. Over-provisioning burns tokens; under-provisioning fails the task. Decide two things before delegating: the **shape** and the **tier**.

**REQUIRED BACKGROUND:** superpowers-extended-cc:dispatching-parallel-agents (parallel mechanism), superpowers-extended-cc:concise-output (cap subagent returns).

## 1. Pick the execution SHAPE

| Shape | When | How |
|-------|------|-----|
| **Inline** (no subagent) | Trivial, single-step, you already have the context | Just do it |
| **One subagent** | One bounded task needing isolated context / a fresh perspective | Agent tool, single dispatch |
| **Parallel agents** | 2+ INDEPENDENT tasks, no shared state, one round | dispatching-parallel-agents |
| **Workflow** | Deterministic MULTI-PHASE fan-out, pipelines, loop-until-done, or scale one context can't hold (audits, migrations, broad sweeps) | Workflow tool |

**Escalate to a Workflow when** the work (a) decomposes into phases with barriers/pipelines, (b) needs adversarial verification before committing, or (c) is too large for one context. A Workflow needs opt-in — **a skill instructing it (this one) counts as opt-in**, but say so: "Using a Workflow to …".

**Do NOT** use a Workflow for a single task or a one-round fan-out — that's *one subagent* or *parallel agents*. Don't use parallel agents for dependent steps — that's a *pipeline* inside a Workflow.

## 2. Pick the compute TIER (model + effort)

Use the **least** tier that can do the job. Route via `subagent_type`; each tier agent has model+effort baked in.

| Tier | `subagent_type` | Model / effort | For |
|------|-----------------|----------------|-----|
| Mechanical | `sp-mechanical` | haiku / low | 1-2 files, clear spec, measurement, batch edits |
| Standard | `sp-standard` | sonnet / medium | integration, multi-file, debugging |
| Deep | `sp-deep` | opus / high | architecture, security, adversarial-audit, judging |

A `BLOCKED: needs higher tier` return → re-dispatch one tier up. Never silently retry the same tier.

> Enforcement (optional): if the dispatch-guard hook is registered (opt-in — see MODEL-ROUTING.md), it blocks a wrong-tier dispatch via the existing `subagentType` check. It's an advisory nudge (fails open), not a hard gate.

## 3. Main-loop compute (advisory — cannot be auto-set)

A skill/agent **cannot** change the MAIN session's extended-thinking or reasoning-effort — that's harness/user-only (`/effort`, Alt+T, settings; hooks get it read-only). If a task clearly warrants more, **tell the user**: "This warrants `/effort high` — raise it before I continue." Never pretend to have set it.

## Red Flags

| Thought | Reality |
|---------|---------|
| "Opus for everything" | Burns tokens. Route mechanical work to sp-mechanical (haiku/low). |
| "One giant agent for the whole audit" | Phased/at-scale → Workflow; independent → parallel agents. |
| "I'll switch on think mode in the skill" | Impossible. Main-loop compute is user-only — advise, don't fake it. |
| "Workflow for this one task" | Overkill. One subagent. |
