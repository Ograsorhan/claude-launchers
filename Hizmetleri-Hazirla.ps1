param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
function Test-Endpoint([string]$Url) {
    try { $null = Invoke-RestMethod -Uri $Url -TimeoutSec 2; return $true } catch { return $false }
}
$services = @(
    @{ Name='FreeLLMAPI'; Url='http://127.0.0.1:31415/api/auth/status'; Exe=(Join-Path $env:USERPROFILE 'Downloads\FreeLLMAPI-0.15.0-win\FreeLLMAPI.exe') },
    @{ Name='Ollama'; Url='http://127.0.0.1:11434/api/version'; Exe=(Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama app.exe') }
)
foreach ($service in $services) {
    if (Test-Endpoint $service.Url) { continue }
    if ($CheckOnly) { throw "$($service.Name) hazir degil." }
    if (-not (Test-Path -LiteralPath $service.Exe)) { throw "$($service.Name) bulunamadi: $($service.Exe)" }
    Write-Host "$($service.Name) baslatiliyor..."
    Start-Process -FilePath $service.Exe -WorkingDirectory (Split-Path $service.Exe) -WindowStyle Hidden
    $ready = $false
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if (Test-Endpoint $service.Url) { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw "$($service.Name) zamaninda hazir olmadi. Uygulamayi kontrol edip yeniden deneyin." }
}
if ($CheckOnly) { Write-Host 'FreeLLMAPI ve Ollama hazir.' }
