# Contributing

Thanks for helping grow the corpus!

## Adding a test case

1. Drop the file in `src/` — use `src/roblox/` for Roblox-only scripts, `src/detections/` for environment-detection scripts, or a category subfolder if it fits one.
2. Add a header comment describing what the case exercises and why it is tricky.
3. Add an entry to `metadata/index.json` with:
   - `file` — path relative to the repository root
   - `category` — one of the top-level categories
   - `difficulty` — `trivial | easy | medium | hard | pathological`
   - `tags` — array of short keywords
   - `description` — one or two sentences
4. Run the validator:
   ```sh
   python tests/validate_syntax.py
   ```
## Style

- Keep valid cases self-contained and runnable.
- Prefer minimal reproductions over realistic programs.
- One surprising behavior per file.
