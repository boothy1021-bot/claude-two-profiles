#!/usr/bin/env bash
# claude-two-profiles — isolated Claude Code profiles you switch with one command.
# macOS / Linux installer (bash/zsh). See README.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates/profile"
MARK_START="# >>> claude-two-profiles >>>"
MARK_END="# <<< claude-two-profiles <<<"

profiles=()
mode="setup"   # setup | uninstall

while [ $# -gt 0 ]; do
  case "$1" in
    --add) shift; [ $# -gt 0 ] || { echo "error: --add needs a name"; exit 1; }; profiles+=("$1");;
    --profiles) shift; [ $# -gt 0 ] || { echo "error: --profiles needs a list"; exit 1; }; IFS=',' read -r -a profiles <<< "$1";;
    --uninstall) mode="uninstall";;
    -h|--help)
      cat <<EOF
claude-two-profiles installer

Usage:
  ./setup.sh                  Create 'personal' and 'work' profiles + install launchers
  ./setup.sh --add NAME       Create one more profile named NAME
  ./setup.sh --profiles a,b   Create the listed profiles
  ./setup.sh --uninstall      Remove the launcher block from your shell rc (profile dirs kept)

After install, switch profiles with:  claude-work | claude-personal | claude-profile <name>
EOF
      exit 0;;
    *) echo "error: unknown option '$1' (try --help)"; exit 1;;
  esac
  shift
done

# ---- the shell block (literal; expansions happen at runtime, not now) ----
read -r -d '' BLOCK <<'EOF' || true
# >>> claude-two-profiles >>>
# Generic launcher: run Claude under an isolated profile at ~/.claude-<name>
claude-profile() {
  if [ -z "${1:-}" ]; then echo "usage: claude-profile <name> [claude args...]"; return 1; fi
  local _name="$1"; shift
  local _dir="$HOME/.claude-$_name"
  if [ ! -d "$_dir" ]; then echo "profile '$_name' not found at $_dir (create it: new-claude-profile $_name)"; return 1; fi
  CLAUDE_CONFIG_DIR="$_dir" claude "$@"
}
# Convenience wrappers
claude-work()     { claude-profile work "$@"; }
claude-personal() { claude-profile personal "$@"; }
# Run Claude with the default (~/.claude) config
claude-default()  { claude "$@"; }
# Scaffold a new profile on the fly: new-claude-profile <name>
new-claude-profile() {
  if [ -z "${1:-}" ]; then echo "usage: new-claude-profile <name>"; return 1; fi
  local _dir="$HOME/.claude-$1"
  if [ -d "$_dir" ]; then echo "profile '$1' already exists at $_dir"; return 0; fi
  mkdir -p "$_dir"
  printf '%s\n' '{' '  "permissions": { "allow": [], "additionalDirectories": [] },' '  "enabledPlugins": {}' '}' > "$_dir/settings.json"
  printf '%s\n' "# $1 profile" '' 'Isolated Claude Code profile. Add profile-specific rules below.' > "$_dir/CLAUDE.md"
  echo "created profile '$1' — launch it with: claude-profile $1"
}
# <<< claude-two-profiles <<<
EOF

# ---- pick the shell rc file ----
rc_file() {
  case "${SHELL##*/}" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    *)    echo "$HOME/.zshrc" ;;
  esac
}

strip_block() {  # remove any existing marked block from a file (portable, no in-place sed)
  local rc="$1"
  [ -f "$rc" ] || return 0
  awk -v s="$MARK_START" -v e="$MARK_END" '
    $0==s {skip=1; next}
    $0==e {skip=0; next}
    skip!=1 {print}
  ' "$rc" > "$rc.ctp.tmp" && mv "$rc.ctp.tmp" "$rc"
}

scaffold_profile() {
  local name="$1"
  local dir="$HOME/.claude-$name"
  if [ -d "$dir" ]; then
    echo "  • profile '$name' exists at $dir — skipping (not overwritten)"
    return 0
  fi
  mkdir -p "$dir"
  cp "$TEMPLATE_DIR/settings.json" "$dir/settings.json"
  sed "s/{{PROFILE_NAME}}/$name/g" "$TEMPLATE_DIR/CLAUDE.md" > "$dir/CLAUDE.md"
  echo "  ✓ created profile '$name' at $dir"
}

RC="$(rc_file)"

if [ "$mode" = "uninstall" ]; then
  echo "Removing claude-two-profiles launchers from $RC ..."
  strip_block "$RC"
  echo "Done. Profile directories (~/.claude-*) were left in place; remove any you don't want with: rm -rf ~/.claude-<name>"
  exit 0
fi

# default presets when none specified
if [ "${#profiles[@]}" -eq 0 ]; then
  profiles=(personal work)
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "error: template dir not found at $TEMPLATE_DIR (run this script from inside the cloned repo)"; exit 1
fi

echo "Scaffolding profiles:"
for p in "${profiles[@]}"; do
  scaffold_profile "$p"
done

echo "Installing launchers into $RC ..."
touch "$RC"
strip_block "$RC"
printf '\n%s\n' "$BLOCK" >> "$RC"
echo "  ✓ launcher block written"

cat <<EOF

Done.

Next:
  1) Restart your terminal, or run:  source "$RC"
  2) Launch a profile:               claude-work   |   claude-personal   |   claude-profile <name>
     (first launch of each profile asks you to sign in to Claude — separate per profile)
  3) Add another profile any time:   new-claude-profile <name>   (then: claude-profile <name>)

Customize a profile (MCP servers, plugins, skills, CLIs): see CUSTOMIZING.md
EOF
