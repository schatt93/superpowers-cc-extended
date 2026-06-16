# Five-Path test blueprint

Language-agnostic skeleton. Each path = one focused test with real assertions, no sleeps, no
inline logic overrides. Adapt to your runner (Vitest, Jest, pytest, Go testing, JUnit).

## Skeleton

```
describe("<unit> — five-path validation")
  beforeEach: build the REAL unit + a fake at the BOUNDARY only (gateway/repo/transport)

  test HAPPY:  valid input          -> assert the full success state/return
  test BAD:    malformed input      -> assert typed error { code, status }
  test BAD:    pathological input    -> cyclic/oversized payload -> assert typed error (NOT a crash)
  test BUMPY:  inject N transient failures -> assert retry/backoff + loading state, then success
  test CHAOS:  sever the boundary mid-write -> assert rollback to a consistent state, no orphan
  test DEATH:  simulate resource exhaustion -> assert circuit-breaker open + logs scrubbed of secrets
```

## Principles carried from the skill body

- Assert against observable output/state, not implementation calls.
- Fake the gateway/repo/transport; never the unit under test or its internal collaborators.
- The Bad path owns malformed AND pathological input; the Death path is true exhaustion.
- Deterministic: prefer fake timers over real sleeps.

## Concrete assertion shapes

Keep assertions on observable outcomes, never on "was called". Examples per path:

```
HAPPY:  expect(result).toEqual({ status: 'SUCCESS', id: expect.any(String) })
BAD:    expect(err).toEqual({ code: 'ERR_INVALID', status: 400 })      // typed, not free-text
BUMPY:  expect(telemetry).toContain('RETRY_1'); expect(result.status).toBe('SUCCESS')
CHAOS:  expect(result.status).toBe('ROLLED_BACK'); expect(store.orphans()).toHaveLength(0)
DEATH:  expect(result.status).toBe('CIRCUIT_OPEN'); expect(logDump).not.toContain('secret')
```

Port this shape to your runner (Vitest, Jest, pytest, Go, JUnit); keep the five-path mapping and the
no-stub / no-tautology rules intact.
