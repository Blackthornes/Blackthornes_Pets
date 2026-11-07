-- The Pet XP bar: off unless ticked, only a hunter's pet, the session's
-- gain and pace, the words, the card, the cheer, width and height, the
-- words moving to the hover on a thin bar, place, and /bpet xpbar.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("petxpbar")

local ns = env.Load()
local Bar, PetXP = ns.PetXPBar, ns.PetXP

local clock = 1000
local class = "HUNTER"
local pet = { exists = true, name = "Ashpaw", level = 18, xp = 539, max = 1350 }
local playerLevel = 20
local saved = {}
for _, k in ipairs({ "GetTime", "UnitClass", "UnitExists", "UnitName", "UnitLevel", "GetPetExperience" }) do
    saved[k] = rawget(_G, k)
end
_G.GetTime = function() return clock end
_G.UnitClass = function() return "Hunter", class end
_G.UnitExists = function(unit) return unit == "pet" and pet.exists end
_G.UnitName = function(unit) return unit == "pet" and pet.name or "Me" end
_G.UnitLevel = function(unit) return unit == "pet" and pet.level or playerLevel end
_G.GetPetExperience = function()
    if class ~= "HUNTER" then return 0, 0 end
    return pet.xp, pet.max
end

suite.check("off unless ticked", ns.db.petXPBar == false and not Bar:IsOn())
suite.check("off, nothing shows", Bar:Refresh() == false)
suite.check("defaults", Bar:Width() == 360 and Bar:Height() == 16 and Bar:ShowsWords() and Bar:Cheers())

-- A demon, or no pet: nothing.
class = "WARLOCK"
suite.check("a demon reads nothing", PetXP:Read() == nil)
class = "HUNTER"
pet.exists = false
suite.check("no pet reads nothing", PetXP:Read() == nil)
pet.exists = true

local read = PetXP:Read()
suite.check("a hunter's pet reads", read and read.name == "Ashpaw" and read.level == 18
    and read.xp == 539 and read.max == 1350 and read.capped == false)

Bar:Set(true)
suite.check("it shows", Bar.frame and Bar.frame:IsShown())
suite.check("the XP on the bar", Bar.frame.bar.text:GetText() == "539 / 1,350 (39%)",
    Bar.frame.bar.text:GetText())
suite.check("level above", Bar.frame.left:GetText() == "Level 18", Bar.frame.left:GetText())
suite.check("no pace yet", Bar.frame.right:GetText() == "")

-- Two kills over five minutes: 298 XP.
clock = clock + 150
pet.xp = 688
Bar:Refresh()
clock = clock + 150
pet.xp = 837
Bar:Refresh()
local s = PetXP:Session(PetXP:Read())
suite.check("the session counts the gains", s.gained == 298 and s.kills == 2, s.gained)
suite.check("below says the session", Bar.frame.belowLeft:GetText() == "This session +298 XP",
    Bar.frame.belowLeft:GetText())
suite.check("XP an hour", Bar.frame.belowRight:GetText() == "3,576 XP an hour",
    Bar.frame.belowRight:GetText())
-- 513 to go at 3,576 an hour: 9 min.
suite.check("time to level", Bar.frame.right:GetText() == "Level 19 in about 9 min",
    Bar.frame.right:GetText())
suite.check("62%", Bar.frame.bar.text:GetText() == "837 / 1,350 (62%)", Bar.frame.bar.text:GetText())
suite.check("the white mark where the session started", Bar.frame.bar.mark:IsShown())

-- The card.
local lines = Bar:CardLines(PetXP:Read())
suite.check("card header", lines.header == "ASHPAW, LEVEL 18", lines.header)
suite.check("XP to level", lines.rows[1].left == "XP to level 19" and lines.rows[1].right == "513",
    lines.rows[1].right)
suite.check("kills to go", lines.rows[2].left == "About 4 more kills"
    and lines.rows[2].sub == "of what you're fighting now" and lines.rows[2].right == "about 9 min",
    lines.rows[2].left)
suite.check("this session", lines.rows[3].sub == "5 min, 2 kills" and lines.rows[3].right == "+298 XP",
    lines.rows[3].sub)
suite.check("your level", lines.rows[4].sub == "Ashpaw can grow until level 20"
    and lines.rows[4].right == "2 levels to go", lines.rows[4].right)
suite.check("card foot", lines.foot == "Drag it anywhere. Right-click puts it back.")
Bar:ShowCard()
suite.check("the card shows", Bar.card and Bar.card:IsShown())
Bar:HideCard()

-- A level up: the gain carries across it, and the cheer.
clock = clock + 120
pet.level, pet.xp, pet.max = 19, 100, 1500
local cheered
local oldCheer = Bar.Cheer
Bar.Cheer = function(self, r, took) cheered = { r = r, took = took } end
Bar:Refresh()
Bar.Cheer = oldCheer
s = PetXP:Session(PetXP:Read())
suite.check("gain across a level", s.gained == 298 + 513 + 100, s.gained)
suite.check("the cheer fires", cheered and cheered.r.level == 19)
local title, took = Bar:CheerText(PetXP:Read(), nil)
suite.check("cheer title", title == "ASHPAW IS LEVEL 19", title)
suite.check("no time for a level not started here", took == nil)
title, took = Bar:CheerText(PetXP:Read(), 41 * 60)
suite.check("took", took == "Took 41 min", took)
Bar:Cheer(PetXP:Read(), 60)
suite.check("the cheer shows its words", Bar.cheer and Bar.cheer.title:GetText() == "ASHPAW IS LEVEL 19")
ns.db.petXPBarCheer = false
Bar.cheer.title:SetText("")
Bar:Cheer(PetXP:Read(), 60)
suite.check("no cheer when unticked", Bar.cheer.title:GetText() == "")
ns.db.petXPBarCheer = nil

-- Same level as you.
pet.level = 20
Bar:Refresh()
suite.check("same level", Bar.frame.left:GetText() == "Level 20 · Same level as you",
    Bar.frame.left:GetText())
lines = Bar:CardLines(PetXP:Read())
suite.check("card at your level", lines.rows[#lines.rows].right == "Same level as you")

-- Width and height.
Bar:SetWidth(500)
suite.check("width kept", ns.db.petXPBarWidth == 500 and Bar:Width() == 500)
Bar:SetWidth(9999)
suite.check("width capped", Bar:Width() == 600)
Bar:SetWidth(360)
suite.check("default width saves nothing", ns.db.petXPBarWidth == nil)
Bar:SetHeight(8)
suite.check("thin bar: words to the hover", not Bar.frame.bar.text:IsShown()
    and not Bar.frame.left:IsShown())
Bar:SetHeight(2)
suite.check("height floor", Bar:Height() == 6)
Bar:SetHeight(16)
suite.check("height back", ns.db.petXPBarHeight == nil and Bar.frame.bar.text:IsShown())

-- Show Words off: the name and level go on the bar.
Bar:SetWords(false)
suite.check("words off hides the lines", not Bar.frame.left:IsShown())
suite.check("words off: all on the bar", Bar.frame.bar.text:GetText():find("Ashpaw · Level 20 · ", 1, true) == 1,
    Bar.frame.bar.text:GetText())
Bar:SetWords(true)

-- No pet: it hides.
pet.exists = false
Bar:Refresh()
suite.check("no pet hides it", not Bar.frame:IsShown())
pet.exists = true
Bar:Refresh()

-- Place.
Bar.frame.GetLeft = function() return 300 end
Bar.frame.GetBottom = function() return 700 end
Bar:SaveSpot()
suite.check("a drop is kept", ns.db.petXPBarX == 300 and ns.db.petXPBarY == 700)
env.chat = {}
Bar:Reset()
suite.check("reset forgets the spot", ns.db.petXPBarX == nil and ns.db.petXPBarY == nil)
suite.check("reset says so", env.ChatText():find("back in its first spot", 1, true) ~= nil)
local point = Bar.frame._point
suite.check("back at the top", point and point[1] == "TOP", point and point[1])

-- /bpet xpbar
ns.commands.xpbar.fn("off")
suite.check("xpbar off", ns.db.petXPBar == false and not Bar.frame:IsShown())
suite.check("says off", env.ChatText():find("Pet XP bar: off.", 1, true) ~= nil)
ns.commands.xpbar.fn("on")
suite.check("xpbar on", ns.db.petXPBar == true and Bar.frame:IsShown())
ns.commands.xpbar.fn("")
suite.check("no word flips it", ns.db.petXPBar == false)

suite.check("numbers", Bar.Number(1350) == "1,350" and Bar.Number(12) == "12"
    and Bar.Number(1234567) == "1,234,567")

-- Put the client back for the suites after this one.
Bar:Set(false)
PetXP:Clear()
for _, k in ipairs({ "GetTime", "UnitClass", "UnitExists", "UnitName", "UnitLevel", "GetPetExperience" }) do
    _G[k] = saved[k]
end

suite.done()
