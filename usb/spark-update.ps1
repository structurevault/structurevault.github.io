# SPARK Centre USB updater (Windows)
# Downloads only the files that changed on GitHub into the "site" folder next to this script.
# If there is no internet, it leaves the existing copy alone.
param(
    [string]$Root = $PSScriptRoot,
    [string]$Repo = 'structurevault/structurevault.github.io',
    [string]$Branch = 'main'
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$site = Join-Path $Root 'site'
$manifestPath = Join-Path $site '.spark-manifest.json'
$versionJs = Join-Path $site 'spark-version.js'
$dot = [string][char]0x00B7
New-Item -ItemType Directory -Force -Path $site | Out-Null

function Write-Version([string]$status) {
    $s = $status -replace '\\', '\\' -replace '"', '\"'
    [IO.File]::WriteAllText($versionJs, "window.SPARK_USB={status:`"$s`"};`n")
}
function Get-Stamp { (Get-Date).ToString('d MMM yyyy, h:mm tt') }

# Same hash git uses for a file, so we can tell if a file on the stick already matches GitHub.
function Get-BlobSha([string]$file) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $header = [Text.Encoding]::ASCII.GetBytes("blob $($bytes.Length)`0")
    $sha1 = [Security.Cryptography.SHA1]::Create()
    [void]$sha1.TransformBlock($header, 0, $header.Length, $null, 0)
    [void]$sha1.TransformFinalBlock($bytes, 0, $bytes.Length)
    ($sha1.Hash | ForEach-Object { $_.ToString('x2') }) -join ''
}

# What we downloaded last time: path -> git blob sha
$old = @{}
if (Test-Path -LiteralPath $manifestPath) {
    try { (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $old[$_.Name] = $_.Value } } catch { $old = @{} }
}

Write-Host ''
Write-Host '  SPARK Centre - checking for updates...' -ForegroundColor Cyan
try {
    $tree = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/git/trees/$($Branch)?recursive=1" `
        -Headers @{ 'User-Agent' = 'spark-usb-updater'; 'Accept' = 'application/vnd.github+json' } -TimeoutSec 15
} catch {
    Write-Host '  No internet (or GitHub is busy). Opening the copy on this USB.' -ForegroundColor Yellow
    if (Test-Path -LiteralPath (Join-Path $site 'index.html')) {
        $last = if (Test-Path -LiteralPath $manifestPath) { (Get-Item -LiteralPath $manifestPath).LastWriteTime.ToString('d MMM yyyy') } else { 'unknown' }
        Write-Version "offline $dot last updated $last"
    }
    exit 0
}
if ($tree.truncated) { Write-Host '  Warning: GitHub sent a partial file list.' -ForegroundColor Yellow }

# Skip hidden files/folders (.claude, .gitignore...) and this usb launcher folder.
$files = @($tree.tree | Where-Object { $_.type -eq 'blob' -and $_.path -notmatch '(^|/)\.' -and $_.path -notmatch '^usb/' })

$new = @{}
$todo = New-Object System.Collections.Generic.List[object]
foreach ($f in $files) {
    $new[$f.path] = $f.sha
    $local = Join-Path $site ($f.path -replace '/', '\')
    if (Test-Path -LiteralPath $local) {
        if ($old[$f.path] -eq $f.sha) { continue }
        if (-not $old.ContainsKey($f.path) -and (Get-BlobSha $local) -eq $f.sha) { continue }
    }
    $todo.Add($f)
}

$wc = New-Object Net.WebClient
$wc.Headers['User-Agent'] = 'spark-usb-updater'
$failed = 0; $i = 0
foreach ($f in $todo) {
    $i++
    $local = Join-Path $site ($f.path -replace '/', '\')
    $url = "https://raw.githubusercontent.com/$Repo/$Branch/" + (($f.path -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/')
    Write-Host ("  [{0}/{1}] {2}" -f $i, $todo.Count, $f.path)
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path $local) | Out-Null
        $part = "$local.part"
        $wc.DownloadFile($url, $part)
        Move-Item -LiteralPath $part -Destination $local -Force
        # GitHub's file cache can lag a few minutes behind; if so, try this file again next time.
        if ((Get-BlobSha $local) -ne $f.sha) { $new[$f.path] = 'retry' }
    } catch {
        $failed++
        Remove-Item -LiteralPath "$local.part" -ErrorAction SilentlyContinue
        if ($old.ContainsKey($f.path)) { $new[$f.path] = $old[$f.path] } else { $new.Remove($f.path) }
        Write-Host "      couldn't download: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Remove files that were deleted on GitHub (only ones this updater put there).
$removed = 0
foreach ($p in @($old.Keys)) {
    if (-not $new.ContainsKey($p)) {
        $local = Join-Path $site ($p -replace '/', '\')
        if (Test-Path -LiteralPath $local) { Remove-Item -LiteralPath $local -Force; $removed++ }
    }
}

[IO.File]::WriteAllText($manifestPath, ($new | ConvertTo-Json -Compress))

if ($todo.Count -eq 0 -and $removed -eq 0) {
    Write-Host '  Already up to date.' -ForegroundColor Green
    Write-Version "up to date $dot checked $(Get-Stamp)"
} elseif ($failed -gt 0) {
    Write-Host "  Updated, but $failed file(s) failed. They'll be tried again next time." -ForegroundColor Yellow
    Write-Version "partly updated $(Get-Stamp)"
} else {
    Write-Host "  Updated $($todo.Count) file(s), removed $removed." -ForegroundColor Green
    Write-Version "updated $(Get-Stamp)"
}
exit 0
