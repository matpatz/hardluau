# Environment detections

Scripts in this directory detect which execution environment they are
running in — Roblox, Lune, the standalone `luau` CLI, or an executor.

## Pattern

The common trick is to probe for environment-specific globals:

- `game` / `workspace` — present only in Roblox
- `getgenv` / `cloneref` — present only in executors
- `script` / `Instance` — Roblox data-model objects

```luau
if not game then
    print("not Roblox (Lune, luau CLI, ...)")
else
    print("Roblox")
end
```

## Rules

- Keep scripts runnable in as many environments as possible.
- Use `if not <global>` guards instead of calling the global directly.
- Don't add `--!strict` — these scripts intentionally reference globals
  that don't exist in every runtime.
