# Remote Docs Reference

How to look up current documentation from https://zudoku.dev when the local package isn't available or you need conceptual guidance.

**Use this when:**

- Zudoku package isn't installed locally
- You need conceptual explanations or guides
- You want the latest documentation (may be ahead of installed version)

## Documentation site structure

Zudoku docs are organized at **https://zudoku.dev**:

- **Docs**: Core documentation covering configuration, customization, and features
- **Guides**: Step-by-step tutorials for specific tasks
- **Components**: Built-in UI component reference
- **Deploy**: Deployment guides for various platforms

## Finding relevant documentation

### Method 1: Use llms.txt (Recommended)

The main llms.txt file provides an agent-friendly overview of all documentation: https://zudoku.dev/llms.txt

This returns a structured markdown document with:

- Documentation organization and hierarchy
- All available topics and sections
- Direct links to relevant documentation
- Agent-optimized content structure

**Use this first** to understand what documentation is available and where to find specific topics.

### Method 2: Direct URL patterns

Documentation follows predictable URL patterns:

- Configuration: `https://zudoku.dev/docs/configuration/{topic}`
- Customization: `https://zudoku.dev/docs/customization/{topic}`
- Components: `https://zudoku.dev/docs/components/{topic}`
- Guides: `https://zudoku.dev/docs/guides/{topic}`
- Markdown: `https://zudoku.dev/docs/markdown/{topic}`
- Deploy: `https://zudoku.dev/docs/deploy/{topic}`

**Examples:**

- `https://zudoku.dev/docs/configuration/overview`
- `https://zudoku.dev/docs/configuration/api-reference`
- `https://zudoku.dev/docs/configuration/authentication`
- `https://zudoku.dev/docs/customization/colors-theme`
- `https://zudoku.dev/docs/deploy/vercel`

## Agent-friendly documentation

**Critical feature**: Add `.md` to any documentation URL to get clean, agent-friendly markdown.

### Standard URL:

```
https://zudoku.dev/docs/configuration/overview
```

### Agent-friendly URL (Markdown):

```
https://zudoku.dev/docs/configuration/overview.md
```

The `.md` version:

- Removes navigation, headers, footers
- Returns pure markdown content
- Optimized for LLM consumption
- Includes all code examples and explanations

## Lookup Workflow

### 1. Check the main documentation index

**Start here** to understand what's available:

```
https://zudoku.dev/llms.txt
```

### 2. Find relevant documentation

**Option A: Use information from llms.txt**
The main llms.txt will guide you to the right section.

**Option B: Construct URL directly**

```
https://zudoku.dev/docs/configuration/{topic}
https://zudoku.dev/docs/guides/{topic}
```

### 3. Fetch agent-friendly version

Add `.md` to the end of any documentation URL:

```
https://zudoku.dev/docs/configuration/api-reference.md
```

### 4. Extract relevant information

The markdown will include:

- Configuration options and types
- Code examples
- Best practices
- Related documentation links

## Common documentation paths

### Configuration

- Overview: `https://zudoku.dev/docs/configuration/overview`
- API Reference: `https://zudoku.dev/docs/configuration/api-reference`
- Navigation: `https://zudoku.dev/docs/configuration/navigation`
- Authentication: `https://zudoku.dev/docs/configuration/authentication`
- Search: `https://zudoku.dev/docs/configuration/search`
- Site: `https://zudoku.dev/docs/configuration/site`

### Customization

- Colors & Theme: `https://zudoku.dev/docs/customization/colors-theme`
- Fonts: `https://zudoku.dev/docs/customization/fonts`

### Content

- Writing docs: `https://zudoku.dev/docs/writing`
- Markdown overview: `https://zudoku.dev/docs/markdown/overview`
- MDX: `https://zudoku.dev/docs/markdown/mdx`
- Code blocks: `https://zudoku.dev/docs/markdown/code-blocks`

### Deployment

- Overview: `https://zudoku.dev/docs/deployment`
- Vercel: `https://zudoku.dev/docs/deploy/vercel`
- Cloudflare Pages: `https://zudoku.dev/docs/deploy/cloudflare-pages`
- GitHub Pages: `https://zudoku.dev/docs/deploy/github-pages`

### Plugins

- Plugins overview: `https://zudoku.dev/docs/plugins`
- Custom plugins: `https://zudoku.dev/docs/custom-plugins`

## Example: Looking up API reference configuration

### 1. Check main documentation index

```
WebFetch({
  url: "https://zudoku.dev/llms.txt",
  prompt: "Where can I find documentation about configuring API references with OpenAPI?"
})
```

### 2. Fetch specific documentation

```
https://zudoku.dev/docs/configuration/api-reference.md
```

### 3. Use WebFetch tool

```
WebFetch({
  url: "https://zudoku.dev/docs/configuration/api-reference.md",
  prompt: "What are the options for configuring OpenAPI specs in Zudoku?"
})
```

## When to use remote vs embedded docs

| Situation                    | Use                                                   |
| ---------------------------- | ----------------------------------------------------- |
| Package installed locally    | **Embedded docs** (guaranteed version match)          |
| Package not installed        | **Remote docs**                                       |
| Need conceptual guides       | **Remote docs**                                       |
| Need exact config types      | **Embedded docs** (if available)                      |
| Exploring new features       | **Remote docs** (may be ahead of installed version)   |
| Need working examples        | **Both** (embedded for types, remote for guides)      |

## Best practices

1. **Always use .md** for fetching documentation
2. **Check llms.txt** when unsure about URL structure
3. **Prefer embedded docs** when the package is installed (version accuracy)
4. **Use remote docs** for conceptual understanding and guides
5. **Combine both** for comprehensive understanding
