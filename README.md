# AISLCTesting — Ecommerce Platform Workspace

This is the **parent workspace repo**. It does not contain service code directly —
it stitches independent service repos together as **git submodules** so that AI
tools (and humans) get full cross-service context from a single clone.

> Full architectural context and rules live in [`CLAUDE.md`](./CLAUDE.md).

## Clone (the right way)

```bash
# --recurse-submodules pulls the service repos too
git clone --recurse-submodules git@github.com:ArfaMujahid/AISLCTesting.git
cd AISLCTesting
```

If `services/*` came up empty (you forgot the flag):

```bash
git submodule update --init --recursive
```

## What's where

| Path                     | Purpose                                                       |
|--------------------------|---------------------------------------------------------------|
| `CLAUDE.md`              | Global AI context + cross-service rules (read this first)     |
| `.cursor/rules/`         | Same context, for Cursor users                                |
| `shared-contracts/`      | Source of truth for API specs + event schemas                 |
| `aidlc-workflows/`       | Submodule → `awslabs/aidlc-workflows` (AI-DLC steering rules)  |
| `services/`              | Service repos as submodules (user / order / api-gateway)      |
| `scripts/`               | Bootstrap + maintenance scripts                               |

## The services

| Service        | Port  | Responsibility                                       |
|----------------|-------|------------------------------------------------------|
| `api-gateway`  | 8080  | Single entry point; routes to the services           |
| `user-service` | 8081  | Owns user data; source of truth for user existence   |
| `order-service`| 8082  | Owns orders; validates users via user-service's API  |

## First-time remote setup

The 4 GitHub repos and submodule wiring are created by
[`scripts/setup-remotes.sh`](./scripts/setup-remotes.sh) (requires `gh` auth).
