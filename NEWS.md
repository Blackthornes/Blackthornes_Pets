# News

What each release says in the Discord server's #general channel: a few
short bullets per version, in plain words for players, saying what they'll
notice, then one line thanking, by their Discord name, everyone whose
feedback or report led to the changes (each name once; no line when nobody
asked). Each release PR writes the new version's section here next to its
CHANGELOG.md section, and after the upload `tools/post_general.py` posts it
under a line with the addon's name and version that points players to
#announcements for the full list. No link or addon card goes with it. This
is the only report that names players. A version with no section here posts
nothing in #general.
This file does not ship in the addon, but its newest sections do, without
the thanks line: `python tools/make_whatsnew.py` writes them into
Core/WhatsNewText.lua for the in-game What's New window. Run it after
writing a section; the release check refuses a tag while it is behind.

The window shows new features only. Write a section's features first, then
a "Fixes and changes:" line with the fixes and other changes under it: those
go to Discord but stay out of the window, and a section of only fixes puts
nothing in it. Say what each feature does in a few plain words, the way you'd
tell a friend: no hype, no questions to the reader, no exclamation marks
outside the thanks line, no dashes as punctuation, no "now you can". The
tool prints a note for a shipped line that reads like an advert.

## 0.18.0

Fixes and changes:

- The pets window has a new look.
- The hours your food lasts are right now.

## 0.17.0

- The pets window shows how your pet fights: health, attack speed, damage, attack power, armor and resistances.

Fixes and changes:

- Various fixes to Pets.

## 0.16.1

Fixes and changes:

- Several bug fixes for feeding and the Compendium.

## 0.16.0

- This is the largest AddOn update so far across the whole suite of Blackthornes addons.
- The pet arrow lies back like a compass on the ground. It's a bit smaller, too.
- If the arrow would cover Farmer's XP bar, it sits just under it instead.
- Settings has an About page with the Discord invite and how to report a bug.
- Beasts spotted in dungeons still get a spot on the map you can follow.

Fixes and changes:

- What's New only shows new features now.

## 0.15.1

Fixes and changes:

- Tamed pets keep the right skill ranks.
- No more Lua error from the Pet care key in dungeons.

## 0.15.0

Fixes and changes:

- Foxes show what they eat in the Compendium.
- The Compendium uses the dark list look.

## 0.14.0

- The Compendium's family picker is a dropdown list.

Fixes and changes:

- The Compendium's scroll bar can be dragged without moving the window.
- Sort by Speed to see the fastest pets first. Click again for the slowest.

Thanks Ezmode for the report!

## 0.13.0

- Pets is in Deutsch on a German client.

Fixes and changes:

- Feeding, taming and the map work on German clients.

## 0.12.0

- The Pet care key casts Mend Pet in a fight.
- A key to dismiss your pet.

Thanks Ezmode for the ideas!

## 0.11.0

- The feed key is now one Pet care key: it calls, revives or feeds your pet, and warlocks get their last demon.
- Tame the beast the arrow was leading you to and the arrow goes away by itself.

## 0.10.1

- The Pet Compendium shows a new tame and its speed right away.

## 0.10.0

- The Pet Compendium now shows how fast each beast attacks, so you can find the fastest pet in a family.

## 0.9.1

- Demons don't show an empty training points line anymore.
- Dragging the beast arrow won't count as a click anymore.

## 0.9.0

- Your pet now eats food that buffs you last, so you keep it for yourself. You can also tell it to never eat that food.
- You can pick a new window look that matches the game's own windows. The gold look is still the default.
- The Feed button doesn't get in the way of other windows anymore, plus a few other fixes.

Thanks Ezmode for the buff food idea!

## 0.8.0

Hey everyone! A new Pets update just went up.

You can see which version you have in the corner of the pets window and on the minimap button. Thanks Ezmode for the idea!

Settings got a makeover. It has pages, a search box and bigger text if you want it. Pets also runs lighter now.

Restart the game fully after you update. Have fun!

## 0.7.0

Hey everyone! A small Pets update just went up.

If you use TomTom, the beast arrow now hands the beast's spot to TomTom so you only see one arrow on your screen. Thanks Ezmode for asking!

Restart the game fully after you update. Happy taming!
