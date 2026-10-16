$ClaudeArgs = $args
$ErrorActionPreference = 'Stop'
$base = 'http://127.0.0.1:31415'
try {
    & (Join-Path $PSScriptRoot 'Hizmetleri-Hazirla.ps1')
    $session = Invoke-RestMethod "$base/api/auth/desktop-session" -Method Post -ContentType 'application/json' -Body '{}' -TimeoutSec 5
    $headers = @{ Authorization = "Bearer $($session.token)" }
    $key = (Invoke-RestMethod "$base/api/settings/api-key" -Headers $headers -TimeoutSec 5).apiKey
    if (-not $key) { throw 'FreeLLMAPI anahtari alinamadi.' }
    $chain = 'auto:ucretsiz-gecis'
    $settings = @{ model=$chain; env=@{
        ANTHROPIC_BASE_URL=$base; ANTHROPIC_AUTH_TOKEN=$key; ANTHROPIC_API_KEY=$key
        ANTHROPIC_MODEL=$chain; ANTHROPIC_DEFAULT_OPUS_MODEL=$chain; ANTHROPIC_DEFAULT_SONNET_MODEL=$chain
        ANTHROPIC_DEFAULT_HAIKU_MODEL=$chain; CLAUDE_CODE_SUBAGENT_MODEL=$chain
        CLAUDE_CODE_DISABLE_AUTO_MEMORY='1'; CLAUDE_CODE_MAX_OUTPUT_TOKENS='8192'; MAX_THINKING_TOKENS='0'; CLAUDE_CODE_DISABLE_THINKING='1'
    }} | ConvertTo-Json -Compress -Depth 5
    $cli = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    $settingsPath = Join-Path ([IO.Path]::GetTempPath()) ('freellm-claude-' + [Guid]::NewGuid().ToString('N') + '.json')
    [IO.File]::WriteAllText($settingsPath, $settings, (New-Object Text.UTF8Encoding($false)))
    $rulesPath = Join-Path $PSScriptRoot 'Calisma-kurallari.md'
    if (-not (Test-Path -LiteralPath $rulesPath)) { throw 'Calisma-kurallari.md ayni klasorde olmali.' }
    $pluginPath = Join-Path $PSScriptRoot 'devam-destegi'
    & $cli --settings $settingsPath --model $chain --tools default --append-system-prompt-file $rulesPath --plugin-dir $pluginPath @ClaudeArgs
    exit $LASTEXITCODE
} catch {
    Write-Host "Baslatilamadi: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'FreeLLMAPI ve Ollama kurulum yollarini kontrol edin.'
    exit 1
}

finally {
    if ($settingsPath -and (Test-Path -LiteralPath $settingsPath)) { Remove-Item -LiteralPath $settingsPath -Force }
}




