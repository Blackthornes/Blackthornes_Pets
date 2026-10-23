-- Blackthornes Pets -- UI/MainWindow.lua
-- The pets window: the pet that is out and how it is doing. The hunter's
-- stable and the warlock's demons will join it here.
--
-- It is what a click on the minimap button and a bare /bpet open. Built like
-- the settings window (same header, palette and row heights) so the two read
-- as one set, and like Equipment's gear window, which is the same shape.

local _, ns = ...
local L = ns.L

local UI = ns.NewModule("UI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local PADDING = 18
-- From the window's top to the gold rule under the header row.
local HEADER = 44
-- The metal rim sits on the window's edge and reaches this far inward, with
-- room to spare (UI/Titanforged.lua).
local EDGE_PAD = 11
-- As wide as the other tabs (UI/PetsTabs.lua), so the window keeps its
-- size as the tabs are clicked.
local WIDTH = ns.PetsTabs and ns.PetsTabs.WIDTH or 820
-- Tall enough for a hunter's pet card: the top card, three bars and the
-- two cards under them, with room for a wrapped line or two. The window is
-- the other tabs' height when that is more, and the cards fill it.
local HEIGHT = 452

-- The pet card (the owner asked 2026-10-17, from a mockup): the pet on a
-- gold-edged card at the top, its experience, happiness and loyalty as bars
-- and lights, then two dark glass cards side by side, its food and how it
-- fights. A warlock's demon has no food card, so its fight card is the
-- whole width.
local GAP = 10
-- Tall enough for the name, the family and level line and the chips under
-- it, each on its own line (the chips once sat over the level line).
local HERO_HEIGHT = 76
local PORTRAIT = 46
local METER_HEIGHT = 24
local METER_X = 108
local METER_WIDTH = 190
local CARD_HEAD = 24
local CARD_ROW = 22
local BAND_HEIGHT = 46
-- The food line in the food card: the icon and its name.
local FOOD_LINE = 44
-- The space under the cards for the version and the footer.
local FOOT = 30
-- About how many hours of food fill the bar under it.
local FOOD_BAR_HOURS = 8

-- Loyalty's six levels, by the name C_PetInfo.GetPetLoyalty gives (it
-- gives no number). The German names are the classic client's; a name in
-- neither list shows as words alone, with no gems.
local LOYALTY_LEVELS = {
    { "rebellious", "rebellisch" },
    { "unruly", "widerspenstig", "aufsässig" },
    { "submissive", "unterwürfig" },
    { "dependable", "zuverlässig" },
    { "faithful", "treu", "loyal" },
    { "best friend", "bester freund" },
}

--- 1 to 6 for a loyalty name, or nil when it is not one we know.
function UI.LoyaltyLevel(name)
    if type(name) ~= "string" then return nil end
    local lower = name:lower()
    for level, names in ipairs(LOYALTY_LEVELS) do
        for _, known in ipairs(names) do
            if lower == known then return level end
        end
    end
    return nil
end

-- The status values, by key, and which card each one sits in. `rows` keeps
-- the label and value of every one, so the tests and the food check can read
-- what is shown.
local FOOD_ROWS = {
    { key = "foods", label = L["Eats"] },
}
local FIGHT_ROWS = {
    { key = "health", label = L["Health"] },
    { key = "speed", label = L["Attack speed"] },
    { key = "attackPower", label = L["Attack power"] },
    { key = "armor", label = L["Armor"] },
    { key = "resistances", label = L["Resistances"] },
}

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function UI:Build()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "BlackthornesPetsWindow", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    Theme.Fill(frame, "window")

    -- The house frame (UI/Titanforged.lua): a gold rim with corner gems, the
    -- paw in a round portrait, the name on a plate and a red close gem.
    if ns.Titanforged then
        local trim = ns.Titanforged:Dress(frame, {
            title = "Blackthornes Pets",
            portrait = true,
            close = function() UI:Hide() end,
        })
        self.trim = trim

        -- Kept on the screen whole: the portrait and plate reach out past
        -- the top left, and the corner gems past every edge.
        local left, right, top, bottom = ns.Titanforged.Reach(trim)
        if frame.SetClampRectInsets then
            frame:SetClampRectInsets(-left, right, top, -bottom)
        end
    else
        Theme.Border(frame, "borderLit")
    end

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        UI:SavePosition()
    end)

    -- The house size grip under the bottom right corner (Widgets.WindowGrip),
    -- saved as `windowScale`.
    self.sizeGrip = Widgets.WindowGrip(frame, "windowScale", function()
        UI:SavePosition()
    end)

    -- Escape closes it, like the game's own windows.
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsWindow")
    end

    self.frame = frame
    -- Pet, Compendium and Settings hang below it (UI/PetsTabs.lua).
    if ns.PetsTabs then ns.PetsTabs:Attach(self, "pet") end
    self:BuildHeader()

    local empty = Theme.CreateLabel(frame, "normal", "muted")
    empty:SetPoint("CENTER", 0, 0)
    empty:SetText(L["No pet out."])
    self.emptyLabel = empty

    self:BuildStatus()
    self:BuildFeedButton()
    self:WatchStats()

    -- The Feed button lives outside the window (see BuildFeedButton), so it
    -- has to be told when the window goes.
    frame:HookScript("OnHide", function() UI:PlaceFeedButton(nil) end)

    -- The installed version, small and faint in the bottom right corner,
    -- for every class, so a player can see at a glance which one they run.
    local version = Theme.CreateLabel(frame, "tiny", "dim", "RIGHT")
    version:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    version:SetText(ns.VersionLabel())
    self.versionLabel = version

    local footer = Theme.CreateLabel(frame, "small", "muted")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("BOTTOMRIGHT", version, "BOTTOMLEFT", -12, 0)
    self.footer = footer

    frame:Hide()
    return frame
end

--- The header row. The window's name is on the plate across the top edge
--- and the close gem sits on the top right corner (UI/Titanforged.lua), so
--- the row holds whose pets these are, clear of the portrait on the left.
--- Settings and the Compendium are tabs below the window now.
function UI:BuildHeader()
    local frame = self.frame

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", EDGE_PAD, -EDGE_PAD)
    header:SetPoint("TOPRIGHT", -EDGE_PAD, -EDGE_PAD)
    header:SetHeight(HEADER - EDGE_PAD)

    -- A gold rule under it, bright at the left and fading out to the right.
    local rule = header:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")
    rule:SetHeight(1)
    Theme.SetGradientAlpha(rule, "HORIZONTAL", "accent", 0.6, 0.05)

    -- Past the portrait, which reaches 48 pixels into the window.
    local subtitle = Theme.CreateLabel(header, "small", "muted")
    subtitle:SetPoint("LEFT", header, "LEFT", 48, -4)
    self.subtitle = subtitle
end

--------------------------------------------------------------------------------
-- The pet card's pieces
--------------------------------------------------------------------------------

--- A frame filled with a palette colour, with a fine border.
local function Glass(parent, key, borderAlpha)
    local frame = CreateFrame("Frame", nil, parent)
    frame.background = Theme.Fill(frame, key or "glass")
    if borderAlpha ~= false then Theme.Border(frame, "border", borderAlpha or 0.6) end
    return frame
end

--- A bar in a dark well: `bar:Set(fraction)` eases its fill there.
local function CreateBar(parent, colorKey, height)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(height or 12)
    bar.background = Theme.Fill(bar, "well")
    Theme.Border(bar, "border", 0.9)

    local fill = bar:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    fill:SetColorTexture(Theme.Unpack(colorKey))
    fill:SetWidth(1)
    bar.fill = fill

    -- A light along the top of the fill, so it reads as lit glass.
    local shine = bar:CreateTexture(nil, "OVERLAY")
    shine:SetPoint("TOPLEFT", fill, "TOPLEFT")
    shine:SetPoint("TOPRIGHT", fill, "TOPRIGHT")
    shine:SetHeight(math.max(math.floor((height or 12) / 2), 1))
    shine:SetColorTexture(1, 1, 1, 0.18)
    bar.shine = shine

    -- Fifths, like the game's own experience bar.
    for i = 1, 4 do
        local tick = bar:CreateTexture(nil, "OVERLAY", nil, 1)
        tick:SetPoint("TOP", bar, "TOPLEFT", 0, -1)
        tick:SetPoint("BOTTOM", bar, "BOTTOMLEFT", 0, 1)
        tick:SetWidth(1)
        tick:SetColorTexture(1, 1, 1, 0.08)
        tick.fifth = i
        bar["tick" .. i] = tick
    end

    Theme.Halo(bar, 4, 0, colorKey)

    -- Kept here rather than on the frame: the fill as drawn, where it is
    -- going, and how wide the bar is.
    local shown, target, barWidth = 0, nil, METER_WIDTH

    local function Draw(fraction)
        shown = fraction
        local inner = math.max(barWidth - 2, 1)
        fill:SetWidth(math.max(math.floor(inner * fraction + 0.5), 1))
        fill:SetShown(fraction > 0)
        shine:SetShown(fraction > 0)
    end

    function bar:Set(fraction)
        fraction = math.min(math.max(tonumber(fraction) or 0, 0), 1)
        -- The window redraws on every pet event, so a bar that has not moved
        -- is left as it is.
        if target == fraction then return end
        target = fraction
        Theme.SetHalo(self, fraction > 0 and 0.25 or 0)
        local from = shown
        if ns.Motion then
            ns.Motion:Run(self, "fill", 0.35, function(p)
                Draw(from + (fraction - from) * p)
            end)
        else
            Draw(fraction)
        end
    end

    --- Where the bar is going, 0 to 1, or nil before it is first set.
    function bar:Fraction() return target end

    function bar:SetBarWidth(width)
        barWidth = width
        self:SetWidth(width)
        for i = 1, 4 do
            local x = math.floor(width * i / 5)
            self["tick" .. i]:SetPoint("TOP", self, "TOPLEFT", x, -1)
            self["tick" .. i]:SetPoint("BOTTOM", self, "BOTTOMLEFT", x, 1)
        end
        Draw(shown)
    end

    return bar
end

--- A small rounded-off label in a dark well, with its edge in a colour.
local function CreateChip(parent)
    local chip = CreateFrame("Frame", nil, parent)
    chip:SetHeight(18)
    chip.background = Theme.Fill(chip, "well")
    Theme.Border(chip, "border")
    chip.label = Theme.CreateLabel(chip, "small", "text", "CENTER")
    chip.label:SetPoint("CENTER", 0, 0)

    function chip:Set(text, colorKey)
        self:SetShown(text ~= nil)
        if not text then return end
        self.label:SetText(text)
        self.label:SetTextColor(Theme.Unpack(colorKey or "text"))
        Theme.SetBorderColor(self, colorKey or "border", 0.8)
        self:SetWidth(Theme.TextWidth("small", text) + 16)
    end

    return chip
end

--- A heading strip for a card: a gold stripe down its left and the name in
--- capitals.
local function CardHeading(card, text)
    local head = CreateFrame("Frame", nil, card)
    head:SetPoint("TOPLEFT", 1, -1)
    head:SetPoint("TOPRIGHT", -1, -1)
    head:SetHeight(CARD_HEAD)
    Theme.Fill(head, "glass")
    Theme.AccentStripe(head, 3)
    local glow = head:CreateTexture(nil, "BORDER")
    glow:SetAllPoints(head)
    glow:SetColorTexture(1, 1, 1, 1)
    Theme.SetGradientAlpha(glow, "HORIZONTAL", "accent", 0.16, 0)
    local label = Theme.CreateLabel(head, "small", "accentHi")
    label:SetPoint("LEFT", 12, 0)
    label:SetText(text)
    head.label = label
    return head
end

--- A label and value line in a card, dark glass: it lights up under the
--- mouse with a gold edge, as every list in the house does.
local function CreateCardRow(card, labelText)
    local row = CreateFrame("Frame", nil, card)
    row.background = Theme.Fill(row, "glass")
    local line = row:CreateTexture(nil, "BORDER")
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(Theme.Unpack("border", 0.6))
    local edge = row:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT")
    edge:SetPoint("BOTTOMLEFT")
    edge:SetWidth(2)
    edge:SetColorTexture(Theme.Unpack("accentHi"))
    edge:Hide()

    row.label = Theme.CreateLabel(row, "small", "muted")
    row.label:SetPoint("TOPLEFT", 10, -5)
    row.label:SetText(labelText)
    row.value = Theme.CreateLabel(row, "normal", "text", "RIGHT")
    row.value:SetPoint("TOPRIGHT", -10, -4)
    row.value:SetWordWrap(true)

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self.background:SetColorTexture(Theme.Unpack("glassHover"))
        edge:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.background:SetColorTexture(Theme.Unpack(self.glassKey or "glass"))
        edge:Hide()
    end)
    return row
end

--- Lay a card's rows out from `y` down, hiding those with nothing to say
--- and taking turns light and dark. A value too long for its line wraps and
--- pushes the rows below down. Returns where the last row ended.
local function LayRows(card, rows, specs, values, y, width)
    local place = 0
    for _, spec in ipairs(specs) do
        local row = rows[spec.key]
        local text = values[spec.key]
        row:SetShown(text ~= nil)
        if text then
            place = place + 1
            row.glassKey = place % 2 == 1 and "glass" or "glassAlt"
            row.background:SetColorTexture(Theme.Unpack(row.glassKey))
            row.value:SetText(text)
            row.value:SetWidth(math.max(width - Theme.TextWidth("small", spec.label) - 34, 60))
            local height = CARD_ROW
            local ok, textHeight = pcall(row.value.GetStringHeight, row.value)
            if ok and type(textHeight) == "number" and textHeight + 9 > height then
                height = math.ceil(textHeight + 9)
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", card, "TOPLEFT", 1, y)
            row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, y)
            row:SetHeight(height)
            y = y - height
        end
    end
    return y
end

function UI:BuildStatus()
    local frame = self.frame
    self.rows = {}

    -- Everything about the pet, so it all goes at once when none is out.
    local body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT", PADDING, -(HEADER + GAP))
    body:SetPoint("BOTTOMRIGHT", -PADDING, FOOT)
    self.body = body
    local inner = WIDTH - PADDING * 2

    -- The top card: the pet's face, name, family and level, gold in the
    -- dark with a bright gold edge, as the open row is everywhere else.
    local hero = Glass(body, "glassActive", 0.8)
    hero:SetPoint("TOPLEFT")
    hero:SetPoint("TOPRIGHT")
    hero:SetHeight(HERO_HEIGHT)
    local edge = hero:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT")
    edge:SetPoint("BOTTOMLEFT")
    edge:SetWidth(3)
    edge:SetColorTexture(Theme.Unpack("accentHi"))
    local wash = hero:CreateTexture(nil, "BORDER")
    wash:SetAllPoints(hero)
    wash:SetColorTexture(1, 1, 1, 1)
    Theme.SetGradientAlpha(wash, "HORIZONTAL", "accent", 0.14, 0)
    Theme.Halo(hero, 6, 0.10, "accent")
    self.hero = hero

    local portrait = CreateFrame("Frame", nil, hero)
    portrait:SetSize(PORTRAIT, PORTRAIT)
    portrait:SetPoint("LEFT", 12, 0)
    Theme.Fill(portrait, "well")
    Theme.Border(portrait, "accent")
    Theme.Halo(portrait, 4, 0.25, "accent")
    local face = portrait:CreateTexture(nil, "ARTWORK")
    face:SetPoint("TOPLEFT", 1, -1)
    face:SetPoint("BOTTOMRIGHT", -1, 1)
    self.portrait = face

    local badge = CreateFrame("Frame", nil, portrait)
    badge:SetSize(22, 16)
    badge:SetPoint("CENTER", portrait, "BOTTOMRIGHT", -2, 2)
    badge:SetFrameLevel(portrait:GetFrameLevel() + 2)
    Theme.Fill(badge, "well")
    Theme.Border(badge, "accent")
    local level = Theme.CreateLabel(badge, "tiny", "accentHi", "CENTER")
    level:SetPoint("CENTER", 0, 0)
    self.levelBadge, self.levelLabel = badge, level

    local name = Theme.CreateLabel(hero, "title", "accentHi")
    name:SetPoint("TOPLEFT", hero, "TOPLEFT", 12 + PORTRAIT + 14, -11)
    name:SetPoint("RIGHT", hero, "RIGHT", -12, 0)
    self.nameLabel = name

    local sub = Theme.CreateLabel(hero, "small", "muted")
    sub:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    sub:SetPoint("RIGHT", hero, "RIGHT", -12, 0)
    self.rows.pet = { value = sub }

    self.moodChip = CreateChip(hero)
    self.moodChip:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -5)
    self.trainingChip = CreateChip(hero)
    self.trainingChip:SetPoint("LEFT", self.moodChip, "RIGHT", 6, 0)
    self.rows.training = { value = self.trainingChip.label }
    -- The whole count under the mouse: free, total and spent.
    self.trainingChip:EnableMouse(true)
    self.trainingChip:SetScript("OnEnter", function(chip)
        if not (chip.detail and GameTooltip) then return end
        GameTooltip:SetOwner(chip, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(L["Training points"], 1, 0.82, 0)
        GameTooltip:AddLine(chip.detail, 1, 1, 1)
        GameTooltip:Show()
    end)
    self.trainingChip:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    -- The three bars: experience, happiness and loyalty, a label on the
    -- left and the words on the right.
    self.meters = {}
    local function Meter(key, labelText)
        local meter = CreateFrame("Frame", nil, body)
        meter:SetHeight(METER_HEIGHT)
        meter.label = Theme.CreateLabel(meter, "small", "muted")
        meter.label:SetPoint("LEFT", 4, 0)
        meter.label:SetText(labelText)
        meter.value = Theme.CreateLabel(meter, "normal", "text")
        meter.value:SetPoint("LEFT", METER_X + METER_WIDTH + 12, 0)
        meter.value:SetPoint("RIGHT", meter, "RIGHT", -4, 0)
        self.meters[key] = meter
        self.rows[key] = meter
        return meter
    end

    local xp = Meter("experience", L["Experience"])
    local bar = CreateBar(xp, "xp", 12)
    bar:SetPoint("LEFT", METER_X, 0)
    bar:SetBarWidth(METER_WIDTH)
    xp.bar = bar

    -- Happiness: three lights, as many lit as the pet is happy, in its colour.
    local mood = Meter("happiness", L["Happiness"])
    mood.lights = {}
    local lightWidth = math.floor((METER_WIDTH - 8) / 3)
    for i = 1, 3 do
        local light = CreateFrame("Frame", nil, mood)
        light:SetSize(lightWidth, 12)
        light:SetPoint("LEFT", METER_X + (i - 1) * (lightWidth + 4), 0)
        light.background = Theme.Fill(light, "well")
        Theme.Border(light, "border", 0.9)
        light.shine = Theme.TopSheen(light, 0.12)
        Theme.Halo(light, 4, 0, "good")
        mood.lights[i] = light
    end

    -- Loyalty: six gold gems, as many lit as its level.
    local loyalty = Meter("loyalty", L["Loyalty"])
    loyalty.gems = {}
    for i = 1, 6 do
        local gem = loyalty:CreateTexture(nil, "ARTWORK")
        gem:SetSize(10, 10)
        gem:SetPoint("LEFT", METER_X + 3 + (i - 1) * 20, 0)
        gem:SetColorTexture(Theme.Unpack("border"))
        if gem.SetRotation then pcall(gem.SetRotation, gem, math.pi / 4) end
        loyalty.gems[i] = gem
    end

    -- The two cards.
    local cardWidth = math.floor((inner - GAP) / 2)
    self.cardWidth, self.fullWidth = cardWidth, inner

    local food = Glass(body, "glassAlt")
    food:SetWidth(cardWidth)
    CardHeading(food, L["FOOD"])
    self.foodCard = food

    local line = CreateFrame("Frame", nil, food)
    line:SetPoint("TOPLEFT", 1, -(CARD_HEAD + 1))
    line:SetPoint("TOPRIGHT", -1, -(CARD_HEAD + 1))
    line:SetHeight(FOOD_LINE)
    Theme.Fill(line, "glass")
    local underline = line:CreateTexture(nil, "BORDER")
    underline:SetPoint("BOTTOMLEFT")
    underline:SetPoint("BOTTOMRIGHT")
    underline:SetHeight(1)
    underline:SetColorTexture(Theme.Unpack("border", 0.6))
    local slot = CreateFrame("Frame", nil, line)
    slot:SetSize(32, 32)
    slot:SetPoint("LEFT", 10, 0)
    Theme.Fill(slot, "well")
    Theme.Border(slot, "metal")
    local icon = slot:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    local count = Theme.CreateLabel(slot, "small", "text", "RIGHT")
    count:SetPoint("BOTTOMRIGHT", -2, 2)
    if count.SetShadowColor then
        count:SetShadowColor(0, 0, 0, 1)
        count:SetShadowOffset(1, -1)
    end
    local foodName = Theme.CreateLabel(line, "normal", "text")
    foodName:SetPoint("TOPLEFT", slot, "TOPRIGHT", 10, -2)
    foodName:SetPoint("RIGHT", line, "RIGHT", -8, 0)
    local foodSub = Theme.CreateLabel(line, "small", "muted")
    foodSub:SetPoint("TOPLEFT", foodName, "BOTTOMLEFT", 0, -3)
    foodSub:SetPoint("RIGHT", line, "RIGHT", -8, 0)
    self.foodIcon, self.foodCount, self.foodName = icon, count, foodName
    self.rows.food = { value = foodSub }

    -- How long the food lasts, as a gold bar and the words under it.
    local lasts = CreateFrame("Frame", nil, food)
    lasts:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, 0)
    lasts:SetPoint("TOPRIGHT", line, "BOTTOMRIGHT", 0, 0)
    lasts:SetHeight(34)
    Theme.Fill(lasts, "glassAlt")
    local lastsBar = CreateBar(lasts, "accent", 8)
    lastsBar:SetPoint("TOPLEFT", 10, -7)
    lastsBar:SetBarWidth(cardWidth - 22)
    local lastsText = Theme.CreateLabel(lasts, "small", "muted")
    lastsText:SetPoint("TOPLEFT", lastsBar, "BOTTOMLEFT", 0, -4)
    lastsText:SetPoint("RIGHT", lasts, "RIGHT", -10, 0)
    self.lasts, self.lastsBar, self.lastsText = lasts, lastsBar, lastsText

    self.foodRows = {}
    for _, spec in ipairs(FOOD_ROWS) do
        local row = CreateCardRow(food, spec.label)
        self.foodRows[spec.key] = row
        self.rows[spec.key] = row
    end

    -- How it fights: damage a second and a hit large, the rest in rows.
    local fight = Glass(body, "glassAlt")
    CardHeading(fight, L["IN A FIGHT"])
    self.fightCard = fight

    local band = CreateFrame("Frame", nil, fight)
    band:SetPoint("TOPLEFT", 1, -(CARD_HEAD + 1))
    band:SetPoint("TOPRIGHT", -1, -(CARD_HEAD + 1))
    band:SetHeight(BAND_HEIGHT)
    Theme.Fill(band, "glass")
    local bandLine = band:CreateTexture(nil, "BORDER")
    bandLine:SetPoint("BOTTOMLEFT")
    bandLine:SetPoint("BOTTOMRIGHT")
    bandLine:SetHeight(1)
    bandLine:SetColorTexture(Theme.Unpack("border", 0.6))
    local function Big(anchorX)
        local number = Theme.CreateLabel(band, "title", "text")
        number:SetPoint("TOPLEFT", anchorX, -7)
        local caption = Theme.CreateLabel(band, "tiny", "muted")
        caption:SetPoint("TOPLEFT", number, "BOTTOMLEFT", 0, -3)
        return number, caption
    end
    self.dpsNumber, self.dpsCaption = Big(12)
    self.hitNumber, self.hitCaption = Big(12)
    self.dpsCaption:SetText(L["Damage a second"])
    self.hitCaption:SetText(L["Damage a hit"])
    self.band = band
    -- Kept under its old name too: the damage line as a whole.
    self.rows.damage = { value = self.hitNumber }

    self.fightRows = {}
    for _, spec in ipairs(FIGHT_ROWS) do
        local row = CreateCardRow(fight, spec.label)
        self.fightRows[spec.key] = row
        self.rows[spec.key] = row
    end

    self:BuildSkills()
end

--------------------------------------------------------------------------------
-- The skills card
--
-- A hunter's pet only (a player asked, the owner said build it from a
-- mockup, 2026-10-22): under the food and fight cards, what the pet knows,
-- what it can learn now and what comes later (Logic/PetSkills.lua), and the
-- nearest pet trainer with Show the Way. The window grows to fit it.
--------------------------------------------------------------------------------

local SKILL_HEAD = 20
local SKILL_ROW = 22
local SKILL_FOOT = 34

--- A section's heading inside the card: its name on the left and what the
--- right column says.
local function SkillHeading(card, left, right)
    local head = CreateFrame("Frame", nil, card)
    head:SetHeight(SKILL_HEAD)
    local name = Theme.CreateLabel(head, "tiny", "muted")
    name:SetPoint("LEFT", 12, -1)
    name:SetText(left)
    local value = Theme.CreateLabel(head, "tiny", "muted", "RIGHT")
    value:SetPoint("RIGHT", -10, -1)
    value:SetText(right)
    return head
end

--- A skill line: dark glass, the skill on the left and its rank, cost or
--- when on the right. A beast skill lights up under the mouse and opens the
--- Compendium on the beasts that teach it.
local function CreateSkillRow(card)
    local row = CreateFrame("Button", nil, card)
    row:SetHeight(SKILL_ROW)
    row.background = Theme.Fill(row, "glass")
    local line = row:CreateTexture(nil, "BORDER")
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    line:SetHeight(1)
    line:SetColorTexture(Theme.Unpack("border", 0.6))
    local edge = row:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT")
    edge:SetPoint("BOTTOMLEFT")
    edge:SetWidth(2)
    edge:SetColorTexture(Theme.Unpack("accentHi"))
    edge:Hide()
    row.value = Theme.CreateLabel(row, "small", "text", "RIGHT")
    row.value:SetPoint("RIGHT", -10, 0)
    row.label = Theme.CreateLabel(row, "normal", "text")
    row.label:SetPoint("LEFT", 12, 0)
    row.label:SetPoint("RIGHT", row.value, "LEFT", -10, 0)
    row.label:SetWordWrap(false)

    row:SetScript("OnEnter", function(self)
        self.background:SetColorTexture(Theme.Unpack("glassHover"))
        edge:Show()
        if self.beast and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.beast, Theme.Unpack("accent"))
            GameTooltip:AddLine(L["Click to see the beasts that teach it."], 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.background:SetColorTexture(Theme.Unpack(self.glassKey or "glass"))
        edge:Hide()
        if GameTooltip then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick", function(self)
        if self.beast then UI:ShowBeastsFor(self.beast) end
    end)
    return row
end

function UI:BuildSkills()
    local card = Glass(self.body, "glassAlt")
    CardHeading(card, L["SKILLS"])
    card:Hide()
    self.skillsCard = card
    self.skillHeads = {
        known = SkillHeading(card, L["YOUR PET KNOWS"], L["RANK"]),
        learn = SkillHeading(card, L["CAN LEARN NOW"], L["COST"]),
        later = SkillHeading(card, L["LATER"], L["WHEN"]),
    }
    self.skillRows = {}

    local foot = CreateFrame("Frame", nil, card)
    foot:SetHeight(SKILL_FOOT)
    Theme.Fill(foot, "glass")
    local way = Widgets.CreateButton(foot, L["Show the Way"], function() UI:ShowTheWayToTrainer() end,
        { primary = true, width = 100, height = 22 })
    way:SetPoint("RIGHT", -8, 0)
    local trainer = Theme.CreateLabel(foot, "small", "muted")
    trainer:SetPoint("LEFT", 12, 0)
    trainer:SetPoint("RIGHT", way, "LEFT", -10, 0)
    trainer:SetWordWrap(false)
    self.skillFoot, self.skillWay, self.skillTrainer = foot, way, trainer
end

--- Skills a beast teaches when tamed: those a click looks up in the
--- Compendium.
function UI.IsBeastSkill(name)
    if not UI.beastSkillNames then
        UI.beastSkillNames = {}
        for _, skill in pairs(ns.BeastSkills and ns.BeastSkills.SKILLS or {}) do
            UI.beastSkillNames[skill.name] = true
        end
    end
    return UI.beastSkillNames[name] == true
end

--- The words on a skill line: { label, value, beast } for each line of a
--- plan's section. `beast` is set for a skill taming teaches.
function UI.SkillLines(plan, section)
    local muted = ns.COLORS.muted
    local out = {}
    for _, skill in ipairs(plan[section] or {}) do
        local name = L.Format("%s Rank %d", skill.name, skill.rank)
        local label, value = name, nil
        if section == "known" then
            value = L.Format("Rank %d", skill.rank)
            label = skill.name
        elseif section == "learn" then
            local from = skill.from == "hunter" and L["from your Beast Training"] or L["from a pet trainer"]
            label = ("%s |c%s\194\183 %s|r"):format(name, muted, from)
            if skill.cost then
                value = skill.cost == 1 and L.Format("%d point", skill.cost) or L.Format("%d points", skill.cost)
            end
        else
            value = skill.level and L.Format("Pet level %d", skill.level) or L["Tame a beast that knows it"]
        end
        out[#out + 1] = { label = label, value = value or "", beast = UI.IsBeastSkill(skill.name) and skill.name or nil,
            muted = section == "later" }
    end
    return out
end

--- Lay the skills card out from `top` (below the cards above it). Returns
--- how tall it is, or nil when it has nothing to show and is hidden.
function UI:ShowSkills(plan, trainer, top)
    local card = self.skillsCard
    local any = plan and (#plan.known + #plan.learn + #plan.later > 0)
    if not (any or trainer) then
        card:Hide()
        return nil
    end
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, top)
    card:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, top)
    card:Show()

    local y, used = -(CARD_HEAD + 1), 0
    for _, section in ipairs({ "known", "learn", "later" }) do
        local head = self.skillHeads[section]
        local lines = plan and UI.SkillLines(plan, section) or {}
        head:SetShown(#lines > 0)
        if #lines > 0 then
            head:ClearAllPoints()
            head:SetPoint("TOPLEFT", card, "TOPLEFT", 1, y)
            head:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, y)
            y = y - SKILL_HEAD
            for index, line in ipairs(lines) do
                used = used + 1
                local row = self.skillRows[used]
                if not row then
                    row = CreateSkillRow(card)
                    self.skillRows[used] = row
                end
                row.glassKey = index % 2 == 1 and "glass" or "glassAlt"
                row.background:SetColorTexture(Theme.Unpack(row.glassKey))
                row.label:SetText(line.label)
                row.value:SetText(line.value)
                row.value:SetTextColor(Theme.Unpack(line.muted and "muted" or "text"))
                row.beast = line.beast
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 1, y)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, y)
                row:Show()
                y = y - SKILL_ROW
            end
        end
    end
    for i = used + 1, #self.skillRows do self.skillRows[i]:Hide() end

    self.skillTrainerPlace = trainer
    self.skillFoot:SetShown(trainer ~= nil)
    if trainer then
        self.skillTrainer:SetText(L.Format("Pet trainer: %s", ("%s, %s"):format(trainer.name, trainer.zone)))
        self.skillFoot:ClearAllPoints()
        self.skillFoot:SetPoint("TOPLEFT", card, "TOPLEFT", 1, y - 2)
        self.skillFoot:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, y - 2)
        y = y - 2 - SKILL_FOOT
    end
    return -y + 2
end

--- Show the Way: the beast arrow points at the nearest pet trainer.
function UI:ShowTheWayToTrainer()
    local trainer = self.skillTrainerPlace or (ns.PetSkills and ns.PetSkills:Trainer())
    if trainer and ns.BeastArrow then ns.BeastArrow:FollowPlace(trainer) end
end

--- A click on a beast skill: the Compendium, searching for that skill.
function UI:ShowBeastsFor(name)
    local window = ns.CompendiumUI
    if not (window and window.ShowSearch) then return end
    window:ShowSearch(name)
end

--- The Feed button. It is a secure action button, because casting Feed Pet
--- is protected, and it belongs to UIParent rather than to this window: a
--- window holding a secure button cannot be closed or moved in combat. It is
--- anchored over the window only while out of combat, and let go of as
--- combat starts, which PLAYER_REGEN_DISABLED fires just before.
function UI:BuildFeedButton()
    local button = Widgets.CreateButton(UIParent, L["Feed"], nil, {
        name = "BlackthornesPetsFeedButton",
        template = "SecureActionButtonTemplate",
        primary = true,
        width = 90,
        height = 22,
    })
    -- A layer above the window's own. On the same layer, the window rises
    -- over the button whenever it is opened or clicked, since the game
    -- brings a toplevel window to the front.
    button:SetFrameStrata("FULLSCREEN_DIALOG")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:Hide()
    self.feedButton = button

    ns.RegisterEvent(self, "PLAYER_REGEN_DISABLED", function() UI:PlaceFeedButton(nil, true) end)
end

-- The pet's speed, damage and the rest move with buffs, which come in
-- bursts, so one redraw follows a moment after the last of them, and only
-- while the window is up.
local STAT_SETTLE = 0.2

function UI:WatchStats()
    local function Soon()
        if not (UI.frame and UI.frame:IsShown()) or UI.statsPending then return end
        if not (C_Timer and C_Timer.After) then return pcall(UI.Refresh, UI) end
        UI.statsPending = true
        C_Timer.After(STAT_SETTLE, function()
            UI.statsPending = nil
            pcall(UI.Refresh, UI)
        end)
    end
    for _, event in ipairs({
        "UNIT_ATTACK_SPEED", "UNIT_DAMAGE", "UNIT_ATTACK_POWER", "UNIT_RESISTANCES",
        "UNIT_MAXHEALTH", "UNIT_STATS",
    }) do
        ns.RegisterPetEvent(self, event, function(_, _, unit)
            if unit == nil or unit == "pet" then Soon() end
        end)
    end
end

local function InCombat()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    return ok and locked == true
end

--- Point the Feed button at a stack of food and put it over the window, or,
--- with no stack, take it away. Does nothing in combat, when the game will
--- not allow it, unless `beforeCombat` says combat is only about to start.
function UI:PlaceFeedButton(stack, beforeCombat)
    local button = self.feedButton
    if not button then return end
    if InCombat() and not beforeCombat then return end

    if stack and self.frame and self.frame:IsShown() and not UI.Covered() then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", ns.Food:FeedMacro(stack))
        -- Plain on the gold face: a rarity colour would not read on it.
        -- The food card above names it in its colour.
        button:SetText(L.Format("Feed %s", stack.name))
        button:ClearAllPoints()
        -- At the foot of the food card, where the food is.
        button:SetPoint("BOTTOMRIGHT", self.foodCard or self.frame, "BOTTOMRIGHT", -8, 8)
        button:SetFrameLevel(self.frame:GetFrameLevel() + 10)
        button:Show()
        self.feedStack = stack
    else
        button:Hide()
        button:ClearAllPoints()
        button:SetAttribute("macrotext", nil)
        self.feedStack = nil
    end
    self:PlaceVersion()
end

--- The version stays in the corner, under the cards. The Feed button sits
--- inside the food card now, so it no longer covers it.
function UI:PlaceVersion()
    local version = self.versionLabel
    if not version then return end
    version:ClearAllPoints()
    version:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -PADDING, 12)
end

--- Is the Settings window or the Pet Compendium open? The Feed button sits
--- a layer above every window, so it is put away while either is up, or it
--- would show through them and take their clicks.
function UI.Covered()
    for _, window in ipairs({ ns.SettingsUI, ns.CompendiumUI }) do
        local frame = window and rawget(window, "frame")
        if frame then
            local ok, shown = pcall(frame.IsShown, frame)
            if ok and shown then return true end
        end
    end
    return false
end

--- Settings and the Compendium tell the pets window when they open or
--- close, so the Feed button goes and comes back with them.
function UI:WatchCover(frame)
    if not (frame and frame.HookScript) then return end
    local function Again()
        if UI.frame and UI.frame:IsShown() then pcall(UI.Refresh, UI) end
    end
    frame:HookScript("OnShow", Again)
    frame:HookScript("OnHide", Again)
end

--- One line on where the Feed button is, for /bpet food.
function UI:FeedButtonState()
    local button = self.feedButton
    if not button then return "the Feed button was not built" end
    local ok, text = pcall(function()
        local shown = button:IsShown() and "shown" or "hidden"
        local visible = button:IsVisible() and "visible" or "not visible"
        return ("Feed button %s, %s, layer %s %s, window %s %s"):format(shown, visible,
            tostring(button:GetFrameStrata()), tostring(button:GetFrameLevel()),
            self.frame and tostring(self.frame:GetFrameStrata()) or "-",
            self.frame and tostring(self.frame:GetFrameLevel()) or "-")
    end)
    return ok and text or "could not read the Feed button"
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

-- The palette key for each happiness level's colour (PetStatus names them
-- by the shared colours, where "bad" is the window's "loss").
local function MoodColor(level)
    local info = level and ns.PetStatus.HAPPINESS[level]
    if not info then return nil end
    return info.color == "bad" and "loss" or info.color
end

--- The top card: the pet's face, name, family, level and the two chips.
function UI:ShowHero(status)
    local PetStatus = ns.PetStatus
    self.nameLabel:SetText(status.name or L["Your pet"])

    local sub
    local family = status.family ~= status.name and status.family or nil
    if family and status.level then
        sub = L.Format("%s, level %s", family, status.level)
    elseif family then
        sub = family
    elseif status.level then
        sub = L.Format("Level %s", status.level)
    end
    self.rows.pet.value:SetText(sub or "")

    self.levelBadge:SetShown(status.level ~= nil)
    if status.level then self.levelLabel:SetText(tostring(status.level)) end

    if type(SetPortraitTexture) == "function" then
        pcall(SetPortraitTexture, self.portrait, "pet")
    end

    local mood = status.happiness and PetStatus.HAPPINESS[status.happiness]
    self.moodChip:Set(mood and mood.name or nil, MoodColor(status.happiness))

    local free = status.trainingFree
    local chip
    if free and status.trainingTotal and (status.trainingTotal > 0 or status.trainingSpent > 0) then
        if free < 0 then
            chip = { L.Format("%d training points over", -free), "loss" }
        elseif free == 1 then
            chip = { L["1 training point free"], "good" }
        else
            chip = { L.Format("%d training points free", free), free > 0 and "good" or "muted" }
        end
    end
    self.trainingChip:Set(chip and chip[1] or nil, chip and chip[2] or nil)
    self.trainingChip.detail = PetStatus:TrainingText(status)
    if not chip then self.trainingChip.label:Hide() else self.trainingChip.label:Show() end
    -- With no happiness, the training chip moves up to its place.
    self.trainingChip:ClearAllPoints()
    if mood then
        self.trainingChip:SetPoint("LEFT", self.moodChip, "RIGHT", 6, 0)
    else
        self.trainingChip:SetPoint("TOPLEFT", self.rows.pet.value, "BOTTOMLEFT", 0, -5)
    end
end

--- The bars under the top card, stacked from `y`, the ones with nothing to
--- say left out. Returns where the last one ended.
function UI:ShowMeters(status, y)
    local PetStatus = ns.PetStatus
    local values = {
        experience = PetStatus:ExperienceText(status),
        happiness = PetStatus:HappinessText(status),
        loyalty = PetStatus:LoyaltyText(status),
    }

    for _, key in ipairs({ "experience", "happiness", "loyalty" }) do
        local meter = self.meters[key]
        local text = values[key]
        meter:SetShown(text ~= nil)
        meter.value:SetShown(text ~= nil)
        if text then
            meter.value:SetText(text)
            meter:ClearAllPoints()
            meter:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, y)
            meter:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, y)
            y = y - METER_HEIGHT
        end
    end

    if values.experience then
        self.meters.experience.bar:Set(status.xp / status.xpMax)
    end

    if values.happiness then
        local key = MoodColor(status.happiness)
        for i, light in ipairs(self.meters.happiness.lights) do
            local lit = i <= status.happiness
            light.background:SetColorTexture(Theme.Unpack(lit and key or "well"))
            Theme.SetHalo(light, lit and 0.3 or 0, key)
            light.shine:SetShown(lit)
        end
    end

    if values.loyalty then
        local level = UI.LoyaltyLevel(status.loyalty)
        for i, gem in ipairs(self.meters.loyalty.gems) do
            gem:SetShown(level ~= nil)
            gem:SetColorTexture(Theme.Unpack(level and i <= level and "accentHi" or "border"))
        end
        -- With no gems to show, the words take their place.
        self.meters.loyalty.value:ClearAllPoints()
        self.meters.loyalty.value:SetPoint("LEFT", level and METER_X + METER_WIDTH + 12 or METER_X, 0)
        self.meters.loyalty.value:SetPoint("RIGHT", self.meters.loyalty, "RIGHT", -4, 0)
    end
    return y
end

--- The food card: the food it eats next, how long the bags will keep it
--- happy, and what it eats. Returns the stacks, best first.
function UI:ShowFood(status, top)
    local card = self.foodCard
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, top)
    card:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 0, 0)
    card:SetWidth(self.cardWidth)

    -- The kept scan, unless the bags changed: this runs on every pet event
    -- and the status check while the window is open.
    local stacks = ns.Food:Latest(status)
    local best = stacks[1]
    local total = ns.Food:Count(stacks)
    self.foodIcon:SetShown(best ~= nil)
    if best then
        local icon = ItemIcon(best.itemID)
        if icon then self.foodIcon:SetTexture(icon) end
        self.foodCount:SetText(tostring(total))
        self.foodName:SetText(ns.Food.ShownName(best))
        local sub = L.Format("%d in your bags (%s)", total, ns.Food:EffectLabel(best.effect))
        if total < ns.Food.LOW_FOOD then
            sub = sub .. (", |c%s%s|r"):format(ns.COLORS.warn, L["running low"])
        end
        self.rows.food.value:SetText(sub)
    else
        self.foodCount:SetText("")
        self.foodName:SetText(L["No food"])
        self.rows.food.value:SetText(("|c%s%s|r"):format(ns.COLORS.bad, L["None in your bags"]))
    end

    local hours = ns.Butler and ns.Butler.Hours and ns.Butler.Hours(stacks)
    local y = -(CARD_HEAD + 1 + FOOD_LINE)
    self.lasts:SetShown(hours ~= nil)
    if hours then
        self.lastsBar:Set(hours / FOOD_BAR_HOURS)
        if hours >= 0.1 then
            self.lastsText:SetText(L.Format("Enough food for about %.1f hours", hours))
            self.lastsText:SetTextColor(Theme.Unpack("muted"))
        else
            self.lastsText:SetText(L["Not enough food to keep it happy"])
            self.lastsText:SetTextColor(Theme.Unpack("loss"))
        end
        y = y - 34
    end

    y = LayRows(card, self.foodRows, FOOD_ROWS, { foods = ns.PetStatus:FoodText(status) },
        y, self.cardWidth - 2)
    return stacks, y
end

--- The fight card: damage a second and a hit large, then the rest.
function UI:ShowFight(stats, top, full)
    local PetStatus = ns.PetStatus
    local card = self.fightCard
    local width = full and self.fullWidth or self.cardWidth
    card:ClearAllPoints()
    if full then
        card:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, top)
    else
        card:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, top)
    end
    card:SetWidth(width)
    card:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", 0, 0)

    local y = -(CARD_HEAD + 1)
    local hasHit = stats.damageMin ~= nil
    self.band:SetShown(hasHit)
    if hasHit then
        local hasDps = stats.dps ~= nil
        self.dpsNumber:SetShown(hasDps)
        self.dpsCaption:SetShown(hasDps)
        if hasDps then self.dpsNumber:SetText(("%.1f"):format(stats.dps)) end
        self.hitNumber:SetText(L.Format("%d to %d", stats.damageMin, stats.damageMax))
        self.hitNumber:ClearAllPoints()
        self.hitNumber:SetPoint("TOPLEFT", self.band, "TOPLEFT",
            hasDps and math.floor(width / 2) or 12, -7)
        y = y - BAND_HEIGHT
    end

    return LayRows(card, self.fightRows, FIGHT_ROWS, {
        health = PetStatus:HealthText(stats),
        speed = PetStatus:SpeedText(stats),
        attackPower = PetStatus:AttackPowerText(stats),
        armor = PetStatus:ArmorText(stats),
        resistances = PetStatus:ResistanceText(stats),
    }, y, width - 2)
end

--- Fill the pet card from a PetStatus reading: everything with nothing to
--- say is left out, and what is left closes up.
function UI:ShowStatus(status)
    self.body:SetShown(status.exists == true)
    self.emptyLabel:SetShown(not status.exists)
    self.rows.pet.value:SetShown(status.exists == true)
    if not status.exists then
        self:PlaceFeedButton(nil)
        return
    end

    self:ShowHero(status)
    local y = self:ShowMeters(status, -(HERO_HEIGHT + GAP))
    if y < -(HERO_HEIGHT + GAP) then y = y - GAP + 4 end

    local stats = ns.PetStatus:ReadStats()
    local stacks, foodEnd, fightEnd
    if status.foods then
        self.foodCard:Show()
        stacks, foodEnd = self:ShowFood(status, y)
        fightEnd = self:ShowFight(stats, y, false)
    else
        self.foodCard:Hide()
        fightEnd = self:ShowFight(stats, y, true)
    end
    self:ShowSkillsUnder(y, stacks and stacks[1], foodEnd, fightEnd)
    self:PlaceFeedButton(stacks and stacks[1] or nil)
end

--- The skills card under the food and fight cards. With it, the two cards
--- are as tall as the fuller of them, the skills card fills what is left
--- and the window grows to fit, never below its usual height. Without it,
--- the cards fill the window as they always have.
function UI:ShowSkillsUnder(top, feeding, foodEnd, fightEnd)
    local plan = ns.PetSkills and ns.PetSkills:Current()
    local trainer = plan and ns.PetSkills:Trainer()
    if not (plan or trainer) then
        self.skillsCard:Hide()
        self:SetPetHeight(HEIGHT)
        return
    end
    local cardsHeight = -(fightEnd or 0) + 6
    if foodEnd then
        cardsHeight = math.max(cardsHeight, -foodEnd + (feeding and 38 or 6))
    end
    for _, card in ipairs({ self.foodCard, self.fightCard }) do
        if card:IsShown() then
            local left = card == self.fightCard and self.foodCard:IsShown()
            card:ClearAllPoints()
            card:SetPoint(left and "TOPRIGHT" or "TOPLEFT", self.body, left and "TOPRIGHT" or "TOPLEFT", 0, top)
            card:SetHeight(cardsHeight)
        end
    end
    local skillsTop = top - cardsHeight - GAP
    local skillsHeight = self:ShowSkills(plan, trainer, skillsTop)
    if not skillsHeight then
        self:SetPetHeight(math.max(HEIGHT, HEADER + GAP + (-top + cardsHeight) + FOOT))
        return
    end
    local needed = HEADER + GAP + (-skillsTop + skillsHeight) + FOOT
    self.skillsCard:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", 0, 0)
    self:SetPetHeight(math.max(HEIGHT, needed))
end

--- How tall the Pet tab needs to be. Every tab grows with it when it needs
--- more than the others (UI/PetsTabs.lua).
function UI:SetPetHeight(height)
    self.petHeight = height
    if ns.PetsTabs then
        ns.PetsTabs:Need("pet", nil, height)
    elseif self.frame then
        self.frame:SetHeight(height)
    end
end

--------------------------------------------------------------------------------
-- Filling it in
--------------------------------------------------------------------------------

--- The player's class token ("HUNTER", "WARLOCK"), or nil if unreadable.
function UI:PlayerClass()
    if type(UnitClass) ~= "function" then return nil end
    local ok, _, token = pcall(UnitClass, "player")
    if ok and type(token) == "string" then return token end
    return nil
end

--- Whether this character's class keeps pets the addon is for.
function UI:HasPetClass()
    local class = self:PlayerClass()
    return class == "HUNTER" or class == "WARLOCK"
end

--- Bring the window up to date with the character.
function UI:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end

    local class = self:PlayerClass()
    if class == "HUNTER" then
        self.subtitle:SetText(L["Hunter"])
    elseif class == "WARLOCK" then
        self.subtitle:SetText(L["Warlock"])
    else
        self.subtitle:SetText("")
    end

    if self:HasPetClass() then
        self.footer:SetText("")
        self:ShowStatus(ns.PetStatus:Read())
    else
        self.footer:SetText(L["Pets is for hunters and warlocks."])
        self:ShowStatus({ exists = false })
        self.emptyLabel:Hide()
    end
end

--------------------------------------------------------------------------------
-- Position and visibility
--------------------------------------------------------------------------------

function UI:SavePosition()
    if not (ns.db and self.frame) then return end
    local point, _, relativePoint, x, y = self.frame:GetPoint()
    ns.db.point, ns.db.relativePoint, ns.db.x, ns.db.y = point, relativePoint, x, y
    if ns.PetsTabs then ns.PetsTabs:Save(self.frame) end
end

function UI:RestorePosition()
    if not self.frame then return end
    local db = ns.db or {}
    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.point or "CENTER", UIParent, db.relativePoint or "CENTER",
        db.x or 0, db.y or 40)
end

function UI:Show()
    self:Build()
    if not self.frame:IsShown() then
        -- Opened from another tab, it takes that tab's place and does not
        -- open again with a flourish: it is the same window.
        local how = ns.PetsTabs and ns.PetsTabs:Take(self)
        if not how then self:RestorePosition() end
        self.frame:Show()
        if not how and ns.PetsTabs then ns.PetsTabs:Settle(self.frame) end
        if how ~= "switch" then
            ns.Motion:Open(self.frame)
            -- A light runs round the portrait as it opens.
            if ns.Titanforged then ns.Titanforged:Opened(self.frame) end
        end
    end
    self:Refresh()
end

function UI:Hide()
    if self.frame then self.frame:Hide() end
end

function UI:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

ns.RegisterCommand("window", L["open the pets window (so does /bpet on its own)"], function()
    UI:Toggle()
end)
