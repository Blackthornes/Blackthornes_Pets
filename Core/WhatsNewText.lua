-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.2.0", lines = {
        "The search and the family picker sit in the header, the tick boxes share one row, and rows take one line with sort arrows and a right-click menu.",
        "A new General page holds Window Style, Text Size, Window Size and Effects.",
    } },
    { version = "1.1.0", lines = {
        "One minimap button now covers every Blackthornes addon you have. Click it to pick one. Turn it off with Combine Addon Buttons on the General page.",
        "Show on Map puts a gold marker with the beast's name on the spot.",
    } },
    { version = "1.0.1", lines = {
        "The small Feed button has the gold plaque look.",
    } },
}
