# Blackthornes Pets

A WoW: Forever addon for everything to do with pets, for **hunters and
warlocks**: the hunter's pet and stable, and the warlock's demons.

Built for the WoW: Forever client (`## Interface: 16001`), without Ace3 or
LibStub, matching
[Blackthornes Equipment](https://github.com/Blackthornes/Blackthornes_Equipment),
[Blackthornes Tradeskills](https://github.com/Blackthornes/Blackthornes_Tradeskills)
and [Blackthornes Farmer](https://github.com/Blackthornes/Blackthornes_Farmer).
They share a palette and a framework on purpose.

So far the pets window shows the pet that is out: its happiness (and the
damage that costs), loyalty, experience, training points and what it eats. The
window also shows the food in your bags the pet will eat, best first, with a
Feed button that feeds it the lowest-level food that still does full good.
While the pet needs feeding, a small Feed button also sits just above the
quest tracker, so it can be fed without opening the window. A
hunter gets a warning in chat and in raid-warning text when the pet stops
being happy, and another when food it eats runs low; both can be changed in
the settings window. Which diet each food is comes from `Data/PetFood.lua`,
by English item name: a food missing from it is not offered.

For a hunter, a tameable beast's tooltip lists the pet skills taming it would
teach, green for a skill you already know and red for one you don't. Which
beast teaches what comes from Classic 1.12's own table, in
`Data/BeastSkills.lua`. Opening the Beast Training window once lets the addon
read every skill you know; `/bpet taming` lists them.

There is also a minimap button and `/bpet probe`, which checks which pet calls
the client supports.

## Install

### Linked to your working copy (recommended while developing)

Run this once, and from then on testing a branch is pulling it and typing
`/reload`:

```powershell
.\tools\link.ps1
```

It junctions `Interface\AddOns\Blackthornes_Pets` to this folder, so the
client reads your checkout directly. Nothing is copied, so there is no deploy
step to forget.

Two things `/reload` will **not** pick up, because the client only reads them at
startup:

- a file that was **added, removed or renamed**
- any change to **`Blackthornes_Pets.toc`**

After pulling a branch that did either, restart the client once.

### Copied into the client

```powershell
.\deploy.ps1              # syntax check, lint, then mirror into Interface\AddOns
.\deploy.ps1 -SkipCheck   # skip the checks (not recommended)
```

Both scripts default to `D:\Blizzard\World of Warcraft\_classic_beta_`. Pass
`-GamePath` if the client lives somewhere else.

The addon folder name has to stay `Blackthornes_Pets`, matching the `.toc`
inside it. If they differ, the client ignores the folder and says nothing.

## Use

```
/bpet            open the pets window (so does clicking the minimap button)
/bpet help       list every command
/bpet probe      check what this client supports for pets; it only reads
/bpet settings   open the settings window (so does right-clicking the minimap button)
/bpet minimap    show or hide the minimap button
/bpet taming     list the pet skills this hunter knows
```

The settings window is also under the game's Options > AddOns.

`/pets` works too.

## Layout

| Folder | What is in it |
|---|---|
| `Core/` | Namespace, module registry, event dispatch, slash commands, saved variables |
| `Data/` | Tables the addon reads: pet food diets and what taming each beast teaches |
| `Logic/` | The pet rules, kept apart from the game so they can be tested (none yet) |
| `UI/` | Theme, widgets, the minimap button, the pets window and the settings window |
| `Probe/` | `/bpet probe`, which checks what the running game actually supports instead of guessing |
| `tools/` | Checks, tests and the link script. Not shipped to the client |
| `docs/` | What the Forever client actually does, found with `/bpet probe`. Not shipped |

`Blackthornes_Pets.toc` lists every Lua file in load order. A file that is
not in it does not load, and WoW says nothing about it.

## Development

```bash
python tools/syntaxcheck.py   # parse every Lua file with a real 5.1 parser
python tools/lintcalls.py     # find calls to methods, and constants, never defined
python tools/runtests.py      # run the logic tests outside WoW
```

`tools/` requires `lupa` (`python -m pip install --user lupa`).

The checks exist because WoW silently disables an addon whose first TOC file
fails to compile, and because a call to a method that no longer exists is valid
Lua that fails only when that line runs. `deploy.ps1` runs the first two before
it copies anything, and `.github/workflows/tests.yml` runs all of them on every
push.

The tests load the addon against a stub client (`tools/testenv.lua`), reading
the file list straight from the TOC. A new test is a new `tools/test_*.lua`
file and nothing else.

## Releasing

Releases are cut by pushing a tag like `v0.1.0`.
`.github/workflows/release.yml` then:

1. refuses the tag unless `CHANGELOG.md` opens with a `## 0.1.0` section
   (`tools/check_release.py`);
2. runs the tests;
3. builds the player-facing zip with the
   [BigWigs packager](https://github.com/BigWigsMods/packager), uploading
   nothing;
4. checks that zip is clear to post (`tools/check_package.py`): only the
   addon's own files, and nothing that looks private, such as a Windows path,
   an email address, a saved-variables dump or a token;
5. only then uploads that same zip to each site with a token, and attaches it
   to a GitHub release.

To release from GitHub Desktop: add the new version's section to the top of
`CHANGELOG.md` and merge it to `main`, pull `main`, then **History**, right-click
the newest commit, **Create Tag...**, name it `v0.1.0`, and **Push origin**.

The version is never typed by hand. The TOC says
`## Version: @project-version@` and the packager fills in the tag. Running
straight from a clone there is no packager, and the addon calls itself a
"dev build". The middle number moves for new behaviour, the last for fixes
alone; a tag like `v0.2.0-beta1` is uploaded as a beta.

`.pkgmeta` leaves `tools/`, `docs/`, `deploy.ps1`, `CLAUDE.md` and this README
out of the zip. The CurseForge project is 1720056, on the `X-Curse-Project-ID` line of the TOC.
Uploading also needs a `CF_API_KEY` repository secret in the repository's
settings on github.com. Without both, the workflow
still builds and checks the zip but uploads nothing to CurseForge.
