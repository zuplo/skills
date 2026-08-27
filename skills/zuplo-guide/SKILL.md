---
name: zuplo-guide
description: "Comprehensive Zuplo API gateway guide for building, configuring, and deploying programmable API gateways. Covers route configuration in routes.oas.json, API authentication (API keys, JWT, OAuth), rate limiting, request/response policies, custom handlers, CORS setup, API proxy forwarding, environment variables, and deployment. Teaches documentation lookup strategies, the OpenAPI-as-config model, policy pipeline architecture, and web standards runtime. Use this skill for all Zuplo API management, API proxy setup, rate limiting configuration, API key authentication, and policy configuration."
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/tools
---

# Zuplo API Gateway Guide

Build and manage programmable API gateways with Zuplo. This skill teaches you how to find current documentation and correctly configure Zuplo projects.

## Critical rule: Always read docs before configuring

Before configuring ANY Zuplo feature, read the relevant documentation first. Do not rely on training data — the docs are the source of truth for configuration format, required fields, and available options.

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

## Core concepts

Zuplo is a **programmable API gateway** deployed at the edge. Key Zuplo-specific principles:

- **OpenAPI-as-config** — `routes.oas.json` is both the API spec and the routing config
- **Policy Pipeline** — Composable middleware that snaps into a request/response pipeline (inbound policies run before the handler, outbound after)
- **Web Standards Runtime** — Uses standard web APIs (`Request`, `Response`, `fetch`) — no Node.js APIs
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

## Route configuration example

A route in `config/routes.oas.json` with API key auth and rate limiting policies:

```json
{
  "paths": {
    "/v1/todos": {
      "get": {
        "summary": "List todos",
        "x-zuplo-route": {
          "corsPolicy": "none",
          "handler": {
            "export": "urlForwardHandler",
            "module": "$import(@zuplo/runtime)",
            "options": {
              "baseUrl": "https://api.example.com"
            }
          },
          "policies": {
            "inbound": ["api-key-inbound", "rate-limit-inbound"]
          }
        }
      }
    }
  }
}
```

## Policy configuration example

Policies are defined in `config/policies.json`. Routes reference policies by name.

```json
[
  {
    "name": "api-key-inbound",
    "policyType": "api-key-inbound",
    "handler": {
      "export": "ApiKeyInboundPolicy",
      "module": "$import(@zuplo/runtime)",
      "options": {}
    }
  },
  {
    "name": "rate-limit-inbound",
    "policyType": "rate-limit-inbound",
    "handler": {
      "export": "RateLimitInboundPolicy",
      "module": "$import(@zuplo/runtime)",
      "options": {
        "rateLimitBy": "user",
        "requestsAllowed": 100,
        "timeWindowMinutes": 1
      }
    }
  }
]
```

Look up all built-in policies in `node_modules/zuplo/docs/policies/_index.md`, then read the specific policy's `doc.md` and `schema.json` for exact configuration options.

## When you see errors

1. Read the relevant doc page (check `node_modules/zuplo/docs/` first)
2. Verify configuration matches the documented format exactly
3. Check that all required fields are present
4. Run `npx zuplo test` to validate, and check deployment logs for specific error messages

## Development workflow

1. **Look up docs** for the feature you're configuring (see documentation sources above)
2. **Check available policies** in `node_modules/zuplo/docs/policies/_index.md`, then read the specific policy's `doc.md`
3. **Write configuration** based on current docs
4. **Validate locally** by running `npx zuplo dev` for local development or `npx zuplo test` to run tests. If tests fail, read the error output, fix the configuration, and re-run before deploying
5. **Deploy** with `npx zuplo deploy` and verify with `npx zuplo list` that the deployment succeeded
