# Bug Report: Windows - Cannot inject the standard library `moonbitlang/core`

## Summary
On Windows, MoonBit CLI v0.1.20260522 fails to load the standard library `moonbitlang/core` for any project, including freshly created ones via `moon new`. The error occurs across all build targets (js, wasm, wasm-gc, native).

## Version

```
moon 0.1.20260522 (84aa893 2026-05-22)
Feature flags enabled: rr_moon_mod,rr_moon_pkg
```

## Environment

- OS: Windows 11 (PowerShell / cmd)
- MoonBit installed via: `irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex`

## Reproduction Steps

1. Fresh install MoonBit on Windows
2. Run `moon new test_project`
3. `cd test_project`
4. Run `moon build --target js` (or `moon test --target js`)

## Expected Behavior

Build/test should succeed using the built-in standard library.

## Actual Behavior

```
Error: failed to run build for target Js

Caused by:
    0: Failed to resolve the module dependency graph
    1: Cannot inject the standard library `moonbitlang/core`: Cannot load the core file
```

## Additional Context

- The standard library source **does exist** at `~/.moon/core/` (cloned from https://github.com/moonbitlang/core, `moon.mod` present)
- Also tried placing it at `~/.mooncakes/moonbitlang/core/` — same error
- Reinstalling the toolchain via the PowerShell script does **not** resolve the issue
- The `.moon/lib/` directory was temporarily deleted during reinstall; manually restoring `runtime_core.c` and other files from the ZIP distribution did not help
- All targets fail with the identical error message
- The `mooncake` CLI does not have an `install` subcommand to manually fetch core

## Suspected Cause

The `rr_moon_mod` / `rr_moon_pkg` feature flags may have changed the standard library discovery path on Windows, causing `moonc` to fail locating/injecting `moonbitlang/core`.
