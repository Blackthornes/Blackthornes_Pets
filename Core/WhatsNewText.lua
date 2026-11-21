-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.14.0", lines = {
        "Pets keeps a number of pet food in your bags. Butler can mail the extra to your bank alt. Turn it on in Settings, Pet page, Feeding.",
    } },
    { version = "1.13.0", lines = {
        "Every window has a gold gem on its title bar. Click it to switch between the one window and separate windows.",
    } },
    { version = "1.12.0", lines = {
        "Blackthornes now has one button on your addon bar.",
        "Settings pages sit in the same order in every Blackthornes addon.",
        "At a vendor, the window opens on Butler.",
        "Various bug fixes for Pets.",
    } },
}
