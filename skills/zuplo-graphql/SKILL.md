---
name: zuplo-graphql
description: "Use when adding or fixing a GraphQL endpoint on a Zuplo API gateway, which always means two things together — a proxy route in routes.oas.json marked x-graphql so GraphQL-aware policies apply, and the Zudoku GraphQL plugin registered in the developer portal config so the schema and playground are documented. Covers the route handlers, the plugin options, and the GraphQL-specific policies."
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/tools
---

# Zuplo GraphQL Endpoints

A GraphQL API on Zuplo is **two things that must be set up together**:

1. **The gateway endpoint** — a route that proxies GraphQL requests to the
   upstream API.
2. **The documentation plugin** — the Zudoku developer portal plugin that
   renders the schema and an interactive playground.

**The developer portal does not document GraphQL automatically the way it
documents OpenAPI routes.** OpenAPI operations come from `routes.oas.json`,
which the portal already reads; a GraphQL schema lives behind the endpoint and
has to be introspected by a plugin. So a GraphQL endpoint is not done until
BOTH parts are in place. Never add the gateway route without also adding the
documentation plugin.

## Read the docs first

Before writing any configuration, read `https://zuplo.com/docs/articles/graphql`
— it is the source of truth for both halves. Prefer local docs when the `zuplo`
package is installed (`node_modules/zuplo/docs/articles/graphql.md`), or the
Zuplo MCP server's `search-zuplo-docs` if it is connected. Do not configure
GraphQL from memory.

Then read the project's current state before changing it: the existing routes
in `config/routes.oas.json` and the portal config in
`docs/zudoku.config.tsx`.

## 1. Find the upstream

Determine the upstream GraphQL URL to proxy to, and the path to mount the
endpoint on (`/graphql` by default). Ask the user for both if they have not
said — never invent an upstream URL.

## 2. Add the gateway route

Add the route to `config/routes.oas.json` under `post` (GraphQL is a POST API),
marked `"x-graphql": true`, with a proxy handler:

- `urlRewriteHandler` — rewrite the incoming path to the full upstream GraphQL
  URL. Use this for a single fixed endpoint.
- `urlForwardHandler` — forward to a base URL, preserving the path. Use this
  when the upstream shares a base with other routes.

```json
{
  "paths": {
    "/graphql": {
      "post": {
        "summary": "GraphQL Endpoint",
        "operationId": "graphql",
        "x-graphql": true,
        "x-zuplo-route": {
          "handler": {
            "module": "$import(@zuplo/runtime)",
            "export": "urlRewriteHandler",
            "options": { "rewritePattern": "https://api.example.com/graphql" }
          },
          "policies": { "inbound": [] }
        }
      }
    }
  }
}
```

**`"x-graphql": true` is required**, not decorative: it is how the gateway
knows the route carries GraphQL, and the GraphQL-aware policies below only
apply to routes that have it.

### GraphQL-specific policies

| Policy                                   | What it does                                                  |
| ---------------------------------------- | ------------------------------------------------------------- |
| `graphql-analytics-outbound`             | Reports the operations being called to analytics              |
| `graphql-disable-introspection-inbound`  | Blocks introspection queries — usual for a production endpoint |

Read each policy's doc page before configuring it. Note the interaction with
step 3: if introspection is disabled on the gateway, the documentation plugin
cannot introspect the schema through it — point the plugin at a schema file or
at the upstream directly.

## 3. Add the documentation plugin (never skip)

Read `docs/zudoku.config.tsx` and **merge** the plugin into the existing config
— do not overwrite the file. Import `graphqlPlugin` from
`@zudoku/plugin-graphql` and add an instance to the config's `plugins` array,
creating the array if it does not exist. Add **one plugin instance per GraphQL
API**.

```tsx
import { graphqlPlugin } from "@zudoku/plugin-graphql";

// merge into the existing config object:
plugins: [
  graphqlPlugin({
    type: "url",          // introspect the schema from the input URL
    input: "https://api.example.com/graphql",
    path: "/graphql",     // where the docs + playground mount in the portal
    options: { title: "GraphQL API" },
  }),
],
```

If `@zudoku/plugin-graphql` is not already a dependency in
`docs/package.json`, add it there too — the portal build fails on the missing
import otherwise.

## 4. Verify and deploy

Build the project and read the result; if it fails, read the logs, fix the
configuration, and build again. Then summarize what was configured and
**confirm both halves explicitly** — the gateway route and the documentation
plugin — before offering to deploy.

## Getting it wrong

| Mistake | Consequence |
| ------- | ----------- |
| Route without the documentation plugin | The endpoint works but is undocumented, with no playground — the portal shows nothing |
| Omitting `"x-graphql": true` | GraphQL-aware policies do not apply to the route |
| Overwriting `docs/zudoku.config.tsx` | Every other portal setting is destroyed |
| Adding the plugin without the dependency in `docs/package.json` | The portal build fails on the missing import |
| Disabling introspection while the plugin introspects through the gateway | The schema cannot be loaded and the docs render empty |
