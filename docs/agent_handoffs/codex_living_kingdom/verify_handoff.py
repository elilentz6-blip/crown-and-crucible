#!/usr/bin/env python3
"""Generate or independently check the exact handoff manifest (no runtime mutations).

Run from any directory:
  python3 docs/agent_handoffs/codex_living_kingdom/verify_handoff.py --write
  python3 docs/agent_handoffs/codex_living_kingdom/verify_handoff.py

--write inventories Git differences from the fixed integration base plus untracked
files. Normal mode checks the inventory, hashes, local Markdown links, API index,
native branding graph and the owner's required final Argon directive. It never
claims a native run or changes the shared coordination board.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = '47f045cad4f968f84e52f4ebe954c378ebdeb65c'
IMPLEMENTATION = '5926006668c35607d1bf43fbf2ac1dd2b875a4f7'
MANIFEST = HERE / 'CHANGE_MANIFEST.json'
REQUIRED = ['IMPLEMENTATION_REPORT.md', 'TECHNICAL_ARCHITECTURE.md', 'TEST_RESULTS.md',
            'KNOWN_ISSUES_AND_NEXT_STEPS.md', 'AGENT_COORDINATION_LOG.md', 'ARGON_START_HERE.md']
DIRECTIVE = '''Argon: You are receiving an implementation that requires independent verification. Do not assume the previous agent's work is correct simply because it is documented.

Begin by reading `docs/AGENT_BOARD.md` and the applicable agent coordination rules, checking your inbox, and establishing your own authorized `agent/` branch and file claims.

Audit the implementation against the Chronicles of Aethelgard, the original requirements, and the actual GameMaker project.

Reproduce reported tests, investigate known defects, identify missing functionality, and improve the implementation where authorized.

Preserve Claude's, Gemini's, and other agents' active work.

Your responsibility is to verify, repair, refine, and extend the Living Kingdom remaster, not merely approve it.'''


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def actual_changes():
    # A revision argument includes both staged and unstaged contents. Untracked
    # files are explicitly added so --write also works before the final commit.
    parts = git('diff', '--no-renames', '--name-status', '-z', BASE).split(b'\0')
    found = {}
    for i in range(0, len(parts) - 1, 2):
        if parts[i]:
            found[parts[i + 1].decode()] = parts[i].decode()
    for name in git('ls-files', '--others', '--exclude-standard', '-z').split(b'\0'):
        if name:
            found.setdefault(name.decode(), 'A')
    return found


def describe(name):
    if name.startswith('docs/agent_handoffs/'):
        return ('Argon handoff / evidence', 'Explain or preserve independently auditable implementation, provenance and validation.',
                'Documentation only; not runtime code.', ['Implementation commit ' + IMPLEMENTATION],
                'Read evidence provenance; snapshots of external work do not transfer ownership.')
    if name.startswith('art_src/branding/'):
        return ('Branding source art', 'Preserve the supplied or matching generated illustration bytes.',
                'Referenced by registered native sprites on this branch; not installed in active checkout.',
                ['tools/register_branding.py', 'sprites/spr_front_*', 'sprites/spr_loading_*'],
                'Do not regenerate or replace original images without coordinating with Claude.')
    if name.startswith('sprites/spr_front_') or name.startswith('sprites/spr_loading_'):
        return ('Native branding resource', 'Provide sprite metadata, frame or matching layer image for the front end.',
                'Registered in BLANK GAME.yyp on this branch.', ['BLANK GAME.yyp', 'art_src/branding/', 'scr_frontend'],
                'Keep frame/layer UUIDs together; older Mac clone uses different identifiers.')
    if name.startswith('options/mac/'):
        return ('Mac branding / packaging', 'Set display name, app icon and startup illustration.',
                'Compile-stage loaded; final archive packaging blocked by output permissions.',
                ['options/mac/options_mac.yy', 'Current-checkout options_dir macro'],
                'Mac signing, icon and first-launch behavior remain unverified.')
    if 'scr_frontend' in name or name in ['objects/obj_game/Step_0.gml', 'objects/obj_game/Draw_64.gml']:
        return ('Frontend state and routing', 'Implement native title/pause/loading behavior or early mode dispatch.',
                'Wired into native events in isolated branch.', ['scr_living_world', 'scr_vis_world', 'ui_text', 'global.frontend'],
                'Preserve existing modes/QA boot routes; validate native input and save behavior.')
    if 'scr_chronicle_followthrough' in name or 'scr_greenmere' in name:
        return ('Historical follow-through', 'Extend or delegate Greenmere conversations, deadlines, evidence and consequences.',
                'Public gm_* wrappers integrated; state uses existing Chronicle save block.',
                ['scr_chronicle_core', 'scr_conversation', 'scr_war_clock', 'scr_living_world'],
                'Keep inherited *_greenmere functions and Gemini historical inquiries; local lore/tuning provisional.')
    if 'scr_feudal' in name or 'scr_living_world' in name:
        return ('Progression and save reconciliation', 'Separate professional standing/service from automatic noble title, estate or tribute.',
                'Integrated with current rank/save interfaces.', ['global.chron', 'Existing rank/employer save fields'],
                'Retain legitimate professional styles and earned standing; do not create automatic knighthood.')
    if name.startswith('tests/'):
        return ('Regression coverage', 'Test actual GML behavior, integrity, compatibility and edge cases under the Node harness.',
                'Executed on recovered branch; method does not substitute for native gameplay.',
                ['tests/harness/gml.cjs', 'Corresponding native GML scripts'],
                'Read test names/assertions; do not assume all old saves or hardware input are covered.')
    if name.startswith('tools/'):
        return ('Build / visual QA tooling', 'Reproduce narrow registration, GML layout rendering or safe native QA launching.',
                'Developer tool; not automatic proof of native execution.', ['GameMaker runtime or optional Canvas/Python dependencies'],
                'Registration writes resources; runner helper requires matching fresh build-side files.')
    if name.startswith('objects/obj_vis_renderer/') or 'scr_vis_world' in name:
        return ('Renderer integration', 'Boot/suppress frontend overlays and suspend pending visual-door transitions.',
                'Narrow hooks in existing renderer.', ['scr_frontend', 'Existing Claude renderer'],
                'Coordinate shared visual changes; do not overwrite the active map/presentation work.')
    if 'scr_retinue' in name:
        return ('Retinue UX/calendar integration', 'Expose present Galahalt testimony or prevent double day/wage advancement.',
                'Existing party/calendar APIs retained.', ['scr_conversation', 'scr_greenmere', 'Existing retinue state'],
                'No ownership of Gemini support mechanics or Claude presentation is implied.')
    if 'scr_conversation' in name:
        return ('Conversation/notebook UX', 'Bound visible replies and show only reports actually heard.',
                'Existing tree and input interfaces retained.', ['cf_heard_news', 'ui_text', 'global.convo'],
                'Inspect long labels, page transitions and notebook persistence natively.')
    if 'scr_chronicle_core' in name or 'scr_chronicle_qa' in name or 'scr_war_clock' in name:
        return ('Chronicle lifecycle and QA', 'Protect day/reward processing, route opt-in follow QA or improve epilogue wording.',
                'Existing Chronicle state/version retained.', ['scr_greenmere', 'scr_chronicle_followthrough'],
                'Regional season results continue play; they are not the four terminal kingdom endings.')
    if name == 'BLANK GAME.yyp':
        return ('Resource registration', 'Register two scripts and six branding sprites.',
                'GameMaker loaded this exact project during native compile attempt.', ['New .yy files and sprite images'],
                'Shared resource: claim only during coordinated edits; no replacement with old clone registry.')
    if name == '.gitignore':
        return ('Repository hygiene', 'Ignore reproducible QA/native/Python cache output while preserving board lock ignore.',
                'Integrated on isolated branch.', [], 'Evidence deliberately included in this handoff must remain tracked.')
    return ('Project documentation', 'Reconcile canonical local status or provide the requested Claude implementation briefing.',
            'Documentation only.', ['Proposed Chronicles', 'Actual source/evidence'],
            'Earlier status snapshots do not certify later revisions; no remote Google Doc edited.')


def make_manifest():
    entries = []
    for name, status in sorted(actual_changes().items()):
        path = ROOT / name
        feature, purpose, integration, dependencies, warning = describe(name)
        is_self = path == MANIFEST
        validation = ('Document/evidence integrity only; external snapshots are not runtime-compiled.'
                      if name.startswith('docs/agent_handoffs/') else
                      'Documented compile-stage and fresh Node evidence; native gameplay unverified.'
                      if path.suffix == '.gml' else 'File/reference integrity checked; inspect feature-specific evidence.')
        entries.append({'path': name, 'change_type': {'A': 'created', 'M': 'modified', 'D': 'deleted'}.get(status, status),
                        'related_feature': feature, 'purpose': purpose, 'integration_status': integration,
                        'validation_status': validation, 'known_dependencies': dependencies,
                        'warnings_for_argon': [warning],
                        'sha256': None if is_self or not path.is_file() else hashlib.sha256(path.read_bytes()).hexdigest(),
                        'hash_note': 'Manifest omits its own hash to avoid self-reference.' if is_self else None})
    observed = json.loads((HERE / 'evidence/active-mac-snapshot.json').read_text())
    return {'schema_version': 1, 'base_commit': BASE, 'implementation_head': IMPLEMENTATION,
            'branch': 'agent/codex-living-kingdom-handoff',
            'remote_main_observed_after_fetch': '99ba93571ab72a3accc17b4df9252665bd7d817e',
            'combined_with_later_remote_main': False,
            'native_validation': {'compile_stage': 'Final Compile finished', 'overall_igor_exit': 1,
                                  'packaging': 'permission denied', 'runtime_play': 'not executed'},
            'scope': 'Every actual branch change since base, including handoff files; external work is separate.',
            'files': entries,
            'observed_external_changes': [{**f, 'change_type': 'created' if f['git_status'] == '??' else 'modified',
                'related_feature': 'Observed shared presentation/map work', 'purpose': 'Inventory only; source not copied into runtime branch.',
                'integration_status': 'Active Mac checkout only; not a Codex implementation change.',
                'validation_status': 'Read-only snapshot, not combined native validation.',
                'known_dependencies': ['Current live agent claims and owner coordination'],
                'warnings_for_argon': ['Preserve active work; do not infer ownership or port without coordination.']}
                for f in observed['changes']],
            'external_snapshot_root': observed['root'],
            'deletions_note': 'Only Git-reported deletions may appear; no deletion entries are invented.'}


def verify():
    data = json.loads(MANIFEST.read_text())
    declared = {f['path']: f for f in data['files']}
    actual = actual_changes()
    assert set(declared) == set(actual), {'missing': sorted(set(actual) - set(declared)), 'extra': sorted(set(declared) - set(actual))}
    for name, entry in declared.items():
        assert entry['change_type'] == {'A': 'created', 'M': 'modified', 'D': 'deleted'}.get(actual[name], actual[name]), name
        path = ROOT / name
        assert path.is_file() or entry['change_type'] == 'deleted', name
        if entry['sha256']:
            assert hashlib.sha256(path.read_bytes()).hexdigest() == entry['sha256'], name
    for name in REQUIRED:
        assert (HERE / name).is_file(), name
    for doc in HERE.glob('*.md'):
        for target in re.findall(r'\]\(([^)]+)\)', doc.read_text()):
            if '://' in target or target.startswith('#'):
                continue
            assert (doc.parent / target.split('#')[0]).exists(), (doc.name, target)
        # Check exact source paths quoted in prose. External map sources must
        # have a frozen evidence copy rather than relying on a future Mac path.
        for token in re.findall(r'`([^`\n]+)`', doc.read_text()):
            if re.fullmatch(r'(?:scripts|objects|art_src|options|tools|tests|docs|sprites)/[A-Za-z0-9_./ -]+\.(?:gml|py|cjs|json|yy|yyp|md|png)', token):
                assert (ROOT / token).exists() or (HERE / 'evidence/external-source-snapshots' / token).exists(), (doc.name, token)
    assert (HERE / 'ARGON_START_HERE.md').read_text().rstrip().endswith(DIRECTIVE), 'Required final directive differs'
    api = json.loads((HERE / 'evidence/api-index.json').read_text())
    for name, functions in api.items():
        text = (ROOT / name).read_text()
        for f in functions:
            assert re.search(r'^function\s+' + re.escape(f['name']) + r'\(', text, re.M), (name, f['name'])
    for name, source in {'spr_front_logo': 'logo', 'spr_front_emblem': 'emblem', 'spr_front_parchment': 'parchment',
                         'spr_loading_greenmere': 'greenmere', 'spr_loading_oakhaven': 'oakhaven', 'spr_loading_dunhollow': 'dunhollow'}.items():
        folder = ROOT / 'sprites' / name
        yy = json.loads((folder / (name + '.yy')).read_text())
        png = (ROOT / 'art_src/branding' / (source + '.png')).read_bytes()
        assert struct.unpack('>II', png[16:24]) == (yy['width'], yy['height']), name
        assert f'sprites/{name}/{name}.yy' in (ROOT / 'BLANK GAME.yyp').read_text(), name
        for f in yy['frames']:
            assert (folder / (f['name'] + '.png')).read_bytes() == png, name
            for layer in yy['layers']:
                assert (folder / 'layers' / f['name'] / (layer['name'] + '.png')).read_bytes() == png, name
    print(json.dumps({'status': 'PASS', 'manifest_matches_actual_git_changes': True,
                      'manifest_file_count': len(declared), 'external_observed_file_count': len(data['observed_external_changes']),
                      'hashes_match': True, 'required_docs_exist': True, 'local_links_exist': True,
                      'indexed_functions_exist': True, 'quoted_source_paths_exist': True,
                      'six_branding_resources_match': True,
                      'required_argon_directive_exact': True, 'native_runtime_verified': False}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true', help='Regenerate inventory before final validation/commit.')
    args = parser.parse_args()
    if args.write:
        if not MANIFEST.exists():
            MANIFEST.write_text('{}\n')
        MANIFEST.write_text(json.dumps(make_manifest(), indent=2) + '\n')
        print('Manifest regenerated from actual Git changes.')
    else:
        verify()
