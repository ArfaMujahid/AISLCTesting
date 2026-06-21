<!--
  ============================================================================
  CLAUDE.md  —  WORKSPACE-ROOT CONTEXT FILE
  ============================================================================
  Claude Code reads this file automatically when run from the workspace root.
  It is the single source of global, cross-service context.

  Namespace note: every repo URL below uses `ArfaMujahid` (your personal
  GitHub account). If you move these repos to an org, find/replace
  `ArfaMujahid` -> <org-name> here AND in .gitmodules AND in
  scripts/setup-remotes.sh.
  ============================================================================
-->

# CLAUDE.md — Ecommerce Platform Workspace

## What This File Is
This file gives Claude Code the full context of the problem we are solving,
the workspace pattern we are using, and the rules for working across multiple
service repositories. Read this before touching anything.

---

## The Problem We Are Solving

### Microservices + AI Context = A Hard Problem
When a project is split across multiple repositories, AI coding tools lose context.
By default, if you open a single service repo, the AI only knows about that service.
It doesn't know what other services exist, how they talk to each other, what contracts
they share, or what decisions have already been made. This causes:

- AI suggesting changes that break other services
- Duplicated logic across services because the AI doesn't know it already exists elsewhere
- Inconsistent API shapes because the AI doesn't know the shared contracts
- No awareness of inter-service dependencies when refactoring

### The Naive Fix That Doesn't Work
Keeping a separate "context repo" as a sibling to the service repos doesn't solve it.
You can't guarantee everyone has it cloned, at the right path, or kept in sync.
The AI still won't automatically have context of it when you open a service folder.

<!-- THIS is the "sibling repo problem". The whole submodule design below exists
     to replace fragile sibling clones with one parent repo that PINS exact
     child-repo versions, so context travels with the clone. -->

### The Solution: Workspace Repo + Git Submodules
We use a single workspace repo that everyone clones. It contains:
- This CLAUDE.md at the root (global context for Claude Code)
- Shared contracts (API specs, event schemas)
- All service repos pulled in as git submodules under services/

When you open the workspace root folder in your IDE or run Claude Code from it,
the AI has visibility of every service simultaneously. One clone, full context.

Each service repo is still independent — it has its own git history, its own CI/CD,
its own deployments. The workspace just stitches them together for local development
and gives the AI the cross-service context it needs.

---

## Repo Structure

```
workspace/                        ← everyone clones THIS (parent repo)
├── CLAUDE.md                     ← global AI context (this file)
├── .cursor/rules/project.mdc     ← same context for Cursor
├── aidlc-workflows/              ← git submodule → awslabs/aidlc-workflows (AI-DLC steering rules)
├── shared-contracts/             ← source of truth for API contracts and event schemas
│   ├── api-specs/                ← OpenAPI specs per service
│   └── events/                   ← async event schemas
└── services/                     ← child repos live here as git submodules
    ├── user-service/             ← git submodule → ArfaMujahid/user-service
    ├── order-service/            ← git submodule → ArfaMujahid/order-service
    └── api-gateway/              ← git submodule → ArfaMujahid/api-gateway
```

On GitHub this looks like:
```
ArfaMujahid/AISLCTesting   ← parent (workspace), has .gitmodules pointing to children
ArfaMujahid/user-service   ← child, independent repo
ArfaMujahid/order-service  ← child, independent repo
ArfaMujahid/api-gateway    ← child, independent repo
awslabs/aidlc-workflows    ← EXTERNAL submodule (not ours): upstream AI-DLC steering rules
```

Note: not every submodule is one of ours. `aidlc-workflows/` points at the
upstream `awslabs/aidlc-workflows` repo. We pin it at a known commit and only
move that pointer deliberately — same mechanism as the services, but we never
push to it; we just track the version of the methodology we're using.

---

## How the Submodule Pattern Works

The workspace repo does not contain service code directly.
It contains pointers — each submodule entry is just a commit hash pointing to
a specific state of the child repo. This means:

- Services are independently deployable and versionable
- Different teams can own different service repos
- The workspace always reflects a known-good combination of service versions
- Updating a service = push to service repo + bump the pointer in workspace

### Setting Up From Scratch (done once by the lead)
```bash
git clone git@github.com:ArfaMujahid/AISLCTesting.git
cd AISLCTesting

git submodule add git@github.com:ArfaMujahid/user-service.git services/user-service
git submodule add git@github.com:ArfaMujahid/order-service.git services/order-service
git submodule add git@github.com:ArfaMujahid/api-gateway.git services/api-gateway

# External: pull in the upstream AI-DLC workflow rules as a submodule too
git submodule add https://github.com/awslabs/aidlc-workflows.git aidlc-workflows

git add .
git commit -m "add service + aidlc-workflows submodules"
git push
```

### Cloning (every new developer does this once)
```bash
git clone --recurse-submodules git@github.com:ArfaMujahid/AISLCTesting.git
```

### If You Forgot --recurse-submodules
```bash
git submodule update --init --recursive
```

### Pulling Latest From All Services
```bash
git submodule update --remote
```

---

## Day to Day Workflow

### Working on a service
```bash
# go into the service, work normally
cd services/user-service
git add . && git commit -m "your change" && git push   # pushes to ArfaMujahid/user-service

# come back and bump the workspace pointer
cd ../..
git add services/user-service
git commit -m "bump user-service to latest"
git push
```

### Changing shared contracts or this CLAUDE.md
```bash
# edit at workspace root
git add shared-contracts/ CLAUDE.md
git commit -m "update order API contract"
git push
```

### Rule: always push the service repo before bumping the workspace pointer
If you bump the pointer before pushing the service, other devs will pull a
commit hash that doesn't exist yet on the remote. This breaks their clone.

---

## Rules Claude Code Must Follow

### Cross-service rules
- Services communicate only over HTTP — never import code from another service
- Never add a database-level foreign key that crosses service boundaries
- If a service needs data from another service, it calls that service's API
- If a service is down, the calling service must handle it gracefully (timeout + fallback)

### Shared contracts rules
- shared-contracts/ is the source of truth for all API shapes and event schemas
- Always update shared-contracts before changing any API response in a service
- Never add or remove a field from a response without updating the spec first
- Never invent a new event without defining it in shared-contracts/events/ first

### Workspace rules
- Never commit service implementation code to the workspace repo
- Workspace only holds: CLAUDE.md, .cursor/rules/, shared-contracts/, and submodule pointers (services + aidlc-workflows)
- Each service must have its own CLAUDE.md explaining what it does
- When adding a new service: add the repo, add the submodule, add its spec to shared-contracts, update this file

### AI tool rules
- Always run Claude Code from the workspace root — never from inside a service folder
- This gives Claude Code visibility of all services simultaneously
- If you run Claude Code from inside a service folder, it loses cross-service context

---

## Multi-Repo Context Problem — Detailed Explanation

### Why normal AI tools struggle with this
Most AI coding tools (Copilot, basic chat assistants) work at the file or repo level.
They see what is open. In a multirepo microservice setup this means:

- Open user-service → AI knows nothing about order-service
- Open order-service → AI doesn't know what fields user-service returns
- Ask AI to refactor an endpoint → it might break the contract another service depends on
- Ask AI to add a field → it won't know to update the shared spec or the other service

### Why Claude Code handles it differently
Claude Code operates as a local agent with filesystem access. It reads your working
directory recursively. When you run it from the workspace root, it can read:
- Every service's code under services/
- All shared contracts under shared-contracts/
- This CLAUDE.md for intent and rules
- aidlc-workflows/ for the AI-DLC methodology and steering rules to follow

This is why opening the workspace root — not individual service folders — matters.

### Why we still need this CLAUDE.md even with full filesystem access
Filesystem access gives Claude Code the code. It does not give it:
- The intent behind the architecture
- Which decisions are intentional vs accidental
- The rules for how services are allowed to interact
- What is in scope vs out of scope
- The submodule workflow so it doesn't accidentally commit to the wrong repo
- The shared contracts rules so it doesn't break inter-service compatibility

This file fills that gap.

---

## Submodule Footguns and Fixes

| Problem | What Happens | Fix |
|---|---|---|
| Cloned without --recurse-submodules | services/ folders are empty | `git submodule update --init --recursive` |
| Submodule is on detached HEAD | Commits disappear, confusing git state | `cd services/user-service && git checkout main` |
| Bumped workspace pointer before pushing service | Other devs get a missing commit hash | Always push service repo first |
| Forgot to bump workspace after pushing service | Other devs are on old version of service | `cd workspace && git add services/x && git commit && git push` |
| Merge conflict on submodule pointer | Confusing diff showing a commit hash | Pick the newer hash, commit |
| Submodule change not showing in workspace diff | You're inside the submodule, not workspace root | `cd` back to workspace root first |

---

## Adding a New Service Checklist
When Claude Code adds a new service, follow this order:

1. Create the service repo on GitHub
2. Build the service — Claude Code decides the architecture
3. Add a CLAUDE.md inside the service explaining its purpose and responsibilities
4. Add its API spec to workspace/shared-contracts/api-specs/
5. Add its event schemas to workspace/shared-contracts/events/ if applicable
6. Add it as a submodule: `git submodule add <repo-url> services/<name>`
7. Update the services list in this CLAUDE.md
8. Add a route in api-gateway if it needs external exposure
9. Commit submodule pointer + updated CLAUDE.md + shared-contracts to workspace

---

## Current Services

| Service      | Responsibility                                      |
|-------------|-----------------------------------------------------|
| api-gateway  | Single entry point, routes traffic to services      |
| user-service | Owns user data, source of truth for user existence  |
| order-service| Owns order data, validates users via user-service   |

Claude Code should read each service's own CLAUDE.md for service-specific context.

---

## AI Tool Setup

| Tool        | Where context lives                  | How it picks it up                        |
|------------|--------------------------------------|-------------------------------------------|
| Claude Code | workspace/CLAUDE.md                  | Reads automatically from working directory|
| Cursor      | workspace/.cursor/rules/project.mdc  | Reads automatically when folder is opened |
| AI-DLC      | workspace/aidlc-workflows/ (submodule)| Upstream awslabs/aidlc-workflows steering rules, referenced at start of session |

Always open the workspace root folder — not a service subfolder — in your IDE or agent.
