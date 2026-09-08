# Zuplo Agent Tools

Official [agent skills](https://agentskills.io) for [Zuplo](https://zuplo.com) and [Zudoku](https://zudoku.dev). These skills help AI coding assistants correctly configure and develop with the Zuplo API gateway and the Zudoku documentation framework.

This repository is also an [Agent Plugins 1.0.0](https://agent-plugins.org/specification) package. Clients that support Agent Plugins discover the skills in `skills/` and the Zuplo Docs and Platform MCP servers in [`mcp.json`](./mcp.json) from the root [`plugin.json`](./plugin.json) manifest.

For Codex, the repository also includes an OpenAI plugin manifest at
[`.codex-plugin/plugin.json`](./.codex-plugin/plugin.json) and MCP configuration
at [`.mcp.json`](./.mcp.json). The same MCP servers power the Zuplo ChatGPT app;
see the [ChatGPT app guide](./CHATGPT_APP.md) for testing, the remaining
registered-connection and privacy prerequisites, and public submission.

## Installation

### Claude Code

Register this repo as a plugin marketplace, then install the skills:

```
/plugin marketplace add zuplo/tools
/plugin install zuplo-skills@zuplo-tools
/plugin install zudoku-skills@zuplo-tools
```

### Cursor

Install via **Cursor Settings > Rules > Add Rule > Remote Rule (GitHub)** and enter this repo URL. Or copy skill directories into your project:

```
.cursor/skills/
├── zuplo-guide/SKILL.md
├── zuplo-cli/SKILL.md
├── zuplo-project-setup/SKILL.md
├── zuplo-graphql/SKILL.md
├── zuplo-monetization/SKILL.md
└── zudoku-guide/SKILL.md
```

Skills in `.cursor/skills/`, `.agents/skills/`, or `~/.cursor/skills/` are auto-discovered.

### GitHub Copilot / VS Code

Copilot reads `AGENTS.md` at the repo root automatically. Clone the skills you need into your project:

```bash
# Copy the AGENTS.md for general project context
curl -o AGENTS.md https://raw.githubusercontent.com/zuplo/tools/main/AGENTS.md
```

Or use the `/create-skill` command in Copilot chat and reference this repo's skills as a starting point.

### Codex (OpenAI)

The OpenAI plugin package combines all included skills with the Zuplo Docs and
Platform MCP servers. Clone this repository for local Codex development. To
test the ChatGPT app, register the MCP endpoints directly in ChatGPT Developer
Mode. See the [ChatGPT app guide](./CHATGPT_APP.md) for the endpoints, test
cases, and submission requirements.

Codex also reads `AGENTS.md` at the repo root. Add the Zuplo `AGENTS.md` to your
project for project-level context.

### Using the `skills` CLI

```bash
npx skills add zuplo/tools
```

Or via [`.well-known` discovery](https://github.com/cloudflare/agent-skills-discovery-rfc):

```bash
npx skills add https://zuplo.com/
npx skills add https://zudoku.dev/
```

### Manual

```bash
git clone https://github.com/zuplo/tools.git
```

Then copy the skill directories you need into your project's skills directory.

## Documentation sources

All Zuplo skills use the following documentation sources in priority order:

### 1. Local docs from `node_modules/zuplo/docs/` (preferred)

The `zuplo` npm package ships with the full Zuplo documentation (642 files, version-matched). Since every Zuplo project has `zuplo` installed, docs are always available locally with no extra setup. Skills instruct agents to read from `node_modules/zuplo/docs/` first.

Key paths:

| Path | Content |
| ---- | ------- |
| `policies/_index.md` | Policy catalog |
| `policies/{id}/doc.md` | Per-policy docs |
| `policies/{id}/schema.json` | Per-policy config schema |
| `handlers/` | Handler docs (url-forward, custom-handler, etc.) |
| `concepts/` | Core concepts (request lifecycle, project structure) |
| `articles/` | Guides (CORS, env vars, auth, deployment, etc.) |
| `articles/monetization/` | Monetization docs |
| `cli/` | CLI reference |
| `dev-portal/` | Developer portal / Zudoku docs |

### 2. Zuplo docs MCP server (optional)

For search and Q&A across all docs, add the Zuplo MCP server.

For **Claude Code**, add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "zuplo-docs": {
      "type": "http",
      "url": "https://dev.zuplo.com/mcp/docs"
    }
  }
}
```

### 3. Fetch docs via URL (fallback)

If local docs aren't available and MCP is not configured, skills fall back to fetching from `https://zuplo.com/docs/`.

## Included skills

### Zuplo

| Skill | Description |
| ----- | ----------- |
| **zuplo-guide** | Comprehensive gateway guide — documentation lookup, request pipeline, route/policy configuration, custom handlers, deployment. Start here for general Zuplo development. |
| **zuplo-monetization** | API monetization — meters, plans, Stripe billing, subscriptions, usage tracking, private plans, tax collection. |
| **zuplo-cli** | CLI reference — local dev, deployment, env vars, tunnels, OpenAPI tools, mTLS, project management. |
| **zuplo-project-setup** | Guided setup for a new or unconfigured gateway — starting point (template, OpenAPI import, or scratch), then API key auth, rate limiting, CORS, and JWT validation in order. |
| **zuplo-graphql** | GraphQL endpoints — the `x-graphql` proxy route plus the Zudoku GraphQL documentation plugin, which must be set up together. |

### Zudoku (Developer Portal)

| Skill | Description |
| ----- | ----------- |
| **zudoku-guide** | Comprehensive Zudoku framework guide — setup, configuration, OpenAPI integration, plugins, auth, theming, troubleshooting, migrations. |

## Contributing

1. Fork the repository
2. Make improvements to `SKILL.md` files
3. Test with actual development workflows
4. Submit a pull request

## Security, privacy, and support

The Claude marketplace entries install static skill instructions only; they do
not automatically connect an MCP server. The portable Agent Plugins package
also advertises the public Zuplo Docs MCP server and the OAuth-protected Zuplo
Platform MCP server for clients that support `mcp.json`.

When a user chooses to connect either server, requests are handled under
Zuplo's [Privacy Policy](https://zuplo.com/legal/privacy-policy) and
[Terms](https://zuplo.com/legal/terms). For product support or to report a
security concern, contact [support@zuplo.com](mailto:support@zuplo.com).

## Resources

- [Zuplo](https://zuplo.com) / [Zuplo Docs](https://zuplo.com/docs)
- [Zudoku](https://zudoku.dev) / [Zudoku Docs](https://zudoku.dev/docs)
- [Agent Skills Spec](https://agentskills.io)
- [Discord](https://discord.zuplo.com)

## License

MIT - See [LICENSE](LICENSE) for details
