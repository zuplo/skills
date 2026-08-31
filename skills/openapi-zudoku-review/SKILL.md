---
name: openapi-zudoku-review
description: "Review an OpenAPI 3.1 specification for documentation quality with an eye toward how it will render in Zudoku/Zuplo developer portals. Produces a thorough findings report grouped by severity (covering missing schemas, weak descriptions, schema hygiene, and Zudoku-specific extensions like x-tagGroups, x-code-samples, x-displayName, x-mcp-server, etc.), then offers to apply the changes to the spec. Use whenever a user shares an OpenAPI/Swagger file (.yaml, .yml, .json) and asks for a review, audit, lint, quality check, improvements, \"best practices\", \"docs cleanup\", or anything about making their API reference better — even if they don't mention Zudoku by name, since the underlying quality issues are the same and the Zudoku-specific suggestions are additive."
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/tools
---

# OpenAPI Zudoku Review

A thorough review skill for OpenAPI 3.1 specs, optimized for documentation quality and Zudoku/Zuplo portal rendering.

## What this skill does

Given an OpenAPI 3.1 spec, walk through it systematically and produce a findings report grouped by severity, then offer to apply the improvements. The review covers two layers:

1. **Generic OpenAPI documentation quality** — missing schemas, weak descriptions, inconsistent naming, missing examples, unstructured errors, etc. These problems exist regardless of the rendering tool.
2. **Zudoku-specific improvements** — Zudoku extensions (`x-tagGroups`, `x-displayName`, `x-code-samples`, `x-mcp-server`, etc.) and patterns that make the rendered portal noticeably better. See `references/zudoku-extensions.md` for the full reference.

The two layers are additive. Run layer 1 on every spec; suggest layer 2 enhancements where they would actually help (don't sprinkle extensions onto every operation just because they exist).

## When to invoke

Trigger whenever a user shares an OpenAPI spec file and wants any kind of quality assessment — "review", "audit", "lint", "clean up", "improve docs", "make this better", "what's missing". Trigger even if the user doesn't mention Zudoku; generic findings still apply, and you can mention Zudoku-specific opportunities as a bonus layer.

Do NOT trigger for: spec generation from scratch (different task), runtime debugging of an API, or code review of an API implementation.

## Workflow

### 1. Confirm scope and load the spec

Before reviewing, briefly confirm with the user:
- Which file? (If a single file is attached, just use it.)
- Is this OpenAPI 3.1? If it's 3.0 or Swagger 2.0, mention that the skill is tuned for 3.1 — 3.0 reviews still work but a few findings (like `nullable` vs. `type: ['string', 'null']`, or `webhooks` support) won't apply.
- Are they using Zudoku to render this, or do they just want general quality improvements? This shapes how much weight to give Zudoku-specific suggestions.

Parse the spec into a structure you can iterate over. YAML and JSON are both common; handle either.

### 2. Run the review

Walk through the spec systematically. Don't skip sections, but it's OK to summarize "everything in `components/schemas` looks clean" rather than enumerate the clean ones.

Cover these areas, in roughly this order — see `references/review-checklist.md` for the detailed checklist with examples of good vs. bad for each item:

1. **Info block** — title, version, description, contact, license, terms of service
2. **Servers** — at least one, with descriptions; environment variables for variants
3. **Tags** — defined at root, used consistently, with descriptions
4. **Paths and operations** — `operationId`, `summary`, `description`, `tags`, parameter descriptions, request body schemas, response schemas including error responses
5. **Components/schemas** — every schema has a description, properties have descriptions, examples are present, `required` is set correctly, no inline schemas that should be `$ref`'d
6. **Security schemes** — defined and applied; global vs. per-operation
7. **Reusability** — repeated inline shapes that should be extracted into `components`
8. **Zudoku layer** — opportunities to add `x-tagGroups`, `x-displayName`, `x-code-samples`, `x-mcp-server`, `x-zudoku-collapsed`, `x-zudoku-playground-enabled`, `x-mcp`

### 3. Produce the findings report

Output a markdown report with this exact structure:

```markdown
# OpenAPI Review: <spec title>

**Spec version:** <openapi version>
**Operations reviewed:** <count>
**Schemas reviewed:** <count>

## Summary

<2-3 sentences: overall quality, biggest themes>

## Critical
<findings that break the spec or break rendering — missing required fields, broken $refs, schemas that won't validate>

## High
<findings that significantly hurt the docs — missing operationId, missing response schemas, undocumented errors, missing top-level descriptions>

## Medium
<polish that meaningfully improves the docs — weak descriptions, missing examples, inconsistent naming, missing tags>

## Low / Nice-to-have
<minor improvements, style consistency>

## Zudoku-specific opportunities
<concrete suggestions to add Zudoku extensions where they'd improve the portal — only include if relevant>
```

For each finding, include:
- **Location** — JSON pointer or human-readable path (e.g., `paths./users.get` or `components.schemas.User.properties.email`)
- **Issue** — what's wrong in one sentence
- **Suggestion** — concrete fix, with a code snippet when useful

Group findings by severity, not by location — readers want to triage by importance first.

### 4. Offer to apply changes

After the report, ask the user how they want to proceed. Don't apply automatically — they may want to review first, or apply only a subset.

Offer these options:
- Apply all suggestions and produce an updated spec file
- Apply only specific severity levels (e.g., critical + high)
- Apply only specific findings (numbered list)
- Just keep the report

When applying changes, preserve formatting and comments as much as possible (use a YAML library that round-trips well, like `ruamel.yaml` for Python, rather than one that reformats everything). Output the updated spec as a new file (e.g., `spec.improved.yaml`) rather than overwriting, so the user can diff.

### 5. Summarize what changed

After applying, briefly summarize the diff at a high level: "Added X descriptions, extracted Y inline schemas into components, added Z code samples for the auth endpoints, introduced x-tagGroups for sidebar organization."

## Style notes

- Be specific. "The description is weak" is unhelpful. "The description just repeats the operation name — describe what the endpoint does, when to use it, and any gotchas" is useful.
- Prioritize value. A spec with 200 operations and weak descriptions everywhere shouldn't get 200 line items — group them into a theme ("All operations under `/admin` lack descriptions; treat them collectively").
- Don't moralize. The user knows their docs aren't perfect, that's why they're asking.
- Quote the user's existing text when suggesting rewrites, so the suggestion is concrete.
- For Zudoku extensions, only suggest them where they earn their keep. Suggesting `x-tagGroups` on a spec with 3 tags is silly; suggesting it on a spec with 25 tags is gold.

## Reference files

- `references/zudoku-extensions.md` — concise reference for all 8 Zudoku extensions: what each does, where it goes, when to suggest it, and a minimal example.
- `references/review-checklist.md` — detailed checklist of what to look for, with good/bad examples for each category. Read this when running the review so you don't miss anything.
