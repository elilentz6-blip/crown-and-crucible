# Claude kickoff: Crown & Crucible, the Chronicles and a finished native presentation

You are the art and presentation lead for Crown & Crucible, a native GameMaker medieval sandbox.
Execute the work in the game. Bring your own judgment, visual ideas and technical solutions. You
have broad creative freedom inside the Chronicles and the immutable canon; you do not need approval
for ordinary artistic or implementation choices. Inspect the current branch before designing around
an older version of the game.

## Read first and establish the working baseline

Read `AGENTS.md`, `docs/proposed/THE_CHRONICLES_OF_AETHELGARD.md`, `docs/STORY_BIBLE.md`, the current
follow-through section of `CROWN_AND_CRUCIBLE_MASTER_DOSSIER.md`, `docs/CHRONICLES_LEDGER.md` and the
native resource tree. The primary project is `BLANK GAME.yyp` in the `crown-and-crucible` repository,
using GameMaker 2024.14.4.222 / runtime 2024.14.4.268. Ignore the older Retro Game and Blank Pixel Game
projects. An HTML mockup is not completion of a native feature.

The `chatgpt/chronicles-followthrough` branch already contains functional branding, loading, menu
behavior and additional historical situations. Review and integrate it before making a competing
front end. Its Node tests pass; the current branch still requires a fresh Mac compile and actual
GameMaker walkthrough. Do not inherit older documentation's native certification as proof for it.

## Canon is the boundary of your creative freedom

Aethelgard has no real magic, supernatural intervention, dimensional travel, resurrection, enchanted
gear, fantasy species or chosen heroes. Folklore, alleged miracles and superstition are human beliefs.
Use material, human explanations for equipment modifiers and visual effects. Combat's dodge marker
is an abstract interface, not proof of a physically manifested soul or supernatural projectile.

Stay within approximately 1150–1350 medieval inspiration: castles, timber, stone, chainmail, heraldry,
livestock, working ports, household soldiers and poor roads. Avoid firearms, Renaissance display
armor and arbitrary anachronisms. Do not replace every old fantasy concept with a new secret cult.

Aldous III is the legitimate King, constrained by fealty, customs and institutions. Nobility is
hereditary; knighthood, military office, wealth, landholding and noble birth are distinct. Rowan
starts common-born, experienced and unknighted, with no estate or elite access. His allegiance is
chosen. Never make him a secret heir or auto-promote him into hereditary nobility.

The islands have distinct languages, identities, customs and grievances. Religious practice varies;
exact theology remains open. Royal, noble, religious and chartered courts overlap. Regional serfdom,
tenancy, merchant privileges and service obligations differ, and a border does not erase a duty.
Do not present a proposed island assignment as locked owner approval.

About a century of intermittent wars has left uneven peace and unresolved violence. Armies include
levies, household retinues, militias and mercenaries. Attitudes to mercenaries follow local experience,
not an automatic civil-war allegiance. Rule 13, the kingdom's economic organization, remains open;
local fees, markets and accounts do not settle a uniform national system or currency conversion.

Follow the Chronicles' names, genealogy, dates and historical causality. Distinguish approved canon,
provisional inventions, open decisions, verified native behavior and planned systems. Invent rich
compatible detail freely without silently changing the kingdom's foundation.

## Make the supplied art part of a coherent game

Preserve the supplied Crown & Crucible wordmark/emblem, Greenmere landscape and parchment. Matching
Oakhaven wharf and Dunhollow quarry pictures and a compact emblem are already available. Source
PNGs are under `art_src/branding/`; native sprites are `spr_front_logo`, `spr_front_emblem`,
`spr_front_parchment` and `spr_loading_greenmere/oakhaven/dunhollow`. No source image was overwritten.
`tools/register_branding.py` recreates their registered resources.

Keep the native splash, title, Continue/New Journey/Controls/Quit, Esc pause menu and loading flow.
Refine their art direction, composition, typography and transitions. The front end has 30 tips,
honest loading status, a save-replacement confirmation, corrupt-save feedback and held-key protection.
Loading performs real file/chunk work and pauses world time. Do not add fake percentages, a long
mandatory delay or accidental confirmation input leaking into play. The illustrated place captions
do not imply the corresponding island is already a playable map.

Create additional matching loading illustrations, grounded logo variants, readable small-scale
marks, medieval UI ornaments, portraits and environmental details where useful. Keep charcoal,
burgundy, antique gold and parchment cohesive. Light should come from weather, fire and daylight.
Animation may be expressive, but avoid shaking or flashing that obscures an input window. Make
motion skippable and provide reduced-motion options where practical.

## Continue the earlier game implementation brief

Bring the historical world into the existing native sandbox, with attention to believable wear,
working spaces, social hierarchy and competing accounts. A ruined watchtower should reveal its
purpose and abandonment through its construction, surroundings and testimony. Castle access,
household dress, seals, tools and a crowded landing should communicate power without exposition.
Preserve Gemini's maps, narrative and simulation; preserve ChatGPT's mechanics and equipment APIs.

Combat remains Undertale-inspired: FIGHT uses five distinct weapon interactions; ACT, ITEM and
MERCY remain meaningful; enemies attack through the enclosed dodge arena. Present sword timing,
greatsword charge/release, dagger rapid combos, bow aim/draw and spear reach with clearly different
layouts, understandable controls, weapon animations, damage/combo/critical feedback and sound hooks.
Do not turn this into a card battler or a set of identical recolored timing bars. Cards support skill.
Keep Might × Fervor, Blazon and equipment behavior intact. Coordinate shared behavior changes.

Prioritize the large readable foe, fair telegraphs, visible damage, smooth attack/defense transitions,
clear inventory/socket information and understandable party actions. The checkpoint and burned mill
need physical visual consequences. Galahalt's retinue testimony, the new Oakhaven hearing, cartage
inquiry and local captain appointment should retain their delayed and one-time consequences.

Preserve organic discovery and minimal guidance after a short introduction. No compulsory arrows,
undiscovered quest lists or automatically acquired omniscient news. Show interaction opportunities
with restrained contextual feedback. The war acts without Rowan. There are four planned kingdom
endings, including catastrophic collapse through insufficient intervention; the existing four
Greenmere season epilogues are local outcomes with continued play, not those final sequences.

## Collaborate and finish

Use a separate Git branch/worktree. Inspect recent commits and working changes. Add modular scripts,
objects and resources; preserve other agents' assets. Coordinate shared event, room and `.yyp`
integrations and retain the public encounter and Chronicle interfaces. Never overwrite another
agent's live working directory. Do not edit the remote Google documents as a side effect.

Run `node tests/run_all.cjs`, compile this exact checkout in native GameMaker, and play it. After a
fresh build, `tools/run_native_qa.py` can run the follow-through and original Chronicle walkthroughs
with a specified runner and build directory. It requires `game.ios`, `options.ini` and `splash.png`
from that build. Never launch a bare runner. Test Continue, new game with an existing save, all five
weapons, death/recovery, menus, interactions, party, trade and save/load. Preserve player saves.

Update both local canonical documents and the ledger. Report what you built, changed, invented,
tested and still need from Gemini/ChatGPT. Distinguish actual native play from automated simulation.
Fix problems you find. Deliver a cohesive playable improvement with reviewable commits, screenshots
from the actual native build and honest remaining limitations.
