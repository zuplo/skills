# AGENTS.md

This file provides context for AI coding assistants (Cursor, GitHub Copilot, Claude Code, etc.) working with the Zuplo Agent Skills repository.

## Project Overview

The **Zuplo Agent Skills** repository provides official agent skills for coding agents working with [Zuplo](https://zuplo.com) products. These skills enable AI assistants to correctly configure and develop with the Zuplo API gateway and the Zudoku documentation framework.

- **Repository**: https://github.com/zuplo/skills
- **Zuplo**: https://zuplo.com
- **Zuplo Documentation**: https://zuplo.com/docs
- **Zudoku Framework**: https://github.com/zuplo/zudoku
- **Zudoku Documentation**: https://zudoku.dev/docs
- **License**: MIT

## Repository Structure

| Directory                    | Description                                                    |
| ---------------------------- | -------------------------------------------------------------- |
| `skills/`                    | Agent skill definitions                                        |
| `skills/zudoku-guide/`       | Single comprehensive Zudoku skill with progressive disclosure  |
| `skills/zuplo-guide/`        | Comprehensive Zuplo API gateway skill with docs and policies   |
| `skills/zuplo-project-setup/`| New project setup guide with step-by-step workflows            |
| `skills/zuplo-monetization/` | API monetization setup, billing, Stripe integration            |
| `skills/zuplo-policies/`     | Policy management guide with complete built-in catalog         |
| `skills/zuplo-handlers/`     | Request handler configuration and custom handler guide         |
| `skills/zuplo-cli/`          | Zuplo CLI command reference and usage guide                    |

## Specification

Fetch the up-to-date [Agent Skills Specification](https://agentskills.io/specification.md) for details on skill structure, frontmatter fields, and best practices.

## Development Guidelines

### Adding New Skills

1. Create directory in `skills/`
2. Add `SKILL.md` with proper frontmatter
3. Include production-ready code patterns
4. Add reference documentation in `references/` if needed
5. Test patterns against current documentation
6. Update root `README.md`

### Updating Existing Skills

1. **Validate against current docs**: Always verify patterns against the latest official documentation
2. **Test patterns**: Ensure all code examples are runnable
3. **Update references**: Keep reference files current with product changes
4. **No marketing language**: Technical documentation only

### Code Pattern Requirements

- **Completeness**: Patterns should be copy-paste ready
- **TODO placeholders**: Use `// TODO:` for user customization points
- **Imports**: Include all necessary import statements
- **Comments**: Explain non-obvious concepts, not syntax
