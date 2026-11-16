# Pets UI cleanup (2026-11-16)

What was fixed in the cleanup PR, and what is recommended next. Nothing in
"Recommended" is built. Each one has a mockup and needs the owner's yes, and
any new player words need his approval in all six languages.

Mockups are in the project files under `previews/pets-ui-cleanup/`.

## Fixed in the cleanup PR

- **Meter names ran under their bars.** The Pet tab's Experience, Happiness
  and Loyalty bars started at a fixed 108. A long name (German
  "Zufriedenheit", or any name at the Larger text size) ran under the bar.
  The bars now start past the longest name (`UI.MeterStart`).
- **Compendium headings ran into each other.** Level and Speed were sized
  for the English words. "VELOCIDAD", "NIVEAU" and the sort arrow ran into
  the next heading. Columns now measure their heading and arrow, and the
  wide columns give up the room (`CompendiumUI.FitColumns`), so the list is
  no wider.
- **Test tools filled the thread.** `runtests.py` printed 212 lines and
  `syntaxcheck.py` 120 on every clean run. Both now print failures and the
  count only; `--verbose` shows all, and `runtests.py food` runs one suite.
- **CLAUDE.md's big-files list** now names the locale files, the other data
  tables, `Docs/claude-notes.md` and `CHANGELOG.md`, which were missing.

## Looked at and found sound

- Timers: the 15 second pet check takes the last bag scan unless something
  changed and skips the window while it is hidden. Bag, shard and stone
  events are coalesced. The Beast Arrow's driver rests while the arrow is
  off. Scroll and drag OnUpdates run only while dragging.
- Every movable frame is clamped to the screen, and buttons are never
  narrower than their label (`Widgets.CreateButton`).
- Settings row names wrap, and card rows on the Pet tab wrap and grow.

## Small things left (no visual change, not done here)

- `UI/TravelMap.lua` (shared with the other addons) keeps an OnUpdate
  running every frame with no trip set. It only counts to half a second,
  but it could rest until a trip starts. A fix belongs in every copy, so it
  goes through the coordinator.
- A Compendium row is 34 high, two lines. A beast with five or more skills
  could wrap its Teaches cell to a third line and touch the row below. Not
  seen in the shipped data; worth a test over the data before changing the
  row.
- `docs/` and `Docs/` both exist. On Windows they are one folder. Moving
  `docs/FOREVER_API_FINDINGS.md` into `Docs/` would end the confusion.

## Recommended (each needs a yes)

### 1. On-screen pieces stop piling up
Mockup: `01-first-spots.png`

First spots today, all top middle: warning cards at -150, the Beast Arrow
at -140 (about 160 tall), the Shard Tracker at -150, the Pet XP Bar at
-210. Guide Me's card starts at the right edge, where the quest list is.
The arrow already steps aside for Farmer's XP bar and nothing else.

Proposal: one shared "lane" (a small board in `_G`, like
`BlackthornesArrows` and `BlackthornesNotice`) where each piece the player
has not dragged takes the next free row, top to bottom, across all five
addons. Guide Me's first spot moves left of the quest list. A dragged piece
keeps its spot, and no saved key changes. Cross-addon, so it is one design
for all five.

### 2. Feed button and Pet XP Bar on the pet frame
Mockup: `02-pet-frame.png`

Proposal: a place choice for each, "On Pet Frame" or "Free". On Pet Frame,
the piece is placed by screen position beside the game's pet frame (read
only, never anchored to it, never hidden or changed, and never moved in a
fight, as the Feed button is placed today). Free is today's behavior.
Anyone who has dragged a piece keeps Free. New words: the choice and its
two values.

### 3. The window sits beside the stable and character sheet
Mockup: `03-dock-stable.png`

`SharedWindow.PLACES` covers auction, mail, vendor and trainer. Adding the
stable (`PET_STABLE_SHOW` / `PET_STABLE_CLOSED`) and the character sheet
(watched by HookScript, read only) would stop the Pets window opening over
them. `UI/SharedWindow.lua` is shared, so this is a FILE_VERSION bump in
all five. The events need a `/bpet probe` check on Forever first.

### 4. A shorter Pet page in Settings
Mockup: `04-settings.png`

- Show only the player's class: a hunter sees Feeding, Pet XP Bar and
  Taming; a warlock sees the Warlock section. The Compendium page is hunter
  only. An unreadable class shows everything.
- Rows that belong to a switch (Bar Width, Bar Height, Show Words,
  Level-Up Cheer; Tracker Size) show once the switch is ticked.
- "Bar Place:" and "Tracker Place:" go, since "Window Spots:" on General
  puts every piece back. (Right-click on the bar or tracker still resets
  just that one.)
- On General, "What's New:", "What's New After Updates:" and "What's New
  Motion:" could become one row with the button and two boxes.

No setting changes value and no saved key is renamed or removed.
