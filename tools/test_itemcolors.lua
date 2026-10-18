-- Food names show in their rarity colour (the owner, 2026-10-18): the pets
-- window, the Feed buttons and the key's tooltip. The Feed macro stays plain:
-- it uses the food by bag and slot.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("itemcolors")

local ns = env.Load()
local Food = ns.Food

local HEX = { [0] = "ff9d9d9d", "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee", "ffff8000" }
_G.ITEM_QUALITY_COLORS = {}
for quality, hex in pairs(HEX) do
    _G.ITEM_QUALITY_COLORS[quality] = {
        r = tonumber(hex:sub(3, 4), 16) / 255, g = tonumber(hex:sub(5, 6), 16) / 255,
        b = tonumber(hex:sub(7, 8), 16) / 255,
    }
end

local KNOWN = { [117] = { "Tough Jerky", 1 }, [8952] = { "Roasted Quail", 1 }, [300] = { "Green Snack", 2 } }
local asked = {}
_G.C_Item = _G.C_Item or {}
C_Item.GetItemInfo = function(id)
    local known = KNOWN[tonumber(id)]
    if not known then return nil end
    return known[1], nil, known[2], 5
end
C_Item.RequestLoadItemDataByID = function(id) asked[#asked + 1] = id end

for quality, hex in pairs(HEX) do
    suite.check("quality " .. quality .. " from the bag slot",
        Food.ShownName({ itemID = 9000 + quality, name = "Food", quality = quality }) == "|c" .. hex .. "Food|r")
end
suite.check("white food is white", Food.ShownName({ itemID = 117, name = "Tough Jerky" })
    == "|cffffffffTough Jerky|r")
suite.check("quality from the item cache", Food.ShownName({ itemID = 300, name = "Green Snack" })
    == "|cff1eff00Green Snack|r")
suite.check("already coloured text is left alone",
    Food.ShownName({ itemID = 300, name = "|cffff0000Green Snack|r" }) == "|cffff0000Green Snack|r")

Food.waitingForQuality = nil
suite.check("food not sent yet stays plain", Food.ShownName({ itemID = 777, name = "Mystery Meat" }) == "Mystery Meat")
local wasAsked = false
for _, id in ipairs(asked) do if id == 777 then wasAsked = true end end
suite.check("and is asked for", wasAsked)
suite.check("and the window waits for it", Food.waitingForQuality == true)

local macro = Food:FeedMacro({ itemID = 117, name = "Tough Jerky", bag = 0, slot = 3, quality = 1 })
suite.check("the Feed macro has no colour", macro and not macro:find("|c", 1, true), macro)
suite.check("the Feed macro uses bag and slot", macro and macro:find("/use 0 3", 1, true) ~= nil, macro)

suite.done()
