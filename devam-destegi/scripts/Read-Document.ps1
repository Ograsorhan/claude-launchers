param([Parameter(Mandatory=$true)][string]$Path,[int]$MaxChars=16000,[int]$Offset=0,[int]$Pages=20)
$ErrorActionPreference='Stop'
$file=(Resolve-Path -LiteralPath $Path).Path
$ext=[IO.Path]::GetExtension($file).ToLowerInvariant()
if ((Get-Item -LiteralPath $file).Length -gt 100000000) { throw 'Dosya 100 MB sinirini asiyor.' }
if ($MaxChars -lt 1 -or $MaxChars -gt 100000 -or $Offset -lt 0) { throw 'Gecersiz okuma siniri.' }
if ($ext -eq '.rtf') {
    throw 'Eski DOC/RTF bu ortamda dogrulanamadi; Word ile DOCX olarak farkli kaydedin ve DOCX dosyasini verin. Dosya degistirilmedi.'
} else {
    $python=Join-Path (Split-Path (Split-Path $PSScriptRoot)) '.venv\Scripts\python.exe'
    if(-not (Test-Path -LiteralPath $python)){throw 'Belge okuyucu bulunamadi. Once KUR.cmd dosyasini calistirin.'}
    & $python (Join-Path $PSScriptRoot 'read_document.py') $file --max-chars $MaxChars --offset $Offset --pages $Pages
    if($LASTEXITCODE -ne 0){throw 'Belge okunamadi; yukaridaki hata mesajina bakin.'}
}
