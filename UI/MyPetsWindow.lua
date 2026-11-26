-- Blackthornes Pets -- UI/MyPetsWindow.lua
-- The My Pets tab, between Pet and Compendium (the owner said build it from
-- a mockup, 2026-11-26), for hunters only: a card for every pet you own,
-- the one out and the ones in the stable, as each was last seen
-- (Logic/MyPets.lua). Each card has the pet's icon and level, its name and
-- family, Out Now or In the Stable, its loyalty, what it eats and its
-- attack speed, the skills it knows, and how many skill ranks it still has
-- to find by taming, with Show Them to open that list in the Compendium.
-- Under the cards, how many stable slots are used.
--
-- It is drawn when the tab opens and when the save changes (a pet out, the
-- stable opened), never on a timer.

local _, ns = ...
local L = ns.L

local MyPetsUI = ns.NewModule("MyPetsUI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local WIDTH = ns.PetsTabs and ns.PetsTabs.WIDTH or 820
local HEIGHT = ns.PetsTabs and ns.PetsTabs.HEIGHT or 586
local PADDING = 18
local HEADER = 44
local FOOT = 40
local COLUMNS = 3
local GAP = 12
local CARD_HEIGHT = 236
local ICON = 52
local LINE = 18
local CHIP_HEIGHT = 20
local SHOW_WIDTH = 100

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function MyPetsUI:Build()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "BlackthornesPetsMyPets", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    Theme.Fill(frame, "window")

    if ns.Titanforged then
        local trim = ns.Titanforged:Dress(frame, {
            title = "Blackthornes Pets",
            portrait = true,
            close = function() MyPetsUI:Hide() end,
        })
        self.trim = trim
        local left, right, top, bottom = ns.Titanforged.Reach(trim)
        if frame.SetClampRectInsets then
            frame:SetClampRectInsets(-left, right, top, -bottom)
        end
    else
        Theme.Border(frame, "borderLit")
    end

    if ns.FoldWindow then
        ns.FoldWindow:Add(frame, { key = "MyPets", onToggle = function(folded)
            if not folded then MyPetsUI:Refresh() end
        end })
    end
    if ns.SharedWindow and ns.SharedWindow.AddSwap then ns.SharedWindow.AddSwap(frame, "pets") end

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if ns.PetsTabs then ns.PetsTabs:Save(self) end
    end)

    self.sizeGrip = Widgets.WindowGrip(frame, "windowScale", function()
        if ns.PetsTabs then ns.PetsTabs:Save(frame) end
    end)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) MyPetsUI:ScrollBy(-delta) end)

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsMyPets")
    end

    self.frame = frame
    if ns.PetsTabs then ns.PetsTabs:Attach(self, "mypets") end
    frame:HookScript("OnHide", function() if ns.PetsTabs then ns.PetsTabs:Closed(frame) end end)
    if ns.UI and ns.UI.WatchCover then ns.UI:WatchCover(frame) end

    local area = CreateFrame("Frame", nil, frame)
    area:SetPoint("TOPLEFT", PADDING, -(HEADER + 10))
    area:SetPoint("BOTTOMRIGHT", -PADDING, FOOT)
    self.area = area
    self.cards = {}

    local empty = Theme.CreateLabel(area, "normal", "muted", "CENTER")
    empty:SetPoint("TOP", area, "TOP", 0, -60)
    empty:SetPoint("LEFT", 20, 0)
    empty:SetPoint("RIGHT", -20, 0)
    empty:SetWordWrap(true)
    empty:SetText(L["Call your pet or open the stable to see your pets here."])
    empty:Hide()
    self.empty = empty

    local version = Theme.CreateLabel(frame, "tiny", "dim", "RIGHT")
    version:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    version:SetText(ns.VersionLabel and ns.VersionLabel() or "")
    self.versionLabel = version

    local footer = Theme.CreateLabel(frame, "small", "muted")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("RIGHT", version, "LEFT", -12, 0)
    self.footer = footer

    frame:Hide()
    return frame
end

--- One "Loyalty .... Faithful" line on a card.
local function CardLine(card, label)
    local line = CreateFrame("Frame", nil, card)
    line:SetHeight(LINE)
    line.label = Theme.CreateLabel(line, "small", "muted")
    line.label:SetPoint("LEFT")
    line.label:SetText(label)
    line.value = Theme.CreateLabel(line, "small", "text", "RIGHT")
    line.value:SetPoint("RIGHT")
    line.value:SetPoint("LEFT", line.label, "RIGHT", 8, 0)
    return line
end

--- A card, built once and kept.
function MyPetsUI:Card(index)
    local card = self.cards[index]
    if card then return card end
    card = CreateFrame("Frame", nil, self.area)
    card:SetHeight(CARD_HEIGHT)
    card.background = Theme.Fill(card, "glass")
    Theme.Border(card, "border")
    local edge = card:CreateTexture(nil, "OVERLAY")
    edge:SetPoint("TOPLEFT")
    edge:SetPoint("BOTTOMLEFT")
    edge:SetWidth(3)
    edge:SetColorTexture(Theme.Unpack("accentHi"))
    card.edge = edge

    local slot = CreateFrame("Frame", nil, card)
    slot:SetSize(ICON, ICON)
    slot:SetPoint("TOPLEFT", 14, -14)
    Theme.Fill(slot, "well")
    Theme.Border(slot, "metal")
    card.icon = slot:CreateTexture(nil, "ARTWORK")
    card.icon:SetPoint("TOPLEFT", 1, -1)
    card.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    if card.icon.SetTexCoord then card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    local badge = CreateFrame("Frame", nil, slot)
    badge:SetSize(24, 16)
    badge:SetPoint("BOTTOMRIGHT", 6, -4)
    Theme.Fill(badge, "window", nil, "ARTWORK")
    Theme.Border(badge, "accent")
    badge.label = Theme.CreateLabel(badge, "tiny", "text", "CENTER")
    badge.label:SetPoint("CENTER")
    card.badge = badge

    card.name = Theme.CreateLabel(card, "large", "accentHi")
    card.name:SetPoint("TOPLEFT", slot, "TOPRIGHT", 12, -2)
    card.name:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    card.family = Theme.CreateLabel(card, "small", "muted")
    card.family:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)

    local tag = CreateFrame("Frame", nil, card)
    tag:SetHeight(20)
    tag:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -8)
    tag.background = Theme.Fill(tag, "well")
    Theme.Border(tag, "border")
    tag.label = Theme.CreateLabel(tag, "small", "muted", "CENTER")
    tag.label:SetPoint("CENTER")
    card.tag = tag

    card.lines = {}
    local y = -(14 + ICON + 8 + 20 + 10)
    for i, label in ipairs({ L["Loyalty"], L["Eats"], L["Speed"] }) do
        local line = CardLine(card, label)
        line:SetPoint("TOPLEFT", 14, y - (i - 1) * LINE)
        line:SetPoint("RIGHT", card, "RIGHT", -14, 0)
        card.lines[i] = line
    end
    card.chipTop = y - 3 * LINE - 8
    card.chips = {}

    local rule = card:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", 14, 40)
    rule:SetPoint("BOTTOMRIGHT", -14, 40)
    rule:SetColorTexture(Theme.Unpack("border", 0.8))

    card.find = Theme.CreateLabel(card, "small", "accent")
    card.find:SetPoint("BOTTOMLEFT", 14, 14)
    card.show = Widgets.CreateButton(card, L["Show Them"], function()
        MyPetsUI:ShowThem(rawget(card, "pet"))
    end, { primary = true, width = SHOW_WIDTH, height = 22 })
    card.show:SetPoint("BOTTOMRIGHT", -14, 10)
    card.find:SetPoint("RIGHT", card.show, "LEFT", -8, 0)

    self.cards[index] = card
    return card
end

--- A skill chip: the skill's icon and "Bite 3".
local function Chip(card, index)
    local chip = card.chips[index]
    if chip then return chip end
    chip = CreateFrame("Frame", nil, card)
    chip:SetHeight(CHIP_HEIGHT)
    Theme.Fill(chip, "well")
    Theme.Border(chip, "border")
    chip.icon = chip:CreateTexture(nil, "ARTWORK")
    chip.icon:SetSize(CHIP_HEIGHT - 4, CHIP_HEIGHT - 4)
    chip.icon:SetPoint("LEFT", 2, 0)
    if chip.icon.SetTexCoord then chip.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    chip.label = Theme.CreateLabel(chip, "small", "text")
    chip.label:SetPoint("LEFT", chip.icon, "RIGHT", 4, 0)
    card.chips[index] = chip
    return chip
end

--------------------------------------------------------------------------------
-- What a card says
--------------------------------------------------------------------------------

--- The skills a pet knows, as { { name, rank } }, in name order.
function MyPetsUI.SkillList(pet)
    local list = {}
    for name, rank in pairs(pet and pet.known or {}) do
        list[#list + 1] = { name = name, rank = rank }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

--- The card's foot: what it still has to find, and whether Show Them shows.
--- Returns the words, their colour and true when Show Them belongs.
function MyPetsUI.FindText(found)
    if not found then return L["Call it out once to see its skills."], "muted", false end
    local count = #(found.now or {})
    if count == 0 then return L["Has every skill for its level"], "good", false end
    if count == 1 then return L["1 skill to find"], "accent", true end
    return L.Format("%d skills to find", count), "accent", true
end

--- The line under the cards: "1 of 2 stable slots used. Visit a stable
--- master to swap pets." Nil before the stable was ever opened.
function MyPetsUI.SlotsText(used, total)
    if not total then return nil end
    if total == 1 then return L.Format("%d of 1 stable slot used. Visit a stable master to swap pets.", used) end
    return L.Format("%d of %d stable slots used. Visit a stable master to swap pets.", used, total)
end

--- Lay a card's chips in rows across it, as many as fit in two rows.
local function LayChips(card, skills, width)
    local x, row, shown = 14, 0, 0
    local room = width - 28
    for i, skill in ipairs(skills) do
        local chip = Chip(card, i)
        local text = ("%s %d"):format(skill.name, skill.rank)
        chip.label:SetText(text)
        chip.icon:SetTexture(ns.PetSkills and ns.PetSkills.Icon(skill.name, skill.rank) or nil)
        local chipWidth = CHIP_HEIGHT + 10 + (Theme.TextWidth("small", text) or 0)
        if x > 14 and x + chipWidth > 14 + room then
            row, x = row + 1, 14
        end
        if row > 1 then
            chip:Hide()
        else
            chip:SetWidth(chipWidth)
            chip:ClearAllPoints()
            chip:SetPoint("TOPLEFT", card, "TOPLEFT", x, card.chipTop - row * (CHIP_HEIGHT + 4))
            chip:Show()
            shown = shown + 1
            x = x + chipWidth + 6
        end
    end
    for i = #skills + 1, #card.chips do card.chips[i]:Hide() end
    return shown
end

--- Fill a card from a saved pet.
function MyPetsUI:FillCard(card, pet, width)
    card.pet = pet
    local active = pet.active == true
    card.background:SetColorTexture(Theme.Unpack(active and "glassActive" or "glass"))
    card.edge:SetShown(active)
    card.icon:SetTexture(pet.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    card.badge.label:SetText(pet.level and tostring(pet.level) or "")
    card.badge:SetShown(pet.level ~= nil)
    card.name:SetText(pet.name or "")
    card.family:SetText(pet.family or "")

    local tagText = active and L["Out Now"] or L["In the Stable"]
    card.tag.label:SetText(tagText)
    card.tag.label:SetTextColor(Theme.Unpack(active and "good" or "muted"))
    Theme.SetBorderColor(card.tag, active and "good" or "border")
    card.tag:SetWidth(math.ceil(Theme.TextWidth("small", tagText) or 0) + 20)

    local speed = pet.speed and ns.PetStatus and ns.PetStatus:SpeedText({ speed = pet.speed }) or nil
    local values = {
        pet.loyalty,
        pet.foods and table.concat(pet.foods, ", ") or nil,
        speed,
    }
    local y = -(14 + ICON + 8 + 20 + 10)
    local at = 0
    for i, line in ipairs(card.lines) do
        if values[i] then
            line.value:SetText(values[i])
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", card, "TOPLEFT", 14, y - at * LINE)
            line:SetPoint("RIGHT", card, "RIGHT", -14, 0)
            line:Show()
            at = at + 1
        else
            line:Hide()
        end
    end
    card.chipTop = y - at * LINE - 8
    LayChips(card, MyPetsUI.SkillList(pet), width)

    local found = ns.MyPets and ns.MyPets:ToFind(pet)
    local text, color, button = MyPetsUI.FindText(found)
    card.find:SetText(text)
    card.find:SetTextColor(Theme.Unpack(color))
    card.show:SetShown(button)
    card:Show()
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

function MyPetsUI:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end
    local pets = ns.MyPets and ns.MyPets:List() or {}
    self.pets = pets
    self.empty:SetShown(#pets == 0)
    local rowsAll = math.ceil(#pets / COLUMNS)
    self.offset = math.max(0, math.min(self.offset or 0, rowsAll - 1))
    self:Draw()
    local used, total
    if ns.MyPets then used, total = ns.MyPets:Slots() end
    self.footer:SetText(MyPetsUI.SlotsText(used, total) or "")
end

--- Lay the cards out, a row of three at a time, from row `offset` on.
function MyPetsUI:Draw()
    local pets = self.pets or {}
    local width = self.area:GetWidth()
    if type(width) ~= "number" or width <= 0 then width = WIDTH - 2 * PADDING end
    local height = self.area:GetHeight()
    if type(height) ~= "number" or height <= 0 then height = HEIGHT - HEADER - 10 - FOOT end
    local cardWidth = math.floor((width - (COLUMNS - 1) * GAP) / COLUMNS)
    local rows = math.max(1, math.floor((height + GAP) / (CARD_HEIGHT + GAP)))
    self.rowsShown = rows
    local first = (self.offset or 0) * COLUMNS + 1
    local index = 0
    for at = first, math.min(#pets, first + rows * COLUMNS - 1) do
        index = index + 1
        local card = self:Card(index)
        local column = (index - 1) % COLUMNS
        local row = math.floor((index - 1) / COLUMNS)
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", self.area, "TOPLEFT", column * (cardWidth + GAP), -row * (CARD_HEIGHT + GAP))
        card:SetWidth(cardWidth)
        self:FillCard(card, pets[at], cardWidth)
    end
    for i = index + 1, #self.cards do
        self.cards[i].pet = nil
        self.cards[i]:Hide()
    end
end

function MyPetsUI:ScrollBy(steps)
    local rowsAll = math.ceil(#(self.pets or {}) / COLUMNS)
    local offset = math.max(0, math.min(rowsAll - (self.rowsShown or 1), (self.offset or 0) + steps))
    if offset == (self.offset or 0) then return end
    self.offset = offset
    self:Draw()
end

--- Show Them: the Compendium's Skills to Find, for this pet.
function MyPetsUI:ShowThem(pet)
    local window = ns.CompendiumUI
    if not (pet and window) then return end
    window:Show()
    window:ShowView("find", nil, not pet.active and pet or nil)
end

--- The window took the size every tab shares (UI/PetsTabs.lua).
function MyPetsUI:OnTabSize()
    self:Refresh()
end

--------------------------------------------------------------------------------
-- Visibility
--------------------------------------------------------------------------------

function MyPetsUI:Show()
    if ns.PetsTabs and ns.PetsTabs:Route("mypets") then return end
    self:Build()
    if not self.frame:IsShown() then
        local how = ns.PetsTabs and ns.PetsTabs:Take(self)
        if not how then
            self.frame:ClearAllPoints()
            self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
        end
        self.frame:Show()
        if not how and ns.PetsTabs then ns.PetsTabs:Settle(self.frame) end
        if how ~= "switch" then
            if ns.Motion then ns.Motion:Open(self.frame) end
            if ns.Titanforged then ns.Titanforged:Opened(self.frame) end
        end
    end
    if ns.FoldWindow then ns.FoldWindow:Unfold(self.frame) end
    -- The pet out is read afresh as the tab opens.
    if ns.MyPets then ns.MyPets:ReadOut() end
    self:Refresh()
end

function MyPetsUI:Hide()
    if self.frame then self.frame:Hide() end
end

function MyPetsUI:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
