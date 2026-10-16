$ErrorActionPreference = 'Stop'
try {
    . (Join-Path $PSScriptRoot 'Ortak.ps1')
    Invoke-ClaudeLauncher -Mode Free -Arguments $args
    exit $script:LauncherExitCode
} catch { Write-Host "Hata: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
