-- Blackthornes Pets -- UI/PetStrip.lua
-- The Pet Strip (a player asked on Discord for a pet status line, the owner
-- said build it from the mockup, 2026-11-26): one small see-through strip
-- with the pet's mood, the food left and how long it lasts, and its
-- experience. Under the mouse it turns solid and shows Feed and the close
-- gem. A hungry pet turns the mood's dot and Feed's glow on, with no card;
-- low food turns the count red.
--
-- Our own frame on UIParent, display only, so it drags even in a fight. The
-- Feed button is a secure action button on UIParent laid over the strip's
-- end by screen position, shown, hidden and moved out of combat only, as the
-- Feed button above the quests is (UI/FeedButton.lua). The game's pet frame
-- is only read (ns.PetFrameRect), never anchored to, moved, shown or hidden.
-- A hunter's pet only; nothing shows with no pet out or for a demon.
--
-- Nothing new is read from the game: it is handed what PetStatus and Food
-- read already (`PetStrip:Update(status, stacks)`), and only the part that
-- changed is drawn again.
--
-- Saved, account wide, never rename them: petStrip (off unless ticked),
-- petStripPlace (nil for On Pet Frame, "free" for Free), petStripX /
-- petStripY (its bottom left on UIParent while Free). Per character:
-- petFeedGap (`{ avg = seconds, n = feeds }`, how long one feed lasts, from
-- the player's own feeding, for "About 5 hours").

local ADDON, ns = ...
local L = ns.L

local Strip = ns.NewModule("PetStrip")

Strip.HEIGHT = 44
Strip.PORTRAIT = 32
Strip.PAD = 6
Strip.GAP = 10
Strip.ICON = 20
Strip.XP_WIDTH = 150
Strip.FEED_WIDTH = 54
Strip.FEED_HEIGHT = 22
Strip.CLOSE = 18
-- The background at rest and under the mouse.
Strip.REST_ALPHA = 0.45
Strip.HOT_ALPHA = 0.95
-- Between the game's pet frame (or the Pet XP bar under it) and the strip.
Strip.FRAME_GAP = 4
Strip.FIRST_Y = -260
-- How long the mouse may be off both the strip and Feed before it rests.
Strip.LEAVE_WAIT = 0.15
-- How long one feed lasts: feeds this far apart or more say nothing (a
-- logout, a pet left in the stable), feeds this close are one feed's top up.
Strip.GAP_MAX = 2 * 60 * 60
Strip.GAP_MIN = 25
-- Feeds seen before "About N hours" shows.
Strip.GAP_FEEDS = 3

local PAW = [[Interface\Icons\Ability_Hunter_BeastTraining]]
local DOT = ([[Interface\AddOns\%s\Media\Arrow\Dot]]):format(ADDON)

local function InCombat()
    -- Set from combat's start, a moment before the client locks frames.
    if Strip.fighting then return true end
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    return ok and locked == true
end

--- The icon of an item, by its ID, or nil.
local function ItemIcon(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
        if ok and icon then return icon end
    end
    if type(GetItemIcon) == "function" then
        local ok, icon = pcall(GetItemIcon, itemID)
        if ok and icon then return icon end
    end
    return nil
end

local function Now()
    if type(GetTime) == "function" then
        local ok, now = pcall(GetTime)
        if ok and type(now) == "number" then return now end
    end
    return 0
end

local function Label(parent, size, colorKey, justify)
    local label = ns.Theme.CreateLabel(parent, size or "small", colorKey or "text", justify or "LEFT")
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 1)
    pcall(label.SetWordWrap, label, false)
    return label
end

local function Width(label)
    local ok, width = pcall(label.GetStringWidth, label)
    return ok and type(width) == "number" and math.ceil(width) or 0
end

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

function Strip:IsOn() return ns.db ~= nil and ns.db.petStrip == true end

--- "Strip Place:" On Pet Frame (nil, the first choice) or Free.
function Strip:OnPetFrame()
    return not (ns.db and ns.db.petStripPlace == "free")
end

function Strip:SetPlace(onFrame)
    if not ns.db then return end
    ns.db.petStripPlace = (not onFrame) and "free" or nil
    self.framePlace = nil
    self:Place()
end

--- Whether the strip is on screen now, so the feed and food warnings leave
--- their card out: the strip says it already.
function Strip:Showing()
    return self:IsOn() and self.frame ~= nil and self.frame:IsShown() == true
end

--------------------------------------------------------------------------------
-- How long the food lasts
--------------------------------------------------------------------------------

--- A feed just started (Food:EatingChanged). The time since the last one,
--- for the same pet in this session, teaches how long one feed lasts.
function Strip:NoteFed(petName)
    local now = Now()
    local last, lastPet = self.lastFed, self.lastFedPet
    self.lastFed, self.lastFedPet = now, petName
    if not (last and ns.charDB) or lastPet ~= petName then return end
    local gap = now - last
    if gap < self.GAP_MIN or gap > self.GAP_MAX then return end
    local saved = ns.charDB.petFeedGap
    if type(saved) ~= "table" or type(saved.avg) ~= "number" then
        saved = { avg = gap, n = 1 }
    else
        -- The newest feeds count most, so a change of food or habit shows.
        saved = { avg = saved.avg * 0.8 + gap * 0.2, n = math.min((tonumber(saved.n) or 0) + 1, 99) }
    end
    ns.charDB.petFeedGap = saved
end

--- Seconds one feed lasts, once enough feeds were seen, or nil.
function Strip:FeedLasts()
    local saved = ns.charDB and ns.charDB.petFeedGap
    if type(saved) ~= "table" or type(saved.avg) ~= "number" then return nil end
    if (tonumber(saved.n) or 0) < self.GAP_FEEDS then return nil end
    return saved.avg
end

--- "About 5 hours" or "About 20 minutes" for `count` pieces of food, or nil
--- before the player's own feeding says how long one lasts.
function Strip:LastsText(count)
    local each = self:FeedLasts()
    if not (each and count and count > 0) then return nil end
    local minutes = math.max(1, math.floor(each * count / 60 + 0.5))
    if minutes < 90 then
        if minutes == 1 then return L["About 1 minute"] end
        return L.Format("About %d minutes", minutes)
    end
    local hours = math.floor(minutes / 60 + 0.5)
    return L.Format("About %d hours", hours)
end

--------------------------------------------------------------------------------
-- What it shows
--------------------------------------------------------------------------------

--- The strip's words and colours for a pet and its food, or nil when it
--- has nothing to show (off, no pet, a demon).
function Strip:Words(status, stacks)
    if not (status and status.exists) then return nil end
    if status.class and status.class ~= "HUNTER" then return nil end
    local words = {}
    words.name = status.name or L["Your pet"]
    words.level = status.level and tostring(status.level) or ""

    local info = status.happiness and ns.PetStatus.HAPPINESS[status.happiness]
    words.mood = info and info.name or ""
    words.moodColor = info and info.color or "dim"
    words.hungry = ns.FeedButton ~= nil and ns.FeedButton:Hungry(status) == true

    stacks = stacks or {}
    local best = stacks[1]
    local total = ns.Food:Count(stacks)
    if best then
        local food = ns.Food.ShownName(best) or best.name or ""
        words.food = ("%d %s"):format(ns.FeedButton.Carried(best, stacks), food)
        words.foodID = best.itemID
        words.lasts = self:LastsText(total)
    else
        words.food = L["None in your bags"]
    end
    words.low = total < (ns.Food.LOW_FOOD or 10)

    words.xpLevel = status.level and L.Format("Level %d", status.level) or ""
    if status.xp and status.xpMax and status.xpMax > 0 then
        words.xpPart = math.max(0, math.min(1, status.xp / status.xpMax))
        words.xpPercent = ("%d%%"):format(math.floor(words.xpPart * 100))
    end
    words.stack = best
    return words
end

--------------------------------------------------------------------------------
-- Build
--------------------------------------------------------------------------------

function Strip:Build()
    if self.frame then return self.frame end
    local Theme = ns.Theme
    local frame = CreateFrame("Frame", "BlackthornesPetsStrip", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetHeight(self.HEIGHT)
    frame:Hide()

    -- Dark glass, see-through at rest, with a fine gold edge.
    frame.background = Theme.Fill(frame, "panel", self.REST_ALPHA)
    Theme.Border(frame, "border", 0.9)

    -- The pet's face in a gold edge, its level in a small badge.
    local face = CreateFrame("Frame", nil, frame)
    face:SetSize(self.PORTRAIT, self.PORTRAIT)
    face:SetPoint("LEFT", self.PAD, 0)
    Theme.Fill(face, "well", 0.9)
    Theme.Border(face, "accent")
    local portrait = face:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", 1, -1)
    portrait:SetPoint("BOTTOMRIGHT", -1, 1)
    portrait:SetTexture(PAW)
    face.portrait = portrait
    local badge = CreateFrame("Frame", nil, face)
    badge:SetSize(18, 12)
    badge:SetPoint("BOTTOMRIGHT", 4, -3)
    Theme.Fill(badge, "well", 1)
    Theme.Border(badge, "accent")
    badge.text = Label(badge, "tiny", "text", "CENTER")
    badge.text:SetPoint("CENTER", 0, 0)
    face.badge = badge
    frame.face = face

    frame.name = Label(frame, "small", "gilt")
    frame.dot = frame:CreateTexture(nil, "ARTWORK")
    frame.dot:SetTexture(DOT)
    frame.dot:SetSize(9, 9)
    frame.mood = Label(frame, "small", "text")

    frame.line1 = Theme.CreateDivider(frame, "border")
    frame.line2 = Theme.CreateDivider(frame, "border")

    local icon = CreateFrame("Frame", nil, frame)
    icon:SetSize(self.ICON, self.ICON)
    Theme.Border(icon, "border")
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.icon = icon
    frame.food = Label(frame, "small", "text")
    frame.lasts = Label(frame, "small", "text")

    frame.xpLevel = Label(frame, "small", "text")
    frame.xpPercent = Label(frame, "small", "text", "RIGHT")
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetHeight(4)
    Theme.Fill(bar, "well", 1)
    bar.fill = bar:CreateTexture(nil, "ARTWORK")
    bar.fill:SetPoint("TOPLEFT")
    bar.fill:SetPoint("BOTTOMLEFT")
    bar.fill:SetColorTexture(Theme.Unpack("xp"))
    frame.bar = bar

    -- The house close gem, shown under the mouse: it turns the strip off.
    if ns.Titanforged and ns.Titanforged.CloseGem then
        local close = ns.Titanforged.CloseGem(frame, function() Strip:Close() end)
        close:SetSize(self.CLOSE, self.CLOSE)
        close:ClearAllPoints()
        close:SetPoint("RIGHT", frame, "RIGHT", -self.PAD, 0)
        close:SetFrameLevel((frame:GetFrameLevel() or 1) + 3)
        close:HookScript("OnLeave", function() Strip:LeaveSoon() end)
        close:Hide()
        frame.close = close
    end

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f)
        if not Strip:OnPetFrame() then f:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if f.SetUserPlaced then pcall(f.SetUserPlaced, f, false) end
        Strip:SaveSpot()
    end)
    frame:SetScript("OnMouseUp", function(_, mouse)
        if mouse == "RightButton" then Strip:Reset(true) end
    end)
    frame:SetScript("OnEnter", function() Strip:SetHot(true) end)
    frame:SetScript("OnLeave", function() Strip:LeaveSoon() end)

    self.frame = frame
    return frame
end

--- The secure Feed button, on UIParent so the strip stays free to drag.
function Strip:BuildFeed()
    if self.feed then return self.feed end
    local button = ns.Widgets.CreateButton(UIParent, L["Feed"], nil, {
        name = "BlackthornesPetsStripFeed",
        template = "SecureActionButtonTemplate",
        primary = true,
        width = self.FEED_WIDTH,
        height = self.FEED_HEIGHT,
    })
    button:SetFrameStrata("HIGH")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("useOnKeyDown", false)
    button:HookScript("OnEnter", function(owner)
        Strip:SetHot(true)
        local words = Strip.words
        if not (words and GameTooltip) then return end
        GameTooltip:SetOwner(owner, "ANCHOR_TOP")
        if Strip.eating then
            GameTooltip:AddLine(L["Your pet is still eating. Feeding now would waste food."], 1, 1, 1, true)
        elseif words.stack then
            GameTooltip:AddLine(L.Format("Feed %s", ns.Food.ShownName(words.stack) or words.stack.name or ""))
        end
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
        Strip:LeaveSoon()
    end)
    button:Hide()
    self.feed = button
    return button
end

--------------------------------------------------------------------------------
-- Draw
--------------------------------------------------------------------------------

--- Lay the pieces out for the widths their words need. Done again only when
--- a width changed.
function Strip:Layout(words)
    local frame = self.frame
    local nameW = math.max(Width(frame.name), 13 + Width(frame.mood))
    local foodW = math.max(Width(frame.food), Width(frame.lasts))
    local feedRoom = self:FeedRoom()
    local key = ("%d:%d:%s:%s:%s"):format(nameW, foodW, tostring(words.lasts ~= nil),
        tostring(feedRoom.feed), tostring(feedRoom.close))
    if key == self.layoutKey then return end
    self.layoutKey = key

    local x = self.PAD + self.PORTRAIT + 8
    frame.name:ClearAllPoints()
    frame.name:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -7)
    frame.dot:ClearAllPoints()
    frame.dot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, 10)
    frame.mood:ClearAllPoints()
    frame.mood:SetPoint("LEFT", frame.dot, "RIGHT", 4, 0)
    x = x + nameW + self.GAP

    local function Line(line)
        line:ClearAllPoints()
        line:SetSize(1, self.HEIGHT - 16)
        line:SetPoint("LEFT", frame, "LEFT", x, 0)
    end
    Line(frame.line1)
    x = x + 1 + self.GAP

    frame.icon:ClearAllPoints()
    frame.icon:SetPoint("LEFT", frame, "LEFT", x, 0)
    x = x + self.ICON + 6
    frame.food:ClearAllPoints()
    frame.lasts:ClearAllPoints()
    if words.lasts then
        frame.food:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -8)
        frame.lasts:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, 8)
    else
        frame.food:SetPoint("LEFT", frame, "LEFT", x, 0)
    end
    x = x + foodW + self.GAP

    Line(frame.line2)
    x = x + 1 + self.GAP

    frame.xpLevel:ClearAllPoints()
    frame.xpLevel:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -9)
    frame.xpPercent:ClearAllPoints()
    frame.xpPercent:SetPoint("TOPRIGHT", frame, "TOPLEFT", x + self.XP_WIDTH, -9)
    frame.bar:ClearAllPoints()
    frame.bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, 11)
    frame.bar:SetWidth(self.XP_WIDTH)
    x = x + self.XP_WIDTH + self.GAP

    -- Room for Feed and the close gem, while they show.
    self.feedX = x
    if feedRoom.feed then x = x + self.FEED_WIDTH + self.PAD end
    if feedRoom.close then x = x + self.CLOSE + self.PAD end
    self.baseWidth = x
    frame:SetWidth(x)
    self:PlaceFeed()
end

--- What the right end makes room for: Feed while the pet is hungry or the
--- mouse is on the strip, out of a fight and with food to give; the close
--- gem under the mouse.
function Strip:FeedRoom()
    local words = self.words
    local feed = words ~= nil and words.stack ~= nil and not InCombat()
        and (self.hot == true or words.hungry == true)
    return { feed = feed, close = self.hot == true }
end

local function Paint(label, text, colorKey)
    label:SetText(text or "")
    label:SetTextColor(ns.Theme.Unpack(colorKey or "text"))
end

--- Draw what changed since the last time.
function Strip:Paint(words)
    local frame = self.frame
    local Theme = ns.Theme

    local who = words.name .. "\1" .. words.level
    if who ~= self.whoKey then
        self.whoKey = who
        frame.name:SetText(words.name)
        frame.face.badge.text:SetText(words.level)
        frame.face.badge:SetShown(words.level ~= "")
        local shown = false
        if type(SetPortraitTexture) == "function" then
            shown = pcall(SetPortraitTexture, frame.face.portrait, "pet")
        end
        if not shown then frame.face.portrait:SetTexture(PAW) end
    end

    local mood = words.mood .. "\1" .. words.moodColor
    if mood ~= self.moodKey then
        self.moodKey = mood
        Paint(frame.mood, words.mood, "text")
        frame.dot:SetVertexColor(Theme.Unpack(words.moodColor))
        frame.dot:SetShown(words.mood ~= "")
    end

    local food = table.concat({ words.food, tostring(words.lasts), tostring(words.low), tostring(words.foodID) }, "\1")
    if food ~= self.foodKey then
        self.foodKey = food
        local color = words.low and "loss" or "text"
        local text = words.food
        -- Low food is red end to end: the name's own colour gives way.
        if words.low then text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") end
        Paint(frame.food, text, color)
        Paint(frame.lasts, words.lasts, words.low and "loss" or "muted")
        frame.lasts:SetShown(words.lasts ~= nil)
        local icon = ItemIcon(words.foodID)
        frame.icon.texture:SetTexture(icon or PAW)
        frame.icon:SetShown(words.foodID ~= nil)
    end

    local xp = words.xpLevel .. "\1" .. tostring(words.xpPercent)
    if xp ~= self.xpKey then
        self.xpKey = xp
        frame.xpLevel:SetText(words.xpLevel)
        frame.xpPercent:SetText(words.xpPercent or "")
        frame.bar:SetShown(words.xpPart ~= nil)
        local part = words.xpPart or 0
        frame.bar.fill:SetWidth(math.max(1, self.XP_WIDTH * part))
        frame.bar.fill:SetShown(part > 0)
    end

    self:Layout(words)
end

--------------------------------------------------------------------------------
-- Feed
--------------------------------------------------------------------------------

--- Put Feed over the strip's right end, pointed at the best food, while the
--- pet is hungry or the mouse is on the strip. Out of combat only; as combat
--- starts (`beforeCombat`) it is put away, since Feed Pet can't be cast in a
--- fight anyway.
function Strip:PlaceFeed(beforeCombat)
    local button = self.feed
    if InCombat() and not beforeCombat then return end
    local words = self.words
    local frame = self.frame
    local wanted = not beforeCombat and frame and frame:IsShown() and self:FeedRoom().feed
    if not wanted then
        if button then
            button:Hide()
            button:SetAttribute("macrotext", nil)
            if ns.Theme.SetHalo then ns.Theme.SetHalo(button, 0.12) end
        end
        self.feedKey = nil
        return
    end
    -- By screen position, so the strip is never tied to a protected frame.
    -- Where the client won't say where the strip is, Feed waits.
    local ok, x, bottom, scale = pcall(function()
        return frame:GetLeft(), frame:GetBottom(), frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    end)
    if not (ok and type(x) == "number" and type(bottom) == "number" and type(scale) == "number") then
        if button then button:Hide() end
        self.feedKey = nil
        return
    end
    button = self:BuildFeed()
    local left = ns.Food.Eating and ns.Food:Eating()
    self.eating = left ~= nil
    local macro = not left and ns.Food:FeedMacro(words.stack) or nil
    local feedLeft = (x + (self.feedX or 0)) * scale
    local feedBottom = (bottom + (self.HEIGHT - self.FEED_HEIGHT) / 2) * scale
    local glow = (words.hungry and not left) and 0.6 or 0.12
    -- Only what moved is set again: the pet's look every few seconds
    -- changes nothing here most of the time.
    local key = table.concat({ tostring(macro), feedLeft, feedBottom, glow }, "\1")
    if key == self.feedKey and button:IsShown() then return end
    self.feedKey = key
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", macro)
    if ns.Theme.SetHalo then ns.Theme.SetHalo(button, glow) end
    button:ClearAllPoints()
    button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", feedLeft, feedBottom)
    button:Show()
end

--------------------------------------------------------------------------------
-- Under the mouse
--------------------------------------------------------------------------------

--- Solid with Feed and the close gem under the mouse, see-through at rest.
function Strip:SetHot(on)
    on = on and true or false
    self.leaving = nil
    if self.hot == on then return end
    self.hot = on
    local frame = self.frame
    if not frame then return end
    frame.background:SetColorTexture(ns.Theme.Unpack("panel", on and self.HOT_ALPHA or self.REST_ALPHA))
    ns.Theme.SetBorderColor(frame, on and "accent" or "border", 0.9)
    if frame.close then frame.close:SetShown(on) end
    if self.words then self:Layout(self.words) end
    self:PlaceFeed()
end

local function Over(frame)
    if not (frame and frame:IsShown()) then return false end
    local ok, over = pcall(frame.IsMouseOver, frame)
    return ok and over == true
end

--- The mouse left one piece: rest once it is on none of them.
function Strip:LeaveSoon()
    if not (C_Timer and C_Timer.After) then
        self:SetHot(false)
        return
    end
    self.leaving = true
    C_Timer.After(self.LEAVE_WAIT, function()
        if not Strip.leaving then return end
        Strip.leaving = nil
        if Over(Strip.frame) or Over(Strip.feed) or (Strip.frame and Over(Strip.frame.close)) then return end
        Strip:SetHot(false)
    end)
end

--------------------------------------------------------------------------------
-- Keeping up
--------------------------------------------------------------------------------

--- Handed the pet and its food by PetStatus and Food whenever they look.
function Strip:Update(status, stacks)
    if not self:IsOn() then
        self:HideAll()
        return false
    end
    local words = self:Words(status, stacks)
    if not words then
        self:HideAll()
        return false
    end
    self.words = words
    local frame = self:Build()
    if not frame:IsShown() then
        self.layoutKey, self.whoKey, self.moodKey, self.foodKey, self.xpKey = nil, nil, nil, nil, nil
        self:Paint(words)
        self:Place()
        frame:Show()
    else
        if self:OnPetFrame() then self:Place() end
        self:Paint(words)
    end
    self:PlaceFeed()
    return true
end

function Strip:HideAll()
    self.words = nil
    if self.frame then self.frame:Hide() end
    if self.hot then
        self.hot = nil
        if self.frame then
            self.frame.background:SetColorTexture(ns.Theme.Unpack("panel", self.REST_ALPHA))
            ns.Theme.SetBorderColor(self.frame, "border", 0.9)
            if self.frame.close then self.frame.close:Hide() end
        end
    end
    if self.feed and not InCombat() then
        self.feedKey = nil
        self.feed:Hide()
        self.feed:SetAttribute("macrotext", nil)
    end
end

--- Look again now, with what PetStatus and Food read.
function Strip:Refresh()
    local status = ns.PetStatus and ns.PetStatus:Read()
    local stacks = status and ns.Food and ns.Food:Latest(status) or {}
    return self:Update(status, stacks)
end

--------------------------------------------------------------------------------
-- Place
--------------------------------------------------------------------------------

function Strip:Spot()
    local x, y = ns.db and ns.db.petStripX, ns.db and ns.db.petStripY
    if type(x) == "number" and type(y) == "number" then return x, y end
    return nil
end

--- On Pet Frame: under the game's pet frame, left edges in line, below the
--- Pet XP bar when that sits there too. Placed again only when that moved.
--- False with no pet frame to read.
function Strip:PlaceOnPetFrame()
    local frame = self.frame
    if not (frame and ns.PetFrameRect) then return false end
    local left, bottom = ns.PetFrameRect()
    if not left then return false end
    local Bar = ns.PetXPBar
    if Bar and Bar.OnPetFrame and Bar:OnPetFrame() and Bar.frame and Bar.frame:IsShown() then
        local ok, barBottom = pcall(Bar.frame.GetBottom, Bar.frame)
        if ok and type(barBottom) == "number" then bottom = barBottom end
    end
    local key = ("%d:%d"):format(left, bottom)
    if key ~= self.framePlace then
        self.framePlace = key
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, bottom - self.FRAME_GAP)
        self:PlaceFeed()
    end
    return true
end

function Strip:Place()
    local frame = self.frame
    if not frame then return end
    if self:OnPetFrame() and self:PlaceOnPetFrame() then return end
    self.framePlace = nil
    frame:ClearAllPoints()
    local x, y = self:Spot()
    if x then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
        -- Never dragged: the next free place on the shared top shelf.
        local sw = ns.SharedWindow
        local placed = sw and sw.ShelfPlace and sw.ShelfPlace(frame, "strip.pets", {
            free = function() return Strip:Spot() == nil end,
            place = function() Strip:Place() end,
        })
        if not placed then
            frame:SetPoint("TOP", UIParent, "TOP", 0, self.FIRST_Y)
        end
    end
    self:PlaceFeed()
end

function Strip:SaveSpot()
    local frame = self.frame
    if not (frame and ns.db) then return end
    local ok, left, bottom = pcall(function() return frame:GetLeft(), frame:GetBottom() end)
    if not (ok and type(left) == "number" and type(bottom) == "number") then return end
    ns.db.petStripX, ns.db.petStripY = left, bottom
    self:Place()
end

function Strip:Reset(quiet)
    if not ns.db then return end
    ns.db.petStripX, ns.db.petStripY = nil, nil
    self:Place()
    if not quiet then ns.Print(L["Pet Strip is back in its first spot."]) end
end

--------------------------------------------------------------------------------
-- On and off
--------------------------------------------------------------------------------

function Strip:Set(on)
    if not ns.db then return end
    ns.db.petStrip = on and true or false
    self:Refresh()
end

--- The close gem: the strip goes off, as unticking it does.
function Strip:Close()
    self:Set(false)
    if ns.SettingsUI and ns.SettingsUI.Refresh then pcall(ns.SettingsUI.Refresh, ns.SettingsUI) end
    ns.Print(L["Pet Strip: off."])
end

function Strip:OnEnable()
    ns.RegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        Strip:PlaceFeed(true)
        Strip.fighting = true
        -- Feed's room closes too; the strip itself is free to change.
        if Strip.words and Strip.frame and Strip.frame:IsShown() then Strip:Layout(Strip.words) end
    end)
    ns.RegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        Strip.fighting = nil
        if Strip:IsOn() then Strip:Refresh() end
    end)
end

ns.RegisterCommand("strip", L["show your pet's mood, food and experience in one strip (on, off, reset)"], function(rest)
    local word = (rest or ""):lower():match("^%s*(%S*)")
    if word == "reset" then
        Strip:Reset()
        return
    end
    local on
    if word == "on" then
        on = true
    elseif word == "off" then
        on = false
    else
        on = not Strip:IsOn()
    end
    Strip:Set(on)
    if ns.SettingsUI and ns.SettingsUI.Refresh then pcall(ns.SettingsUI.Refresh, ns.SettingsUI) end
    ns.Print(on and L["Pet Strip: on."] or L["Pet Strip: off."])
end)
