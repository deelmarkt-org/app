#!/usr/bin/env bash
# Quick hook setup — run this after pulling new hook changes.
# For full setup, run: bash scripts/setup.sh
#
# Usage: bash scripts/setup_hooks.sh

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

echo "Updating pre-commit + pre-push hooks..."
pre-commit install
pre-commit install --hook-type pre-push
echo -e "${GREEN}✓${NC}  Git hooks updated"

echo "Setting up Claude Code quality hooks..."
mkdir -p .claude
if [[ ! -f .claude/settings.json ]]; then
  cat > .claude/settings.json << 'EOF'
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
EOF
  echo -e "${GREEN}✓${NC}  Claude Code hooks created"
else
  echo -e "${GREEN}✓${NC}  Claude Code hooks already exist"
fi

# Optional: check for deno (needed for Edge Function TS linting)
if command -v deno &>/dev/null; then
  echo -e "${GREEN}✓${NC}  deno found: $(deno --version | head -1)"
else
  echo "  ⚠  deno not installed — Edge Function lint/fmt hooks will be skipped"
  echo "     Install: https://deno.land/#installation"
fi

# Git LFS (needed for screen design PNGs)
if git lfs version &>/dev/null; then
  git lfs install >/dev/null 2>&1
  echo -e "${GREEN}✓${NC}  Git LFS initialized"
  # Pull LFS objects if pointer files detected
  if git lfs ls-files 2>/dev/null | head -1 | grep -q '\*'; then
    echo "  Pulling LFS files (screen design PNGs)..."
    git lfs pull
    echo -e "${GREEN}✓${NC}  LFS files downloaded"
  fi
else
  echo "  ⚠  git-lfs not installed — screen design PNGs will be pointer files"
  echo "     macOS: brew install git-lfs"
  echo "     Windows: winget install GitHub.GitLFS"
fi

echo ""
echo "Done. Quality gates active:"
echo "  Pre-commit: file length, cross-feature imports, l10n, Semantics, setState"
echo "              missing test file, missing screen spec reference"
echo "              Edge Function lint + schema cross-reference (.ts/.sql)"
echo "              deno lint + deno fmt (if deno installed)"
echo "  Pre-push:   duplicate strings, nested ternaries, long methods, coverage"
echo "  Claude Code: inline warnings on file write"
