# DeelMarkt - Local Stack Bootstrap (Windows PowerShell)
#
# Starts Supabase local (Postgres + Auth + Storage + Realtime + Edge Functions
# + Inbucket for emails), applies every migration, and prints the URLs and
# keys you need to fill in `.env`.
#
# Safe to re-run. Will not wipe data unless you pass -Reset.
#
# Usage:
#   .\scripts\dev-bootstrap.ps1            # start (or keep running) + apply migrations
#   .\scripts\dev-bootstrap.ps1 -Reset     # drop all data and reapply migrations from scratch
#   .\scripts\dev-bootstrap.ps1 -Stop      # stop local stack
#
# Prereqs: Docker Desktop running; Supabase CLI on PATH.
# See: docs/LOCAL-STACK.md

[CmdletBinding()]
param(
    [switch]$Reset,
    [switch]$Stop
)

$ErrorActionPreference = "Stop"

function Info($msg)  { Write-Host "i  $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "v  $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "!  $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "x  $msg" -ForegroundColor Red; exit 1 }

# -- Preflight ---------------------------------------------------------------
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Fail "Supabase CLI not installed. See docs/LOCAL-STACK.md section 1."
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Fail "Docker not installed."
}
try { docker info *> $null } catch {
    Fail "Docker daemon not running. Start Docker Desktop and re-run."
}

# cd to repo root (scripts/.. )
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "..")

# -- Stop --------------------------------------------------------------------
if ($Stop) {
    Info "Stopping local Supabase stack..."
    supabase stop
    Ok "Stopped."
    exit 0
}

# -- Start / reset -----------------------------------------------------------
$mode = if ($Reset) { "reset" } else { "start" }

Write-Host ""
Write-Host "  DeelMarkt - Local Stack Bootstrap (mode: $mode)" -ForegroundColor Cyan
Write-Host "  ==================================================" -ForegroundColor Cyan
Write-Host ""

if ($Reset) {
    Warn "Reset requested - all local data will be dropped."
    Info "Applying every migration from supabase/migrations/..."
    supabase db reset
    if ($LASTEXITCODE -ne 0) { Fail "supabase db reset failed." }
    Ok "Database reset and migrations re-applied."
} else {
    $running = $false
    $envOutput = supabase status -o env 2>$null
    if ($envOutput -match '^API_URL=http') { $running = $true }

    if ($running) {
        Ok "Supabase already running - keeping data."
    } else {
        Info "Starting Supabase local stack (first run pulls ~1 GB of Docker images)..."
        supabase start
        if ($LASTEXITCODE -ne 0) { Fail "supabase start failed." }
        Ok "Supabase started."
    }

    Info "Applying any new migrations..."
    supabase migration up
    if ($LASTEXITCODE -ne 0) {
        Warn "Migration up failed - run 'supabase db reset' if the schema is out of sync."
    }
}

# -- Seed (optional) ---------------------------------------------------------
$seedDir = Join-Path (Get-Location) "supabase\seeds"
if (Test-Path $seedDir) {
    $seeds = Get-ChildItem -Path $seedDir -Filter *.sql -ErrorAction SilentlyContinue
    if ($seeds) {
        Info "Applying seed data from supabase/seeds/..."
        # Supabase CLI's standard local-only DB URL - not a real credential.
        $localDbUrl = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"  # pragma: allowlist secret
        foreach ($seed in $seeds) {
            # Requires psql on PATH (ships with Supabase CLI's bundled postgres on Windows).
            & psql $localDbUrl -v ON_ERROR_STOP=1 -f $seed.FullName *> $null
            if ($LASTEXITCODE -eq 0) {
                Ok "  seeded: $($seed.Name)"
            } else {
                Warn "  seed failed: $($seed.Name) - check psql is on PATH"
            }
        }
    }
} else {
    Warn "No supabase/seeds/ directory - the DB is empty. Ask belengaz for the fixture set."
}

# -- Output ------------------------------------------------------------------
Write-Host ""
Write-Host "  Local stack is up." -ForegroundColor Green
Write-Host "  ===================" -ForegroundColor Green
Write-Host ""
supabase status
Write-Host ""
Write-Host "== Ready-to-paste .env values =="
supabase status -o env | Select-String -Pattern '^(ANON_KEY|API_URL)=' | ForEach-Object {
    $line = $_.Line
    $line = $line -replace '^ANON_KEY=', 'SUPABASE_ANON_PUBLIC='
    $line = $line -replace '^API_URL=', 'SUPABASE_URL='
    Write-Host $line
}
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Paste the SUPABASE_* lines above into your .env, then:"
Write-Host "       flutter pub run build_runner build --delete-conflicting-outputs"
Write-Host "  2. Open http://localhost:54323  (Studio - DB browser)"
Write-Host "  3. Open http://localhost:54324  (Inbucket - auth emails)"
Write-Host "  4. flutter run"
Write-Host ""
Write-Host "See docs/LOCAL-STACK.md for troubleshooting and ngrok/Mollie/Firebase tips."
