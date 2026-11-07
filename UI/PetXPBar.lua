-- Blackthornes Pets -- UI/PetXPBar.lua
-- The Pet XP bar (a player asked, the owner said build it from a mockup,
-- 2026-11-07): Farmer's XP bar look for a hunter's pet. A gold fill in
-- dark glass with a gold rim, a tick every tenth, a white mark where this
-- session started and a spark at the tip. Words above and below it, the
-- XP on it, and a dark glass card on hover. A level-up cheer that follows
-- Effects (Full, Subtle, Off), with no sound.
--
-- Our own frame on UIParent, display only, so it can be dragged in a fight.
-- The game's pet frame is never touched. Hidden with no pet or a demon.
--
-- Saved, account wide, never rename them: petXPBar (off unless ticked),
-- petXPBarWidth (200 to 600, nil for 360), petXPBarHeight (6 to 32, nil
-- for 16), petXPBarWords and petXPBarCheer (on unless unticked), and
-- petXPBarX / petXPBarY (its bottom left on UIParent, nil for its first
-- spot).

local ADDON, ns = ...
local L = ns.L

local Bar = ns.NewModule("PetXPBar")

Bar.WIDTH, Bar.MIN_WIDTH, Bar.MAX_WIDTH, Bar.WIDTH_STEP = 360, 200, 600, 20
Bar.HEIGHT, Bar.MIN_HEIGHT, Bar.MAX_HEIGHT, Bar.HEIGHT_STEP = 16, 6, 32, 2
-- Under this height the words go to the hover only.
Bar.WORDS_FROM = 12
Bar.LINE = 16
Bar.SETTLE = 0.2
Bar.FIRST_Y = -210
Bar.CHEER_HOLD = 3
Bar.CARD_WIDTH = 280
Bar.CARD_ROW = 34

Bar.GOLD = { 0.97, 0.84, 0.48 }

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

--- 1350 as "1,350".
function Bar.Number(n)
    n = math.floor((n or 0) + 0.5)
    if type(BreakUpLargeNumbers) == "function" then
        local ok, text = pcall(BreakUpLargeNumbers, n)
        if ok and type(text) == "string" then return text end
    end
    local text = tostring(n)
    local sign, digits = text:match("^(%-?)(%d+)$")
    if not digits then return text end
    digits = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. digits
end

local function Clamp(value, low, high, default)
    if type(value) ~= "number" then return default end
    return math.max(low, math.min(high, value))
end

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

function Bar:IsOn() return ns.db ~= nil and ns.db.petXPBar == true end
function Bar:Width()
    return Clamp(ns.db and ns.db.petXPBarWidth, self.MIN_WIDTH, self.MAX_WIDTH, self.WIDTH)
end
function Bar:Height()
    return Clamp(ns.db and ns.db.petXPBarHeight, self.MIN_HEIGHT, self.MAX_HEIGHT, self.HEIGHT)
end
function Bar:ShowsWords() return not (ns.db and ns.db.petXPBarWords == false) end
function Bar:Cheers() return not (ns.db and ns.db.petXPBarCheer == false) end

--- Do words fit on the bar at this height?
function Bar:WordsFit() return self:Height() >= self.WORDS_FROM end

function Bar:SetWidth(width)
    if not ns.db then return end
    width = Clamp(width, self.MIN_WIDTH, self.MAX_WIDTH, self.WIDTH)
    ns.db.petXPBarWidth = width ~= self.WIDTH and width or nil
    self:Layout()
end

function Bar:SetHeight(height)
    if not ns.db then return end
    height = Clamp(height, self.MIN_HEIGHT, self.MAX_HEIGHT, self.HEIGHT)
    ns.db.petXPBarHeight = height ~= self.HEIGHT and height or nil
    self:Layout()
end

function Bar:SetWords(on)
    if not ns.db then return end
    ns.db.petXPBarWords = on and true or false
    self:Layout()
end

function Bar:SetCheer(on)
    if ns.db then ns.db.petXPBarCheer = on and true or false end
end

--------------------------------------------------------------------------------
-- The words
--------------------------------------------------------------------------------

local function NameOf(read)
    return read.name or L["Your pet"]
end

--- Everything the bar and its card say, worked out once a look.
--- { left, right, belowLeft, belowRight, onBar, fraction, mark }
function Bar:Words(read)
    local PetXP = ns.PetXP
    local s = PetXP:Session(read)
    local words = {}
    local pct = math.floor(read.xp / read.max * 100)
    local numbers = L.Format("%s / %s (%d%%)", Bar.Number(read.xp), Bar.Number(read.max), pct)
    words.fraction = math.max(0, math.min(1, read.xp / read.max))
    words.mark = s.startFraction
    words.name = NameOf(read)

    if read.capped then
        words.left = L.Format("Level %d · Same level as you", read.level)
    else
        words.left = L.Format("Level %d", read.level)
        local minutes = PetXP:MinutesLeft(read)
        if minutes then
            words.right = L.Format("Level %d in about %d min", read.level + 1, minutes)
        end
    end
    words.belowLeft = L.Format("This session +%s XP", Bar.Number(s.gained))
    local perHour = PetXP:PerHour(read)
    if perHour then words.belowRight = L.Format("%s XP an hour", Bar.Number(perHour)) end

    if self:ShowsWords() then
        words.onBar = numbers
    else
        words.onBar = L.Format("%s · Level %d · %s", words.name, read.level, numbers)
    end
    return words
end

--- The hover card's lines: { header, rows = { { left, sub, right } }, foot }.
function Bar:CardLines(read)
    local PetXP = ns.PetXP
    local s = PetXP:Session(read)
    local name = NameOf(read)
    local rows = {}
    if not read.capped then
        rows[#rows + 1] = { left = L.Format("XP to level %d", read.level + 1),
            right = Bar.Number(PetXP:ToGo(read)) }
        local kills = PetXP:KillsLeft(read)
        if kills then
            local minutes = PetXP:MinutesLeft(read)
            rows[#rows + 1] = {
                left = kills == 1 and L["About 1 more kill"] or L.Format("About %d more kills", kills),
                sub = L["of what you're fighting now"],
                right = minutes and L.Format("about %d min", minutes) or nil,
            }
        end
    end
    local minutes = PetXP.Minutes(PetXP:Seconds(read))
    rows[#rows + 1] = {
        left = L["This session"],
        sub = s.kills == 1 and L.Format("%d min, 1 kill", minutes)
            or L.Format("%d min, %d kills", minutes, s.kills),
        right = L.Format("+%s XP", Bar.Number(s.gained)),
    }
    local togo = math.max(0, (read.playerLevel or read.level) - read.level)
    rows[#rows + 1] = {
        left = L["Your level"],
        sub = L.Format("%s can grow until level %d", name, read.playerLevel or read.level),
        right = togo == 0 and L["Same level as you"]
            or (togo == 1 and L["1 level to go"] or L.Format("%d levels to go", togo)),
    }
    return {
        header = L.Format("%s, LEVEL %d", name:upper(), read.level),
        rows = rows,
        foot = L["Drag it anywhere. Right-click puts it back."],
    }
end

--------------------------------------------------------------------------------
-- The frame
--------------------------------------------------------------------------------

local function Label(parent, size, justify)
    local label = ns.Theme.CreateLabel(parent, size or "small", "text", justify or "LEFT")
    label:SetShadowOffset(1, -1)
    label:SetShadowColor(0, 0, 0, 1)
    pcall(label.SetWordWrap, label, false)
    return label
end

function Bar:Build()
    if self.frame then return self.frame end
    local Theme = ns.Theme
    local frame = CreateFrame("Frame", "BlackthornesPetsXPBar", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:Hide()

    frame.left = Label(frame, "small", "LEFT")
    frame.right = Label(frame, "small", "RIGHT")
    frame.belowLeft = Label(frame, "tiny", "LEFT")
    frame.belowRight = Label(frame, "tiny", "RIGHT")
    frame.name = Label(frame, "small", "LEFT")
    frame.name:SetTextColor(unpack(self.GOLD))
    frame.belowLeft:SetTextColor(Theme.Unpack("muted"))
    frame.belowRight:SetTextColor(Theme.Unpack("muted"))

    -- The bar: a dark well in a gold rim with a soft halo.
    local bar = CreateFrame("Frame", nil, frame)
    frame.bar = bar
    local C = ns.Plaque or { RIM_TOP = { 0.98, 0.89, 0.60 }, RIM_WAIST = { 0.54, 0.35, 0.09 } }
    local rim = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
    rim:SetPoint("TOPLEFT", -2, 2)
    rim:SetPoint("BOTTOMRIGHT", 2, -2)
    Gradient(rim, C.RIM_WAIST, C.RIM_TOP)
    local well = bar:CreateTexture(nil, "BACKGROUND", nil, 2)
    well:SetAllPoints(bar)
    well:SetColorTexture(Theme.Unpack("well", 0.95))
    if Theme.Halo then
        local halo = CreateFrame("Frame", nil, bar)
        halo:SetAllPoints(bar)
        halo:SetFrameLevel(math.max(0, (bar:GetFrameLevel() or 1) - 1))
        Theme.Halo(halo, 7, 0.18, "accent")
    end

    local fill = bar:CreateTexture(nil, "BORDER", nil, 1)
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMLEFT")
    Gradient(fill, { 0.70, 0.50, 0.15, 1 }, { 0.97, 0.84, 0.48, 1 })
    bar.fill = fill
    local sheen = bar:CreateTexture(nil, "BORDER", nil, 2)
    sheen:SetPoint("TOPLEFT", fill, "TOPLEFT")
    sheen:SetPoint("TOPRIGHT", fill, "TOPRIGHT")
    sheen:SetColorTexture(1, 1, 1, 0.22)
    bar.sheen = sheen
    local shade = bar:CreateTexture(nil, "BORDER", nil, 2)
    shade:SetPoint("BOTTOMLEFT", fill, "BOTTOMLEFT")
    shade:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT")
    shade:SetColorTexture(0, 0, 0, 0.18)
    bar.shade = shade

    bar.ticks = {}
    for i = 1, 9 do
        local tick = bar:CreateTexture(nil, "ARTWORK", nil, 1)
        tick:SetWidth(1)
        tick:SetColorTexture(0, 0, 0, 0.5)
        bar.ticks[i] = tick
    end
    local mark = bar:CreateTexture(nil, "ARTWORK", nil, 2)
    mark:SetWidth(2)
    mark:SetColorTexture(1, 1, 1, 0.8)
    bar.mark = mark

    local spark = bar:CreateTexture(nil, "OVERLAY", nil, 1)
    spark:SetTexture(GLOW_ART)
    pcall(spark.SetBlendMode, spark, "ADD")
    spark:SetVertexColor(1, 0.9, 0.6)
    bar.spark = spark

    local text = bar:CreateFontString(nil, "OVERLAY", nil, 2)
    pcall(text.SetFont, text, Theme.FONT, Theme.sizes.small or 11, "THICKOUTLINE")
    text:SetTextColor(1, 1, 1)
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    pcall(text.SetWordWrap, text, false)
    bar.text = text

    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if f.SetUserPlaced then pcall(f.SetUserPlaced, f, false) end
        Bar:SaveSpot()
    end)
    frame:SetScript("OnMouseUp", function(_, mouse)
        if mouse == "RightButton" then Bar:Reset(true) end
    end)
    frame:SetScript("OnEnter", function() Bar:ShowCard() end)
    frame:SetScript("OnLeave", function() Bar:HideCard() end)

    self.frame = frame
    self:Layout()
    return frame
end

--- Size and place the pieces for the width, height and words picked.
function Bar:Layout()
    local frame = self.frame
    if not frame then return end
    local width, height = self:Width(), self:Height()
    local words = self:ShowsWords() and self:WordsFit()
    local line = words and self.LINE or 0
    frame:SetSize(width + 8, height + line * 2 + 8)
    local bar = frame.bar
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -(4 + line))
    bar:SetSize(width, height)
    bar.sheen:SetHeight(math.max(1, math.floor(height * 0.4)))
    bar.shade:SetHeight(math.max(1, math.floor(height * 0.3)))
    for i, tick in ipairs(bar.ticks) do
        tick:ClearAllPoints()
        tick:SetPoint("TOP", bar, "TOPLEFT", width * i / 10, 0)
        tick:SetHeight(height)
    end
    bar.mark:SetHeight(height + 4)
    bar.spark:SetSize(height * 2 + 6, height * 2 + 6)

    frame.name:ClearAllPoints()
    frame.name:SetPoint("BOTTOMLEFT", bar, "TOPLEFT", 0, 3)
    frame.left:ClearAllPoints()
    frame.left:SetPoint("LEFT", frame.name, "RIGHT", 8, 0)
    frame.right:ClearAllPoints()
    frame.right:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 3)
    frame.belowLeft:ClearAllPoints()
    frame.belowLeft:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
    frame.belowRight:ClearAllPoints()
    frame.belowRight:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    for _, key in ipairs({ "name", "left", "right", "belowLeft", "belowRight" }) do
        frame[key]:SetShown(words)
    end
    bar.text:SetShown(self:WordsFit())
    if self.read then self:Paint(self.read) end
end

--- Draw one read.
function Bar:Paint(read)
    local frame = self.frame
    if not (frame and read) then return end
    local words = self:Words(read)
    local width, height = self:Width(), self:Height()
    local bar = frame.bar
    local filled = math.max(1, width * words.fraction)
    bar.fill:SetWidth(filled)
    bar.mark:ClearAllPoints()
    bar.mark:SetPoint("CENTER", bar, "LEFT", width * (words.mark or 0), 0)
    bar.mark:SetShown((words.mark or 0) > 0 and (words.mark or 0) < words.fraction)
    bar.spark:ClearAllPoints()
    bar.spark:SetPoint("CENTER", bar, "LEFT", filled, 0)
    bar.spark:SetShown(words.fraction > 0 and words.fraction < 1)
    bar.text:SetText(self:WordsFit() and words.onBar or "")

    frame.name:SetText(words.name)
    frame.left:SetText(words.left or "")
    frame.left:SetTextColor(ns.Theme.Unpack(read.capped and "muted" or "text"))
    frame.right:SetText(words.right or "")
    frame.belowLeft:SetText(words.belowLeft or "")
    frame.belowRight:SetText(words.belowRight or "")
    self:FitWords(width)
    if self.card and self.card:IsShown() then self:ShowCard() end
end

--- Never cut the words: the bar grows a little when they need the room.
function Bar:FitWords(width)
    local frame = self.frame
    if not (frame and frame.name:IsShown()) then return end
    local TW = ns.Theme.TextWidth
    local above = TW("small", frame.name:GetText()) + 8 + TW("small", frame.left:GetText())
        + 12 + TW("small", frame.right:GetText())
    local below = TW("tiny", frame.belowLeft:GetText()) + 12 + TW("tiny", frame.belowRight:GetText())
    local need = math.max(above, below)
    if need > width then frame:SetWidth(need + 8) end
end

--------------------------------------------------------------------------------
-- The hover card
--------------------------------------------------------------------------------

function Bar:BuildCard()
    if self.card then return self.card end
    local Theme = ns.Theme
    local card = CreateFrame("Frame", nil, UIParent)
    card:SetFrameStrata("TOOLTIP")
    card:SetWidth(self.CARD_WIDTH)
    Theme.Fill(card, "window", 0.96)
    Theme.Border(card, "metal", 1)
    local head = CreateFrame("Frame", nil, card)
    head:SetPoint("TOPLEFT", 1, -1)
    head:SetPoint("TOPRIGHT", -1, -1)
    head:SetHeight(26)
    Theme.Fill(head, "glassActive", 1)
    local edge = head:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT")
    edge:SetPoint("BOTTOMLEFT")
    edge:SetWidth(2)
    edge:SetColorTexture(Theme.Unpack("accentHi"))
    card.header = Label(head, "normal", "LEFT")
    card.header:SetPoint("LEFT", 10, 0)
    card.header:SetTextColor(unpack(self.GOLD))
    card.head = head
    card.rows = {}
    card.foot = Label(card, "tiny", "LEFT")
    card.foot:SetTextColor(Theme.Unpack("dim"))
    pcall(card.foot.SetWordWrap, card.foot, true)
    card.foot:SetWidth(self.CARD_WIDTH - 20)
    card:Hide()
    self.card = card
    return card
end

function Bar:CardRow(index)
    local card = self.card
    local row = card.rows[index]
    if row then return row end
    local Theme = ns.Theme
    row = CreateFrame("Frame", nil, card)
    row:SetHeight(self.CARD_ROW)
    row.back = Theme.Fill(row, index % 2 == 1 and "glass" or "glassAlt", 1)
    local line = row:CreateTexture(nil, "BORDER")
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(Theme.Unpack("border", 0.6))
    row.left = Label(row, "small", "LEFT")
    row.sub = Label(row, "tiny", "LEFT")
    row.sub:SetTextColor(Theme.Unpack("muted"))
    row.right = Label(row, "small", "RIGHT")
    row.right:SetTextColor(unpack(self.GOLD))
    row.right:SetPoint("RIGHT", -10, 0)
    card.rows[index] = row
    return row
end

function Bar:ShowCard()
    local read = self.read
    if not (read and self.frame) then return end
    local card = self:BuildCard()
    local lines = self:CardLines(read)
    card.header:SetText(lines.header)
    local TW = ns.Theme.TextWidth
    local width = math.max(self.CARD_WIDTH, TW("normal", lines.header) + 24)
    for _, r in ipairs(lines.rows) do
        local leftW = math.max(TW("small", r.left), TW("tiny", r.sub or ""))
        width = math.max(width, leftW + TW("small", r.right or "") + 36)
    end
    card:SetWidth(width)
    local y = -27
    for index, r in ipairs(lines.rows) do
        local row = self:CardRow(index)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", card, "TOPLEFT", 1, y)
        row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, y)
        row.left:ClearAllPoints()
        row.sub:ClearAllPoints()
        if r.sub then
            row.left:SetPoint("TOPLEFT", 10, -4)
            row.sub:SetPoint("TOPLEFT", row.left, "BOTTOMLEFT", 0, -2)
        else
            row.left:SetPoint("LEFT", 10, 0)
        end
        row.left:SetText(r.left)
        row.sub:SetText(r.sub or "")
        row.sub:SetShown(r.sub ~= nil)
        row.right:SetText(r.right or "")
        row:Show()
        y = y - self.CARD_ROW
    end
    for index = #lines.rows + 1, #card.rows do card.rows[index]:Hide() end
    card.foot:SetWidth(width - 20)
    card.foot:SetText(lines.foot)
    card.foot:ClearAllPoints()
    card.foot:SetPoint("TOPLEFT", card, "TOPLEFT", 10, y - 6)
    local footH = (card.foot.GetStringHeight and card.foot:GetStringHeight()) or 12
    if type(footH) ~= "number" then footH = 12 end
    card:SetHeight(-y + footH + 14)
    card:ClearAllPoints()
    card:SetPoint("TOP", self.frame, "BOTTOM", 0, -6)
    card:Show()
end

function Bar:HideCard()
    if self.card then self.card:Hide() end
end

--------------------------------------------------------------------------------
-- The level-up cheer
--------------------------------------------------------------------------------

function Bar:BuildCheer()
    if self.cheer then return self.cheer end
    local Theme = ns.Theme
    local cheer = CreateFrame("Frame", nil, UIParent)
    cheer:SetFrameStrata("HIGH")
    cheer:SetSize(320, 46)
    local glow = cheer:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture(GLOW_ART)
    pcall(glow.SetBlendMode, glow, "ADD")
    glow:SetPoint("CENTER")
    glow:SetSize(340, 70)
    glow:SetVertexColor(1, 0.8, 0.35)
    glow:SetAlpha(0.5)
    cheer.title = cheer:CreateFontString(nil, "OVERLAY")
    pcall(cheer.title.SetFont, cheer.title, Theme.FONT, Theme.sizes.title or 16, "OUTLINE")
    cheer.title:SetTextColor(unpack(self.GOLD))
    cheer.title:SetPoint("TOP", 0, -4)
    cheer.took = Label(cheer, "small", "CENTER")
    cheer.took:SetPoint("TOP", cheer.title, "BOTTOM", 0, -4)
    cheer:Hide()
    self.cheer = cheer
    return cheer
end

--- The text a level-up cheer shows: title and, when known, how long it took.
function Bar:CheerText(read, took)
    local title = L.Format("%s IS LEVEL %d", NameOf(read):upper(), read.level)
    local line = took and L.Format("Took %d min", ns.PetXP.Minutes(took)) or nil
    return title, line
end

function Bar:Cheer(read, took)
    if not (self:Cheers() and self.frame and self.frame:IsShown()) then return end
    local cheer = self:BuildCheer()
    local title, line = self:CheerText(read, took)
    cheer.title:SetText(title)
    cheer.took:SetText(line or "")
    cheer:ClearAllPoints()
    cheer:SetPoint("BOTTOM", self.frame, "TOP", 0, 6)
    cheer:SetAlpha(1)
    cheer:Show()
    self.cheerAt = (GetTime and GetTime()) or 0
    local Motion = ns.Motion
    local level = Level()
    if level ~= "off" and Motion and Motion.Run then
        local rise = level == "full" and 10 or 0
        Motion:Run(cheer, "in", 0.35, function(p)
            cheer:SetAlpha(p)
            cheer:ClearAllPoints()
            cheer:SetPoint("BOTTOM", Bar.frame, "TOP", 0, 6 - rise * (1 - p))
        end)
    end
    local stamp = self.cheerAt
    if C_Timer and C_Timer.After then
        C_Timer.After(self.CHEER_HOLD, function()
            if Bar.cheerAt ~= stamp then return end
            if Level() ~= "off" and Motion and Motion.Run then
                Motion:Run(cheer, "out", 0.6, function(p) cheer:SetAlpha(1 - p) end,
                    { done = function() cheer:Hide() end })
            else
                cheer:Hide()
            end
        end)
    end
end

--------------------------------------------------------------------------------
-- Reading
--------------------------------------------------------------------------------

--- Read and draw. Hides it when there is nothing to show.
function Bar:Refresh()
    local read = self:IsOn() and ns.PetXP and ns.PetXP:Read() or nil
    if not read then
        self.read = nil
        if self.frame then self.frame:Hide() end
        self:HideCard()
        return false
    end
    local _, leveled, took = ns.PetXP:Update(read)
    self.read = read
    local frame = self:Build()
    if not frame:IsShown() then
        self:Layout()
        self:Place()
        frame:Show()
    end
    self:Paint(read)
    if leveled then self:Cheer(read, took) end
    return true
end

function Bar:Soon()
    if self.pending then return end
    if not (C_Timer and C_Timer.After) then
        self:Refresh()
        return
    end
    self.pending = true
    C_Timer.After(self.SETTLE, function()
        Bar.pending = nil
        Bar:Refresh()
    end)
end

--------------------------------------------------------------------------------
-- Place
--------------------------------------------------------------------------------

function Bar:Spot()
    local x, y = ns.db and ns.db.petXPBarX, ns.db and ns.db.petXPBarY
    if type(x) == "number" and type(y) == "number" then return x, y end
    return nil
end

function Bar:Place()
    local frame = self.frame
    if not frame then return end
    frame:ClearAllPoints()
    local x, y = self:Spot()
    if x then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, self.FIRST_Y)
    end
end

function Bar:SaveSpot()
    local frame = self.frame
    if not (frame and ns.db) then return end
    local ok, left, bottom = pcall(function() return frame:GetLeft(), frame:GetBottom() end)
    if not (ok and type(left) == "number" and type(bottom) == "number") then return end
    ns.db.petXPBarX, ns.db.petXPBarY = left, bottom
    self:Place()
end

function Bar:Reset(quiet)
    if not ns.db then return end
    ns.db.petXPBarX, ns.db.petXPBarY = nil, nil
    self:Place()
    if not quiet then ns.Print(L["Pet XP bar is back in its first spot."]) end
end

--------------------------------------------------------------------------------
-- On and off
--------------------------------------------------------------------------------

local EVENTS = { "PET_UI_UPDATE", "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }
local PET_EVENTS = { "UNIT_PET_EXPERIENCE", "UNIT_PET", "UNIT_LEVEL" }

--- Listen only while it is turned on.
function Bar:Listen(on)
    if on and not self.listening then
        self.listening = true
        local function Look() Bar:Soon() end
        for _, event in ipairs(EVENTS) do ns.RegisterEvent(self, event, Look) end
        for _, event in ipairs(PET_EVENTS) do
            if ns.RegisterPetEvent then
                ns.RegisterPetEvent(self, event, Look)
            else
                ns.RegisterEvent(self, event, Look)
            end
        end
    elseif not on and self.listening then
        self.listening = nil
        if ns.UnregisterEvent then
            for _, event in ipairs(EVENTS) do ns.UnregisterEvent(self, event) end
            for _, event in ipairs(PET_EVENTS) do ns.UnregisterEvent(self, event) end
        end
    end
end

function Bar:Set(on)
    ns.db.petXPBar = on and true or false
    self:Listen(on)
    self:Refresh()
end

function Bar:OnEnable()
    if self:IsOn() then
        self:Listen(true)
        self:Soon()
    end
end

ns.RegisterCommand("xpbar", L["show your pet's XP on screen (on, off, reset)"], function(rest)
    local word = (rest or ""):lower():match("^%s*(%S*)")
    if word == "reset" then
        Bar:Reset()
        return
    end
    local on
    if word == "on" then
        on = true
    elseif word == "off" then
        on = false
    else
        on = not Bar:IsOn()
    end
    Bar:Set(on)
    if ns.SettingsUI and ns.SettingsUI.Refresh then pcall(ns.SettingsUI.Refresh, ns.SettingsUI) end
    ns.Print(on and L["Pet XP bar: on."] or L["Pet XP bar: off."])
end)
