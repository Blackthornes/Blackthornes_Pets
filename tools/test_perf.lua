-- The shortcuts that keep Pets cheap give the same answers as the long way.
--
-- The pet check every few seconds takes the last bag scan while nothing in
-- the bags or about the pet has changed, and reads them again after a bag
-- event; item answers only matter while names are missing; and the UNIT_
-- events are asked for the player and the pet only, lifted to every unit
-- when another handler wants them.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("perf")

local ns = env.Load()
local Food = ns.Food

_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Boar" end
_G.UnitLevel = function() return 9 end
_G.HasPetUI = function() return true end
local realPetInfo, realContainer, realItem, realTime = _G.C_PetInfo, _G.C_Container, _G.C_Item, _G.GetTime
_G.C_PetInfo = {
    GetPetHappiness = function() return 3, 125, 5 end,
    GetPetFoodTypes = function() return { "Meat" } end,
}
local reads = 0
local bags = { [0] = { [1] = { itemID = 117, stackCount = 9 } } }
_G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and 16 or 0 end,
    GetContainerItemInfo = function(bag, slot)
        reads = reads + 1
        return bags[bag] and bags[bag][slot]
    end,
}
_G.C_Item = { GetItemInfo = function(id) if id == 117 then return "Tough Jerky", nil, 1, 5 end end }
local clock = 100
_G.GetTime = function() return clock end

local status = ns.PetStatus:Read()
local first = Food:Scan(status)
suite.check("a scan finds the food", #first == 1 and first[1].count == 9, #first)

reads = 0
local again = Food:Latest(status)
suite.check("nothing changed: the last scan is taken", again == first and reads == 0, reads)

bags[0][1] = { itemID = 117, stackCount = 4 }
Food:BagsChanged()
local after = Food:Latest(status)
suite.check("after a bag event the bags are read again", after ~= first and after[1].count == 4)

clock = clock + 61
reads = 0
Food:Latest(status)
suite.check("and after a minute anyway", reads > 0)

_G.UnitLevel = function() return 10 end
reads = 0
Food:Latest(ns.PetStatus:Read())
suite.check("a new pet level reads them again", reads > 0)

suite.check("with every name known, item answers are not waited on", not Food.waitingForNames)

-- Player and pet only.
local unitAsked, allAsked = 0, 0
local frame = ns.eventFrame
local plainRegister, unitRegister = frame.RegisterEvent, frame.RegisterUnitEvent
frame.RegisterUnitEvent = function(_, _, a, b)
    if a == "player" and b == "pet" then unitAsked = unitAsked + 1 end
end
frame.RegisterEvent = function() allAsked = allAsked + 1 end
local owner = {}
ns.RegisterPetEvent(owner, "UNIT_PERF_TEST", function() end)
suite.check("a pet event asks for the player and the pet", unitAsked == 1 and allAsked == 1)
ns.RegisterPetEvent(owner, "UNIT_PERF_TEST", function() end)
suite.check("a second one changes nothing", unitAsked == 1 and allAsked == 1)
ns.RegisterEvent(owner, "UNIT_PERF_TEST", function() end)
suite.check("a handler for every unit lifts the filter", allAsked == 2)
ns.UnregisterEvent(owner, "UNIT_PERF_TEST")
frame.RegisterEvent, frame.RegisterUnitEvent = plainRegister, unitRegister

_G.C_PetInfo, _G.C_Container, _G.C_Item, _G.GetTime = realPetInfo, realContainer, realItem, realTime
_G.UnitClass, _G.UnitExists, _G.UnitName, _G.UnitLevel, _G.HasPetUI = nil, nil, nil, nil, nil

suite.done()
