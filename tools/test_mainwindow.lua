-- The pets window. Empty for now: what matters is that it opens and closes,
-- knows whose pets it is for, and remembers where it was put.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("mainwindow")

local ns = env.Load()
local UI = ns.UI

_G.UnitClass = function() return "Hunter", "HUNTER" end
UI:Show()
suite.check("it opens", UI.frame:IsShown())
suite.check("the header says hunter", UI.subtitle:GetText() == "Hunter", UI.subtitle:GetText())
suite.check("and it says it is empty", UI.emptyLabel:GetText() == "Nothing here yet.")

_G.UnitClass = function() return "Warlock", "WARLOCK" end
UI:Refresh()
suite.check("a warlock is a warlock", UI.subtitle:GetText() == "Warlock", UI.subtitle:GetText())

_G.UnitClass = function() return "Mage", "MAGE" end
UI:Refresh()
suite.check("another class is told who it is for",
    UI.footer:GetText() == "Pets is for hunters and warlocks.", UI.footer:GetText())

_G.UnitClass = function() error("secret value") end
UI:Refresh()
suite.check("an unreadable class is not an error", UI.subtitle:GetText() == "")

-- /bpet window.
UI:Hide()
ns.HandleSlash("window")
suite.check("/bpet window opens it", UI.frame:IsShown())

-- Its place is remembered.
UI.frame._point = { "TOPLEFT", nil, "TOPLEFT", 120, -80 }
UI:SavePosition()
suite.check("where it was dragged is saved", ns.db.point == "TOPLEFT" and ns.db.x == 120)

suite.done()
