$ErrorActionPreference = 'Stop'
try {
    . (Join-Path $PSScriptRoot 'Ortak.ps1')
    $config = Get-LauncherConfig
    New-Item -ItemType Directory -Path $config.Workspace -Force | Out-Null
    Set-Location -LiteralPath $config.Workspace
    $mode = 'Local'
    $modeFile = Join-Path $PSScriptRoot 'installed-mode.txt'
    if (Test-Path -LiteralPath $modeFile) { $mode = (Get-Content -LiteralPath $modeFile -Raw).Trim() }
    Invoke-ClaudeLauncher -Mode $mode -Arguments $args
    exit $script:LauncherExitCode
} catch { Write-Host "Hata: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
