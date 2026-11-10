-- Food kept in the reagent bag counts too: the bag past the backpack and its
-- four bags, found from the client and never a bank bag.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("reagentbag")

local ns = env.Load()
local Food = ns.Food

_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Boar" end
_G.UnitLevel = function() return 9 end
_G.C_PetInfo = {
    GetPetHappiness = function() return 3, 125, 5 end,
    GetPetFoodTypes = function() return { "Meat" } end,
}
local ITEMS = { [2287] = { "Haunch of Meat", 15 }, [117] = { "Tough Jerky", 5 } }
local bags = {
    [0] = { [1] = { itemID = 117, stackCount = 1 } },
    [5] = { [2] = { itemID = 2287, stackCount = 20 } },
    [6] = { [1] = { itemID = 117, stackCount = 40 } },   -- a bank bag
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
local savedEnum = rawget(_G, "Enum")

-- No word of a reagent bag: the backpack and four bags only.
_G.Enum = nil
suite.check("no reagent bag without the client saying so", Food.ReagentBag() == nil)
suite.check("so only the bag food counts", Food:Count(Food:Scan()) == 1)

-- The client names it.
_G.Enum = { BagIndex = { ReagentBag = 5, BankBag_1 = 6 } }
suite.check("the reagent bag is read from the client", Food.ReagentBag() == 5)
local bagsRead = Food.Bags()
suite.check("it is walked last", #bagsRead == 6 and bagsRead[6] == 5)
local stacks = Food:Scan()
suite.check("food in it counts", Food:Count(stacks) == 21, Food:Count(stacks))
local fromReagent
for _, stack in ipairs(stacks) do if stack.bag == 5 then fromReagent = stack end end
suite.check("and is fed from its own slot", fromReagent and fromReagent.slot == 2
    and Food:FeedMacro(fromReagent):find("/use 5 2", 1, true))

-- No enum, but the client counts more bag slots than the four.
_G.Enum = nil
_G.NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
suite.check("a fifth equipped bag slot is the reagent bag", Food.ReagentBag() == 5)
_G.NUM_TOTAL_EQUIPPED_BAG_SLOTS = nil

-- On a client laid out the older way, 5 is the first bank bag.
_G.Enum = { BagIndex = { ReagentBag = 5, BankBag_1 = 5 } }
suite.check("a bank bag is never taken for it", Food.ReagentBag() == nil)
suite.check("so bank food is not counted", Food:Count(Food:Scan()) == 1)

_G.Enum = savedEnum
_G.C_Container, _G.C_Item, _G.C_PetInfo = nil, nil, nil
_G.UnitExists, _G.UnitName, _G.UnitLevel = nil, nil, nil

suite.done()
