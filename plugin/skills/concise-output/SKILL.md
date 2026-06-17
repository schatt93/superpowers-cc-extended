---
name: concise-output
description: Use when output length or token cost matters — make responses and subagent returns terse and results-first: structured over prose, no preamble or restatement, no filler. Output tokens cost ~5x input.
---

# Concise Output

Output tokens are generated, at ~5x the price of input. Maximize signal per token: lead with the result, cut anything that doesn't change the reader's next action.

This is a **flexible** discipline — adapt to context, but the rules below are the default.

## Rules

- **Result first.** Outcome in the first line. Reasoning after, only if it changes a decision.
- **No preamble or restatement.** Don't repeat the question, don't narrate what you're about to do, don't recap what was just said.
- **Structured over prose.** Tables, short bullets, code — not paragraphs — for lists, comparisons, and status.
- **No filler.** Cut "Great!", "Certainly", "I hope this helps", and hedging ("it seems", "I think").
- **Say it once.** No summary that just repeats the body.
- **Reference, don't echo.** Don't reprint unchanged code; cite `file:line`.

## Subagent returns (the big lever)

A subagent's output is output-token cost paid by the parent. When dispatching, constrain the return:

- Specify a **hard cap and shape**: "ranked list, max N, each = severity + one line + evidence ref. No narration, no preamble."
- Ask for **the conclusion, not the journey** — findings/verdict, not a step-by-step log.
- For data, require a **schema** (structured output), not prose.

## When NOT to compress

Never trade correctness for brevity. Keep: required evidence/citations, the full content of a deliverable the user asked for, and safety-critical caveats. Terse ≠ omitting what matters.

## Red Flags — STOP, you're bloating

| Pattern | Fix |
|---------|-----|
| Restating the question before answering | Delete; answer first |
| "Let me explain what I'll do…" preamble | State the result / just do it |
| A summary that repeats the body | Cut it |
| Paragraphs for a list or comparison | Convert to a table/bullets |
| Echoing unchanged code back | Reference `file:line` |
| Unbounded subagent prompt ("report your findings") | Add a cap + shape |
