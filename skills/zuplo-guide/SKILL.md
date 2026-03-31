---
name: zuplo-guide
description: "Comprehensive Zuplo API gateway guide. Teaches how to find current documentation, understand the request pipeline, configure routes and policies, write custom handlers, and manage deployments. Covers documentation lookup strategies (llms.txt, individual doc pages), core concepts (OpenAPI-as-config, policy pipeline, web standards runtime), and all built-in policies. Use this skill for all Zuplo development to ensure correct configuration from official docs."
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/skills
---

# Zuplo API Gateway Guide

Build and manage programmable API gateways with Zuplo. This skill teaches you how to find current documentation and correctly configure Zuplo projects.

## Critical rule: Read docs before configuring

Before configuring ANY Zuplo feature (policies, handlers, routes, CORS, rate limiting, auth, etc.), you MUST read the relevant documentation first. Do not rely on training data for Zuplo-specific configuration. The docs are the source of truth for correct configuration format, required fields, and available options.

If you skip this step and produce incorrect configuration, it will break the user's project.

## How to look up Zuplo documentation

Use the following sources in priority order:

1. **Local docs (preferred):** The `zuplo` npm package bundles full documentation. Look for docs at `node_modules/zuplo/docs/` (check both the project root and parent directories for monorepos or hoisted installs). These are version-matched and always available offline.

2. **MCP server tools:** If the Zuplo MCP server is connected, use `search-zuplo-docs` and `ask-question-about-zuplo` (may be prefixed, e.g. `mcp__*Zuplo*__search-zuplo-docs`).

3. **Fetch docs via URL:** Fetch `https://zuplo.com/docs/llms.txt` for a page index, then fetch individual pages. Policy catalog: `https://cdn.zuplo.com/portal/policies.v5.json`.

### Local docs quick reference

| Topic | Path in `node_modules/zuplo/docs/` |
| ----- | ---------------------------------- |
| Concepts (request lifecycle, project structure) | `concepts/` |
| Policies (index + per-policy config/schema) | `policies/_index.md`, `policies/{policy-id}/doc.md`, `policies/{policy-id}/schema.json` |
| Handlers (URL forward, rewrite, custom, etc.) | `handlers/` |
| Articles (CORS, env vars, auth, deployment) | `articles/` |
| CLI reference | `cli/` |
| Monetization | `articles/monetization/` |
| Developer portal / Zudoku | `dev-portal/` |
| Programmable API reference | `programmable-api/` |
| Guides | `guides/` |

## Core concepts (summary)

Zuplo is a **programmable API gateway** built on **web standards**. Key principles:

- **OpenAPI-as-config** — `routes.oas.json` is both the API spec and the routing config
- **Web Standards First** — Uses `Request`, `Response`, `Headers`, `fetch()`, Web Crypto, Streams (no Node.js APIs)
- **Policy Pipeline** — Composable middleware that snaps into a request/response pipeline
- **Edge-Native** — Global edge deployment by default

### Project structure

```
zuplo.jsonc                    # Project config (version, compatibilityDate)
/config/
  routes.oas.json              # OpenAPI 3.1 spec = routing configuration
/modules/
  *.ts                         # Custom handlers, policies, shared utilities
  zuplo.runtime.ts             # Global runtime extensions and hooks
```

### Request pipeline

```
Request → Pre-Routing Hooks → Route Matching → Request Hooks
  → Inbound Policies (auth, rate limiting — can short-circuit)
  → Handler (core logic)
  → Outbound Policies (response transformation)
  → Response Hooks → Response sent
  → waitUntil tasks (background work)
```

### Key imports

```ts
import {
  ZuploRequest, ZuploContext, RuntimeExtensions, HttpProblems,
  ZoneCache, environment,
} from "@zuplo/runtime";
```

For full details on handlers, runtime objects, caching, authentication, and deployment models, read the docs in `node_modules/zuplo/docs/concepts/`.

## When you see errors

1. Read the relevant doc page for the feature causing the error (check `node_modules/zuplo/docs/` first)
2. Verify configuration matches the documented format exactly
3. Check that all required fields are present
4. For build failures, check deployment logs for specific error messages

## Development workflow

1. **Read the docs** for the feature you're configuring — check `node_modules/zuplo/docs/` or use MCP tools
2. **Check available policies** — read `node_modules/zuplo/docs/policies/_index.md` for the full list, then the specific policy's `doc.md` for configuration
3. **Write configuration** based on current docs (never from memory)
4. **Verify the build** succeeded after saving changes
