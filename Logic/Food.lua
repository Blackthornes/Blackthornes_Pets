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
    -- The item link carries the name in brackets, for a client whose slot
    -- info has no itemName.
    local link = Plain(info.hyperlink)
    if type(name) ~= "string" and type(link) == "string" then
        name = link:match("|h%[(.-)%]|h") or link:match("%[(.-)%]")
    end
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
    -- Before the client has the item, the link reads "[]": no name yet.
    if type(name) ~= "string" or name == "" then name = nil end
    if type(level) ~= "number" then level = nil end
    return name, level
end

--- Ask the client to load an item it has not sent yet; GET_ITEM_INFO_RECEIVED
--- follows, and the bags are read again.
local function RequestItem(id)
    local fn = C_Item and C_Item.RequestLoadItemDataByID
    if type(fn) == "function" and id then pcall(fn, id) end
end

--- One bag slot: the stack as Scan lists it if the pet will eat it, or nil
--- and why not, which /bpet food prints.
function Food:Inspect(bag, slot, info, status, eats)
    local name, level = NameAndLevel(info)
    if not name then return nil, "no name from the client", name, level end
    local diet = ns.PetFood.byName[name]
    if not diet then return nil, "not in the food list", name, level end
    if not eats[diet] then return nil, ("%s, which it does not eat"):format(diet), name, level end
    local effect = self:Effect(level, status.level)
    if effect == "refused" then return nil, "too low level", name, level end
    return {
        bag = bag, slot = slot, itemID = Plain(info.itemID),
        name = name, level = level, diet = diet, effect = effect,
        count = tonumber(Plain(info.stackCount)) or 1,
    }, nil, name, level
end

--- Every stack in the bags the pet will eat, as { bag, slot, itemID, name,
--- count, level, diet, effect }, best first: food that feeds fully before
--- food that does less, and among those the lowest level first, so the
--- better food is kept for later. `stacks.incomplete` is true when the
--- client has not yet told the addon what is in the bags (just after login,
--- when the bags read empty and items come back without names).
function Food:Scan(status)
    status = status or ns.PetStatus:Read()
    local stacks = {}
    if not (status.exists and status.foods) then return stacks end

    local eats = {}
    for _, diet in ipairs(status.foods) do eats[diet] = true end

    local slots = 0
    for bag = FIRST_BAG, LAST_BAG do
        local count = NumSlots(bag)
        slots = slots + count
        for slot = 1, count do
            local info = SlotItem(bag, slot)
            if info then
                local stack, why = self:Inspect(bag, slot, info, status, eats)
                if stack then
                    stacks[#stacks + 1] = stack
                elseif why == "no name from the client" then
                    stacks.incomplete = true
                    RequestItem(Plain(info.itemID))
                end
            end
        end
    end
    if slots == 0 then stacks.incomplete = true end

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
    -- Just after login the bags can read empty before the client has sent
    -- them; that is not a lack of food.
    if self.bagsReady == false or stacks.incomplete then return false end

    -- Another pet may eat other food, so it gets its own warning.
    if self.warnedPet ~= status.name then self.warnedLow = nil end
    self.warnedPet = status.name

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
-- /bpet food: what the helper sees in each bag slot, and why it did or did not
-- count it. Reads only.
--------------------------------------------------------------------------------

function Food:Report()
    local status = ns.PetStatus:Read()
    if not status.exists then
        ns.Print("food: no pet out.")
        return
    end
    if not status.foods then
        ns.Print("food: the client did not say what your pet eats.")
        return
    end

    local eats = {}
    for _, diet in ipairs(status.foods) do eats[diet] = true end
    ns.Print(("food: %s (level %s) eats %s"):format(status.name or "your pet",
        tostring(status.level or "?"), table.concat(status.foods, ", ")))

    local slots, items, found = 0, 0, 0
    local unlisted, seen = {}, {}
    for bag = FIRST_BAG, LAST_BAG do
        local count = NumSlots(bag)
        slots = slots + count
        for slot = 1, count do
            local info = SlotItem(bag, slot)
            if info then
                items = items + 1
                local stack, why, name, level = self:Inspect(bag, slot, info, status, eats)
                local label = ("%s%s"):format(name or ("item " .. tostring(Plain(info.itemID) or "?")),
                    level and (" (level " .. level .. ")") or "")
                if stack then
                    found = found + stack.count
                    ns.PrintRaw(("  |c%s%s|r  %s x%d, %s"):format(ns.COLORS.good, label,
                        stack.diet, stack.count, self:EffectLabel(stack.effect)))
                elseif why == "not in the food list" then
                    if not seen[name] then
                        seen[name] = true
                        unlisted[#unlisted + 1] = name
                    end
                else
                    ns.PrintRaw(("  |c%s%s|r  %s"):format(ns.COLORS.muted, label, why))
                end
            end
        end
    end

    -- On one line, since most of a bag is not food: if a food is missing from
    -- Data/PetFood.lua, this is where it shows up.
    if #unlisted > 0 then
        table.sort(unlisted)
        ns.PrintRaw(("  |c%snot in the food list:|r %s"):format(ns.COLORS.muted, table.concat(unlisted, ", ")))
    end

    if slots == 0 then
        ns.Print("food: could not read your bags on this client.")
    else
        ns.Print(("food: %d items in %d slots, %d pieces your pet will eat."):format(
            items, slots, found))
    end
    if ns.UI and ns.UI.FeedButtonState then
        ns.Print("food: " .. ns.UI:FeedButtonState() .. ".")
    end
    if ns.FeedKey then
        ns.Print("food: " .. ns.FeedKey:State())
    end
end

ns.RegisterCommand("food", "list the food in your bags and whether your pet will eat it (reads only)", function()
    Food:Report()
end)

--------------------------------------------------------------------------------
-- Keeping up with the bags
--------------------------------------------------------------------------------

function Food:Update()
    local status = ns.PetStatus:Read()
    local stacks = self:Scan(status)
    self:CheckLow(status, stacks)
    self:RetryIncomplete(stacks)
    if ns.FeedButton then ns.FeedButton:Update(status, stacks) end
    if ns.FeedKey then ns.FeedKey:Update(status, stacks) end
    if ns.UI and ns.UI.Refresh then
        pcall(ns.UI.Refresh, ns.UI)
    end
end

-- How long after the loading screen before the bags are trusted. The first
-- bag update at login can come before the client has sent the items, so it
-- is not enough on its own.
local BAGS_SETTLE = 10

-- While items still have no name, read the bags again this often, at most
-- this many times, in case the client never says it has loaded them.
local RETRY_EVERY, RETRIES = 2, 15

--- No low food warning until BAGS_SETTLE seconds after the loading screen.
--- A later loading screen starts the wait again, and only the newest wait
--- counts.
function Food:Settle()
    if not (C_Timer and C_Timer.After) then
        self.bagsReady = true
        return
    end
    self.bagsReady = false
    self.settleToken = (self.settleToken or 0) + 1
    local token = self.settleToken
    C_Timer.After(BAGS_SETTLE, function()
        if Food.settleToken ~= token then return end
        Food.bagsReady = true
        Food:Update()
    end)
end

--- Read the bags again shortly when a scan found items with no name yet.
function Food:RetryIncomplete(stacks)
    if not stacks.incomplete then
        self.retries = 0
        return
    end
    if self.retryPending or (self.retries or 0) >= RETRIES then return end
    if not (C_Timer and C_Timer.After) then return end
    self.retries = (self.retries or 0) + 1
    self.retryPending = true
    C_Timer.After(RETRY_EVERY, function()
        Food.retryPending = nil
        Food:Update()
    end)
end

function Food:OnEnable()
    self:Settle()

    local function OnBags() Food:Update() end
    ns.RegisterEvent(self, "BAG_UPDATE_DELAYED", OnBags)
    -- Leaving combat: the Feed button can only be pointed at new food then.
    ns.RegisterEvent(self, "PLAYER_REGEN_ENABLED", OnBags)
    -- Logging in or a /reload: wait for the bags again.
    ns.RegisterEvent(self, "PLAYER_ENTERING_WORLD", function(_, _, isLogin, isReload)
        if isLogin or isReload then Food:Settle() end
    end)
    -- An item the bags held without a name has arrived.
    ns.RegisterEvent(self, "GET_ITEM_INFO_RECEIVED", function()
        if Food.retryPending or not (C_Timer and C_Timer.After) then return end
        Food.retryPending = true
        C_Timer.After(0.5, function()
            Food.retryPending = nil
            Food:Update()
        end)
    end)
end
