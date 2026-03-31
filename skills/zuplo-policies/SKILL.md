---
name: zuplo-policies
description: Manage policies on Zuplo API gateway routes. Use when the user wants to add, configure, reorder, or remove authentication, rate limiting, request/response transformation, validation, or any other policy in their Zuplo project. Covers built-in policy configuration, custom code policies, and wiring policies to routes. Includes a complete built-in policy catalog with default configurations.
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/skills
---

# Adding Policies to Zuplo

This skill helps you add and configure policies on Zuplo API gateway routes. Policies are composable middleware that run in the request/response pipeline.

## Critical rule: Read docs before configuring

Before configuring ANY policy, you MUST read the relevant documentation first. Do not rely on training data. Use these sources in priority order:

1. **Local docs (preferred):** Read from `node_modules/zuplo/docs/policies/` — each policy has a `doc.md` and `schema.json`. The full index is at `policies/_index.md`. Check both the project root and parent directories for monorepos.
2. **MCP server tools:** Use `search-zuplo-docs` and `ask-question-about-zuplo` if the Zuplo MCP server is connected.
3. **Fetch docs via URL:** Fetch `https://zuplo.com/docs/policies/{policy-id}` or the policy catalog at `https://cdn.zuplo.com/portal/policies.v5.json`.

If you skip this step and produce incorrect configuration, it will break the user's project.

## How policies work

- **Inbound policies** run before the handler (auth, rate limiting, validation). They can short-circuit by returning a `Response`.
- **Outbound policies** run after the handler (response transformation, headers). They receive both the response and original request.
- Policies execute sequentially in declaration order. Each policy's output is the next policy's input.

```
Request → Inbound Policy 1 → Inbound Policy 2 → Handler → Outbound Policy 1 → Outbound Policy 2 → Response
```

## Finding the right policy

1. **Check the policy index** at `node_modules/zuplo/docs/policies/_index.md` for a list of all built-in policies
2. **Read the specific policy docs** at `node_modules/zuplo/docs/policies/{policy-id}/doc.md` — each policy also has a `schema.json` with the full config schema
3. **If no built-in policy fits**, write a custom code policy (see below)

## Step-by-step: Add a built-in policy

### Step 1: Define the policy in `config/policies.json`

Look up the policy in the catalog or docs. Add its configuration to the `policies` array:

```json
{
  "policies": [
    {
      "name": "my-rate-limit",
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
}
```

**Policy configuration fields:**

| Field | Description |
|-------|-------------|
| `name` | Unique instance name. Referenced in routes. Use descriptive names like `auth-api-key` or `rate-limit-free-tier`. |
| `policyType` | The policy type identifier (e.g., `rate-limit-inbound`). Must match exactly. |
| `handler.export` | The exported class/function name from the module. |
| `handler.module` | For built-in: `$import(@zuplo/runtime)`. For custom: `$import(./modules/your-file)`. |
| `handler.options` | Policy-specific configuration object. Check docs for required/optional fields. |

### Step 2: Wire the policy to routes in `config/routes.oas.json`

Add the policy name to the `inbound` or `outbound` array in the route's `x-zuplo-route.policies`:

```json
{
  "paths": {
    "/products/{productId}": {
      "get": {
        "operationId": "get-product",
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
            "inbound": ["my-api-key-auth", "my-rate-limit"],
            "outbound": ["my-response-headers"]
          }
        }
      }
    }
  }
}
```

**Key points:**
- Policy names in the route must match the `name` field in `policies.json` exactly
- Inbound policies execute left-to-right (first in array runs first)
- Outbound policies also execute left-to-right
- A policy can be referenced by multiple routes
- The same policy type can have multiple instances with different names/options

### Step 3: Verify

After adding the policy, verify the project builds without errors. If using local dev:

```bash
npm run dev
```

## Common policy patterns

### Authentication + Rate Limiting (most common)

**`config/policies.json`:**
```json
{
  "policies": [
    {
      "name": "api-key-auth",
      "policyType": "api-key-inbound",
      "handler": {
        "export": "ApiKeyInboundPolicy",
        "module": "$import(@zuplo/runtime)",
        "options": {
          "allowUnauthenticatedRequests": false,
          "cacheTtlSeconds": 60
        }
      }
    },
    {
      "name": "rate-limit",
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
}
```

**Route wiring** — auth runs first, then rate limiting:
```json
"policies": {
  "inbound": ["api-key-auth", "rate-limit"]
}
```

### Request Validation

```json
{
  "name": "validate-request",
  "policyType": "request-validation-inbound",
  "handler": {
    "export": "RequestValidationInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "validateBody": "reject-and-log",
      "validateQueryParams": "reject-and-log",
      "validatePathParams": "reject-and-log"
    }
  }
}
```

### JWT Authentication (Auth0, Clerk, Supabase, etc.)

```json
{
  "name": "jwt-auth",
  "policyType": "open-id-jwt-auth-inbound",
  "handler": {
    "export": "OpenIdJwtInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "issuer": "https://your-issuer.com/",
      "audience": "https://your-api.com/",
      "jwkUrl": "https://your-issuer.com/.well-known/jwks.json",
      "allowUnauthenticatedRequests": false
    }
  }
}
```

## Writing custom code policies

When no built-in policy fits, create a custom policy.

### Custom inbound policy

**1. Create the module** at `modules/my-policy.ts`:

```typescript
import { ZuploRequest, ZuploContext } from "@zuplo/runtime";

type MyPolicyOptions = {
  // TODO: Define your options
  headerName: string;
};

export default async function (
  request: ZuploRequest,
  context: ZuploContext,
  options: MyPolicyOptions,
  policyName: string,
): Promise<ZuploRequest | Response> {
  // Return ZuploRequest to continue the pipeline
  // Return Response to short-circuit (e.g., 401, 403)

  const value = request.headers.get(options.headerName);
  if (!value) {
    return new Response("Missing required header", { status: 400 });
  }

  return request;
}
```

**2. Define in `config/policies.json`:**

```json
{
  "name": "my-custom-policy",
  "policyType": "custom-code-inbound",
  "handler": {
    "export": "default",
    "module": "$import(./modules/my-policy)",
    "options": {
      "headerName": "X-Custom-Header"
    }
  }
}
```

### Custom outbound policy

**1. Create the module** at `modules/my-outbound-policy.ts`:

```typescript
import { ZuploRequest, ZuploContext } from "@zuplo/runtime";

export default async function (
  response: Response,
  request: ZuploRequest,
  context: ZuploContext,
  options: any,
  policyName: string,
): Promise<Response> {
  // Create new Response to modify (Response objects are immutable)
  const newResponse = new Response(response.body, {
    status: response.status,
    headers: response.headers,
  });
  newResponse.headers.set("X-Custom-Header", "value");
  return newResponse;
}
```

**2. Define in `config/policies.json`:**

```json
{
  "name": "my-outbound-policy",
  "policyType": "custom-code-outbound",
  "handler": {
    "export": "default",
    "module": "$import(./modules/my-outbound-policy)",
    "options": {}
  }
}
```

## Programmatic policy invocation

Policies can be invoked conditionally from handlers or other policies:

```typescript
// Invoke an inbound policy conditionally
const result = await context.invokeInboundPolicy("rate-limit", request);
if (result instanceof Response) return result; // policy short-circuited

// Invoke an outbound policy
const transformed = await context.invokeOutboundPolicy("transform", response, request);
```

## Composite policies (grouping)

Use composite policies to group multiple policies together:

```json
{
  "name": "my-composite-outbound",
  "policyType": "composite-outbound",
  "handler": {
    "export": "CompositeOutboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "policies": ["outbound-policy-1", "outbound-policy-2"]
    }
  }
}
```

## Documentation lookup

For any policy, always read its documentation before configuring:

- **Local docs (preferred):** `node_modules/zuplo/docs/policies/{policy-id}/doc.md` and `schema.json`
- **Policy index:** `node_modules/zuplo/docs/policies/_index.md`
- **MCP tools:** Use `search-zuplo-docs` or `ask-question-about-zuplo` if available
- **By URL:** `https://zuplo.com/docs/policies/{policy-id}`
- **Machine-readable catalog:** `https://cdn.zuplo.com/portal/policies.v6.json`
