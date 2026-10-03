# Changelog

Versions follow [semantic versioning](https://semver.org): the middle number
moves for new behaviour, the last for fixes alone. The newest version goes at
the top; a release is refused if its version has no section here.

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
