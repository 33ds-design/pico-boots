# PowerShell equivalent of test_scripts.sh
# Test lua modules with busted
#
# Lua scripts must be written in pure Lua, i.e. they must not use PICO-8-specific syntax.
#
# Dependencies:
# - busted (must be in PATH)
# - luacov (must be in PATH)

[CmdletBinding(PositionalBinding=$false)]
param(
    [Parameter()]
    [Alias("f")]
    [string]$File = "",

    [Parameter()]
    [Alias("m")]
    [ValidateSet("", "solo", "all")]
    [string]$FilterMode = "",

    [Parameter()]
    [switch]$MuteAll,

    [Parameter()]
    [string]$Filter = "",

    [Parameter()]
    [string]$FilterOut = "",

    [Parameter()]
    [Alias("l")]
    [string]$LuaRoot = "",

    [Parameter()]
    [Alias("c")]
    [string]$CovConfig = "",

    [Parameter()]
    [switch]$Coverage,

    [Parameter()]
    [Alias("h")]
    [switch]$Help,

    # Positional arguments: root folders containing test scripts
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Roots = @()
)

function Show-Help {
    Write-Host @"
Test lua modules with busted

Lua scripts must be written in pure Lua, i.e. they must not use PICO-8-specific syntax.

Dependencies:
- busted (must be in PATH)
- luacov (must be in PATH)

Usage: test_scripts.ps1 [ROOT-1 [ROOT-2 [...]]]

ARGUMENTS
  ROOT                      Path to folder containing test scripts.
                            Path is relative to the current working directory.
                            The full relative path to a specific test file can also
                            be passed, but it is recommended to use the -f option instead
                            to benefit from the automated test detection/targeted coverage.
                            If no folder is defined, the current working directory is tested.
                            (this differs from busted which requires '.' to be passed)
                            Ex: 'src/engine/application'
                            (optional, default: single root '.')

OPTIONS
  -f, -File FILE_BASE_NAME  Basename of either the Lua source file (module) to test or
                            of the test itself.
                            If FILE_BASE_NAME ends with '_utest', it is stripped
                            to define the module name.
                            Else, it is directly used as module name.
                            A test file named '`${MODULE}_utest.lua' should exist
                            somewhere under the ROOTs.
                            If empty, all test files found in the ROOTs are tested.
                            It is recommended to give a different name to every module
                            present under the ROOTS to avoid incorrect test detection/
                            targeted coverage.
                            Ex: 'flow', 'flow_utest'
                            (default: '')

  -m, -FilterMode MODE      Filter mode.
                            '' to filter out #mute (useful to skip WIP tests)
                            'solo' to filter #solo (useful to focus on a specific test)
                            'all' for no filters (include #mute compared to '')
                            (default: '')

  -MuteAll                  Equivalent to -m all. Include #mute tests.

  -Filter PATTERN           Pass a --filter argument directly to busted.
                            Overrides FilterMode-derived filter if set.

  -FilterOut PATTERN        Pass a --filter-out argument directly to busted.
                            Overrides FilterMode-derived filter-out if set.

  -l, -LuaRoot EXTRA_LUA_ROOT
                            Lua root used besides engine source directory for lua_path.
                            Add one if you are testing scripts outside the engine source
                            directory, that require other scripts from a given root.
                            Typically, this is your game source directory.

  -c, -CovConfig COVERAGE_CONFIG
                            Path to Luacov configuration file to use.
                            Path is relative to current working directory.

  -Coverage                 Force enable coverage even when FilterMode would disable it
                            (e.g. in 'solo' mode).

  -h, -Help                 Show this help message
"@
}

if ($Help) {
    Show-Help
    exit 0
}

$ErrorActionPreference = "Stop"

# Configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$picobootsSrcPath = Resolve-Path (Join-Path $scriptPath "../src")
$picobootsScriptsPath = $scriptPath

# Handle -MuteAll as alias for -m all
if ($MuteAll) {
    $FilterMode = "all"
}

# Default to current directory if no roots specified
if ($Roots.Count -eq 0) {
    $Roots = @(".")
}

# Determine module name from file base name
$module = ""
if ($File -ne "") {
    if ($File.EndsWith("_utest")) {
        $module = $File.Substring(0, $File.Length - 6)
    } else {
        $module = $File
    }
}

# Determine test file pattern and coverage options
if ($module -eq "") {
    # No specific file to test, test them all (inside target project directories)
    $testFilePattern = "_utest%.lua`$"

    # Cover exactly the roots you are testing
    # Escape pattern symbols like with '%' for luacov (as in .luacov_game)
    # The most common one is '-' (as in "pico-boots"), but '*', '+', '?', '[', ']' and '%' must also be escaped
    # See http://www.lua.org/manual/5.1/manual.html#5.4.1
    # ex: "pico-boots/src/engine" -> "pico%-boots/src/engine"
    $coverageOptions = @()
    foreach ($root in $Roots) {
        $escaped = $root -replace '([-*+?\[\]])', '%$1'
        $coverageOptions += $escaped
    }

    # For logging
    $moduleStr = "all modules"
} else {
    # Test specific module with exact full name to avoid issues with similar file names
    # (busted uses Lua string.match where escaping is done with '%')
    $testFilePattern = "^${module}_utest%.lua`$"

    # luacov filter will ignore any trailing '.lua', so we need to add end symbol '$' just after module name
    # to avoid confusion with similar file names.
    # The final '$' will prevent detecting folder with the same name (e.g. ui.lua vs ui/) since all folders continue with '/'.
    # Modules with the exact same name will still be covered together, so make sure to name your modules differently
    # (even between engine and game), as recommended in the Usage.
    $coverageOptions = @("/${module}`$")

    # For logging
    $moduleStr = "module $module"
}

# Determine filter arguments and whether to use coverage
$filterArg = ""
$filterOutArg = ""
$useCoverage = $true

switch ($FilterMode) {
    "all" {
        $filterArg = ""
        $filterOutArg = ""
        $useCoverage = $true
    }
    "solo" {
        $filterArg = '#solo'
        $filterOutArg = ""
        $useCoverage = $false  # coverage on a file is not relevant when testing one or two functions
    }
    default {
        $filterArg = ""
        $filterOutArg = '#mute'  # by default, skip #mute (flag your WIP tests #mute to avoid error/failure spam)
        $useCoverage = $true
    }
}

# Override with explicit -Filter / -FilterOut if provided
if ($Filter -ne "") {
    $filterArg = $Filter
}
if ($FilterOut -ne "") {
    $filterOutArg = $FilterOut
}

# -Coverage flag forces coverage on
if ($Coverage) {
    $useCoverage = $true
}

Write-Host "Testing $moduleStr in: $($Roots -join ' ')..."

# Always give access to engine modules
$luaPath = Join-Path $picobootsSrcPath "?.lua"

# Add access to custom (game) modules if testing external source
if ($LuaRoot -ne "") {
    $extraPath = Join-Path (Get-Location) "$LuaRoot/?.lua"
    $luaPath += ";$extraPath"
}

# Set LUA_PATH environment variable
$env:LUA_PATH = "$luaPath;"

# Pre-test: clean previous coverage files
if ($useCoverage) {
    Remove-Item -Path "luacov.stats.out", "luacov.report.out" -ErrorAction SilentlyContinue
}

# Build busted arguments
$bustedArgs = @()
$bustedArgs += $Roots
$bustedArgs += "--lpath=`"$luaPath`""
$bustedArgs += "-p=`"$testFilePattern`""

if ($filterArg -ne "") {
    $bustedArgs += "--filter"
    $bustedArgs += $filterArg
}

if ($filterOutArg -ne "") {
    $bustedArgs += "--filter-out"
    $bustedArgs += $filterOutArg
}

if ($useCoverage) {
    $bustedArgs += "-c"
}

$bustedArgs += "-v"

# Build display command
$displayCmd = "busted $($bustedArgs -join ' ')"
Write-Host "> $displayCmd"

# Run busted
& busted @bustedArgs
$testResult = $LASTEXITCODE

# Post-test: generate luacov report if tests passed and coverage is enabled
if ($useCoverage -and $testResult -eq 0) {
    Write-Host ""
    Write-Host "Generating coverage report..."

    $luacovArgs = @()
    if ($coverageOptions.Count -gt 0) {
        $luacovArgs += $coverageOptions
    }
    if ($CovConfig -ne "") {
        $luacovArgs += "-c"
        $luacovArgs += $CovConfig
    }

    $luacovDisplay = "luacov $($luacovArgs -join ' ')"
    Write-Host "> $luacovDisplay"

    & luacov @luacovArgs
    $luacovResult = $LASTEXITCODE

    if ($luacovResult -eq 0 -and (Test-Path "luacov.report.out")) {
        Write-Host ""
        Write-Host "=== COVERAGE REPORT ==="
        Write-Host ""
        # Show lines with *0 (uncovered) and percentages
        Get-Content "luacov.report.out" | Select-String -Pattern '(^\*0| [*]0|\d+%$|Total:)' -Context 1, 1 | ForEach-Object {
            Write-Host $_.Line
        }
    }
}

exit $testResult
