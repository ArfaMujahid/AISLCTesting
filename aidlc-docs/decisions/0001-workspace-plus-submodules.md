# ADR 0001: Workspace repo + git submodules over sibling repos

- **Status:** Accepted
- **Date:** 2026-06-21

## Context
Service code is split across independent repos. AI tools (and new developers)
opening a single service repo have no visibility of the other services, their
contracts, or prior decisions. The obvious fix — telling everyone to clone a
"context repo" as a sibling folder — fails because there's no guarantee it's
cloned, at the right path, or kept in sync. This is the **sibling repo problem**.

## Decision
Use one **parent workspace repo** (`AISLCTesting`) that pulls every service in as
a **git submodule** under `services/`, alongside `CLAUDE.md`, `shared-contracts/`,
and `aidlc-docs/`. Developers clone the workspace with `--recurse-submodules`;
AI tools are run from the workspace root and therefore see everything at once.

## Consequences
- (+) One clone delivers full cross-service context — context travels with the repo.
- (+) The workspace pins an exact, known-good combination of service versions.
- (+) Each service stays independently versioned, deployed, and owned.
- (−) Submodules have sharp edges (detached HEAD, pointer-before-push). Mitigated
      by the "Submodule Footguns" table in `CLAUDE.md`.

## Rejected alternatives
- **Sibling context repo:** no sync guarantee; AI doesn't auto-pick it up. (The problem.)
- **Monorepo:** would couple deploy/versioning and break independent service ownership.
