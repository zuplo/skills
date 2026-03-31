# Create Zudoku Reference

Complete guide for creating new Zudoku projects. Includes both quickstart CLI method and detailed manual installation.

**Official documentation: [zudoku.dev/docs](https://zudoku.dev/docs)**

## Get started

Ask: **"How would you like to create your Zudoku project?"**

1. **Quick Setup**: Copy and run: `npm create zudoku@latest`
2. **Guided Setup**: I walk you through each step, you approve commands
3. **Automatic Setup**: I create everything for you

> **For AI agents:** The CLI is interactive. Use **Automatic Setup** to create files using the steps in "Automatic Setup / Manual Installation" below.

## Prerequisites

- **Node.js** `22.7.0+` (or `20.19+`)
- A terminal or command prompt
- An OpenAPI specification file (optional, can be added later)

## Quick Setup (user runs CLI)

Create a new Zudoku project with one command:

```bash
npm create zudoku@latest
```

**Other package managers:**

```bash
pnpm create zudoku@latest
yarn create zudoku@latest
bun create zudoku@latest
```

The CLI will walk you through setting up your project with interactive prompts. Choose from templates like API documentation, developer portals, or start from scratch.

## Automatic setup / manual installation

**Use this for automatic setup** (AI creates all files) or when you prefer manual control.

Follow these steps to create a complete Zudoku project:

### Step 1: Create project directory

```bash
mkdir my-docs && cd my-docs
npm init -y
```

### Step 2: Install dependencies

```bash
npm install zudoku
```

### Step 3: Configure package scripts

Add to `package.json`:

```json
{
  "scripts": {
    "dev": "zudoku dev",
    "build": "zudoku build"
  }
}
```

### Step 4: Create Zudoku configuration

Create `zudoku.config.ts`:

```typescript
import type { ZudokuConfig } from "zudoku";

const config: ZudokuConfig = {
  navigation: [
    {
      type: "category",
      label: "Documentation",
      items: ["introduction"],
    },
    { type: "link", to: "api", label: "API Reference" },
  ],
  redirects: [{ from: "/", to: "/docs/introduction" }],
  apis: {
    type: "file",
    input: "./apis/openapi.yaml",
    path: "/api",
  },
  docs: {
    files: "/pages/**/*.{md,mdx}",
  },
};

export default config;
```

### Step 5: Create documentation pages

Create `pages/introduction.md`:

```markdown
---
title: Introduction
description: Welcome to our API documentation.
---

# Welcome

This is the introduction to our API documentation.
```

### Step 6: Add an OpenAPI specification (optional)

Create `apis/openapi.yaml` with your API spec, or use a URL instead:

```typescript
// In zudoku.config.ts
apis: {
  type: "url",
  input: "https://your-api.example.com/openapi.json",
  path: "/api",
},
```

### Step 7: Launch the development server

```bash
npm run dev
```

Your Zudoku site is now running at `http://localhost:3000` with hot reloading.

## Next steps

After creating your project:

- **Customize your theme** — see [Colors & Theme](https://zudoku.dev/docs/customization/colors-theme)
- **Add OpenAPI specs** — see [API Reference config](https://zudoku.dev/docs/configuration/api-reference)
- **Set up authentication** — see [Authentication](https://zudoku.dev/docs/configuration/authentication)
- **Configure navigation** — see [Navigation](https://zudoku.dev/docs/configuration/navigation)
- **Add plugins** — see [Plugins](https://zudoku.dev/docs/plugins)
- **Deploy your site** — see [Deployment](https://zudoku.dev/docs/deployment)

## Troubleshooting

| Issue                | Solution                                                      |
| -------------------- | ------------------------------------------------------------- |
| Module not found     | Ensure `zudoku` is installed: `npm install zudoku`            |
| Dev server won't start | Check that port 3000 is available, or set `port` in config  |
| Config type errors   | Ensure you're importing `ZudokuConfig` from `"zudoku"`        |
| Node version error   | Use Node.js 22.7.0+ or 20.19+                                |

## Resources

- [Docs](https://zudoku.dev/docs)
- [Quickstart](https://zudoku.dev/docs/quickstart)
- [Configuration](https://zudoku.dev/docs/configuration/overview)
- [GitHub](https://github.com/zuplo/zudoku)
- [Examples](https://github.com/zuplo/zudoku/tree/main/examples)
