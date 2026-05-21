# OpenAPI Review Checklist

Detailed checklist for reviewing an OpenAPI 3.1 spec. Each section lists what to look for, examples of weak vs. strong, and what severity to assign.

## Table of contents

1. [Info block](#1-info-block)
2. [Servers](#2-servers)
3. [Tags](#3-tags)
4. [Paths and operations](#4-paths-and-operations)
5. [Parameters](#5-parameters)
6. [Request bodies](#6-request-bodies)
7. [Responses](#7-responses)
8. [Components / schemas](#8-components--schemas)
9. [Security](#9-security)
10. [Reusability and consistency](#10-reusability-and-consistency)
11. [Examples](#11-examples)

---

## 1. Info block

Check:
- `title` — present and meaningful (not "API")
- `version` — present, semver-style preferred
- `description` — present, more than one line, explains what the API does and who it's for
- `contact` — present with email or URL (helps users when things break)
- `license` — present if the API is meant to be used publicly
- `termsOfService` — present for commercial APIs

**Weak:** `description: "REST API"`
**Strong:** Multi-paragraph description with overview, key concepts, and a pointer to getting-started docs.

Severity: missing `title`/`version` = critical (spec invalid). Missing `description` = high. Missing `contact`/`license` = medium.

---

## 2. Servers

Check:
- At least one `servers` entry
- Each server has a `description` (Production, Staging, etc.)
- Use server variables for tenant/region patterns rather than listing every URL

**Weak:**
```yaml
servers:
  - url: https://api.example.com
```

**Strong:**
```yaml
servers:
  - url: https://api.example.com
    description: Production
  - url: https://api.{region}.example.com
    description: Regional production
    variables:
      region:
        enum: [us, eu, ap]
        default: us
```

Severity: no `servers` = high. Missing descriptions = medium.

---

## 3. Tags

Check:
- All tags used in operations are defined at root
- Each root-level tag has a `description`
- Tag naming is consistent (don't mix `Users`, `user-management`, `Auth`)
- Tags are used to group operations meaningfully

**Weak:** Operations use `tags: [users]`, `tags: [User]`, `tags: [user-mgmt]` interchangeably.
**Strong:** A single canonical tag name per concept, defined once at root with a description.

Severity: undefined tags = high (renders as untagged section). Inconsistent naming = medium. Missing descriptions = medium.

---

## 4. Paths and operations

Per operation, check:
- `operationId` — present, unique, descriptive (`getUserById`, not `op1`)
- `summary` — present, short (under ~50 chars), action-oriented
- `description` — present, explains what, when, and any gotchas
- `tags` — present and references defined tags
- `deprecated` — set when applicable, with explanation in description

**Weak summary:** `summary: get user`
**Strong summary:** `summary: Get user by ID`

**Weak description:** Just repeats the summary.
**Strong description:** "Returns the full user profile including embedded organization memberships. Use this when you need the canonical user record; for lightweight existence checks, use HEAD /users/{id}."

Severity: missing `operationId` = high (breaks SDK gen). Missing `summary` = high (sidebar shows path). Missing/weak `description` = high. Missing `tags` = high (operation falls into "default" group).

---

## 5. Parameters

Per parameter, check:
- `description` — present
- `required` — set correctly (path params must be required)
- `schema` — present with `type` and any constraints
- `example` or `examples` — present for non-obvious values

**Weak:**
```yaml
parameters:
  - name: id
    in: path
    required: true
    schema: { type: string }
```

**Strong:**
```yaml
parameters:
  - name: id
    in: path
    required: true
    description: The unique identifier of the user (UUID v4).
    schema:
      type: string
      format: uuid
      example: "550e8400-e29b-41d4-a716-446655440000"
```

Severity: missing `schema` = critical. Missing `description` = medium. Missing `example` for non-obvious = low.

---

## 6. Request bodies

Check:
- `description` on the request body itself
- `required: true` set if needed
- `content` has a schema (preferably `$ref` to a named component, not inline)
- Schema has examples
- All supported media types listed

**Weak:** Inline schema with 15 properties, no description, no example.
**Strong:** `$ref: "#/components/schemas/CreateUserRequest"` to a named schema with full descriptions and examples.

Severity: missing schema = critical. Inline complex schema that should be reusable = medium.

---

## 7. Responses

Check:
- Every operation has at least the success status documented (200, 201, 204, etc.)
- Error responses documented (400, 401, 403, 404, 409, 422, 500 as applicable)
- Each response has a `description`
- Each response has a `content` schema (except 204)
- Errors use a consistent shape (e.g., RFC 7807 `application/problem+json`)
- Headers documented where relevant (rate-limit headers, location, etc.)

**Weak:** Only `200: OK` documented.
**Strong:** Success + all expected error codes, each with a `$ref` to a shared `Error` schema or RFC 7807 `Problem` schema.

Severity: missing success response = critical. Missing error responses = high. Inconsistent error shapes across operations = high.

---

## 8. Components / schemas

Per schema, check:
- `description` on the schema itself
- `description` on each property
- `type` and constraints (`format`, `minLength`, `pattern`, `minimum`, etc.)
- `required` array set correctly
- `example` or `examples` present
- `additionalProperties: false` if the schema is closed (prevents accidental extra fields)
- Discriminators set for polymorphic schemas (`oneOf`, `anyOf` with shared key)
- Nullable handled with `type: [string, "null"]` (3.1) not `nullable: true` (3.0)

**Weak:**
```yaml
User:
  type: object
  properties:
    id: { type: string }
    email: { type: string }
```

**Strong:**
```yaml
User:
  type: object
  description: A registered user account.
  required: [id, email]
  properties:
    id:
      type: string
      format: uuid
      description: Stable identifier assigned at creation.
    email:
      type: string
      format: email
      description: Primary contact email; also used for login.
      example: "alex@example.com"
```

Severity: missing top-level description = high. Missing property descriptions = high. Missing `required` = high. Missing examples = medium. `nullable: true` in 3.1 spec = medium (silently ignored).

---

## 9. Security

Check:
- `securitySchemes` defined under `components`
- Each scheme has a `description`
- Global `security` array set, OR per-operation `security` overrides documented
- Public endpoints explicitly opt out with `security: []`
- For OAuth2, scopes are defined and used per-operation
- For API keys, location (`header`, `query`, `cookie`) is right

**Weak:** Security scheme defined but never applied anywhere.
**Strong:** Global `security`, with explicit `security: []` on public endpoints like `/health` and `/login`.

Severity: scheme defined but not applied = high. Missing scope documentation for OAuth2 = high.

---

## 10. Reusability and consistency

Check:
- Repeated inline shapes pulled into `components/schemas`
- Repeated parameters pulled into `components/parameters`
- Repeated responses pulled into `components/responses`
- Naming conventions consistent across the spec (camelCase vs. snake_case — pick one)
- Pagination, filtering, sorting handled the same way across list endpoints
- Date/time fields all use the same format (ideally `date-time`)
- Money amounts handled consistently (minor units integer vs. decimal string)

Severity: significant duplication = medium-high. Inconsistent naming = medium.

---

## 11. Examples

Beyond per-property examples, check:
- Request and response examples on operations
- Multiple `examples` (named) where there's meaningful variety
- Examples are realistic (not `"string"`, `"foo"`, or `0`)
- Examples are actually valid against the schema

**Weak:**
```yaml
example: "string"
```

**Strong:**
```yaml
examples:
  individual:
    summary: Individual customer
    value:
      type: individual
      firstName: Alex
      lastName: Müller
      email: alex@example.com
  business:
    summary: Business customer
    value:
      type: business
      companyName: "Acme GmbH"
      vatId: "DE123456789"
      contactEmail: billing@acme.example
```

Severity: missing examples = medium. Unrealistic examples = low (but call out — they hurt the docs even though the spec validates).

---

## Severity guide

When in doubt, here's how to think about severity:

- **Critical**: Spec is invalid or won't render (missing required OpenAPI fields, broken `$ref`s, invalid schemas).
- **High**: Spec is valid but documentation is materially broken — users can't figure out how to use the API from the docs alone. Missing descriptions on key elements, missing error responses, missing security application.
- **Medium**: Polish that meaningfully improves the docs — weak descriptions, missing examples, inconsistent naming, missing tag descriptions.
- **Low**: Nice-to-have — style consistency, minor extension opportunities.

If a spec has dozens of findings of the same kind, collapse them into a thematic finding ("All 47 operations under `/admin` lack descriptions — treat as a single workstream") rather than enumerating each.
