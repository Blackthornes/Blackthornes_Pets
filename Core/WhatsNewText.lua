-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.18.0", lines = {
        "The All Addons page in Settings has a Set Default button. Click Confirm and this addon's settings go back to how they started.",
    } },
    { version = "1.17.0", lines = {
        "The Pet tab shows the pet's bars beside its name, and skills in two columns with icons.",
        "New skills show in gold.",
        "A faint paw shows when no pet is out.",
        "The Compendium has icons for families and skills.",
    } },
    { version = "1.16.0", lines = {
        "Windows fold into a round button with the Pets badge.",
    } },
}
