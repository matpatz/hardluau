# Generators

Procedural case generators that produce more suite files on demand.

| Script | Output |
|--------|--------|
| `nested_expr_generator.py` | One deeply nested binary expression |
| `random_valid_ast_generator.py` | Many random but valid programs |

Both scripts require Python 3.9+ and have no third-party dependencies.

## Examples

```sh
python generators/nested_expr_generator.py --depth 500 --op ".." --out deep-concat.luau
python generators/random_valid_ast_generator.py --count 200 --seed 42 --out-dir src/generated/
```

Generated files are not committed; the `src/generated/` directory is
listed in `.gitignore`.
