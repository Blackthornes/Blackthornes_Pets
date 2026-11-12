-- The feed hold: while Feed Pet Effect is on the pet, the small Feed button,
-- the Pet care key and the window's Feed button all hold and count down.
-- When the buff can't be read, feeding works as it always has.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("feedhold")

local ns = env.Load()
local FeedButton = ns.FeedButton
local button = FeedButton:Build()
local key = ns.FeedKey:Build()

local now = 1000
_G.GetTime = function() return now end
_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Scorpid" end
_G.UnitLevel = function() return 12 end
_G.C_PetInfo = {
    GetPetHappiness = function() return 2, 100, 5 end,
    GetPetFoodTypes = function() return { "Meat" } end,
}
local bags = { [0] = { [3] = { itemID = 117, stackCount = 30 } } }
_G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and 16 or 0 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
}
_G.C_Item = { GetItemInfo = function() return "Tough Jerky", nil, 1, 5 end }
_G.ObjectiveTrackerFrame = env.Stub({ _shown = true })
function ObjectiveTrackerFrame:IsVisible() return self._shown end
function ObjectiveTrackerFrame:GetLeft() return 950 end
function ObjectiveTrackerFrame:GetTop() return 700 end

local aura -- nil: no buff; "raise": the call raises
_G.C_UnitAuras = {
    GetAuraDataByIndex = function(unit, index)
        if aura == "raise" then error("secret") end
        if unit == "pet" and index == 1 and aura then return aura end
        return nil
    end,
}

ns.Food:Update()
suite.check("no buff: the small button feeds",
    button:IsShown() and (button:GetAttribute("macrotext") or ""):find("/use 0 3", 1, true),
    button:GetAttribute("macrotext"))
suite.check("and the key feeds", (key:GetAttribute("macrotext") or ""):find("/use 0 3", 1, true))

-- The pet eats: 14 seconds left.
aura = { spellId = 1539, name = "Feed Pet Effect", expirationTime = now + 14 }
ns.Food:EatingChanged()
suite.check("Eating says how long is left", ns.Food:Eating() == 14, tostring(ns.Food:Eating()))
suite.check("the small button stays, holding",
    button:IsShown() and button:GetAttribute("macrotext") == nil, tostring(button:GetAttribute("macrotext")))
suite.check("it names the pet eating", button.first:GetText() == "Scorpid is eating", button.first:GetText())
suite.check("and counts down", button.second:GetText() == "Ready in 14s", button.second:GetText())
local keyText = key:GetAttribute("macrotext") or ""
suite.check("the key feeds nothing while it eats", not keyText:find("/use", 1, true), keyText)
suite.check("a ticker watches the buff", ns.Food.eatTicker ~= nil)

now = now + 5
ns.Food.eatTicker._fn()
suite.check("the ticker moves the count", button.second:GetText() == "Ready in 9s", button.second:GetText())

-- In combat the words are left alone.
_G.InCombatLockdown = function() return true end
now = now + 1
ns.Food.eatTicker._fn()
suite.check("in combat nothing changes", button.second:GetText() == "Ready in 9s", button.second:GetText())
_G.InCombatLockdown = nil

-- The buff ends.
local ticker = ns.Food.eatTicker
aura = nil
now = now + 9
ticker._fn()
suite.check("done eating: the button feeds again",
    button:IsShown() and (button:GetAttribute("macrotext") or ""):find("/use 0 3", 1, true),
    tostring(button:GetAttribute("macrotext")))
suite.check("with its usual words", button.first:GetText() == "Feed Scorpid", button.first:GetText())
suite.check("the key feeds again", (key:GetAttribute("macrotext") or ""):find("/use 0 3", 1, true))
suite.check("the ticker stops", ns.Food.eatTicker == nil)

-- Matched by name too, and with no end given it counts its own 20 seconds.
aura = { name = "Feed Pet Effect" }
ns.Food.eatSeen = nil
_G.C_Spell = { GetSpellName = function(id) return id == 1539 and "Feed Pet Effect" or nil end }
suite.check("no end given: about 20 seconds", ns.Food:Eating() == 20, tostring(ns.Food:Eating()))
aura = nil
ns.Food:EatingChanged()
_G.C_Spell = nil

-- A client that won't say: feeding works as before.
aura = "raise"
ns.Food:EatingChanged()
suite.check("a raising aura call never holds feeding", ns.Food:Eating() == nil)
ns.Food:Update()
suite.check("and the button still feeds", (button:GetAttribute("macrotext") or ""):find("/use 0 3", 1, true))
aura = nil

_G.C_Container, _G.C_Item, _G.C_PetInfo, _G.ObjectiveTrackerFrame, _G.C_UnitAuras = nil, nil, nil, nil, nil
_G.UnitExists, _G.UnitName, _G.UnitLevel, _G.GetTime = nil, nil, nil, nil

suite.done()
