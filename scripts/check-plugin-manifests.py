#!/usr/bin/env python3

import json
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent.parent


def load(path: str) -> dict:
    with (ROOT / path).open() as file:
        return json.load(file)


portable_plugin = load("plugin.json")
openai_plugin = load(".codex-plugin/plugin.json")
claude_marketplace = load(".claude-plugin/marketplace.json")
portable_mcp = load("mcp.json")["mcpServers"]
openai_mcp = load(".mcp.json")["mcpServers"]
submission = load("chatgpt-app-submission.json")


def require_path(reference: str, label: str) -> Path:
    path = ROOT / reference.removeprefix("./")
    if not path.exists():
        raise SystemExit(f"{label} does not exist: {reference}")
    return path


def require_https(url: str, label: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme != "https" or not parsed.netloc:
        raise SystemExit(f"{label} must be an absolute HTTPS URL: {url}")

versions = {
    "plugin.json": portable_plugin["version"],
    ".codex-plugin/plugin.json": openai_plugin["version"],
    ".claude-plugin/marketplace.json": claude_marketplace["metadata"]["version"],
}
if len(set(versions.values())) != 1:
    raise SystemExit(f"Plugin versions do not match: {versions}")

if openai_plugin.get("skills") != "./skills/":
    raise SystemExit("OpenAI plugin must reference ./skills/")
if openai_plugin.get("mcpServers") != "./.mcp.json":
    raise SystemExit("OpenAI plugin must reference ./.mcp.json")

require_path(openai_plugin["skills"], "OpenAI skills path")
require_path(openai_plugin["mcpServers"], "OpenAI MCP configuration")

required_interface_fields = {
    "displayName",
    "shortDescription",
    "longDescription",
    "developerName",
    "category",
    "capabilities",
    "websiteURL",
    "privacyPolicyURL",
    "termsOfServiceURL",
    "defaultPrompt",
    "brandColor",
    "composerIcon",
    "logo",
    "logoDark",
}
interface = openai_plugin.get("interface", {})
missing_interface_fields = sorted(required_interface_fields - set(interface))
if missing_interface_fields:
    raise SystemExit(
        f"OpenAI plugin interface is missing fields: {missing_interface_fields}"
    )

for field in ("homepage", "repository"):
    require_https(openai_plugin[field], f"OpenAI plugin {field}")
for field in ("websiteURL", "privacyPolicyURL", "termsOfServiceURL"):
    require_https(interface[field], f"OpenAI plugin interface.{field}")
for field in ("composerIcon", "logo", "logoDark"):
    require_path(interface[field], f"OpenAI plugin interface.{field}")

apps_path = openai_plugin.get("apps")
if apps_path:
    app_config = load(apps_path.removeprefix("./"))
    if not app_config.get("apps"):
        raise SystemExit("OpenAI app configuration must contain an apps mapping")
elif (ROOT / ".app.json").exists():
    raise SystemExit(".app.json exists but .codex-plugin/plugin.json has no apps path")

if set(portable_mcp) != set(openai_mcp):
    raise SystemExit("Portable and OpenAI MCP server names do not match")

for name, portable_server in portable_mcp.items():
    openai_server = openai_mcp[name]
    if portable_server.get("url") != openai_server.get("url"):
        raise SystemExit(f"MCP URL mismatch for {name}")
    if portable_server.get("type") != "streamable-http":
        raise SystemExit(f"Portable MCP transport for {name} must be streamable-http")
    if openai_server.get("type") != "http":
        raise SystemExit(f"OpenAI MCP transport for {name} must be http")
    require_https(openai_server["url"], f"OpenAI MCP URL for {name}")

platform_server = openai_mcp.get("zuplo-platform", {})
if platform_server.get("oauth_resource") != platform_server.get("url"):
    raise SystemExit("Zuplo platform oauth_resource must match its MCP URL")

if submission.get("submissionType") != "mcp":
    raise SystemExit("ChatGPT app submission type must be mcp")
if submission.get("productionMcpUrl") != platform_server.get("url"):
    raise SystemExit("ChatGPT production MCP URL must match zuplo-platform")
if not submission.get("fixture", {}).get("setup"):
    raise SystemExit("ChatGPT submission must describe a reviewer fixture")

test_requirements = {
    "positiveTestCases": {
        "id",
        "prompt",
        "expectedTools",
        "expectedWorkflow",
        "expectedResult",
    },
    "negativeTestCases": {
        "id",
        "prompt",
        "expectedFallback",
        "whyItMustNotComplete",
    },
}
for collection, required_fields in test_requirements.items():
    cases = submission.get(collection, [])
    if not cases:
        raise SystemExit(f"ChatGPT submission must include {collection}")
    for index, case in enumerate(cases):
        missing_fields = sorted(required_fields - set(case))
        if missing_fields:
            raise SystemExit(
                f"{collection}[{index}] is missing fields: {missing_fields}"
            )

print("Plugin manifests are consistent.")
