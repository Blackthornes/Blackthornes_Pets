-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "0.15.0", lines = {
        "A new What's New window shows what changed after each update.",
        "Foxes now show what they eat in the Compendium.",
        "The Compendium got the new dark look.",
    } },
    { version = "0.14.0", lines = {
        "Pick a family in the Compendium from a dropdown list.",
        "You can grab the Compendium's scroll bar now without moving the whole window.",
        "Sort by Speed to see the fastest pets first. Click again for the slowest.",
    } },
    { version = "0.13.0", lines = {
        "Pets speaks German now on German game clients.",
        "Feeding, taming and the map work on German clients too.",
    } },
}
