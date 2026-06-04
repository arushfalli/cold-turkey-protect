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
    Write-Fail "This script must be run as Administrator."
    Write-Host "  Right-click the file and select 'Run as administrator'." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit 1
}

# --- Find Cold Turkey ---
Write-Status "Looking for Cold Turkey..."

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
    Write-Fail "Cold Turkey not found. Is it installed?"
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit 1
}

Write-OK "Found at: $installPath"
Write-Host ""

# --- 1. Block deletion of the installation folder ---
Write-Status "Protecting: Cold Turkey folder (blocking deletion)..."
try {
    icacls $installPath /deny "Everyone:(D,DC)" /T /Q | Out-Null
    Write-OK "Folder is now protected against deletion."
} catch {
    Write-Fail "Could not protect folder: $_"
}

# --- 2. Block execution of the uninstaller ---
$uninstaller = "$installPath\unins000.exe"
if (Test-Path $uninstaller) {
    Write-Status "Protecting: blocking uninstaller..."
    try {
        icacls $uninstaller /deny "Everyone:(X)" /Q | Out-Null
        Write-OK "Uninstaller is blocked."
    } catch {
        Write-Fail "Could not block uninstaller: $_"
    }
} else {
    Write-Warn "Uninstaller not found (skipped)."
}

# --- 3. Find and block removal tools on disk ---
Write-Status "Searching for Cold Turkey Removal Tools..."

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
            Write-OK "Blocked: $($tool.Name)"
            $blocked++
        } catch {
            Write-Warn "Could not block: $($tool.Name)"
        }
    }
}

if ($blocked -eq 0) {
    Write-OK "No removal tools found in common locations."
}

# --- Done ---
Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "   Protection active!         " -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""
Write-Host "  Cold Turkey can no longer be uninstalled." -ForegroundColor White
Write-Host "  Good luck!" -ForegroundColor White
Write-Host ""
Read-Host "  Press Enter to exit"
