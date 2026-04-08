# Quick hook setup for Windows — run after pulling new hook changes.
# For full setup, run: .\scripts\setup.ps1
#
# Usage: .\scripts\setup_hooks.ps1

$ErrorActionPreference = "Stop"

function Ok($msg) { Write-Host "v  $msg" -ForegroundColor Green }

Write-Host "Updating pre-commit + pre-push hooks..."
pre-commit install
pre-commit install --hook-type pre-push
Ok "Git hooks updated"

Write-Host "Setting up Claude Code quality hooks..."

$claudeDir = ".claude"
$claudeSettings = "$claudeDir\settings.json"

if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

if (-not (Test-Path $claudeSettings)) {
    @'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "dart run scripts/check_single_file.dart $CLAUDE_FILE_PATH"
          }
        ]
      }
    ]
  }
}
'@ | Out-File -Encoding utf8 $claudeSettings
    Ok "Claude Code hooks created"
} else {
    Ok "Claude Code hooks already exist"
}

# Optional: check for deno
if (Get-Command deno -ErrorAction SilentlyContinue) {
    Ok "deno found: $(deno --version | Select-Object -First 1)"
} else {
    Write-Host "  !!  deno not installed - Edge Function lint/fmt hooks will be skipped" -ForegroundColor Yellow
    Write-Host "     Install: https://deno.land/#installation"
}

Write-Host ""
Write-Host "Done. Quality gates active:"
Write-Host "  Pre-commit: file length, cross-feature imports, l10n, Semantics, setState"
Write-Host "              Edge Function lint + schema cross-reference (.ts/.sql)"
Write-Host "              deno lint + deno fmt (if deno installed)"
Write-Host "  Pre-push:   duplicate strings, nested ternaries, long methods, coverage"
Write-Host "  Claude Code: inline warnings on file write"
