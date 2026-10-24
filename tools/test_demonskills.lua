-- The warlock's demon books on the Skills card: what the demon knows, the
-- grimoires to buy now and later, the prices and spot a demon trainer's
-- window teaches, and the card's lines.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("demonskills")

local ns = env.Load()
local DemonSkills, Data = ns.DemonSkills, ns.DemonBooksData

-- The data.
suite.check("the four demons are there", Data.DEMONS.Imp and Data.DEMONS.Voidwalker
    and Data.DEMONS.Succubus and Data.DEMONS.Felhunter)
local broken
for demon, entry in pairs(Data.DEMONS) do
    for skill, ranks in pairs(entry.skills) do
        for rank, row in pairs(ranks) do
            if type(row.spell) ~= "number" or not (row.free
                or (type(row.book) == "number" and type(row.level) == "number" and type(row.cost) == "number")) then
                broken = demon .. " " .. skill .. " " .. rank
            end
        end
    end
end
suite.check("every rank is free or has a grimoire, level and price", broken == nil, broken)
suite.check("a spell names its skill and rank", Data.SPELLS[3110] and Data.SPELLS[3110][1] == "Firebolt")

local function Find(list, name)
    for _, entry in ipairs(list) do
        if entry.name == name then return entry end
    end
    return nil
end

-- The plan for a Voidwalker at level 32 that has bought nothing.
local plan = DemonSkills:Plan("Voidwalker", {}, 32)
suite.check("Torment's first rank comes free", Find(plan.known, "Torment")
    and Find(plan.known, "Torment").rank == 1)
local sacrifice = Find(plan.learn, "Sacrifice")
suite.check("only the best rank it can buy is offered", sacrifice and (function()
    local best = 0
    for rank, row in pairs(Data.DEMONS.Voidwalker.skills.Sacrifice) do
        if not row.free and row.level <= 32 and rank > best then best = rank end
    end
    return sacrifice.rank == best
end)())
suite.check("with its grimoire and price", sacrifice and type(sacrifice.book) == "number"
    and type(sacrifice.cost) == "number")
suite.check("later comes nearest first", (function()
    local last = 0
    for _, entry in ipairs(plan.later) do
        if entry.level < last or entry.level <= 32 then return false end
        last = entry.level
    end
    return true
end)())
suite.check("later shows a few lines at most", #plan.later <= DemonSkills.LATER_MOST)
suite.check("nothing to buy at level 1", #DemonSkills:Plan("Voidwalker", {}, 1).learn == 0)

local top = {}
for name, ranks in pairs(Data.DEMONS.Imp.skills) do
    local best = 0
    for rank in pairs(ranks) do if rank > best then best = rank end end
    top[name] = best
end
plan = DemonSkills:Plan("Imp", top, 60)
suite.check("a demon that knows it all has nothing to buy", #plan.learn == 0 and #plan.later == 0)
suite.check("an unknown demon has no plan", DemonSkills:Plan("Doomguard", {}, 60) == nil)

-- A price a trainer asked beats the data's.
local row = { book = 16321, cost = 100 }
suite.check("the data's price at first", DemonSkills.Price(row) == 100)
ns.db.demonBookPrices = { [16321] = 95 }
suite.check("the trainer's price once seen", DemonSkills.Price(row) == 95)
ns.db.demonBookPrices = nil

-- A demon trainer's window: its spot and prices are kept.
local book = sacrifice.book
_G.GetMerchantNumItems = function() return 2 end
_G.GetMerchantItemID = function(i) return i == 1 and 2589 or book end
_G.GetMerchantItemInfo = function(i) return "x", nil, i == 1 and 13 or 17500 end
_G.UnitGUID = function(unit) if unit == "npc" then return "Creature-0-1-2-3-5875-0001" end end
_G.UnitName = function(unit) if unit == "npc" then return "Gan'rul Bloodeye" end return "Me" end
local realHere = ns.BeastArrow.Here
ns.BeastArrow.Here = function() return { zone = "Orgrimmar", x = 0.4851, y = 0.4573 } end
ns.Travel.Side = function() return "H" end
suite.check("a grimoire on the list makes it a demon trainer", DemonSkills:ReadMerchant() == true)
local kept = ns.db.demonTrainers and ns.db.demonTrainers[5875]
suite.check("its spot is kept", kept and kept.zone == "Orgrimmar" and kept.x == 48.5 and kept.y == 45.7
    and kept.name == "Gan'rul Bloodeye" and kept.side == "H")
suite.check("and the price it asked", ns.db.demonBookPrices and ns.db.demonBookPrices[book] == 17500
    and ns.db.demonBookPrices[2589] == nil)
local trainer = DemonSkills:Trainer()
suite.check("it is the nearest demon trainer", trainer and trainer.id == 5875)
ns.Travel.Side = function() return "A" end
suite.check("never one of the other side", DemonSkills:Trainer() == nil)
ns.Travel.Side = function() return "H" end

_G.GetMerchantItemID = function() return 2589 end
ns.db.demonTrainers = nil
suite.check("a vendor with no grimoire is not one", DemonSkills:ReadMerchant() == false
    and ns.db.demonTrainers == nil)
ns.BeastArrow.Here = realHere
_G.GetMerchantNumItems, _G.GetMerchantItemID, _G.GetMerchantItemInfo, _G.UnitGUID = nil, nil, nil, nil

-- The card's lines.
local UI = ns.UI
suite.check("coin in gold, silver and copper", UI.Money(17500):find("1") and UI.Money(17500):find("75")
    and not UI.Money(17500):find("0c"))
plan = DemonSkills:Plan("Voidwalker", {}, 32)
local lines = UI.DemonSkillLines(plan, "learn")
local bought
for _, line in ipairs(lines) do
    if line.label:find("Sacrifice") then bought = line end
end
suite.check("a book to buy names its grimoire and price", bought and bought.value and bought.value ~= "")
lines = UI.DemonSkillLines(plan, "later")
suite.check("a later book names its level", lines[1] and lines[1].value:find(tostring(plan.later[1].level)))

suite.done()
