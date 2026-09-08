---
name: zuplo-project-setup
description: "Use when standing up a new Zuplo API gateway project or configuring one that has no policies yet, including choosing a starting point (template, existing OpenAPI spec, or from scratch), then adding the policies almost every gateway needs — API key authentication, rate limiting, CORS, and JWT validation — in a sensible order, wiring them onto routes, and verifying the build before deploying."
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/tools
---

# Zuplo Project Setup

Take a Zuplo project from empty (or unconfigured) to a deployed gateway with
authentication, rate limiting, and CORS in place.

This skill is the **order of operations**. For how any individual policy,
handler, or route is written, read the docs — see `zuplo-guide` for the full
gateway reference.

## Critical rule: Read docs before configuring

Before configuring ANY policy, read that policy's own documentation page and
schema first. Policy configuration is exact — option names, nesting, and
required fields differ per policy — and a configuration guessed from training
data will break the user's project.

Look docs up in this priority order:

1. **Local docs (preferred):** the `zuplo` npm package bundles them at
   `node_modules/zuplo/docs/` — check the project root and parent directories
   (monorepos, hoisted installs). Per-policy: `policies/{policy-id}/doc.md` and
   `policies/{policy-id}/schema.json`.
2. **MCP server tools:** `search-zuplo-docs` and `ask-question-about-zuplo` if
   the Zuplo MCP server is connected (names may be prefixed, e.g.
   `mcp__*Zuplo*__search-zuplo-docs`).
3. **Fetch by URL:** `https://zuplo.com/docs/policies/{policy-id}`. Policy
   catalog: `https://cdn.zuplo.com/portal/policies.v5.json`.

## How to run the setup

Work through the four phases in order. Each phase has decisions that belong to
the user, so **ask one question at a time and wait for the answer** — do not
assume a starting point, invent an upstream URL, or configure a policy the user
did not ask for. Where the host offers a structured way to present a choice
(a picker, buttons, a numbered prompt), use it; otherwise ask in plain text.

Do not narrate the phases to the user, and do not mention step numbers — they
are the structure of the work, not a script to read out.

### Phase 1 — Read the project before changing it

Read the current state first, then say what you found:

- `zuplo.jsonc` — project config (`version`, `compatibilityDate`).
- `config/routes.oas.json` — the OpenAPI 3.1 spec that **is** the routing
  config. Its presence and whether it has any paths decides everything below.
- `modules/` — existing custom handlers or policies.

If routes already exist, do not overwrite them. Offer the three real choices:

| Choice                       | What it means                                                     |
| ---------------------------- | ----------------------------------------------------------------- |
| Configure the existing routes | Keep the routes, go straight to Phase 3 and add policies          |
| Change the routes            | Add or modify endpoints, then continue to Phase 3                 |
| Start over                   | Replace the configuration — only with explicit confirmation       |

If there are no routes yet, continue to Phase 2.

### Phase 2 — Pick a starting point

| Starting point           | When to use it                                              |
| ------------------------ | ----------------------------------------------------------- |
| **Template**             | A common shape: REST API proxy, webhook gateway, public API with monetization |
| **Existing OpenAPI spec** | The user already has an OpenAPI/Swagger document           |
| **From scratch**         | Routes will be written by hand                              |

- **Template:** describe what the template includes before writing it, then
  write the files.
- **OpenAPI spec:** import it into `config/routes.oas.json`. Zuplo's routing
  config *is* an OpenAPI document, so the spec becomes the routes rather than
  sitting beside them; each operation needs an `x-zuplo-route` with a handler.
  Read the imported spec back and summarize what came in (how many operations,
  which paths) instead of listing every route.
- **From scratch:** go to Phase 3 and add routes as the policies need them.

### Phase 3 — Add the policies the gateway needs

Add policies **one at a time**, confirming each with the user before writing it.
This is the order that works, because each layer assumes the one above it:

| Order | Policy                     | Doc page to read first                | Purpose                          |
| ----- | -------------------------- | ------------------------------------- | -------------------------------- |
| 1     | `api-key-inbound`          | `/policies/api-key-inbound`           | Identify the caller with an API key |
| 2     | `rate-limit-inbound`       | `/policies/rate-limit-inbound`        | Cap request volume — per consumer once keys identify callers |
| 3     | `cors-inbound`             | `/policies/cors-inbound`              | Allow browser callers            |
| 4     | `open-id-jwt-auth-inbound` | `/policies/open-id-jwt-auth-inbound`  | Validate JWTs from an OIDC issuer |

For each policy:

1. **Read its doc page and schema** (see the critical rule above).
2. Ask what it needs — rate limits (a starting point: 20 req/min for a private
   API, 100 req/min for a public one), allowed CORS origins (`*` is fine for
   development, never for production), the JWKS URL or issuer for JWT auth.
3. Add the policy definition under `policies.policies` in
   `config/routes.oas.json`.
4. **Reference it from the routes.** A policy that is defined but not listed in
   a route's `policies.inbound` array does nothing — this is the single most
   common setup mistake. Add the reference to every route that should enforce
   it.

Skipping a policy is a legitimate answer. Do not add API key auth to a
deliberately public API, and do not stack both API key auth and JWT validation
unless the user wants both.

### Phase 4 — Verify, then deploy

1. **Verify the build before claiming success.** Whatever this host uses to
   build or deploy the project, run it and read the result. If it fails, read
   the logs, fix the configuration, and build again — do not hand back a
   project that does not build.
2. Summarize what changed: the routes, the policies configured, and — call this
   out explicitly — **any environment variable or secret the user still has to
   set** (a JWKS URL, an upstream API key). The gateway will fail at runtime
   without them, and only the user can supply them.
3. Then offer to deploy, to review the changed files, or to keep editing.

## Getting it wrong

| Mistake | Consequence |
| ------- | ----------- |
| Configuring a policy from memory | Wrong option names — the build fails or the policy silently does nothing |
| Defining a policy without referencing it in a route | No enforcement at all, and it looks configured |
| Overwriting `config/routes.oas.json` when routes already exist | The user's API is gone |
| Reporting success without checking the build | The user finds the breakage in production |
| Leaving required environment variables unmentioned | Runtime 500s the user cannot explain |
