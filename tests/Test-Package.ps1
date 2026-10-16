$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$failed = @()
Get-ChildItem -LiteralPath $root -Recurse -Filter '*.ps1' | ForEach-Object {
    $tokens=$null; $errors=$null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName,[ref]$tokens,[ref]$errors) | Out-Null
    if ($errors.Count) { $failed += $errors }
}
if ($failed.Count) { throw ($failed | Out-String) }
. (Join-Path $root 'Ortak.ps1')
function Assert($Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
$testDir = Join-Path ([IO.Path]::GetTempPath()) ('launcher-tests-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDir | Out-Null
$originalLocalAppData = $env:LOCALAPPDATA
try {
    $env:LOCALAPPDATA = $testDir
    $script:PackageRoot = $testDir
    $defaults = Get-LauncherConfig
    Assert ($defaults.FreeModel -eq 'auto') 'New users must not inherit a private cloud profile.'
    @{LocalModel='test:2b';Workspace='C:\Example Space\Projects';FreeExe='C:\Example Space\FreeLLMAPI.exe'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $testDir 'launcher-config.json')
    $config = Get-LauncherConfig
    Assert ($config.Workspace -eq 'C:\Example Space\Projects') 'Paths with spaces must survive config loading.'
    Assert ($config.LocalModel -eq 'test:2b') 'Model configuration was ignored.'
    $settings = New-ClaudeSettings 'http://127.0.0.1:11434' 'test-token' 'test:2b'
    Assert ($settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL -eq 'test:2b') 'Unexpected model fallback.'
    Assert (-not $settings.ContainsKey('permissions')) 'Launcher must retain Claude permission defaults.'
    Assert ($settings.env.CLAUDE_CODE_DISABLE_THINKING -eq '1') 'Local performance settings unexpectedly changed.'
    $cloud = New-ClaudeSettings 'http://127.0.0.1:31415' 'test-token' 'auto' 'Free'
    Assert ($cloud.alwaysThinkingEnabled -eq $true) 'Cloud reasoning is disabled.'
    Assert ($cloud.env.CLAUDE_CODE_DISABLE_THINKING -eq '0') 'Inherited reasoning disable flag must be overridden.'
    Assert ($cloud.env.MAX_THINKING_TOKENS -eq '4096') 'Cloud reasoning budget is missing.'
    Assert ([int]$cloud.env.CLAUDE_CODE_MAX_OUTPUT_TOKENS -gt [int]$cloud.env.MAX_THINKING_TOKENS) 'Output budget must exceed reasoning budget.'
    $freeId='nvidia/nemotron-3.5-super-vl:free'
    Assert ((Resolve-FreeModel 'auto' @(@{id=$freeId})) -eq $freeId) 'Available preferred free model was not selected.'
    Assert ((Resolve-FreeModel 'auto' @(@{id='different-model'})) -eq 'auto') 'Missing preferred model must retain working auto routing.'
    Assert ((Resolve-FreeModel 'auto:custom-profile' @(@{id=$freeId})) -eq 'auto:custom-profile') 'Explicit user model choice must be preserved.'
    # Exercise process argument forwarding, nonzero exit propagation and credential cleanup.
    $fakeCli = Join-Path $testDir 'fake-claude.cmd'
    @'
@echo off
if not "%~1"=="--settings" exit /b 91
if not exist "%~2" exit /b 92
echo %* > "%LAUNCHER_TEST_ARGS%"
echo simulated CLI output
exit /b 7
'@ | Set-Content -LiteralPath $fakeCli -Encoding ASCII
    $script:FakeClaude = $fakeCli
    function Get-ClaudeCommand { return $script:FakeClaude }
    function Start-OllamaService { }
    Set-Content -LiteralPath (Join-Path $testDir 'Calisma-kurallari.md') -Value 'Test rules'
    $env:LAUNCHER_TEST_ARGS = Join-Path $testDir 'args.txt'
    Invoke-ClaudeLauncher -Mode Local -Arguments @('-p','two words','--max-turns','1')
    Assert ($script:LauncherExitCode -eq 7) 'Child process exit code was lost.'
    $actualArgs = Get-Content -LiteralPath $env:LAUNCHER_TEST_ARGS -Raw
    Assert ($actualArgs -match 'two words') 'Prompt arguments were lost.'
    $settingsMatch = [regex]::Match($actualArgs,'--settings\s+"?([^"\r\n]+?settings\.json)"?')
    Assert $settingsMatch.Success 'Settings file argument missing.'
    Assert (-not (Test-Path -LiteralPath $settingsMatch.Groups[1].Value)) 'Temporary credentials were not cleaned after child failure.'
    # Startup failure must not be reported as success.
    function Start-OllamaService { throw 'simulated unavailable service' }
    $caught=$false
    try { Invoke-ClaudeLauncher -Mode Local -Arguments @() } catch { $caught=$true }
    Assert $caught 'Service errors must stop the launcher.'
    Write-Host 'PASS: syntax, defaults, config paths, model isolation, argument forwarding, failure exit, cleanup, service errors.'
} finally {
    $env:LOCALAPPDATA = $originalLocalAppData
    Remove-Item Env:LAUNCHER_TEST_ARGS -ErrorAction SilentlyContinue
    # Only files created by this test in its unique directory.
    foreach ($name in @('launcher-config.json','fake-claude.cmd','Calisma-kurallari.md','args.txt')) {
        $file = Join-Path $testDir $name
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
    $sessions = Join-Path $testDir 'ClaudeLaunchers\sessions'
    if (Test-Path -LiteralPath $sessions) { Remove-Item -LiteralPath $sessions -Force }
    $appDir = Join-Path $testDir 'ClaudeLaunchers'
    if (Test-Path -LiteralPath $appDir) { Remove-Item -LiteralPath $appDir -Force }
    Remove-Item -LiteralPath $testDir -Force
}
# The mock deliberately exits with 7. Do not leak that native exit status to CI.
exit 0
