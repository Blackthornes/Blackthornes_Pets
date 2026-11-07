-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.7.0", lines = {
        "Hunters can show a bar for their pet's XP. It shows how long to the next level and XP an hour. You can size it and move it. It is in Settings, on the Pet page, under Pet XP Bar.",
    } },
    { version = "1.6.0", lines = {
        "Warlocks get a Shard Tracker, a small plaque that shows your soul shards and stones. It starts off. Turn it on in Settings, on the Pet page.",
    } },
    { version = "1.5.0", lines = {
        "You can drag the small Feed button where you want it. Right-click puts it back.",
    } },
}
