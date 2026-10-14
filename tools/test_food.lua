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
    Food:FeedMacro(stacks[1]) == "/stopmacro [nopet][@pet,dead][combat]\n/cast Feed Pet\n/use 0 3", Food:FeedMacro(stacks[1]))
_G.C_Spell = nil
suite.check("without the spell name it falls back on English",
    Food:FeedMacro(stacks[1]) == "/stopmacro [nopet][@pet,dead][combat]\n/cast Feed Pet\n/use 0 3")

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
-- Another pet called out gets its own warning.
_G.UnitName = function() return "Wolf" end
local wolf = ns.PetStatus:Read()
suite.check("another pet is told about too", Food:CheckLow(wolf, stacks) == true)
suite.check("by its name", env.ChatText():find("You have no food Wolf will eat.", 1, true))
suite.check("once", Food:CheckLow(wolf, stacks) == false)
_G.UnitName = function() return "Boar" end
ns.db.lowFoodWarning = false
Food.warnedLow = nil
suite.check("turned off it says nothing", Food:CheckLow(status, stacks) == false)
ns.db.lowFoodWarning = true

-- Just after login: the bags read empty, or items come back without names,
-- before the client has sent them. That is not a lack of food.
Food.warnedLow = nil
local saved = _G.C_Container.GetContainerNumSlots
_G.C_Container.GetContainerNumSlots = function() return 0 end
stacks = Food:Scan(status)
suite.check("bags that read empty are not trusted", stacks.incomplete == true)
suite.check("so no warning", Food:CheckLow(status, stacks) == false)
_G.C_Container.GetContainerNumSlots = saved
bags[2] = { [1] = { itemID = 5555, stackCount = 1 } }
stacks = Food:Scan(status)
suite.check("an item with no name yet is not trusted either", stacks.incomplete == true)
suite.check("so no warning then", Food:CheckLow(status, stacks) == false)
bags[2] = {}
Food.bagsReady = false
stacks = Food:Scan(status)
suite.check("nor before the bags are ready", not stacks.incomplete and Food:CheckLow(status, stacks) == false)
Food.bagsReady = true
suite.check("and once they are, it warns", Food:CheckLow(status, stacks) == true)
Food.bagsReady = nil

-- At login the link can read "[]" before the client has the item: an empty
-- name is no name, so the scan asks the client for it and does not warn.
Food.warnedLow = nil
local requested
_G.C_Item.RequestLoadItemDataByID = function(id) requested = id end
bags[2] = { [1] = { itemID = 5555, stackCount = 1, hyperlink = "|cffffffff|Hitem:5555::|h[]|h|r" } }
stacks = Food:Scan(status)
suite.check("a link with an empty name is not trusted", stacks.incomplete == true)
suite.check("the client is asked for that item", requested == 5555, requested)
suite.check("and there is no warning", Food:CheckLow(status, stacks) == false)

-- Scans that keep finding unnamed items try again, but not forever.
local scans = 0
local realScan = Food.Scan
Food.Scan = function(self, ...) scans = scans + 1; return realScan(self, ...) end
Food.retries, Food.retryPending = 0, nil
Food:Update()
suite.check("unnamed items are read again, a limited number of times",
    scans > 1 and scans <= 20, scans)
Food.Scan = realScan
bags[2] = {}
Food:Update()
suite.check("a full read resets the retries", Food.retries == 0, Food.retries)
_G.C_Item.RequestLoadItemDataByID = nil

-- The first bag update at login does not open the warning: only the wait
-- after the loading screen does, and a newer wait replaces an older one.
local timers = {}
local realTimer = _G.C_Timer
_G.C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
Food:Settle()
Food:Settle()
suite.check("waiting after a loading screen", Food.bagsReady == false)
timers[1]()
suite.check("an older wait does not end it", Food.bagsReady == false)
timers[2]()
suite.check("the newest wait does", Food.bagsReady == true)
_G.C_Timer = realTimer
Food.bagsReady, Food.warnedLow = nil, nil

-- The window: a Food row and the Feed button over it.
bags[0] = { [3] = { itemID = 117, stackCount = 30 } }
Food:BagsChanged()
local UI = ns.UI
UI:Show()
suite.check("the window has a food row",
    UI.rows.food.value:GetText():find("Tough Jerky (full), 30 in bags", 1, true), UI.rows.food.value:GetText())
suite.check("the Feed button is shown", UI.feedButton:IsShown())
suite.check("on a layer above the window, which rises when clicked",
    UI.feedButton:GetFrameStrata() == "FULLSCREEN_DIALOG" and UI.frame:GetFrameStrata() == "DIALOG",
    UI.feedButton:GetFrameStrata())
suite.check("and names the food", UI.feedButton.label:GetText() == "Feed Tough Jerky", UI.feedButton.label:GetText())

bags[0] = {}
Food:BagsChanged()
UI:Refresh()
suite.check("with no food the button goes", not UI.feedButton:IsShown())

-- In combat the button is left alone, since the game will not allow a change.
bags[0] = { [3] = { itemID = 117, stackCount = 30 } }
Food:BagsChanged()
_G.InCombatLockdown = function() return true end
UI:Refresh()
suite.check("in combat nothing is changed", not UI.feedButton:IsShown())
_G.InCombatLockdown = nil
UI:Refresh()
suite.check("out of combat it comes back", UI.feedButton:IsShown())
UI:PlaceFeedButton(nil, true)
suite.check("combat starting takes it away", not UI.feedButton:IsShown())

-- The button is a layer above every window, so it goes while Settings or
-- the Compendium is open, or it would take their clicks.
UI:Refresh()
suite.check("the version moves up over the Feed button",
    select(2, UI.versionLabel:GetPoint(1)) == UI.feedButton)
-- The test frames do not run OnShow and OnHide themselves.
local function Fire(window, script)
    local frame = window.frame
    local fn = frame:GetScript(script)
    if fn then fn(frame) end
end
ns.SettingsUI:Show()
Fire(ns.SettingsUI, "OnShow")
suite.check("Settings open puts the Feed button away", not UI.feedButton:IsShown())
ns.SettingsUI:Hide()
Fire(ns.SettingsUI, "OnHide")
suite.check("and closing it brings it back", UI.feedButton:IsShown())
ns.CompendiumUI:Show()
Fire(ns.CompendiumUI, "OnShow")
suite.check("so does the Compendium", not UI.feedButton:IsShown())
ns.CompendiumUI:Hide()
Fire(ns.CompendiumUI, "OnHide")
suite.check("and back again", UI.feedButton:IsShown())

-- Settings.
ns.SettingsUI:Show()
local box = ns.SettingsUI.controls.lowFoodWarning
suite.check("the settings page shows the low food warning on", box:GetChecked())
box:GetScript("OnClick")(box)
suite.check("and unticking turns it off", ns.db.lowFoodWarning == false)

-- A client whose slot info has no itemName and whose item cache is empty
-- still gives the name in the item link.
_G.C_Item = nil
bags[0] = { [3] = { itemID = 117, stackCount = 4,
    hyperlink = "|cffffffff|Hitem:117::::::::9:::::|h[Tough Jerky]|h|r" } }
stacks = Food:Scan()
suite.check("the name comes from the link", #stacks == 1 and stacks[1].name == "Tough Jerky",
    stacks[1] and stacks[1].name)

-- /bpet food says what it sees in each slot.
bags[1] = { [2] = { itemID = 4536, stackCount = 20, hyperlink = "|h[Shiny Red Apple]|h" },
    [5] = { itemID = 2589, stackCount = 10, hyperlink = "|h[Linen Cloth]|h" },
    [6] = { itemID = 9999, stackCount = 5, hyperlink = "|h[Scorpid Surprise]|h" } }
env.chat = {}
ns.HandleSlash("food")
local report = env.ChatText()
suite.check("the report names what the pet eats", report:find("Boar (level 9) eats Meat, Fish, Bread", 1, true), report)
suite.check("food it eats is listed with the count", report:find("Tough Jerky|r  Meat x4, full", 1, true), report)
suite.check("food of another diet says why", report:find("Shiny Red Apple|r  Fruit, which it doesn't eat", 1, true), report)
suite.check("everything else is on one line", report:find("not in the food list:|r Linen Cloth", 1, true), report)
suite.check("and it adds up", report:find("pieces your pet will eat", 1, true), report)

-- Buff food (a player asked): food whose use text gives a buff is fed last,
-- and never with "Never feed buff food" ticked. The client's tooltip says
-- which it is.
ITEMS[3662] = { "Crocolisk Steak", 12 }
local TOOLTIPS = {
    [3662] = { "Crocolisk Steak", "Use: Restores 243 health over 21 sec. Must remain seated while eating. If you spend at least 10 seconds eating you will become well fed and gain 6 Stamina and Spirit for 15 min." },
    [117] = { "Tough Jerky", "Use: Restores 61 health over 18 sec. Must remain seated while eating." },
    [2287] = { "Haunch of Meat", "Use: Restores 243 health over 21 sec. Must remain seated while eating." },
}
local tooltipReads = 0
_G.C_TooltipInfo = {
    GetItemByID = function(id)
        tooltipReads = tooltipReads + 1
        local lines = TOOLTIPS[id]
        if not lines then return nil end
        local data = { lines = {} }
        for i, text in ipairs(lines) do data.lines[i] = { leftText = text } end
        return data
    end,
}
_G.UnitExists = function() return true end
_G.C_Item = {
    GetItemInfo = function(id)
        local item = ITEMS[id]
        if item then return item[1], nil, 1, item[2] end
    end,
}
Food.buffKnown = nil
bags = {
    [0] = { [1] = { itemID = 3662, stackCount = 5 }, [2] = { itemID = 2287, stackCount = 2 } },
    [1] = { [1] = { itemID = 117, stackCount = 3 } },
}
stacks = Food:Scan()
suite.check("buff food is still fed", #stacks == 3, #stacks)
suite.check("but last, after plainer food of a higher level",
    stacks[3].name == "Crocolisk Steak" and stacks[3].buff == true, stacks[3].name)
suite.check("plain food comes first", stacks[1].name == "Tough Jerky" and not stacks[1].buff, stacks[1].name)
local reads = tooltipReads
Food:Scan()
suite.check("each food's tooltip is read once a session", tooltipReads == reads, tooltipReads - reads)

bags[0][2], bags[1] = nil, nil
stacks = Food:Scan()
suite.check("with nothing else, buff food is fed", #stacks == 1 and stacks[1].name == "Crocolisk Steak")

ns.db.neverFeedBuffFood = true
stacks = Food:Scan()
suite.check("ticked, buff food is never fed", #stacks == 0, #stacks)
suite.check("and does not count as food left", Food:Count(stacks) == 0)
env.chat = {}
ns.HandleSlash("food")
suite.check("the food report says why",
    env.ChatText():find("buff food, which you've chosen not to feed", 1, true), env.ChatText())
ns.db.neverFeedBuffFood = false

-- An item the tooltip has not loaded is not called buff food, and is asked
-- about again on the next scan.
Food.buffKnown = nil
TOOLTIPS[3662] = { "Crocolisk Steak" }
suite.check("no tooltip yet is not buff food", Food:IsBuffFood(3662) == false)
suite.check("and is not kept", Food.buffKnown[3662] == nil)

-- A scan with such a food is not kept, so the tooltip is read again once it
-- loads rather than a minute later.
Food.buffKnown, Food.buffTries = nil, nil
bags = { [0] = { [1] = { itemID = 3662, stackCount = 5 } } }
Food:BagsChanged()
stacks = Food:Scan()
suite.check("a scan waiting on a tooltip is not kept", Food.kept == nil)
suite.check("and listens for the item to load", Food.waitingForNames == true)
TOOLTIPS[3662] = { "Crocolisk Steak", "Use: Restores 243 health over 21 sec. If you spend at least 10 seconds eating you will become well fed." }
ns.db.neverFeedBuffFood = true
stacks = Food:Latest()
suite.check("once it loads, Never feed it holds", #stacks == 0, #stacks)
ns.db.neverFeedBuffFood = false

-- A tooltip that never loads is given up on after a few reads, so the bags
-- are not read again for it forever.
Food.buffKnown, Food.buffTries = nil, nil
TOOLTIPS[3662] = { "Crocolisk Steak" }
for _ = 1, 5 do Food:Scan() end
suite.check("given up on after a few tries", Food.buffKnown[3662] == false)
stacks = Food:Scan()
suite.check("and the scan is kept again", Food.kept ~= nil and not Food.waitingForNames)
Food.buffKnown, Food.buffTries = nil, nil

-- Without the tooltip call, the use spell's description says.
_G.C_TooltipInfo = nil
_G.C_Item.GetItemSpell = function(id) if id == 3662 then return "Food", 1131 end end
_G.C_Spell = { GetSpellDescription = function(id)
    return id == 1131 and "Restores 243 health over 21 sec. If you spend at least 10 seconds eating you will become well fed." or nil
end }
suite.check("the spell description is read too", Food:IsBuffFood(3662) == true)
_G.C_Spell = nil

-- Settings: the tick box.
ns.SettingsUI:Show()
local buffBox = ns.SettingsUI.controls.neverFeedBuffFood
suite.check("the tick box is there and off by default", buffBox and buffBox:GetChecked() == false)
buffBox:GetScript("OnClick")(buffBox)
suite.check("and ticking it turns it on", ns.db.neverFeedBuffFood == true)
buffBox:GetScript("OnClick")(buffBox)
suite.check("and unticking turns it off again", ns.db.neverFeedBuffFood == false)
ns.SettingsUI:Hide()

_G.UnitExists = function() return false end
env.chat = {}
ns.HandleSlash("food")
suite.check("with no pet out it says so", env.ChatText():find("no pet out", 1, true))

_G.C_Container, _G.C_Item, _G.C_PetInfo = nil, nil, nil
_G.UnitExists, _G.UnitName, _G.UnitLevel = nil, nil, nil

suite.done()
