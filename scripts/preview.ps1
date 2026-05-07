# preview.ps1
# Live PDF preview: watches .qmd files, recompiles on change, auto-refreshes in SumatraPDF.
# Usage: .\scripts\preview.ps1
# Press Ctrl+C to stop.

param(
    [int]$PollMs = 1000
)

$projectDir  = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pdfPath     = Join-Path $projectDir "index.pdf"
$compileScript = Join-Path $PSScriptRoot "compile.ps1"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  PFE Live PDF Preview" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Project : $projectDir" -ForegroundColor Yellow
Write-Host "  PDF     : $pdfPath" -ForegroundColor Yellow
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Yellow
Write-Host ""

# ── Initial compile ─────────────────────────────────────────────
Write-Host "[INFO] Initial compile..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File $compileScript 2>&1 | ForEach-Object { Write-Host "  $_" }

if (-not (Test-Path $pdfPath)) {
    Write-Host "[ERROR] PDF not found at $pdfPath. Fix compile errors first." -ForegroundColor Red
    exit 1
}

# ── Open PDF in SumatraPDF (auto-reloads on file change) ────────
$sumatra = Get-Command "sumatrapdf" -ErrorAction SilentlyContinue
if ($sumatra) {
    Write-Host "[INFO] Opening PDF in SumatraPDF..." -ForegroundColor Green
    Start-Process "sumatrapdf" -ArgumentList "`"$pdfPath`"" -NoNewWindow
} else {
    Write-Host "[WARN] SumatraPDF not found. Install it: scoop install sumatrapdf" -ForegroundColor Yellow
    Write-Host "       Opening with default viewer (may lock the file)..." -ForegroundColor Yellow
    Start-Process $pdfPath
}

# ── Build file snapshot ──────────────────────────────────────────
function Get-SourceSnapshot {
    Get-ChildItem -Path $projectDir -Recurse -Include "*.qmd","*.yml","*.tex","*.bib","*.puml" |
        Where-Object { $_.FullName -notmatch '\\\.quarto|_freeze|node_modules|\\\.git\\' } |
        ForEach-Object { @{ Path = $_.FullName; LastWrite = $_.LastWriteTimeUtc } }
}

$snapshot = @{}
Get-SourceSnapshot | ForEach-Object { $snapshot[$_.Path] = $_.LastWrite }
Write-Host "[WATCHING] $($snapshot.Count) source files..." -ForegroundColor Green
Write-Host ""

# ── Poll loop ────────────────────────────────────────────────────
try {
    while ($true) {
        Start-Sleep -Milliseconds $PollMs

        $changedFiles = @()
        Get-SourceSnapshot | ForEach-Object {
            $path      = $_.Path
            $lastWrite = $_.LastWrite
            if (-not $snapshot.ContainsKey($path) -or $snapshot[$path] -ne $lastWrite) {
                $changedFiles += $path
                $snapshot[$path] = $lastWrite
            }
        }

        if ($changedFiles.Count -gt 0) {
            $rel = $changedFiles[0].Replace($projectDir, "").TrimStart("\")
            $extra = if ($changedFiles.Count -gt 1) { " (+$($changedFiles.Count - 1) more)" } else { "" }
            Write-Host "[CHANGE] $rel$extra" -ForegroundColor Magenta
            Write-Host "[INFO]   Recompiling..." -ForegroundColor Yellow

            & powershell -ExecutionPolicy Bypass -File $compileScript 2>&1 | ForEach-Object { Write-Host "  $_" }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK]     PDF updated. SumatraPDF will auto-refresh." -ForegroundColor Green
            } else {
                Write-Host "[ERROR]  Compile failed. Fix errors and save again." -ForegroundColor Red
            }
            Write-Host ""
        }
    }
} finally {
    Write-Host ""
    Write-Host "[STOP] Preview ended." -ForegroundColor Cyan
}
