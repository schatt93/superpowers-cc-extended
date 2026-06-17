---
name: delivery-standards
description: Use when planning a release, deployment topology, token auth, or disaster-recovery posture — progressive delivery, OAuth2.1/token-exchange, RTO/RPO tiers, split-brain. Org-opinionated standards.
---

# Delivery & Operations Standards (org)

## Progressive delivery (manual single-node updates prohibited)
- **Blue-green:** two identical envs; cutover = L7 target switch; keep the old env warm for the **bake window** — sized to your rollback-detection time, not a fixed interval.
- **Automated canary:** metric-driven phases (1 → 5 → 10 → 25 → 50 → 100%); the ingress advances only while error rates/telemetry stay in thresholds, else halts + rolls back.

## Token authorization (OAuth 2.1 / OIDC)
- Stateless, signed. Ingress authenticates against the IdP over OIDC.
- **Never reuse the high-privilege ingress token downstream.** Use **token exchange (RFC 8693)** to mint short-lived, low-privilege tokens scoped to each target.

## Disaster recovery (pick the tier deliberately — cost is real)
- **RTO** = max tolerable downtime; **RPO** = max tolerable data loss (in time).

| Tier | Replication | RPO | Tradeoff |
|------|-------------|-----|----------|
| Backup-restore | periodic snapshots | hours | cheapest; large loss window |
| Async replication | streaming WAL / log shipping | seconds–min | low write latency; bounded loss on failover |
| Sync replication | commit acks remote write | ~0 | every write pays inter-region RTT; CAP — can't keep strict consistency AND availability under partition |

**RPO ≈ 0 is real only for the narrow critical data where you accept the write-latency penalty and choose consistency over availability under partition.** Never a blanket target for all data.

- **Split-brain:** active-active uses a consensus engine (Raft/Paxos); on losing quorum a region goes **read-only** — consistency over availability, by design.

## Release checklist
- [ ] Blue-green or canary; no manual node updates.
- [ ] Canary advances only on healthy metrics; auto-rollback wired.
- [ ] RTO/RPO tier chosen deliberately for the data class, tradeoff understood.
- [ ] Split-brain behavior defined (read-only on minority partition).
- [ ] Downstream calls use least-privilege exchanged tokens.
