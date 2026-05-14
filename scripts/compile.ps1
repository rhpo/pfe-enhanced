# compile.ps1 - Optimized PFE compiler
# Usage:
#   .\scripts\compile.ps1              → PDF (single-pass, fast ~10s)
#   .\scripts\compile.ps1 -Format html → HTML only (~3s)
#   .\scripts\compile.ps1 -Final       → PDF with full 3-pass LaTeX (for submission)
#   .\scripts\compile.ps1 -Format all  → Both formats, full quality
param(
    [ValidateSet("html", "pdf", "all")]
    [string]$Format = "pdf",
    [switch]$Final
)

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host "  Compiling PFE Project (Quarto)" -ForegroundColor Cyan
Write-Host "  Format: $Format$(if ($Final) {' (final)'} else {' (fast)'})" -ForegroundColor Cyan
Write-Host "------------------------------------------" -ForegroundColor Cyan

$sw = [System.Diagnostics.Stopwatch]::StartNew()

# ── Step 1: Re-render PlantUML diagrams only if changed ──────────
$diagramsDir = Join-Path $PSScriptRoot "..\diagrams"
$javaExe     = "C:\Users\ramyh\scoop\apps\openjdk17\current\bin\java.exe"
$plantumlJar = "C:\Users\ramyh\Documents\plantuml.jar"

if (Test-Path $diagramsDir) {
    $needsRender = $false
    $pumlFiles = Get-ChildItem -Path $diagramsDir -Filter "*.puml"

    foreach ($f in $pumlFiles) {
        $png = Join-Path $diagramsDir "$($f.BaseName).png"
        if ((-not (Test-Path $png)) -or ($f.LastWriteTime -gt (Get-Item $png).LastWriteTime)) {
            $needsRender = $true
            break
        }
    }

    if ($needsRender -and $pumlFiles.Count -gt 0) {
        Write-Host "[1/2] Rendering diagrams..." -ForegroundColor Yellow
        & $javaExe -jar $plantumlJar -charset UTF-8 -tpng "$diagramsDir\*.puml" 2>&1 | Out-Null
        Write-Host "      Diagrams OK" -ForegroundColor Green
    } else {
        Write-Host "[1/2] Diagrams up-to-date (skipped)" -ForegroundColor DarkGray
    }
}

# ── Step 2: Clean stale artifacts ────────────────────────────────
@("index.tex", "index.log") | ForEach-Object {
    if (Test-Path $_) { Remove-Item $_ }
}

# ── Step 3: Quarto render ────────────────────────────────────────
$quartoArgs = @("render", "index.qmd")

if ($Format -ne "all") {
    $quartoArgs += "--to"
    $quartoArgs += $Format
}

# Fast mode: single LaTeX pass (~10s instead of ~30s)
if (-not $Final -and ($Format -eq "pdf" -or $Format -eq "all")) {
    $quartoArgs += "-M"
    $quartoArgs += "latex-max-runs:2"
}

Write-Host "[2/2] Rendering $($Format.ToUpper())..." -ForegroundColor Yellow
& quarto @quartoArgs

$sw.Stop()
$elapsed = [math]::Round($sw.Elapsed.TotalSeconds, 1)

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Build succeeded in ${elapsed}s" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Build failed after ${elapsed}s" -ForegroundColor Red
}

Write-Host "------------------------------------------" -ForegroundColor Cyan
