#!/usr/bin/env bash
# DeelMarkt — Development Environment Setup (macOS / Linux)
# Usage: bash scripts/setup.sh

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info() {
  local msg="$1"
  echo -e "${CYAN}ℹ${NC}  ${msg}"
  return 0
}

ok() {
  local msg="$1"
  echo -e "${GREEN}✓${NC}  ${msg}"
  return 0
}

warn() {
  local msg="$1"
  echo -e "${YELLOW}⚠${NC}  ${msg}"
  return 0
}

fail() {
  local msg="$1"
  echo -e "${RED}✗${NC}  ${msg}"
  exit 1
}

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  DeelMarkt — Development Environment Setup${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ── 1. Check prerequisites ──────────────────────────────────────────────────
info "Checking prerequisites..."

check_cmd() {
  local cmd="$1"
  if command -v "${cmd}" &> /dev/null; then
    local cmd_path
    cmd_path="$(command -v "${cmd}")"
    ok "${cmd} found: ${cmd_path}"
    return 0
  else
    return 1
  fi
}

MISSING=()

if ! check_cmd flutter; then MISSING+=("flutter"); fi
if ! check_cmd dart; then MISSING+=("dart"); fi
if ! check_cmd git; then MISSING+=("git"); fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  fail "Missing required tools: ${MISSING[*]}. Install them first — see docs/SETUP.md"
fi

# Optional: deno for Edge Function linting
if ! check_cmd deno; then
  warn "deno not found — Edge Function lint/fmt hooks will be skipped"
  warn "Install: https://deno.land/#installation"
fi

# Check Flutter version
FLUTTER_VER=$(flutter --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
ok "Flutter version: $FLUTTER_VER"

echo ""

# ── 2. Install pre-commit (Python) ──────────────────────────────────────────
info "Setting up pre-commit hooks..."

if ! check_cmd pre-commit; then
  warn "pre-commit not found. Installing..."
  if check_cmd brew; then
    brew install pre-commit
  elif pip3 install --user pre-commit 2>/dev/null; then
    true
  elif pip install --user pre-commit 2>/dev/null; then
    true
  else
    fail "Cannot install pre-commit. Install Homebrew (macOS) or Python (pip)."
  fi
  ok "pre-commit installed"
fi

# Install hooks
pre-commit install
ok "Pre-commit hooks installed"

pre-commit install --hook-type pre-push
ok "Pre-push hooks installed"

echo ""

# ── 3. Secrets baseline ─────────────────────────────────────────────────────
info "Setting up secrets scanning..."

if ! check_cmd detect-secrets; then
  warn "detect-secrets not found. Installing..."
  if check_cmd brew; then
    brew install detect-secrets
  else
    pip3 install --user detect-secrets 2>/dev/null || pip install --user detect-secrets
  fi
fi

if [[ ! -f .secrets.baseline ]]; then
  detect-secrets scan > .secrets.baseline
  ok "Secrets baseline created (.secrets.baseline)"
else
  ok "Secrets baseline already exists"
fi

echo ""

# ── 4. Git branch setup ─────────────────────────────────────────────────────
info "Setting up git branches..."

CURRENT=$(git branch --show-current)

if ! git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
  git checkout -b dev
  ok "Created 'dev' branch"
  git checkout "$CURRENT"
else
  ok "'dev' branch already exists"
fi

echo ""

# ── 5. Flutter setup ────────────────────────────────────────────────────────
info "Running Flutter setup..."

if [[ -f pubspec.yaml ]]; then
  flutter pub get
  ok "Flutter dependencies installed"

  if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
    dart run build_runner build --delete-conflicting-outputs
    ok "Code generation complete"
  fi
else
  warn "No pubspec.yaml found — Flutter project not yet created. Run 'flutter create' first."
fi

echo ""

# ── 6. Verify hooks work ────────────────────────────────────────────────────
info "Verifying pre-commit hooks..."

if pre-commit run --all-files 2>/dev/null; then
  ok "All pre-commit hooks pass"
else
  warn "Some hooks failed — this is expected before Flutter project is created"
fi

echo ""

# ── 7. Claude Code quality hooks ────────────────────────────────────────────
info "Setting up Claude Code quality hooks..."

CLAUDE_DIR=".claude"
CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"

mkdir -p "$CLAUDE_DIR"

if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
  cat > "$CLAUDE_SETTINGS" << 'SETTINGS_EOF'
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
SETTINGS_EOF
  ok "Claude Code quality hooks configured"
else
  ok "Claude Code settings already exist"
fi

echo ""

# ── Done ─────────────────────────────────────────────────────────────────────
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Next steps:"
echo "    1. Read CLAUDE.md for development rules"
echo "    2. Read docs/ARCHITECTURE.md for tech overview"
echo "    3. Read docs/epics/README.md for what to build"
echo "    4. Create a feature branch: git checkout -b feature/E07-infrastructure dev"
echo ""
