# Customizing a profile

Every profile is an isolated Claude Code config directory at `~/.claude-<name>`. Anything you'd
normally configure for Claude Code, you configure **per profile** here.

> **Golden rule:** launch the target profile first (so `CLAUDE_CONFIG_DIR` is set), *then* run the
> commands below. For example, start `claude-work` and run the `/...` commands inside it, or run the
> `claude mcp ...` shell commands in a terminal where that profile is active.

The quickest way to scope a shell command to a profile without a launcher:

```bash
# macOS / Linux
CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude mcp list
```
```powershell
# Windows
$env:CLAUDE_CONFIG_DIR = "$HOME\.claude-work"; claude mcp list
```

## MCP servers

Added MCP servers are written into the **active profile's** config, so each profile can have a
different set.

```bash
# stdio server (a local command)
claude mcp add <name> -- <command> [args...]

# remote HTTP/SSE server
claude mcp add --transport http <name> <url>

claude mcp list            # see this profile's servers
claude mcp remove <name>   # remove one
```

Example (a filesystem server via npx):
```bash
claude mcp add files -- npx -y @modelcontextprotocol/server-filesystem "$HOME/projects"
```

## Plugins & skills (from a marketplace)

Inside the running profile:

```
/plugin marketplace add <owner/repo>      # e.g. an org's plugin repo
/plugin install <plugin-name>@<marketplace>
/plugin                                   # browse / manage interactively
```

Or edit the profile's `~/.claude-<name>/settings.json` directly:

```json
{
  "extraKnownMarketplaces": {
    "my-marketplace": { "source": { "source": "github", "repo": "owner/repo" } }
  },
  "enabledPlugins": {
    "some-plugin@my-marketplace": true
  }
}
```

## Custom skills (your own)

Drop a skill folder straight into the profile — no marketplace needed:

```
~/.claude-<name>/skills/<skill-name>/SKILL.md
```

Claude picks it up for that profile only. Put the skill's frontmatter (`name`, `description`) at the
top of `SKILL.md` as usual.

## CLIs and external tools

CLIs are installed at the OS level (not per profile), but you control **how Claude uses them** per
profile:

1. Install the CLI normally (`brew install ...`, `winget install ...`, `npm i -g ...`, etc.).
2. Mention it in the profile's `CLAUDE.md` so Claude reaches for it (e.g. "use `gh` for GitHub work").
3. Optionally allowlist its read-only commands in `settings.json` to cut permission prompts:

```json
{
  "permissions": {
    "allow": ["Bash(gh repo view*)", "Bash(gh pr list*)"]
  }
}
```

Avoid wildcarding whole interpreters (`Bash(python *)`) or mutating commands — keep allow-rules tight.

## Permissions & memory

- **Permissions:** edit `permissions.allow` in the profile's `settings.json`.
- **Memory:** each profile keeps its own memory store inside its directory — notes and learnings in
  one profile never leak into another.

## Profile-specific rules

Put behavioral rules for a profile in its `~/.claude-<name>/CLAUDE.md` (the template seeds a
"Customize me" section). Example: a work profile might say "never push directly to `main`", while a
personal profile has no such rule.
