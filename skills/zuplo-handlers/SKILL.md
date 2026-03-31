---
name: zuplo-handlers
description: Configure and write request handlers for Zuplo API gateway routes. Use when the user wants to set up URL forwarding/proxying, URL rewriting, redirects, custom TypeScript handlers, AWS Lambda integration, WebSockets, MCP servers, or OpenAPI spec serving. Covers all built-in handlers and custom handler patterns.
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/skills
---

# Zuplo Handlers

This skill helps you configure request handlers on Zuplo API gateway routes. A handler is the core logic that processes a request and produces a response — it runs after inbound policies and before outbound policies.

## Critical rule: Read docs before configuring

Before configuring ANY handler, you MUST read the relevant documentation first. Do not rely on training data. Use these sources in priority order:

1. **Local docs (preferred):** Read from `node_modules/zuplo/docs/handlers/` — each handler has a dedicated doc file. Check both the project root and parent directories for monorepos.
2. **MCP server tools:** Use `search-zuplo-docs` and `ask-question-about-zuplo` if the Zuplo MCP server is connected.
3. **Fetch docs via URL:** Fetch `https://zuplo.com/docs/handlers/{handler-name}` or discover pages at `https://zuplo.com/docs/llms.txt`.

## How handlers work

Every route in `config/routes.oas.json` has exactly one handler. The handler is configured in the `x-zuplo-route.handler` object:

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
            "inbound": [],
            "outbound": []
          }
        }
      }
    }
  }
}
```

**Handler configuration fields:**

| Field | Description |
|-------|-------------|
| `export` | The exported handler function name (e.g., `urlForwardHandler`, `default`) |
| `module` | For built-in: `$import(@zuplo/runtime)`. For custom: `$import(./modules/your-file)` |
| `options` | Handler-specific configuration object |

## Choosing the right handler

| Need | Handler | When to use |
|------|---------|-------------|
| Proxy to backend API | `urlForwardHandler` | Simple proxying where gateway path is appended to backend base URL |
| Proxy with URL reshaping | `urlRewriteHandler` | Complex URL mapping, parameter rearrangement, host switching |
| Custom logic | Function handler | Any custom TypeScript logic — return JSON, call APIs, transform data |
| HTTP redirect | `redirectHandler` | Redirect clients to a different URL (301/302/307/308) |
| AWS Lambda | `awsLambdaHandler` | Invoke AWS Lambda functions directly |
| WebSocket | `webSocketHandler` | WebSocket connections |
| MCP server | `mcpServerHandler` | Expose API routes as MCP tools for AI agents |
| Serve OpenAPI spec | `openApiSpecHandler` | Serve a public version of the OpenAPI spec |

Full reference for each handler: read the corresponding file in `node_modules/zuplo/docs/handlers/` (e.g. `url-forward.mdx`, `custom-handler.mdx`).

## URL Forward Handler (most common)

Proxies requests by appending the incoming path to a base URL. Incoming `https://gateway.com/api/users/123` with `baseUrl` of `https://backend.com/v2` becomes `https://backend.com/v2/api/users/123`.

```json
"handler": {
  "export": "urlForwardHandler",
  "module": "$import(@zuplo/runtime)",
  "options": {
    "baseUrl": "${env.BACKEND_URL}"
  }
}
```

**Options:**
- `baseUrl` (required) — Target base URL. Supports template interpolation.
- `forwardSearch` (optional, default: `true`) — Forward query parameters.
- `followRedirects` (optional, default: `false`) — Follow redirects automatically.

## URL Rewrite Handler

Full control over the target URL via template pattern. Use when you need to reshape paths, rearrange parameters, or switch hosts.

```json
"handler": {
  "export": "urlRewriteHandler",
  "module": "$import(@zuplo/runtime)",
  "options": {
    "rewritePattern": "https://api-${params.version}.example.com/v2/users/${params.userId}"
  }
}
```

**Options:**
- `rewritePattern` (required) — Full target URL template.
- `forwardSearch` (optional, default: `true`) — Forward query parameters.
- `followRedirects` (optional, default: `false`) — Follow redirects automatically.

### Template variables (both URL handlers)

Available in `baseUrl` and `rewritePattern`:

| Variable | Example value |
|----------|---------------|
| `${env.VARIABLE_NAME}` | Environment variable value |
| `${params.paramName}` | Route parameter (e.g., `:paramName`) |
| `${query.key}` | Query string parameter |
| `${headers.get("name")}` | Request header value |
| `${pathname}` | `/v1/products/123` |
| `${hostname}` | `example.com` |
| `${host}` | `example.com:8080` |
| `${method}` | `GET` |
| `${origin}` | `https://example.com` |
| `${protocol}` | `https:` |
| `${port}` | `8080` |
| `${search}` | `?category=cars` |
| `${url}` | Full URL string |
| `${encodeURIComponent(value)}` | URL-encoded value (alias: `${e(value)}`) |
| `${context.custom.key}` | Custom context value set by policies |

## Custom Function Handler

Write any logic in TypeScript. This is the most flexible option.

### Step 1: Create the handler module

Create a file in `modules/`, e.g., `modules/my-handler.ts`:

```typescript
import { ZuploRequest, ZuploContext } from "@zuplo/runtime";

export default async function (
  request: ZuploRequest,
  context: ZuploContext,
): Promise<Response> {
  // TODO: Implement your handler logic
  return new Response(JSON.stringify({ message: "Hello" }), {
    status: 200,
    headers: { "content-type": "application/json" },
  });
}
```

### Step 2: Configure the route

```json
"handler": {
  "export": "default",
  "module": "$import(./modules/my-handler)"
}
```

### Return behavior

- **Return any value** — auto-serialized to JSON with `application/json` content-type
- **Return a `Response`** — full control over status, headers, body
- **Return a string** — sent as-is

### Common patterns

**JSON API response:**
```typescript
import { ZuploRequest, ZuploContext } from "@zuplo/runtime";

export default async function (request: ZuploRequest, context: ZuploContext) {
  const { productId } = request.params;
  // Return value is auto-serialized to JSON
  return { id: productId, name: "Widget", price: 9.99 };
}
```

**Proxy with transformation:**
```typescript
import { ZuploRequest, ZuploContext, environment } from "@zuplo/runtime";

export default async function (request: ZuploRequest, context: ZuploContext) {
  const response = await fetch(
    `${environment.BACKEND_URL}/api${request.pathname}`,
    {
      method: request.method,
      headers: request.headers,
      body: request.body,
    },
  );

  const data = await response.json();
  // Transform the response
  return { ...data, gateway: "zuplo" };
}
```

**Reading request data:**
```typescript
import { ZuploRequest, ZuploContext } from "@zuplo/runtime";

export default async function (request: ZuploRequest, context: ZuploContext) {
  // Route params (e.g., /users/:userId)
  const userId = request.params.userId;

  // Query string (e.g., ?page=2)
  const page = request.query.page;

  // Request body
  const body = await request.json();

  // Headers
  const auth = request.headers.get("authorization");

  // Authenticated user (set by auth policies)
  const user = request.user?.sub;

  return { userId, page, body, user };
}
```

**HTML response:**
```typescript
export default async function () {
  return new Response("<html><body><h1>Hello</h1></body></html>", {
    status: 200,
    headers: { "content-type": "text/html" },
  });
}
```

**Named exports** (multiple handlers in one file):
```typescript
import { ZuploRequest, ZuploContext } from "@zuplo/runtime";

export async function getProduct(request: ZuploRequest, context: ZuploContext) {
  return { id: request.params.productId };
}

export async function listProducts(request: ZuploRequest, context: ZuploContext) {
  return [{ id: "1" }, { id: "2" }];
}
```

```json
// Route 1
"handler": { "export": "getProduct", "module": "$import(./modules/products)" }
// Route 2
"handler": { "export": "listProducts", "module": "$import(./modules/products)" }
```

## Redirect Handler

Send HTTP redirects:

```json
"handler": {
  "export": "redirectHandler",
  "module": "$import(@zuplo/runtime)",
  "options": {
    "location": "/docs",
    "status": 302
  }
}
```

**Options:**
- `location` (required) — Target URL or path.
- `status` (optional, default: `302`) — `301` (permanent), `302` (temporary), `307` (temporary, preserve method), `308` (permanent, preserve method).

## Other built-in handlers

Read the full docs for each in `node_modules/zuplo/docs/handlers/`:
- **AWS Lambda Handler** (`aws-lambda.mdx`) — invoke Lambda functions with IAM credentials
- **MCP Server Handler** (`mcp-server.mdx`) — expose routes as MCP tools for AI agents
- **OpenAPI Spec Handler** (`openapi.mdx`) — serve public OpenAPI spec
- **WebSocket Handler** (`websocket-handler.mdx`) — WebSocket connections

## Documentation lookup

For any handler, read its documentation before configuring:

- **Local docs (preferred):** `node_modules/zuplo/docs/handlers/{handler-name}.mdx`
- **MCP tools:** Use `search-zuplo-docs` or `ask-question-about-zuplo` if available
- **By URL:** `https://zuplo.com/docs/handlers/{handler-name}`
