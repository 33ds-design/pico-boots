# Contributing to pico-boots

## Development Setup

### Prerequisites

- **Lua 5.3** (5.2 may also work)
- **busted** — Lua unit test framework (`luarocks install busted`)
- **luacov** — Lua coverage analyzer (`luarocks install luacov`)
- **Python 3.6+** — for build/preprocess scripts
- **Node.js + npm** — for luamin minifier (run `setup.sh` to install)

### Installation

```bash
git clone https://github.com/33ds-design/pico-boots.git
cd pico-boots
./setup.sh  # installs npm dependencies (luamin)
```

## Running Tests

### Linux / macOS

```bash
# Run all tests (excluding #mute WIP tests)
./test.sh

# Run all tests including #mute
./test.sh -m all

# Run only #solo tests (useful when focusing on a specific test)
./test.sh -m solo

# Run tests for a specific engine subfolder
./test.sh core
./test.sh physics
./test.sh debug
```

### Windows (PowerShell)

```powershell
# Run all tests (excluding #mute WIP tests)
.\test.ps1

# Run all tests including #mute
.\test.ps1 -FilterMode all

# Run only #solo tests
.\test.ps1 -FilterMode solo

# Run tests for a specific engine subfolder
.\test.ps1 -Folder core
```

### Direct busted commands (cross-platform)

If `busted` is in your PATH, you can run tests directly:

```bash
# Using the .busted config file (just run busted from project root)
busted

# Or with explicit arguments
busted src/engine --lpath="src/?.lua" -p "_utest%.lua$" -v

# Include #mute tests
busted src/engine --lpath="src/?.lua" -p "_utest%.lua$" -m all -v

# Test a single module
busted src/engine/core --lpath="src/?.lua" -p "_utest%.lua$" -v
```

## Test Conventions

### File naming

All unit test files must follow the convention: `{module_name}_utest.lua`

Example: module `helper.lua` has test file `helper_utest.lua`

### Required imports

Every test file must start with:

```lua
require("engine/test/bustedhelper")
```

This provides the PICO-8 API bridge (`pico8api.lua`) and other test helpers.

### Test markers

- **`#solo`** — Flag a test to run it exclusively with `./test.sh -m solo`. Useful when working on a specific test.
- **`#mute`** — Flag a test as work-in-progress. Excluded by default to avoid error spam. Use `./test.sh -m all` to include them.

```lua
describe('#solo my feature', function ()
  it('should do something', function ()
    -- this test only runs with -m solo
  end)
end)

describe('#mute my WIP test', function ()
  it('should eventually work', function ()
    -- this test is skipped by default
  end)
end)
```

## Coverage Reports

### Generating coverage

Coverage is automatically generated when running tests with the `-c` flag (enabled by default via `.busted` config or `test.sh`).

After tests complete, `luacov.report.out` is generated in the project root.

### Viewing coverage

```bash
# Linux/macOS
luacov -c config/.luacov_engine
cat luacov.report.out

# Cross-platform (Lua script)
lua scripts/generate_coverage_report.lua config/.luacov_engine
```

### Luacov configuration

Coverage exclusion rules are defined in `config/.luacov_engine`. Test files (`*_utest.lua`) and shared library modules are excluded from coverage statistics.

## Code Style

- Write all code in "clean Lua" — compatible with both standard Lua 5.3 and PICO-8
- Avoid PICO-8-specific syntax (`+=`, `-=`, `!=`, single-line `if (cond) statement` without `then`/`end`)
- Use `api.print()` instead of `print()` in game code (requires `require("engine/pico8/api")`)
- Use `--#if symbol` / `--#endif` for conditional compilation (debug code stripping)

## CI

Tests run automatically on GitHub Actions (`.github/workflows/test.yml`) on every push and pull request to `master`.

- CI runs both Python toolchain tests and Lua unit tests
- Coverage is uploaded to Codecov
