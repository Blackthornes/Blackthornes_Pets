-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.19.0", lines = {
        "A new My Pets tab lists every pet you own, out and in the stable.",
        "The Compendium has Skills to Find and a Beast Sheet for each beast.",
        "The Pet tab has a Next Step line and an optional Pet Strip.",
        "The Skills card has a List and Grid switch.",
        "The Shard Tracker shows Soulstone time and holder.",
    } },
    { version = "1.18.0", lines = {
        "The All Addons page in Settings has a Set Default button. Click Confirm and this addon's settings go back to how they started.",
    } },
    { version = "1.17.0", lines = {
        "The Pet tab shows the pet's bars beside its name, and skills in two columns with icons.",
        "New skills show in gold.",
        "A faint paw shows when no pet is out.",
        "The Compendium has icons for families and skills.",
    } },
}
