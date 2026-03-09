# compile.ps1
# Simple script to render the Quarto project to PDF and HTML

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host "  Compiling PFE Project (Quarto)" -ForegroundColor Cyan
Write-Host "------------------------------------------" -ForegroundColor Cyan

# 1. Clean previous build artifacts if any
if (Test-Path "index.tex") { Remove-Item "index.tex" }
if (Test-Path "index.log") { Remove-Item "index.log" }

# 2. Render to PDF
Write-Host "[1/2] Generating PDF..." -ForegroundColor Yellow
quarto render index.qmd --to pdf

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] PDF generated successfully." -ForegroundColor Green
} else {
    Write-Host "[ERROR] PDF generation failed." -ForegroundColor Red
}

# 3. Render to HTML
Write-Host "[2/2] Generating HTML..." -ForegroundColor Yellow
quarto render index.qmd --to html

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] HTML generated successfully." -ForegroundColor Green
} else {
    Write-Host "[ERROR] HTML generation failed." -ForegroundColor Red
}

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host "Done." -ForegroundColor Cyan
