$ErrorActionPreference = 'Stop'
$script:PackageRoot = $PSScriptRoot

function Get-LauncherConfig {
    $config = @{ LocalModel='claude-launchers-local'; FreeModel='auto'; FreeExe=''; Workspace=(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Claude Projeleri') }
    $path = Join-Path $script:PackageRoot 'launcher-config.json'
    if (Test-Path -LiteralPath $path) {
        $saved = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        foreach ($name in @('LocalModel','FreeModel','FreeExe','Workspace')) {
            if ($saved.$name) { $config[$name] = [string]$saved.$name }
        }
    }
    return $config
}

function Find-LauncherCommand([string]$Name, [string[]]$Candidates) {
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $candidate }
    }
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    return $null
}

function Get-ClaudeCommand {
    Find-LauncherCommand 'claude.exe' @((Join-Path $env:USERPROFILE '.local\bin\claude.exe'), (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\claude.exe'))
}

function Get-OllamaCommand {
    Find-LauncherCommand 'ollama.exe' @((Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'))
}

function Test-LocalService([string]$Url) {
    try { $null = Invoke-RestMethod -Uri $Url -TimeoutSec 3; return $true } catch { return $false }
}

function Wait-LocalService([string]$Url, [int]$Seconds=60) {
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    do {
        if (Test-LocalService $Url) { return }
        Start-Sleep -Milliseconds 500
    } while ([DateTime]::UtcNow -lt $deadline)
    throw "Servis yanit vermedi: $Url. Uygulamayi kontrol edip yeniden deneyin."
}

function Start-OllamaService {
    if (Test-LocalService 'http://127.0.0.1:11434/api/version') { return }
    $exe = Get-OllamaCommand
    if (-not $exe) { throw 'Ollama bulunamadi. KUR.cmd dosyasini calistirin.' }
    Start-Process -FilePath $exe -ArgumentList 'serve' -WindowStyle Hidden | Out-Null
    Wait-LocalService 'http://127.0.0.1:11434/api/version'
}

function Start-FreeService {
    if (Test-LocalService 'http://127.0.0.1:31415/api/auth/status') { return }
    $config = Get-LauncherConfig
    $exe = Find-LauncherCommand 'FreeLLMAPI.exe' @($config.FreeExe, (Join-Path $script:PackageRoot 'tools\FreeLLMAPI\FreeLLMAPI.exe'), (Join-Path $env:LOCALAPPDATA 'Programs\FreeLLMAPI\FreeLLMAPI.exe'))
    if (-not $exe) { throw 'FreeLLMAPI bulunamadi. KUR-BULUT.cmd dosyasini calistirin.' }
    Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -WindowStyle Hidden | Out-Null
    Wait-LocalService 'http://127.0.0.1:31415/api/auth/status'
}

function New-ClaudeSettings([string]$BaseUrl, [string]$Key, [string]$Model) {
    return @{ model=$Model; alwaysThinkingEnabled=$false; env=@{
        ANTHROPIC_BASE_URL=$BaseUrl; ANTHROPIC_AUTH_TOKEN=$Key; ANTHROPIC_API_KEY=$Key
        ANTHROPIC_MODEL=$Model; ANTHROPIC_DEFAULT_OPUS_MODEL=$Model; ANTHROPIC_DEFAULT_SONNET_MODEL=$Model
        ANTHROPIC_DEFAULT_HAIKU_MODEL=$Model; CLAUDE_CODE_SUBAGENT_MODEL=$Model
        CLAUDE_CODE_DISABLE_AUTO_MEMORY='1'; CLAUDE_CODE_MAX_OUTPUT_TOKENS='4096'
        MAX_THINKING_TOKENS='0'; CLAUDE_CODE_DISABLE_THINKING='1'
    }}
}

function Invoke-ClaudeLauncher([ValidateSet('Local','Free')][string]$Mode, [string[]]$Arguments) {
    $tempDirectory = $null
    try {
        $cli = Get-ClaudeCommand
        if (-not $cli) { throw 'Claude Code bulunamadi. KUR.cmd dosyasini calistirin.' }
        $config = Get-LauncherConfig
        if ($Mode -eq 'Local') {
            Start-OllamaService
            $base = 'http://127.0.0.1:11434'; $key = 'ollama'; $model = $config.LocalModel
        } else {
            Start-FreeService
            $base = 'http://127.0.0.1:31415'
            $session = Invoke-RestMethod "$base/api/auth/desktop-session" -Method Post -ContentType 'application/json' -Body '{}' -TimeoutSec 10
            $headers = @{Authorization="Bearer $($session.token)"}
            $key = (Invoke-RestMethod "$base/api/settings/api-key" -Headers $headers -TimeoutSec 10).apiKey
            if (-not $key) { throw 'FreeLLMAPI yerel anahtari alinamadi.' }
            $model = $config.FreeModel
            $models = Invoke-RestMethod "$base/v1/models" -Headers @{Authorization="Bearer $key"} -TimeoutSec 15
            if (-not @($models.data).Count) { throw 'Bulut modeli yok. FreeLLMAPI uygulamasinda kendi saglayici anahtarinizi ekleyin.' }
        }
        $rules = Join-Path $script:PackageRoot 'Calisma-kurallari.md'
        $plugin = Join-Path $script:PackageRoot 'devam-destegi'
        if (-not (Test-Path -LiteralPath $rules)) { throw 'Paket eksik. ZIP dosyasinin tamamini cikarin.' }
        # Inherit the current user's profile ACL; no credentials are saved in the package.
        $tempDirectory = Join-Path $env:LOCALAPPDATA ('ClaudeLaunchers\sessions\' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempDirectory -Force | Out-Null
        $settingsPath = Join-Path $tempDirectory 'settings.json'
        New-ClaudeSettings $base $key $model | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
        & $cli --settings $settingsPath --model $model --tools default --append-system-prompt-file $rules --plugin-dir $plugin @Arguments | Out-Host
        return $LASTEXITCODE
    } finally {
        if ($tempDirectory -and (Test-Path -LiteralPath (Join-Path $tempDirectory 'settings.json'))) {
            Remove-Item -LiteralPath (Join-Path $tempDirectory 'settings.json') -Force
            Remove-Item -LiteralPath $tempDirectory -Force
        }
    }
}
