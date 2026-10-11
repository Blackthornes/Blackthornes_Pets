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
quest tracker, so it can be fed without opening the window. One "Pet care"
key does whatever the pet needs: it calls the pet when none is out, revives
it when it is dead, and otherwise feeds it the same food, hungry or not. In a fight, with the pet
alive, the same key casts Mend Pet. A second key, "Revive pet", casts Revive
Pet and nothing else. For a
warlock it summons the last demon you used. Set the key under Options,
Keybindings, AddOns, Blackthornes Pets. With nothing to do it says why in
chat. A
hunter gets a warning in chat and in raid-warning text when the pet stops
being happy, and another when food it eats runs low; both can be changed in
the settings window. Which diet each food is comes from `Data/PetFood.lua`,
by English item name: a food missing from it is not offered.

For a hunter, a tameable beast's tooltip lists the pet skills taming it would
teach, green for a skill you already know and red for one you don't. Which
beast teaches what comes from Classic 1.12's own table, in
`Data/BeastSkills.lua`. Opening the Beast Training window once lets the addon
read every skill you know; `/bpet taming` lists them.
Beasts new to WoW: Forever aren't in the Classic table, so the addon writes
down what a beast really teaches each time you tame one (a freshly tamed pet
knows exactly those skills), and shows that on the beast's tooltip from then
on. `/bpet tamed` lists everything recorded so far.

The Pet Compendium (`/bpet compendium`, or the button in the pets window and
in Settings) lists every beast a hunter can tame: its family and diet, level,
zone and spot, rank and respawn, attack speed (fastest first in each family
when sorted by it), and what taming it teaches, with filters for
what you can tame now, rares, skills you lack and what WoW: Forever has shown.
Classic's list comes from `tools/make_compendium.py`; Forever's findings from
`tools/forever_beasts.py` (see the top of each for how to rerun them).

Shift-click a beast in the compendium and the **beast arrow** points the way
to it: a gold dial that turns as you turn, with the distance in yards and a
green check once you are there. A beast with a zone and no spot points at
the middle of the zone and says so. The compendium's **Arrow** button,
`/bpet arrow` or Settings shows or hides it; its red gem closes it, and it
hides inside dungeons. Tame the beast it points at and it puts itself away.
It is Farmer's goal arrow and Equipment's quest
arrow brought over, and only one of the three is on screen at a time: the
one aimed last shows, and the others wait until it is put away.
With TomTom installed, the beast arrow hands its place to TomTom as a
waypoint and its own dial stays hidden, so only TomTom's arrow is on screen;
places TomTom cannot point at show on the dial as before. Untick **Use
TomTom** in Settings, or type `/bpet arrow tomtom off`, to keep the dial.

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
/bpet tamed      list the beasts you have tamed and what each taught
/bpet compendium open the Pet Compendium; add words to search it (/bpet compendium fox)
/bpet arrow      an arrow to a beast from the compendium (on, off, clear, check, tomtom, reset)
```

The settings window is also under the game's Options > AddOns. Its pages
(Hunter pet, Compendium, General) are picked along the top. Hover a setting
to see what it does, or tick **Show descriptions** to see it under every
row; **Find a setting** searches every page. **Text size** on the General
page makes all of the addon's text a point or two bigger after a `/reload`.
Every command above has a button there too.

`/pets` works too.

## Layout

| Folder | What is in it |
|---|---|
| `Core/` | Namespace, module registry, event dispatch, slash commands, saved variables |
| `Data/` | Tables the addon reads: pet food diets and what taming each beast teaches |
| `Logic/` | The pet rules, kept apart from the game so they can be tested (none yet) |
| `UI/` | Theme, widgets, the house window frame, the minimap button, the pets window, the settings window and the Pet care key |
| `Media/` | The window frame's art (`Frame/*.tga`), drawn by `tools/make_frame_art.py` |
| `Probe/` | `/bpet probe`, which checks what the running game actually supports instead of guessing |
| `tools/` | Checks, tests, the frame art script and the link script. Not shipped to the client |
| `docs/` | What the Forever client actually does, found with `/bpet probe`. Not shipped |

`Bindings.xml` names the Pet care key binding; the client loads it by itself,
so it is not in the TOC.

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
