# hardluau

hardluau is a curated suite of Luau source files designed to stress-test
parsers, formatters, linters, type checkers, and language servers.

Every file in the suite is valid Luau that a conforming tool must accept.

## Layout

| Path | Purpose |
|------|---------|
| `src/syntax/` | Grammar edge cases that are valid Luau |
| `src/luau-specific/` | Features unique to Luau (not vanilla Lua) |
| `src/semantic-traps/` | Legal syntax with surprising runtime behavior |
| `src/formatting-extremes/` | Whitespace and layout stress |
| `src/roblox/` | Roblox-exclusive scripts (engine/executor APIs) |
| `src/detections/` | Environment-detection scripts (Roblox vs Lune vs standalone) |
| `generators/` | Scripts that procedurally generate more cases |
| `metadata/` | Machine-readable index (`index.json`) |
| `tests/` | Sanity harness for validating the suite |

## Goals

1. **Correctness** — parsers must reproduce Luau's grammar exactly.
2. **Idempotence** — a formatter round-trip should be stable.
3. **Interoperability** — a single suite usable across many tools.

## Usage

Validate the suite against a reference parser:

```sh
python tests/validate_syntax.py --luau /path/to/luau-analyze
```

Generate procedural cases:

```sh
python generators/nested_expr_generator.py --depth 100 --out src/generated
```

## Contributing

See `CONTRIBUTING.md`. New cases must be added to `metadata/index.json`
with category, difficulty, tags, and description.

## License

See `LICENSE`.
