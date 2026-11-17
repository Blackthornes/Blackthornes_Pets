-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.12.0", lines = {
        "Blackthornes now has one button on your addon bar.",
        "Settings pages sit in the same order in every Blackthornes addon.",
        "At a vendor, the window opens on Butler.",
        "Various bug fixes for Pets.",
    } },
    { version = "1.11.0", lines = {
        "The Feed button and Pet XP bar can sit on the game's pet frame.",
        "The Pet page shows only what fits your class.",
        "Settings has an All Addons page for what every addon shares.",
        "The window can dock in more places and you can resize it by hand.",
    } },
    { version = "1.10.0", lines = {
        "Windows now remember where you drag them, so they come back in the same spot.",
        "A new button on the General page puts every window back where it started.",
        "The Feed button waits while your pet is still eating, and counts down.",
    } },
}
