---
name: zuplo-ai-gateway
description: "Use when working with a Zuplo AI Gateway project — connecting LLM providers, organizing teams and apps, wiring an app's policy chain (model filtering, fallback model, budgets, semantic cache), setting usage limits, or calling the gateway from application code. Covers how models are addressed as providerLabel/model, where an app's request URL comes from, how budgets cascade, and how to diagnose a rejected AI request."
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/tools
---

# Zuplo AI Gateway

One gateway in front of every LLM an organization calls: provider keys held in
one place, usage metered and capped per team and per app, and an
OpenAI-compatible surface so client SDKs need only a base URL change.

## Critical rule: Read docs before configuring

Read the relevant page before writing configuration — the AI Gateway's policy
names and metadata shapes are exact, and a guess breaks the app's policy chain.
Sources in priority order:

1. **Local docs (preferred):** `node_modules/zuplo/docs/ai-gateway/` when the
   `zuplo` package is installed. Check the project root and parent directories.
2. **MCP server tools:** `search-zuplo-docs` and `ask-question-about-zuplo` if
   the Zuplo MCP server is connected (names may be prefixed, e.g.
   `mcp__*Zuplo*__search-zuplo-docs`).
3. **Fetch by URL:** `https://zuplo.com/docs/ai-gateway/overview` and the pages
   under `https://zuplo.com/docs/ai-gateway/`.

## The three layers

| Layer         | What it is                                                                 | What it carries                                                        |
| ------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| **Providers** | The LLM vendors the gateway may route to (OpenAI, Anthropic, Google, Bedrock, Vertex, an OpenAI-compatible custom endpoint…) | The vendor API key, and the models the gateway may reach through it |
| **Teams**     | A hierarchy that groups apps and the people who own them                    | Shared usage limits, and who may access and manage the apps beneath   |
| **Apps**      | The pieces of software that call the gateway — a chatbot, an internal agent | Its own request URL, its own Zuplo-managed API key, its own policy chain, and the team it belongs to |

All three live inside one AI Gateway project. Read the layer a question is
about rather than guessing: which models are reachable is a *provider* question,
who is spending is a *team* and *app* question, why one request was rejected is
an *app policy chain* question.

## Models are addressed `providerLabel/model`

**The prefix is the name given to the provider configuration, not the vendor.**
A provider labelled `openai` yields `openai/gpt-5-mini`; label the same vendor
`openai-eu` and its models are `openai-eu/gpt-5-mini`. Two configurations of one
vendor — different keys, regions or accounts — are told apart by exactly this.

Take model ids from the gateway's own supported-model catalog, never from
memory: a model the gateway does not list is not routable, and a plausible id
you invented fails at request time rather than at configuration time.

Unrestricted, an app may call any model reachable through the project's
providers, and each request names its own in the `model` field.

## Calling an app

Each app has its own API URL, containing that app's id — the gateway attributes
usage from it. **Read that URL from the app itself; never construct it by hand
or borrow another app's.** The hostname is the deployed environment's, the path
segment identifies the app, and both come from the app, not from a pattern.

Under it sit the OpenAI-compatible services:

| Service          | Path                  |
| ---------------- | --------------------- |
| Chat Completions | `v1/chat/completions` |
| Responses        | `v1/responses`        |
| Messages         | `v1/messages`         |

```bash
curl https://<gateway-host>/<app-id>/v1/chat/completions \
  -H "Authorization: Bearer $APP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-5-mini",
    "messages": [{ "role": "user", "content": "Hello, world!" }]
  }'
```

Client SDKs generally want a base URL ending in `/v1`, so point the SDK at
`https://<gateway-host>/<app-id>/v1` and let it append its own paths. The app's
API key goes in `Authorization: Bearer …`, and is enforced when the
authentication policy is in the app's chain.

## The app's policy chain

An app runs an ordered chain, each entry chosen from the gateway's policy menu,
before the handler calls the provider. An entry can short-circuit the request —
a cache hit answers it, a guardrail blocks it.

| Policy               | Declaration                              | What it does                                             |
| -------------------- | ---------------------------------------- | -------------------------------------------------------- |
| Model Filtering      | `ai-gateway-model-filtering-v2-inbound`  | Restricts which models the app may call                   |
| Fallback Model       | `ai-gateway-fallback-model-v2-inbound`   | Routes to a fallback when a budget is spent or upstream fails |
| Budgets and Costs    | `ai-gateway-metering-v2-inbound`         | Meters cost, tokens and requests, and enforces the app's own limits |
| Semantic Cache       | `ai-gateway-semantic-cache-v2-inbound`   | Serves a semantically equivalent cached response          |
| Authentication       | `ai-gateway-auth-v2-inbound`             | Enforces the app's API key                                |

**The recommended order is Model Filtering → Fallback Model → Budgets and Costs
→ Semantic Cache, and the order is load-bearing:** budgets after the fallback so
an exceeded budget can route to the fallback model instead of failing, and the
cache after budgets so cache hits still count toward request limits.

A Model Filtering allow list does double duty: it restricts the models **and its
first entry becomes the default** when a request omits `model`.

## Usage limits cascade

Limits exist at three levels, and **all of them apply at once — a request is
blocked when any one is exceeded**:

| Level       | Covers                                   | Configured at                                  |
| ----------- | ---------------------------------------- | ---------------------------------------------- |
| **Gateway** | Every team and app in the project        | Settings → Usage Limits                        |
| **Team**    | All of that team's apps together         | The team's Usage & Limits tab                   |
| **App**     | That one app                             | The Budgets and Costs policy in its chain       |

Gateway and team limits are **inherited by every app beneath them**, whether or
not the app has Budgets and Costs in its own chain — so an app with no budget
policy is still capped. The app's policy is the only place per-metadata budgets
live (a budget per user or per customer, keyed on an expression).

Each rule chooses a scope (the whole app, or one budget per distinct metadata
value) and carries limit rows of **meter** (cost, tokens, requests) × **period**
(hourly, daily, weekly, monthly) × **limit** × **action** (block or warn). A
warn row and a block row on the same meter and period give warn-then-block.

Over a limit, a request goes to the app's quota fallback model if one is
configured; otherwise it is rejected with **HTTP 429** and a `budget` object
naming what ran out.

## Keys and secrets

- **The vendor's API key belongs to the provider configuration**, stored as a
  project secret. It is never in application code, a request header, or a
  committed file — the point of the gateway is that callers never hold it.
- **An app's key is issued and rotated by Zuplo.** Application code carries only
  that app key, which the gateway trades for provider access.
- Never echo a key value back to a user or write one into a file. Refer to the
  environment variable or the app, not the secret.

## Diagnosing a rejected request

| Symptom | Where to look |
| ------- | ------------- |
| "No provider" / model not available | The provider layer: is a provider connected, and does it enable that model? Check the `providerLabel/` prefix matches a provider's actual label |
| `429` with a `budget` object | Which level ran out — gateway, team, or app. The object names the meter and period; a quota fallback model turns this into a slower answer instead of a failure |
| The model is ignored or substituted | Model Filtering's allow list — its first entry is the default when `model` is omitted |
| `401` / `403` | The app's API key, and whether the authentication policy is in that app's chain |
| A `404` on the request URL | The URL was constructed rather than read from the app. Get it from the app itself |
| Costs attributed to the wrong app | Two callers sharing one app URL — usage is attributed by the app id in the URL, so each caller needs its own app |

## Getting it wrong

| Mistake | Consequence |
| ------- | ----------- |
| Prefixing a model with the vendor instead of the provider's label | The model does not resolve, and the error looks like a missing provider |
| Inventing a model id instead of reading the catalog | Configuration saves, then every request using it fails |
| Constructing an app's request URL from a pattern | A hard 404, or usage billed to another app |
| Putting Budgets and Costs before the Fallback Model | An exceeded budget fails the request instead of falling back |
| Putting Semantic Cache before Budgets and Costs | Cache hits escape the request count |
| Assuming an app with no budget policy is uncapped | Gateway and team limits still apply to it |
| Putting a vendor API key in application code | The secret the gateway exists to hold is now in your repo |
