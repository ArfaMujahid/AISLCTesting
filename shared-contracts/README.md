# shared-contracts

**Source of truth** for every API shape and async event in the platform.

Rules (also enforced in `CLAUDE.md`):

1. Update the spec here **before** changing a response field in any service.
2. Never add/remove a response field without editing the matching spec first.
3. Never emit a new event without first defining it under `events/`.

```
shared-contracts/
├── api-specs/   ← one OpenAPI doc per service (synchronous HTTP contracts)
└── events/      ← one JSON Schema per async event (e.g. order.created)
```

A service and its spec are a pair: if the spec and the code disagree, the **spec wins**
and the code is the bug.
