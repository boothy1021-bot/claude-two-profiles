# {{PROFILE_NAME}} profile

This is an **isolated Claude Code profile**. It has its own MCP servers, plugins, skills, memory,
permissions, and login — completely separate from your default `~/.claude` and from any other
profile. It's loaded when `CLAUDE_CONFIG_DIR` points at this directory (the `claude-{{PROFILE_NAME}}`
launcher does that for you).

## Customize me

Put rules and context that should apply **only to this profile** below. Examples:

- Coding conventions, tone, or workflow rules specific to this context.
- "Always do X here" / "Never do Y here" guardrails.
- Pointers to the CLIs and services this profile uses, so Claude reaches for them.

Wiring tools (MCP servers, plugins, skills, CLIs, permissions) is covered in **CUSTOMIZING.md** in
the starter-kit repo. Quick reminders — run these while this profile is active:

- Add an MCP server: `claude mcp add <name> -- <command> [args]`
- Add a plugin marketplace + plugin: `/plugin marketplace add <owner/repo>` then `/plugin install <name>@<marketplace>`
- Add a custom skill: create `skills/<skill-name>/SKILL.md` inside this profile directory.

<!-- Add your profile-specific rules below this line. -->
