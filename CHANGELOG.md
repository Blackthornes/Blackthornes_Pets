# Changelog

Versions follow [semantic versioning](https://semver.org): the middle number
moves for new behaviour, the last for fixes alone. The newest version goes at
the top; a release is refused if its version has no section here.

## 0.1.0

The first release, for WoW: Forever (interface 16001). A new addon, so the
game needs a full restart after installing it.

- The pets window (`/bpet`, or click the minimap button) shows the pet that
  is out: its happiness and the damage that costs, loyalty, experience,
  training points and what it eats.
- The window lists the food in your bags the pet will eat, best first, with
  a Feed button that feeds it the lowest-level food that still does full
  good.
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
