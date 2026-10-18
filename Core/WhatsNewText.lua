-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "0.20.0", lines = {
        "The taming skills on a beast's tooltip can be Off, Shift or Always. You pick in Settings.",
    } },
    { version = "0.19.0", lines = {
        "Pets speaks Simplified Chinese, French, Spanish and Russian now if your game is in one of those.",
    } },
    { version = "0.17.0", lines = {
        "The pets window shows how your pet fights: health, attack speed, damage, attack power, armor and resistances.",
    } },
}
