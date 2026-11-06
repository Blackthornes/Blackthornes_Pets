-- Every language: the client names the pet's diet in its own language
-- (French "Viande", Russian "Мясо", ...). The food helper must line that
-- word up with the food list, or a wolf with meat in the bags reads "No
-- food". Food is found by item ID, so only the diet word and buff text
-- depend on the language.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("dietwords")

local ns = env.Load()
local Food, PetFood = ns.Food, ns.PetFood

local WORDS = {
    enUS = { "Meat", "Fish", "Bread", "Cheese", "Fruit", "Fungus" },
    deDE = { "Fleisch", "Fisch", "Brot", "Käse", "Obst", "Pilz" },
    frFR = { "Viande", "Poisson", "Pain", "Fromage", "Fruits", "Champignon" },
    esES = { "Carne", "Pescado", "Pan", "Queso", "Fruta", "Hongo" },
    ruRU = { "Мясо", "Рыба", "Хлеб", "Сыр", "Фрукты", "Грибы" },
    zhCN = { "肉", "鱼", "面包", "奶酪", "水果", "蘑菇" },
}
local KEYS = { "Meat", "Fish", "Bread", "Cheese", "Fruit", "Fungus" }

for locale, words in pairs(WORDS) do
    for i, word in ipairs(words) do
        suite.check(locale .. " " .. word .. " is " .. KEYS[i], PetFood.Diet(word) == KEYS[i], PetFood.Diet(word))
    end
end
suite.check("lower case works too", PetFood.Diet("viande") == "Meat" and PetFood.Diet("мясо") == "Meat")
suite.check("spaces around the word are fine", PetFood.Diet(" Viande ") == "Meat")
suite.check("a word it does not know is nil", PetFood.Diet("Xyzzy") == nil)

-- The report: a level 11 wolf on a French client, meat in the bags.
_G.UnitClass = function() return "Chasseur", "HUNTER" end
_G.UnitExists = function(unit) return unit == "pet" end
_G.UnitName = function() return "Loup" end
_G.UnitLevel = function() return 11 end
local diet = { "Viande" }
_G.C_PetInfo = {
    GetPetHappiness = function() return 3, 125, 5 end,
    GetPetFoodTypes = function() return diet end,
}
local ITEMS = {
    [2287] = { "Cuissot", 15 },
    [117] = { "Bœuf séché coriace", 5 },
    [4536] = { "Pomme rouge brillante", 5 },
    [21072] = { "Merlan fumé", 10 },
}
local bags = {
    [0] = { [1] = { itemID = 2287, stackCount = 7 }, [2] = { itemID = 117, stackCount = 12 } },
    [1] = { [1] = { itemID = 4536, stackCount = 20 } },
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
local BUFF_TEXT = {
    frFR = "Utiliser : Rend 294 points de vie en 21 sec. Si vous passez au moins 10 secondes à manger, vous serez bien nourri et gagnerez 6 en endurance et en esprit pendant 15 min.",
    esES = "Uso: Restaura 294 p. de salud durante 21 s. Si pasas al menos 10 s comiendo, estarás bien alimentado y ganarás 6 de aguante y espíritu durante 15 min.",
    ruRU = "Использование: Восполняет 294 ед. здоровья в течение 21 сек. Если вы проведете за едой не менее 10 сек., то почувствуете сытость и получите 6 ед. к выносливости и духу на 15 мин.",
    zhCN = "使用：在21秒内恢复294点生命值。如果你花费至少10秒进食，你将会进食充分并获得6点耐力和精神，持续15分钟。",
}
local PLAIN_TEXT = {
    frFR = "Utiliser : Rend 61 points de vie en 18 sec. Vous devez rester assis pendant que vous mangez.",
    esES = "Uso: Restaura 61 p. de salud durante 18 s. Debes permanecer sentado mientras comes.",
    ruRU = "Использование: Восполняет 61 ед. здоровья в течение 18 сек. Во время еды нужно сидеть.",
    zhCN = "使用：在18秒内恢复61点生命值。进食时必须保持坐姿。",
}
local locale = "frFR"
_G.C_TooltipInfo = {
    GetItemByID = function(id)
        local text = id == 21072 and BUFF_TEXT[locale] or PLAIN_TEXT[locale]
        return { lines = { { leftText = ITEMS[id] and ITEMS[id][1] or "?" }, { leftText = text } } }
    end,
}

local stacks = Food:Scan()
suite.check("the French wolf finds both meats", #stacks == 2, #stacks)
suite.check("and counts all 19", Food:Count(stacks) == 19, Food:Count(stacks))
local apple = ns.Butler:Advise(4536)
suite.check("the apple is not for it", apple and apple.eats == false)
local meat = ns.Butler:Advise(2287)
suite.check("Butler hears it eats the haunch", meat and meat.eats == true and meat.count == 7)

-- The same wolf in every other language.
for other, words in pairs(WORDS) do
    diet = { words[1] }
    Food.kept = nil
    Food:BagsChanged()
    local found = Food:Scan()
    suite.check(other .. " wolf finds the meat", #found == 2, #found)
end

-- Buff food told apart from plain food in each language.
for _, other in ipairs({ "frFR", "esES", "ruRU", "zhCN" }) do
    locale = other
    Food.buffKnown, Food.buffTries, Food.buffFirst, Food.buffGuessed = nil, nil, nil, nil
    suite.check(other .. " buff food is buff food", Food:IsBuffFood(21072) == true)
    suite.check(other .. " plain food is plain", Food:IsBuffFood(117) == false)
end

suite.done()
