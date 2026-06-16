---
name: e2e-testing
description: Use when writing end-to-end or full-user-journey tests across real boundaries — applies the five operational paths at system scale plus load/soak/chaos escalation and device-matrix parity. Specializes writing-tests for the E2E layer.
---

# End-to-End Testing

E2E exercises the **full user journey across real boundaries**. If you mock the database or internal services, it is not E2E — only external third parties are stubbed, with production-accurate contracts.

**REQUIRED BACKGROUND:** superpowers-extended-cc:writing-tests (the five-path core this builds on).

## Principles

- **Real boundaries.** Real DB, real internal services, real transport. Stub only external SaaS, with production-accurate schemas.
- **Five paths at system scale.** Apply Happy / Bad / Bumpy / Chaos / Death to the whole journey, not a single unit (see writing-tests).
- **Select by role/label/test-id**, never CSS/DOM chains — resilient to markup churn.
- **Propagate one trace id** across the journey and emit OTel spans, so a failure is isolable to a layer.

## Load family — escalate deliberately

| Stage | Goal |
|-------|------|
| **Smoke** | Minimal deploy meets baseline latency/throughput |
| **Load** | Standard peak concurrency; find transactional constraints |
| **Stress** | Past peak; find the breaking point and recovery behavior |
| **Soak** | High concurrency for 24–48h; expose memory leaks + connection-pool exhaustion |

The five paths and this load family compose: **Bumpy** and **Death** at system scale ARE the Stress/Soak stages. Run load and chaos with dedicated tools (k6/Artillery, a fault injector) in a **separate harness** — not inside the per-device browser runner.

## Chaos & matrix

- **Chaos:** inject faults mid-journey (kill a pod, add latency, drop a zone); verify the system self-heals and the journey rolls back to a consistent state — no double-charge, no orphan.
- **Device matrix:** run the journey in parallel across real devices + emulators to verify parity across viewports, browsers, and OSes.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll mock the DB to speed it up" | Then it's an integration test, not E2E. |
| "One viewport/browser is enough" | Parity bugs live in the matrix. |
| "The happy journey is enough" | Production breaks on the other four paths. |
| "Select by CSS class" | Brittle; use role/label/test-id. |

A Playwright device-matrix example is in `references/playwright-example.md`.
