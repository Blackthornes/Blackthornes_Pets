-- Blackthornes Pets -- UI/SkillsToFind.lua
-- Skills to Find, the Compendium tab's second view (the owner said build it
-- from a mockup, 2026-11-26): a short to-do list of each skill rank the pet
-- out lacks, the closest beast that teaches it and Show the Way, then the
-- ranks that come later and what it has. "All Beasts" and "Skills to Find"
-- switch between the two at the top left of the Compendium.
--
-- Logic/PetSkills.lua works the list out (`PetSkills:CurrentToFind`, kept
-- until the pet, its skills, a level or the zone change). It is laid out
-- when the view opens, when the pet changes and when a spell is learned,
-- never on a timer. Skills from a pet trainer stay on the Pet tab.

local _, ns = ...
local L = ns.L

local SkillsToFindUI = ns.NewModule("SkillsToFindUI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local PADDING = 18
local HEADER = 44
local ROW_HEIGHT = 34
local HEAD_HEIGHT = 22
local SUMMARY_HEIGHT = 30
local FOOT = 40
local BAR_WIDTH = 240
local ICON = 22
local WAY_WIDTH = 100

-- Where each part of a row starts, as a share of the row past the icon.
local SKILL_X = 12 + ICON + 10
local BEAST_SHARE = 0.27
local ZONE_SHARE = 0.62

local function Compendium() return ns.CompendiumUI end

--------------------------------------------------------------------------------
-- The switch: All Beasts | Skills to Find
--------------------------------------------------------------------------------

--- Two joined buttons, the picked one gold. `onPick(key)` on a click.
function SkillsToFindUI.CreateSwitch(parent, onPick)
    local switch = CreateFrame("Frame", nil, parent)
    switch:SetHeight(24)
    switch.buttons = {}
    local x = 0
    for _, spec in ipairs({ { key = "all", text = L["All Beasts"] }, { key = "find", text = L["Skills to Find"] } }) do
        local button = CreateFrame("Button", nil, switch)
        local width = math.max(90, math.ceil(Theme.TextWidth("small", spec.text) or 0) + 26)
        button:SetSize(width, 24)
        button:SetPoint("LEFT", switch, "LEFT", x, 0)
        button.background = Theme.Fill(button, "glass")
        Theme.Border(button, "metal")
        button.label = Theme.CreateLabel(button, "small", "muted", "CENTER")
        button.label:SetPoint("CENTER")
        button.label:SetText(spec.text)
        button.key = spec.key
        button:SetScript("OnClick", function() onPick(spec.key) end)
        button:SetScript("OnEnter", function(self)
            if switch.picked ~= self.key then self.background:SetColorTexture(Theme.Unpack("glassHover")) end
        end)
        button:SetScript("OnLeave", function(self)
            if switch.picked ~= self.key then self.background:SetColorTexture(Theme.Unpack("glass")) end
        end)
        switch.buttons[spec.key] = button
        x = x + width
    end
    switch:SetWidth(x)

    function switch:Pick(key)
        self.picked = key
        for name, button in pairs(self.buttons) do
            local on = name == key
            button.background:SetColorTexture(Theme.Unpack(on and "accent" or "glass"))
            button.label:SetTextColor(Theme.Unpack(on and "ink" or "muted"))
        end
    end
    switch:Pick("all")
    return switch
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

--- Build the view inside the Compendium's frame, hidden.
function SkillsToFindUI:Build(frame)
    if self.panel then return self.panel end
    local panel = CreateFrame("Frame", nil, frame)
    panel:SetPoint("TOPLEFT", PADDING, -(HEADER + 10))
    panel:SetPoint("BOTTOMRIGHT", -PADDING, FOOT)
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta) SkillsToFindUI:ScrollBy(-delta) end)
    panel:Hide()
    self.panel = panel

    local summary = Theme.CreateLabel(panel, "normal", "text")
    summary:SetPoint("TOPLEFT", 2, -6)
    self.summary = summary
    local bar = CreateFrame("Frame", nil, panel)
    bar:SetSize(BAR_WIDTH, 8)
    bar:SetPoint("LEFT", summary, "RIGHT", 16, 0)
    Theme.Fill(bar, "well")
    Theme.Border(bar, "border", 0.8)
    local fill = bar:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    fill:SetColorTexture(Theme.Unpack("accent"))
    bar.fill = fill
    self.bar = bar

    local well = Theme.CreatePanel(panel, "panel", "border")
    well:SetPoint("TOPLEFT", 0, -SUMMARY_HEIGHT)
    well:SetPoint("BOTTOMRIGHT", 0, 0)
    if Theme.Recess then Theme.Recess(well) end
    self.well = well

    self.rows = {}
    self.empty = Theme.CreateLabel(well, "normal", "muted", "CENTER")
    self.empty:SetPoint("TOP", well, "TOP", 0, -40)
    self.empty:SetPoint("LEFT", 20, 0)
    self.empty:SetPoint("RIGHT", -20, 0)
    self.empty:Hide()

    -- Kept until the Compendium's own footer is back: the hint for this view.
    self.hint = L["Tame the beast, use the skill until you learn it, then teach it to your pet."]
    return panel
end

--- A row of the list: a heading, a rank to find, or a rank it has.
function SkillsToFindUI:Row(index)
    local row = self.rows[index]
    if row then return row end
    row = CreateFrame("Button", nil, self.well)
    row.background = Theme.Fill(row, "glass")
    row.rule = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.rule:SetPoint("BOTTOMLEFT")
    row.rule:SetPoint("BOTTOMRIGHT")
    row.rule:SetHeight(1)
    row.rule:SetColorTexture(Theme.Unpack("border", 0.6))
    local stripe = row:CreateTexture(nil, "OVERLAY")
    stripe:SetPoint("TOPLEFT")
    stripe:SetPoint("BOTTOMLEFT")
    stripe:SetWidth(2)
    stripe:SetColorTexture(Theme.Unpack("accentHi"))
    stripe:Hide()
    row.stripe = stripe

    local slot = CreateFrame("Frame", nil, row)
    slot:SetSize(ICON, ICON)
    slot:SetPoint("LEFT", 12, 0)
    Theme.Fill(slot, "well")
    Theme.Border(slot, "metal")
    row.icon = slot:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", 1, -1)
    row.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    if row.icon.SetTexCoord then row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    row.slot = slot

    row.check = Theme.CreateLabel(row, "normal", "good", "CENTER")
    row.check:SetPoint("CENTER", slot, "CENTER", 0, 0)
    row.check:SetText("\226\156\147")

    row.heading = Theme.CreateLabel(row, "tiny", "accent")
    row.heading:SetPoint("LEFT", 12, 0)
    row.skill = Theme.CreateLabel(row, "normal", "text")
    row.skill:SetPoint("LEFT", SKILL_X, 0)
    row.beast = Theme.CreateLabel(row, "normal", "text")
    row.beastSub = Theme.CreateLabel(row, "tiny", "muted")
    row.zone = Theme.CreateLabel(row, "normal", "text")
    row.way = Widgets.CreateButton(row, L["Show the Way"], function()
        local entry = rawget(row, "line") and row.line.beast
        local window = Compendium()
        if entry and window and window.AimArrow then window:AimArrow(entry) end
    end, { primary = true, width = WAY_WIDTH, height = 22 })
    row.way:SetPoint("RIGHT", -8, 0)

    row:SetScript("OnClick", function(self)
        local line = rawget(self, "line")
        if line and line.name and line.section ~= "done" then
            local window = Compendium()
            if window then window:ShowView("all", line.name) end
        end
    end)
    row:SetScript("OnEnter", function(self)
        local line = rawget(self, "line")
        if not line or line.kind == "head" then return end
        self.background:SetColorTexture(Theme.Unpack("glassHover"))
        self.stripe:Show()
    end)
    row:SetScript("OnLeave", function(self)
        local line = rawget(self, "line")
        self.background:SetColorTexture(Theme.Unpack(rawget(self, "rest") or "glass"))
        self.stripe:Hide()
        if line and line.first then self.stripe:Show() end
    end)
    self.rows[index] = row
    return row
end

--------------------------------------------------------------------------------
-- The lines
--------------------------------------------------------------------------------

--- The list as lines to draw: headings and ranks, in the order shown.
function SkillsToFindUI.Lines(found)
    local lines = {}
    local function Section(key, title, list)
        if #list == 0 then return end
        lines[#lines + 1] = { kind = "head", text = title }
        for _, item in ipairs(list) do
            lines[#lines + 1] = { kind = "rank", section = key, name = item.name, rank = item.rank,
                beast = item.beast, level = item.level }
        end
    end
    Section("now", L["YOU CAN TAME THESE NOW"], found.now or {})
    Section("later", L["LATER"], found.later or {})
    Section("done", L["DONE"], found.done or {})
    for _, line in ipairs(lines) do
        if line.section == "now" then
            line.first = true
            break
        end
    end
    return lines
end

--- The summary over the list: "Shadowpaw has 6 of 9 skill ranks for level 23."
function SkillsToFindUI.SummaryText(name, found, level)
    return L.Format("%s has %d of %d skill ranks for level %d.", name or L["Your pet"], found.have or 0,
        found.of or 0, level or 0)
end

local function Muted(text) return ("|c%s%s|r"):format(ns.COLORS.muted, text) end

--- Fill one row from a line, at `y` in the well. Returns its height.
function SkillsToFindUI:FillRow(row, line, y, band)
    row.line = line
    local height = line.kind == "head" and HEAD_HEIGHT or ROW_HEIGHT
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.well, "TOPLEFT", 3, y)
    row:SetPoint("TOPRIGHT", self.well, "TOPRIGHT", -3, y)
    row:SetHeight(height)
    local head = line.kind == "head"
    row.rest = head and "well" or (band % 2 == 0 and "glassAlt" or "glass")
    row.background:SetColorTexture(Theme.Unpack(row.rest))
    row.heading:SetShown(head)
    row.heading:SetText(head and line.text or "")
    row.stripe:SetShown(line.first == true)

    local done = line.section == "done"
    row.slot:SetShown(not head and not done)
    row.check:SetShown(done)
    row.skill:SetShown(not head)
    row.beast:SetShown(not head and not done)
    row.beastSub:SetShown(not head and not done)
    row.zone:SetShown(not head and not done)
    row.way:SetShown(line.section == "now")
    if head then
        row:Show()
        return height
    end

    local skillText = L.Format("%s Rank %d", line.name, line.rank)
    row.skill:SetText(done and Muted(skillText) or skillText)
    row.icon:SetTexture(ns.PetSkills.Icon(line.name, line.rank))
    if not done then
        local wellWidth = self.well:GetWidth()
        if type(wellWidth) ~= "number" or wellWidth <= 0 then wellWidth = 760 end
        local width = wellWidth - SKILL_X - WAY_WIDTH - 20
        local beastX = SKILL_X + math.floor(width * BEAST_SHARE)
        local zoneX = SKILL_X + math.floor(width * ZONE_SHARE)
        local beast = line.beast or {}
        row.beast:ClearAllPoints()
        row.beast:SetPoint("TOPLEFT", row, "TOPLEFT", beastX, -3)
        row.beast:SetPoint("RIGHT", row, "LEFT", zoneX - 10, 0)
        row.beast:SetText(beast.name or "")
        row.beastSub:ClearAllPoints()
        row.beastSub:SetPoint("TOPLEFT", row.beast, "BOTTOMLEFT", 0, -2)
        row.beastSub:SetPoint("RIGHT", row, "LEFT", zoneX - 10, 0)
        local levelText = ns.Compendium.LevelText(beast)
        local sub = levelText ~= "" and L.Format("Level %s", levelText) or ""
        if line.first then sub = sub .. (sub ~= "" and ". " or "") .. L["Closest beast that teaches it."] end
        row.beastSub:SetText(sub)
        row.zone:ClearAllPoints()
        row.zone:SetPoint("LEFT", row, "LEFT", zoneX, 0)
        row.zone:SetPoint("RIGHT", row, "RIGHT", -(WAY_WIDTH + 16), 0)
        if line.section == "later" then
            row.zone:SetText(L.Format("At level %d", line.level or 0))
        else
            row.zone:SetText(beast.zone or "")
        end
    end
    row:Show()
    return height
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

--- Work the list out again and draw it.
function SkillsToFindUI:Refresh()
    if not (self.panel and self.panel:IsShown()) then return end
    local PetSkills = ns.PetSkills
    local found = PetSkills and PetSkills:CurrentToFind()
    local status = ns.PetStatus and ns.PetStatus:Read() or {}
    self.found = found
    if not found then
        self.lines = {}
        self.summary:SetText("")
        self.bar:Hide()
        self.empty:SetText(PetSkills and PetSkills.IsHunter() and L["Call your pet to see what it still has to learn."]
            or L["Skills to Find is for hunters' pets."])
        self.empty:Show()
        self:Draw()
        return
    end
    local level = PetSkills.PetLevel() or status.level
    self.summary:SetText(SkillsToFindUI.SummaryText(status.name, found, level))
    self.bar:SetShown((found.of or 0) > 0)
    if (found.of or 0) > 0 then
        local share = math.min(1, (found.have or 0) / found.of)
        self.bar.fill:SetWidth(math.max(1, math.floor((BAR_WIDTH - 2) * share + 0.5)))
    end
    self.lines = SkillsToFindUI.Lines(found)
    local nothing = #found.now == 0 and #found.later == 0
    self.empty:SetShown(nothing and #found.done == 0)
    if nothing and #found.done == 0 then
        self.empty:SetText(L.Format("%s has everything for level %d.", status.name or L["Your pet"], level or 0))
    end
    self.offset = math.min(self.offset or 0, math.max(0, #self.lines - 1))
    self:Draw()
end

--- Lay the lines out from `offset` on, as many as fit.
function SkillsToFindUI:Draw()
    local lines = self.lines or {}
    local room = self.well:GetHeight()
    if type(room) ~= "number" or room <= 0 then room = 400 end
    room = room - 6
    local y, used, band = -3, 0, 0
    local index = 0
    for at = (self.offset or 0) + 1, #lines do
        local line = lines[at]
        local height = line.kind == "head" and HEAD_HEIGHT or ROW_HEIGHT
        if used + height > room then break end
        index = index + 1
        if line.kind == "head" then band = 0 else band = band + 1 end
        local row = self:Row(index)
        self:FillRow(row, line, y, band)
        y, used = y - height, used + height
    end
    for i = index + 1, #self.rows do
        self.rows[i].line = nil
        self.rows[i]:Hide()
    end
    self.drawn = index
end

function SkillsToFindUI:ScrollBy(steps)
    local lines = self.lines or {}
    local offset = math.max(0, math.min(#lines - (self.drawn or 0), (self.offset or 0) + steps))
    if offset == self.offset then return end
    self.offset = offset
    self:Draw()
end

function SkillsToFindUI:Show()
    if not self.panel then return end
    self.panel:Show()
    self.offset = 0
    self:Refresh()
end

function SkillsToFindUI:Hide()
    if self.panel then self.panel:Hide() end
end

--- A new pet called, or a spell learned: an open list draws again.
function SkillsToFindUI:OnEnable()
    local function Again()
        if SkillsToFindUI.panel and SkillsToFindUI.panel:IsShown() then pcall(SkillsToFindUI.Refresh, SkillsToFindUI) end
    end
    ns.RegisterPetEvent(self, "UNIT_PET", function(_, _, unit)
        if unit == nil or unit == "player" then Again() end
    end)
    for _, event in ipairs({ "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_LEVEL_UP" }) do
        ns.RegisterEvent(self, event, function()
            if ns.PetSkills then ns.PetSkills:Forget() end
            Again()
        end)
    end
end
