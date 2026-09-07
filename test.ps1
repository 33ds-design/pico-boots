# PowerShell test runner for pico-boots (Windows equivalent of test.sh)
# Usage:
#   .\test.ps1                    # Run all tests (excluding #mute)
#   .\test.ps1 -FilterMode all    # Run all tests including #mute
#   .\test.ps1 -FilterMode solo   # Run only #solo tests
#   .\test.ps1 -Folder core       # Run tests for a specific engine subfolder

param(
    [Parameter(Position=0)]
    [string]$Folder,

    [Parameter()]
    [ValidateSet('all', 'solo', 'default', '')]
    [string]$FilterMode = 'default',

    [switch]$Help
)

if ($Help) {
    Write-Host @"
Test pico-boots modules with busted (Windows PowerShell version)

Usage:
    .\test.ps1 [options]

Options:
    -Folder <name>       Engine subfolder to test (e.g. 'core', 'physics').
                         Path is relative to src/engine. Sub-folders supported.
                         If omitted, all engine folders are tested.

    -FilterMode <mode>   Filter mode:
                         'default' - Skip #mute tests (default)
                         'all'     - Include all tests (including #mute)
                         'solo'    - Only run #solo tests

    -Help                Show this help message

Dependencies:
    - busted (must be in PATH)
    - luacov (must be in PATH)
"@
    exit 0
}

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$srcEnginePath = Join-Path $projectRoot "src/engine"
$luaPath = Join-Path $projectRoot "src/?.lua"
$coverageConfig = Join-Path $projectRoot "config/.luacov_engine"

# Determine test root
if ($Folder) {
    $testRoot = Join-Path $srcEnginePath $Folder
} else {
    $testRoot = $srcEnginePath
}

# Set filter options
$filterArgs = ""
$useCoverage = $true

switch ($FilterMode) {
    'all' {
        $filterArgs = ""
        $useCoverage = $true
    }
    'solo' {
        $filterArgs = '--filter "#solo"'
        $useCoverage = $false
    }
    default {
        $filterArgs = '--filter-out "#mute"'
        $useCoverage = $true
    }
}

# Set environment variable for Lua module path
$env:LUA_PATH = "$luaPath;"

# Clean previous coverage files
if ($useCoverage) {
    Remove-Item -Path "luacov.stats.out", "luacov.report.out" -ErrorAction SilentlyContinue
}

# Build and run test command
$testPattern = "_utest%.lua$"
$bustedArgs = @(
    $testRoot,
    "--lpath=`"$luaPath`"",
    "-p=`"$testPattern`""
)
if ($filterArgs) {
    $bustedArgs += $filterArgs
}
if ($useCoverage) {
    $bustedArgs += "-c"
}
$bustedArgs += "-v"

Write-Host "Testing in: $testRoot"
$bustedCmd = "busted $($bustedArgs -join ' ')"
Write-Host "> $bustedCmd"

& busted @bustedArgs
$testResult = $LASTEXITCODE

# Generate coverage report
if ($useCoverage -and $testResult -eq 0) {
    Write-Host ""
    Write-Host "Generating coverage report..."
    & luacov -c $coverageConfig
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=== COVERAGE REPORT ==="
        Write-Host ""
        Get-Content "luacov.report.out" | Select-String -Pattern "Total:|\d+\.\d+%$" | ForEach-Object { Write-Host $_.Line }
    }
}

exit $testResult
