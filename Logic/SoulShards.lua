-- Blackthornes Pets -- Logic/SoulShards.lua
-- A warlock's soul shards (the owner said yes, 2026-10-24): how many are in
-- the bags, shown as a chip on the Pet tab, and a warning once they drop to
-- LOW or fewer. Off unless ticked (soulShards, account wide, never rename
-- it). The count is the client's, read inside a pcall; nothing is saved.

local _, ns = ...
local L = ns.L

local SoulShards = ns.NewModule("SoulShards")

-- The Soul Shard item.
SoulShards.ITEM = 6265
-- At this many or fewer the chip turns red and the warning comes.
SoulShards.LOW = 2
-- How long after a loading screen before the bags are trusted, as the low
-- food warning waits (Food's BAGS_SETTLE).
SoulShards.SETTLE = 10

local function Plain(value) return ns.PetStatus.Plain(value) end

--- Is it turned on?
function SoulShards:IsOn()
    return ns.db ~= nil and ns.db.soulShards == true
end

--- Is the player a warlock?
function SoulShards.IsWarlock()
    if type(UnitClass) ~= "function" then return false end
    local ok, _, token = pcall(UnitClass, "player")
    return ok and Plain(token) == "WARLOCK"
end

--- How many soul shards are in the bags, or nil when the client won't say.
function SoulShards:Count()
    local fn = (C_Item and C_Item.GetItemCount) or _G.GetItemCount
    if type(fn) ~= "function" then return nil end
    local ok, count = pcall(fn, self.ITEM)
    count = ok and Plain(count) or nil
    if type(count) ~= "number" then return nil end
    return count
end

--- What the Pet tab's chip says, and its colour: nil when it is off, or
--- not a warlock, or the count can't be read.
function SoulShards:Chip()
    if not (self:IsOn() and self.IsWarlock()) then return nil end
    local count = self:Count()
    if not count then return nil end
    local text
    if count == 1 then
        text = L["1 soul shard"]
    else
        text = L.Format("%d soul shards", count)
    end
    return text, count <= self.LOW and "loss" or "muted"
end

--- Warn once when the shards drop to LOW or fewer, and again only after
--- there have been more than that.
function SoulShards:Check()
    if not (self:IsOn() and self.IsWarlock()) or self.ready == false then return false end
    local count = self:Count()
    if not count then return false end
    if count > self.LOW then
        self.warned = nil
        return false
    end
    if self.warned then return false end
    self.warned = true
    local message
    if count == 0 then
        message = L["You have no soul shards."]
    elseif count == 1 then
        message = L["Only 1 soul shard left."]
    else
        message = L.Format("Only %d soul shards left.", count)
    end
    ns.Warn(message)
    ns.PetStatus:Alert(message)
    return true
end

--- Turn it on or off, from Settings or /bpet shards.
function SoulShards:Set(on)
    ns.db.soulShards = on and true or false
    self.warned = nil
    if on then self:Check() end
    if ns.UI and ns.UI.Refresh then pcall(ns.UI.Refresh, ns.UI) end
end

--- No warning until SETTLE seconds after the loading screen: the bags can
--- read empty before the client has sent them.
function SoulShards:Settle()
    if not (C_Timer and C_Timer.After) then
        self.ready = true
        return
    end
    self.ready = false
    self.token = (self.token or 0) + 1
    local token = self.token
    C_Timer.After(self.SETTLE, function()
        if SoulShards.token ~= token then return end
        SoulShards.ready = true
        SoulShards:Check()
    end)
end

function SoulShards:OnEnable()
    self:Settle()
    ns.RegisterEvent(self, "BAG_UPDATE_DELAYED", function() SoulShards:Check() end)
    ns.RegisterEvent(self, "PLAYER_ENTERING_WORLD", function(_, _, isLogin, isReload)
        if isLogin or isReload then SoulShards:Settle() end
    end)
end

ns.RegisterCommand("shards", L["show your soul shards on the Pet tab and warn when low (on, off)"], function(rest)
    local word = (rest or ""):lower():match("^%s*(%S*)")
    local on
    if word == "on" then
        on = true
    elseif word == "off" then
        on = false
    else
        on = not SoulShards:IsOn()
    end
    SoulShards:Set(on)
    ns.Print(on and L["Soul shards: on."] or L["Soul shards: off."])
end)
