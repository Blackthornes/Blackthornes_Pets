-- Blackthornes Pets -- Logic/Butler.lua
-- The one call Blackthornes Butler makes here, to tell the player what to
-- do with a bag item: keep it for the pet, or not.
--
--   _G.BlackthornesPets.Butler:Advise(itemID)
--
-- Reads only and never raises. Butler asks once per bag item when it judges
-- the bags, so a burst of a hundred calls in one frame reads the pet and the
-- bags once: the answers are kept until the bags change (Food:BagsChanged)
-- or the clock moves on, and the bags themselves come from Food:Latest,
-- which keeps its own scan between bag events. Butler's Logic/Sisters.lua
-- makes the call; if it changes, change that file too.

local _, ns = ...

local Butler = ns.NewModule("Butler")

-- How happy a food makes the pet, by how much good it does, and how fast
-- the pet grows unhappy: the classic rule, which the Forever client's Feed
-- Pet still carries. A food gives 35,000 points a tick for food within 10
-- levels (17,000 and 8,000 below that), and Feed Pet Effect ticks every 2
-- seconds for 20 seconds, so ten ticks a food. 670 points are lost every
-- 7.5 seconds, and a full bar is 1,050,000. A fighting pet grows hungry
-- faster, so `hours` is only "about".
local TICKS_PER_FOOD = 10
local HAPPINESS_PER_FOOD = {
    full = 35000 * TICKS_PER_FOOD, half = 17000 * TICKS_PER_FOOD, low = 8000 * TICKS_PER_FOOD,
}
local HAPPINESS_PER_SECOND = 670 / 7.5

-- A kept reading lasts at most this long with no bag event, so a pet
-- dismissed, levelled or swapped is read again on Butler's next burst.
local KEEP = 1

local Plain = function(value) return ns.PetStatus.Plain(value) end

local function Now()
    local ok, now = pcall(GetTime)
    return ok and tonumber(now) or nil
end

--- About how many hours the stacks feed the pet, to a tenth: 0 with none,
--- nil when the bags are not all read yet.
function Butler.Hours(stacks)
    if stacks.incomplete then return nil end
    local seconds = 0
    for _, stack in ipairs(stacks) do
        seconds = seconds + (stack.count or 0) * (HAPPINESS_PER_FOOD[stack.effect] or 0) / HAPPINESS_PER_SECOND
    end
    return math.floor(seconds / 360 + 0.5) / 10
end

--- The pet and its food, read once: nil when there is no hunter pet that
--- eats. Kept while the bags are unchanged and the clock has not moved on.
function Butler:Reading()
    local now, bags = Now(), ns.Food.bagsSeen or 0
    local kept = self.kept
    if kept and now and kept.at and kept.bags == bags and now >= kept.at and now - kept.at < KEEP then
        return kept.reading
    end

    local reading
    local status = ns.PetStatus:Read()
    if status.exists and status.foods and (status.class == nil or status.class == "HUNTER") then
        local stacks = ns.Food:Latest(status)
        local eats, carried = ns.PetFood.Eats(status.foods), {}
        for _, stack in ipairs(stacks) do
            if stack.itemID then
                carried[stack.itemID] = (carried[stack.itemID] or 0) + stack.count
            end
        end
        reading = {
            status = status, eats = eats, carried = carried,
            -- Counts are known only from a complete read of the bags.
            complete = not stacks.incomplete,
            hours = Butler.Hours(stacks),
            answers = {},
        }
    end
    self.kept = { at = now, bags = bags, reading = reading }
    return reading
end

local function NameAndLevel(itemID)
    local getInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if type(getInfo) ~= "function" then return nil end
    local ok, name, _, _, level = pcall(getInfo, itemID)
    if not ok then return nil end
    name, level = Plain(name), Plain(level)
    if type(name) ~= "string" or name == "" then return nil end
    return name, type(level) == "number" and level or nil
end

local function Answer(reading, itemID)
    local name, level = NameAndLevel(itemID)
    -- By ID first, so food is known on a client in any language.
    local diet = ns.PetFood.DietOf(itemID, name)
    if not diet then return false end
    local eats = reading.eats[diet] == true
        and ns.Food:Effect(level, reading.status.level) ~= "refused"
    local buff = ns.Food:IsBuffFood(itemID) == true
    -- Only food the pet is fed is counted. Food it eats that the scan did
    -- not find is none at all, unless it is buff food the player chose never
    -- to feed (the scan leaves that out) or the bags are not all read yet.
    local count = reading.carried[itemID]
    if count == nil and eats and reading.complete
        and not (buff and ns.db and ns.db.neverFeedBuffFood == true) then
        count = 0
    end
    return {
        eats = eats,
        buff = buff,
        hours = reading.hours,
        count = count,
    }
end

--- What Butler should know about an item for the character's pet: a table
--- { eats, buff, hours, count }, or nil when there is no hunter pet that
--- eats, or the item is not pet food. Never raises.
function Butler:Advise(itemID)
    local ok, advice = pcall(function()
        if type(itemID) ~= "number" then return nil end
        local reading = self:Reading()
        if not reading then return nil end
        local answer = reading.answers[itemID]
        if answer == nil then
            answer = Answer(reading, itemID)
            reading.answers[itemID] = answer
        end
        if not answer then return nil end
        -- A copy, so Butler cannot change what is kept.
        return { eats = answer.eats, buff = answer.buff, hours = answer.hours, count = answer.count }
    end)
    if ok then return advice end
    return nil
end
