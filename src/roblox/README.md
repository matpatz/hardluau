# Roblox-exclusive scripts

Files in this directory use Roblox engine APIs (`game`, `workspace`,
`Instance`, services via `game:GetService(...)`) and/or executor-only
globals (`getgenv`, `cloneref`, `hookfunction`, `getconnections`, ...). They will **not** run in standalone `luau` — they need a
Roblox client with an executor.

## Why separate them?

The rest of `src/` is pure Luau that should parse and run anywhere. Scripts
here are still syntactically valid Luau, but they depend on Roblox-only
globals, so a reference tool may report undefined identifiers on them.

## Rules

- Keep each script self-contained and runnable in an executor.
