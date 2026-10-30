# Test results and evidence boundaries

Tested implementation: `5926006668c35607d1bf43fbf2ac1dd2b875a4f7`, before these documentation-only
changes. Fresh execution date: 30 October 2026, on Eli's Mac. The primary runner for logic tests was
`/opt/homebrew/bin/node`; Python used `/Library/Frameworks/Python.framework/Versions/3.13/bin/python3`.
No native gameplay result is inferred from a Node result or a layout render.

## 1. Fresh automated execution on the recovered branch

Commands below run from the isolated handoff repository root. Logs are retained, not paraphrased
as substitutes for evidence. `tests/harness/gml.cjs` translates the actual GML scripts and game events
into a Node VM with shims for GameMaker I/O. It checks mechanics and state, not engine resource
loading, real hardware input, rendering performance or a user's gameplay experience.

| Command | Expected | Observed | Status / evidence |
| --- | --- | --- | --- |
| `node tests/run_all.cjs` | All registered `.test.cjs` suites finish successfully. | **12/12 suites passed.** Includes 23 new follow-through/frontend cases and inherited combat/equipment/retinue coverage. | PASS: [mac-regression.log](evidence/mac-regression.log) |
| `node tests/challenger_stress.cjs` | Corrupt saves and full persistence round trips remain safe. | **14 passed, 0 failed.** | PASS: [mac-stress.log](evidence/mac-stress.log) |
| `node tests/challenger_m2_stress.cjs` | Presentation/state stress and legitimate player-title persistence. | **26/26 passed.** Existing professional-title round-trip expectation passes unchanged. | PASS: [mac-m2-stress.log](evidence/mac-m2-stress.log) |
| `node tests/challenger_m2_adversarial.test.cjs` | Adversarial UI/audio/input cases finish successfully. | **19 passed, 0 failed.** Also executed within run_all; these are repeat executions, not 19 unique extra features. | PASS: [mac-adversarial.log](evidence/mac-adversarial.log) |
| `node tests/chronicles_greenmere.test.cjs` | Existing Greenmere conditions, outcomes, saves and content integrity hold. | **25 passed.** Also included in run_all. | PASS: [mac-greenmere.log](evidence/mac-greenmere.log) |
| `node tests/gml_translator.test.cjs` | Token translation and all project scripts/game events parse. | **5 passed.** This is not the GameMaker compiler. | PASS: [mac-translator.log](evidence/mac-translator.log) |

The machine-readable [test-case-results.json](evidence/test-case-results.json) lists every named case
emitted by these logs, with source command, observed result and evidence line. Expected behavior is
the assertion contract expressed by the test name and the corresponding source test; the document
does not invent a separate manual test for each PASS line. Full logs retain warnings and totals.
UNDICI experimental-proxy warnings appeared; they did not cause the recorded suite failures.

Artifact/documentation checks are separate from gameplay tests: ZIP `testzip()` completed without
corruption; `git bundle verify` accepted the recovered bundle and reported base `47f045c`/head
`5926006`. `verify_handoff.py` checks the actual Git manifest, file hashes, required documents, local
links, indexed functions, the exact final directive and all six branding PNG/frame/layer graphs.
`git diff --check` checks patch whitespace. Their final outputs are captured in the handoff validation
evidence; none is described as a native gameplay test. Earlier narrow resource registration was also
checked for idempotence; it is a developer-tool check, not a broad world/art regeneration.

### New suite: the exact behavior covered

`tests/chronicles_followthrough.test.cjs` executes 23 cases:

1. Standing grants no automatic oath, knighthood, birth or land; invalid/unsworn ally requests fail.
2. Legacy automatic lordship migrates while earned rank survives and no tribute is minted.
3. Clerk arrival and four-day hearing answer through real conversation paths.
4. Default hearing consequence fires once; unread finding is not put into the inventory.
5. Stolen grain is not laundered by filing; restitution is explicit and charged once.
6. Payment after judgment adds a later receipt without rewriting the original finding.
7. Cartage requires evidence; copy fees do not repeat; remaining assessment survives credit.
8. Complete inquiry is reachable through Alden, Oswin and Fenner's displayed choices.
9. Refusal and collection differ and cannot both be repeatedly harvested.
10. Ignoring cartage leads to distress without taking Rowan's gold for a household liability.
11. The assessment issues and becomes due without Rowan asking; remaining-day text updates.
12. Reports enter the notebook only after conversation, persist after queue turnover and do not duplicate.
13. Local captain assent creates one actor and no Rowan estate/noble title.
14. Pending deadlines, documents and people survive save/load without duplicate actors.
15. Elapsed-day/dawn coincidence advances both calendars once.
16. Shared cargo qualifies for lodging without unrelated reputation.
17. Long reply lists retain a bounded visible window and selected final reply.
18. New papers have readable names; all new tree destinations exist; unknown trees delegate safely.
19. Frontend pauses simulation/pending door presentation; new journey does not overwrite disk save.
20. Continue loads state; new-game confirmation and controls preserve the saved file.
21. Corrupt save returns to title; held confirm cannot leak into world interaction.
22. Thirty tips and all six sprite frame resources are registered with valid basic dimensions/origin.
23. Native-walkthrough driver follows actual conversations in the harness, captures five requested
    screen calls, reports zero failures and does not write a player save.

These cover selected edge cases; they do not certify every item tooltip, all possible event ordering,
every old save payload, all screen sizes or a future combined map/presentation merge.

## 2. Native GameMaker compiler attempt during this handoff

Runtime: `/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268`.
Igor: `bin/igor/osx/arm64/Igor`. Target: `--runtime=VM -- Mac PackageZip`, profile
`/Users/elilentz/Library/Application Support/GameMakerStudio2/elilentz6_5139243`.

The existing IDE BFF and cache-input files were copied into `_native/argon-audit/` in this isolated
checkout. Project/options/cache macros, output and temp locations were redirected to the reviewed
checkout. Original IDE settings, shared source and player saves were not changed. No authentication
files or cache secrets are included in the handoff. Runtime artifacts stay ignored.

Expected: load the exact project, compile with no GML errors, and complete packaging.
Observed in [native-build.log](evidence/native-build.log):

- Successful resource load/link, explicitly naming this handoff checkout's `BLANK GAME.yyp`.
- Constants/scripts/rooms/objects/UI/global scripts compiled; **Final Compile finished**.
- IFF/archive chunks and textures written; no GML compile error observed in this attempt.
- Final package copy attempted `/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.zip`.
- `System.UnauthorizedAccessException` / operation not permitted; **Igor exit 1**.

Classification: **PASS for observed load/GML compile stage; FAIL/BLOCKED for complete packaging**.
It is false to describe this as a clean complete build. Produced artifact hashes/sizes are listed
in [native-artifact-inventory.json](evidence/native-artifact-inventory.json), without distributing
a runtime as if it were a certified release. Do not substitute an older build for the failed package.

No fresh safe runner smoke, `CC_FOLLOW_QA`, `CC_CHRON_QA` or manual native walkthrough was executed
after this attempt. These remain **UNVERIFIED**. The agreed runner build directory lies outside the
writable workspace. Do not launch a runner bare, without fresh build-side files, or through a path
workaround to evade that restriction.

## 3. Evidence recovered from earlier executions

The review archive supplied logs under `evidence/prior-cloud-tests/`: regression 12/12, stress 14,
M2 stress 26, adversarial 19, Greenmere 25, translator 5. These are earlier executions from the cloud
continuation, not fresh native tests. The fresh Mac results above independently reproduce those
logic-suite totals on the recovered source.

Six previews under `evidence/layout-previews/` came from `node tools/render_frontend.cjs` in the
cloud workspace: splash, title, loading_oakhaven, loading_dunhollow, controls and load_confirmation.
The script draws translated `frontend_draw()`/existing bitmap-font code using actual native PNGs and
checks that drawing does not mutate frontend state. Optional dependency: `@napi-rs/canvas`.
They were visually inspected and the parchment bounds corrected. They are **layout renders, not
Mac_Runner screenshots**. This handoff did not rerun that Canvas render on the Mac or claim a native
frame-rate/accessibility test from it.

Historical Grok logs preserved as `historical-main-*` and `historical-trial-*` describe different
worktrees. Main's earlier compile/smoke and the older trial's compile/test defects provide context,
not certification of `5926006`. Trial logs point at `/tmp/cc_trial/`; main logs at the prior main
checkout. The live board reports CHRON QA 13/0 on main at 13:33 ET. That claim is attributed to the
board; Codex did not newly execute that native walkthrough here.

## 4. Interrupted inspections and failed environment actions

An attempted full `node tests/run_all.cjs` in the **older Mac clone** completed part of its suites
but did not finish during the allotted inspection. The preserved catalogue has 76 named case-result lines;
individual failures, if any, are recorded there without inventing a full-suite total. It was
interrupted, exit 130. See
[old-mac-clone-regression.log](evidence/old-mac-clone-regression.log). There is no fresh pass/fail total
for that attempt. The earlier four-failure report is the board's historical result, not this partial
log. The latest recovered branch's passing suite is separate evidence.

Specifically, that interrupted older-clone catalogue contains 75 PASS result lines and one FAIL:
`content integrity: every reply leads somewhere, every id is handled, every page fits the box`.
This reproduces part of the older text-ID integrity problem. It does not establish results for
the uncompleted remainder or turn the board's other three historical failures into fresh observations.

A full older-clone byte/hash/diff inventory also stalled on reading a file and was interrupted.
Its partial-snapshot marker explicitly records the limitation. No files in that clone were edited.
Process-list diagnostics were denied by the environment; no other agent's processes were killed.
Only the two inspection sessions started by Codex were interrupted.

The live board claim/status/post command was rejected before execution because escalated access is
disabled and the authoritative board is outside writable roots. See the coordination log for exact
pending messages. A previous GitHub push was rejected for missing explicit publication authorization;
this handoff did not retry it. Missing-path/discovery commands are inspection failures, not passing
game tests. No PR exists. A remote-read fetch, if unavailable, is recorded separately in evidence.

## 5. Bugs found and what the tests demonstrate

Corrected in the implementation: double day/wage advancement; string-vs-boolean lodging check;
automatic noble/fief/oath progression; lost legitimate professional titles on load; omniscient news;
repeat copy/reward/payment opportunities; reply/paper panel layout; placeholder-ended hearing and
nomination chains. The named assertions and earlier/updated source explain their reproductions.

Observed but **not repaired in this documentation pass**: active external map has no inspected map
surface cleanup; legacy visual/generator portal/shade references; Claude's reported dice held-state
problem; missing native package/runtime gates. See KNOWN_ISSUES_AND_NEXT_STEPS.md for exact paths,
certainty, priorities and ownership. No new claim of a fixed defect is based solely on a TODO.

## 6. Reproduction and completion gate for Argon

1. Read the live board/rules and claim your own isolated branch. Confirm the implementation/base hash.
2. Run the six commands in section 1; compare suite totals and named assertions, not just process exit.
3. Check `CHANGE_MANIFEST.json` with `verify_handoff.py`; compare actual Git changes and referenced files.
4. Open this exact `BLANK GAME.yyp` in GameMaker 2024.14.4.222. Build with macros and resource paths
   pointing here. Resolve authorized packaging/signing/output access; retain the whole log.
5. Place fresh `game.ios`, `options.ini` and `splash.png` from that build in the agreed build folder.
   Use `tools/run_native_qa.py --runner /absolute/path/to/Mac_Runner --build /absolute/build/folder
   --suite follow`, then `--suite chronicle`. The driver never writes a player save. Verify completion
   markers and absence of CF/CHRON QA FAIL, runner errors and incomplete logs.
6. Perform a 15-second safe smoke and manual walkthrough: splash skip; title with/without save;
   Continue/new confirmation; corrupt save; pause/controls; movement/doors; all five weapons; defense;
   ACT/ITEM/MERCY; sockets/equipment; party; trade; defeat/recovery; save/load inside/outside.
7. On a coordinated combined branch, separately test M map/icons/surface loss, active dice/archery,
   day/night redoubt/Weald views and independent war consequences. Do not call inherited tests proof
   that unmerged content was integrated or that the final kingdom endings exist.
