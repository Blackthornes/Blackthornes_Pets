-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "0.19.0", lines = {
        "Pets speaks Simplified Chinese, French, Spanish and Russian now if your game is in one of those.",
    } },
    { version = "0.17.0", lines = {
        "The pets window shows how your pet fights: health, attack speed, damage, attack power, armor and resistances.",
    } },
    { version = "0.16.0", lines = {
        "This is the largest AddOn update so far across the whole suite of Blackthornes addons.",
        "The pet arrow lies back like a compass on the ground. It's a bit smaller, too.",
        "If the arrow would cover Farmer's XP bar, it sits just under it instead.",
        "Settings has an About page with the Discord invite and how to report a bug.",
        "Beasts spotted in dungeons still get a spot on the map you can follow.",
    } },
}
