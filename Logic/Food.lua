-- Blackthornes Pets -- Logic/Food.lua
-- The food in the bags that the pet will eat, which one to feed it, and the
-- warning when that food runs low.
--
-- What the pet eats comes from C_PetInfo.GetPetFoodTypes (read by
-- PetStatus); what diet an item is comes from Data/PetFood.lua; the item's
-- level, and so how much good it does, comes from the client.

local _, ns = ...

local Food = ns.NewModule("Food")

-- The bags a character carries: the backpack and four bags.
local FIRST_BAG, LAST_BAG = 0, 4

-- Below this many pieces of food the pet will eat, warn.
local LOW_FOOD = 10

Food.LOW_FOOD = LOW_FOOD

-- How much a food does for the pet, by how many levels it is below the pet.
-- The classic rule: within 10 levels it does its full good, then half, then
-- little, and from 30 levels below the pet will not eat it at all.
local EFFECTS = {
    { below = 10, key = "full", label = "full" },
    { below = 20, key = "half", label = "half" },
    { below = 30, key = "low", label = "little" },
}

--- How well food of `itemLevel` feeds a pet of `petLevel`: "full", "half",
--- "low", or "refused". Unknown levels count as full; the client would say.
function Food:Effect(itemLevel, petLevel)
    if type(itemLevel) ~= "number" or type(petLevel) ~= "number" then return "full" end
    local gap = petLevel - itemLevel
    for _, effect in ipairs(EFFECTS) do
        if gap < effect.below then return effect.key end
    end
    return "refused"
end

function Food:EffectLabel(key)
    for _, effect in ipairs(EFFECTS) do
        if effect.key == key then return effect.label end
    end
    return "refused"
end

--------------------------------------------------------------------------------
-- Reading the bags
--------------------------------------------------------------------------------

local Plain = function(value) return ns.PetStatus.Plain(value) end

local function NumSlots(bag)
    local fn = C_Container and C_Container.GetContainerNumSlots
    if type(fn) ~= "function" then return 0 end
    local ok, slots = pcall(fn, bag)
    slots = ok and Plain(slots)
    return type(slots) == "number" and slots or 0
end

local function SlotItem(bag, slot)
    local fn = C_Container and C_Container.GetContainerItemInfo
    if type(fn) ~= "function" then return nil end
    local ok, info = pcall(fn, bag, slot)
    if not ok or type(info) ~= "table" then return nil end
    return info
end

--- The item's name and level, from the slot's info or the item cache.
local function NameAndLevel(info)
    local name = Plain(info.itemName)
    local level
    local getInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    local id = Plain(info.itemID)
    if type(getInfo) == "function" and id then
        local ok, itemName, _, _, itemLevel = pcall(getInfo, id)
        if ok then
            name = name or Plain(itemName)
            level = Plain(itemLevel)
        end
    end
    if type(name) ~= "string" then name = nil end
    if type(level) ~= "number" then level = nil end
    return name, level
end

--- Every stack in the bags the pet will eat, as { bag, slot, itemID, name,
--- count, level, diet, effect }, best first: food that feeds fully before
--- food that does less, and among those the lowest level first, so the
--- better food is kept for later.
function Food:Scan(status)
    status = status or ns.PetStatus:Read()
    local stacks = {}
    if not (status.exists and status.foods) then return stacks end

    local eats = {}
    for _, diet in ipairs(status.foods) do eats[diet] = true end

    for bag = FIRST_BAG, LAST_BAG do
        for slot = 1, NumSlots(bag) do
            local info = SlotItem(bag, slot)
            if info then
                local name, level = NameAndLevel(info)
                local diet = name and ns.PetFood.byName[name]
                if diet and eats[diet] then
                    local effect = self:Effect(level, status.level)
                    if effect ~= "refused" then
                        stacks[#stacks + 1] = {
                            bag = bag, slot = slot, itemID = Plain(info.itemID),
                            name = name, level = level, diet = diet, effect = effect,
                            count = tonumber(Plain(info.stackCount)) or 1,
                        }
                    end
                end
            end
        end
    end

    local rank = { full = 1, half = 2, low = 3 }
    table.sort(stacks, function(a, b)
        if rank[a.effect] ~= rank[b.effect] then return rank[a.effect] < rank[b.effect] end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    return stacks
end

--- How many pieces of food the pet will eat, all stacks together.
function Food:Count(stacks)
    local total = 0
    for _, stack in ipairs(stacks) do total = total + stack.count end
    return total
end

--- "Tough Jerky (full), 34 in bags" or "None in your bags", for the window.
function Food:Summary(stacks)
    if #stacks == 0 then
        return ("|c%sNone in your bags|r"):format(ns.COLORS.bad)
    end
    local best = stacks[1]
    local total = self:Count(stacks)
    local text = ("%s (%s), %d in bags"):format(best.name, self:EffectLabel(best.effect), total)
    if total < LOW_FOOD then
        text = text .. (", |c%srunning low|r"):format(ns.COLORS.warn)
    end
    return text
end

--------------------------------------------------------------------------------
-- The low food warning
--------------------------------------------------------------------------------

--- Warn once when the food the pet will eat drops below LOW_FOOD, and again
--- only after the bags have been restocked above it.
function Food:CheckLow(status, stacks)
    if not (ns.db and ns.db.lowFoodWarning) then return false end
    if not (status and status.exists and status.foods) then return false end

    local total = self:Count(stacks)
    if total >= LOW_FOOD then
        self.warnedLow = nil
        return false
    end
    if self.warnedLow then return false end

    self.warnedLow = true
    local message
    if total == 0 then
        message = ("You have no food %s will eat."):format(status.name or "your pet")
    else
        message = ("Only %d food left that %s will eat."):format(total, status.name or "your pet")
    end
    ns.Warn(message)
    ns.PetStatus:Alert(message)
    return true
end

--------------------------------------------------------------------------------
-- Feeding
--------------------------------------------------------------------------------

-- Feed Pet's spell ID, for its name in the client's language.
local FEED_PET = 6991

--- Feed Pet's name as this client spells it.
function Food:FeedSpellName()
    local fn = C_Spell and C_Spell.GetSpellName
    if type(fn) == "function" then
        local ok, name = pcall(fn, FEED_PET)
        name = ok and Plain(name)
        if type(name) == "string" and name ~= "" then return name end
    end
    return "Feed Pet"
end

--- The macro the Feed button runs for a stack: cast Feed Pet, then use the
--- food, which is how the classic client takes the food Feed Pet asks for.
function Food:FeedMacro(stack)
    if not stack then return nil end
    return ("/cast %s\n/use %d %d"):format(self:FeedSpellName(), stack.bag, stack.slot)
end

--------------------------------------------------------------------------------
-- Keeping up with the bags
--------------------------------------------------------------------------------

function Food:Update()
    local status = ns.PetStatus:Read()
    self:CheckLow(status, self:Scan(status))
    if ns.UI and ns.UI.Refresh then
        pcall(ns.UI.Refresh, ns.UI)
    end
end

function Food:OnEnable()
    local function OnBags() Food:Update() end
    ns.RegisterEvent(self, "BAG_UPDATE_DELAYED", OnBags)
    -- Leaving combat: the Feed button can only be pointed at new food then.
    ns.RegisterEvent(self, "PLAYER_REGEN_ENABLED", OnBags)
end
