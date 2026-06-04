# Cold Turkey Protect
# Prevents Cold Turkey from being uninstalled or removed.
# Run as Administrator.

$ErrorActionPreference = "Stop"

function Write-Status($msg) { Write-Host "  $msg" -ForegroundColor Cyan }
function Write-OK($msg)     { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)   { Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Fail($msg)   { Write-Host "  [X]  $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "==============================" -ForegroundColor White
Write-Host "   Cold Turkey Protect v1.0   " -ForegroundColor White
Write-Host "==============================" -ForegroundColor White
Write-Host ""

# --- Check admin ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Fail "Dit script moet als Administrator worden uitgevoerd."
    Write-Host "  Rechtsklik op 'Uitvoeren als administrator' en probeer opnieuw." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Druk op Enter om af te sluiten"
    exit 1
}

# --- Find Cold Turkey ---
Write-Status "Cold Turkey zoeken..."

$installPath = $null
$commonPaths = @(
    "C:\Program Files\Cold Turkey",
    "C:\Program Files (x86)\Cold Turkey"
)
foreach ($p in $commonPaths) {
    if (Test-Path "$p\Cold Turkey Blocker.exe") {
        $installPath = $p
        break
    }
}

if (-not $installPath) {
    Write-Fail "Cold Turkey niet gevonden. Is het geinstalleerd?"
    Write-Host ""
    Read-Host "  Druk op Enter om af te sluiten"
    exit 1
}

Write-OK "Gevonden op: $installPath"
Write-Host ""

# --- 1. Blokkeer verwijderen van de installatiemap ---
Write-Status "Beschermen: Cold Turkey map (verwijderen blokkeren)..."
try {
    icacls $installPath /deny "Everyone:(D,DC)" /T /Q | Out-Null
    Write-OK "Map is nu beveiligd tegen verwijdering."
} catch {
    Write-Fail "Kon map niet beveiligen: $_"
}

# --- 2. Blokkeer uitvoering uninstaller ---
$uninstaller = "$installPath\unins000.exe"
if (Test-Path $uninstaller) {
    Write-Status "Beschermen: uninstaller blokkeren..."
    try {
        icacls $uninstaller /deny "Everyone:(X)" /Q | Out-Null
        Write-OK "Uninstaller is geblokkeerd."
    } catch {
        Write-Fail "Kon uninstaller niet blokkeren: $_"
    }
} else {
    Write-Warn "Uninstaller niet gevonden (overgeslagen)."
}

# --- 3. Zoek en blokkeer removal tools op schijf ---
Write-Status "Zoeken naar Cold Turkey Removal Tools..."

$searchLocations = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:PUBLIC\Downloads",
    "$env:PUBLIC\Desktop"
)

$blocked = 0
foreach ($loc in $searchLocations) {
    if (-not (Test-Path $loc)) { continue }
    $tools = Get-ChildItem $loc -Filter "Blocker_Removal_Tool*.exe" -ErrorAction SilentlyContinue
    foreach ($tool in $tools) {
        try {
            icacls $tool.FullName /deny "Everyone:(X)" /Q | Out-Null
            Write-OK "Geblokkeerd: $($tool.Name)"
            $blocked++
        } catch {
            Write-Warn "Kon niet blokkeren: $($tool.Name)"
        }
    }
}

if ($blocked -eq 0) {
    Write-OK "Geen removal tools gevonden op bekende locaties."
}

# --- Klaar ---
Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "   Bescherming actief!        " -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""
Write-Host "  Cold Turkey kan nu niet meer worden verwijderd." -ForegroundColor White
Write-Host "  Veel succes!" -ForegroundColor White
Write-Host ""
Read-Host "  Druk op Enter om af te sluiten"
