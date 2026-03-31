# Setup Steps Reference

Detailed configuration reference for each step of a new Zuplo project setup. Read the relevant section when you need the full configuration details beyond what's in the main skill file.

## Project creation options

### Using `create-zuplo-api`

```bash
# Empty project (recommended for starting from scratch)
npx create-zuplo-api@latest my-api --empty

# From a template
npx create-zuplo-api@latest my-api --example basic-api-gateway

# With tooling
npx create-zuplo-api@latest my-api --eslint --prettier

# Non-interactive with defaults
npx create-zuplo-api@latest my-api -y
```

Browse available templates at `https://zuplo.com/examples`.

### Using the Zuplo CLI directly

If the CLI is already installed globally:

```bash
zuplo init my-api
```

### Connecting to the platform

After creating the project locally, connect it to Zuplo's platform:

```bash
zuplo login          # Authenticate (one-time)
zuplo init           # Initialize on the platform
zuplo link           # Link to an existing project/environment
```

`zuplo link` creates `.env.zuplo` with account/project/environment info, enabling local access to Zuplo services (API keys, rate limiting, etc.).

## Route configuration details

### OpenAPI 3.1 structure

Routes live in `config/routes.oas.json`. The file is a standard OpenAPI 3.1 document with Zuplo extensions.

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "My API",
    "version": "1.0.0"
  },
  "paths": {
    "/v1/todos": {
      "x-zuplo-path": {
        "pathMode": "open-api"
      },
      "get": {
        "summary": "List all todos",
        "description": "Returns a list of todo items",
        "operationId": "listTodos",
        "x-zuplo-route": {
          "corsPolicy": "none",
          "handler": {
            "export": "urlForwardHandler",
            "module": "$import(@zuplo/runtime)",
            "options": {
              "baseUrl": "https://your-backend.example.com",
              "forwardSearch": true
            }
          },
          "policies": {
            "inbound": [],
            "outbound": []
          }
        },
        "responses": {
          "200": {
            "description": "Successful response"
          }
        }
      },
      "post": {
        "summary": "Create a todo",
        "operationId": "createTodo",
        "x-zuplo-route": {
          "corsPolicy": "none",
          "handler": {
            "export": "urlForwardHandler",
            "module": "$import(@zuplo/runtime)",
            "options": {
              "baseUrl": "https://your-backend.example.com",
              "forwardSearch": true
            }
          },
          "policies": {
            "inbound": [],
            "outbound": []
          }
        },
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["title"],
                "properties": {
                  "title": { "type": "string" },
                  "completed": { "type": "boolean", "default": false }
                }
              }
            }
          }
        }
      }
    },
    "/v1/todos/{todoId}": {
      "x-zuplo-path": {
        "pathMode": "open-api"
      },
      "get": {
        "summary": "Get a todo by ID",
        "operationId": "getTodo",
        "parameters": [
          {
            "name": "todoId",
            "in": "path",
            "required": true,
            "schema": { "type": "string" }
          }
        ],
        "x-zuplo-route": {
          "corsPolicy": "none",
          "handler": {
            "export": "urlForwardHandler",
            "module": "$import(@zuplo/runtime)",
            "options": {
              "baseUrl": "https://your-backend.example.com",
              "forwardSearch": true
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

### Path modes

The `x-zuplo-path.pathMode` controls how paths are matched:

- `open-api` — Standard OpenAPI path matching (recommended)
- `url-pattern` — Uses the URL Pattern API for advanced matching

### Built-in handlers

| Handler | Use case |
| ------- | -------- |
| `urlForwardHandler` | Proxy requests to an upstream URL (most common) |
| `urlRewriteHandler` | Rewrite the URL before forwarding |
| `redirectHandler` | Return a redirect response |

For custom logic, write a handler in `modules/`:

```ts
// modules/my-handler.ts
import { ZuploRequest, ZuploContext } from "@zuplo/runtime";

export default async function handler(
  request: ZuploRequest,
  context: ZuploContext,
) {
  // Your handler logic
  return new Response(JSON.stringify({ hello: "world" }), {
    headers: { "content-type": "application/json" },
  });
}
```

Reference it in routes:

```json
"handler": {
  "export": "default",
  "module": "$import(./modules/my-handler)"
}
```

## Rate limiting configuration

### Basic IP-based rate limiting

```json
{
  "name": "rate-limit-inbound",
  "policyType": "rate-limit-inbound",
  "handler": {
    "export": "RateLimitInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "rateLimitBy": "ip",
      "requestsAllowed": 100,
      "timeWindowMinutes": 1
    }
  }
}
```

### User-based rate limiting (requires authentication)

```json
{
  "name": "rate-limit-inbound",
  "policyType": "rate-limit-inbound",
  "handler": {
    "export": "RateLimitInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "rateLimitBy": "user",
      "requestsAllowed": 1000,
      "timeWindowMinutes": 1
    }
  }
}
```

### Rate limit by function (advanced)

For dynamic rate limiting based on request properties, user metadata, etc., use `rateLimitBy: "function"` and provide a custom function. Fetch `https://zuplo.com/docs/policies/rate-limit-inbound` for full details.

**Important:** Always place rate limiting AFTER authentication in the inbound policy array so that `rateLimitBy: "user"` has access to the authenticated user identity.

## Authentication setup

### API key authentication

Policy configuration:

```json
{
  "name": "api-key-inbound",
  "policyType": "api-key-inbound",
  "handler": {
    "export": "ApiKeyInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {}
  }
}
```

Default behavior:
- Looks for the key in the `Authorization: Bearer <key>` header
- Rejects unauthenticated requests with a 401 response
- Sets `request.user` with the consumer's identity and metadata

Options you may configure:
- `allowUnauthenticatedRequests` — Set to `true` to allow passthrough (useful when combining with JWT)
- Custom header/query parameter location

After adding the policy, set up API keys:

1. **Portal:** Go to **Services > API Key Service > Configure**
2. **Create consumers:** Each consumer gets one or more API keys
3. **Add metadata:** Attach custom data to consumers (plan tier, permissions, etc.)
4. **Manage keys:** Create, rotate, and revoke keys through the portal or API

API keys follow the format: `zpka_<key>_<suffix>`

### JWT authentication (OpenID Connect)

For integrating with identity providers (Auth0, Cognito, Firebase, Okta, etc.):

```json
{
  "name": "jwt-auth-inbound",
  "policyType": "open-id-jwt-auth-inbound",
  "handler": {
    "export": "OpenIdJwtInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "issuer": "https://your-idp.example.com/",
      "audience": "your-api-audience",
      "jwkUrl": "https://your-idp.example.com/.well-known/jwks.json"
    }
  }
}
```

Fetch the specific provider doc for exact configuration:
- Auth0: `https://zuplo.com/docs/policies/auth0-jwt-auth-inbound`
- Cognito: `https://zuplo.com/docs/policies/cognito-jwt-auth-inbound`
- Firebase: `https://zuplo.com/docs/policies/firebase-jwt-auth-inbound`
- Generic OIDC: `https://zuplo.com/docs/policies/open-id-jwt-auth-inbound`

### Combining API keys and JWT

To support both auth methods on the same route, set `allowUnauthenticatedRequests: true` on the API key policy so unauthenticated requests fall through to the JWT policy:

```json
"inbound": ["api-key-inbound", "jwt-auth-inbound"]
```

With the API key policy configured:

```json
{
  "name": "api-key-inbound",
  "policyType": "api-key-inbound",
  "handler": {
    "export": "ApiKeyInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "allowUnauthenticatedRequests": true
    }
  }
}
```

## CORS configuration

### Built-in policies

- `none` — Strips all CORS headers (default)
- `anything-goes` — Allows everything (development only, never use in production)

### Custom CORS policy

Defined in the `corsPolicies` array in `config/policies.json`:

```json
{
  "corsPolicies": [
    {
      "name": "production-cors",
      "allowedOrigins": [
        "https://app.example.com",
        "https://admin.example.com"
      ],
      "allowedMethods": ["GET", "POST", "PUT", "DELETE", "PATCH"],
      "allowedHeaders": ["Authorization", "Content-Type", "X-Request-Id"],
      "exposeHeaders": ["X-Request-Id", "X-RateLimit-Remaining"],
      "maxAge": 3600,
      "allowCredentials": true
    }
  ]
}
```

### Wildcard origins

```json
"allowedOrigins": ["https://*.example.com"]
```

### Environment-specific CORS

Use environment variables in origins for different configs per environment:

```json
"allowedOrigins": ["$env(CORS_ALLOWED_ORIGIN)"]
```

Set different `CORS_ALLOWED_ORIGIN` values for each environment (prod, preview, development).

### Applying to routes

```json
"x-zuplo-route": {
  "corsPolicy": "production-cors"
}
```

## Environment variables

### Types

| Type | Description |
| ---- | ----------- |
| **Configuration** | Non-secret values, readable after creation |
| **Secret** | Write-only values, cannot be retrieved once set |

### Environments

| Environment | Description |
| ----------- | ----------- |
| Prod | Deployed from the default branch (usually `main`) |
| Preview | Deployed from non-default branches |
| Development | Used during local development |

### Setting via CLI

```bash
# Non-secret
zuplo variable create --name BACKEND_URL --value "https://api.example.com" --is-secret false --branch main

# Secret
zuplo variable create --name BACKEND_SECRET --value "super-secret" --is-secret true --branch main
```

### Using in code

```ts
import { environment } from "@zuplo/runtime";

export default async function handler(request: ZuploRequest, context: ZuploContext) {
  const apiUrl = environment.BACKEND_URL;
  // ...
}
```

### Using in JSON configuration

The `$env()` selector works in policy options and handler options:

```json
{
  "options": {
    "baseUrl": "$env(BACKEND_URL)"
  }
}
```

```json
{
  "options": {
    "headers": [
      {
        "name": "x-backend-secret",
        "value": "$env(BACKEND_SECRET)"
      }
    ]
  }
}
```

## Backend security options

### 1. Shared secret (simplest, most common)

Add a secret header that only the gateway knows. See the main skill file for the full example.

### 2. Cloud provider IAM

- **GCP:** Use the Upstream GCP Service Auth policy (`https://zuplo.com/docs/policies/upstream-gcp-service-auth-inbound`)
- **AWS:** Use IAM roles and the Upstream AWS Lambda Auth policy
- **Azure:** Use the Upstream Azure AD Service Auth policy (`https://zuplo.com/docs/policies/upstream-azure-ad-service-auth-inbound`)

### 3. mTLS (enterprise)

Mutual TLS with client certificates. Fetch `https://zuplo.com/docs/articles/securing-backend-mtls`.

### 4. Secure tunnels (enterprise)

WireGuard-based tunnel for backends not exposed to the internet. Fetch `https://zuplo.com/docs/articles/secure-tunnel`.

Full guide: `https://zuplo.com/docs/articles/securing-your-backend`

## Developer portal

The developer portal is powered by Zudoku and lives in `docs/`.

### Configuration

The portal is configured via `docs/zudoku.config.ts`. It auto-generates API reference docs from your OpenAPI spec.

### Adding custom pages

Create Markdown files in `docs/pages/`:

```
docs/
├── zudoku.config.ts
└── pages/
    ├── getting-started.md
    ├── authentication.md
    └── rate-limits.md
```

### Running standalone

```bash
zuplo docs                                          # Default port 9200
zuplo docs --port 3000                              # Custom port
zuplo docs --server-url https://my-api.zuplo.dev    # Point to remote API
```

For full customization (themes, auth providers, custom React components), fetch `https://zuplo.com/docs/dev-portal/introduction`.

## Deployment workflows

### Local development → CLI deploy

```bash
npx create-zuplo-api@latest my-api
cd my-api
npm install
npm run dev              # Develop locally
zuplo login              # Authenticate
zuplo init               # Initialize on platform
zuplo deploy             # Deploy
```

### Git integration (recommended)

1. Connect GitHub in the Zuplo Portal: **Settings > Source Control**
2. Authorize the Zuplo GitHub app
3. Every push deploys automatically
4. Each branch gets its own environment URL
5. Merge to `main` deploys to production

### CI/CD pipeline

```bash
export ZUPLO_API_KEY=zpka_xxxxx
zuplo deploy --environment production --account my-acct --project my-proj
```

Get API keys from **portal.zuplo.com > Settings > API Keys**.

### Environment management

- `main` branch → production environment
- Feature branches → preview environments (auto-created, auto-deleted)
- Use `zuplo list` to see all deployed environments
- Use `zuplo delete --url <env-url>` to remove an environment
