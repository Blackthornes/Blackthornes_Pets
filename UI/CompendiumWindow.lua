-- Blackthornes Pets -- UI/CompendiumWindow.lua
-- The Pet Compendium: every beast a hunter can tame, what taming it teaches,
-- when it can be tamed, where it lives and how rare it is, with what WoW:
-- Forever has shown marked in green.
--
-- It wears the whole house frame, like the pets window: the paw in the
-- portrait, the name on the plate and the close gem. Above the list is the
-- option bar (the family chooser, the search, then the tick boxes), and the
-- list's headings sort it. A click on a beast pins it on the map. The
-- choices are kept, account wide, in BlackthornesPetsDB.compendium.

local _, ns = ...

local CompendiumUI = ns.NewModule("CompendiumUI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local WIDTH = 820
local HEIGHT = 586
local PADDING = 18
local EDGE_PAD = 11
local HEADER = 44
local BAR_GAP = 8
local ROW_HEIGHT = 34
local VISIBLE = 11
local SCROLL_WIDTH = 4

-- The list's columns: where each starts in a row, and how wide it is.
local COLUMNS = {
    { key = "name", label = "Beast", x = 10, width = 196 },
    { key = "family", label = "Family", x = 212, width = 92 },
    { key = "level", label = "Level", x = 308, width = 52 },
    { key = "zone", label = "Where", x = 364, width = 200 },
    { key = "skills", label = "Teaches", x = 570, width = 196 },
}

-- The colour a beast's name takes for its rank.
local RANK_COLOR = { rare = "rare", rareelite = "rare", elite = "warn" }

local function Hex(key)
    local r, g, b = Theme.Unpack(key)
    return ("ff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5))
end

local function Colored(key, text)
    return ("|c%s%s|r"):format(Hex(key), text)
end

--------------------------------------------------------------------------------
-- Saved choices
--------------------------------------------------------------------------------

function CompendiumUI:Options()
    if not ns.db then return {} end
    if type(ns.db.compendium) ~= "table" then ns.db.compendium = {} end
    return ns.db.compendium
end

--- What the list is filtered and sorted by, from the saved choices.
function CompendiumUI:Filter()
    local o = self:Options()
    return {
        family = o.family, text = self.searchText, tameNow = o.tameNow == true,
        raresOnly = o.raresOnly == true, newSkills = o.newSkills == true,
        foreverOnly = o.foreverOnly == true, sort = o.sort or "name", descending = o.descending == true,
    }
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function CompendiumUI:Build()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "BlackthornesPetsCompendium", UIParent)
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
            title = "Pet Compendium",
            portrait = true,
            close = function() CompendiumUI:Hide() end,
        })
        self.trim = trim
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
        CompendiumUI:SavePosition()
    end)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) CompendiumUI:ScrollBy(-delta) end)

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsCompendium")
    end

    self.frame = frame
    self:BuildHeader()
    self:BuildBar()
    self:BuildHeadings()
    self:BuildList()

    local footer = Theme.CreateLabel(frame, "small", "text")
    footer:SetPoint("BOTTOMLEFT", PADDING, 28)
    footer:SetWidth(WIDTH - PADDING * 2)
    self.footer = footer

    local hint = Theme.CreateLabel(frame, "tiny", "dim")
    hint:SetPoint("BOTTOMLEFT", PADDING, 12)
    hint:SetWidth(WIDTH - PADDING * 2)
    hint:SetWordWrap(true)
    hint:SetText(("Click a beast to pin it on your map. %s marks what WoW: Forever has shown; "
        .. "the rest is Classic 1.12."):format(Colored("good", "Forever")))
    self.hint = hint

    frame:Hide()
    return frame
end

function CompendiumUI:BuildHeader()
    local frame = self.frame
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", EDGE_PAD, -EDGE_PAD)
    header:SetPoint("TOPRIGHT", -EDGE_PAD, -EDGE_PAD)
    header:SetHeight(HEADER - EDGE_PAD)

    local rule = header:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")
    rule:SetHeight(1)
    Theme.SetGradientAlpha(rule, "HORIZONTAL", "accent", 0.6, 0.05)

    -- Past the portrait, which reaches 48 pixels into the window.
    local subtitle = Theme.CreateLabel(header, "small", "muted")
    subtitle:SetPoint("LEFT", header, "LEFT", 48, -4)
    self.subtitle = subtitle

    local settings = Widgets.CreateButton(header, "Settings", function()
        if ns.SettingsUI then ns.SettingsUI:Toggle() end
    end, { width = 70, height = 20 })
    settings:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -10, 4)
end

--- The option bar: the family chooser and the search on one line, the tick
--- boxes under them.
function CompendiumUI:BuildBar()
    local frame = self.frame
    local top = -(HEADER + 12)

    local familyLabel = Theme.CreateLabel(frame, "small", "muted")
    familyLabel:SetPoint("TOPLEFT", PADDING, top - 4)
    familyLabel:SetText("Family")

    -- 0 is every family; 1 and up are the families in name order.
    local family = Widgets.CreateStepper(frame, {
        min = 0, max = 999, step = 1, value = 0,
        format = function(value)
            return CompendiumUI.families and CompendiumUI.families[value] or "All families"
        end,
        onChange = function(value)
            CompendiumUI:Options().family = CompendiumUI.families[value]
            CompendiumUI.offset = 0
            CompendiumUI:Refresh()
        end,
    })
    family:SetWidth(170)
    family:SetPoint("LEFT", familyLabel, "RIGHT", 8, 0)
    self.familyStepper = family

    local search = Widgets.CreateSearchBox(frame, "Search beasts, zones or skills", function(text)
        CompendiumUI.searchText = text
        CompendiumUI.offset = 0
        CompendiumUI:Refresh()
    end)
    search:SetPoint("LEFT", family, "RIGHT", 14, 0)
    search:SetWidth(260)
    self.search = search

    local ticks = {
        { key = "tameNow", text = "Tameable now",
          tip = "Only beasts at or below your level, so you can tame them today." },
        { key = "raresOnly", text = "Rares only", tip = "Only rare and rare elite beasts." },
        { key = "newSkills", text = "Teaches me something new",
          tip = "Only beasts whose taming teaches a skill this hunter has not got." },
        { key = "foreverOnly", text = "Seen on Forever",
          tip = "Only beasts WoW: Forever has shown: seen, tamed or named by a Forever guide." },
    }
    self.ticks = {}
    local previous
    for _, spec in ipairs(ticks) do
        local box = Widgets.CreateCheckbox(frame, spec.text, function(checked)
            CompendiumUI:Options()[spec.key] = checked
            CompendiumUI.offset = 0
            CompendiumUI:Refresh()
        end, false)
        if previous then
            box:SetPoint("LEFT", previous, "RIGHT", 18, 0)
        else
            box:SetPoint("TOPLEFT", PADDING, top - 32)
        end
        box:HookScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(spec.text, 1, 1, 1)
            GameTooltip:AddLine(spec.tip, 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end)
        box:HookScript("OnLeave", function() GameTooltip:Hide() end)
        self.ticks[spec.key] = box
        previous = box
    end

    self.barBottom = top - 32 - 18 - BAR_GAP
end

--- The headings, which sort the list: a click sorts by that column, a
--- second click turns it round.
function CompendiumUI:BuildHeadings()
    local frame = self.frame
    self.headings = {}
    for _, column in ipairs(COLUMNS) do
        local heading = CreateFrame("Button", nil, frame)
        heading:SetSize(column.width, 18)
        heading:SetPoint("TOPLEFT", PADDING + column.x, self.barBottom)
        local label = Theme.CreateLabel(heading, "tiny", "muted")
        label:SetPoint("LEFT", 0, 0)
        label:SetText(column.label:upper())
        heading.label = label
        heading.column = column

        local sortKey = column.key ~= "skills" and column.key or nil
        heading.sortKey = sortKey
        if sortKey then
            heading:SetScript("OnClick", function() CompendiumUI:SortBy(sortKey) end)
            heading:SetScript("OnEnter", function(self)
                self.label:SetTextColor(Theme.Unpack("accentHi"))
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(("Sort by %s"):format(column.label:lower()), 1, 1, 1)
                GameTooltip:AddLine("Click again to turn the order round.", 0.9, 0.9, 0.9, true)
                GameTooltip:Show()
            end)
            heading:SetScript("OnLeave", function()
                CompendiumUI:PaintHeadings()
                GameTooltip:Hide()
            end)
        end
        self.headings[#self.headings + 1] = heading
    end
    self.listTop = self.barBottom - 20
end

function CompendiumUI:BuildList()
    local frame = self.frame

    local well = Theme.CreatePanel(frame, "panel", "border")
    well:SetPoint("TOPLEFT", PADDING - 3, self.listTop + 3)
    well:SetPoint("TOPRIGHT", -(PADDING - 3), self.listTop + 3)
    well:SetHeight(VISIBLE * ROW_HEIGHT + 6)
    if Theme.Recess then Theme.Recess(well) end
    self.well = well

    self.rows = {}
    for index = 1, VISIBLE do self.rows[index] = self:BuildRow(index) end

    local track = well:CreateTexture(nil, "ARTWORK")
    track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, self.listTop)
    track:SetSize(SCROLL_WIDTH, VISIBLE * ROW_HEIGHT)
    track:SetColorTexture(Theme.Unpack("rowAlt"))
    self.track = track

    local thumb = well:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(SCROLL_WIDTH)
    thumb:SetColorTexture(Theme.Unpack("accent", 0.8))
    self.thumb = thumb

    local empty = Theme.CreateLabel(well, "normal", "muted", "CENTER")
    empty:SetPoint("TOP", frame, "TOP", 0, self.listTop - 60)
    empty:SetWidth(WIDTH - PADDING * 4)
    empty:SetWordWrap(true)
    self.empty = empty
end

local function Cell(row, column, size, color)
    local label = Theme.CreateLabel(row, size, color)
    label:SetPoint("TOPLEFT", column.x, -4)
    label:SetWidth(column.width)
    label:SetWordWrap(true)
    label:SetJustifyV("TOP")
    return label
end

function CompendiumUI:BuildRow(index)
    local row = CreateFrame("Button", nil, self.frame)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", PADDING, self.listTop - (index - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -(PADDING + SCROLL_WIDTH + 2), self.listTop - (index - 1) * ROW_HEIGHT)
    row.background = Theme.Fill(row, index % 2 == 0 and "rowAlt" or "panel")
    row.rest = index % 2 == 0 and "rowAlt" or "panel"

    -- A gold bar down the left edge under the mouse, as the house lists do.
    local stripe = row:CreateTexture(nil, "OVERLAY")
    stripe:SetPoint("TOPLEFT")
    stripe:SetPoint("BOTTOMLEFT")
    stripe:SetWidth(2)
    stripe:SetColorTexture(Theme.Unpack("accentHi"))
    stripe:Hide()
    row.stripe = stripe

    row.name = Cell(row, COLUMNS[1], "small", "text")
    row.family = Cell(row, COLUMNS[2], "small", "text")
    row.level = Cell(row, COLUMNS[3], "small", "text")
    row.zone = Cell(row, COLUMNS[4], "small", "text")
    row.skills = Cell(row, COLUMNS[5], "tiny", "text")

    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function(self)
        local entry = rawget(self, "entry")
        if entry then ns.Compendium:Pin(entry) end
    end)
    row:SetScript("OnEnter", function(self)
        self.over = true
        self.background:SetColorTexture(Theme.Unpack("rowHover"))
        self.stripe:Show()
        if rawget(self, "entry") then CompendiumUI:ShowTooltip(self) end
    end)
    row:SetScript("OnLeave", function(self)
        self.over = false
        self.background:SetColorTexture(Theme.Unpack(self.rest))
        self.stripe:Hide()
        GameTooltip:Hide()
    end)
    row:Hide()
    return row
end

--------------------------------------------------------------------------------
-- Words for a row
--------------------------------------------------------------------------------

local Compendium = function() return ns.Compendium end

--- Each skill coloured: green when the hunter knows it, red when not, plain
--- when nothing can say.
function CompendiumUI.SkillText(skills)
    local parts = {}
    for i, skill in ipairs(skills) do
        local text = ns.Taming.Label(skill):gsub(" %(Rank (%d+)%)", " %1")
        local known = ns.Taming:Knows(skill)
        if known == true then
            text = Colored("good", text)
        elseif known == false then
            text = Colored("loss", text)
        end
        parts[i] = text
    end
    return table.concat(parts, ", ")
end

function CompendiumUI:NameText(entry)
    local name = entry.name
    local key = RANK_COLOR[entry.rank]
    if key then name = Colored(key, name) end
    local below = {}
    local rank = Compendium().RankText(entry)
    if rank then below[#below + 1] = rank end
    if entry.forever then below[#below + 1] = Colored("good", "Forever") end
    if #below > 0 then name = name .. "\n" .. Colored("dim", table.concat(below, "  ")) end
    return name
end

function CompendiumUI:ZoneText(entry)
    if not entry.zone then return Colored("dim", "Not known yet") end
    local where = entry.zone
    if entry.x and entry.y then
        where = where .. "\n" .. Colored("dim", ("%.1f, %.1f"):format(entry.x, entry.y))
    elseif entry.instance then
        where = where .. "\n" .. Colored("dim", entry.instance == "raid" and "Raid" or "Dungeon")
    end
    return where
end

function CompendiumUI:FillRow(row, entry, level)
    row.entry = entry
    if not entry then
        row:Hide()
        return
    end
    row.name:SetText(self:NameText(entry))
    row.family:SetText(entry.family or Colored("dim", "Not known yet"))
    local levelText = Compendium().LevelText(entry)
    if Compendium():CanTame(entry, level) == false then levelText = Colored("loss", levelText) end
    row.level:SetText(levelText)
    row.zone:SetText(self:ZoneText(entry))
    local skills = Compendium():Skills(entry)
    row.skills:SetText(#skills > 0 and self.SkillText(skills) or Colored("dim", "Nothing"))
    row:Show()
end

--- Everything known about a beast, on the game's tooltip.
function CompendiumUI:ShowTooltip(row)
    local entry = rawget(row, "entry")
    local C = Compendium()
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")

    local r, g, b = Theme.Unpack(RANK_COLOR[entry.rank] or "accentHi")
    GameTooltip:AddLine(entry.name, r, g, b)

    local kind = {}
    if C.RankText(entry) then kind[#kind + 1] = C.RankText(entry) end
    kind[#kind + 1] = entry.family or "Family not known yet"
    GameTooltip:AddLine(table.concat(kind, " "), 1, 1, 1)
    if entry.diet then GameTooltip:AddLine("Eats " .. entry.diet, 0.9, 0.9, 0.9, true) end

    local levelText = C.LevelText(entry)
    if levelText ~= "" then
        local can = C:CanTame(entry)
        if can == true then
            GameTooltip:AddLine(("Level %s. You can tame it now."):format(levelText), Theme.Unpack("good"))
        elseif can == false then
            GameTooltip:AddLine(("Level %s. You can tame it from level %d."):format(levelText, entry.min),
                Theme.Unpack("loss"))
        else
            GameTooltip:AddLine("Level " .. levelText, 1, 1, 1)
        end
    end

    GameTooltip:AddLine(" ")
    if entry.zone then
        GameTooltip:AddLine(C.PlaceText(entry), 1, 1, 1, true)
    else
        GameTooltip:AddLine("Where it lives is not known yet.", 0.9, 0.9, 0.9, true)
    end
    if entry.also and #entry.also > 0 then
        GameTooltip:AddLine("Also in " .. table.concat(entry.also, ", "), 0.9, 0.9, 0.9, true)
    end
    if entry.spawns and entry.spawns > 1 and entry.x then
        GameTooltip:AddLine(("%d spawn points; the spot shown is near the middle."):format(entry.spawns),
            0.7, 0.7, 0.7, true)
    end
    local respawn = C.RespawnText(entry)
    if respawn then GameTooltip:AddLine("Comes back after " .. respawn, 0.9, 0.9, 0.9, true) end

    local skills = C:Skills(entry)
    GameTooltip:AddLine(" ")
    if #skills == 0 then
        GameTooltip:AddLine("Taming it teaches nothing new.", 0.9, 0.9, 0.9, true)
    else
        GameTooltip:AddLine("Taming it teaches", Theme.Unpack("accent"))
        for _, skill in ipairs(skills) do
            local known = ns.Taming:Knows(skill)
            local key = known == true and "good" or known == false and "loss" or "text"
            local tail = known == true and "  (known)" or known == false and "  (not known)" or ""
            GameTooltip:AddLine("  " .. ns.Taming.Label(skill) .. tail, Theme.Unpack(key))
        end
    end

    local forever = C.ForeverText(entry)
    if forever then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(forever, Theme.Unpack("good"))
        local classic = entry.classic
        if classic and classic.zone and classic.zone ~= entry.zone then
            GameTooltip:AddLine(("Classic had it in %s."):format(classic.zone), 0.7, 0.7, 0.7, true)
        end
        if entry.source then
            local site = entry.source:match("^https?://([^/]+)") or entry.source
            GameTooltip:AddLine("Source: " .. site:gsub("^www%.", ""), 0.7, 0.7, 0.7, true)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(entry.zone and "Click to pin it on your map." or "No place to pin yet.",
        0.6, 0.6, 0.6)
    GameTooltip:Show()
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

function CompendiumUI:SortBy(key)
    local o = self:Options()
    if (o.sort or "name") == key then
        o.descending = not o.descending
    else
        o.sort, o.descending = key, false
    end
    self.offset = 0
    self:Refresh()
end

function CompendiumUI:PaintHeadings()
    local sort = self:Options().sort or "name"
    for _, heading in ipairs(self.headings or {}) do
        heading.label:SetTextColor(Theme.Unpack(heading.sortKey == sort and "accent" or "muted"))
    end
end

function CompendiumUI:ScrollBy(steps)
    local most = math.max(0, #(self.lines or {}) - VISIBLE)
    self.offset = math.max(0, math.min(most, (self.offset or 0) + steps))
    self:Draw()
end

function CompendiumUI:Draw()
    local lines = self.lines or {}
    local offset = self.offset or 0
    local level = ns.Compendium:PlayerLevel()
    for index, row in ipairs(self.rows) do
        self:FillRow(row, lines[offset + index], level)
        if rawget(row, "over") == true then
            if rawget(row, "entry") then self:ShowTooltip(row) else GameTooltip:Hide() end
        end
    end

    local total = #lines
    if total > VISIBLE then
        local height = VISIBLE * ROW_HEIGHT
        local size = math.max(16, height * VISIBLE / total)
        local top = (height - size) * offset / (total - VISIBLE)
        self.thumb:SetHeight(size)
        self.thumb:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -PADDING, self.listTop - top)
        self.thumb:Show()
        self.track:Show()
    else
        self.thumb:Hide()
        self.track:Hide()
    end
end

--- Read the choices back into the controls, which /bpet commands and other
--- windows may have changed.
function CompendiumUI:SyncControls()
    local o = self:Options()
    self.families = ns.Compendium:Families()
    local index = 0
    for i, name in ipairs(self.families) do
        if name == o.family then index = i end
    end
    if o.family and index == 0 then o.family = nil end
    -- The stepper's range follows the families there are.
    local stepper = self.familyStepper
    stepper.minus:SetScript("OnClick", function()
        if (stepper.value or 0) > 0 then stepper:SetValue(stepper.value - 1) end
    end)
    stepper.plus:SetScript("OnClick", function()
        if (stepper.value or 0) < #self.families then stepper:SetValue(stepper.value + 1) end
    end)
    stepper.value = index
    stepper.text:SetText(self.families[index] or "All families")
    stepper.minus:SetLabelColor(index <= 0 and "dim" or nil)
    stepper.plus:SetLabelColor(index >= #self.families and "dim" or nil)

    for key, box in pairs(self.ticks) do box:SetChecked(o[key] == true) end
    self:PaintHeadings()
end

function CompendiumUI:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end
    self:SyncControls()

    self.lines = ns.Compendium:List(self:Filter())
    local most = math.max(0, #self.lines - VISIBLE)
    self.offset = math.min(self.offset or 0, most)
    self:Draw()

    local level = ns.Compendium:PlayerLevel()
    self.subtitle:SetText(level and ("Beasts a hunter can tame. You are level %d."):format(level)
        or "Beasts a hunter can tame.")

    local shown, total = #self.lines, #ns.Compendium:All()
    self.empty:SetShown(shown == 0)
    self.empty:SetText("No beast matches. Untick a box or clear the search.")
    if shown == total then
        self.footer:SetText(("%d beasts"):format(total))
    else
        self.footer:SetText(("%d of %d beasts"):format(shown, total))
    end
end

--------------------------------------------------------------------------------
-- Position and visibility
--------------------------------------------------------------------------------

function CompendiumUI:SavePosition()
    if not (ns.db and self.frame) then return end
    local point, _, relativePoint, x, y = self.frame:GetPoint()
    local o = self:Options()
    o.point, o.relativePoint, o.x, o.y = point, relativePoint, x, y
end

function CompendiumUI:RestorePosition()
    if not self.frame then return end
    local o = self:Options()
    self.frame:ClearAllPoints()
    self.frame:SetPoint(o.point or "CENTER", UIParent, o.relativePoint or "CENTER", o.x or 0, o.y or 20)
end

function CompendiumUI:Show()
    self:Build()
    if not self.frame:IsShown() then
        self:RestorePosition()
        self.frame:Show()
        ns.Motion:Open(self.frame)
        if ns.Titanforged then ns.Titanforged:Opened(self.frame) end
    end
    self:Refresh()
end

function CompendiumUI:Hide()
    if self.frame then self.frame:Hide() end
end

function CompendiumUI:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

ns.RegisterCommand("compendium", "open the Pet Compendium: every beast you can tame", function(rest)
    if type(rest) == "string" and rest:match("%S") then
        CompendiumUI.searchText = rest:match("^%s*(.-)%s*$")
        CompendiumUI:Show()
        if CompendiumUI.search then CompendiumUI.search:SetText(CompendiumUI.searchText) end
        CompendiumUI.offset = 0
        CompendiumUI:Refresh()
        return
    end
    CompendiumUI:Toggle()
end)
ns.commands.beasts = ns.commands.compendium
