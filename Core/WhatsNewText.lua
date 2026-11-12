-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.9.0", lines = {
        "A new box mutes every sound from all the Blackthornes addons at once. It starts off.",
    } },
    { version = "1.8.0", lines = {
        "The Shard Tracker is clickable now. Use your Healthstone, Soulstone or Firestone right from it.",
        "New Firestone slot for warlocks.",
        "A cleaner look for the Shard Tracker.",
    } },
    { version = "1.7.0", lines = {
        "Hunters can show a bar for their pet's XP. It shows how long to the next level and XP an hour. You can size it and move it. It is in Settings, on the Pet page, under Pet XP Bar.",
    } },
}
