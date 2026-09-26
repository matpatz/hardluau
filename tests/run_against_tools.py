#!/usr/bin/env python3
"""Example harness for benchmarking external tools across the suite.

For each tool, run it over every file under src/ and report timing and
exit status. Tools are expected to accept a file path as their final argument.

Usage:
    python run_against_tools.py --tools luau-analyze stylua selene
"""

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCRIPTS = REPO / "src"


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tools", nargs="+", required=True,
                        help="tool executables to benchmark")
    args = parser.parse_args(argv)

    files = sorted(SCRIPTS.rglob("*.luau"))
    results = {}
    for tool in args.tools:
        tool_results = []
        for path in files:
            start = time.perf_counter()
            proc = subprocess.run([tool, str(path)],
                                  capture_output=True, text=True)
            elapsed = time.perf_counter() - start
            tool_results.append({
                "file": str(path.relative_to(REPO)),
                "exit": proc.returncode,
                "seconds": round(elapsed, 4),
                "stderr": proc.stderr[:200],
            })
        results[tool] = tool_results

    print(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
