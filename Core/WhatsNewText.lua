-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.2.0", lines = {
        "The search and family picker are at the top. Each beast takes one line. Click a heading to sort, or right-click a beast for a menu.",
        "Settings has a new General page for how the windows look.",
    } },
    { version = "1.1.0", lines = {
        "One minimap button now covers every Blackthornes addon you have. Click it to pick one. Turn it off with Combine Addon Buttons on the General page.",
        "Show on Map puts a gold marker with the beast's name on the spot.",
    } },
    { version = "1.0.1", lines = {
        "The small Feed button has the gold plaque look.",
    } },
}
