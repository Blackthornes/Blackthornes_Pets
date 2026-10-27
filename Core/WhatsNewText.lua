-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.0.1", lines = {
        "The small Feed button has the gold plaque look.",
    } },
    { version = "1.0.0", lines = {
        "A warlock's Pet tab shows the demon's books, and dim chips with a level for demons not gotten yet.",
        "Soul Shards shows your count and warns when it's low. Stone Reminder says after a fight if a Healthstone or Soulstone is missing. Both are under Warlock on the Pet page and off until ticked.",
        "Arrow Size picks 50%, 75% or 100% for the guide arrow.",
        "A small gem beside the close button folds a window down to its title.",
    } },
    { version = "0.21.0", lines = {
        "The Pet tab shows what your pet knows, what it can learn now and what comes later, and where the pet trainer is.",
        "Pet, Compendium and Settings are tabs in one window now.",
        "Every window has a size grip, and the General page has an Effects choice.",
    } },
}
