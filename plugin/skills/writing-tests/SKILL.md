---
name: writing-tests
description: Use when authoring or adding tests for a feature or bugfix — to decide WHAT to cover (the five operational paths) and avoid stub or tautology tests. Complements test-driven-development, which sets the test-first order.
---

# Writing Thorough Tests

Coverage percentage is not coverage. A suite can be 100% green and test nothing real. Thorough tests exercise the **five operational paths** with non-trivial assertions, and mock only at the system's edges.

**REQUIRED BACKGROUND:** superpowers-extended-cc:test-driven-development (when/order). For full-system journeys, see superpowers-extended-cc:e2e-testing.

## The Five Paths

Every change is tested across all five. A change that leaves one unhandled is incomplete.

| Path | Condition | Must verify | Gate failure |
|------|-----------|-------------|--------------|
| **Happy** | Valid input, healthy deps | The full success lifecycle, end to end | No real success assertion (or line-coverage padding) |
| **Bad** | Malformed/illegal input, crossed bounds, pathological payloads (oversized, deeply nested, self-referential) | A strongly-typed, structured semantic error | An unhandled exception or bare `500` |
| **Bumpy** | Transient degradation: latency, `429`, dropped connections | Timeouts, backoff/retry, non-blocking loading states | Hang, no retry, or blocking UI |
| **Chaos** | Infra fault mid-write (DB drop, pod kill) | Rollback to a consistent state, no orphaned records | A partial write left committed |
| **Death** | Resource exhaustion: OOM, disk-full, unbounded recursion | Circuit breaker trips, session isolated, logs scrubbed of secrets/stack internals | A leak, cascade, or secret in logs |

Boundary rule: pathological *input* (self-referential, huge) is a **Bad**-path concern — validate and reject it. The **Death** path is genuine resource exhaustion, not bad input.

Adapt to the unit's real failure surface: a pure or dependency-injected function with no breaker/logger/infra may fold **Chaos** and **Death** into the Bad path (model the injected collaborator failing). Don't invent infrastructure just to fill a row.

## Rules

- **AAA structure** — Arrange, Act, Assert. One behavior per test.
- **Mock only at outer boundaries** (network, persistence, third-party), with production-accurate schemas. Never mock the unit under test or its internal collaborators.
- **Assert behavior/state, not implementation.** "The function was called" is a tautology, not a test.
- **No stubs, no duplicates.** One E2E test of the happy lifecycle — not many tests re-walking the same lines for coverage %.
- **UI: select by role/label/test-id**, never CSS or DOM-chain selectors.
- **Errors are typed and structured** on the Bad path (code + status), not free text.

## Mutation-strength bar

Coverage says lines *ran*; mutation says tests *catch bugs*. Run a mutation engine (Stryker, PITest): if mutating `>=` to `>` (or similar) leaves tests green, the test is superficial. A **surviving mutant in critical logic (auth, money, access control) is a blocking defect.**

## Red Flags — STOP, you're padding

| Thought | Reality |
|---------|---------|
| "Coverage is green, we're done" | Green lines ≠ caught bugs. Run mutation. |
| "I'll mock the internal function" | Then you're testing the mock. Mock the boundary only. |
| "Assert it called the service" | Tautology. Assert the observable outcome. |
| "Happy path is enough for now" | Four of five paths are where production breaks. |
| "I'll add a quick test to hit the line" | Coverage-padding slop. Delete it. |

The full reactive blueprint (five paths as a runnable suite) is in `references/blueprint.md`.
