-- Cross-platform coverage report generator for pico-boots
-- Usage: lua scripts/generate_coverage_report.lua [luacov_config_path]
-- This script runs luacov and displays a coverage summary without bash-specific commands.

local config_path = arg and arg[1] or "config/.luacov_engine"

-- Run luacov to generate the report
local luacov_cmd = string.format('luacov -c "%s"', config_path)
print("Generating coverage report with: " .. luacov_cmd)
os.execute(luacov_cmd)

-- Read and parse the generated report
local report_file = io.open("luacov.report.out", "r")
if not report_file then
  print("ERROR: luacov.report.out not found. Make sure luacov is installed and tests have been run.")
  os.exit(1)
end

print("\n\n=== COVERAGE REPORT ===\n")

local total_files = 0
local total_lines = 0
local total_covered = 0
local uncovered_lines = {}

for line in report_file:lines() do
  -- Match file header lines (e.g., "src/engine/core/math.lua")
  local file_path = line:match("^(src/.+%.lua)%s*$")
  if file_path then
    total_files = total_files + 1
  end

  -- Match summary lines (e.g., "Total:  90.0%")
  local total_pct = line:match("^Total:%s+(%d+%.?%d*)%%")
  if total_pct then
    print(line)
  end

  -- Match per-file coverage lines (e.g., "file.lua            85.7%")
  local file_pct = line:match("%s+(%d+%.?%d*)%%%s*$")
  if file_pct and line:match("%.lua") then
    print(line)
  end

  -- Track uncovered lines (lines starting with *0)
  if line:match("^%*0") or line:match("%s%*0") then
    table.insert(uncovered_lines, line)
  end
end

report_file:close()

-- Show uncovered lines summary
if #uncovered_lines > 0 then
  print(string.format("\n--- %d uncovered line(s) found ---", #uncovered_lines))
  for _, line in ipairs(uncovered_lines) do
    print(line)
  end
end

print(string.format("\nFiles analyzed: %d", total_files))
print("Done.")
