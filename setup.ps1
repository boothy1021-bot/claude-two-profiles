<#
  claude-two-profiles — isolated Claude Code profiles you switch with one command.
  Windows (PowerShell 5+/7) installer. See README.md.

  Usage:
    ./setup.ps1                      Create 'personal' and 'work' profiles + install launchers
    ./setup.ps1 -Add client-a        Create one more profile
    ./setup.ps1 -Profiles a,b,c      Create the listed profiles
    ./setup.ps1 -Uninstall           Remove the launcher block from your PowerShell profile

  After install (new shell), switch with:  claude-work | claude-personal | claude-profile <name>
#>
param(
  [string[]]$Add,
  [string[]]$Profiles,
  [switch]$Uninstall,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'
$TemplateDir = Join-Path $PSScriptRoot 'templates\profile'
$MarkStart = '# >>> claude-two-profiles >>>'
$MarkEnd   = '# <<< claude-two-profiles <<<'

# Literal block (single-quoted here-string => no expansion at install time)
$Block = @'
# >>> claude-two-profiles >>>
# Generic launcher: run Claude under an isolated profile at ~/.claude-<name>
function claude-profile {
  param([Parameter(Mandatory)][string]$Name, [Parameter(ValueFromRemainingArguments=$true)]$Rest)
  $dir = Join-Path $HOME ".claude-$Name"
  if (-not (Test-Path $dir)) { Write-Host "profile '$Name' not found at $dir (create it: new-claude-profile $Name)"; return }
  $old = $env:CLAUDE_CONFIG_DIR
  $env:CLAUDE_CONFIG_DIR = $dir
  try { claude @Rest } finally { $env:CLAUDE_CONFIG_DIR = $old }
}
function claude-work     { claude-profile work @args }
function claude-personal { claude-profile personal @args }
function claude-default {
  $old = $env:CLAUDE_CONFIG_DIR; $env:CLAUDE_CONFIG_DIR = $null
  try { claude @args } finally { $env:CLAUDE_CONFIG_DIR = $old }
}
function new-claude-profile {
  param([Parameter(Mandatory)][string]$Name)
  $dir = Join-Path $HOME ".claude-$Name"
  if (Test-Path $dir) { Write-Host "profile '$Name' already exists at $dir"; return }
  New-Item -ItemType Directory -Force $dir | Out-Null
  "{`n  ""permissions"": { ""allow"": [], ""additionalDirectories"": [] },`n  ""enabledPlugins"": {}`n}" | Set-Content -Encoding utf8 (Join-Path $dir 'settings.json')
  "# $Name profile`n`nIsolated Claude Code profile. Add profile-specific rules below." | Set-Content -Encoding utf8 (Join-Path $dir 'CLAUDE.md')
  Write-Host "created profile '$Name' - launch it with: claude-profile $Name"
}
# <<< claude-two-profiles <<<
'@

function Strip-Block($path) {
  if (-not (Test-Path $path)) { return }
  $lines = Get-Content -LiteralPath $path
  $out = New-Object System.Collections.Generic.List[string]
  $skip = $false
  foreach ($l in $lines) {
    if ($l -eq $MarkStart) { $skip = $true; continue }
    if ($l -eq $MarkEnd)   { $skip = $false; continue }
    if (-not $skip) { $out.Add($l) }
  }
  Set-Content -LiteralPath $path -Value $out -Encoding utf8
}

function Scaffold-Profile($name) {
  $dir = Join-Path $HOME ".claude-$name"
  if (Test-Path $dir) { Write-Host "  - profile '$name' exists at $dir - skipping (not overwritten)"; return }
  New-Item -ItemType Directory -Force $dir | Out-Null
  Copy-Item (Join-Path $TemplateDir 'settings.json') (Join-Path $dir 'settings.json')
  (Get-Content -Raw (Join-Path $TemplateDir 'CLAUDE.md')) -replace '\{\{PROFILE_NAME\}\}', $name |
    Set-Content -Encoding utf8 (Join-Path $dir 'CLAUDE.md')
  Write-Host "  + created profile '$name' at $dir"
}

if ($Help) {
  Get-Help $PSCommandPath -Detailed 2>$null
  Write-Host "Usage: ./setup.ps1 [-Add NAME] [-Profiles a,b,c] [-Uninstall]"
  return
}

if ($Uninstall) {
  Write-Host "Removing claude-two-profiles launchers from $PROFILE ..."
  Strip-Block $PROFILE
  Write-Host "Done. Profile directories (~/.claude-*) were left in place; remove any you don't want with: Remove-Item -Recurse -Force `$HOME\.claude-<name>"
  return
}

# choose profiles
$list = @()
if ($Add)      { $list = $Add }
elseif ($Profiles) { $list = $Profiles }
else           { $list = @('personal','work') }

if (-not (Test-Path $TemplateDir)) {
  throw "template dir not found at $TemplateDir (run this script from inside the cloned repo)"
}

Write-Host "Scaffolding profiles:"
foreach ($p in $list) { Scaffold-Profile $p }

Write-Host "Installing launchers into $PROFILE ..."
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force $profileDir | Out-Null }
if (-not (Test-Path $PROFILE))    { New-Item -ItemType File -Force $PROFILE | Out-Null }
Strip-Block $PROFILE
Add-Content -LiteralPath $PROFILE -Value "`n$Block" -Encoding utf8
Write-Host "  + launcher block written"

Write-Host ""
Write-Host "Done."
Write-Host ""
Write-Host "Next:"
Write-Host "  1) Restart PowerShell, or run:  . `$PROFILE"
Write-Host "  2) Launch a profile:            claude-work | claude-personal | claude-profile <name>"
Write-Host "     (first launch of each profile asks you to sign in to Claude - separate per profile)"
Write-Host "  3) Add another profile anytime: new-claude-profile <name>   (then: claude-profile <name>)"
Write-Host ""
Write-Host "Customize a profile (MCP servers, plugins, skills, CLIs): see CUSTOMIZING.md"
