-- The pets window: it opens and closes, knows whose pets it is for, remembers
-- where it was put, and shows the pet that is out.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("mainwindow")

local ns = env.Load()
local UI = ns.UI

_G.UnitClass = function() return "Hunter", "HUNTER" end
UI:Show()
suite.check("it opens", UI.frame:IsShown())
suite.check("the header says hunter", UI.subtitle:GetText() == "Hunter", UI.subtitle:GetText())
suite.check("with no pet out it says so",
    UI.emptyLabel:GetText() == "No pet out." and UI.emptyLabel:IsShown())
suite.check("and shows no status rows", not UI.rows.pet.value:IsShown())

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

-- The house frame: the name on the plate, the paw in the portrait, and a
-- close gem in place of the old X.
local trim = UI.frame.titan
suite.check("the window wears the house frame", trim ~= nil)
suite.check("its name is on the plate", trim and trim.plate.label:GetText() == "Blackthornes Pets")
suite.check("with the portrait", trim and type(trim.portrait) == "table")
trim.closeButton:GetScript("OnClick")(trim.closeButton)
suite.check("the close gem closes it", not UI.frame:IsShown())

-- /bpet window.
UI:Hide()
ns.HandleSlash("window")
suite.check("/bpet window opens it", UI.frame:IsShown())

-- Its place is remembered.
UI.frame._point = { "TOPLEFT", nil, "TOPLEFT", 120, -80 }
UI:SavePosition()
suite.check("where it was dragged is saved", ns.db.point == "TOPLEFT" and ns.db.x == 120)

-- A hunter with an unhappy boar out, as the fourth probe found one.
_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Boar" end
_G.UnitCreatureFamily = function() return "Boar", 5 end
_G.UnitLevel = function(unit) return unit == "pet" and 8 or 10 end
_G.GetPetExperience = function() return 92, 1350 end
_G.C_PetInfo = {
    GetPetHappiness = function() return 1, 75, -10 end,
    GetPetLoyalty = function() return "Rebellious" end,
    GetPetFoodTypes = function() return { "Meat", "Fish", "Cheese", "Bread", "Fungus", "Fruit" } end,
    GetPetTrainingPoints = function() return 0, 5 end,
}
UI:Refresh()
local rows = UI.rows
suite.check("the empty line goes", not UI.emptyLabel:IsShown())
suite.check("the pet row names it and its level",
    rows.pet.value:GetText() == "Boar, level 8", rows.pet.value:GetText())
suite.check("happiness says unhappy and the damage",
    rows.happiness.value:GetText():find("Unhappy (75% damage)", 1, true), rows.happiness.value:GetText())
suite.check("loyalty says it is falling",
    rows.loyalty.value:GetText():find("Rebellious, ", 1, true)
        and rows.loyalty.value:GetText():find("falling", 1, true), rows.loyalty.value:GetText())
suite.check("experience has the percent",
    rows.experience.value:GetText() == "92 / 1350 (6%)", rows.experience.value:GetText())
suite.check("training points go below zero",
    rows.training.value:GetText():find("-5", 1, true)
        and rows.training.value:GetText():find("free (0 total, 5 spent)", 1, true), rows.training.value:GetText())
suite.check("and it lists what the pet eats",
    rows.foods.value:GetText() == "Meat, Fish, Cheese, Bread, Fungus, Fruit", rows.foods.value:GetText())

-- A warlock's demon has none of the hunter rows: they hide and close up.
_G.UnitClass = function() return "Warlock", "WARLOCK" end
_G.UnitName = function() return "Grel'zok" end
_G.UnitCreatureFamily = function() return "Imp" end
_G.GetPetExperience = function() return 0, 0 end
_G.C_PetInfo = { GetPetHappiness = function() return nil end }
UI:Refresh()
suite.check("a demon is named with its family",
    rows.pet.value:GetText() == "Grel'zok, Imp, level 8", rows.pet.value:GetText())
suite.check("and has no happiness row", not rows.happiness.value:IsShown())
suite.check("or loyalty, experience or training rows",
    not rows.loyalty.value:IsShown() and not rows.experience.value:IsShown()
        and not rows.training.value:IsShown())

-- A secret name is left out rather than breaking the window.
_G.UnitName = function() return newproxy(true) end
local secret = UnitName()
getmetatable(secret).__tostring = function(self) return self end
_G.UnitName = function() return secret end
UI:Refresh()
suite.check("a secret name reads as your pet",
    rows.pet.value:GetText() == "Your pet, Imp, level 8", rows.pet.value:GetText())

_G.UnitExists, _G.UnitName, _G.UnitCreatureFamily, _G.UnitLevel = nil, nil, nil, nil
_G.GetPetExperience, _G.C_PetInfo = nil, nil

suite.done()
