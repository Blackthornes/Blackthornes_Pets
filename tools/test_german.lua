-- A German client: the client names diets, items, spells and families in
-- its own language. The food helper finds food by item ID and knows the
-- German diet words, buff food is told from its German text, Beast
-- Training and a tame are read under the data's English skill names, and a
-- tamed beast's family is placed by its ID. English goes on as before.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("german")

local ns = env.Load()
local Food, PetFood = ns.Food, ns.PetFood

-- The diet words.
suite.check("Fleisch is meat", PetFood.Diet("Fleisch") == "Meat")
suite.check("Käse is cheese", PetFood.Diet("Käse") == "Cheese")
suite.check("Obst is fruit", PetFood.Diet("Obst") == "Fruit")
suite.check("English is still English", PetFood.Diet("Fish") == "Fish")
suite.check("a word it does not know is nil", PetFood.Diet("Viande") == nil)
suite.check("food is known by ID", PetFood.DietOf(117) == "Meat")
suite.check("whatever the client calls it", PetFood.DietOf(117, "Zähes Stockfleisch") == "Meat")
suite.check("and by English name when it has no ID", PetFood.DietOf(nil, "Bat Wing") == "Meat")
suite.check("every food but one carries its ID", (function()
    local named = 0
    for _ in pairs(PetFood.byName) do named = named + 1 end
    local ids = 0
    for _ in pairs(PetFood.byID) do ids = ids + 1 end
    return ids >= 100 and named == ids + 1
end)())

-- A hunter with a level 9 boar on a German client.
_G.UnitClass = function() return "Jäger", "HUNTER" end
_G.UnitExists = function(unit) return unit == "pet" end
_G.UnitName = function() return "Eber" end
_G.UnitLevel = function() return 9 end
_G.C_PetInfo = {
    GetPetHappiness = function() return 3, 125, 5 end,
    GetPetFoodTypes = function() return { "Fleisch", "Fisch", "Brot" } end,
}
local ITEMS = {
    [117] = { "Zähes Stockfleisch", 5 },
    [2287] = { "Fleischschenkel", 15 },
    [4540] = { "Zäher Brocken Brot", 5 },
    [4536] = { "Glänzender roter Apfel", 5 },      -- fruit: not eaten
    [21072] = { "Geräucherter Weisenfisch", 10 },  -- fish, and buff food
}
local bags = {
    [0] = { [1] = { itemID = 2287, stackCount = 4 }, [3] = { itemID = 117, stackCount = 3 } },
    [1] = { [2] = { itemID = 4536, stackCount = 20 }, [4] = { itemID = 21072, stackCount = 2 } },
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
_G.C_TooltipInfo = {
    GetItemByID = function(id)
        local text = id == 21072
            and "Benutzen: Stellt im Verlauf von 21 Sek. 294 Punkt(e) Gesundheit wieder her. Wenn Ihr mindestens 10 Sek. lang esst, werdet Ihr satt und erhaltet 6 Ausdauer und Willenskraft für 15 Min."
            or "Benutzen: Stellt im Verlauf von 18 Sek. 61 Punkt(e) Gesundheit wieder her."
        return { lines = { { leftText = ITEMS[id] and ITEMS[id][1] or "?" }, { leftText = text } } }
    end,
}

local stacks = Food:Scan()
suite.check("finds the four foods it eats", #stacks == 4, #stacks)
suite.check("plain food first, by its German name",
    stacks[1].name == "Zähes Stockfleisch" and stacks[1].diet == "Meat", stacks[1] and stacks[1].name)
suite.check("the fruit it does not eat is left out", (function()
    for _, stack in ipairs(stacks) do if stack.itemID == 4536 then return false end end
    return true
end)())
suite.check("German buff food goes last", stacks[4].itemID == 21072 and stacks[4].buff == true)
suite.check("plain food is not buff food", Food:IsBuffFood(117) == false)

local advice = ns.Butler:Advise(117)
suite.check("Butler hears the pet eats it", advice and advice.eats == true and advice.count == 3,
    advice and advice.count)
local apple = ns.Butler:Advise(4536)
suite.check("and not the apple", apple and apple.eats == false)

-- "Satt" only as a word of its own.
Food.buffKnown = nil
_G.C_TooltipInfo.GetItemByID = function()
    return { lines = { { leftText = "Sattelzeug" }, { leftText = "Benutzen: Stellt 61 Gesundheit wieder her." } } }
end
suite.check("a word with satt inside is not buff food", Food:IsBuffFood(117) == false)

-- Beast Training names its skills in German.
_G.C_Spell = {
    GetSpellName = function(id)
        return ({ [17253] = "Beißen", [17254] = "Beißen", [7371] = "Sturmangriff", [7370] = "Sturmangriff" })[id]
    end,
    GetSpellSubtext = function(id) return ({ [17253] = "Rang 1" })[id] end,
}
ns.charDB.beastTraining = nil
local crafts = {
    { "Beißen", "Rang 1", "used" },
    { "Sturmangriff", "Rang 1", "available" },
}
_G.GetNumCrafts = function() return #crafts end
_G.GetCraftInfo = function(i) return unpack(crafts[i]) end
suite.check("reads the German window", ns.Taming:ReadBeastTraining() == 2)
suite.check("under the data's English names", ns.charDB.beastTraining.known["Bite#1"] == true
    and ns.charDB.beastTraining.known["Charge#1"] == true)
_G.GetNumCrafts, _G.GetCraftInfo = nil, nil
suite.check("a German skill name turns English", ns.Taming:EnglishName("Beißen") == "Bite")
suite.check("an English one stays", ns.Taming:EnglishName("Claw") == "Claw")

-- A tame: the pet bar's skill is kept by its English name, and the family
-- by its ID.
local clock = 100
_G.GetTime = function() return clock end
_G.UnitGUID = function(unit) if unit == "target" then return "Creature-0-1-2-3-999001-00001" end end
_G.UnitName = function(unit) if unit == "target" then return "Schattenflügel" end return "Eule" end
_G.UnitCreatureFamily = function() return "Eule", 26 end
_G.GetPetActionInfo = function(slot)
    if slot == 1 then return "Beißen", nil, false, false, true, false, 17253 end
end
ns.TameRecord:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
local record = ns.TameRecord:Capture()
suite.check("the tame is recorded", record ~= nil)
suite.check("its skill under the English name", record and record.skills[1].name == "Bite"
    and record.skills[1].rank == 1, record and record.skills[1] and record.skills[1].name)
suite.check("the family as the client says it, and its ID", record and record.family == "Eule"
    and record.familyID == 26)
ns.Compendium:Invalidate()
local entry = ns.Compendium:Get(999001)
suite.check("the compendium places it by the ID", entry and entry.family == "Owl"
    and entry.diet == "Meat", entry and entry.family)
suite.check("and knows what taming it teaches", (function()
    local skills = ns.Taming:SkillsFor(999001)
    return skills[1] and skills[1].name == "Bite" and skills[1].teach == 17254
end)())

-- An old record with only a German family name keeps it as it was.
ns.db.tamedBeasts[999002] = { name = "Alte Eule", level = 10, family = "Eule", skills = {} }
ns.Compendium:Invalidate()
suite.check("an old record keeps its family name", ns.Compendium:Get(999002).family == "Eule")

_G.C_Container, _G.C_Item, _G.C_PetInfo, _G.C_TooltipInfo, _G.C_Spell = nil, nil, nil, nil, nil
_G.UnitClass, _G.UnitExists, _G.UnitName, _G.UnitLevel = nil, nil, nil, nil
_G.UnitGUID, _G.UnitCreatureFamily, _G.GetPetActionInfo, _G.GetTime = nil, nil, nil, nil

suite.done()
