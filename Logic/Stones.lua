-- Blackthornes Pets -- Logic/Stones.lua
-- A warlock's Healthstone and Soulstone (the owner said yes, 2026-10-24):
-- once a fight ends, a note when the bags hold no Healthstone, or when the
-- Soulstone is on nobody. Each says so once, and again only after it was
-- put right. Only for a stone the warlock can make. Off unless ticked
-- (stoneReminder, account wide, never rename it). Everything is read inside
-- a pcall; nothing is saved.

local _, ns = ...
local L = ns.L

local Stones = ns.NewModule("Stones")

-- Classic's Healthstones, every rank with and without the talent.
Stones.HEALTHSTONES = {
    5512, 19004, 19005, 5511, 19006, 19007, 5509, 19008, 19009,
    5510, 19010, 19011, 9421, 19012, 19013,
}
-- Create Healthstone, every rank.
Stones.HEALTH_SPELLS = { 6201, 6202, 5699, 11729, 11730 }
-- Create Soulstone, every rank.
Stones.SOUL_SPELLS = { 693, 20752, 20755, 20756, 20757 }
-- Soulstone Resurrection, the buff, every rank.
Stones.SOUL_BUFFS = {
    [20707] = true, [20762] = true, [20763] = true, [20764] = true, [20765] = true,
}
-- How long after a fight ends before looking, so the bags and buffs settle.
Stones.AFTER = 2
-- Buffs read on one unit at most.
Stones.MOST_AURAS = 40

local function Plain(value) return ns.PetStatus.Plain(value) end

--- Is it turned on?
function Stones:IsOn()
    return ns.db ~= nil and ns.db.stoneReminder == true
end

--- Does the warlock know one of these spells?
function Stones.Knows(spells)
    local fns = { _G.IsPlayerSpell, _G.IsSpellKnown }
    for _, fn in ipairs(fns) do
        if type(fn) == "function" then
            for _, id in ipairs(spells) do
                local ok, known = pcall(fn, id)
                if ok and Plain(known) == true then return true end
            end
        end
    end
    return false
end

--- Is there a Healthstone in the bags? nil when the client won't say.
function Stones:HasHealthstone()
    local fn = (C_Item and C_Item.GetItemCount) or _G.GetItemCount
    if type(fn) ~= "function" then return nil end
    local read = false
    for _, id in ipairs(self.HEALTHSTONES) do
        local ok, count = pcall(fn, id)
        count = ok and Plain(count) or nil
        if type(count) == "number" then
            read = true
            if count > 0 then return true end
        end
    end
    if read then return false end
    return nil
end

-- One buff on a unit, as a plain table, or nil.
local function AuraAt(unit, index)
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, "HELPFUL")
        if not ok or type(aura) ~= "table" then return nil end
        local okId, id = pcall(function() return Plain(aura.spellId) end)
        local okFrom, from = pcall(function() return Plain(aura.sourceUnit) end)
        return { spellId = okId and id or nil, source = okFrom and from or nil }
    end
    if type(_G.UnitBuff) == "function" then
        local ok, name, _, _, _, _, _, source, _, _, id = pcall(_G.UnitBuff, unit, index)
        if not ok or Plain(name) == nil then return nil end
        return { spellId = Plain(id), source = Plain(source) }
    end
    return nil
end

-- Does this unit carry the warlock's own Soulstone?
function Stones:HasSoulstone(unit)
    for index = 1, self.MOST_AURAS do
        local aura = AuraAt(unit, index)
        if not aura then return false end
        if self.SOUL_BUFFS[aura.spellId] and (aura.source == nil or aura.source == "player") then
            return true
        end
    end
    return false
end

-- The units to look at: the warlock and the group.
function Stones.Units()
    local units = { "player" }
    local inRaid = type(IsInRaid) == "function" and select(2, pcall(IsInRaid)) == true
    local okCount, count = pcall(GetNumGroupMembers or function() return 0 end)
    count = okCount and Plain(count) or 0
    if type(count) ~= "number" then count = 0 end
    if inRaid then
        for i = 1, count do units[#units + 1] = "raid" .. i end
    else
        for i = 1, count - 1 do units[#units + 1] = "party" .. i end
    end
    return units
end

--- Is the Soulstone on anyone?
function Stones:SoulstoneOnSomeone()
    for _, unit in ipairs(self.Units()) do
        if self:HasSoulstone(unit) then return true end
    end
    return false
end

-- Say it on screen and in chat.
local function Tell(message)
    ns.Warn(message)
    ns.PetStatus:Alert(message)
end

--- Look now. Returns how many notes it gave.
function Stones:Check()
    if not (self:IsOn() and ns.SoulShards.IsWarlock()) then return 0 end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, "player")
        if ok and Plain(dead) == true then return 0 end
    end
    local told = 0
    if self.Knows(self.HEALTH_SPELLS) then
        local has = self:HasHealthstone()
        if has == true then
            self.healthTold = nil
        elseif has == false and not self.healthTold then
            self.healthTold = true
            Tell(L["You have no Healthstone."])
            told = told + 1
        end
    end
    if self.Knows(self.SOUL_SPELLS) then
        if self:SoulstoneOnSomeone() then
            self.soulTold = nil
        elseif not self.soulTold then
            self.soulTold = true
            Tell(L["Your Soulstone isn't on anyone."])
            told = told + 1
        end
    end
    return told
end

--- A fight ended: look a moment later.
function Stones:FightOver()
    if not self:IsOn() then return end
    if not (C_Timer and C_Timer.After) then
        self:Check()
        return
    end
    self.token = (self.token or 0) + 1
    local token = self.token
    C_Timer.After(self.AFTER, function()
        if Stones.token ~= token then return end
        if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
        Stones:Check()
    end)
end

--- Turn it on or off, from Settings or /bpet stones.
function Stones:Set(on)
    ns.db.stoneReminder = on and true or false
    self.healthTold, self.soulTold = nil, nil
end

function Stones:OnEnable()
    ns.RegisterEvent(self, "PLAYER_REGEN_ENABLED", function() Stones:FightOver() end)
end

ns.RegisterCommand("stones", L["remind you after a fight when your Healthstone or Soulstone is missing (on, off)"], function(rest)
    local word = (rest or ""):lower():match("^%s*(%S*)")
    local on
    if word == "on" then
        on = true
    elseif word == "off" then
        on = false
    else
        on = not Stones:IsOn()
    end
    Stones:Set(on)
    ns.Print(on and L["Stone reminder: on."] or L["Stone reminder: off."])
end)
