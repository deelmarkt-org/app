# DeelMarkt - Development Environment Setup (Windows PowerShell)
# Usage: .\scripts\setup.ps1

$ErrorActionPreference = "Stop"

function Info($msg)  { Write-Host "i  $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "v  $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "!  $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "x  $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  DeelMarkt - Development Environment Setup" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""

# -- 1. Check prerequisites ---------------------------------------------------
Info "Checking prerequisites..."

$missing = @()

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterVer = (flutter --version 2>$null | Select-Object -First 1)
    Ok "flutter found: $flutterVer"
} else { $missing += "flutter" }

if (Get-Command dart -ErrorAction SilentlyContinue) {
    Ok "dart found"
} else { $missing += "dart" }

if (Get-Command git -ErrorAction SilentlyContinue) {
    Ok "git found"
} else { $missing += "git" }

if ($missing.Count -gt 0) {
    Fail "Missing required tools: $($missing -join ', '). Install them first - see docs/SETUP.md"
}

Write-Host ""

# -- 2. Install pre-commit ----------------------------------------------------
Info "Setting up pre-commit hooks..."

if (-not (Get-Command pre-commit -ErrorAction SilentlyContinue)) {
    Warn "pre-commit not found. Installing via pip..."
    pip install pre-commit
    if ($LASTEXITCODE -ne 0) { Fail "Failed to install pre-commit. Ensure Python + pip are installed." }
}
Ok "pre-commit available"

pre-commit install
Ok "Pre-commit hooks installed"

pre-commit install --hook-type pre-push
Ok "Pre-push hooks installed"

Write-Host ""

# -- 3. Secrets baseline -------------------------------------------------------
Info "Setting up secrets scanning..."

if (-not (Get-Command detect-secrets -ErrorAction SilentlyContinue)) {
    Warn "detect-secrets not found. Installing..."
    pip install detect-secrets
}

if (-not (Test-Path .secrets.baseline)) {
    detect-secrets scan | Out-File -Encoding utf8 .secrets.baseline
    Ok "Secrets baseline created (.secrets.baseline)"
} else {
    Ok "Secrets baseline already exists"
}

Write-Host ""

# -- 4. Git branch setup ------------------------------------------------------
Info "Setting up git branches..."

$branches = git branch --list 2>$null
if ($branches -notmatch "dev") {
    $current = git branch --show-current
    git checkout -b dev
    Ok "Created 'dev' branch"
    git checkout $current
} else {
    Ok "'dev' branch already exists"
}

Write-Host ""

# -- 5. Flutter setup ----------------------------------------------------------
Info "Running Flutter setup..."

if (Test-Path pubspec.yaml) {
    flutter pub get
    Ok "Flutter dependencies installed"

    $pubspec = Get-Content pubspec.yaml -Raw
    if ($pubspec -match "build_runner") {
        dart run build_runner build --delete-conflicting-outputs
        Ok "Code generation complete"
    }
} else {
    Warn "No pubspec.yaml found - Flutter project not yet created. Run 'flutter create' first."
}

Write-Host ""

# -- 6. Verify hooks -----------------------------------------------------------
Info "Verifying pre-commit hooks..."

pre-commit run --all-files 2>$null
if ($LASTEXITCODE -eq 0) {
    Ok "All pre-commit hooks pass"
} else {
    Warn "Some hooks failed - this is expected before Flutter project is created"
}

Write-Host ""
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "  ===============" -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    1. Read CLAUDE.md for development rules"
Write-Host "    2. Read docs/ARCHITECTURE.md for tech overview"
Write-Host "    3. Read docs/epics/README.md for what to build"
Write-Host "    4. Create a feature branch: git checkout -b feature/E07-infrastructure dev"
Write-Host ""
