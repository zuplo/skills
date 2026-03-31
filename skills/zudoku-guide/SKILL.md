---
name: zudoku-guide
description: "Comprehensive Zudoku framework guide. Teaches how to find current documentation, verify API signatures, and build API documentation sites and developer portals. Covers documentation lookup strategies (embedded docs, remote docs), core concepts (configuration, navigation, OpenAPI integration, plugins, authentication, theming), and common patterns. Use this skill for all Zudoku development to ensure you're using current APIs from the installed version or latest documentation."
license: MIT
metadata:
  author: Zuplo
  version: "2.0.0"
  repository: https://github.com/zuplo/skills
---

# Zudoku Framework Guide

Build beautiful API documentation sites and developer portals with Zudoku. This skill teaches you how to find current documentation and configure Zudoku projects.

<important>
The Zudoku framework is an open source project built on top of vite. However, it is also used as the underlying framework for Zuplo's developer portal/documentation product. This means that all the documentation and knowledge about how to use Zudoku is also applicable to building documentation sites with Zuplo. If you are building a documentation site with Zuplo, you can use the same Zudoku configuration and concepts covered in this skill, but you will deploy it using Zuplo's platform instead of hosting it yourself. End users may refer to Zudoku as "developer portal", "API documentation site", or "docs site", but the underlying framework is Zudoku. This skill focuses on teaching you how to use Zudoku effectively, which will directly translate to building powerful documentation sites with Zuplo.
</important>

## Prerequisites

Before writing any Zudoku code, check if the package is installed:

```bash
ls node_modules/zudoku/
```

- **If package exists:** Use embedded docs first (most reliable)
- **If no package:** Install first or use remote docs

## Documentation lookup guide

### Quick Reference

| User Question                          | First Check                                                      | How To                                           |
| -------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------ |
| "Create/install Zudoku project"        | [`references/create-zudoku.md`](references/create-zudoku.md)     | Setup guide with CLI and manual steps            |
| "How do I configure X?"               | [`references/embedded-docs.md`](references/embedded-docs.md)     | Look up in `node_modules/zudoku/`                |
| "How do I use X?" (no packages)        | [`references/remote-docs.md`](references/remote-docs.md)         | Fetch from `https://zudoku.dev/llms.txt`         |
| "I'm getting an error..."             | [`references/common-errors.md`](references/common-errors.md)     | Common errors and solutions                      |
| "Upgrade from v0.x to v0.y"           | [`references/migration-guide.md`](references/migration-guide.md) | Version upgrade workflows                        |

### Priority order for writing code

1. **Embedded docs first** (if package installed)

   Look up current types and config options in `node_modules`. Example:

   ```bash
   grep -r "ZudokuConfig" node_modules/zudoku/dist/
   ```

   - **Why:** Matches your EXACT installed version
   - **Most reliable source of truth**
   - **More information:** [`references/embedded-docs.md`](references/embedded-docs.md)

2. **Source code second** (if package installed)

   If you can't find what you need in the types, look directly at the source code:

   ```bash
   # Check type definitions
   cat node_modules/zudoku/dist/config.d.ts
   ```

   - **Why:** Ultimate source of truth if docs are missing or unclear
   - **More information:** [`references/embedded-docs.md`](references/embedded-docs.md)

3. **Remote docs third** (if package not installed)

   Fetch the latest docs from the Zudoku website:

   ```
   https://zudoku.dev/llms.txt
   ```

   - **Why:** Latest published docs (may be ahead of installed version)
   - **Use when:** Package not installed or exploring new features
   - **More information:** [`references/remote-docs.md`](references/remote-docs.md)

## Core concepts

### Configuration

Zudoku uses a single configuration file (`zudoku.config.ts` or `.tsx`, `.js`, `.mjs`, `.jsx`) that controls structure, metadata, style, plugins, and routing.

```typescript
import type { ZudokuConfig } from "zudoku";

const config: ZudokuConfig = {
  navigation: [
    { type: "category", label: "Documentation", items: ["introduction"] },
    { type: "link", to: "api", label: "API Reference" },
  ],
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

### Key components

- **Navigation**: Top bar and sidebar structure (categories, links, custom pages)
- **APIs**: OpenAPI/Swagger specification integration for interactive API reference
- **Docs**: Markdown/MDX documentation pages with frontmatter
- **Theme**: Full color customization with light/dark mode (ShadCN UI variables)
- **Plugins**: Extensible architecture for search, auth, analytics, and more
- **Authentication**: Support for Auth0, Clerk, Supabase, Azure AD, Firebase, PingFederate

### Content authoring

Zudoku supports GitHub Flavored Markdown and MDX (JSX in Markdown). Features include:

- Frontmatter for page metadata (title, description, sidebar icon)
- Code blocks with syntax highlighting, line numbers, and titles
- Admonitions/callouts (note, tip, caution, danger)
- 28+ built-in UI components (buttons, cards, dialogs, etc.)
- Interactive API playground component
- Mermaid diagrams

### Plugin system

Zudoku is extensible with plugin types:

- **CommonPlugin**: Head elements, MDX components, initialization
- **NavigationPlugin**: Custom routes and sidebar items
- **ApiIdentityPlugin**: API authentication contexts
- **SearchProviderPlugin**: Custom search implementation
- **EventConsumerPlugin**: React to application events

### Deployment

Zudoku supports deployment to:

- Zuplo (native)
- Vercel
- Cloudflare Pages
- GitHub Pages
- Apache/Nginx servers

Build with `npm run build` → outputs to `/dist`.

## Critical requirements

### Node.js version

Zudoku requires **Node.js 22.7.0+** (or **20.19+**).

### Config file security

The config file runs on both client and server at runtime. **Never include secrets directly in `zudoku.config.ts`** — they will be exposed to the client.

## When you see errors

**Common signs of issues:**

- Build failures or Vite errors
- Config type errors
- Missing module errors
- OpenAPI spec parsing errors

**What to do:**

1. Check [`references/common-errors.md`](references/common-errors.md)
2. Verify current API in embedded docs
3. Check the Zudoku config type definitions

## Development workflow

**Always verify before writing code:**

1. **Check package installed**

   ```bash
   ls node_modules/zudoku/
   ```

2. **Look up current API**
   - If installed → Use embedded docs [`references/embedded-docs.md`](references/embedded-docs.md)
   - If not → Use remote docs [`references/remote-docs.md`](references/remote-docs.md)

3. **Write code based on current docs**

4. **Test locally**
   ```bash
   npm run dev  # http://localhost:3000
   ```

## Resources

- **Setup**: [`references/create-zudoku.md`](references/create-zudoku.md)
- **Embedded docs lookup**: [`references/embedded-docs.md`](references/embedded-docs.md) - Start here if package is installed
- **Remote docs lookup**: [`references/remote-docs.md`](references/remote-docs.md)
- **Common errors**: [`references/common-errors.md`](references/common-errors.md)
- **Migrations**: [`references/migration-guide.md`](references/migration-guide.md)
