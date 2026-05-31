# claude-two-profiles

Run **multiple isolated Claude Code profiles** on one machine and switch between them with a single
command. Ships ready-to-go **`work`** and **`personal`** profiles, and lets you spin up as many more
as you like — each with its own MCP servers, plugins, skills, memory, permissions, and login.

![claude-two-profiles demo](assets/demo.gif)

Great for keeping work and personal contexts cleanly separated (different tools, different rules,
even different Claude accounts), or giving each client/project its own sandbox.

## How it works

Claude Code loads its **entire** configuration — MCP servers, plugins, memory, permissions, and its
login — from the directory named in the `CLAUDE_CONFIG_DIR` environment variable. Point it at
different folders and you get fully isolated profiles:

- `~/.claude` — your normal default config (untouched by this kit; plain `claude` still uses it)
- `~/.claude-work` — the **work** profile
- `~/.claude-personal` — the **personal** profile
- `~/.claude-<name>` — any extra profile you create

The installer adds small shell functions so you never have to set the variable by hand.

## Quickstart

```bash
git clone https://github.com/boothy1021-bot/claude-two-profiles.git
cd claude-two-profiles

# macOS / Linux
./setup.sh

# Windows (PowerShell)
./setup.ps1
```

Then restart your terminal (or `source ~/.zshrc` / `. $PROFILE`) and launch a profile:

```bash
claude-work        # uses ~/.claude-work
claude-personal    # uses ~/.claude-personal
claude-profile foo # uses ~/.claude-foo (any profile)
claude-default     # plain ~/.claude
```

The **first launch of each profile** asks you to sign in to Claude — that's expected, since each
profile holds its own login (see FAQ).

## Add more profiles

```bash
new-claude-profile client-a     # scaffold ~/.claude-client-a, then: claude-profile client-a
# or, from the repo:
./setup.sh --add client-a       # macOS/Linux
./setup.ps1 -Add client-a       # Windows
```

## Customize a profile

Each profile is just a folder you can tailor — add MCP servers, plugins, skills, CLIs, and
permission rules **per profile**. See **[CUSTOMIZING.md](CUSTOMIZING.md)**.

## FAQ

**Does this change my existing `~/.claude`?** No. It only creates new `~/.claude-<name>` folders and
adds a few functions to your shell rc. Plain `claude` keeps using your default config.

**Do the profiles share my Claude account?** Not automatically — each profile has its own login
(stored inside its own directory). You can sign every profile into the **same** Claude account
(usage just pools under that subscription), or use different accounts. They don't share a session.

**Does my setup sync to another computer?** No — profiles, plugins, and CLIs are local to each
machine. Clone this repo there and run the installer again to reproduce the structure.

**How do I remove it?**
```bash
./setup.sh --uninstall      # macOS/Linux  (removes the shell functions)
./setup.ps1 -Uninstall      # Windows
```
Profile folders are left in place; delete any you don't want with `rm -rf ~/.claude-<name>`
(or `Remove-Item -Recurse -Force $HOME\.claude-<name>`).

## Notes

- Cross-platform: `setup.sh` (bash/zsh) and `setup.ps1` (PowerShell 5+/7).
- Re-running the installer is safe: it **skips existing profile folders** (never overwrites) and
  refreshes the shell block in place.
- Requires the [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) (`claude`) on your PATH.

## License

MIT — see [LICENSE](LICENSE).
