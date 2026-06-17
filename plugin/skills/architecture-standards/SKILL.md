---
name: architecture-standards
description: Use when designing system architecture or service boundaries — frontend data flow, backend ports/adapters & DDD, distributed transactions, or ingress/routing. Org-opinionated standards (your CLAUDE.md overrides).
---

# Architecture Standards (org)

Opinionated org standards for new/changed architecture — **not universal truth; CLAUDE.md overrides.** Where a rule says **must/prohibited** it's CI-enforced; where it's a **target with a tradeoff**, choose deliberately.

## Frontend — reactive, unidirectional, traceable
- **Unidirectional data flow:** view emits immutable events → a BLoC / reactive state machine processes them → emits deterministic states → view renders from state. **No two-way binding; the view never mutates data.**
- **Traceability:** every event + resulting state passes a global OpenTelemetry interceptor (enables replay / time-travel debugging).
- **Components** are pure stateless `state → layout` functions — no inline async, no hidden context; verified in isolation.
- **Design tokens** are centralized platform-agnostic JSON compiled per platform — one source of truth.

## Backend — hexagonal & domain-driven
- **DDD bounded contexts:** service/table boundaries reflect the ubiquitous language; state changes go through aggregates.
- **Hexagonal (ports & adapters):** domain logic talks to the outside ONLY through abstract ports; adapters implement DB/transport/SaaS at the edge — swap infra without touching the domain.
- **CQRS** where it earns it: writes (transactional consistency) separate from reads (scale via materialized views / edge cache).

## Distributed transactions & messaging
- **Saga, not 2PC:** each step has an explicit **compensating transaction** that reverses it on downstream failure.
- **Transactional outbox:** write state + event to an `outbox` table in the SAME db transaction; a log-tailing relay (e.g. Debezium) ships to the broker. Never write to the broker inside business logic.
- **Effectively-once, not exactly-once:** broker exactly-once holds only within its boundary. End-to-end needs **idempotent consumers** (dedup on message id). Transactional producer + idempotent consumer = effectively-once.
- **DLQ:** a poison message trips a breaker, gets error-context, routes to a dead-letter queue — never blocks the queue.

## Ingress, load balancing & routing (THREE separate concerns)
- **BGP/anycast** gets the packet to the nearest edge/PoP.
- **L4** balancer distributes connections (TCP/UDP).
- **L7** proxy (e.g. Envoy) routes on application data (headers/paths/JWT/TLS).
- East-west traffic via a **service mesh** (Istio/Linkerd): mTLS, retries, telemetry.

## Service-design checklist
- [ ] Domain logic behind ports; adapters at the edges.
- [ ] Commands/queries separated where the context warrants.
- [ ] Cross-service transactions are sagas with compensating actions.
- [ ] Events via transactional outbox, not direct broker writes.
- [ ] Consumers idempotent (effectively-once).
- [ ] Poison messages route to a DLQ.
