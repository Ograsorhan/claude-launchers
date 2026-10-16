param(
    [ValidateSet('Local','Free')][string]$Mode='Local',
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9._:/-]*$')][string]$Model='qwen3.5:4b',
    [switch]$NoLaunch,
    [switch]$Plan
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Ortak.ps1')

function Refresh-LauncherPath {
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')
}

function Install-WinGetPackage([string]$Id) {
    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw 'WinGet bulunamadi. Microsoft Store uzerinden App Installer uygulamasini kurup tekrar deneyin.'
    }
    Write-Host "Kuruluyor: $Id (Windows veya lisans onayi istenebilir)"
    & winget.exe install --id $Id --exact --source winget
    if ($LASTEXITCODE -ne 0) { throw "$Id kurulumu tamamlanamadi (kod $LASTEXITCODE). WinGet ciktisini kontrol edip yeniden deneyin." }
    Refresh-LauncherPath
}

try {
    $target = Join-Path $env:LOCALAPPDATA 'ClaudeLaunchers\app'
    if ($Plan) {
        Write-Host "PLAN: $Mode | Model: $Model | Hedef: $target"
        Write-Host 'Eksik: Claude Code (WinGet), Python 3.12 (WinGet), belge okuyucu venv+pypdf.'
        if ($Mode -eq 'Local') { Write-Host 'Ollama (WinGet), model indirme, 64K baglamli yerel model, saglik testi.' }
        else { Write-Host 'FreeLLMAPI 0.15.0 (SHA256 dogrulamali), saglayici anahtari kullanici tarafindan eklenir.' }
        Write-Host 'Masaustu ve Baslat kisayollari; kurulum sonrasi BASLAT.cmd.'
        exit 0
    }
    if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
        throw 'Bu kurulum paketi Windows x64 icindir.'
    }
    Write-Host 'Claude Launchers - Windows kurulumu' -ForegroundColor Cyan
    Write-Host 'Eksik programlar indirilir. Yerel model birkac GB yer kaplar; ilk kurulum uzun surebilir.'
    Write-Host 'Lisans kosullari ve Windows guvenlik istemleri kullanici tarafindan onaylanir.'
    # Preserve user config when installing over an existing copy.
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    if ([IO.Path]::GetFullPath($PSScriptRoot) -ne [IO.Path]::GetFullPath($target)) {
        Get-ChildItem -LiteralPath $PSScriptRoot -File | Where-Object { $_.Extension -in '.ps1','.cmd','.md','.txt' -and $_.Name -ne 'installed-mode.txt' } | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'devam-destegi') -Destination $target -Recurse -Force
    }
    . (Join-Path $target 'Ortak.ps1')
    $config = Get-LauncherConfig
    if (-not (Get-ClaudeCommand)) { Install-WinGetPackage 'Anthropic.ClaudeCode' }
    $cli = Get-ClaudeCommand
    if (-not $cli) { throw 'Claude Code kuruldu ancak bulunamadi. Yeni oturumda KUR.cmd dosyasini tekrar calistirin.' }
    & $cli --version
    if ($LASTEXITCODE -ne 0) { throw 'Claude Code surum kontrolu basarisiz.' }

    $python = Find-LauncherCommand 'python.exe' @((Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'))
    if (-not $python -or $python -like '*\WindowsApps\*') {
        Install-WinGetPackage 'Python.Python.3.12'
        $python = Find-LauncherCommand 'python.exe' @((Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'))
    }
    if (-not $python -or $python -like '*\WindowsApps\*') { throw 'Python bulunamadi. Kurulumu tekrar calistirin.' }
    $venv = Join-Path $target '.venv'
    $venvPython = Join-Path $venv 'Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $venvPython)) {
        & $python -m venv $venv
        if ($LASTEXITCODE -ne 0) { throw 'Belge okuyucu ortami olusturulamadi.' }
    }
    & $venvPython -m pip install --disable-pip-version-check 'pypdf>=6,<7'
    if ($LASTEXITCODE -ne 0) { throw 'PDF okuyucu kurulumu basarisiz.' }

    if ($Mode -eq 'Local') {
        if (-not (Get-OllamaCommand)) { Install-WinGetPackage 'Ollama.Ollama' }
        Start-OllamaService
        $ollama = Get-OllamaCommand
        Write-Host "Model indiriliyor: $Model"
        & $ollama pull $Model
        if ($LASTEXITCODE -ne 0) { throw 'Model indirilemedi. Internet ve disk alanini kontrol edip tekrar deneyin.' }
        # Separate alias: do not change the user's existing model or global Ollama settings.
        $body = @{model='claude-launchers-local';from=$Model;parameters=@{num_ctx=65536};stream=$false} | ConvertTo-Json -Depth 5
        $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/create' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 600
        $config.LocalModel = 'claude-launchers-local'
        Write-Host 'Modelin yanit verebildigi kontrol ediliyor (ilk yukleme zaman alabilir)...'
        $probe = @{model=$config.LocalModel;prompt='Reply with OK.';stream=$false;think=$false;options=@{num_predict=8}} | ConvertTo-Json -Depth 5
        $response = Invoke-RestMethod 'http://127.0.0.1:11434/api/generate' -Method Post -ContentType 'application/json' -Body $probe -TimeoutSec 600
        if (-not $response.response) { throw 'Model yanit uretmedi. Daha kucuk model icin: KUR.cmd -Model qwen3.5:2b' }
    } else {
        $freeDir = Join-Path $target 'tools\FreeLLMAPI'
        $freeExe = Join-Path $freeDir 'FreeLLMAPI.exe'
        if ($config.FreeExe -and (Test-Path -LiteralPath $config.FreeExe)) { $freeExe = $config.FreeExe }
        if (-not (Test-Path -LiteralPath $freeExe)) {
            $downloadDir = Join-Path $target 'downloads'
            New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
            $archive = Join-Path $downloadDir 'FreeLLMAPI-0.15.0-win.zip'
            $url = 'https://github.com/tashfeenahmed/freellmapi/releases/download/v0.15.0/FreeLLMAPI-0.15.0-win.zip'
            Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing -TimeoutSec 600
            $expected = '3a34a4b6d30485e28764faea765d6513d1fbc1b23086d4387c6158b3799d4f14'
            if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expected) { throw 'FreeLLMAPI SHA256 dogrulamasi basarisiz; dosya calistirilmadi.' }
            Expand-Archive -LiteralPath $archive -DestinationPath $freeDir -Force
            $found = @(Get-ChildItem -LiteralPath $freeDir -Recurse -Filter 'FreeLLMAPI.exe' -File)
            if ($found.Count -ne 1) { throw 'FreeLLMAPI uygulama dosyasi bulunamadi.' }
            $freeExe = $found[0].FullName
        }
        $config.FreeExe = $freeExe
        Write-Host 'FreeLLMAPI acilacak. Keys ekraninda KENDI saglayici anahtarinizi ekleyin.' -ForegroundColor Yellow
        Start-Process -FilePath $freeExe -WorkingDirectory (Split-Path $freeExe) | Out-Null
        Read-Host 'Saglayici kurulumu bitince Enter'
    }
    $config | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $target 'launcher-config.json') -Encoding UTF8
    # Verify the complete launcher, not just the model server, before reporting success.
    $probeExit = Invoke-ClaudeLauncher -Mode $Mode -Arguments @('-p','Reply with OK.','--max-turns','1')
    if ($probeExit -ne 0) { throw 'Claude Code baglanti testi basarisiz. Kurulum tamamlandi olarak isaretlenmedi.' }
    Set-Content -LiteralPath (Join-Path $target 'installed-mode.txt') -Value $Mode -Encoding ASCII
    New-Item -ItemType Directory -Path $config.Workspace -Force | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    foreach ($folder in @([Environment]::GetFolderPath('Desktop'), (Join-Path ([Environment]::GetFolderPath('Programs')) 'Claude Launchers'))) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        $shortcut = $shell.CreateShortcut((Join-Path $folder 'Claude Launchers.lnk'))
        $shortcut.TargetPath = Join-Path $target 'BASLAT.cmd'
        $shortcut.WorkingDirectory = $config.Workspace
        $shortcut.Description = 'Claude Code - yerel veya FreeLLMAPI modeli'
        $shortcut.Save()
    }
    Write-Host 'Kurulum tamamlandi. Masaustundeki Claude Launchers kisayolunu kullanabilirsiniz.' -ForegroundColor Green
    if (-not $NoLaunch) { & (Join-Path $target 'BASLAT.cmd') }
    exit 0
} catch {
    Write-Host "Kurulum tamamlanamadi: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Sorunu giderip ayni kurulum dosyasini yeniden calistirabilirsiniz.'
    exit 1
}
