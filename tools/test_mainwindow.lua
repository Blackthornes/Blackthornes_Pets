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
suite.check("and shows no pet card", not UI.body:IsShown())

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
suite.check("the top card names the pet", UI.nameLabel:GetText() == "Boar", UI.nameLabel:GetText())
suite.check("and its level under the name, the family being its name",
    rows.pet.value:GetText() == "Level 8", rows.pet.value:GetText())
suite.check("so the level badge on its face rests", UI.levelLabel:GetText() == "8" and not UI.levelBadge:IsShown())
suite.check("the mood chip says unhappy", UI.moodChip.label:GetText() == "Unhappy")
suite.check("happiness says unhappy and the damage",
    rows.happiness.value:GetText():find("Unhappy (75% damage)", 1, true), rows.happiness.value:GetText())
local lit = 0
for _, light in ipairs(UI.meters.happiness.lights) do
    if light.shine:IsShown() then lit = lit + 1 end
end
suite.check("one happiness light is lit", lit == 1, lit)
suite.check("loyalty says it is falling",
    rows.loyalty.value:GetText():find("Rebellious, ", 1, true)
        and rows.loyalty.value:GetText():find("falling", 1, true), rows.loyalty.value:GetText())
suite.check("rebellious is the first of six", UI.LoyaltyLevel("Rebellious") == 1
    and UI.LoyaltyLevel("Best Friend") == 6 and UI.LoyaltyLevel("Wobbly") == nil)
suite.check("experience has the percent",
    rows.experience.value:GetText() == "92 / 1350 (6%)", rows.experience.value:GetText())
local bar = UI.meters.experience.bar
suite.check("and its bar is that far along", math.abs(bar:Fraction() - 92 / 1350) < 1e-9, bar:Fraction())
suite.check("training points below zero are over",
    rows.training.value:GetText() == "5 training points over", rows.training.value:GetText())
suite.check("with the whole count under the mouse",
    UI.trainingChip.detail:find("free (0 total, 5 spent)", 1, true), UI.trainingChip.detail)
suite.check("and it lists what the pet eats",
    rows.foods.value:GetText() == "Meat, Fish, Cheese, Bread, Fungus, Fruit", rows.foods.value:GetText())
suite.check("a hunter's pet has the food card", UI.foodCard:IsShown())
suite.check("beside the fight card", UI.fightCard._point[1] == "BOTTOMRIGHT"
    and UI.fightCard._width == UI.cardWidth)

-- The chips sit under the family and level line, not over it.
suite.check("the mood chip sits under the level line",
    UI.moodChip._point[2] == rows.pet.value and UI.moodChip._point[3] == "BOTTOMLEFT", UI.moodChip._point[3])

-- The three bars sit in the top card, right of the name, centred as one
-- block, and the cards start right under the card.
local blockTop = -(88 - 3 * 24) / 2
suite.check("the experience bar is the first, in the top card",
    UI.meters.experience._point[2] == UI.hero and UI.meters.experience._point[5] == blockTop,
    UI.meters.experience._point[5])
suite.check("the loyalty bar is the third",
    UI.meters.loyalty._point[2] == UI.hero and UI.meters.loyalty._point[5] == blockTop - 48,
    UI.meters.loyalty._point[5])
suite.check("past the name and chips", UI.meters.experience._point[4] >= 12 + 64 + 14 + 200,
    UI.meters.experience._point[4])
suite.check("with a fine line between", UI.heroSplit:IsShown())
suite.check("the name stops before the bars",
    UI.nameLabel._point[1] == "RIGHT" and UI.nameLabel._point[3] == "LEFT"
        and UI.nameLabel._point[4] < UI.meters.experience._point[4], UI.nameLabel._point[4])
suite.check("the bar is its usual width", UI.meterBarWidth == 150, UI.meterBarWidth)
suite.check("the cards start right under the top card", UI.foodCard._point[1] == "TOPLEFT"
    and UI.foodCard._point[5] == -(88 + 10), UI.foodCard._point[5])

-- Long words beside a bar take room from the bar, never below its least.
local wasHappy = ns.PetStatus.HappinessText
ns.PetStatus.HappinessText = function() return ("Very happy indeed "):rep(4) end
UI:Refresh()
suite.check("a bar gives up room to long words", UI.meterBarWidth < 150 and UI.meterBarWidth >= 110,
    UI.meterBarWidth)
ns.PetStatus.HappinessText = wasHappy
UI:Refresh()
suite.check("and takes it back", UI.meterBarWidth == 150, UI.meterBarWidth)

-- A value that wraps onto two lines pushes the next row down past it.
_G.UnitHealthMax = function() return 300 end
_G.UnitAttackSpeed = function() return 2 end
_G.UnitArmor = function() return 0, 450 end
UI:Refresh()
local healthY = rows.health._point[5]
suite.check("one line a row", rows.speed._point[5] == healthY - 22, rows.speed._point[5])
rows.health.value.GetStringHeight = function() return 28 end
UI:Refresh()
suite.check("a wrapped value moves the next row down",
    rows.speed._point[5] == healthY - 37, rows.speed._point[5])
rows.health.value.GetStringHeight = nil
_G.UnitHealthMax, _G.UnitAttackSpeed, _G.UnitArmor = nil, nil, nil

-- A warlock's demon has none of the hunter rows: they hide and close up.
_G.UnitClass = function() return "Warlock", "WARLOCK" end
_G.UnitName = function() return "Grel'zok" end
_G.UnitCreatureFamily = function() return "Imp" end
_G.GetPetExperience = function() return 0, 0 end
-- Forever answers 0, 0 for a demon's training points (the probe, 2026-09-30).
_G.C_PetInfo = { GetPetHappiness = function() return nil end,
    GetPetTrainingPoints = function() return 0, 0 end }
UI:Refresh()
suite.check("a demon is named", UI.nameLabel:GetText() == "Grel'zok", UI.nameLabel:GetText())
suite.check("with its family under, the level on the badge",
    rows.pet.value:GetText() == "Imp" and UI.levelBadge:IsShown() and UI.levelLabel:GetText() == "8",
    rows.pet.value:GetText())
suite.check("a demon has no bars, so no line and the name has the card",
    not UI.heroSplit:IsShown() and UI.nameLabel._point[3] == "RIGHT")
suite.check("a demon has no food card", not UI.foodCard:IsShown())
suite.check("so its fight card is the whole width", UI.fightCard._point[1] == "BOTTOMRIGHT"
    and UI.fightCard._width ~= UI.cardWidth)
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
    UI.nameLabel:GetText() == "Your pet" and rows.pet.value:GetText() == "Imp",
    UI.nameLabel:GetText())

_G.UnitExists, _G.UnitName, _G.UnitCreatureFamily, _G.UnitLevel = nil, nil, nil, nil
_G.GetPetExperience, _G.C_PetInfo = nil, nil

-- The bars start past the longest meter name.
suite.check("short meter names keep the usual start", UI.MeterStart({ "Experience", "Loyalty" }) == 80,
    UI.MeterStart({ "Experience", "Loyalty" }))
local long = ("x"):rep(30)
suite.check("a long meter name pushes the bars along",
    UI.MeterStart({ "Experience", long }) >= ns.Theme.TextWidth("small", long) + 12)

suite.done()
