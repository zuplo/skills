# Zuplo ChatGPT app

The Zuplo ChatGPT app is a tool-only integration backed by remote MCP servers;
it does not require a custom widget. ChatGPT discovers the app's tools from the
submitted MCP server. It does not import the repository's agent skills.

| Capability | MCP endpoint | Authentication |
| --- | --- | --- |
| Search and ask questions about Zuplo documentation | `https://dev.zuplo.com/mcp/docs` | None |
| Work with a user's Zuplo account and projects | `https://dev.zuplo.com/mcp` | OAuth 2.1 |

The repository also packages the same MCP connections together with its agent
skills for Codex. That OpenAI plugin package is described by
[`/.codex-plugin/plugin.json`](./.codex-plugin/plugin.json), with MCP
configuration in [`/.mcp.json`](./.mcp.json). The portable Agent Plugins
manifest remains at [`/plugin.json`](./plugin.json); the formats serve different
clients and intentionally coexist.

## Test in ChatGPT

1. Open ChatGPT **Settings > Security and login** and enable **Developer mode**.
2. Open the ChatGPT Plugins page and select the plus button.
3. Create a connection for `https://dev.zuplo.com/mcp/docs`.
4. Create a separate connection for `https://dev.zuplo.com/mcp` and complete
   the Zuplo sign-in flow.
5. Review the discovered tools and metadata, then test the prompts below in a
   new chat.
6. Refresh each connection after MCP tool or metadata changes.

ChatGPT assigns each registered connection an environment-specific technical
ID. To make this repository installable as a ChatGPT-backed OpenAI plugin,
register the production connection, add its real ID to `.app.json`, and add an
`apps` path to `.codex-plugin/plugin.json` in the same change. This repository
does not contain a placeholder mapping because it would not resolve in another
workspace.

## Test cases

### Positive

1. **Documentation search:** "Find the Zuplo documentation for adding API key
   authentication and summarize the required configuration."
2. **Troubleshooting:** "My Zuplo route is returning a CORS error. What should I
   inspect?"
3. **Project inspection:** "List my Zuplo projects and identify the environment
   used by the first project."
4. **Configuration review:** "Review this project's route and policy
   configuration for authentication gaps."
5. **Explicit action:** "Deploy this project to the preview environment. Ask me
   to confirm before making the change."

### Negative

1. **Missing authentication:** Request account data without signing in; the app
   should explain that authentication is required and must not fabricate data.
2. **Ambiguous mutation:** Ask it to "delete the broken project" without naming
   a project; it should request the missing identifier and confirmation.
3. **Out of scope:** Ask for unrelated personal or financial information; it
   should decline to use Zuplo tools for the request.

## Public submission

Create a **With MCP** submission in the OpenAI Platform plugin portal. Submit
the production MCP URL directly rather than an existing ChatGPT connection ID.
OpenAI currently accepts one production MCP URL per submission. Use
`https://dev.zuplo.com/mcp` for the Zuplo product app. Publish the docs server
separately, or expose its tools through the product server before submission if
one public listing should include both surfaces.

The reproducible reviewer fixture, exact platform tool names, expected
workflows, result shapes, and negative fallbacks are recorded in
[`chatgpt-app-submission.json`](./chatgpt-app-submission.json).

The submission also requires:

- a verified Zuplo business identity and Apps Management write access;
- domain verification for `dev.zuplo.com`;
- public website, support, privacy policy, and terms URLs;
- accurate tool names, descriptions, schemas, and behavioral annotations;
- working reviewer credentials for the authenticated platform server;
- the positive and negative test cases above; and
- a successful **Scan Tools** result for the submitted MCP server.

The public submission and review are managed in OpenAI Platform and are not
created by committing a repository manifest. Before submission, Zuplo must also
publish a privacy policy that explicitly covers the ChatGPT/OpenAI integration,
including account and project data processed through MCP, transmission,
logging/retention, deletion, and support. The current website privacy policy is
linked from the Codex package for identification but is not sufficient evidence
that the app-specific disclosures are complete.

## References

- [Package a plugin](https://developers.openai.com/plugins/build/plugins)
- [Connect and test a plugin](https://developers.openai.com/plugins/deploy/connect-chatgpt)
- [Submit a plugin](https://developers.openai.com/plugins/deploy/submission)
