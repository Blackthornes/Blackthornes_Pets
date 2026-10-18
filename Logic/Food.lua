-- Blackthornes Pets -- Logic/Food.lua
-- The food in the bags that the pet will eat, which one to feed it, and the
-- warning when that food runs low.
--
-- What the pet eats comes from C_PetInfo.GetPetFoodTypes (read by
-- PetStatus); what diet an item is comes from Data/PetFood.lua, by item ID;
-- the item's level, and so how much good it does, comes from the client.

local _, ns = ...
local L = ns.L

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
    { below = 10, key = "full", label = L["full"] },
    { below = 20, key = "half", label = L["half"] },
    { below = 30, key = "low", label = L["little"] },
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
    return L["refused"]
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

--------------------------------------------------------------------------------
-- Food names in their rarity colour
--
-- The owner (2026-10-18): an item's name always shows its rarity colour.
-- Only what is drawn is coloured; the Feed macro, saved data and anything
-- compared keep the plain name. The bag slot says the quality; else the
-- item cache does, kept per item once known; else the item is asked for
-- and the name keeps the line's colour until the bags are read again.
--------------------------------------------------------------------------------

local qualityOf = {}   -- [itemID] = quality, once known
local hexOf = {}       -- [quality] = "ffrrggbb"

local function QualityNumber(value)
    local ok, number = pcall(function()
        local n = tonumber(value)
        if n and n >= 0 and n <= 9 then return n end
    end)
    return ok and number or nil
end

--- The colour code of a quality ("ff1eff00" for green), or nil.
function Food.QualityHex(quality)
    if type(quality) ~= "number" then return nil end
    if hexOf[quality] then return hexOf[quality] end
    local hex
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = type(colors) == "table" and colors[quality] or nil
    local ok, made = pcall(function()
        if type(color) == "table" and type(color.r) == "number" then
            return ("ff%02x%02x%02x"):format(math.floor(color.r * 255 + 0.5),
                math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5))
        end
        local fn = (C_Item and C_Item.GetItemQualityColor) or rawget(_G, "GetItemQualityColor")
        if type(fn) ~= "function" then return nil end
        local r, g, b, h = fn(quality)
        if type(h) == "string" and h:match("^%x%x%x%x%x%x%x%x$") then return h:lower() end
        if type(r) == "number" then
            return ("ff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5),
                math.floor(b * 255 + 0.5))
        end
    end)
    if ok and made then hex = made end
    if hex then hexOf[quality] = hex end
    return hex
end

--- An item's quality, from the slot's own reading or the item cache.
function Food.QualityOf(itemID, given)
    local quality = QualityNumber(given)
    if quality then
        if type(itemID) == "number" then qualityOf[itemID] = quality end
        return quality
    end
    if type(itemID) ~= "number" then return nil end
    if qualityOf[itemID] then return qualityOf[itemID] end
    local getInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if type(getInfo) == "function" then
        local ok, _, _, raw = pcall(getInfo, itemID)
        quality = ok and QualityNumber(raw) or nil
    end
    if quality then qualityOf[itemID] = quality end
    return quality
end

--- A food's name to show: in its rarity colour once its quality is known.
--- `stack` is a stack as Scan lists it, or anything with itemID and name.
function Food.ShownName(stack)
    if type(stack) ~= "table" then return nil end
    local name = stack.name
    if type(name) ~= "string" or name == "" or name:find("|c", 1, true) then return name end
    local quality = Food.QualityOf(stack.itemID, stack.quality)
    local hex = Food.QualityHex(quality)
    if not hex then
        if not quality and type(stack.itemID) == "number" then
            Food.waitingForQuality = true
            RequestItem(stack.itemID)
        end
        return name
    end
    return "|c" .. hex .. name .. "|r"
end

--------------------------------------------------------------------------------
-- Buff food
--
-- Food that also gives a buff (stat food: "you will become well fed and
-- gain...") is worth more to the hunter than to the pet, so it is fed last,
-- only when nothing else the pet eats is in the bags, and never with "Never
-- feed buff food" (neverFeedBuffFood) ticked. Which food that is comes from
-- the client: the item's tooltip, or its use spell's description, read once
-- per item a session.
--------------------------------------------------------------------------------

-- Words in a food's "Use:" text that mean it gives more than health back.
-- The client hands out no flag for it, so this reads its text: English,
-- and the German client's words (classic's, not yet seen on Forever). A
-- client in another language reads every food as plain food, as before.
-- Patterns, matched on the lower-cased text.
local BUFF_WORDS = {
    "well fed", "increases your", "for the next",
    -- German: "... werdet Ihr satt", "Erhöht Eure ...", "für die nächsten"
    "%f[%a]satt%f[%A]", "erhöht eure", "erhöht euer", "für die nächsten",
}

local function GivesBuff(text)
    if type(text) ~= "string" then return false end
    text = text:lower()
    for _, words in ipairs(BUFF_WORDS) do
        if text:find(words) then return true end
    end
    return false
end

local function LineText(line)
    if type(line) ~= "table" then return nil end
    local text = Plain(line.leftText)
    if text == nil and type(line.args) == "table" then
        for _, arg in ipairs(line.args) do
            if type(arg) == "table" and arg.field == "leftText" then text = Plain(arg.stringVal) end
        end
    end
    return type(text) == "string" and text or nil
end

--- What the client says about the item's buff: true or false, or nil when
--- it has nothing to say yet (the tooltip not loaded). A client with neither
--- call has nothing to wait for: false.
local function ReadBuff(itemID)
    local answer
    local tooltip = C_TooltipInfo and C_TooltipInfo.GetItemByID
    if type(tooltip) == "function" then
        local ok, data = pcall(tooltip, itemID)
        if ok and type(data) == "table" and type(data.lines) == "table" and #data.lines > 1 then
            answer = false
            for _, line in ipairs(data.lines) do
                if GivesBuff(LineText(line)) then return true end
            end
        end
    end
    local itemSpell = (C_Item and C_Item.GetItemSpell) or _G.GetItemSpell
    local describe = C_Spell and C_Spell.GetSpellDescription
    if type(itemSpell) == "function" and type(describe) == "function" then
        local ok, _, spellID = pcall(itemSpell, itemID)
        spellID = ok and Plain(spellID)
        if type(spellID) == "number" then
            local okText, text = pcall(describe, spellID)
            text = okText and Plain(text)
            if type(text) == "string" and text ~= "" then
                if GivesBuff(text) then return true end
                answer = false
            end
        end
    end
    if answer == nil and type(tooltip) ~= "function"
        and not (type(itemSpell) == "function" and type(describe) == "function") then
        return false
    end
    return answer
end

--- True when the food gives a buff as well as feeding. Kept per item ID
--- once the client has answered, so a bag scan reads each food once. The
--- second value is true while the client has not answered yet: the food
--- counts as plain food until it does, and after BUFF_TRIES reads with no
--- answer it is taken as plain food for the session, so a client that never
--- answers does not keep the bags being read again.
local BUFF_TRIES = 5

function Food:IsBuffFood(itemID)
    if type(itemID) ~= "number" then return false end
    self.buffKnown = self.buffKnown or {}
    local known = self.buffKnown[itemID]
    if known ~= nil then return known end
    known = ReadBuff(itemID)
    if known == nil then
        self.buffTries = self.buffTries or {}
        local tries = (self.buffTries[itemID] or 0) + 1
        self.buffTries[itemID] = tries
        if tries < BUFF_TRIES then return false, true end
        known = false
    end
    self.buffKnown[itemID] = known
    return known
end

local function NeverBuffFood()
    return ns.db and ns.db.neverFeedBuffFood == true
end

--- One bag slot: the stack as Scan lists it if the pet will eat it, or nil
--- and why not, which /bpet food prints.
function Food:Inspect(bag, slot, info, status, eats)
    local name, level = NameAndLevel(info)
    if not name then return nil, "no name from the client", name, level end
    local itemID = Plain(info.itemID)
    local diet = ns.PetFood.DietOf(itemID, name)
    if not diet then return nil, "not in the food list", name, level end
    if not eats[diet] then
        return nil, L.Format("%s, which it doesn't eat", ns.PetFood.Label(diet)), name, level
    end
    local effect = self:Effect(level, status.level)
    if effect == "refused" then return nil, L["too low level"], name, level end
    local buff, unsure = self:IsBuffFood(itemID)
    if unsure then RequestItem(itemID) end
    if buff and NeverBuffFood() then return nil, L["buff food, which you've chosen not to feed"], name, level end
    return {
        bag = bag, slot = slot, itemID = itemID, buff = buff or nil, buffUnsure = unsure or nil,
        name = name, level = level, diet = diet, effect = effect,
        count = tonumber(Plain(info.stackCount)) or 1,
        quality = QualityNumber(Plain(info.quality)),
    }, nil, name, level
end

local RANK = { full = 1, half = 2, low = 3 }

local function BestFirst(a, b)
    -- Buff food goes last, whatever it would do for the pet.
    if (a.buff or false) ~= (b.buff or false) then return not a.buff end
    if RANK[a.effect] ~= RANK[b.effect] then return RANK[a.effect] < RANK[b.effect] end
    if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
end

--- Every stack in the bags the pet will eat, as { bag, slot, itemID, name,
--- count, level, diet, effect, buff }, best first: food that feeds fully
--- before food that does less, and among those the lowest level first, so
--- the better food is kept for later. Buff food comes after all the rest. `stacks.incomplete` is true when the
--- client has not yet told the addon what is in the bags (just after login,
--- when the bags read empty and items come back without names).
-- How long a scan is kept at most, even with no bag event, as a safety net.
local KEEP_SCAN = 60

local function Now()
    local ok, now = pcall(GetTime)
    return ok and tonumber(now) or nil
end

--- The bags changed (or may have): the next Scan reads them again.
function Food:BagsChanged()
    self.bagsSeen = (self.bagsSeen or 0) + 1
end

local function ScanKey(status)
    return ("%s|%s|%s|%s"):format(tostring(status.name), tostring(status.level),
        table.concat(status.foods, ","), tostring(NeverBuffFood()))
end

--- Scan's answer, kept from the last complete scan when nothing it reads can
--- have changed. The pet status is checked every few seconds and the pets
--- window reads it again, but the food in the bags only changes when the
--- bags do, so those reads take the kept scan: same pet, level and diet, no
--- bag event (or item name arriving) since, and under a minute old.
function Food:Latest(status)
    status = status or ns.PetStatus:Read()
    if not (status.exists and status.foods) then return {} end
    local kept, now = self.kept, Now()
    if kept and kept.key == ScanKey(status) and kept.bags == (self.bagsSeen or 0)
        and now and kept.at and now >= kept.at and now - kept.at < KEEP_SCAN then
        return kept.stacks
    end
    return self:Scan(status)
end

function Food:Scan(status)
    status = status or ns.PetStatus:Read()
    local stacks = {}
    self.kept = nil
    if not (status.exists and status.foods) then return stacks end
    local key = ScanKey(status)

    -- The client's diet words, in its own language, as Data/PetFood.lua's.
    local eats = ns.PetFood.Eats(status.foods)

    local slots, unsure = 0, false
    for bag = FIRST_BAG, LAST_BAG do
        local count = NumSlots(bag)
        slots = slots + count
        for slot = 1, count do
            local info = SlotItem(bag, slot)
            if info then
                local stack, why = self:Inspect(bag, slot, info, status, eats)
                if stack then
                    stacks[#stacks + 1] = stack
                    if stack.buffUnsure then unsure = true end
                elseif why == "no name from the client" then
                    stacks.incomplete = true
                    RequestItem(Plain(info.itemID))
                end
            end
        end
    end
    if slots == 0 then stacks.incomplete = true end

    table.sort(stacks, BestFirst)

    -- Only a complete read is kept; one still waiting on item names is read
    -- again on the next ask, as before. So is one with a food whose tooltip
    -- has not loaded yet: until it does, buff food could sort first (or be
    -- fed with "Never feed it" ticked) for the minute a kept scan lasts.
    self.waitingForNames = (stacks.incomplete or unsure) or nil
    if not (stacks.incomplete or unsure) then
        self.kept = { key = key, bags = self.bagsSeen or 0, at = Now(), stacks = stacks }
    end
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
        return ("|c%s%s|r"):format(ns.COLORS.bad, L["None in your bags"])
    end
    local best = stacks[1]
    local total = self:Count(stacks)
    local text = L.Format("%s (%s), %d in bags", Food.ShownName(best), self:EffectLabel(best.effect), total)
    if total < LOW_FOOD then
        text = text .. (", |c%s%s|r"):format(ns.COLORS.warn, L["running low"])
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
        message = L.Format("You have no food %s will eat.", status.name or L["your pet"])
    else
        message = L.Format("Only %d food left that %s will eat.", total, status.name or L["your pet"])
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
--- It stops first when Feed Pet cannot be cast (no pet, a dead one, a
--- fight): the /use alone would have the hunter sit down and eat the food.
function Food:FeedMacro(stack)
    if not stack then return nil end
    return ("/stopmacro [nopet][@pet,dead][combat]\n/cast %s\n/use %d %d"):format(
        self:FeedSpellName(), stack.bag, stack.slot)
end

--------------------------------------------------------------------------------
-- /bpet food: what the helper sees in each bag slot, and why it did or did not
-- count it. Reads only.
--------------------------------------------------------------------------------

function Food:Report()
    local status = ns.PetStatus:Read()
    if not status.exists then
        ns.Print(L["food: no pet out."])
        return
    end
    if not status.foods then
        ns.Print(L["food: the client did not say what your pet eats."])
        return
    end

    local eats = ns.PetFood.Eats(status.foods)
    ns.Print(L.Format("food: %s (level %s) eats %s", status.name or L["your pet"],
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
                -- The name in its rarity colour, the level in the line's.
                local shown = name and Food.ShownName({ itemID = Plain(info.itemID), name = name,
                    quality = Plain(info.quality) })
                    or L.Format("item %s", tostring(Plain(info.itemID) or "?"))
                local levelText = level and L.Format(" (level %s)", level) or ""
                local function Tail(color)
                    return levelText ~= "" and ("|c%s%s|r"):format(color, levelText) or ""
                end
                if stack then
                    found = found + stack.count
                    ns.PrintRaw(("  %s%s  %s x%d, %s%s"):format(shown, Tail(ns.COLORS.good),
                        ns.PetFood.Label(stack.diet), stack.count, self:EffectLabel(stack.effect),
                        stack.buff and L[", buff food (fed last)"] or ""))
                elseif why == "not in the food list" then
                    if not seen[name] then
                        seen[name] = true
                        unlisted[#unlisted + 1] = { name = name, shown = shown }
                    end
                else
                    if why == "no name from the client" then why = L["no name from the client"] end
                    ns.PrintRaw(("  %s%s  %s"):format(shown, Tail(ns.COLORS.muted), why))
                end
            end
        end
    end

    -- On one line, since most of a bag is not food: if a food is missing from
    -- Data/PetFood.lua, this is where it shows up.
    if #unlisted > 0 then
        table.sort(unlisted, function(a, b) return a.name < b.name end)
        local names = {}
        for index, entry in ipairs(unlisted) do names[index] = entry.shown end
        ns.PrintRaw(("  |c%s%s|r %s"):format(ns.COLORS.muted, L["not in the food list:"], table.concat(names, ", ")))
    end

    if slots == 0 then
        ns.Print(L["food: could not read your bags on this client."])
    else
        ns.Print(L.Format("food: %d items in %d slots, %d pieces your pet will eat.",
            items, slots, found))
    end
    if ns.UI and ns.UI.FeedButtonState then
        ns.Print(L.Format("food: %s.", ns.UI:FeedButtonState()))
    end
    if ns.FeedKey then
        ns.Print(L.Format("food: %s", ns.FeedKey:State()))
    end
end

ns.RegisterCommand("food", L["list the food in your bags and whether your pet will eat it"], function()
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

    ns.RegisterEvent(self, "BAG_UPDATE_DELAYED", function()
        Food:BagsChanged()
        Food:Update()
    end)
    -- Leaving combat: the Feed button can only be pointed at new food then.
    ns.RegisterEvent(self, "PLAYER_REGEN_ENABLED", function() Food:Update() end)
    -- Logging in or a /reload: wait for the bags again.
    ns.RegisterEvent(self, "PLAYER_ENTERING_WORLD", function(_, _, isLogin, isReload)
        Food:BagsChanged()
        if isLogin or isReload then Food:Settle() end
    end)
    -- An item the bags held without a name has arrived. Only listened to
    -- while the last scan was missing names: other addons ask the client for
    -- items all the time, and each answer used to read the bags again.
    ns.RegisterEvent(self, "GET_ITEM_INFO_RECEIVED", function()
        -- Also while a name was drawn plain for want of its quality.
        if not (Food.waitingForNames or Food.waitingForQuality) then return end
        Food.waitingForQuality = nil
        Food:BagsChanged()
        if Food.retryPending or not (C_Timer and C_Timer.After) then return end
        Food.retryPending = true
        C_Timer.After(0.5, function()
            Food.retryPending = nil
            Food:Update()
        end)
    end)
end
