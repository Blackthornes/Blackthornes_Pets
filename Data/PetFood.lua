-- Blackthornes Pets -- Data/PetFood.lua
-- Which diet each pet food belongs to, by item ID, with its English name.
--
-- The client says what a pet eats (C_PetInfo.GetPetFoodTypes: "Meat",
-- "Fish", ...) but not what diet an item is, so this list says. It is the
-- classic vendor, drop and cooked foods up to level 60. A food missing from
-- it is simply not offered; add it here under its diet. The item's level
-- comes from the client, not from here.
--
-- Each food is { item ID, "English name" }: the ID is what is matched, so
-- the list works on a client in any language, and the name keeps a line
-- easy to check against the game's tooltip. tools/petfood_ids.py fills in
-- the ID for a food added by name alone ("Name",) from pfQuest's item
-- names; a food it cannot find stays a name, matched by the English name
-- as before.

local _, ns = ...
local L = ns.L

local DIETS = {
    Meat = {
        -- Vendor
        { 117, "Tough Jerky" },
        { 2287, "Haunch of Meat" },
        { 3770, "Mutton Chop" },
        { 3771, "Wild Hog Shank" },
        { 4599, "Cured Ham Steak" },
        { 8952, "Roasted Quail" },
        -- Raw, from beasts
        { 769, "Chunk of Boar Meat" },
        { 2672, "Stringy Wolf Meat" },
        { 12208, "Tender Wolf Meat" },
        { 2677, "Boar Ribs" },
        { 3172, "Boar Intestines" },
        { 2673, "Coyote Meat" },
        { 2674, "Crawler Meat" },
        { 2924, "Crocolisk Meat" },
        { 3667, "Tender Crocolisk Meat" },
        { 3173, "Bear Meat" },
        { 3730, "Big Bear Meat" },
        { 3731, "Lion Meat" },
        { 5471, "Stag Meat" },
        { 5467, "Kodo Meat" },
        { 5469, "Strider Meat" },
        { 723, "Goretusk Liver" },
        { 12184, "Raptor Flesh" },
        { 12205, "White Spider Meat" },
        { 12203, "Red Wolf Meat" },
        { 12202, "Tiger Meat" },
        { 12204, "Heavy Kodo Meat" },
        { 12037, "Mystery Meat" },
        { 3404, "Buzzard Wing" },
        "Bat Wing",
        -- Cooked
        { 2681, "Roasted Boar Meat" },
        { 2679, "Charred Wolf Meat" },
        { 2680, "Spiced Wolf Meat" },
        { 5474, "Roasted Kodo Meat" },
        { 2684, "Coyote Steak" },
        { 3662, "Crocolisk Steak" },
        { 3664, "Crocolisk Gumbo" },
        { 6890, "Smoked Bear Meat" },
        { 724, "Goretusk Liver Pie" },
        { 1082, "Redridge Goulash" },
        { 1017, "Seasoned Wolf Kabob" },
        { 12210, "Roast Raptor" },
        { 3727, "Hot Lion Chops" },
        { 3728, "Tasty Lion Steak" },
        { 4457, "Barbecued Buzzard Wing" },
        { 12215, "Heavy Kodo Stew" },
        { 5472, "Kaldorei Spider Kabob" },
        { 2888, "Beer Basted Boar Ribs" },
        { 12224, "Crispy Bat Wing" },
        { 5473, "Scorpid Surprise" },
    },
    Fish = {
        -- Vendor
        { 787, "Slitherskin Mackerel" },
        { 4592, "Longjaw Mud Snapper" },
        { 4593, "Bristle Whisker Catfish" },
        { 4594, "Rockscale Cod" },
        { 21552, "Striped Yellowtail" },
        { 8957, "Spinefin Halibut" },
        -- Raw
        { 6303, "Raw Slitherskin Mackerel" },
        { 6289, "Raw Longjaw Mud Snapper" },
        { 6291, "Raw Brilliant Smallfish" },
        { 6308, "Raw Bristle Whisker Catfish" },
        { 6362, "Raw Rockscale Cod" },
        { 21071, "Raw Sagefish" },
        { 6317, "Raw Loch Frenzy" },
        { 6361, "Raw Rainbow Fin Albacore" },
        { 8365, "Raw Mithril Head Trout" },
        { 4603, "Raw Spotted Yellowtail" },
        { 13758, "Raw Redgill" },
        { 13889, "Raw Whitescale Salmon" },
        { 13759, "Raw Nightfin Snapper" },
        { 13760, "Raw Sunscale Salmon" },
        { 13754, "Raw Glossy Mightfish" },
        { 13755, "Winter Squid" },
        -- Cooked
        { 6290, "Brilliant Smallfish" },
        { 21072, "Smoked Sagefish" },
        { 6316, "Loch Frenzy Delight" },
        { 5095, "Rainbow Fin Albacore" },
        { 6887, "Spotted Yellowtail" },
        { 13928, "Grilled Squid" },
        { 13927, "Cooked Glossy Mightfish" },
        { 13930, "Filet of Redgill" },
        { 13931, "Nightfin Soup" },
        { 13935, "Baked Salmon" },
        { 5476, "Fillet of Frenzy" },
    },
    Bread = {
        { 4540, "Tough Hunk of Bread" },
        { 4541, "Freshly Baked Bread" },
        { 4542, "Moist Cornbread" },
        { 4544, "Mulgore Spice Bread" },
        { 4601, "Soft Banana Bread" },
        { 8950, "Homemade Cherry Pie" },
    },
    Cheese = {
        { 2070, "Darnassian Bleu" },
        { 414, "Dalaran Sharp" },
        { 422, "Dwarven Mild" },
        { 1707, "Stormwind Brie" },
        { 3927, "Fine Aged Cheddar" },
        { 8932, "Alterac Swiss" },
    },
    Fruit = {
        { 4536, "Shiny Red Apple" },
        { 4537, "Tel'Abim Banana" },
        { 4538, "Snapvine Watermelon" },
        { 4539, "Goldenbark Apple" },
        { 4602, "Moon Harvest Pumpkin" },
        { 8953, "Deep Fried Plantains" },
    },
    Fungus = {
        { 4604, "Forest Mushroom Cap" },
        { 4605, "Red-speckled Mushroom" },
        { 4606, "Spongy Morel" },
        { 4607, "Delicious Cave Mold" },
        { 4608, "Raw Black Truffle" },
        { 8948, "Dried King Bolete" },
    },
}

-- The words the client uses for each diet (GetPetFoodTypes), to this file's
-- diet keys. English is what the probe read on Forever. The German words
-- are classic's and not yet seen on Forever: a word missing here only means
-- that diet's food is not offered, never the wrong food.
local DIET_WORDS = {
    Meat = "Meat", Fish = "Fish", Bread = "Bread", Cheese = "Cheese",
    Fruit = "Fruit", Fungus = "Fungus",
    -- German (unverified)
    Fleisch = "Meat", Fisch = "Fish", Brot = "Bread", ["Käse"] = "Cheese",
    Obst = "Fruit", Pilz = "Fungus", Pilze = "Fungus",
}

-- Each diet's name as players read it, in their language.
local LABELS = {
    Meat = L["Meat"], Fish = L["Fish"], Bread = L["Bread"], Cheese = L["Cheese"],
    Fruit = L["Fruit"], Fungus = L["Fungus"],
}

--- A diet key ("Meat") as players read it.
local function Label(diet)
    return LABELS[diet] or diet
end

-- item ID -> diet, and English name -> diet for a food with no ID.
local byID, byName = {}, {}
for diet, foods in pairs(DIETS) do
    for _, food in ipairs(foods) do
        if type(food) == "table" then
            if food[1] then byID[food[1]] = diet end
            if food[2] then byName[food[2]] = diet end
        else
            byName[food] = diet
        end
    end
end

local lowerWords = {}
for word, diet in pairs(DIET_WORDS) do lowerWords[word:lower()] = diet end

--- This file's diet key for one of the client's diet words, or nil.
local function Diet(word)
    if type(word) ~= "string" then return nil end
    return DIET_WORDS[word] or lowerWords[word:lower()]
end

--- The diet an item is: by its ID, else by its English name. nil when it
--- is not pet food this file knows.
local function DietOf(itemID, name)
    return (itemID and byID[itemID]) or (name and byName[name]) or nil
end

--- The diets a pet eats, as a set of diet keys, from the client's words.
--- A word this file does not know is kept as itself, so an English food
--- list still lines up with it.
local function Eats(foods)
    local eats = {}
    for _, word in ipairs(foods or {}) do
        eats[Diet(word) or word] = true
    end
    return eats
end

ns.PetFood = {
    DIETS = DIETS,
    DIET_WORDS = DIET_WORDS,
    byID = byID,
    byName = byName,
    Diet = Diet,
    DietOf = DietOf,
    Eats = Eats,
    Label = Label,
}
