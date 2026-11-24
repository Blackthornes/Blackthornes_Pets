-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.17.0", lines = {
        "The Pet tab shows the pet's bars beside its name, and skills in two columns with icons.",
        "New skills show in gold.",
        "A faint paw shows when no pet is out.",
        "The Compendium has icons for families and skills.",
    } },
    { version = "1.16.0", lines = {
        "Windows fold into a round button with the Pets badge.",
    } },
    { version = "1.15.0", lines = {
        "Panels and rows have a warm brown-black look.",
        "The food line links in chat and shows the item's tooltip.",
        "Pets has its own key in Key Bindings.",
    } },
}
