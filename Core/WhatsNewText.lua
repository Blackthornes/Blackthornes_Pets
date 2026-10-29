-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.1.0", lines = {
        "One minimap button now covers every Blackthornes addon you have. Click it to pick one. Turn it off with Combine Addon Buttons on the General page.",
        "Show on Map puts a gold marker with the beast's name on the spot.",
    } },
    { version = "1.0.1", lines = {
        "The small Feed button has the gold plaque look.",
    } },
    { version = "1.0.0", lines = {
        "A warlock's Pet tab shows the demon's books, and dim chips with a level for demons not gotten yet.",
        "Soul Shards shows your count and warns when it's low. Stone Reminder says after a fight if a Healthstone or Soulstone is missing. Both are under Warlock on the Pet page and off until ticked.",
        "Arrow Size picks 50%, 75% or 100% for the guide arrow.",
        "A small gem beside the close button folds a window down to its title.",
    } },
}
