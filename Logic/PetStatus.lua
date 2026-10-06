-- Blackthornes Pets -- Logic/PetStatus.lua
-- What the current pet is and how it is doing, read from the client, and the
-- warning when a hunter's pet needs feeding.
--
-- Built on what /bpet probe found (docs/FOREVER_API_FINDINGS.md): Forever
-- keeps the classic hunter mechanics under C_PetInfo, in their classic
-- shapes, except that the food types come back as a list. The pet's current
-- health and focus are secret values, so nothing here reads them.

local _, ns = ...

local PetStatus = ns.NewModule("PetStatus")

-- How often the feed warning looks at happiness, in seconds, in case the
-- client has no happiness event (it is registered too, where it exists).
local CHECK_EVERY = 15

-- C_PetInfo.GetPetHappiness's first value.
local HAPPINESS = {
    [1] = { name = "Unhappy", color = "bad" },
    [2] = { name = "Content", color = "warn" },
    [3] = { name = "Happy", color = "good" },
}

PetStatus.HAPPINESS = HAPPINESS

--------------------------------------------------------------------------------
-- Reading the client
--------------------------------------------------------------------------------

--- The value itself if it is plain, or nil if the client made it secret.
--- A secret raises when compared or passed to table.concat, and even "..",
--- which the client allows, hands back another secret, so ask the client
--- where it can say and otherwise try table.concat.
local function Plain(value)
    if value == nil then return nil end
    local isSecret = _G.issecretvalue
    if type(isSecret) == "function" then
        local ok, secret = pcall(isSecret, value)
        if not ok or secret then return nil end
        return value
    end
    local ok = pcall(table.concat, { tostring(value) })
    if not ok then return nil end
    return value
end

PetStatus.Plain = Plain

local function Resolve(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return nil end
        value = value[part]
    end
    if type(value) == "function" then return value end
    return nil
end

--- Call a global or a dotted C_ function inside a pcall. Returns its values
--- with any secret ones turned to nil, or nothing if it is absent or raises.
local function Call(path, ...)
    local fn = Resolve(path)
    if not fn then return end
    local results = { pcall(fn, ...) }
    if not results[1] then return end
    local out = {}
    for i = 2, table.maxn(results) do out[i - 1] = Plain(results[i]) end
    return unpack(out, 1, table.maxn(results) - 1)
end

local function Number(value)
    if type(value) == "number" then return value end
    return nil
end

local function Text(value)
    if type(value) == "string" and value ~= "" then return value end
    return nil
end

--- Everything the addon knows about the current pet, as a plain table.
--- `exists` is false when there is no pet out; every other field may be nil
--- when the client does not say.
function PetStatus:Read()
    local status = {}

    local _, class = Call("UnitClass", "player")
    status.class = Text(class)

    status.exists = Call("UnitExists", "pet") == true
    if not status.exists then return status end

    status.name = Text(Call("UnitName", "pet"))
    status.family = Text(Call("UnitCreatureFamily", "pet"))
    status.level = Number(Call("UnitLevel", "pet"))
    status.healthMax = Number(Call("UnitHealthMax", "pet"))

    local xp, xpMax = Call("GetPetExperience")
    status.xp, status.xpMax = Number(xp), Number(xpMax)

    -- Only hunters' pets have these. A demon may get nils or nothing.
    local happiness, damage, loyaltyRate = Call("C_PetInfo.GetPetHappiness")
    happiness = Number(happiness)
    if happiness and HAPPINESS[happiness] then
        status.happiness = happiness
        status.damagePercent = Number(damage)
        status.loyaltyRate = Number(loyaltyRate)
    end

    status.loyalty = Text(Call("C_PetInfo.GetPetLoyalty"))

    local foods = Call("C_PetInfo.GetPetFoodTypes")
    if type(foods) == "table" then
        local list = {}
        for _, food in ipairs(foods) do
            local name = Text(Plain(food))
            if name then list[#list + 1] = name end
        end
        if #list > 0 then status.foods = list end
    end

    local total, spent = Call("C_PetInfo.GetPetTrainingPoints")
    total, spent = Number(total), Number(spent)
    if total and spent then
        status.trainingTotal, status.trainingSpent = total, spent
        status.trainingFree = total - spent
    end

    return status
end

--------------------------------------------------------------------------------
-- Describing it
--------------------------------------------------------------------------------

local function Colored(colorKey, text)
    return ("|c%s%s|r"):format(ns.COLORS[colorKey] or ns.COLORS.text, text)
end

--- "Unhappy (75% damage)" in its colour, or nil if happiness is unknown.
function PetStatus:HappinessText(status)
    local info = status and status.happiness and HAPPINESS[status.happiness]
    if not info then return nil end
    local text = info.name
    if status.damagePercent then
        text = ("%s (%d%% damage)"):format(text, status.damagePercent)
    end
    return Colored(info.color, text)
end

--- "Rebellious, falling" or nil if loyalty is unknown.
function PetStatus:LoyaltyText(status)
    if not (status and status.loyalty) then return nil end
    local rate = status.loyaltyRate
    if rate and rate < 0 then
        return status.loyalty .. ", " .. Colored("bad", "falling")
    elseif rate and rate > 0 then
        return status.loyalty .. ", " .. Colored("good", "rising")
    end
    return status.loyalty
end

--- "92 / 1350 (7%)" or nil.
function PetStatus:ExperienceText(status)
    if not (status and status.xp and status.xpMax and status.xpMax > 0) then return nil end
    return ("%d / %d (%d%%)"):format(status.xp, status.xpMax,
        math.floor(status.xp / status.xpMax * 100))
end

--- "-5 free (0 total, 5 spent)" or nil. Newly tamed pets often start below
--- zero: the abilities they come with cost points before loyalty earns any.
function PetStatus:TrainingText(status)
    if not (status and status.trainingFree) then return nil end
    local free = status.trainingFree
    local freeText = Colored(free < 0 and "bad" or "text", tostring(free))
    return ("%s free (%d total, %d spent)"):format(freeText,
        status.trainingTotal, status.trainingSpent)
end

--- "Meat, Fish, Bread" or nil.
function PetStatus:FoodText(status)
    if not (status and status.foods) then return nil end
    return table.concat(status.foods, ", ")
end

--------------------------------------------------------------------------------
-- The feed warning
--------------------------------------------------------------------------------

--- The happiness level below which the pet needs feeding: below Happy by
--- default, or below Content when the player only wants to hear about an
--- unhappy pet.
function PetStatus:WarnBelow()
    if ns.db and ns.db.feedWarnOnlyUnhappy then return 2 end
    return 3
end

--- Put a message where it cannot be missed: the big raid-warning text in the
--- middle of the screen, with its sound. The first run of the feed warning
--- used the red error line near the top, which fades too fast to notice.
--- Falls back on that line if this client has no raid warning frame.
function PetStatus:Alert(message)
    local frame = _G.RaidWarningFrame
    local add = _G.RaidNotice_AddMessage
    local shown = false
    if type(frame) == "table" and type(add) == "function" then
        local color = type(ChatTypeInfo) == "table" and ChatTypeInfo.RAID_WARNING
            or { r = 1, g = 0.82, b = 0.35 }
        shown = pcall(add, frame, message, color)
    end
    if not shown then
        local errors = _G.UIErrorsFrame
        if type(errors) == "table" and type(errors.AddMessage) == "function" then
            shown = pcall(errors.AddMessage, errors, message, 1, 0.82, 0.35)
        end
    end
    if type(PlaySound) == "function" and type(SOUNDKIT) == "table" and SOUNDKIT.RAID_WARNING then
        pcall(PlaySound, SOUNDKIT.RAID_WARNING)
    end
    return shown
end

--- Look at the pet and warn once when it has dropped below the line. It does
--- not repeat while the pet stays there, and warns again only after the pet
--- has been fed back above it, or has dropped a further level.
function PetStatus:CheckFeed(status)
    if not (ns.db and ns.db.feedWarning) then return false end
    status = status or self:Read()
    local level = status.exists and status.happiness
    if not level then return false end

    -- Another pet called out starts afresh: a warning about the last one
    -- says nothing about this one.
    if self.warnedPet ~= status.name then self.warnedAt = nil end
    self.warnedPet = status.name

    if level >= self:WarnBelow() then
        self.warnedAt = nil
        return false
    end
    if self.warnedAt and self.warnedAt <= level then return false end

    self.warnedAt = level
    local name = status.name or "Your pet"
    local message = ("%s is %s. Feed it."):format(name, HAPPINESS[level].name:lower())
    ns.Warn(message)
    PetStatus:Alert(message)
    return true
end

--------------------------------------------------------------------------------
-- Keeping up with the pet
--------------------------------------------------------------------------------

function PetStatus:Update()
    local status = self:Read()
    self:CheckFeed(status)
    if ns.Food then
        local stacks = ns.Food:Scan(status)
        ns.Food:CheckLow(status, stacks)
        if ns.FeedButton then ns.FeedButton:Update(status, stacks) end
        if ns.FeedKey then ns.FeedKey:Update(status, stacks) end
    end
    if ns.UI and ns.UI.Refresh then
        pcall(ns.UI.Refresh, ns.UI)
    end
end

local function OnPetEvent(self, _, unit)
    if unit and unit ~= "pet" and unit ~= "player" then return end
    self:Update()
end

function PetStatus:OnEnable()
    -- Any of these may be unknown to Forever; ns.RegisterEvent shrugs that off.
    for _, event in ipairs({
        "UNIT_PET", "UNIT_HAPPINESS", "PET_UI_UPDATE", "UNIT_PET_EXPERIENCE",
        "UNIT_LEVEL", "PLAYER_REGEN_DISABLED",
    }) do
        ns.RegisterEvent(self, event, OnPetEvent)
    end

    if C_Timer and C_Timer.NewTicker then
        self.ticker = C_Timer.NewTicker(CHECK_EVERY, function() PetStatus:Update() end)
    end
end
