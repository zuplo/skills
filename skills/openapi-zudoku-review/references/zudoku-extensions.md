# Zudoku OpenAPI Extensions Reference

Zudoku supports 8 OpenAPI extensions that affect how the rendered portal looks and behaves. Use this reference to know what to suggest, where it goes in the spec, and when it actually helps versus when it's noise.

## Cheat sheet

| Extension | Location | What it does | When to suggest |
|---|---|---|---|
| `x-tagGroups` | Root | Groups tags into sidebar sections | Spec has 8+ tags that fall into themes |
| `x-displayName` | Tag object | Pretty label for a tag (e.g. `ai-ops` → `AI Operations`) | Tag names are kebab-case, snake_case, or otherwise not human-friendly |
| `x-code-samples` (alias: `x-codeSamples`) | Operation | Custom code samples in sidebar | Operation is unusual, auth is non-trivial, or the user has hand-tuned snippets |
| `x-zudoku-collapsed` | Tag object | Initial collapsed state in sidebar | Some tags are advanced/optional and shouldn't dominate the sidebar at first glance |
| `x-zudoku-collapsible` | Tag object | Whether user can collapse a tag at all | "Getting Started" or core sections that should always be visible |
| `x-zudoku-playground-enabled` (alias: `x-explorer-enabled`) | Operation | Show/hide the API playground per operation | Webhooks, destructive ops, or anything that shouldn't be triggered from the docs |
| `x-mcp-server` | Operation | Marks an operation as an MCP endpoint; replaces request/response UI with MCP client setup card | Operation actually serves MCP traffic |
| `x-mcp` | Root | Describes a full MCP server's tools/resources/prompts at the document root | Spec describes an MCP server holistically (rendering support is in development) |

---

## x-tagGroups (root level)

Organize tags into named sidebar groups. Without this, tags are a flat list.

```yaml
tags:
  - name: Packages
  - name: Parcels
  - name: Tracking
  - name: Billing

x-tagGroups:
  - name: Shipment
    tags: [Packages, Parcels]
  - name: Management
    tags: [Tracking, Billing]
```

**Suggest when:** The spec has roughly 8+ tags that naturally cluster. Don't suggest for small specs — flat lists are fine under ~6 tags.

---

## x-displayName (tag object)

Override the tag's display label without changing the tag name (which operations reference).

```yaml
tags:
  - name: ai-ops
    description: AI-powered operations
    x-displayName: AI Operations
```

**Suggest when:** Tag names use kebab-case, snake_case, abbreviations, or otherwise look ugly in a sidebar. Don't rename the tag itself — that breaks operation references.

---

## x-code-samples (operation level)

Custom code snippets that appear in the sidecar alongside auto-generated examples.

```yaml
paths:
  /users:
    get:
      x-code-samples:
        - lang: curl
          label: cURL
          source: |
            curl https://api.example.com/users \
              -H "Authorization: Bearer $TOKEN"
        - lang: python
          label: Python
          source: |
            import requests
            requests.get("https://api.example.com/users",
                         headers={"Authorization": f"Bearer {token}"})
```

**Suggest when:** Auth flow is non-trivial (custom headers, signing, OAuth dance), or the operation has a tricky payload shape that benefits from a worked example. Don't suggest blanket addition — auto-generated samples are usually fine.

---

## x-zudoku-collapsed (tag object)

Whether a tag's section starts collapsed in the sidebar. Defaults to `true`.

```yaml
tags:
  - name: Getting Started
    x-zudoku-collapsed: false
  - name: Advanced
    x-zudoku-collapsed: true
```

**Suggest when:** There's a clear "primary path" through the docs that should be open by default, and other sections are deep-dive material.

---

## x-zudoku-collapsible (tag object)

Whether a tag section *can* be collapsed at all. Defaults to `true`. Set `false` to lock a section open.

```yaml
tags:
  - name: Core API
    x-zudoku-collapsible: false
    x-zudoku-collapsed: false
```

**Suggest when:** There's a section the user always wants in front of readers (a `Getting Started`, an `Authentication` section). Use sparingly — taking away user control is friction.

---

## x-zudoku-playground-enabled (operation level)

Show/hide the interactive playground per operation. Alias: `x-explorer-enabled`. Defaults to whatever the global `disablePlayground` setting is.

```yaml
paths:
  /webhooks/trigger:
    post:
      x-zudoku-playground-enabled: false
```

**Suggest when:** Operation is destructive without confirmation (delete account), triggers external systems (sends real webhook, charges a card), or doesn't make sense interactively (long-running async job).

---

## x-mcp-server (operation level)

Marks an operation as an MCP endpoint. Zudoku replaces the standard request/response view with an MCP card showing the endpoint URL and client setup tabs (Claude, ChatGPT, Cursor, VS Code, generic).

Boolean shorthand:
```yaml
paths:
  /mcp:
    post:
      summary: My MCP Server
      x-mcp-server: true
```

Object form (richer):
```yaml
x-mcp-server:
  name: my-mcp-server
  version: 1.0.0
  tools:
    - name: search_docs
      description: Search the documentation
    - name: get_page
      description: Retrieve a specific documentation page
```

**Suggest when:** The operation genuinely serves MCP traffic. Don't add to non-MCP endpoints.

---

## x-mcp (root level)

Describes an MCP server's protocol version, capabilities, tools, resources, and prompts at the document root. Rendering support is in development; for per-operation MCP UI today, use `x-mcp-server`.

```yaml
x-mcp:
  protocolVersion: "2025-06-18"
  capabilities:
    tools:
      listChanged: true
  tools:
    - name: clients/get
      description: Get a client by ID
      inputSchema:
        type: object
        properties:
          clientId: { type: string }
      outputSchema:
        $ref: "#/components/schemas/Client"
```

**Suggest when:** The whole spec describes an MCP server (not just one endpoint). Forward-looking; mention that rendering is in development.

---

## What NOT to suggest

A few patterns to avoid:

- Don't suggest extensions just because they exist. If a spec is small and clean, the answer is usually "no extensions needed."
- Don't conflate `x-mcp` and `x-mcp-server`. `x-mcp-server` is per-operation, has full UI today. `x-mcp` is document-level, rendering still in development.
- Don't use `x-zudoku-collapsible: false` casually — it removes user control. Reserve for sections that genuinely should always be visible.
