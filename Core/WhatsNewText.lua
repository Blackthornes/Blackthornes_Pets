-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "0.21.0", lines = {
        "The Pet tab shows what your pet knows, what it can learn now and what comes later, and where the pet trainer is.",
        "Pet, Compendium and Settings are tabs in one window now.",
        "Every window has a size grip, and the General page has an Effects choice.",
    } },
    { version = "0.20.0", lines = {
        "The taming skills on a beast's tooltip can be Off, Shift or Always. You pick in Settings.",
    } },
    { version = "0.19.0", lines = {
        "Pets speaks Simplified Chinese, French, Spanish and Russian now if your game is in one of those.",
    } },
}
