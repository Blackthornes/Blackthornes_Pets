-- The Beast Sheet in the Compendium: a click on a row opens a sheet beside
-- the list with everything about that beast and how it compares to your
-- pet. While it is open the list keeps Beast, Level, Speed and Teaches.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("beastsheet")

local ns = env.Load()
local UI, C = ns.CompendiumUI, ns.Compendium

_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitLevel = function() return 20 end

UI:Show()
local fang = C:Get(471)
suite.check("a beast with a spot to open", fang and fang.zone ~= nil)

local function Column(key)
    for _, heading in ipairs(UI.headings) do
        if heading.column.key == key then return heading end
    end
end
local wideSkills = Column("skills").column.x
suite.check("the sheet starts shut", not UI.sheet:IsShown() and Column("family").column.shown ~= false)

local row = UI.rows[1]
local entry = row.entry
row:GetScript("OnClick")(row)
suite.check("a click opens the sheet", UI.sheet:IsShown() and UI.picked == entry)
suite.check("its row is lit gold with a gold edge", row.stripe:IsShown())
suite.check("the sheet names the beast", UI.sheet.name:GetText() == entry.name)
suite.check("Family moves off the list", Column("family").column.shown == false and row.family._shown == false)
suite.check("Where moves off the list", Column("zone").column.shown == false and row.zone._shown == false)
suite.check("Beast, Level, Speed and Teaches stay",
    Column("name").column.shown ~= false and Column("level").column.shown ~= false and Column("speed").column.shown ~= false and Column("skills").column.shown ~= false)
suite.check("Teaches moves left into the room", Column("skills").column.x < wideSkills, Column("skills").column.x)
suite.check("the list narrows beside the sheet", UI.listRight > 18, UI.listRight)

-- Its words.
UI:OpenSheet(fang)
local sheet = UI.sheet
suite.check("another click moves the sheet to that beast", UI.picked == fang and sheet.name:GetText() == fang.name)
suite.check("the line under the name says family and level", sheet.kind:GetText():find(fang.family or "", 1, true) ~= nil,
    sheet.kind:GetText())
suite.check("the map shows a dot and the zone", sheet.map.dot:IsShown()
    and sheet.map.caption:GetText():find(fang.zone, 1, true) ~= nil, sheet.map.caption:GetText())

local words, key = UI.TameWords({ min = 12, max = 13 }, 20)
suite.check("a beast at your level can be tamed now", words == "You can tame it now" and key == "good", words)
words, key = UI.TameWords({ min = 53, max = 53 }, 20)
suite.check("one above it says when", words == "You can tame it at level 53" and key == "loss", words)

local slow = { speed = 1.5 }
suite.check("slower than your pet",
    UI.SpeedWords(slow, "Shadowpaw", 1.3):find("Slower than Shadowpaw (1.3)", 1, true) ~= nil, UI.SpeedWords(slow, "Shadowpaw", 1.3))
suite.check("faster than your pet",
    UI.SpeedWords({ speed = 1.2 }, "Shadowpaw", 1.3):find("Faster than Shadowpaw (1.3)", 1, true) ~= nil)
suite.check("the same speed says nothing more", not UI.SpeedWords({ speed = 1.3 }, "Shadowpaw", 1.3):find("than", 1, true))
suite.check("no pet out, no compare", not UI.SpeedWords(slow):find("than", 1, true))

-- Your pet, read in a pcall: one the game keeps back is no pet.
_G.UnitExists = function() return true end
_G.UnitName = function() return "Shadowpaw" end
_G.UnitAttackSpeed = function() return 1.3 end
local name, speed = UI.PetSpeed()
suite.check("your pet's name and speed", name == "Shadowpaw" and speed == 1.3)
_G.UnitAttackSpeed = function() error("secret value") end
suite.check("a speed the game keeps back is none", UI.PetSpeed() == nil)
_G.UnitExists, _G.UnitName, _G.UnitAttackSpeed = nil, nil, nil

suite.check("the diet reads as players say it", UI.DietWords({ diet = "Meat, Fish" }) ~= nil)

-- A beast whose place isn't known: the buttons rest.
local lost = { name = "Nobody", family = "Wolf", min = 10, max = 10, speed = 2 }
UI:OpenSheet(lost)
suite.check("no place, no dot", not sheet.map.dot:IsShown()
    and sheet.map.caption:GetText() == "Where it lives is not known yet.")
local pinned
local savedPin = C.Pin
C.Pin = function(_, e) pinned = e end
sheet.pin:GetScript("OnClick")(sheet.pin)
suite.check("Show on Map does nothing with no place", pinned == nil)
UI:OpenSheet(fang)
sheet.pin:GetScript("OnClick")(sheet.pin)
suite.check("Show on Map pins the beast", pinned == fang)
C.Pin = savedPin

-- Closing.
sheet.close:GetScript("OnClick")(sheet.close)
suite.check("the red gem closes it", not sheet:IsShown() and UI.picked == nil)
suite.check("the list takes the whole width again", UI.listRight == 18 and Column("family").column.shown ~= false
    and Column("skills").column.x == wideSkills)
row = UI.rows[1]
row:GetScript("OnClick")(row)
row:GetScript("OnClick")(row)
suite.check("a second click on the same row closes it", not sheet:IsShown())

_G.UnitClass, _G.UnitLevel = nil, nil
suite.done()
