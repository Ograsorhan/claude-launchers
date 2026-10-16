param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Ortak.ps1')
if ($CheckOnly) {
    if (-not (Test-LocalService 'http://127.0.0.1:31415/api/auth/status')) { throw 'FreeLLMAPI hazir degil.' }
} else { Start-FreeService }
