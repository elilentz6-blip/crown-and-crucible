#!/usr/bin/env python3
"""Scripted native run of the real start-up flow, with the front end NOT bypassed.

Each scenario runs in its own HOME, so the player's save and settings stay untouched.
Input comes from keyboard_key_press inside the game (scr_frontend_qa), so no screen or
app control is needed.

  python3 tools/run_front_qa.py --build ~/GameMakerProjects/_build/front \
      --old-save /path/to/a/real/save.json --shots ~/GameMakerProjects/_build/front/shots
"""
import argparse
import hashlib
import os
import plistlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

SAVE = 'save_crown_and_crucible.json'
RUNNER = '/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/mac/YoYo Runner.app/Contents/MacOS/Mac_Runner'
# (scenario, HOME it shares, what to seed the save with, must end through the in-game Quit)
PLAN = [('first', 'a', None), ('relaunch', 'a', None), ('oldsave', 'b', 'old'), ('corrupt', 'c', 'garbage'),
        ('door', 'd', None), ('systems', 'e', None), ('fullscreen', 'f', None)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runner', default=RUNNER)
    parser.add_argument('--build', type=Path, help='folder with game.ios, options.ini, splash.png')
    parser.add_argument('--app', type=Path, help='a packaged .app to run instead of --build')
    parser.add_argument('--old-save', type=Path)
    parser.add_argument('--shots', type=Path, required=True)
    parser.add_argument('--only', nargs='*')
    args = parser.parse_args()
    if args.app:
        runner, game = args.app / 'Contents/MacOS/Mac_Runner', []
        with (args.app / 'Contents/Info.plist').open('rb') as plist:
            support = plistlib.load(plist)['CFBundleIdentifier']
    else:
        support = 'com.yoyogames.macyoyorunner'
        build = args.build.expanduser().resolve()
        for name in ['game.ios', 'options.ini', 'splash.png']:
            if not (build / name).is_file():
                parser.error(f'missing {build / name}')
        runner, game = args.runner, ['-game', str(build / 'game.ios')]
    args.shots.mkdir(parents=True, exist_ok=True)
    real = Path.home() / 'Library/Application Support/com.yoyogames.macyoyorunner' / SAVE
    before = hashlib.md5(real.read_bytes()).hexdigest() if real.exists() else None
    root = Path(tempfile.mkdtemp(prefix='frontqa'))
    failed = 0
    for scenario, home_key, seed in PLAN:
        if args.only and scenario not in args.only:
            continue
        home = root / home_key
        data = home / 'Library/Application Support' / support
        data.mkdir(parents=True, exist_ok=True)
        if seed == 'old':
            shutil.copy(args.old_save, data / SAVE)
        if seed == 'garbage':
            (data / SAVE).write_text('{"version": 2, "hero": {"gold"')
        env = {k: v for k, v in os.environ.items() if not k.startswith('CC_')}
        env.update(HOME=str(home), CFFIXED_USER_HOME=str(home), CC_FRONT_QA=scenario)
        log = args.shots / f'{scenario}.log'
        try:
            with log.open('w') as out:
                code = subprocess.run([str(runner), *game, '-outputdebugstring'], env=env, cwd=str(root),
                                      stdout=out, stderr=subprocess.STDOUT, timeout=150).returncode
        except subprocess.TimeoutExpired:
            code = 'timeout'
        text = log.read_text(errors='replace')
        lines = [l for l in text.splitlines() if 'FRONT QA' in l]
        fails = [l for l in lines if 'FRONT QA FAIL' in l]
        ended = 'FRONT QA QUIT-REQUESTED failures=0' in text or 'FRONT QA COMPLETE failures=0' in text
        crash = 'ERROR in action number' in text or 'FATAL ERROR' in text
        ok = code == 0 and ended and not fails and not crash
        failed += not ok
        print(f"{'PASS' if ok else 'FAIL'} {scenario}: exit={code} checks={sum('FRONT QA ok' in l for l in lines)} fails={len(fails)}")
        for line in fails + ([l for l in text.splitlines() if 'ERROR' in l][:6] if crash else []):
            print('   ', line)
        for line in lines:
            if 'diff after restart' in line:
                print('   ', line)
        for shot in home.rglob('front_*.png'):
            shutil.copy(shot, args.shots / shot.name)
    after = hashlib.md5(real.read_bytes()).hexdigest() if real.exists() else None
    print('player save untouched' if before == after else 'FAIL: the player save changed')
    shutil.rmtree(root, ignore_errors=True)
    return 1 if failed or before != after else 0


if __name__ == '__main__':
    sys.exit(main())
