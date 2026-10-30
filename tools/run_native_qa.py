#!/usr/bin/env python3
"""Run a freshly built native Mac walkthrough, never a bare or unbuilt runner.

Example:
  python3 tools/run_native_qa.py --runner '/path/to/Mac_Runner' \
    --build ~/GameMakerProjects/_build --suite follow

Compile this checkout in GameMaker first. All three build-side files must come
from that compilation. This tool does not compile or repair signatures.
"""
import argparse
import os
from pathlib import Path
import platform
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runner', required=True, type=Path)
    parser.add_argument('--build', required=True, type=Path)
    parser.add_argument('--suite', choices=['follow', 'chronicle'], default='follow')
    args = parser.parse_args()
    if platform.system() != 'Darwin':
        parser.error('Native verification requires macOS and the GameMaker 2024.14 runner.')
    runner, build = args.runner.expanduser().resolve(), args.build.expanduser().resolve()
    for file in [runner, *(build / name for name in ['game.ios', 'options.ini', 'splash.png'])]:
        if not file.is_file() or not file.stat().st_size:
            parser.error(f'Missing required compiled file: {file}')
    env = os.environ.copy()
    for key in ['CC_CHRON_QA', 'CC_FOLLOW_QA', 'CC_RETINUE_QA', 'CC_VIS_TOUR', 'CC_VIS_SCREENS', 'CC_VIS_SNAP']:
        env.pop(key, None)
    env['CC_FOLLOW_QA' if args.suite == 'follow' else 'CC_CHRON_QA'] = '1'
    log = build / ('qa-' + args.suite + '.log')
    try:
        with log.open('w') as output:
            result = subprocess.run([str(runner), '-game', str(build / 'game.ios'), '-outputdebugstring'],
                                    cwd=build, env=env, stdout=output, stderr=subprocess.STDOUT, timeout=90)
    except subprocess.TimeoutExpired:
        print(f'FAIL: native walkthrough timed out; see {log}', file=sys.stderr)
        return 1
    text = log.read_text(errors='replace')
    complete = 'CF QA COMPLETE failures=0' if args.suite == 'follow' else 'play-through complete'
    failed = 'CF QA FAIL' in text or 'CHRON QA FAIL' in text or 'ERROR in action number' in text
    if result.returncode or failed or complete not in text:
        print(f'FAIL: exit={result.returncode}; inspect {log}', file=sys.stderr)
        return 1
    print(f'PASS: {args.suite} native walkthrough; {log}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
