$ClaudeArgs = $args
$ErrorActionPreference = 'Stop'
$base = 'http://127.0.0.1:11434'
try {
    $null = Invoke-RestMethod "$base/api/version" -TimeoutSec 5
    $key = 'ollama'
    $chain = 'qwen3.5-hizli:4b'
    $settings = @{ model=$chain; alwaysThinkingEnabled=$false; env=@{
        ANTHROPIC_BASE_URL=$base; ANTHROPIC_AUTH_TOKEN=$key; ANTHROPIC_API_KEY=$key
        ANTHROPIC_MODEL=$chain; ANTHROPIC_DEFAULT_OPUS_MODEL=$chain; ANTHROPIC_DEFAULT_SONNET_MODEL=$chain
        ANTHROPIC_DEFAULT_HAIKU_MODEL=$chain; CLAUDE_CODE_SUBAGENT_MODEL=$chain
        CLAUDE_CODE_DISABLE_AUTO_MEMORY='1'; CLAUDE_CODE_MAX_OUTPUT_TOKENS='4096'; MAX_THINKING_TOKENS='0'; CLAUDE_CODE_DISABLE_THINKING='1'
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
    Write-Host 'Ollama uygulamasinin acik oldugunu kontrol edin.'
    exit 1
}

finally {
    if ($settingsPath -and (Test-Path -LiteralPath $settingsPath)) { Remove-Item -LiteralPath $settingsPath -Force }
}





