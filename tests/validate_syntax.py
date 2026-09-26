#!/usr/bin/env python3
"""Validate that every suite file parses correctly in a reference tool.

Usage:
    python validate_syntax.py [--luau PATH] [--tool {luau-analyze,stylua,lua}]
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCRIPTS = REPO / "src"


def check_parse(tool: str, path: Path) -> bool:
    """Return True if `tool` parses `path` without error."""
    if tool == "lua":
        # `lua -p` is a syntax-only check that prints nothing on success.
        proc = subprocess.run([tool, "-p", str(path)],
                              capture_output=True, text=True)
    elif tool in ("luau-analyze", "luau"):
        proc = subprocess.run([tool, str(path)],
                              capture_output=True, text=True)
    elif tool == "stylua":
        proc = subprocess.run([tool, "--check", str(path)],
                              capture_output=True, text=True)
    else:
        raise ValueError(f"unknown tool {tool!r}")
    return proc.returncode == 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", default=None,
                        help="path to the luau-analyze / luau binary")
    parser.add_argument("--tool", default=None,
                        choices=["luau-analyze", "luau", "stylua", "lua"],
                        help="tool to use; auto-detected if omitted")
    args = parser.parse_args(argv)

    tool_path = args.luau or (args.tool if args.tool else None)
    tool_name = args.tool
    if not tool_path:
        for candidate in ("luau-analyze", "luau", "stylua", "lua"):
            found = shutil.which(candidate)
            if found:
                tool_path, tool_name = found, candidate
                break
    if not tool_path:
        print("error: no reference tool found; pass --luau or --tool",
              file=sys.stderr)
        return 2

    failures = []
    checked = 0
    for path in sorted(SCRIPTS.rglob("*.luau")):
        checked += 1
        if not check_parse(tool_path, path):
            failures.append(str(path.relative_to(REPO)))

    if failures:
        print(f"FAIL: {len(failures)} file(s) did not parse:")
        for f in failures:
            print(f"  - {f}")
        return 1

    print(f"OK: {checked} files checked with {tool_name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
