# setup-diagrams.ps1
# One-time: extract inline PlantUML from ch3/main.qmd -> .puml files,
# render them to PNG, and replace inline blocks with static image refs.

$ErrorActionPreference = "Stop"

$qmdFile     = Join-Path $PSScriptRoot "..\chapters\ch3\main.qmd"
$outDir      = Join-Path $PSScriptRoot "..\diagrams"
$javaExe     = "C:\Users\ramyh\scoop\apps\openjdk17\current\bin\java.exe"
$plantumlJar = "C:\Users\ramyh\Documents\plantuml.jar"

# Pre-flight checks
if (-not (Test-Path $javaExe))     { Write-Error "Java not found at $javaExe"; exit 1 }
if (-not (Test-Path $plantumlJar)) { Write-Error "PlantUML not found at $plantumlJar"; exit 1 }
if (-not (Test-Path $qmdFile))     { Write-Error "QMD not found at $qmdFile"; exit 1 }

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

Write-Host "`n=== Extracting PlantUML diagrams ===" -ForegroundColor Cyan

$names = @(
    "uc-etudiant"
    "uc-enseignant"
    "uc-administration"
    "dc-classes"
    "seq-authentification"
    "seq-soumission-fiche"
    "seq-fiche-suivi"
    "seq-jury-planification"
    "seq-resultat-soutenance"
    "etat-pfe"
    "etat-fiche-suivi"
    "act-global"
)

$captions = @(
    "Cas d'utilisation de l'étudiant"
    "Cas d'utilisation de l'enseignant encadrant"
    "Cas d'utilisation de l'administration"
    "Diagramme de classes du système"
    "Séquence - Authentification"
    "Séquence - Soumission et validation d'une fiche PFE"
    "Séquence - Renseignement d'une fiche de suivi"
    "Séquence - Constitution du jury et planification"
    "Séquence - Enregistrement du résultat de soutenance"
    "Diagramme d'états - Cycle de vie d'un PFE"
    "Diagramme d'états - Cycle de vie d'une FicheSuiviPFE"
    "Diagramme d'activité global du processus PFE"
)

$closingFence = '`' + '`' + '`'

# Read file
$lines    = [System.IO.File]::ReadAllLines($qmdFile, [System.Text.Encoding]::UTF8)
$newLines = [System.Collections.Generic.List[string]]::new()
$blockBuf = [System.Collections.Generic.List[string]]::new()
$inBlock  = $false
$idx      = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    if ((-not $inBlock) -and ($line -match '^\s*```\{\.plantuml')) {
        $inBlock = $true
        $blockBuf.Clear()
        continue
    }

    if ($inBlock -and ($line.Trim() -eq $closingFence)) {
        # Save .puml
        $pumlPath = Join-Path $outDir "$($names[$idx]).puml"
        [System.IO.File]::WriteAllLines($pumlPath, $blockBuf.ToArray(), [System.Text.Encoding]::UTF8)
        Write-Host "  [+] $($names[$idx]).puml  ($($blockBuf.Count) lines)" -ForegroundColor Green

        # Insert image reference instead of inline block
        $newLines.Add("![$($captions[$idx])](/diagrams/$($names[$idx]).png){width=`"100%`"}")

        $idx++
        $inBlock = $false
        continue
    }

    if ($inBlock) {
        $blockBuf.Add($line)
    } else {
        $newLines.Add($line)
    }
}

Write-Host "`n  Extracted $idx / $($names.Count) diagrams" -ForegroundColor Yellow

# Write updated QMD
[System.IO.File]::WriteAllLines($qmdFile, $newLines.ToArray(), [System.Text.Encoding]::UTF8)
Write-Host "  [OK] Updated ch3/main.qmd" -ForegroundColor Green

# Render all .puml to .png
Write-Host "`n=== Rendering diagrams to PNG ===" -ForegroundColor Cyan

$pumlFiles = Get-ChildItem -Path $outDir -Filter "*.puml"
foreach ($f in $pumlFiles) {
    Write-Host "  Rendering $($f.Name) ..." -NoNewline -ForegroundColor Yellow
    & $javaExe -jar $plantumlJar -charset UTF-8 -tpng $f.FullName 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

Write-Host "`n=== Done! ===" -ForegroundColor Cyan
Write-Host "  $idx diagrams extracted and rendered to $outDir" -ForegroundColor Green
Write-Host "  ch3/main.qmd updated with static image references" -ForegroundColor Green
Write-Host "  You can now run: .\scripts\compile.ps1" -ForegroundColor Yellow
