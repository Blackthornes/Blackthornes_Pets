-- Butler's call: what Blackthornes Butler hears about a bag item for the
-- character's pet, read once per burst of calls.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("butler")

local ns = env.Load()
local Butler = ns.Butler

suite.check("the call is on the global", _G.BlackthornesPets.Butler == Butler
    and type(Butler.Advise) == "function")

-- A hunter with a level 9 boar that eats meat and bread.
local classCalls = 0
_G.UnitClass = function() classCalls = classCalls + 1; return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Boar" end
_G.UnitLevel = function() return 9 end
_G.C_PetInfo = {
    GetPetFoodTypes = function() return { "Meat", "Bread" } end,
}
local clock = 100
_G.GetTime = function() return clock end

local ITEMS = {
    [117] = { "Tough Jerky", 5 },
    [2287] = { "Haunch of Meat", 15 },
    [4540] = { "Tough Hunk of Bread", 5 },
    [4536] = { "Shiny Red Apple", 5 },       -- fruit: this boar will not eat it
    [2589] = { "Linen Cloth", 5 },            -- not food
    [3220] = { "Blood Sausage", 5 },          -- buff food (meat)
    [2681] = { "Roasted Boar Meat", 5 },      -- meat, not carried
}
local bags = {
    [0] = { [1] = { itemID = 117, stackCount = 10 }, [2] = { itemID = 117, stackCount = 5 } },
    [1] = { [1] = { itemID = 2287, stackCount = 4 }, [2] = { itemID = 4536, stackCount = 20 },
            [3] = { itemID = 2589, stackCount = 10 }, [4] = { itemID = 3220, stackCount = 2 } },
}
local slotReads = 0
_G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and 16 or 0 end,
    GetContainerItemInfo = function(bag, slot)
        slotReads = slotReads + 1
        return bags[bag] and bags[bag][slot]
    end,
}
_G.C_Item = {
    GetItemInfo = function(id)
        local item = ITEMS[id]
        if item then return item[1], nil, 1, item[2] end
    end,
}
_G.C_TooltipInfo = {
    GetItemByID = function(id)
        local text = id == 3220 and "Use: Restores health. If you eat for 10 seconds you will become well fed"
            or "Use: Restores health."
        return { lines = { { leftText = ITEMS[id] and ITEMS[id][1] or "?" }, { leftText = text } } }
    end,
}

-- Blood Sausage needs to be in the food list for the test; it is meat.
ns.PetFood.byName["Blood Sausage"] = ns.PetFood.byName["Blood Sausage"] or "Meat"

local jerky = Butler:Advise(117)
suite.check("food the pet eats", jerky and jerky.eats == true and jerky.buff == false)
suite.check("counts every stack of it", jerky.count == 15, jerky and jerky.count)
-- 15 + 4 full (Haunch is level 15, pet 9) + 2 buff sausage = 21 pieces at
-- 35,000 each, 670 lost every 7.5 s: about 2.3 hours.
suite.check("about how many hours all the food lasts", jerky.hours == 2.3, jerky.hours)

local sausage = Butler:Advise(3220)
suite.check("buff food says so", sausage and sausage.buff == true and sausage.eats == true
    and sausage.count == 2, sausage and sausage.count)

local apple = Butler:Advise(4536)
suite.check("food of a diet it will not eat", apple and apple.eats == false and apple.count == nil)
suite.check("not food at all is nil", Butler:Advise(2589) == nil)
suite.check("an item the client does not know is nil", Butler:Advise(99999) == nil)
suite.check("a bad argument is nil", Butler:Advise("x") == nil and Butler:Advise(nil) == nil)

local roast = Butler:Advise(2681)
suite.check("food it eats but none carried counts none", roast and roast.eats and roast.count == 0,
    roast and roast.count)

-- A burst reads the pet and the bags once.
local before, beforeClass = slotReads, classCalls
for _ = 1, 100 do Butler:Advise(117); Butler:Advise(2589) end
suite.check("a burst reads the bags no more", slotReads == before, slotReads - before)
suite.check("and the pet no more", classCalls == beforeClass, classCalls - beforeClass)

-- A bag change: read again.
bags[0][2] = nil
ns.Food:BagsChanged()
suite.check("a bag change is seen", Butler:Advise(117).count == 10)

-- Never feed buff food: the scan leaves it out, so its count is unknown.
ns.db.neverFeedBuffFood = true
clock = clock + 5
local kept = Butler:Advise(3220)
suite.check("buff food never fed has no count", kept and kept.buff and kept.count == nil)
ns.db.neverFeedBuffFood = false

-- What Butler gets is a copy.
Butler:Advise(117).count = 999
suite.check("the kept answer cannot be changed", Butler:Advise(117).count == 10)

-- No pet out.
clock = clock + 5
_G.UnitExists = function() return false end
suite.check("no pet is nil", Butler:Advise(117) == nil)

-- A warlock with a demon.
clock = clock + 5
_G.UnitExists = function() return true end
_G.UnitClass = function() return "Warlock", "WARLOCK" end
suite.check("a warlock is nil", Butler:Advise(117) == nil)

-- An error inside is nil, not raised.
clock = clock + 5
_G.UnitClass = function() return "Hunter", "HUNTER" end
local read = ns.PetStatus.Read
ns.PetStatus.Read = function() error("boom") end
local ok, answer = pcall(Butler.Advise, Butler, 117)
suite.check("an error is nil and never raised", ok and answer == nil)
ns.PetStatus.Read = read

_G.C_Container, _G.C_Item, _G.C_PetInfo, _G.C_TooltipInfo = nil, nil, nil, nil
_G.UnitExists, _G.UnitName, _G.UnitLevel, _G.UnitClass, _G.GetTime = nil, nil, nil, nil, nil

suite.done()
