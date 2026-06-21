# Architecture: system overview

## Topology

```
                ┌────────────────────────┐
   client  ───► │  api-gateway  (:8080)  │   single external entry point
                └───────────┬────────────┘
                  /api/users │ /api/orders
                ┌───────────┴───────────┐
                ▼                        ▼
   ┌────────────────────┐   validate   ┌─────────────────────┐
   │ user-service :8081 │ ◄─────────── │ order-service :8082 │
   │  owns USERS        │  GET /users  │  owns ORDERS        │
   └────────────────────┘   /{id}      └─────────────────────┘
                                              │ emits
                                              ▼
                                     order.created (contract)
```

## Why three services
- **user-service** is the authority on user existence. Nothing else may own user data.
- **order-service** owns orders but must ask user-service whether a user is real —
  it never reaches into user-service's storage.
- **api-gateway** gives the outside world one URL and hides the internal topology.

## Failure handling
`order-service` calls `user-service` with a short timeout. If user-service is
unreachable it returns `502` rather than crashing or guessing — see the
order-service spec. This is the "degrade gracefully" rule from CLAUDE.md.
