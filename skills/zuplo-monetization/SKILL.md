---
name: zuplo-monetization
description: "Complete guide to Zuplo's API monetization product. Covers setup of meters, features, plans, Stripe integration, the monetization policy, developer portal monetization plugin, subscription lifecycle, private plans, tax collection, billing models, and troubleshooting. Use when a developer wants to monetize their API, set up billing, configure usage-based pricing, manage subscriptions, or integrate Stripe with Zuplo."
license: MIT
metadata:
  author: Zuplo
  version: "1.0.0"
  repository: https://github.com/zuplo/skills
---

# Zuplo API Monetization Guide

Set up usage-based billing and subscription management for your API using Zuplo's built-in monetization product with Stripe integration.

## Critical rule: Read docs before configuring

Before configuring monetization features, read the relevant Zuplo documentation. The monetization product is in beta and evolving. Use these sources in priority order:

1. **Local docs (preferred):** Read from `node_modules/zuplo/docs/articles/monetization/` — version-matched, always available offline. Check both the project root and parent directories for monorepos.
2. **MCP server tools:** Use `search-zuplo-docs` and `ask-question-about-zuplo` if the Zuplo MCP server is connected.
3. **Fetch docs via URL.** Key doc pages:
- Quickstart: `https://zuplo.com/docs/articles/monetization/quickstart`
- Stripe integration: `https://zuplo.com/docs/articles/monetization/stripe-integration`
- Developer portal: `https://zuplo.com/docs/articles/monetization/developer-portal`
- Subscription lifecycle: `https://zuplo.com/docs/articles/monetization/subscription-lifecycle`
- Billing models: `https://zuplo.com/docs/articles/monetization/billing-models`
- Plan examples: `https://zuplo.com/docs/articles/monetization/plan-examples`
- Monetization policy: `https://zuplo.com/docs/policies/monetization-inbound`

## How monetization works

Zuplo handles metering, quota enforcement, and subscription state. Stripe handles payment processing, billing, and invoicing.

```
Developer Portal                    Zuplo Gateway                    Stripe
┌─────────────────┐                ┌──────────────┐                ┌─────────┐
│ Pricing page    │──Subscribe──>  │ Creates sub  │──Creates───>   │ Checkout│
│ Usage dashboard │                │ Issues API   │  subscription  │ Payment │
│ Key management  │<──Redirect──  │ key + quota  │<──Confirms──   │ Billing │
│ Plan changes    │                │ Meters usage │──Reports───>   │ Invoice │
└─────────────────┘                └──────────────┘                └─────────┘
```

The flow:
1. You define **meters**, **features**, and **plans** in Zuplo
2. You connect your **Stripe account** via the Zuplo Portal
3. **Publishing plans** creates corresponding Stripe Products and Prices
4. Customers **subscribe** through the Developer Portal via Stripe Checkout
5. Zuplo creates a **subscription with an API key** scoped to plan entitlements
6. The **MonetizationInboundPolicy** meters usage in real time and enforces quotas
7. For usage-based billing, usage is billed through Stripe at end of period

## Setup overview

| Step | What | Details |
| ---- | ---- | ------- |
| 1 | Create project | Use the Zuplo Portal or CLI |
| 2 | Enable monetization plugin | Add to `docs/zudoku.config.tsx` |
| 3 | Configure Monetization Service | Portal > Services > Monetization Service |
| 4 | Create meters | Define what to measure (API calls, tokens, etc.) |
| 5 | Create features | Link features to meters or define boolean features |
| 6 | Create and publish plans | Set pricing, tiers, entitlements |
| 7 | Connect Stripe | Add Stripe API key in Monetization Service |
| 8 | Add monetization policy | Add to `config/policies.json` and attach to routes |
| 9 | Deploy and test | Push changes, subscribe, make API calls |

## Step 1: Create a project

Use a fresh project for monetization setup.

1. Go to [portal.zuplo.com](https://portal.zuplo.com) and create a **New Project**
2. Select **API Management (+ MCP Server)**
3. Select **Starter Project (Recommended)** — it comes with endpoints ready to monetize

Or via CLI:

```bash
npx create-zuplo-api@latest my-monetized-api
```

## Step 2: Enable the monetization plugin

In `docs/zudoku.config.tsx`, add the monetization plugin:

```tsx
import { zuploMonetizationPlugin } from "@zuplo/zudoku-plugin-monetization";

const config: ZudokuConfig = {
  // ... your existing config
  plugins: [
    zuploMonetizationPlugin(),
    // ... any other plugins you have
  ],
};
```

Save and wait for deployment to complete.

## Step 3: Configure the Monetization Service

1. Navigate to the **Services** tab in your project
2. Select the environment (e.g., **Working Copy**)
3. Click **Configure** on the **Monetization Service** card

## Step 4: Create meters

Meters track what you want to measure (API calls, tokens, data transfer, etc.).

In Monetization Service > **Meters** > **Add Meter** > **Blank Meter**:

| Field | Example value | Description |
| ----- | ------------- | ----------- |
| Name | `API` | Display name |
| Event | `api` | Event type identifier (used in policy config) |
| Description | `API Calls` | Human-readable description |
| Aggregation | `SUM` | How to combine values (`SUM`, `COUNT`, `MAX`, etc.) |
| Value Property | `$.total` | JSONPath to extract value from events |

## Step 5: Create features

Features define customer entitlements. In Monetization Service > **Features** > **Add Feature**:

**Usage-based feature** (linked to a meter):
- Name: `api`, Key: `api`, Linked Meter: `API`

**Flat fee feature** (no meter):
- Name: `Monthly Fee`, Key: `monthly_fee`, Linked Meter: (empty)

**Boolean feature** (on/off capability):
- Name: `Metadata Support`, Key: `metadata_support`, Linked Meter: (empty)

## Step 6: Create and publish plans

Plans combine features with pricing and entitlements. In **Plans** > **Create Plan**.

### Example plan structure

| Plan | Monthly Fee | Included Requests | Overage Rate | Metadata Support |
| ---- | ----------- | ----------------- | ------------ | ---------------- |
| Developer | $9.99 | 1,000 | $0.10/req | No |
| Pro | $19.99 | 5,000 | $0.05/req | Yes |
| Business | $29.99 | 10,000 | $0.01/req | Yes |

### Rate card configuration for a plan

Each plan has rate cards for each feature:

**Monthly Fee rate card:**
- Pricing Model: `Flat fee`
- Billing Cadence: `Monthly`
- Payment Term: `In advance`
- Price: (e.g. `$9.99`)
- Entitlement: `No entitlement`

**API usage rate card (tiered with overage):**
- Pricing Model: `Tiered`
- Billing Cadence: `Monthly`
- Price Mode: `Graduated`
- Tier 1: First `0` to Last `1000`, Unit Price `$0`, Flat Price `$0`
- Tier 2: First `1001` to infinity, Unit Price `$0.10`, Flat Price `$0`
- Entitlement: `Metered (track usage)`
- Usage Limit: `1000`
- Soft limit: `enabled` (allows overage; disable for hard cap)

**Boolean feature rate card:**
- Pricing Model: `Free`
- Entitlement: `Boolean (on/off)`

### Reorder and publish

- Drag-and-drop plans to control pricing page display order
- Each plan must be published: **... menu > Publish Plan**

For more plan examples (trials, credits, pay-as-you-go): read `node_modules/zuplo/docs/articles/monetization/billing-models.md` and `plan-examples.mdx`

## Step 7: Connect Stripe

1. In [Stripe Dashboard](https://dashboard.stripe.com), ensure **sandbox mode** is active
2. Go to **Developers > API keys**, copy your **Secret key** (`sk_test_...`)
3. In Monetization Service > **Payment Provider** > **Configure** Stripe
4. Enter a Name and paste the Stripe API Key, click **Save**

Always use `sk_test_...` for development. Switch to `sk_live_...` for production.

When you publish plans, Zuplo automatically creates corresponding Stripe Products and Prices.

## Step 8: Add the monetization policy

### Define the policy in `config/policies.json`

```json
{
  "name": "monetization-inbound",
  "policyType": "monetization-inbound",
  "handler": {
    "export": "MonetizationInboundPolicy",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "meters": {
        "api": 1
      }
    }
  }
}
```

The `meters` object maps meter event slugs to units per request. `"api": 1` means each request increments the `api` meter by 1.

### Apply to routes in `config/routes.oas.json`

```json
"x-zuplo-route": {
  "corsPolicy": "none",
  "handler": {
    "export": "urlForwardHandler",
    "module": "$import(@zuplo/runtime)",
    "options": {
      "baseUrl": "https://your-backend.example.com"
    }
  },
  "policies": {
    "inbound": ["monetization-inbound"]
  }
}
```

**Important:** The `MonetizationInboundPolicy` handles API key authentication automatically on monetized routes. You do NOT need a separate `api-key-inbound` policy on routes that have the monetization policy.

### Policy options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `meters` | `object` | `{}` | Maps meter slugs to units per request |
| `meterOnStatusCodes` | `string` | all | Status code ranges to meter (e.g. `"200-299"`) |
| `authHeader` | `string` | `"authorization"` | Header containing the API key |
| `authScheme` | `string` | `"Bearer"` | Auth scheme prefix |
| `cacheTtlSeconds` | `number` | `60` | Cache TTL for monetization lookups |

For advanced metering (dynamic meters at runtime): read `node_modules/zuplo/docs/articles/monetization/monetization-policy.md`

## Step 9: Deploy and test

1. Commit and push your changes to trigger deployment
2. Navigate to your Developer Portal > **Pricing** tab
3. Subscribe to a plan using Stripe test card `4242 4242 4242 4242`
4. Copy the API key from your subscription
5. Make API calls:

```bash
curl --request GET \
  --url https://<your-gateway-url>/todos \
  --header 'Authorization: Bearer <your-api-key>'
```

6. Check the usage dashboard in the Developer Portal — the meter should update

### What to verify

- Requests succeed within quota
- `403 Forbidden` when quota exceeded (hard limit plans)
- Overage allowed (soft limit plans) with usage tracked
- Usage visible in Developer Portal dashboard
- Stripe dashboard shows the subscription and usage

## Subscription lifecycle

| State | API Access | Description |
| ----- | ---------- | ----------- |
| `active` | Yes | Subscription active, payment current |
| `inactive` | No | Not yet active or deactivated |
| `canceled` | No | Subscription canceled |
| `scheduled` | No | Scheduled for future activation |

### Key behaviors

- **Plan changes (upgrades/downgrades):** Charges are prorated automatically. Upgrades take effect immediately; downgrades at next billing cycle. API key stays the same.
- **Cancellation:** By default, access continues until end of billing period, then revoked. API key stops working.
- **Payment failures:** Default 3-day grace period. Access blocked after grace period if payment remains overdue. Configurable via `zuplo_max_payment_overdue_days` plan metadata.
- **Reactivation:** Canceled subscriptions can be restored via API.

### Programmatic subscription management

Subscriptions can also be managed via the Metering API. See `node_modules/zuplo/docs/articles/monetization/subscription-lifecycle.md`.

## Developer portal features

Once monetization is enabled, the portal provides:

- **Pricing page** — Plan comparison with subscribe buttons
- **Subscription management** — View active/past subscriptions, upgrade, downgrade, cancel
- **Usage dashboard** — Real-time quota consumption per metered feature
- **API key management** — View, regenerate keys per subscription
- **Stripe billing portal** — Manage payment methods and invoices

## Advanced topics

All of these are in `node_modules/zuplo/docs/articles/monetization/`:

| Topic | Doc file |
| ----- | -------- |
| Dynamic metering at runtime | `monetization-policy.md` |
| Billing models (flat rate, tiered, pay-as-you-go) | `billing-models.md` |
| Plan examples (trials, multiple tiers) | `plan-examples.mdx` |
| Private (invite-only) plans | `private-plans.md` |
| Tax collection with Stripe Tax | `tax-collection.md` |
| Subscription lifecycle and API | `subscription-lifecycle.md` |
| Troubleshooting | `troubleshooting.md` |

## Troubleshooting

| Problem | Cause | Fix |
| ------- | ----- | --- |
| Pricing page not showing | Plugin not added or not deployed | Add `zuploMonetizationPlugin()` to `zudoku.config.tsx` and redeploy |
| Plans not visible on pricing page | Plans not published | Publish each plan via **... > Publish Plan** |
| API returns 401 on monetized route | No API key or invalid key | Get key from Developer Portal subscription |
| API returns 403 on monetized route | Quota exceeded (hard limit) | Upgrade plan or wait for quota reset |
| Usage not tracking | Meter slug mismatch | Ensure `meters` key in policy matches the meter event slug exactly |
| Stripe not connected | API key not configured | Configure Stripe in Monetization Service > Payment Provider |
| Subscription not created after checkout | Deployment not complete | Ensure latest code is deployed before testing |

## Resources

- **Local docs:** `node_modules/zuplo/docs/articles/monetization/` — full monetization documentation
- **Monetization docs (web):** `https://zuplo.com/docs/articles/monetization`
- **Setup script:** The [`setup-monetization.sh`](https://github.com/zuplo-samples/monetization-preview/blob/main/scripts/setup-monetization.sh) script automates meter, feature, plan creation, and Stripe connection via the API
