# DeelMarkt - Populate local Supabase Vault with secrets from .env + firebase/
#
# Edge Functions read secrets from Supabase Vault (not process env) via
# getVaultSecret(...). In Supabase Cloud the vault is populated by ops;
# locally we seed it from .env + the Firebase admin SDK JSON so the
# create-payment / mollie-webhook / image-upload-process / send-push-
# notification functions work end-to-end.
#
# Idempotent - re-running warns on existing secrets but does not rotate.
#
# Usage: .\scripts\dev-secrets.ps1
#
# Prereq: `supabase start` must already be running.

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Info($msg)  { Write-Host "i  $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "v  $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "!  $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "x  $msg" -ForegroundColor Red; exit 1 }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "..")

if (-not (Test-Path ".env")) { Fail "No .env - copy .env.example and fill in credentials first." }

# -- Read Supabase local endpoints/keys --------------------------------------
# If .env has SUPABASE_PROJECT_ID that doesn't match the running container,
# `supabase status` errors with "No such container" - catch explicitly.
$statusEnv = supabase status -o env 2>&1
if ($statusEnv -match "No such container") {
    Fail "supabase status cannot find the running container.`n   Likely cause: .env has SUPABASE_PROJECT_ID set and it does not match`n   the running stack. Remove SUPABASE_PROJECT_ID from .env locally -`n   SUPABASE_URL is all the app needs."
}
$apiUrl     = ($statusEnv | Select-String '^API_URL=').Line         -replace '^API_URL=',''       -replace '"',''
$serviceKey = ($statusEnv | Select-String '^SERVICE_ROLE_KEY=').Line -replace '^SERVICE_ROLE_KEY=','' -replace '"',''

if (-not $apiUrl)     { Fail "Supabase not running - run scripts\dev-bootstrap.ps1 first." }
if (-not $serviceKey) { Fail "Could not read SERVICE_ROLE_KEY from supabase status." }

# -- Load .env values (last-wins on duplicates) ------------------------------
$envHash = @{}
Get-Content .env | Where-Object { $_ -match '^[A-Z_]+=' } | ForEach-Object {
    $pair = $_ -split '=', 2
    $envHash[$pair[0]] = $pair[1]
}

$cloudinaryUrl = $envHash['CLOUDINARY_URL']
$mollieKey     = $envHash['MOLLIE_TEST_API_KEY']

# -- Parse Cloudinary URL ----------------------------------------------------
$cloudName = ""; $apiKey = ""; $apiSecret = ""
if ($cloudinaryUrl -match '^cloudinary://([^:]+):([^@]+)@(.+)$') {
    $apiKey    = $matches[1]
    $apiSecret = $matches[2]
    $cloudName = $matches[3]
}

# -- Firebase admin SDK ------------------------------------------------------
$fcmJson = ""
$fcmFile = Get-ChildItem -Path "firebase" -Filter "deelmarkt-*-firebase-adminsdk-*.json" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($fcmFile) {
    $fcmJson = Get-Content $fcmFile.FullName -Raw
}

# -- Upsert helper -----------------------------------------------------------
function Put-Secret($name, $value, $description) {
    if (-not $value) { Warn "skip $name - empty value"; return }

    $body = @{ p_name = $name; p_secret = $value; p_description = $description } | ConvertTo-Json -Compress

    try {
        Invoke-RestMethod -Method Post `
            -Uri "$apiUrl/rest/v1/rpc/insert_vault_secret" `
            -Headers @{ "apikey" = $serviceKey; "Authorization" = "Bearer $serviceKey"; "Content-Type" = "application/json" } `
            -Body $body | Out-Null
        Ok "vault: $name"
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__
        if ($status -eq 409 -or $status -eq 500) {
            Warn "vault: $name already set (supabase stop/start wipes it)"
        } else {
            Fail "vault: $name - HTTP $status"
        }
    }
}

# -- Write all secrets -------------------------------------------------------
Write-Host ""
Info "Populating Supabase Vault from .env + firebase/..."

Put-Secret "CLOUDINARY_CLOUD_NAME" $cloudName "GH-59 image pipeline"
Put-Secret "CLOUDINARY_API_KEY"    $apiKey    "GH-59 image pipeline"
Put-Secret "CLOUDINARY_API_SECRET" $apiSecret "GH-59 image pipeline"
Put-Secret "mollie_api_key"        $mollieKey "Mollie test (local dev)"
Put-Secret "fcm_service_account"   $fcmJson   "Firebase admin SDK (FCM push)"

Write-Host ""
Ok "Vault seeded. Start Edge Functions in a second terminal:"
Write-Host "    supabase functions serve"
Write-Host ""
Write-Host "  Then for Mollie webhooks (if testing checkout):"
Write-Host "    ngrok http 54321"
Write-Host "    # Paste the https://*.ngrok-free.app URL into Mollie dashboard -> profile -> webhook URL."
