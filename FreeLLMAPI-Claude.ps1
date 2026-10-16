$ErrorActionPreference = 'Stop'
try {
    . (Join-Path $PSScriptRoot 'Ortak.ps1')
    $result = Invoke-ClaudeLauncher -Mode Free -Arguments $args
    exit $result
} catch { Write-Host "Hata: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }