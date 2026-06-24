# Barter Load Test - PowerShell Runner
#
# Usage:
#   .\tools\load_test\run_load_test.ps1              (full ramp-up, ~12 min)
#   .\tools\load_test\run_load_test.ps1 -Scenario smoke   (quick 1-min smoke test)
#   .\tools\load_test\run_load_test.ps1 -Scenario spike   (spike burst test)
#   .\tools\load_test\run_load_test.ps1 -ScenarioFile 04_trade  (single scenario)
#
# Env vars used:
#   FIREBASE_API_KEY       - Firebase Web API Key
#   FIREBASE_PROJECT_ID    - Firebase project ID (default: barter-30a05)
#   PAYMOB_WEBHOOK_URL     - Optional: deployed Cloud Function URL for webhook test

param(
    [ValidateSet('default', 'smoke', 'spike')]
    [string]$Scenario = 'default',

    [string]$ScenarioFile = '',

    [switch]$JsonOutput,
    [switch]$SkipPrecheck
)

$ErrorActionPreference = 'Stop'

# -- Configuration -------------------------------------------------------------
$API_KEY = $env:FIREBASE_API_KEY
if (-not $API_KEY) {
    $API_KEY = 'AIzaSyDpLwQQpMlyMEyEZFi2YC-xKiQvA_TuX4E'
}

$PROJECT_ID = $env:FIREBASE_PROJECT_ID
if (-not $PROJECT_ID) {
    $PROJECT_ID = 'barter-30a05'
}

$WEBHOOK_URL = $env:PAYMOB_WEBHOOK_URL
if (-not $WEBHOOK_URL) {
    $WEBHOOK_URL = ''
}

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ResultsDir  = Join-Path $ScriptDir 'results'
$Timestamp   = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$JsonFile    = Join-Path $ResultsDir "results_${Scenario}_${Timestamp}.json"
$SummaryFile = Join-Path $ResultsDir "summary_${Scenario}_${Timestamp}.txt"

# -- Banner --------------------------------------------------------------------
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   Barter App - k6 Load Test Runner                  " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Scenario  : $Scenario" -ForegroundColor Yellow
Write-Host "  Project   : $PROJECT_ID" -ForegroundColor Yellow
Write-Host "  Timestamp : $Timestamp" -ForegroundColor Yellow
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# -- Pre-checks ----------------------------------------------------------------
if (-not $SkipPrecheck) {
    Write-Host "[INFO] Running pre-checks..." -ForegroundColor Blue

    # 1. Resolve k6 executable (check PATH first, then winget default install location)
    $k6Exe = Get-Command k6 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $k6Exe) {
        $fallback = 'C:\Program Files\k6\k6.exe'
        if (Test-Path $fallback) {
            $k6Exe = $fallback
            Write-Host "   [OK] k6 found at: $k6Exe (not yet on PATH - open a new terminal to fix)" -ForegroundColor Green
        } else {
            Write-Host "   [ERROR] k6 not found. Install via: winget install k6" -ForegroundColor Red
            Write-Host "      Then open a new PowerShell window and try again." -ForegroundColor Yellow
            exit 1
        }
    } else {
        $k6Version = & $k6Exe version 2>&1
        Write-Host "   [OK] k6 found: $k6Version" -ForegroundColor Green
    }

    # 2. Check API key is set
    if ([string]::IsNullOrEmpty($API_KEY)) {
        Write-Host "   [ERROR] FIREBASE_API_KEY is not set." -ForegroundColor Red
        Write-Host "      Set it with: `$env:FIREBASE_API_KEY = 'your-key'" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "   [OK] Firebase API key: $($API_KEY.Substring(0,12))..." -ForegroundColor Green

    # 3. Warn if webhook URL is missing
    if ([string]::IsNullOrEmpty($WEBHOOK_URL)) {
        Write-Host "   [WARN] PAYMOB_WEBHOOK_URL not set - scenario 06_payment will be skipped." -ForegroundColor Yellow
    } else {
        Write-Host "   [OK] Paymob webhook URL configured." -ForegroundColor Green
    }

    # 4. Create results directory
    if (-not (Test-Path $ResultsDir)) {
        New-Item -ItemType Directory -Path $ResultsDir | Out-Null
        Write-Host "   [OK] Created results directory: $ResultsDir" -ForegroundColor Green
    }

    Write-Host ""
}

# -- Select target scenario file -----------------------------------------------
if ($ScenarioFile -ne '') {
    # Run a single scenario
    $TargetFile = Join-Path $ScriptDir "scenarios\${ScenarioFile}.js"
    if (-not (Test-Path $TargetFile)) {
        Write-Host "[ERROR] Scenario file not found: $TargetFile" -ForegroundColor Red
        exit 1
    }
} else {
    # Run the full journey (default)
    $TargetFile = Join-Path $ScriptDir 'scenarios\08_full_journey.js'
}

Write-Host "[INFO] Starting k6 load test..." -ForegroundColor Green
Write-Host "   Target: $TargetFile" -ForegroundColor Gray
Write-Host "   Results will be saved to: $ResultsDir" -ForegroundColor Gray
Write-Host ""

# -- Build k6 command ----------------------------------------------------------
$k6Args = @(
    'run',
    '--env', "FIREBASE_API_KEY=$API_KEY",
    '--env', "FIREBASE_PROJECT_ID=$PROJECT_ID",
    '--env', "SCENARIO=$Scenario"
)

if ($WEBHOOK_URL -ne '') {
    $k6Args += '--env', "PAYMOB_WEBHOOK_URL=$WEBHOOK_URL"
}

if ($JsonOutput -or $Scenario -ne 'smoke') {
    $k6Args += '--out', "json=$JsonFile"
}

$k6Args += '--summary-export', $SummaryFile
$k6Args += $TargetFile

$k6Exe = if ($k6Exe) { $k6Exe } else {
    $candidate = 'C:\Program Files\k6\k6.exe'
    if (Test-Path $candidate) { $candidate } else { 'k6' }
}

# -- Execute -------------------------------------------------------------------
try {
    & $k6Exe @k6Args
    $exitCode = $LASTEXITCODE
} catch {
    Write-Host "[ERROR] k6 execution failed: $_" -ForegroundColor Red
    exit 1
}

# -- Results summary -----------------------------------------------------------
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
if ($exitCode -eq 0) {
    Write-Host "   [OK] Load test PASSED - all thresholds met!" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Load test FAILED - one or more thresholds breached." -ForegroundColor Red
    Write-Host "   Check the results below and in Firebase Console." -ForegroundColor Yellow
}
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[INFO] Results saved to:" -ForegroundColor Blue
Write-Host "   JSON   : $JsonFile" -ForegroundColor Gray
Write-Host "   Summary: $SummaryFile" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO] Firebase Console links:" -ForegroundColor Blue
Write-Host "   Firestore Usage  : https://console.firebase.google.com/project/$PROJECT_ID/firestore/usage" -ForegroundColor Gray
Write-Host "   Functions Logs   : https://console.firebase.google.com/project/$PROJECT_ID/functions/logs" -ForegroundColor Gray
Write-Host "   Auth Users       : https://console.firebase.google.com/project/$PROJECT_ID/authentication/users" -ForegroundColor Gray
Write-Host ""
Write-Host "[INFO] To clean up leftover load-test data:" -ForegroundColor Blue
Write-Host "   node tools\load_test\cleanup.js --key path/to/serviceAccountKey.json" -ForegroundColor Gray
Write-Host ""

exit $exitCode
