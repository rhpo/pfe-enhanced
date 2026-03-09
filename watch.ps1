# quarto-watch.ps1
# Polls all .qmd and .yml files every second for changes.
# On change: runs full quarto render, then triggers live-server reload.
#
# Requirements: npm install -g live-server
# Usage: .\quarto-watch.ps1

param(
    [string]$ProjectDir = (Get-Location).Path,
    [string]$OutputDir  = ".",
    [int]   $Port       = 5500,
    [int]   $PollMs     = 1000
)

$fullOutputDir = if ($OutputDir -eq ".") { $ProjectDir } else { Join-Path $ProjectDir $OutputDir }
$triggerFile   = Join-Path $fullOutputDir ".reload-trigger.html"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Quarto Full-Project Watcher (polling)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Project : $ProjectDir" -ForegroundColor Yellow
Write-Host "  Serving : $fullOutputDir" -ForegroundColor Yellow
Write-Host "  URL     : http://localhost:$Port" -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

# --- Check live-server ---
if (-not (Get-Command "live-server" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] live-server not found. Run: npm install -g live-server" -ForegroundColor Red
    exit 1
}

# --- Initial render ---
Write-Host "[INFO] Running initial render..." -ForegroundColor Yellow
& quarto render --to html 2>&1 | ForEach-Object { Write-Host "  $_" }
Write-Host "[OK]     Initial render complete." -ForegroundColor Green

# --- Write trigger file ---
"<!-- reload -->" | Set-Content $triggerFile

# --- Start live-server watching only the trigger file ---
Write-Host "[INFO] Starting live-server at http://localhost:$Port ..." -ForegroundColor Green
$liveServer = Start-Process "cmd.exe" `
    -ArgumentList "/c live-server `"$fullOutputDir`" --port=$Port --no-browser --watch=`".reload-trigger.html`"" `
    -PassThru -NoNewWindow

Start-Sleep -Seconds 2
Write-Host "[READY] Open http://localhost:$Port" -ForegroundColor Cyan
Write-Host ""

# --- Build initial snapshot of all .qmd and .yml LastWriteTimes ---
function Get-SourceSnapshot {
    Get-ChildItem -Path $ProjectDir -Recurse -Include "*.qmd","*.yml" |
        Where-Object { $_.FullName -notmatch '\\_|\\.quarto|_freeze' } |
        ForEach-Object { @{ Path = $_.FullName; LastWrite = $_.LastWriteTimeUtc } }
}

$snapshot = @{}
Get-SourceSnapshot | ForEach-Object { $snapshot[$_.Path] = $_.LastWrite }
Write-Host "[WATCHING] $($snapshot.Count) source files..." -ForegroundColor Green
Write-Host ""

# --- Poll loop ---
try {
    while ($true) {
        Start-Sleep -Milliseconds $PollMs

        $changed = $null
        Get-SourceSnapshot | ForEach-Object {
            $path      = $_.Path
            $lastWrite = $_.LastWrite
            if (-not $snapshot.ContainsKey($path) -or $snapshot[$path] -ne $lastWrite) {
                $changed = $path
                $snapshot[$path] = $lastWrite
            }
        }

        if ($changed) {
            $rel = $changed.Replace($ProjectDir, "").TrimStart("\")
            Write-Host "[CHANGE] $rel" -ForegroundColor Magenta
            Write-Host "[INFO]   Rendering..." -ForegroundColor Yellow

            & quarto render --to html 2>&1 | ForEach-Object { Write-Host "  $_" }

            Write-Host "[OK]     Done. Reloading browser..." -ForegroundColor Green
            "<!-- $(Get-Date) -->" | Set-Content $triggerFile
        }
    }
} finally {
    Write-Host ""
    Write-Host "[STOP] Shutting down..." -ForegroundColor Yellow
    if (-not $liveServer.HasExited) {
        Stop-Process -Id $liveServer.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[DONE] Stopped." -ForegroundColor Cyan
}
