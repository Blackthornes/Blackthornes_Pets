-- The food helper: which food in the bags the pet will eat, which to feed it
-- first, the Feed button's macro, and the low food warning.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("food")

local ns = env.Load()
local Food = ns.Food

-- How good food is by its level against the pet's.
suite.check("within 10 levels feeds fully", Food:Effect(5, 14) == "full")
suite.check("10 to 19 below does half", Food:Effect(5, 15) == "half")
suite.check("20 to 29 below does little", Food:Effect(5, 34) == "low")
suite.check("30 below is refused", Food:Effect(5, 35) == "refused")
suite.check("food above the pet is fine", Food:Effect(25, 9) == "full")
suite.check("an unknown level counts as full", Food:Effect(nil, 9) == "full")

-- A hunter with a level 9 boar that eats everything.
_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Boar" end
_G.UnitLevel = function() return 9 end
_G.C_PetInfo = {
    GetPetHappiness = function() return 3, 125, 5 end,
    GetPetFoodTypes = function() return { "Meat", "Fish", "Bread" } end,
}

-- Bags: item ID -> name and level, and what is in each slot.
local ITEMS = {
    [117] = { "Tough Jerky", 5 },
    [2287] = { "Haunch of Meat", 15 },
    [4540] = { "Tough Hunk of Bread", 5 },
    [4536] = { "Shiny Red Apple", 5 },      -- fruit: this boar is told it will not eat it
    [2589] = { "Linen Cloth", 5 },           -- not food at all
}
local bags = {
    [0] = { [1] = { itemID = 2287, stackCount = 4 }, [3] = { itemID = 117, stackCount = 3 } },
    [1] = { [2] = { itemID = 4536, stackCount = 20 }, [5] = { itemID = 2589, stackCount = 10 } },
    [2] = { [1] = { itemID = 4540, stackCount = 2 } },
}
_G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and 16 or 0 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
}
_G.C_Item = {
    GetItemInfo = function(id)
        local item = ITEMS[id]
        if item then return item[1], nil, 1, item[2] end
    end,
}

local stacks = Food:Scan()
suite.check("finds the three foods it eats", #stacks == 3, #stacks)
suite.check("the lowest level full food comes first",
    stacks[1].name == "Tough Jerky" and stacks[1].bag == 0 and stacks[1].slot == 3, stacks[1].name)
suite.check("the same level sorts by bag", stacks[2].name == "Tough Hunk of Bread", stacks[2].name)
suite.check("better food is kept for later", stacks[3].name == "Haunch of Meat", stacks[3].name)
suite.check("it counts every piece", Food:Count(stacks) == 9)
suite.check("fruit it will not eat is left out", (function()
    for _, stack in ipairs(stacks) do if stack.name == "Shiny Red Apple" then return false end end
    return true
end)())

-- The window's line.
local summary = Food:Summary(stacks)
suite.check("the summary names the best food and the count",
    summary:find("Tough Jerky (full), 9 in bags", 1, true), summary)
suite.check("and says it is running low", summary:find("running low", 1, true), summary)
suite.check("no food at all says so", Food:Summary({}):find("None in your bags", 1, true))

-- The Feed button's macro.
_G.C_Spell = { GetSpellName = function(id) return id == 6991 and "Feed Pet" or nil end }
suite.check("the macro casts Feed Pet then uses the food",
    Food:FeedMacro(stacks[1]) == "/cast Feed Pet\n/use 0 3", Food:FeedMacro(stacks[1]))
_G.C_Spell = nil
suite.check("without the spell name it falls back on English",
    Food:FeedMacro(stacks[1]) == "/cast Feed Pet\n/use 0 3")

-- A pet level 40 turns its nose up at level 5 food and does little with 15.
_G.UnitLevel = function() return 40 end
stacks = Food:Scan()
suite.check("too low food is refused", #stacks == 1 and stacks[1].name == "Haunch of Meat")
suite.check("and the rest is marked little", stacks[1].effect == "low")
_G.UnitLevel = function() return 9 end

-- The low food warning.
local status = ns.PetStatus:Read()
stacks = Food:Scan(status)
suite.check("warns when food is low", Food:CheckLow(status, stacks) == true)
suite.check("in chat", env.ChatText():find("Only 9 food left that Boar will eat.", 1, true), env.ChatText())
suite.check("once", Food:CheckLow(status, stacks) == false)
bags[3] = { [1] = { itemID = 117, stackCount = 20 } }
stacks = Food:Scan(status)
suite.check("restocked, it goes quiet", Food:CheckLow(status, stacks) == false and Food.warnedLow == nil)
bags[3] = nil
bags[0], bags[2] = {}, {}
stacks = Food:Scan(status)
suite.check("and warns again when it runs out", Food:CheckLow(status, stacks) == true)
suite.check("saying there is none", env.ChatText():find("You have no food Boar will eat.", 1, true))
ns.db.lowFoodWarning = false
Food.warnedLow = nil
suite.check("turned off it says nothing", Food:CheckLow(status, stacks) == false)
ns.db.lowFoodWarning = true

-- The window: a Food row and the Feed button over it.
bags[0] = { [3] = { itemID = 117, stackCount = 30 } }
local UI = ns.UI
UI:Show()
suite.check("the window has a food row",
    UI.rows.food.value:GetText():find("Tough Jerky (full), 30 in bags", 1, true), UI.rows.food.value:GetText())
suite.check("the Feed button is shown", UI.feedButton:IsShown())
suite.check("and names the food", UI.feedButton.label:GetText() == "Feed Tough Jerky", UI.feedButton.label:GetText())

bags[0] = {}
UI:Refresh()
suite.check("with no food the button goes", not UI.feedButton:IsShown())

-- In combat the button is left alone, since the game will not allow a change.
bags[0] = { [3] = { itemID = 117, stackCount = 30 } }
_G.InCombatLockdown = function() return true end
UI:Refresh()
suite.check("in combat nothing is changed", not UI.feedButton:IsShown())
_G.InCombatLockdown = nil
UI:Refresh()
suite.check("out of combat it comes back", UI.feedButton:IsShown())
UI:PlaceFeedButton(nil, true)
suite.check("combat starting takes it away", not UI.feedButton:IsShown())

-- Settings.
ns.SettingsUI:Show()
local box = ns.SettingsUI.controls.lowFoodWarning
suite.check("the settings page shows the low food warning on", box:GetChecked())
box:GetScript("OnClick")(box)
suite.check("and unticking turns it off", ns.db.lowFoodWarning == false)

_G.C_Container, _G.C_Item, _G.C_PetInfo = nil, nil, nil
_G.UnitExists, _G.UnitName, _G.UnitLevel = nil, nil, nil

suite.done()
