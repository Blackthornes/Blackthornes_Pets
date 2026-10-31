-- Core/WhatsNewText.lua
-- Written by tools/make_whatsnew.py from NEWS.md. Never edit it by hand:
-- change NEWS.md and run the tool. UI/WhatsNew.lua shows it.

local _, ns = ...

ns.WHATS_NEW = {
    { version = "1.4.0", lines = {
        "The one window now stays next to the auction house.",
        "Pet food gets a soft ring for its quality.",
    } },
    { version = "1.3.0", lines = {
        "All your Blackthornes addons share one window. A strip down the left has a button for each addon you have, and the tabs of the one you pick sit beside it. At the auction house, mailbox, vendor and trainer it sits next to the game's window, and it goes back when you close that one. Turn it off with One Window on the General page.",
    } },
    { version = "1.2.0", lines = {
        "The search and family picker are at the top. Each beast takes one line. Click a heading to sort, or right-click a beast for a menu.",
        "Settings has a new General page for how the windows look.",
    } },
}
