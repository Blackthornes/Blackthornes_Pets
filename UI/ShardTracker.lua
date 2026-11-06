-- Blackthornes Pets -- UI/ShardTracker.lua
-- The Shard Tracker (the owner said build it, 2026-11-06, from a mockup):
-- a small gold plaque on the screen with a warlock's soul shards and, once
-- each is learned, Healthstones and Soulstones. Nothing shows until Drain
-- Soul is known, since shards mean nothing before it.
--
-- It is our own frame on UIParent, display only (no secure parts), so it
-- can be dragged in a fight too. The house plaque's look (gold rim, red gem
-- at each end, dark glass), built from UI/Plaque.lua's colours without
-- changing that shared file. A count going up pops with a gold ring, going
-- down dips; shards at SoulShards.LOW or fewer turn red; a stone at 0 greys
-- out; a slot that appears slides in once. Effects Full moves all of it,
-- Subtle holds the glow still, Off holds everything still.
--
-- Saved, account wide, never rename them: shardTracker (off unless
-- ticked), shardTrackerScale (75, 100 or 125; nil for 100), shardTrackerX
-- and shardTrackerY (its bottom left on UIParent, nil for its first spot).
-- Counts are read inside a pcall, a moment after a burst of events.

local ADDON, ns = ...
local L = ns.L

local ShardTracker = ns.NewModule("ShardTracker")

ShardTracker.SIZES = { 75, 100, 125 }
-- How long a burst of bag, spell and aura events waits before one look.
ShardTracker.SETTLE = 0.3
ShardTracker.RIM = 2
ShardTracker.PAD = 10
ShardTracker.HEIGHT = 50
ShardTracker.SLOT = 74
ShardTracker.ICON = 30
ShardTracker.COUNT_SIZE = 20
ShardTracker.GEM = 11
ShardTracker.BREATHE = 1.6
-- Its first spot, from the top of the screen.
ShardTracker.FIRST_Y = -150

ShardTracker.RED = { 0.878, 0.325, 0.247 }
ShardTracker.VIOLET = { 0.608, 0.361, 1 }
ShardTracker.GOLD = { 0.97, 0.84, 0.48 }

-- Icons the client gives for each, these when it won't say.
ShardTracker.KINDS = {
    { key = "shards", title = L["Soul Shards"], item = 6265, fallback = 134075 },
    { key = "health", title = L["Healthstone"], item = 5512, fallback = 135230 },
    { key = "soul", title = L["Soulstone"], item = 5232, fallback = 136210 },
}

local GEM_ART = ([[Interface\AddOns\%s\Media\Frame\CloseGem.tga]]):format(ADDON)
local GLOW_ART = ([[Interface\AddOns\%s\Media\Frame\Glow.tga]]):format(ADDON)

local function Level()
    local Motion = ns.Motion
    return Motion and Motion.Level and Motion.Level() or "full"
end

local function Gradient(texture, bottom, top)
    if ns.Plaque and ns.Plaque.Gradient then
        ns.Plaque.Gradient(texture, bottom, top)
    else
        texture:SetColorTexture(top[1], top[2], top[3], top[4] or 1)
    end
end

local function Colors()
    return ns.Plaque or {
        RIM_TOP = { 0.98, 0.89, 0.60 }, RIM_MID = { 0.79, 0.57, 0.18 },
        RIM_WAIST = { 0.54, 0.35, 0.09 }, RIM_FOOT = { 0.89, 0.72, 0.35 },
        GLASS_TOP = { 0.157, 0.125, 0.086, 0.96 }, GLASS_FOOT = { 0.055, 0.043, 0.031, 0.96 },
    }
end

local function ItemIcon(kind)
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, kind.item)
        if ok and icon then return icon end
    end
    return kind.fallback
end

--- An alpha that breathes between 1 and `low`, played by the game.
local function Breathing(region, low, duration)
    if type(region.CreateAnimationGroup) ~= "function" then return nil end
    local ok, group = pcall(region.CreateAnimationGroup, region)
    if not (ok and group) then return nil end
    pcall(group.SetLooping, group, "BOUNCE")
    local ok2, fade = pcall(group.CreateAnimation, group, "Alpha")
    if not (ok2 and fade) then return nil end
    pcall(fade.SetFromAlpha, fade, 1)
    pcall(fade.SetToAlpha, fade, low)
    pcall(fade.SetDuration, fade, duration)
    pcall(fade.SetSmoothing, fade, "IN_OUT")
    return group
end

--------------------------------------------------------------------------------
-- What it shows
--------------------------------------------------------------------------------

--- Is it turned on?
function ShardTracker:IsOn()
    return ns.db ~= nil and ns.db.shardTracker == true
end

--- Should it be on screen: on, a warlock, and Drain Soul known.
function ShardTracker:Wanted()
    local SoulShards = ns.SoulShards
    return self:IsOn() and SoulShards ~= nil and SoulShards.IsWarlock()
        and SoulShards.KnowsDrainSoul()
end

--- The slots to show, in order, each { key, count, low, empty, onSomeone }.
--- Nil when the tracker should not show.
function ShardTracker:Slots()
    if not self:Wanted() then return nil end
    local Stones, SoulShards = ns.Stones, ns.SoulShards
    local slots = {}
    local shards = SoulShards:Count()
    slots[#slots + 1] = { key = "shards", count = shards,
        low = shards ~= nil and shards <= SoulShards.LOW }
    if Stones and Stones.Knows(Stones.HEALTH_SPELLS) then
        local count = Stones:HealthstoneCount()
        slots[#slots + 1] = { key = "health", count = count, empty = count == 0 }
    end
    if Stones and Stones.Knows(Stones.SOUL_SPELLS) then
        local count = Stones:SoulstoneCount()
        slots[#slots + 1] = { key = "soul", count = count, empty = count == 0,
            onSomeone = Stones:SoulstoneOnSomeone() }
    end
    return slots
end

--------------------------------------------------------------------------------
-- The frame
--------------------------------------------------------------------------------

function ShardTracker:Build()
    if self.frame then return self.frame end
    local C = Colors()
    local RIM = self.RIM

    local frame = CreateFrame("Frame", "BlackthornesPetsShardTracker", UIParent)
    frame:SetHeight(self.HEIGHT)
    frame:SetWidth(self.SLOT + (RIM + self.PAD) * 2)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:Hide()

    -- The soft gold glow round it, breathing on Full.
    local glow = CreateFrame("Frame", nil, frame)
    glow:SetAllPoints(frame)
    glow:SetFrameLevel(math.max(0, (frame:GetFrameLevel() or 1) - 1))
    if ns.Theme and ns.Theme.Halo then ns.Theme.Halo(glow, 7, 0.5, "accent") end
    glow.breathe = Breathing(glow, 0.35, self.BREATHE)
    frame.glow = glow

    local rimTop = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    rimTop:SetPoint("TOPLEFT")
    rimTop:SetPoint("TOPRIGHT")
    rimTop:SetPoint("BOTTOM", frame, "CENTER")
    Gradient(rimTop, C.RIM_MID, C.RIM_TOP)
    local rimFoot = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    rimFoot:SetPoint("BOTTOMLEFT")
    rimFoot:SetPoint("BOTTOMRIGHT")
    rimFoot:SetPoint("TOP", frame, "CENTER")
    Gradient(rimFoot, C.RIM_FOOT, C.RIM_WAIST)

    local glass = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    glass:SetPoint("TOPLEFT", RIM, -RIM)
    glass:SetPoint("BOTTOMRIGHT", -RIM, RIM)
    Gradient(glass, C.GLASS_FOOT, C.GLASS_TOP)

    local shine = frame:CreateTexture(nil, "BACKGROUND", nil, 3)
    shine:SetPoint("TOPLEFT", glass, "TOPLEFT")
    shine:SetPoint("TOPRIGHT", glass, "TOPRIGHT")
    shine:SetHeight(1)
    shine:SetColorTexture(1, 0.9, 0.63, 0.18)

    for _, side in ipairs({ "LEFT", "RIGHT" }) do
        local gem = frame:CreateTexture(nil, "OVERLAY", nil, 2)
        gem:SetSize(self.GEM, self.GEM)
        gem:SetTexture(GEM_ART)
        gem:SetPoint("CENTER", frame, side, 0, 0)
    end

    -- Dragging moves it, a fight or not: it has nothing the game guards.
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if f.SetUserPlaced then pcall(f.SetUserPlaced, f, false) end
        ShardTracker:SaveSpot()
    end)
    frame:SetScript("OnMouseUp", function(_, mouse)
        if mouse == "RightButton" then ShardTracker:Reset(true) end
    end)

    frame.slots = {}
    self.frame = frame
    return frame
end

--- One slot: icon in a small gold frame, a big count, and its glows.
function ShardTracker:MakeSlot(index)
    local frame = self.frame
    local C = Colors()
    local slot = CreateFrame("Frame", nil, frame)
    slot:SetSize(self.SLOT, self.HEIGHT - (self.RIM + 4) * 2)
    slot:EnableMouse(true)

    local back = slot:CreateTexture(nil, "BACKGROUND", nil, 4)
    back:SetAllPoints(slot)
    slot.back = back
    local edge = slot:CreateTexture(nil, "BORDER", nil, 0)
    edge:SetPoint("BOTTOMLEFT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetHeight(1)
    slot.edge = edge

    -- The violet halo behind the shard, and the gold ring a rise flashes.
    local halo = slot:CreateTexture(nil, "BORDER", nil, 1)
    halo:SetTexture(GLOW_ART)
    pcall(halo.SetBlendMode, halo, "ADD")
    halo:SetSize(self.ICON + 22, self.ICON + 22)
    halo:SetAlpha(0)
    slot.halo = halo
    slot.haloBreathe = Breathing(halo, 0.4, self.BREATHE * 1.25)

    local frameTex = slot:CreateTexture(nil, "BORDER", nil, 2)
    frameTex:SetSize(self.ICON + 4, self.ICON + 4)
    frameTex:SetPoint("LEFT", slot, "LEFT", 4, 0)
    Gradient(frameTex, C.RIM_WAIST, C.RIM_TOP)
    halo:SetPoint("CENTER", frameTex, "CENTER")
    local well = slot:CreateTexture(nil, "BORDER", nil, 3)
    well:SetPoint("TOPLEFT", frameTex, "TOPLEFT", 2, -2)
    well:SetPoint("BOTTOMRIGHT", frameTex, "BOTTOMRIGHT", -2, 2)
    well:SetColorTexture(0.105, 0.078, 0.051, 1)
    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", well, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", well, "BOTTOMRIGHT", -1, 1)
    pcall(icon.SetTexCoord, icon, 0.08, 0.92, 0.08, 0.92)
    slot.icon, slot.iconFrame = icon, frameTex

    local ring = slot:CreateTexture(nil, "OVERLAY", nil, 1)
    ring:SetTexture(GLOW_ART)
    pcall(ring.SetBlendMode, ring, "ADD")
    ring:SetPoint("CENTER", frameTex, "CENTER")
    ring:SetSize(self.ICON, self.ICON)
    ring:SetVertexColor(1, 0.85, 0.4)
    ring:SetAlpha(0)
    slot.ring = ring

    local count = slot:CreateFontString(nil, "OVERLAY")
    slot.count = count
    self:SetCountSize(slot, 1)
    count:SetPoint("LEFT", frameTex, "RIGHT", 6, 0)
    count:SetShadowOffset(1, -1)
    count:SetShadowColor(0, 0, 0, 1)

    -- The gold dot while the Soulstone is on someone.
    local dotGlow = slot:CreateTexture(nil, "OVERLAY", nil, 2)
    dotGlow:SetTexture(GLOW_ART)
    pcall(dotGlow.SetBlendMode, dotGlow, "ADD")
    dotGlow:SetSize(14, 14)
    dotGlow:SetPoint("CENTER", slot, "TOPRIGHT", -6, -6)
    dotGlow:SetVertexColor(1, 0.85, 0.4)
    local dot = slot:CreateTexture(nil, "OVERLAY", nil, 3)
    dot:SetSize(5, 5)
    dot:SetPoint("CENTER", dotGlow, "CENTER")
    dot:SetColorTexture(1, 0.88, 0.5, 1)
    slot.dot, slot.dotGlow = dot, dotGlow
    dot:Hide()
    dotGlow:Hide()

    -- Drags and right-clicks on a slot are the tracker's.
    slot:RegisterForDrag("LeftButton")
    slot:SetScript("OnDragStart", function() frame:GetScript("OnDragStart")(frame) end)
    slot:SetScript("OnDragStop", function() frame:GetScript("OnDragStop")(frame) end)
    slot:SetScript("OnMouseUp", function(_, mouse)
        if mouse == "RightButton" then ShardTracker:Reset(true) end
    end)
    slot:SetScript("OnEnter", function(s) ShardTracker:ShowTooltip(s) end)
    slot:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    slot.index = index
    frame.slots[index] = slot
    return slot
end

function ShardTracker:SetCountSize(slot, scale)
    local font = (ns.Theme and ns.Theme.FONT) or [[Fonts\FRIZQT__.TTF]]
    pcall(slot.count.SetFont, slot.count, font,
        math.max(8, math.floor(self.COUNT_SIZE * scale + 0.5)), "OUTLINE")
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

local function CountText(count)
    if count == nil then return "?" end
    return tostring(count)
end

--- Paint one slot for what it holds now; animate what changed.
function ShardTracker:Paint(slot, data, index)
    local kind
    for _, k in ipairs(self.KINDS) do if k.key == data.key then kind = k end end
    local old = slot.data
    slot.data = data
    slot.kind = kind

    slot.back:SetColorTexture(ns.Theme.Unpack(index % 2 == 1 and "glass" or "glassAlt", 0.9))
    slot.icon:SetTexture(ItemIcon(kind))
    pcall(slot.icon.SetDesaturated, slot.icon, data.empty and true or false)

    local textR, textG, textB = unpack(self.GOLD)
    local textAlpha = 1
    if data.low then
        textR, textG, textB = unpack(self.RED)
        slot.edge:SetColorTexture(self.RED[1], self.RED[2], self.RED[3], 0.9)
    elseif data.empty then
        textR, textG, textB = 0.55, 0.57, 0.61
        textAlpha = 0.6
        slot.edge:SetColorTexture(ns.Theme.Unpack("border", 0.6))
    else
        slot.edge:SetColorTexture(ns.Theme.Unpack("border", 0.6))
    end
    slot.count:SetText(CountText(data.count))
    slot.count:SetTextColor(textR, textG, textB)
    slot.count:SetAlpha(textAlpha)

    -- The halo: violet behind the shard, red when shards run low.
    local level = Level()
    if data.key == "shards" then
        local c = data.low and self.RED or self.VIOLET
        slot.halo:SetVertexColor(c[1], c[2], c[3])
        slot.halo:SetAlpha(level == "off" and 0.55 or 0.8)
        local breathe = rawget(slot, "haloBreathe")
        if breathe then pcall(level == "full" and breathe.Play or breathe.Stop, breathe) end
    else
        slot.halo:SetAlpha(0)
    end

    slot.dot:SetShown(data.onSomeone and true or false)
    slot.dotGlow:SetShown(data.onSomeone and true or false)

    -- What moved since the last look.
    if old and old.key == data.key and type(old.count) == "number" and type(data.count) == "number" then
        if data.count > old.count then
            self:Pop(slot)
        elseif data.count < old.count then
            self:Dip(slot)
        end
    end
end

--- A count going up: it grows and settles, with a gold ring.
function ShardTracker:Pop(slot)
    local Motion = ns.Motion
    if Level() == "off" or not (Motion and Motion.Run) then return end
    Motion:Run(slot.count, "pop", 0.45, function(p)
        ShardTracker:SetCountSize(slot, 1 + 0.35 * math.sin(math.pi * p))
    end, { ease = false, done = function() ShardTracker:SetCountSize(slot, 1) end })
    Motion:Run(slot.ring, "ring", 0.6, function(p)
        local size = ShardTracker.ICON * (1 + 1.2 * p)
        slot.ring:SetSize(size, size)
        slot.ring:SetAlpha(0.9 * (1 - p))
    end)
end

--- A count going down: it drops a little and comes back.
function ShardTracker:Dip(slot)
    local Motion = ns.Motion
    if Level() == "off" or not (Motion and Motion.Run) then return end
    Motion:Run(slot.count, "dip", 0.4, function(p)
        local depth = -4 * math.sin(math.pi * p)
        slot.count:ClearAllPoints()
        slot.count:SetPoint("LEFT", slot.iconFrame, "RIGHT", 6, depth)
    end, { ease = false })
end

--- A slot that appeared slides in from below, once.
function ShardTracker:SlideIn(slot)
    local Motion = ns.Motion
    if Level() == "off" or not (Motion and Motion.Run) then
        slot:SetAlpha(1)
        return
    end
    Motion:Run(slot, "slide", 0.35, function(p)
        slot:SetAlpha(p)
        slot:ClearAllPoints()
        slot:SetPoint("LEFT", ShardTracker.frame, "LEFT", slot.x, -8 * (1 - p))
    end, { done = function()
        slot:ClearAllPoints()
        slot:SetPoint("LEFT", ShardTracker.frame, "LEFT", slot.x, 0)
    end })
end

--- Read and draw. Hides it when it should not show.
function ShardTracker:Refresh()
    local slots = self:Slots()
    if not slots then
        if self.frame then self.frame:Hide() end
        return false
    end
    local frame = self:Build()
    local RIM, PAD = self.RIM, self.PAD
    for index, data in ipairs(slots) do
        local slot = frame.slots[index] or self:MakeSlot(index)
        slot.x = RIM + PAD + (index - 1) * self.SLOT
        local fresh = not slot.placed or slot.key ~= data.key
        slot.key = data.key
        self:Paint(slot, data, index)
        slot:Show()
        if fresh then
            slot.placed = true
            slot:ClearAllPoints()
            slot:SetPoint("LEFT", frame, "LEFT", slot.x, 0)
            -- Slide in only when a slot joins a tracker already showing.
            if frame:IsShown() and index > 1 then self:SlideIn(slot) end
        end
    end
    for index = #slots + 1, #frame.slots do
        frame.slots[index]:Hide()
        frame.slots[index].placed = nil
        frame.slots[index].data = nil
    end
    frame:SetWidth(#slots * self.SLOT + (RIM + PAD) * 2)

    if not frame:IsShown() then
        self:ApplyScale()
        self:Place()
        frame:Show()
    end
    self:Glow()
    return true
end

--- The gold glow round it: breathing on Full, still on Subtle and Off.
function ShardTracker:Glow()
    local glow = self.frame and self.frame.glow
    if not glow then return end
    glow:Show()
    local breathe = rawget(glow, "breathe")
    if breathe then pcall(Level() == "full" and breathe.Play or breathe.Stop, breathe) end
end

--- One look a moment after a burst of events.
function ShardTracker:Soon()
    if self.pending then return end
    if not (C_Timer and C_Timer.After) then
        self:Refresh()
        return
    end
    self.pending = true
    C_Timer.After(self.SETTLE, function()
        ShardTracker.pending = nil
        ShardTracker:Refresh()
    end)
end

--------------------------------------------------------------------------------
-- The hover
--------------------------------------------------------------------------------

function ShardTracker:ShowTooltip(slot)
    local data, kind = slot.data, slot.kind
    if not (data and kind and GameTooltip) then return end
    GameTooltip:SetOwner(slot, "ANCHOR_BOTTOM")
    GameTooltip:AddLine(kind.title, 1, 0.82, 0.3)
    local gold = self.GOLD
    if GameTooltip.AddDoubleLine then
        GameTooltip:AddDoubleLine(L["In your bags"], CountText(data.count),
            0.9, 0.9, 0.9, gold[1], gold[2], gold[3])
    else
        GameTooltip:AddLine(L["In your bags"] .. "  " .. CountText(data.count))
    end
    if data.key == "soul" and data.onSomeone and ns.Stones then
        local name = ns.Stones:SoulstoneHolderName()
        if name then GameTooltip:AddLine(L.Format("On %s", name), 1, 1, 1) end
    end
    GameTooltip:AddLine(L["Drag to move it. Right-click to put it back."], 0.5, 0.5, 0.5, true)
    GameTooltip:Show()
end

--------------------------------------------------------------------------------
-- Place and size
--------------------------------------------------------------------------------

--- The size picked: 75, 100 or 125.
function ShardTracker:Size()
    local size = ns.db and ns.db.shardTrackerScale
    for _, allowed in ipairs(self.SIZES) do
        if size == allowed then return size end
    end
    return 100
end

function ShardTracker:SetSize(size)
    if not ns.db then return end
    local fits = false
    for _, allowed in ipairs(self.SIZES) do if size == allowed then fits = true end end
    if not fits then size = 100 end
    ns.db.shardTrackerScale = size ~= 100 and size or nil
    if self.frame then
        self:ApplyScale()
        self:Place()
    end
end

function ShardTracker:ApplyScale()
    if self.frame then self.frame:SetScale(self:Size() / 100) end
end

--- The spot the player dragged it to, or nil.
function ShardTracker:Spot()
    local x, y = ns.db and ns.db.shardTrackerX, ns.db and ns.db.shardTrackerY
    if type(x) == "number" and type(y) == "number" then return x, y end
    return nil
end

--- Where it sits: the spot kept in screen units, so a new size keeps it.
function ShardTracker:Place()
    local frame = self.frame
    if not frame then return end
    frame:ClearAllPoints()
    local scale = self:Size() / 100
    local x, y = self:Spot()
    if x then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, self.FIRST_Y / scale)
    end
end

--- Keep where it was dropped, as its bottom left on UIParent.
function ShardTracker:SaveSpot()
    local frame = self.frame
    if not (frame and ns.db) then return end
    local ok, left, bottom, scale = pcall(function()
        return frame:GetLeft(), frame:GetBottom(),
            frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    end)
    if not (ok and type(left) == "number" and type(bottom) == "number" and type(scale) == "number") then
        return
    end
    ns.db.shardTrackerX, ns.db.shardTrackerY = left * scale, bottom * scale
    self:Place()
end

--- Back to its first spot.
function ShardTracker:Reset(quiet)
    if not ns.db then return end
    ns.db.shardTrackerX, ns.db.shardTrackerY = nil, nil
    self:Place()
    if not quiet then ns.Print(L["Shard tracker is back in its first spot."]) end
end

--------------------------------------------------------------------------------
-- On and off
--------------------------------------------------------------------------------

local function OnAura(_, _, unit)
    if type(unit) ~= "string" then return end
    if not (ShardTracker.frame and ShardTracker.frame:IsShown()) then return end
    if unit == "player" or unit:find("^party%d") or unit:find("^raid%d") then
        ShardTracker:Soon()
    end
end

--- Listen only while it is turned on, so nobody else pays for it.
function ShardTracker:Listen(on)
    if on and not self.listening then
        self.listening = true
        local function Look() ShardTracker:Soon() end
        for _, event in ipairs({ "BAG_UPDATE_DELAYED", "LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED",
            "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD" }) do
            ns.RegisterEvent(self, event, Look)
        end
        ns.RegisterEvent(self, "UNIT_AURA", OnAura)
    elseif not on and self.listening then
        self.listening = nil
        if ns.UnregisterEvent then
            for _, event in ipairs({ "BAG_UPDATE_DELAYED", "LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED",
                "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "UNIT_AURA" }) do
                ns.UnregisterEvent(self, event)
            end
        end
    end
end

--- Turn it on or off, from Settings or /bpet tracker.
function ShardTracker:Set(on)
    ns.db.shardTracker = on and true or false
    self:Listen(on)
    self:Refresh()
end

function ShardTracker:OnEnable()
    if self:IsOn() then
        self:Listen(true)
        self:Soon()
    end
end

ns.RegisterCommand("tracker", L["show your soul shards and stones on screen (on, off, reset)"], function(rest)
    local word = (rest or ""):lower():match("^%s*(%S*)")
    if word == "reset" then
        ShardTracker:Reset()
        return
    end
    local on
    if word == "on" then
        on = true
    elseif word == "off" then
        on = false
    else
        on = not ShardTracker:IsOn()
    end
    ShardTracker:Set(on)
    if ns.SettingsUI and ns.SettingsUI.Refresh then pcall(ns.SettingsUI.Refresh, ns.SettingsUI) end
    ns.Print(on and L["Shard tracker: on."] or L["Shard tracker: off."])
end)
