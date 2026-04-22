# DeelMarkt - tear down the local dev stack cleanly (Windows PowerShell).
#
# Stops the Edge Functions background job started by dev-up.ps1, then stops
# the Supabase stack.

$ErrorActionPreference = "Continue"

Get-Job -Name "deelmarkt-functions" -ErrorAction SilentlyContinue | Stop-Job -PassThru | Remove-Job
Write-Host "v  Edge Functions stopped." -ForegroundColor Green

supabase stop
Write-Host "v  Supabase stopped." -ForegroundColor Green
