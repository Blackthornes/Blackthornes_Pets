# Notes for Claude

Read this before working in this repo. It is one of five Blackthornes addons
(Farmer, Tradeskills, Equipment, Pets, Butler), each in its own repo. What one
needs to know about another lives in the repos, in this file and in theirs. Keep them current: when a change here leans on something
new in another addon, or a standing rule from the owner applies to all of them,
add it to each file.

Nothing private goes in this file (no local paths, emails or account names).
It never ships: `.pkgmeta` leaves it out of the zip and
`tools/check_package.py` refuses it.

## Long notes live in Docs/claude-notes.md

CLAUDE.md is kept short on purpose (a 130 to 170 KB one ran every session out of room). Every feature history, call list and sister note was moved word for word, nothing deleted, into `Docs/claude-notes.md`. Grep a heading there and read about 150 lines at a time; never read it whole. Add new feature notes to that file, not here. **Before you change any saved key, global, call between addons or shared file named in a section below, read that section first**: the cross-addon calls (`What ... calls here`, `Sending ...`, `The goal arrow`, `The one window` and the like) must stay stable and are changed in both repos together.

Sections there:

- Checking a change
- What this addon is for
- How this repo was set up
- What Butler calls here
- The Skills card and one window with tabs
- Demon books on the Skills card
- Soul shards
- The Shard Tracker
- The Pet XP bar
- Healthstone and Soulstone reminder
- The one window
- The shared minimap button
- The settings pages (from Tradeskills)
- Off, Shift or Always on tooltips
- German translation
- Simplified Chinese translation
- French, Spanish and Russian translations
- The house frame (Titanforged)
- Still eating (the feed hold)
- The gold plaque
- The fold gem
- The Blizzard window style
- Reading the probe
- Discord
- What's New
- The About page and the note
- The sister note
- One look across the addons (the house kit)
- The Pet page shows your class
- On Pet Frame (the Feed button and the Pet XP bar)
- Standing rules in full
- Shelves, dock places and the All Addons page
- The swap gem (One Window toggle, 2026-11-19)
- The look upgrade (2026-11-24)

## Checking a change

Before every PR, follow `.claude/skills/verify/SKILL.md`: a bug fix starts
with a test that fails the way the game failed; act the steps out in the
fake game; run `python tools/check_house_rules.py` (player words and dark
glass, lines this change adds) and `python tools/checklist_for_change.py`
(the items in `Docs/change-checklist.md` this change touches). Every PR
body ends with `Checked:` and `Not checked:` lines. After three failed
rounds, stop and ask the owner. A miss a diff could have shown gets a
checklist item in the fix's PR. Details under "Checking a change" in
`Docs/claude-notes.md`.

## Standing rules (short; full wording in Docs/claude-notes.md, "Standing rules in full")

Each is in every addon's notes; keep them the same. Grep the full wording
before leaning on one.

- **One key per character.** A character is its GUID in saved data and in
  calls between addons, never a name. An unreadable GUID (a dungeon) means
  "not sure who's playing": write nothing under another key. Old records
  stay readable, nothing is deleted. Ask the one test (`Alts.PlayerGUID()`
  in Equipment, `Errands:IsMe` in Butler, `Characters:Same` in Tradeskills,
  `Goals:IsOwner` in Farmer), and every errand refuses the character playing.
- **Mute All Sounds.** Every `PlaySound` and `PlaySoundFile` asks
  `ns.Muted()` first, new ones too. Saved as `muteSounds` and
  `muteSoundsAt` (never rename). `/bpet mute [on|off]`. `UI/SharedChoices.lua`.
- **Writing for players.** Plain, warm, sixth grade. Short sentences, no
  hype, no filler, no em-dashes, no questions to the reader. deDE changes
  with the English, informal "du". `About.NOTE` is the owner's wording.
- **Plain prose everywhere** (the owner, 2026-11-21): notes, commits, PRs
  and replies as well as player words. Say plainly what you mean, with no
  stock figures of speech. Use a short word where one will do. Cut every
  word you can, but keep the context the reader needs. Use the active
  voice. Use everyday words or the reader's own term, not foreign phrases,
  jargon or words made up during the work. Defaults, not hard limits.
  Check all prose against them before handing it over.
- **Every list is dark glass.** `glass` and `glassAlt` in turn, a 1 px
  `border` line under each, `glassHover` and a gold edge under the mouse,
  `glassActive` for the picked row. Gradients fade through
  `Theme.LightGradient` or are hidden, never SetAlpha alone.
- **No red gems on a rim's ends** (the owner, 2026-11-22): never put red
  circles on the left and right of a window, plaque or pop-up, in any
  addon. The red close gem (the X) and the corner gems stay.
- **Clear to post.** Nothing is published or uploaded without the owner's
  go-ahead. He tags releases himself.
- **Keep his data safe.** Never commit saved variables, tokens or anything
  from his machine. Never ask him to paste a key.
- **Changelogs come from git history,** never from asking the owner.
- **A checkout shows the real version.** `ns.RELEASED_VERSION` in
  `Core/Init.lua` matches the newest `## X.Y.Z` in CHANGELOG.md; the
  release PR changes both.
- **Every reply that ships code** says the PR is ready and whether the game
  needs `/reload` or a full restart (a file added, removed or renamed, or
  the TOC changed). Never merge on github.com or pull with GitHub Desktop.
- **CurseForge descriptions are features only.**
- **Forever is not retail or classic for classes or pets.** Never assume a
  pet API exists: check with `/bpet probe`, record it in
  `docs/FOREVER_API_FINDINGS.md`.
- **Smooth play first, never at the cost of looks.** Nothing on a timer
  rebuilds a whole list when one thing moved. Coalesce bag, loot, cast and
  skill events. Skip hidden windows. Spread big work over frames.
- **The client is WoW: Forever** (`## Interface: 16001`, modern Lua). Read
  client values inside a pcall; register events through `ns.RegisterEvent`.
- **Fold in fresh data at each release,** after Farmer's:
  `tools/forever_beasts.py --harvest <Blackthornes_Farmer/Data/Data_Harvested.lua> <Blackthornes_Pets.lua>`.
  Committed as "Refresh shipped data", never announced, never the save.
- **Window spots.** Windows remember where they were dragged:
  `oneWindowDockSpots[place]`, `windowSpots[key]` and `foldedWindows[key]` (never rename),
  `SharedWindow.KeepSpot(frame, key)`, `windows reset` runs
  `SharedWindow.ResetAllSpots`. SharedWindow.lua is FILE_VERSION 16 (the round button, the swap gem, Butler at the vendor, no placing mid-drag, shelves,
  dock places, All Addons gear) and WhatsNew.lua FILE_VERSION 7.

## Big files (read these in pieces)

Reading a huge file whole runs the session out of room. Sizes are
from 2026-11-03 and only grow. Find more with `find . -name '*.lua' | xargs wc -lc | sort -n`.

- Never read a file below whole. Use `grep -n` to find the spot, then read
  about 150 lines at a time (Read with `offset` and `limit`).
- Never read data tables or locale files whole. Grep them for one key.
- CLAUDE.md is big too. Grep it for a heading, then read that part only.
- Generated files (`Data/`) are written by their `tools/` script. Never edit
  them by hand, and never open them to see what they hold.

Data tables (generated, grep only): `Data/Compendium.lua` 585 lines, 85 KB; `Data/ForeverBeasts.lua` 40 KB; `Data/PetTraining.lua`, `Data/BeastSkills.lua`, `Data/ForeverPetFood.lua` about 20 KB each.

Locale (grep one key, never read): `Locale/ruRU.lua` 603 lines, 43 KB; `deDE`, `frFR`, `esES`, `zhCN` are each about 603 lines, 32 to 35 KB.

Notes (grep a heading, never read whole): `Docs/claude-notes.md` 1100 lines, 67 KB; `CHANGELOG.md` 536 lines, 25 KB.

Code:
- `UI/Widgets.lua` 1630 lines, 62 KB: shared widgets.
- `UI/MainWindow.lua` 1630 lines, 63 KB: the Pet tab.
- `UI/WhatsNew.lua` 1245 lines, 48 KB and `UI/SharedWindow.lua` 1082 lines, 43 KB: shared.
- `UI/CompendiumWindow.lua` 970 lines, 39 KB: the Compendium tab.
- `UI/Settings.lua` 911 lines, 39 KB: Settings pages.

Over 800 lines, same rule: `UI/SettingsPages.lua`, `UI/ShardTracker.lua`, `Logic/Travel.lua`, `Logic/Food.lua`.

The same file lives in several addons: `UI/SharedWindow.lua`, `UI/WhatsNew.lua`, `UI/SettingsPages.lua`, `Logic/Travel.lua`. A fix to one belongs in all.

## Running the tests (keep the output small)

- `python tools/runtests.py` prints one line when everything passes, and a
  failing suite's last lines and error when one fails. `--verbose` prints
  every line (212 of them): do not use it in a session.
- One suite while you work: `python tools/runtests.py food petxpbar`. The
  whole run once before the PR.
- `python tools/syntaxcheck.py` lists only failures; `--verbose` lists every file.
- Pipe anything else long through `tail -20`.
