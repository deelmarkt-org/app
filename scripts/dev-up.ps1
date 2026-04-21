# DeelMarkt - One-shot local stack + run the app (Windows PowerShell)
#
# Does the full local dev setup in one command:
#   1. `supabase start` (or keep running) + apply migrations + seed DB
#   2. Populate Supabase Vault (Cloudinary, Mollie, FCM)
#   3. Start Edge Functions serve as a background job
#   4. Write SUPABASE_URL + SUPABASE_ANON_PUBLIC to .env
#   5. Run build_runner to regenerate env.g.dart
#   6. `flutter run` on the device you pick (default: chrome)
#
# Usage:
#   .\scripts\dev-up.ps1                    # full flow, launches on Chrome
#   .\scripts\dev-up.ps1 -Device macos      # any Flutter device id
#   .\scripts\dev-up.ps1 -NoRun             # set everything up but don't launch
#   .\scripts\dev-up.ps1 -Reset             # drop DB + reapply from scratch

[CmdletBinding()]
param(
    [string]$Device = "chrome",
    [switch]$NoRun,
    [switch]$Reset
)

$ErrorActionPreference = "Stop"

function Info($msg)  { Write-Host "i  $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "v  $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "!  $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "x  $msg" -ForegroundColor Red; exit 1 }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "..")

# -- 1. Supabase + seeds -----------------------------------------------------
Info "[1/6] Bringing up Supabase stack..."
if ($Reset) { & "$scriptDir\dev-bootstrap.ps1" -Reset } else { & "$scriptDir\dev-bootstrap.ps1" }
if ($LASTEXITCODE -ne 0) { Fail "Supabase bootstrap failed." }

# -- 2. Vault ----------------------------------------------------------------
Info "[2/6] Seeding Vault (Cloudinary, Mollie, FCM)..."
& "$scriptDir\dev-secrets.ps1"

# -- 3. Functions serve (background job) -------------------------------------
Info "[3/6] Starting Edge Functions in background..."
$funcLog = Join-Path $env:TEMP "deelmarkt-functions-serve.log"

# Stop any previous job from this session.
Get-Job -Name "deelmarkt-functions" -ErrorAction SilentlyContinue | Stop-Job -PassThru | Remove-Job

Start-Job -Name "deelmarkt-functions" -ScriptBlock {
    param($workDir, $log)
    Set-Location $workDir
    supabase functions serve --no-verify-jwt *>&1 | Out-File -FilePath $log -Encoding utf8
} -ArgumentList (Get-Location), $funcLog | Out-Null
Ok "Edge Functions job started - tail: $funcLog"

# -- 4. .env - write local SUPABASE_URL + ANON -------------------------------
Info "[4/6] Updating .env with local Supabase URL + anon key..."
$statusEnv = supabase status -o env 2>$null
$anonKey = ($statusEnv | Select-String '^ANON_KEY=').Line -replace '^ANON_KEY=','' -replace '"',''

# Backup .env once per session.
if (-not (Test-Path ".env.backup") -or ((Get-Item .env).LastWriteTime -gt (Get-Item .env.backup).LastWriteTime)) {
    Copy-Item .env .env.backup -Force
    Ok ".env backed up -> .env.backup"
}

# Upsert SUPABASE_URL + SUPABASE_ANON_PUBLIC (preserve everything else).
$text = Get-Content .env -Raw
function UpsertEnv($body, $key, $val) {
    $pattern = "(?m)^$([regex]::Escape($key))=.*$"
    $line = "$key=$val"
    if ($body -match $pattern) { return ($body -replace $pattern, $line) }
    return ($body.TrimEnd() + "`r`n" + $line + "`r`n")
}
$text = UpsertEnv $text 'SUPABASE_URL' 'http://127.0.0.1:54321'
$text = UpsertEnv $text 'SUPABASE_ANON_PUBLIC' $anonKey
Set-Content .env -Value $text -NoNewline
Ok ".env updated"

# -- 5. build_runner ---------------------------------------------------------
Info "[5/6] Regenerating env.g.dart..."
flutter pub run build_runner build --delete-conflicting-outputs | Out-Null
if ($LASTEXITCODE -ne 0) { Warn "build_runner returned non-zero - check output above." }
Ok "env.g.dart regenerated."

# -- 6. Flutter run ----------------------------------------------------------
Write-Host ""
Ok "Local stack ready. Useful URLs:"
Write-Host "    Studio (DB):   http://localhost:54323"
Write-Host "    Inbucket:      http://localhost:54324"
Write-Host "    Edge logs:     Get-Content $funcLog -Wait"
Write-Host ""
Write-Host "  Seeded login: buyer-l2@deelmarkt.test / Password123!  (see supabase/seeds/01_users.sql)"
Write-Host ""

if ($NoRun) {
    Write-Host "  Skipping flutter run (-NoRun). When ready: flutter run -d $Device"
    Write-Host "  Tear down:   supabase stop; Stop-Job -Name deelmarkt-functions"
    exit 0
}

Info "[6/6] flutter run -d $Device  (Ctrl-C to stop the app, then 'supabase stop' to tear down)"
Write-Host ""
flutter run -d $Device
