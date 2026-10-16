param([string]$Destination=(Join-Path $PSScriptRoot 'dist'))
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Path $Destination -Force | Out-Null
$zip = Join-Path $Destination 'Claude-Launchers-Windows.zip'
$files = @(Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in '.ps1','.cmd','.md' -and $_.Name -ne 'Build-Package.ps1' })
$paths = @($files.FullName) + (Join-Path $PSScriptRoot 'devam-destegi')
Compress-Archive -LiteralPath $paths -DestinationPath $zip -Force
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath ($zip+'.sha256') -Value ($hash+'  Claude-Launchers-Windows.zip') -Encoding ASCII
Write-Host "Paket: $zip"
