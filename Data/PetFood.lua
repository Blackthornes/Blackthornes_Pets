-- Blackthornes Pets -- Data/PetFood.lua
-- Which diet each pet food belongs to, by its English item name.
--
-- The client says what a pet eats (C_PetInfo.GetPetFoodTypes: "Meat",
-- "Fish", ...) but not what diet an item is, so this list says. It is the
-- classic vendor, drop and cooked foods up to level 60. A food missing from
-- it is simply not offered; add it here under its diet. The item's level
-- comes from the client, not from here.
--
-- Keyed by name rather than item ID so a line is easy to check against the
-- game's tooltip. Names are English: on another language's client nothing
-- matches and the helper shows no food rather than the wrong food.

local _, ns = ...

local DIETS = {
    Meat = {
        -- Vendor
        "Tough Jerky", "Haunch of Meat", "Mutton Chop", "Wild Hog Shank",
        "Cured Ham Steak", "Roasted Quail",
        -- Raw, from beasts
        "Chunk of Boar Meat", "Stringy Wolf Meat", "Tender Wolf Meat",
        "Boar Ribs", "Boar Intestines", "Coyote Meat", "Crawler Meat",
        "Crocolisk Meat", "Tender Crocolisk Meat", "Bear Meat", "Big Bear Meat",
        "Lion Meat", "Stag Meat", "Kodo Meat", "Strider Meat", "Goretusk Liver",
        "Raptor Flesh", "White Spider Meat", "Red Wolf Meat", "Tiger Meat",
        "Heavy Kodo Meat", "Mystery Meat", "Buzzard Wing", "Bat Wing",
        -- Cooked
        "Roasted Boar Meat", "Charred Wolf Meat", "Spiced Wolf Meat",
        "Roasted Kodo Meat", "Coyote Steak", "Crocolisk Steak",
        "Crocolisk Gumbo", "Smoked Bear Meat", "Goretusk Liver Pie",
        "Redridge Goulash", "Seasoned Wolf Kabob", "Roast Raptor",
        "Hot Lion Chops", "Tasty Lion Steak", "Barbecued Buzzard Wing",
        "Heavy Kodo Stew", "Kaldorei Spider Kabob", "Beer Basted Boar Ribs",
        "Crispy Bat Wing", "Scorpid Surprise",
    },
    Fish = {
        -- Vendor
        "Slitherskin Mackerel", "Longjaw Mud Snapper", "Bristle Whisker Catfish",
        "Rockscale Cod", "Striped Yellowtail", "Spinefin Halibut",
        -- Raw
        "Raw Slitherskin Mackerel", "Raw Longjaw Mud Snapper",
        "Raw Brilliant Smallfish", "Raw Bristle Whisker Catfish",
        "Raw Rockscale Cod", "Raw Sagefish", "Raw Loch Frenzy",
        "Raw Rainbow Fin Albacore", "Raw Mithril Head Trout",
        "Raw Spotted Yellowtail", "Raw Redgill", "Raw Whitescale Salmon",
        "Raw Nightfin Snapper", "Raw Sunscale Salmon", "Raw Glossy Mightfish",
        "Winter Squid",
        -- Cooked
        "Brilliant Smallfish", "Smoked Sagefish", "Loch Frenzy Delight",
        "Rainbow Fin Albacore", "Spotted Yellowtail", "Grilled Squid",
        "Cooked Glossy Mightfish", "Filet of Redgill", "Nightfin Soup",
        "Baked Salmon", "Fillet of Frenzy",
    },
    Bread = {
        "Tough Hunk of Bread", "Freshly Baked Bread", "Moist Cornbread",
        "Mulgore Spice Bread", "Soft Banana Bread", "Homemade Cherry Pie",
    },
    Cheese = {
        "Darnassian Bleu", "Dalaran Sharp", "Dwarven Mild", "Stormwind Brie",
        "Fine Aged Cheddar", "Alterac Swiss",
    },
    Fruit = {
        "Shiny Red Apple", "Tel'Abim Banana", "Snapvine Watermelon",
        "Goldenbark Apple", "Moon Harvest Pumpkin", "Deep Fried Plantains",
    },
    Fungus = {
        "Forest Mushroom Cap", "Red-speckled Mushroom", "Spongy Morel",
        "Delicious Cave Mold", "Raw Black Truffle", "Dried King Bolete",
    },
}

-- name -> diet
local byName = {}
for diet, names in pairs(DIETS) do
    for _, name in ipairs(names) do
        byName[name] = diet
    end
end

ns.PetFood = {
    DIETS = DIETS,
    byName = byName,
}
