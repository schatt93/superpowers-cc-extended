---
name: adversarial-audit
description: Use when you must verify a design, plan, claim, or finished work product is actually sound — dispatches parallel red-team agents on non-overlapping attack surfaces, each required to falsify it with evidence. For broad multi-perspective scrutiny, not a single-pass diff review.
---

# Adversarial Audit

A single reviewer — especially the author — confirms; a red team falsifies. Dispatch parallel agents that each try to *kill* the work from a different angle, with the burden of proof on the work, not the auditor.

**REQUIRED BACKGROUND:** superpowers-extended-cc:dispatching-parallel-agents (the dispatch mechanism).

## When to use

| Situation | Use this | Not this |
|-----------|----------|----------|
| Verify a design/plan before committing to it | adversarial-audit | — |
| Verify a finished product / your own claims before shipping | adversarial-audit | self-review (confirmation bias) |
| Quality pass on a code diff | — | requesting-code-review |

## Method

1. **State the target precisely** — the artifact, and what "sound" would mean (the claims to falsify).
2. **Partition into NON-OVERLAPPING attack surfaces.** Overlap means agents redundantly find the same obvious thing and miss the rest. Pick disjoint lenses, e.g.:
   - *Premise / ROI* — is this even worth doing; is the core assumption true?
   - *Mechanism / correctness* — does it actually work as claimed?
   - *Lost context / regression* — what breaks or is silently dropped?
   - *Measurement / validation* — are the numbers or tests honest?
   - *Safety / security* — how is it abused; how does it fail?
3. **Dispatch one agent per lens** (parallel). Each agent MUST:
   - Try to KILL the work, not defend it. Burden of proof is on the work.
   - **Inspect real artifacts / run commands** — ground every claim in evidence, not opinion.
   - Return severity-ranked findings (**kill / major / minor**) with file or command evidence and a concrete fix.
   - End with a **falsifiable verdict** (e.g. PROCEED / WITH-CHANGES / RECONSIDER).
4. **Synthesize.** Separate "held up under attack" from "broke." Dedup across agents. Rank by severity, then map to the overall verdict: any **kill** → RECONSIDER; else any **major** → WITH-CHANGES; else PROCEED.
5. **Loop-until-dry** (for exhaustive audits) — re-dispatch until **K=2** consecutive rounds surface nothing new (raise K for higher assurance). The method also works single-threaded: run the lenses sequentially yourself when parallel dispatch isn't available.

## Agent prompt template

> You are an ADVERSARIAL auditor. Try to KILL [target] via the [lens] surface. Burden of proof is on the work. Inspect real files / run commands; cite evidence. Return ranked findings (kill/major/minor), each with evidence + a fix, then a one-line falsifiable verdict.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll just review it myself" | One perspective; you share the author's blind spots. |
| "The agents all agreed, so it's fine" | If their lenses overlapped, agreement is collusion, not confirmation. |
| "It's my work, it's probably fine" | That bias is exactly why you red-team it. |
| "Their opinions are enough" | An audit without evidence is theater. Require commands/citations. |
