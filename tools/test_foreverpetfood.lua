-- Forever's own foods from the client's game tables (Data/ForeverPetFood.lua)
-- laid over Data/PetFood.lua's hand list.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("foreverpetfood")

local ns = env.Load()
local PetFood, Forever = ns.PetFood, ns.ForeverPetFood

suite.check("the client's list is loaded", type(Forever) == "table" and type(Forever.FOOD) == "table")

local count = 0
for _ in pairs(Forever.FOOD) do count = count + 1 end
suite.check("it knows hundreds of foods", count > 300)

-- Every food the client names is known, under the client's diet.
local all = true
for itemID, food in pairs(Forever.FOOD) do
    if PetFood.DietOf(itemID) ~= food[1] then all = false end
end
suite.check("every client food has the client's diet", all)

suite.check("a Classic food the hand list missed", PetFood.DietOf(733) == "Meat")          -- Westfall Stew
suite.check("one of Forever's own cooked foods", PetFood.DietOf(232436) == "Fish")         -- Darkclaw Bisque
suite.check("a fish weight from fishing", PetFood.DietOf(6292) == "Fish")                  -- 10 Pound Mud Snapper
suite.check("the client's diet beats the hand list", PetFood.DietOf(2683) == "Fish")       -- Crab Cake
suite.check("the hand list still answers", PetFood.DietOf(117) == "Meat")

-- What is never offered.
suite.check("a food no pet eats on Forever is dropped", PetFood.DietOf(12223) == nil)      -- Meaty Bat Wing
suite.check("and not by its name either", PetFood.DietOf(nil, "Meaty Bat Wing") == nil)
suite.check("conjured food is left out", PetFood.DietOf(1113) == nil)                       -- Conjured Bread
suite.check("quest items are left out", PetFood.DietOf(5051) == nil)                       -- Dig Rat
suite.check("diets a pet never names are left out", PetFood.DietOf(887) == nil)            -- Pound of Flesh

-- Every diet is one the file already has words for.
local known = { Meat = true, Fish = true, Bread = true, Cheese = true, Fruit = true, Fungus = true }
local good = true
for _, food in pairs(Forever.FOOD) do
    if not known[food[1]] then good = false end
end
suite.check("only the six diets", good)

suite.done()
