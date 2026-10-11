# Changelog

Versions follow [semantic versioning](https://semver.org): the middle number
moves for new behaviour, the last for fixes alone. The newest version goes at
the top; a release is refused if its version has no section here.

## 0.10.1

For WoW: Forever (interface 16001). No files were added, so `/reload` is
enough after updating.

- **Fixes:** with the Pet Compendium open, a new tame or a pet's attack
  speed shows at once, without a click or a `/reload`.

## 0.10.0

For WoW: Forever (interface 16001). Files were added, so restart the game
fully after updating (`/reload` is not enough).

- **Speed in the Pet Compendium:** a new Speed column shows the seconds
  between a beast's swings, green when faster than 2.0 and amber when
  slower. Clicking the heading puts the fastest of each family first, and
  clicking again puts the slowest first. A pet you tame has its real speed
  read off it, marked "tamed".
- **More Forever beasts:** six more beasts seen on Forever join the
  Compendium, and four have better spots.
- **Fixes:** in the Blizzard window style, the Window style box fits its
  words and the Reload buttons sit under their setting.

## 0.9.1

For WoW: Forever (interface 16001). No files were added, so `/reload` is
enough after updating.

- **Fixes:** a warlock's demon no longer shows an empty "Training points"
  row. Dropping the beast arrow's dial after a drag never counts as a click
  or eats the next one. TomTom gets the beast's place again after the arrow
  or Use TomTom is turned off and on. "Open Pets settings" in the game's
  options leaves the game's panel alone. The Blizzard window style's
  portrait ring stays silver on every client.

## 0.9.0

For WoW: Forever (interface 16001). A file was added, so restart the game
fully after updating (`/reload` is not enough).

- **Buff food is fed last:** the Feed buttons and the Feed pet key only use
  food that makes you Well Fed when nothing else the pet eats is in your
  bags. Settings > Hunter pet > Feeding has a new "Never feed it" tick box
  (off by default) to leave it out altogether.
- **Window style:** Settings > General has a new Window style switch.
  Titanforged stays the default. Blizzard gives the windows the game's own
  look, with no glows. A change takes effect after a reload.
- **Pet Compendium:** two more beasts seen on Forever (Timber Wolf and Young
  Wolf in Elwynn Forest).
- **Fixes:** buff food is no longer fed before its tooltip has loaded; the
  pets window's Feed button no longer shows through Settings or the
  Compendium, or covers the version number; the beast arrow's dial comes back
  when TomTom drops its waypoint; the compendium offers a pin only where it
  knows a spot; Put it back resets the arrow too; the minimap button follows
  the cursor on a resized minimap; and fixes to the Blizzard window style.

## 0.8.0

For WoW: Forever (interface 16001). A file was added, so restart the game
fully after updating (`/reload` is not enough).

- **The version number** shows in the pets window's corner for every class and
  in the minimap button's tooltip.
- **New Settings window** like Tradeskills': pages along the top (Hunter pet,
  Compendium, General), a tooltip on every row (or **Show descriptions**),
  **Find a setting**, **Text size**, and buttons for Food, Your pet skills,
  Beasts you tamed, the pets window, Client check and Commands.
- **Less CPU:** the bags are read for food only when they change, and unit
  events come only for you and your pet.
- **More Forever beasts in the Compendium:** eight more seen on Forever,
  with their real spots and levels.

## 0.7.0

For WoW: Forever (interface 16001). A file was added, so restart the game
fully after updating (`/reload` is not enough).

- **TomTom:** with TomTom installed, the beast arrow's spot goes to TomTom as a
  waypoint and the dial stays hidden, so only one arrow is on screen. Places
  TomTom can't point at still show on the dial. Turn it off with the
  **Use TomTom** tick box in Settings.

## 0.6.0

For WoW: Forever (interface 16001). Files were added, so restart the game
fully after updating (`/reload` is not enough).

- New **beast arrow**: Shift-click a beast in the Pet Compendium to bring
  up a gold dial that turns as you turn and points at the beast's spot,
  with its name and level on the plate, the distance in yards and a green
  check once you are there. A plain click still pins the map. A beast with
  a zone but no spot points at the middle of the zone and says so; one in
  a dungeon or on the other continent only gets its zone named. The
  Compendium has an **Arrow** button, Settings has a Beast arrow row, and
  `/bpet arrow on|off|clear|check|reset` works too. It is off by default,
  hides inside dungeons and closes with its red gem.
- Only one Blackthornes arrow is on screen at a time: with Farmer's goal
  arrow or Equipment's quest arrow also showing, the one turned on or
  aimed most recently is drawn and the others wait.

## 0.5.0

For WoW: Forever (interface 16001). Files were added, so restart the game
fully after updating (`/reload` is not enough).

- New **Pet Compendium** (`/bpet compendium`, or the button in the pets
  window and in Settings) lists every beast a hunter can tame: the 535
  from Classic plus the beasts and skills WoW: Forever has added, like the
  fox family and the new rares. Each row shows the family, level (red when
  above yours), zone and spot, rank, and what taming it teaches (green if
  you know it, red if not). Hover a row for the diet, other zones, spawn
  count, rare respawn time and source. Click a row to pin the beast on
  your map, or a heading to sort by it.
- Filter the Compendium by family, search names, zones and skills, or tick
  Tameable now, Rares only, Teaches me something new or Seen on Forever.
  Beasts with Forever data are tagged **Forever** in green, and Forever's
  data always wins over Classic's. Nothing is guessed: a detail no source
  gives shows "Not known yet".
- Your own tames now also remember the beast's family, zone and spot, and
  feed the Compendium.
- Fixed a failed or interrupted Tame Beast recording your old pet's skills
  as what that beast teaches when you called the old pet back soon after.
  A pet is now only recorded when it is the beast being tamed.

## 0.4.3

For WoW: Forever (interface 16001). No files were added, so `/reload` is
enough after updating.

- The minimap button now sits on the minimap's ring beside other addons'
  buttons, instead of floating just outside it.

## 0.4.2

For WoW: Forever (interface 16001). No files were added, so `/reload` is
enough after updating.

- Fixed a Lua error from the tame recorder when the game hid a spell's id
  (it happens in instances).
- Each pet now gets its own feed warning and low food warning, so calling
  out a different pet no longer skips them.
- In the pets window, a value long enough to wrap onto a second line no
  longer runs into the row below.
- Ticking **Only when unhappy** now moves the Feed button by the quests
  straight away.

## 0.4.1

For WoW: Forever (interface 16001). Nothing in the addon itself changed, so
`/reload` is enough after updating.

- New versions are now announced in the Blackthornes Discord, in the
  #announcements channel.

## 0.4.0

For WoW: Forever (interface 16001). This version adds files, so fully
restart the game after updating; `/reload` is not enough.

- New look: the pets window wears a gold metal frame with corner gems, a
  round portrait holding a gold paw, a title plate across the top and a red
  gem to close it. Settings gets the plate and close gem. Buttons are raised
  gold-edged metal and the Feed buttons are solid gold. A light runs round
  the portrait as the window opens and a glint slides along the rim.
- Settings labels too long for their space wrap instead of being cut off.
- The quick Feed button above the quest tracker keeps its place and works
  the same in combat; only its look changes.

## 0.3.0

For WoW: Forever (interface 16001). This version adds files, so fully
restart the game after updating; `/reload` is not enough.

- A Feed pet key binding under Options, Keybindings, AddOns. It feeds the
  same food the Feed buttons would pick, hungry or not, so you can top your
  pet up. With no pet or no food it eats, it says why in chat. `/bpet food`
  shows which key is set and what it feeds.

## 0.2.0

For WoW: Forever (interface 16001). This version adds a file, so fully
restart the game after updating; `/reload` is not enough.

- Beasts new to WoW: Forever aren't in the Classic table, so each time you
  tame a beast the addon writes down what it really teaches and shows that on
  the beast's tooltip from then on. `/bpet tamed` lists every beast recorded.
- Fixed: right after logging in, the food warning could say the bags held
  nothing the pet would eat before the game had finished loading them.

## 0.1.0

The first release, for WoW: Forever (interface 16001). A new addon, so the
game needs a full restart after installing it.

- The pets window (`/bpet`, or click the minimap button) shows the pet that
  is out: its happiness and the damage that costs, loyalty, experience,
  training points and what it eats.
- The window shows the best food in your bags the pet will eat and how much
  is left, with a Feed button that feeds it the lowest-level food that still
  does full good.
- While the pet needs feeding, a small Feed button sits just above the quest
  tracker, so it can be fed without opening the window.
- A warning in chat and in raid-warning text when the pet stops being happy
  (or only once it is unhappy), and another when the food it eats runs low.
- For a hunter, a tameable beast's tooltip lists the pet skills taming it
  would teach, green for a skill you already know and red for one you don't.
  Open the Beast Training window once so the addon can read what you know;
  `/bpet taming` lists it.
- `/bpet food` lists the food in your bags and whether your pet will eat it.
- Settings window (`/bpet settings`, right-click the minimap button, or the
  game's Options > AddOns) for the warnings, the quest-tracker Feed button,
  the taming skills and the minimap button.
