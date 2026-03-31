# Zuplo Agent Skills

Official [agent skills](https://agentskills.io) for [Zuplo](https://zuplo.com) and [Zudoku](https://zudoku.dev). These skills help AI coding assistants correctly configure and develop with the Zuplo API gateway and the Zudoku documentation framework.

## Installation

Install from GitHub:

```bash
npx skills add zuplo/skills
```

Or via [`.well-known` discovery](https://github.com/cloudflare/agent-skills-discovery-rfc):

```bash
npx skills add https://zuplo.com/
npx skills add https://zudoku.dev/
```

Or clone manually:

```bash
git clone https://github.com/zuplo/skills.git
```

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
      "url": "https://mcp.inkeep.com/zuplo/mcp"
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
| **zuplo-project-setup** | Step-by-step new project setup — scaffolding, routes, auth, rate limiting, CORS, env vars, backend security, dev portal, deployment. |
| **zuplo-policies** | Policy configuration — built-in policy catalog, custom code policies, wiring policies to routes. |
| **zuplo-handlers** | Request handlers — URL forwarding/rewriting, redirects, custom TypeScript handlers, Lambda, WebSockets, MCP servers. |
| **zuplo-monetization** | API monetization — meters, plans, Stripe billing, subscriptions, usage tracking, private plans, tax collection. |
| **zuplo-cli** | CLI reference — local dev, deployment, env vars, tunnels, OpenAPI tools, mTLS, project management. |

### Zudoku (Developer Portal)

| Skill | Description |
| ----- | ----------- |
| **zudoku-guide** | Comprehensive Zudoku framework guide — setup, configuration, OpenAPI integration, plugins, auth, theming, troubleshooting, migrations. |

## Contributing

1. Fork the repository
2. Make improvements to `SKILL.md` files
3. Test with actual development workflows
4. Submit a pull request

## Resources

- [Zuplo](https://zuplo.com) / [Zuplo Docs](https://zuplo.com/docs)
- [Zudoku](https://zudoku.dev) / [Zudoku Docs](https://zudoku.dev/docs)
- [Agent Skills Spec](https://agentskills.io)
- [Discord](https://discord.zuplo.com)

## License

MIT - See [LICENSE](LICENSE) for details
