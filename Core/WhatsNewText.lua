-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "0.14.0", lines = {
        "The Compendium's family picker is a dropdown list.",
    } },
    { version = "0.13.0", lines = {
        "Pets is in Deutsch on a German client.",
    } },
    { version = "0.12.0", lines = {
        "The Pet care key casts Mend Pet in a fight.",
        "A key to dismiss your pet.",
    } },
}
