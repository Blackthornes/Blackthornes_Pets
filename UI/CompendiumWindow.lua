-- Blackthornes Pets -- UI/CompendiumWindow.lua
-- The Pet Compendium: every beast a hunter can tame, what taming it teaches,
-- when it can be tamed, where it lives and how rare it is, with what WoW:
-- Forever has shown marked in green.
--
-- It wears the whole house frame, like the pets window: the paw in the
-- portrait, the name on the plate and the close gem. Above the list is the
-- option bar (the family chooser, the search, then the tick boxes), and the
-- list's headings sort it. A click on a beast pins it on the map; a
-- Shift-click points the beast arrow at it (UI/BeastArrow.lua), and the
-- Arrow button by Settings shows or hides that arrow. The
-- choices are kept, account wide, in BlackthornesPetsDB.compendium.

local _, ns = ...
local L = ns.L

local CompendiumUI = ns.NewModule("CompendiumUI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local WIDTH = ns.PetsTabs and ns.PetsTabs.WIDTH or 820
local HEIGHT = ns.PetsTabs and ns.PetsTabs.HEIGHT or 586
local PADDING = 18
local EDGE_PAD = 11
local HEADER = 44
local BAR_GAP = 8
local ROW_HEIGHT = 34
local VISIBLE = 11
local SCROLL_WIDTH = 4
-- The game's knob, in the Blizzard window style, needs room to read as one.
local BLIZZARD_SCROLL_WIDTH = 10
-- How wide the bar is to the mouse: wider than it looks, so it is easy to
-- catch, and it takes the click so the window is not dragged instead.
local GRIP_WIDTH = 16

-- The list's columns: where each starts in a row, and how wide it is.
local COLUMNS = {
    { key = "name", label = L["Beast"], sortTip = L["Sort by beast"], x = 10, width = 206 },
    { key = "family", label = L["Family"], sortTip = L["Sort by family"], x = 220, width = 78 },
    { key = "level", label = L["Level"], sortTip = L["Sort by level"], x = 292, width = 48 },
    { key = "speed", label = L["Speed"], sortTip = L["Sort by speed"], x = 344, width = 46,
      tip = L["Seconds between its attacks. Lower is faster."] },
    { key = "zone", label = L["Where"], sortTip = L["Sort by where"], x = 394, width = 170 },
    { key = "skills", label = L["Teaches"], x = 578, width = 188 },
}

-- Room a heading keeps for its sort arrow, and the space between columns.
local ARROW_ROOM = 16
local COLUMN_GAP = 4
-- The columns that give room up, in turn, and the least each keeps.
local GIVERS = { "skills", "zone", "name" }
local GIVER_LEAST = 120

-- The Beast Sheet beside the list (the owner said build it from a mockup,
-- 2026-11-26): how wide it is, the gap before it, and the columns the list
-- keeps while it is open. Family and Where move onto the sheet.
local SHEET_WIDTH = 286
local SHEET_GAP = 10
local SHEET_PAD = 12
local SHEET_MAP = 100
local SHEET_LINE = 22
local SHEET_ICON = 40
local NARROW_KEYS = { name = true, level = true, speed = true, skills = true }

-- A pet's usual swing time; quicker is green, slower amber.
local USUAL_SPEED = 2.0

-- The colour a beast's name takes for its rank.
local RANK_COLOR = { rare = "rare", rareelite = "rare", elite = "warn" }

-- Each beast wears its family's icon at the start of its row (the owner
-- said build it from a mockup, 2026-11-24). These are the game's own icons,
-- named here and drawn by the client; none ships with the addon. A family
-- with none here wears the Beast Taming icon.
local ICONS = [[Interface\Icons\]]
local FAMILY_ICON = {
    ["Bat"] = "Ability_Hunter_Pet_Bat",
    ["Bear"] = "Ability_Hunter_Pet_Bear",
    ["Boar"] = "Ability_Hunter_Pet_Boar",
    ["Carrion Bird"] = "Ability_Hunter_Pet_Vulture",
    ["Cat"] = "Ability_Hunter_Pet_Cat",
    ["Core Hound"] = "Ability_Hunter_Pet_CoreHound",
    ["Crab"] = "Ability_Hunter_Pet_Crab",
    ["Crocolisk"] = "Ability_Hunter_Pet_Crocolisk",
    ["Gorilla"] = "Ability_Hunter_Pet_Gorilla",
    ["Hyena"] = "Ability_Hunter_Pet_Hyena",
    ["Owl"] = "Ability_Hunter_Pet_Owl",
    ["Raptor"] = "Ability_Hunter_Pet_Raptor",
    ["Scorpid"] = "Ability_Hunter_Pet_Scorpid",
    ["Spider"] = "Ability_Hunter_Pet_Spider",
    ["Tallstrider"] = "Ability_Hunter_Pet_TallStrider",
    ["Turtle"] = "Ability_Hunter_Pet_Turtle",
    ["Wind Serpent"] = "Ability_Hunter_Pet_WindSerpent",
    ["Wolf"] = "Ability_Hunter_Pet_Wolf",
}
local ANY_FAMILY_ICON = "Ability_Hunter_BeastTaming"
local FAMILY_ICON_SIZE = 22
-- How far the beast's name starts past its family icon.
local NAME_INDENT = FAMILY_ICON_SIZE + 8

-- A skill a beast teaches is a small tag: its icon and its name and rank.
local TAG_HEIGHT = 15
local TAG_ICON = 11
local TAG_GAP = 4
local TAG_LINES = 2

--- The icon for a beast's family (by its English name), as a path. Where
--- the client can say whether it has a file, a family whose icon it lacks
--- wears Beast Taming's. Asked once a family.
local familyIcons = {}
function CompendiumUI.FamilyIcon(family)
    local key = family or false
    local kept = familyIcons[key]
    if kept then return kept end
    local path = ICONS .. (FAMILY_ICON[family] or ANY_FAMILY_ICON)
    if FAMILY_ICON[family] and type(_G.GetFileIDFromPath) == "function" then
        local ok, id = pcall(_G.GetFileIDFromPath, path)
        if ok and not id then path = ICONS .. ANY_FAMILY_ICON end
    end
    familyIcons[key] = path
    return path
end

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
            title = "Blackthornes Pets",
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

    -- The fold gem beside the close gem folds the window down to its plate
    -- (UI/FoldWindow.lua, a player asked, 2026-10-24).
    if ns.FoldWindow then
        ns.FoldWindow:Add(frame, { key = "Compendium", onToggle = function(folded)
            if not folded then CompendiumUI:Refresh() end
        end })
    end
    -- And left of it, the swap gem: it joins every Blackthornes addon into
    -- the one window (UI/SharedWindow.lua).
    if ns.SharedWindow and ns.SharedWindow.AddSwap then ns.SharedWindow.AddSwap(frame, "pets") end

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        CompendiumUI:SavePosition()
    end)

    -- The house size grip under the bottom right corner (Widgets.WindowGrip),
    -- saved as `windowScale`, the one every tab shares (`compendiumScale`,
    -- from before the tabs, stays in the save unread).
    self.sizeGrip = Widgets.WindowGrip(frame, "windowScale", function()
        CompendiumUI:SavePosition()
    end)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) CompendiumUI:ScrollBy(-delta) end)

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsCompendium")
    end

    self.frame = frame
    if ns.PetsTabs then ns.PetsTabs:Attach(self, "compendium") end
    -- Inside the one window, it closes with this one.
    frame:HookScript("OnHide", function() if ns.PetsTabs then ns.PetsTabs:Closed(frame) end end)
    -- The pets window puts its Feed button away while this is open.
    if ns.UI and ns.UI.WatchCover then ns.UI:WatchCover(frame) end
    self:BuildHeader()
    self:BuildBar()
    self:BuildHeadings()
    self:BuildList()
    self:BuildSheet()
    self.wideColumns = {}
    for i, column in ipairs(COLUMNS) do self.wideColumns[i] = { x = column.x, width = column.width } end

    -- The house footer (the owner, 2026-10-29): the count on the left,
    -- the version small and faint on the right. What a click does is the
    -- last line of each beast's hover.
    local version = Theme.CreateLabel(frame, "tiny", "dim", "RIGHT")
    version:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    version:SetText(ns.VersionLabel and ns.VersionLabel() or "")
    self.versionLabel = version

    local footer = Theme.CreateLabel(frame, "small", "text")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("RIGHT", version, "LEFT", -12, 0)
    self.footer = footer

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

    -- The house header (the owner, 2026-10-29): the search on the left past
    -- the portrait, which reaches 48 pixels into the window, then the family
    -- drop-down. What the old line under the plate said is on the hovers.
    local search = Widgets.CreateSearchBox(header, L["Search beasts, zones or skills"], function(text)
        CompendiumUI.searchText = text
        CompendiumUI.offset = 0
        CompendiumUI:Refresh()
    end)
    search:SetPoint("LEFT", header, "LEFT", 48, -2)
    search:SetWidth(260)
    self.search = search

    -- A drop-down of every family (a player asked, the owner agreed
    -- 2026-10-11; it was a stepper that went one family at a time), wide
    -- enough for the longest name in either language.
    local options = self:FamilyOptions()
    local family = Widgets.CreateDropdown(header, options, function(value)
        CompendiumUI:Options().family = value or nil
        CompendiumUI.offset = 0
        CompendiumUI:Refresh()
    end, { width = Widgets.DropdownWidth(options, 170) })
    family:SetPoint("LEFT", search, "RIGHT", 14, 0)
    family:SetValue(false)
    self.familyDropdown = family
end

--- The beast arrow's switch, at the right end of the filter row: lit green
--- while it is up.
function CompendiumUI:BuildArrowButton(parent, anchorY)
    local arrow = Widgets.CreateButton(parent, L["Arrow"], function()
        if ns.BeastArrow then ns.HandleSlash(ns.BeastArrow.IsOn() and "arrow off" or "arrow on") end
    end, { width = 60, height = 20 })
    arrow:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING, anchorY)
    arrow:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Beast arrow"], Theme.Unpack("accent"))
        GameTooltip:AddLine(L["Points the way to a beast. Shift-click one in the compendium to aim it."],
            1, 1, 1, true)
        GameTooltip:Show()
    end)
    arrow:HookScript("OnLeave", function() GameTooltip:Hide() end)
    self.arrowButton = arrow
    self:OnBeastArrowChanged()
end

--- The beast arrow turned on or off: relight its button.
function CompendiumUI:OnBeastArrowChanged()
    if self.arrowButton and self.arrowButton.SetLabelColor then
        self.arrowButton:SetLabelColor(ns.BeastArrow and ns.BeastArrow.IsOn() and "good" or "gilt")
    end
end

--- The family dropdown's choices: every family first, then each family in
--- name order. `false` stands for every family.
function CompendiumUI:FamilyOptions()
    local options = { { text = L["All families"], value = false } }
    for _, name in ipairs(ns.Compendium:Families()) do
        options[#options + 1] = { text = name, value = name }
    end
    return options
end

--- The option bar: the family chooser and the search on one line, the tick
--- boxes under them.
function CompendiumUI:BuildBar()
    local frame = self.frame
    local top = -(HEADER + 12)

    local ticks = {
        { key = "tameNow", text = L["Tameable Now"],
          tip = L["Only beasts at or below your level."] },
        { key = "raresOnly", text = L["Rares Only"] },
        { key = "newSkills", text = L["Teaches Me Something New"],
          tip = L["Only beasts that teach a skill you don't have yet."] },
        { key = "foreverOnly", text = L["Seen on Forever"],
          tip = L["Only beasts known to live on WoW: Forever."] },
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
            box:SetPoint("TOPLEFT", PADDING, top - 2)
        end
        -- A box whose label says it all has no hover.
        if spec.tip then
            box:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(spec.text, 1, 1, 1)
                GameTooltip:AddLine(spec.tip, 0.9, 0.9, 0.9, true)
                -- The level, which the line under the plate once said.
                local level = spec.key == "tameNow" and ns.Compendium:PlayerLevel()
                if level then GameTooltip:AddLine(L.Format("You are level %d.", level), 0.9, 0.9, 0.9, true) end
                GameTooltip:Show()
            end)
            box:HookScript("OnLeave", function() GameTooltip:Hide() end)
        end
        self.ticks[spec.key] = box
        previous = box
    end

    self:BuildArrowButton(frame, top)
    self.barBottom = top - 18 - BAR_GAP
end

--- Give each column room for its heading and sort arrow: "VELOCIDAD" and
--- its arrow ran into the next heading in a column sized for "SPEED". The
--- room comes out of the wide columns, so the list stays as wide as it was.
--- `measure(text)` is how wide a heading draws.
function CompendiumUI.FitColumns(columns, measure)
    local grown = 0
    for _, column in ipairs(columns) do
        local need = measure(column.label:upper()) + (column.key ~= "skills" and ARROW_ROOM or 0)
        if need > column.width then
            grown = grown + need - column.width
            column.width = need
        end
    end
    for _, key in ipairs(GIVERS) do
        for _, column in ipairs(columns) do
            if column.key == key and grown > 0 and column.width > GIVER_LEAST then
                local give = math.min(grown, column.width - GIVER_LEAST)
                column.width = column.width - give
                grown = grown - give
            end
        end
    end
    local x = columns[1].x
    for _, column in ipairs(columns) do
        column.x = x
        x = x + column.width + COLUMN_GAP
    end
    return columns
end

--- The headings, which sort the list: a click sorts by that column, a
--- second click turns it round, a third goes back to sorting by beast.
function CompendiumUI:BuildHeadings()
    local frame = self.frame
    self.headings = {}
    if not self.columnsFitted then
        self.columnsFitted = true
        CompendiumUI.FitColumns(COLUMNS, function(text) return Theme.TextWidth("tiny", text) end)
    end
    for _, column in ipairs(COLUMNS) do
        local heading = CreateFrame("Button", nil, frame)
        heading:SetSize(column.width, 18)
        heading:SetPoint("TOPLEFT", PADDING + column.x, self.barBottom)
        local label = Theme.CreateLabel(heading, "tiny", "heading")
        label:SetPoint("LEFT", 0, 0)
        label:SetText(column.label:upper())
        heading.label = label
        -- The house sort arrow (Media/Frame/SortArrow.tga, Equipment's),
        -- down for the first click, up once flipped.
        local sortArrow = heading:CreateTexture(nil, "OVERLAY")
        sortArrow:SetTexture((ns.Titanforged and ns.Titanforged.MEDIA or "") .. "SortArrow")
        sortArrow:SetSize(10, 10)
        sortArrow:SetVertexColor(Theme.Unpack("accent"))
        sortArrow:SetPoint("LEFT", label, "RIGHT", 3, 0)
        sortArrow:Hide()
        heading.arrow = sortArrow
        heading.column = column

        local sortKey = column.key ~= "skills" and column.key or nil
        heading.sortKey = sortKey
        if sortKey then
            heading:SetScript("OnClick", function() CompendiumUI:SortBy(sortKey) end)
            heading:SetScript("OnEnter", function(self)
                self.label:SetTextColor(Theme.Unpack("accentHi"))
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(column.sortTip, 1, 1, 1)
                if column.tip then GameTooltip:AddLine(column.tip, 0.9, 0.9, 0.9, true) end
                GameTooltip:AddLine(L["Click again to flip it, and once more to go back."], 0.9, 0.9, 0.9, true)
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
    self.visible = VISIBLE

    local well = Theme.CreatePanel(frame, "panel", "border")
    well:SetPoint("TOPLEFT", PADDING - 3, self.listTop + 3)
    self.listRight = self.listRight or PADDING
    well:SetPoint("TOPRIGHT", -(self.listRight - 3), self.listTop + 3)
    well:SetHeight(self.visible * ROW_HEIGHT + 6)
    if Theme.Recess then Theme.Recess(well) end
    self.well = well

    local thumb = well:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(Theme.Unpack("accent", 0.8))
    -- The game's knob in the Blizzard window style (UI/BlizzardLook.lua),
    -- which needs a wider bar than the house's thin one or it is squashed
    -- to a sliver.
    self.scrollWidth = SCROLL_WIDTH
    if ns.BlizzardLook and ns.BlizzardLook.Thumb(thumb) then self.scrollWidth = BLIZZARD_SCROLL_WIDTH end
    thumb:SetWidth(self.scrollWidth)
    self.thumb = thumb

    local track = well:CreateTexture(nil, "ARTWORK")
    track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -self.listRight, self.listTop)
    track:SetSize(self.scrollWidth, self.visible * ROW_HEIGHT)
    track:SetColorTexture(Theme.Unpack("rowAlt"))
    self.track = track

    -- What the mouse catches: the bar and a little either side, above the
    -- rows. Holding it drags the thumb; a click on the bar jumps there.
    local grip = CreateFrame("Frame", nil, frame)
    grip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(self.listRight - (GRIP_WIDTH - self.scrollWidth) / 2), self.listTop)
    grip:SetSize(GRIP_WIDTH, self.visible * ROW_HEIGHT)
    grip:SetFrameLevel(frame:GetFrameLevel() + 10)
    grip:EnableMouse(true)
    grip:SetScript("OnMouseDown", function(_, button)
        if button == nil or button == "LeftButton" then CompendiumUI:StartScrollDrag() end
    end)
    grip:SetScript("OnMouseUp", function() CompendiumUI:StopScrollDrag() end)
    grip:SetScript("OnHide", function() CompendiumUI:StopScrollDrag() end)
    self.grip = grip

    self.rows, self.allRows = {}, {}
    for index = 1, self.visible do
        self.allRows[index] = self:BuildRow(index)
        self.rows[index] = self.allRows[index]
    end

    -- The house empty block (Widgets.CreateEmpty): the paw faint, one line
    -- and a button that clears every filter.
    local empty = Widgets.CreateEmpty(well, { width = WIDTH - PADDING * 4 })
    empty:SetPoint("TOP", frame, "TOP", 0, self.listTop - 40)
    self.empty = empty
end

--- The window took the size every tab shares (UI/PetsTabs.lua): more rows
--- fill a taller window, so the list never ends short of the hint.
function CompendiumUI:OnTabSize(_, height)
    if not self.allRows then return end
    local visible = math.max(VISIBLE, VISIBLE + math.floor(((height or HEIGHT) - HEIGHT) / ROW_HEIGHT))
    if visible == self.visible then return end
    self.visible = visible
    self.rows = {}
    for index = 1, visible do
        self.allRows[index] = self.allRows[index] or self:BuildRow(index)
        self.rows[index] = self.allRows[index]
    end
    for index = visible + 1, #self.allRows do self.allRows[index]:Hide() end
    self.well:SetHeight(visible * ROW_HEIGHT + 6)
    self.track:SetHeight(visible * ROW_HEIGHT)
    self.grip:SetHeight(visible * ROW_HEIGHT)
    if self.sheet then self.sheet:SetHeight(visible * ROW_HEIGHT + 6 + 20) end
    self.offset = math.min(self.offset or 0, math.max(0, #(self.lines or {}) - visible))
    if self.frame:IsShown() then self:Draw() end
end

--- A cell's words sit in the middle of the row, one line or two, level
--- with the family icon. `indent` starts them further in (the beast's name,
--- past its icon).
local function Cell(row, column, size, color, indent)
    local label = Theme.CreateLabel(row, size, color)
    label:SetPoint("LEFT", row, "LEFT", column.x + (indent or 0), 0)
    label:SetSize(column.width - (indent or 0), ROW_HEIGHT - 4)
    label:SetWordWrap(true)
    label:SetJustifyV("MIDDLE")
    return label
end

--- A skill tag: dark glass with a fine edge, the skill's icon and its name
--- and rank. Gold for a skill the hunter does not have yet, grey for one
--- they do, plain when nothing can say.
local function CreateTag(row)
    local tag = CreateFrame("Frame", nil, row)
    tag:SetHeight(TAG_HEIGHT)
    tag.background = Theme.Fill(tag, "well", 0.5)
    Theme.Border(tag, "border", 0.8)
    tag.icon = tag:CreateTexture(nil, "ARTWORK")
    tag.icon:SetSize(TAG_ICON, TAG_ICON)
    tag.icon:SetPoint("LEFT", tag, "LEFT", 2, 0)
    if tag.icon.SetTexCoord then tag.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    tag.label = Theme.CreateLabel(tag, "tiny", "text")
    tag.label:SetWordWrap(false)
    return tag
end

-- How wide a tag's words are, kept: the list redraws as it scrolls.
local tagWidths = {}
local function TagTextWidth(text)
    local width = tagWidths[text]
    if not width then
        width = math.ceil(Theme.TextWidth("tiny", text))
        tagWidths[text] = width
    end
    return width
end

--- The colour key for a skill: "accentHi" when it is new to the hunter,
--- "muted" when they have it, "text" when nothing can say.
function CompendiumUI.SkillColor(skill)
    local known = ns.Taming:Knows(skill)
    if known == true then return "muted", true end
    if known == false then return "accentHi", false end
    return "text", nil
end

--- Lay a row's skill tags out in the Teaches column, left to right, on up
--- to TAG_LINES lines. Returns false when they do not fit, and the row
--- shows them as words instead.
function CompendiumUI:LayTags(row, skills)
    local column = COLUMNS[6]
    local tags = rawget(row, "tags")
    if not tags then
        tags = {}
        row.tags = tags
    end
    local places, x, line = {}, 0, 1
    for i, skill in ipairs(skills) do
        local text = ("%s %d"):format(skill.name, skill.rank)
        local icon = ns.PetSkills and ns.PetSkills.Icon(skill.name, skill.rank)
        local width = (icon and (2 + TAG_ICON + 4) or 6) + TagTextWidth(text) + 6
        if x > 0 and x + width > column.width then
            x, line = 0, line + 1
        end
        if line > TAG_LINES then
            for _, tag in ipairs(tags) do tag:Hide() end
            return false
        end
        places[i] = { x = x, line = line, width = width, text = text, icon = icon }
        x = x + width + TAG_GAP
    end

    local top = line == 1 and -math.floor((ROW_HEIGHT - TAG_HEIGHT) / 2) or -1
    for i, place in ipairs(places) do
        local tag = tags[i]
        if not tag then
            tag = CreateTag(row)
            tags[i] = tag
        end
        local key = CompendiumUI.SkillColor(skills[i])
        tag.colorKey = key
        tag.label:SetText(place.text)
        tag.label:SetTextColor(Theme.Unpack(key))
        Theme.SetBorderColor(tag, key == "accentHi" and "accent" or "border", 0.8)
        tag.background:SetColorTexture(Theme.Unpack(key == "accentHi" and "accent" or "well", key == "accentHi" and 0.12 or 0.5))
        tag.icon:SetShown(place.icon ~= nil)
        if place.icon then
            tag.icon:SetTexture(place.icon)
            if tag.icon.SetDesaturated then tag.icon:SetDesaturated(key == "muted") end
        end
        tag.label:ClearAllPoints()
        tag.label:SetPoint("LEFT", tag, "LEFT", place.icon and (2 + TAG_ICON + 4) or 6, 0)
        tag:SetWidth(place.width)
        tag:ClearAllPoints()
        tag:SetPoint("TOPLEFT", row, "TOPLEFT", column.x + place.x,
            top - (place.line - 1) * (TAG_HEIGHT + 2))
        tag:Show()
    end
    for i = #places + 1, #tags do tags[i]:Hide() end
    return true
end

function CompendiumUI:BuildRow(index)
    local row = CreateFrame("Button", nil, self.frame)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", PADDING, self.listTop - (index - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -((self.listRight or PADDING) + (self.scrollWidth or SCROLL_WIDTH) + 2),
        self.listTop - (index - 1) * ROW_HEIGHT)
    row.index = index
    -- Dark glass, a shade apart row by row, with a fine line under each.
    row.rest = index % 2 == 0 and "glassAlt" or "glass"
    row.background = Theme.Fill(row, row.rest)
    row.rule = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.rule:SetPoint("BOTTOMLEFT")
    row.rule:SetPoint("BOTTOMRIGHT")
    row.rule:SetHeight(1)
    row.rule:SetColorTexture(Theme.Unpack("border", 0.6))

    -- A gold bar down the left edge under the mouse, as the house lists do.
    local stripe = row:CreateTexture(nil, "OVERLAY")
    stripe:SetPoint("TOPLEFT")
    stripe:SetPoint("BOTTOMLEFT")
    stripe:SetWidth(2)
    stripe:SetColorTexture(Theme.Unpack("accentHi"))
    stripe:Hide()
    row.stripe = stripe

    -- And a soft gold wash from the left, as the house rows light. Shown
    -- and hidden outright: a gradient faded with SetAlpha stayed lit.
    row.wash = row:CreateTexture(nil, "BORDER", nil, 1)
    row.wash:SetAllPoints(row)
    Theme.SetGradientAlpha(row.wash, "HORIZONTAL", "accent", 0.10, 0)
    row.wash:Hide()

    -- The family's icon in a fine metal frame, the beast's name past it.
    local slot = CreateFrame("Frame", nil, row)
    slot:SetSize(FAMILY_ICON_SIZE, FAMILY_ICON_SIZE)
    slot:SetPoint("LEFT", row, "LEFT", COLUMNS[1].x, 0)
    Theme.Fill(slot, "well")
    Theme.Border(slot, "metal")
    row.familyIcon = slot:CreateTexture(nil, "ARTWORK")
    row.familyIcon:SetPoint("TOPLEFT", 1, -1)
    row.familyIcon:SetPoint("BOTTOMRIGHT", -1, 1)
    if row.familyIcon.SetTexCoord then row.familyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    row.name = Cell(row, COLUMNS[1], "small", "text", NAME_INDENT)
    row.family = Cell(row, COLUMNS[2], "small", "text")
    row.level = Cell(row, COLUMNS[3], "small", "text")
    row.speed = Cell(row, COLUMNS[4], "small", "text")
    row.zone = Cell(row, COLUMNS[5], "small", "text")
    row.skills = Cell(row, COLUMNS[6], "tiny", "text")
    row.cells = {
        { row.name, COLUMNS[1], NAME_INDENT }, { row.family, COLUMNS[2], 0 }, { row.level, COLUMNS[3], 0 },
        { row.speed, COLUMNS[4], 0 }, { row.zone, COLUMNS[5], 0 }, { row.skills, COLUMNS[6], 0 },
    }

    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, button)
        local entry = rawget(self, "entry")
        if not entry then return end
        if button == "RightButton" then
            CompendiumUI:OpenMenu(entry)
            return
        end
        local shift = type(IsShiftKeyDown) == "function" and select(2, pcall(IsShiftKeyDown))
        if shift then
            CompendiumUI:AimArrow(entry)
        elseif CompendiumUI.picked == entry then
            CompendiumUI:CloseSheet()
        else
            CompendiumUI:OpenSheet(entry)
        end
    end)
    row:SetScript("OnEnter", function(self)
        self.over = true
        self.background:SetColorTexture(Theme.Unpack("glassHover"))
        self.stripe:Show()
        self.wash:Show()
        if rawget(self, "entry") then CompendiumUI:ShowTooltip(self) end
    end)
    row:SetScript("OnLeave", function(self)
        self.over = false
        CompendiumUI:PaintRow(self)
        self.wash:Hide()
        GameTooltip:Hide()
    end)
    row:Hide()
    return row
end

--------------------------------------------------------------------------------
-- Words for a row
--------------------------------------------------------------------------------

local Compendium = function() return ns.Compendium end

--- Each skill coloured, for a row whose tags do not fit: gold when it is
--- new to the hunter, grey when they have it, plain when nothing can say.
function CompendiumUI.SkillText(skills)
    local parts = {}
    for i, skill in ipairs(skills) do
        local text = ("%s %d"):format(skill.name, skill.rank)
        local key = CompendiumUI.SkillColor(skill)
        if key ~= "text" then text = Colored(key, text) end
        parts[i] = text
    end
    return table.concat(parts, ", ")
end

function CompendiumUI:NameText(entry)
    local name = entry.name
    local key = RANK_COLOR[entry.rank]
    if key then name = Colored(key, name) end
    -- One line a row (the owner, 2026-10-29): rare and elite are a tag
    -- after the name, as Forever is.
    local rank = Compendium().RankText(entry)
    if rank then name = name .. "  " .. Colored(key or "muted", rank) end
    if entry.forever then name = name .. "  " .. Colored("good", "Forever") end
    return name
end

function CompendiumUI:ZoneText(entry)
    if not entry.zone then return Colored("dim", L["Not known yet"]) end
    -- Where in the zone, and a dungeon or raid, are on the hover.
    return entry.zone
end

--- "1.2" in green when quicker than usual, amber when slower, with "tamed"
--- under it when the number was read off a real pet.
function CompendiumUI:SpeedCell(entry)
    local text = Compendium().SpeedText(entry)
    if not text then return Colored("dim", "-") end
    if entry.speed < USUAL_SPEED then
        text = Colored("good", text)
    elseif entry.speed > USUAL_SPEED then
        text = Colored("warn", text)
    end
    return text
end

function CompendiumUI:FillRow(row, entry, level)
    row.entry = entry
    if not entry then
        row:Hide()
        return
    end
    if rawget(row, "over") ~= true then self:PaintRow(row) end
    row.name:SetText(self:NameText(entry))
    row.family:SetText(entry.family or Colored("dim", L["Not known yet"]))
    local levelText = Compendium().LevelText(entry)
    if Compendium():CanTame(entry, level) == false then levelText = Colored("loss", levelText) end
    row.level:SetText(levelText)
    row.speed:SetText(self:SpeedCell(entry))
    row.zone:SetText(self:ZoneText(entry))
    -- The family's icon is set only when the family changes: the list
    -- redraws as it scrolls.
    if rawget(row, "familyShown") ~= (entry.family or false) then
        row.familyShown = entry.family or false
        row.familyIcon:SetTexture(CompendiumUI.FamilyIcon(entry.family))
    end
    local skills = Compendium():Skills(entry)
    if #skills == 0 then
        self:LayTags(row, skills)
        row.skills:SetText(Colored("dim", L["Nothing"]))
    elseif self:LayTags(row, skills) then
        row.skills:SetText("")
    else
        row.skills:SetText(self.SkillText(skills))
    end
    row:Show()
end

--- The row's menu (UI/RowMenu.lua): the click's own action first.
function CompendiumUI:OpenMenu(entry)
    if not (ns.RowMenu and entry) then return end
    local where = entry.zone ~= nil
    ns.RowMenu:Open({
        { text = L["Show on Map"], disabled = not where, run = function() ns.Compendium:Pin(entry) end },
        { text = L["Show the Way"], disabled = not where, run = function() CompendiumUI:AimArrow(entry) end },
    }, { title = entry.name })
end

--- Point the beast arrow at a beast, and say so.
function CompendiumUI:AimArrow(entry)
    local arrow = ns.BeastArrow
    if not arrow then return false end
    if arrow:Follow(entry) then
        ns.Print(L.Format("beast arrow pointing at %s. Hide it with its red gem, /bpet arrow off or Settings.",
            entry.name or L["it"]))
        return true
    end
    ns.Print(L.Format("where %s lives isn't known yet, so the arrow can't point at it.", entry.name or L["it"]))
    return false
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
    kind[#kind + 1] = entry.family or L["Family not known yet"]
    GameTooltip:AddLine(table.concat(kind, " "), 1, 1, 1)
    if entry.diet then
        -- The data's diet words ("Meat, Fish") as players read them.
        local words = {}
        for word in entry.diet:gmatch("[^,]+") do
            words[#words + 1] = ns.PetFood.Label((word:gsub("^%s+", ""):gsub("%s+$", "")))
        end
        GameTooltip:AddLine(L.Format("Eats %s", table.concat(words, ", ")), 0.9, 0.9, 0.9, true)
    end

    local levelText = C.LevelText(entry)
    if levelText ~= "" then
        local can = C:CanTame(entry)
        if can == true then
            GameTooltip:AddLine(L.Format("Level %s. You can tame it now.", levelText), Theme.Unpack("good"))
        elseif can == false then
            GameTooltip:AddLine(L.Format("Level %s. You can tame it from level %d.", levelText, entry.min),
                Theme.Unpack("loss"))
        else
            GameTooltip:AddLine(L.Format("Level %s", levelText), 1, 1, 1)
        end
    end

    local speed = C.SpeedText(entry)
    if speed then
        local key = entry.speed < USUAL_SPEED and "good" or entry.speed > USUAL_SPEED and "warn" or "text"
        local text = entry.speedSeen and L.Format("Attack speed %s (seen on Forever)", speed)
            or L.Format("Attack speed %s", speed)
        GameTooltip:AddLine(text, Theme.Unpack(key))
    end

    GameTooltip:AddLine(" ")
    if entry.zone then
        GameTooltip:AddLine(C.PlaceText(entry), 1, 1, 1, true)
    else
        GameTooltip:AddLine(L["Where it lives is not known yet."], 0.9, 0.9, 0.9, true)
    end
    if entry.also and #entry.also > 0 then
        GameTooltip:AddLine(L.Format("Also in %s", table.concat(entry.also, ", ")), 0.9, 0.9, 0.9, true)
    end
    if entry.spawns and entry.spawns > 1 and entry.x then
        GameTooltip:AddLine(L.Format("Found in %d spots. This one is near the middle.", entry.spawns),
            0.7, 0.7, 0.7, true)
    end
    local respawn = C.RespawnText(entry)
    if respawn then GameTooltip:AddLine(L.Format("Comes back after %s", respawn), 0.9, 0.9, 0.9, true) end

    local skills = C:Skills(entry)
    GameTooltip:AddLine(" ")
    if #skills == 0 then
        GameTooltip:AddLine(L["Taming it teaches nothing new."], 0.9, 0.9, 0.9, true)
    else
        GameTooltip:AddLine(L["Taming it teaches"], Theme.Unpack("accent"))
        for _, skill in ipairs(skills) do
            local known = ns.Taming:Knows(skill)
            local key = CompendiumUI.SkillColor(skill)
            local tail = known == true and ("  " .. L["(known)"]) or known == false and ("  " .. L["(not known)"]) or ""
            GameTooltip:AddLine("  " .. ns.Taming.Label(skill) .. tail, Theme.Unpack(key))
        end
    end

    local forever = C.ForeverText(entry)
    if forever then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(forever, Theme.Unpack("good"))
    end

    GameTooltip:AddLine(" ")
    -- A click opens the Beast Sheet beside the list.
    GameTooltip:AddLine(L["Click to see more."], 0.6, 0.6, 0.6, true)
    if entry.zone then GameTooltip:AddLine(L["Shift-click to point the arrow at it."], 0.6, 0.6, 0.6, true) end
    GameTooltip:AddLine(L["Right-click for more."], 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
end

--------------------------------------------------------------------------------
-- The Beast Sheet (the owner said build it from a mockup, 2026-11-26)
--
-- A click on a row opens a sheet beside the list with everything about that
-- beast and how it compares to your pet, as Equipment's Find Upgrades does.
-- While it is open the list keeps Beast, Level, Speed and Teaches; Family
-- and Where are on the sheet. A second click on the row, or its red gem,
-- closes it. Shift-click and the right-click menu are as they were.
--------------------------------------------------------------------------------

--- A row at rest: dark glass, or gold in the dark with a gold edge down its
--- left while its beast is on the sheet.
function CompendiumUI:PaintRow(row)
    local picked = self.picked ~= nil and rawget(row, "entry") == self.picked
    row.background:SetColorTexture(Theme.Unpack(picked and "glassActive" or row.rest))
    row.stripe:SetShown(picked)
end

--- Lay the columns out: every one, or only those the list keeps beside the
--- sheet, with Teaches taking what is left.
function CompendiumUI:LayColumns(narrow)
    local wide = self.wideColumns
    if not wide then return end
    local x = COLUMNS[1].x
    local listWidth = (self.frame:GetWidth() or WIDTH) - PADDING - self.listRight
        - (self.scrollWidth or SCROLL_WIDTH) - 2
    for i, column in ipairs(COLUMNS) do
        column.shown = not narrow or NARROW_KEYS[column.key] == true
        column.width = wide[i].width
        if column.shown then
            column.x = x
            if narrow and column.key == "skills" then
                column.width = math.max(listWidth - x - 6, 100)
            end
            x = x + column.width + COLUMN_GAP
        end
    end
    if not narrow then
        for i, column in ipairs(COLUMNS) do column.x = wide[i].x end
    end
    for _, heading in ipairs(self.headings or {}) do
        local column = heading.column
        heading:SetShown(column.shown)
        heading:SetWidth(column.width)
        heading:ClearAllPoints()
        heading:SetPoint("TOPLEFT", PADDING + column.x, self.barBottom)
    end
    for _, row in ipairs(self.allRows or {}) do
        for _, cell in ipairs(row.cells) do
            local label, column, indent = cell[1], cell[2], cell[3]
            label:SetShown(column.shown)
            label:ClearAllPoints()
            label:SetPoint("LEFT", row, "LEFT", column.x + indent, 0)
            label:SetSize(column.width - indent, ROW_HEIGHT - 4)
        end
    end
end

--- Move the list's right edge: PADDING alone, or past the sheet.
function CompendiumUI:SetListRight(right)
    self.listRight = right
    self.well:SetPoint("TOPRIGHT", -(right - 3), self.listTop + 3)
    self.track:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -right, self.listTop)
    self.grip:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -(right - (GRIP_WIDTH - self.scrollWidth) / 2), self.listTop)
    for _, row in ipairs(self.allRows or {}) do
        row:SetPoint("TOPRIGHT", -(right + (self.scrollWidth or SCROLL_WIDTH) + 2),
            self.listTop - (row.index - 1) * ROW_HEIGHT)
    end
end

--- A label on the left and its value on the right, with a fine line under.
local function SheetLine(sheet, label)
    local line = CreateFrame("Frame", nil, sheet)
    line:SetHeight(SHEET_LINE)
    line.label = Theme.CreateLabel(line, "small", "muted")
    line.label:SetPoint("LEFT", 0, 0)
    line.label:SetText(label)
    line.value = Theme.CreateLabel(line, "small", "text", "RIGHT")
    line.value:SetPoint("RIGHT", 0, 0)
    line.value:SetPoint("LEFT", line.label, "RIGHT", 8, 0)
    line.value:SetWordWrap(true)
    local rule = line:CreateTexture(nil, "BORDER")
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")
    rule:SetHeight(1)
    rule:SetColorTexture(Theme.Unpack("border", 0.6))
    return line
end

function CompendiumUI:BuildSheet()
    local frame = self.frame
    local sheet = Theme.CreatePanel(frame, "panel", "border")
    sheet:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(PADDING - 3), self.barBottom + 3)
    sheet:SetWidth(SHEET_WIDTH)
    sheet:SetHeight(self.visible * ROW_HEIGHT + 6 + 20)
    sheet:EnableMouse(true)
    sheet:Hide()
    self.sheet = sheet
    local inner = SHEET_WIDTH - SHEET_PAD * 2

    -- The family's icon, the beast's name and what it is.
    local slot = CreateFrame("Frame", nil, sheet)
    slot:SetSize(SHEET_ICON, SHEET_ICON)
    slot:SetPoint("TOPLEFT", SHEET_PAD, -SHEET_PAD)
    Theme.Fill(slot, "well")
    Theme.Border(slot, "metal")
    sheet.icon = slot:CreateTexture(nil, "ARTWORK")
    sheet.icon:SetPoint("TOPLEFT", 1, -1)
    sheet.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    if sheet.icon.SetTexCoord then sheet.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    sheet.name = Theme.CreateLabel(sheet, "large", "accentHi")
    sheet.name:SetPoint("TOPLEFT", slot, "TOPRIGHT", 10, -2)
    sheet.name:SetWidth(inner - SHEET_ICON - 10 - 24)
    sheet.name:SetWordWrap(true)
    sheet.kind = Theme.CreateLabel(sheet, "small", "muted")
    sheet.kind:SetPoint("TOPLEFT", sheet.name, "BOTTOMLEFT", 0, -3)
    sheet.kind:SetWidth(inner - SHEET_ICON - 10)
    sheet.kind:SetWordWrap(true)

    -- The red close gem (the X) in its top right corner.
    local close
    if ns.Titanforged and ns.Titanforged.CloseGem then
        close = ns.Titanforged.CloseGem(sheet, function() CompendiumUI:CloseSheet() end)
        close:SetSize(20, 20)
    else
        close = Widgets.CreateButton(sheet, "X", function() CompendiumUI:CloseSheet() end, { width = 20, height = 20 })
    end
    close:ClearAllPoints()
    close:SetPoint("TOPRIGHT", sheet, "TOPRIGHT", -8, -8)
    sheet.close = close

    -- A small picture of where it lives: the zone's name and one gold dot.
    local map = CreateFrame("Frame", nil, sheet)
    map:SetSize(inner, SHEET_MAP)
    map:SetPoint("TOPLEFT", slot, "BOTTOMLEFT", 0, -12)
    Theme.Fill(map, "well")
    Theme.Border(map, "border")
    local glow = map:CreateTexture(nil, "BORDER")
    glow:SetPoint("TOPLEFT", 1, -1)
    glow:SetPoint("BOTTOMRIGHT", -1, 1)
    glow:SetColorTexture(1, 1, 1, 1)
    Theme.SetGradientAlpha(glow, "VERTICAL", "accent", 0.04, 0.14)
    local media = ns.Titanforged and ns.Titanforged.MEDIA or ""
    map.halo = map:CreateTexture(nil, "ARTWORK")
    map.halo:SetTexture(media .. "Glow")
    map.halo:SetSize(26, 26)
    map.halo:SetVertexColor(Theme.Unpack("accent"))
    if map.halo.SetBlendMode then map.halo:SetBlendMode("ADD") end
    map.dot = map:CreateTexture(nil, "OVERLAY")
    map.dot:SetTexture(media .. "TravelDot")
    map.dot:SetSize(10, 10)
    map.dot:SetVertexColor(Theme.Unpack("accentHi"))
    map.halo:SetPoint("CENTER", map.dot, "CENTER")
    map.caption = Theme.CreateLabel(map, "small", "muted")
    map.caption:SetPoint("BOTTOMLEFT", 8, 6)
    map.caption:SetWidth(inner - 16)
    map.caption:SetWordWrap(true)
    sheet.map = map

    sheet.speed = SheetLine(sheet, L["Speed"])
    sheet.eats = SheetLine(sheet, L["Eats"])
    sheet.level = SheetLine(sheet, L["Level"])

    sheet.teachHead = Theme.CreateLabel(sheet, "small", "muted")
    sheet.teachHead:SetText(L["Taming it teaches"])
    sheet.tags, sheet.news = {}, {}
    sheet.nothing = Theme.CreateLabel(sheet, "small", "muted")
    sheet.nothing:SetText(L["Taming it teaches nothing new."])
    sheet.nothing:SetWidth(inner)
    sheet.nothing:SetWordWrap(true)

    sheet.way = Widgets.CreateButton(sheet, L["Show the Way"], function()
        if CompendiumUI.picked and CompendiumUI.picked.zone then CompendiumUI:AimArrow(CompendiumUI.picked) end
    end, { primary = true, width = 100, height = 24 })
    sheet.pin = Widgets.CreateButton(sheet, L["Show on Map"], function()
        if CompendiumUI.picked and CompendiumUI.picked.zone then ns.Compendium:Pin(CompendiumUI.picked) end
    end, { primary = true, width = 100, height = 24 })
    sheet.pin:SetPoint("LEFT", sheet.way, "RIGHT", 10, 0)
end

--- Your pet's name and attack speed, for the sheet to compare against, or
--- nil with no pet out (or one the game won't read).
function CompendiumUI.PetSpeed()
    local function Call(fn, ...)
        if type(fn) ~= "function" then return nil end
        local ok, a, b = pcall(fn, ...)
        if ok then return a, b end
    end
    if Call(_G.UnitExists, "pet") ~= true then return nil end
    local name = Call(_G.UnitName, "pet")
    local ok, speed = pcall(function()
        local value = Call(_G.UnitAttackSpeed, "pet")
        return value + 0
    end)
    if not (ok and type(name) == "string" and name ~= "" and type(speed) == "number" and speed > 0) then return nil end
    return name, speed
end

--- What the Speed line says: the beast's speed and how it compares to your
--- pet's.
function CompendiumUI.SpeedWords(entry, petName, petSpeed)
    local text = Compendium().SpeedText(entry)
    if not text then return Colored("dim", "-") end
    local key = entry.speed < USUAL_SPEED and "good" or entry.speed > USUAL_SPEED and "warn" or nil
    local shown = key and Colored(key, text) or text
    if petName and petSpeed then
        local pet = ("%.1f"):format(petSpeed)
        if ("%.1f"):format(entry.speed) ~= pet then
            local words = entry.speed < petSpeed and L.Format("Faster than %s (%s)", petName, pet)
                or L.Format("Slower than %s (%s)", petName, pet)
            shown = shown .. " " .. Colored("muted", words)
        end
    end
    return shown
end

--- What the Level line says, and its colour.
function CompendiumUI.TameWords(entry, level)
    local can = Compendium():CanTame(entry, level)
    if can == true then return L["You can tame it now"], "good" end
    if can == false then return L.Format("You can tame it at level %d", entry.min), "loss" end
    local text = Compendium().LevelText(entry)
    return text ~= "" and text or "-", "text"
end

--- The diet as players read it: "Meat, Fish".
function CompendiumUI.DietWords(entry)
    if not entry.diet then return nil end
    local words = {}
    for word in entry.diet:gmatch("[^,]+") do
        local plain = word:gsub("^%s+", ""):gsub("%s+$", "")
        words[#words + 1] = ns.PetFood and ns.PetFood.Label(plain) or plain
    end
    return table.concat(words, ", ")
end

--- Open the sheet on a beast. The list narrows beside it.
function CompendiumUI:OpenSheet(entry)
    if not (entry and self.sheet) then return end
    self.picked = entry
    if not self.sheet:IsShown() then
        self.sheet:Show()
        self:SetListRight(PADDING + SHEET_WIDTH + SHEET_GAP)
        self.empty:ClearAllPoints()
        self.empty:SetPoint("TOP", self.well, "TOP", 0, -40)
    end
    -- Laid out each time: the window may have grown for another tab.
    self:LayColumns(true)
    self:FillSheet(entry)
    if self.frame:IsShown() then self:Draw() end
end

--- Close the sheet, and the list takes the whole width again.
function CompendiumUI:CloseSheet()
    if not self.sheet then return end
    self.picked = nil
    if self.sheet:IsShown() then
        self.sheet:Hide()
        self:SetListRight(PADDING)
        self:LayColumns(false)
        self.empty:ClearAllPoints()
        self.empty:SetPoint("TOP", self.frame, "TOP", 0, self.listTop - 40)
    end
    if self.frame:IsShown() then self:Draw() end
end

function CompendiumUI:FillSheet(entry)
    local sheet = self.sheet
    local C = Compendium()
    local inner = SHEET_WIDTH - SHEET_PAD * 2
    sheet.icon:SetTexture(CompendiumUI.FamilyIcon(entry.family))
    sheet.name:SetText(entry.name or "")
    sheet.name:SetTextColor(Theme.Unpack(RANK_COLOR[entry.rank] or "accentHi"))
    local family = entry.family or L["Family not known yet"]
    local rank = C.RankText(entry)
    if rank then family = Colored(RANK_COLOR[entry.rank] or "muted", rank) .. " " .. family end
    local levelText = C.LevelText(entry)
    sheet.kind:SetText(levelText ~= "" and L.Format("%s, level %s", family, levelText) or family)

    -- The dot sits where the beast lives in its zone, or in the middle when
    -- only the zone is known.
    local map = sheet.map
    local where = entry.zone ~= nil
    map.dot:SetShown(where)
    map.halo:SetShown(where)
    if where then
        local x = math.max(0.06, math.min(0.94, (tonumber(entry.x) or 50) / 100))
        local y = math.max(0.08, math.min(0.80, (tonumber(entry.y) or 50) / 100))
        map.dot:ClearAllPoints()
        map.dot:SetPoint("CENTER", map, "TOPLEFT", inner * x, -SHEET_MAP * y)
        map.caption:SetText(C.PlaceText(entry))
        map.caption:SetTextColor(Theme.Unpack("muted"))
    else
        map.caption:SetText(L["Where it lives is not known yet."])
        map.caption:SetTextColor(Theme.Unpack("dim"))
    end

    local y = -(SHEET_PAD + SHEET_ICON + 12 + SHEET_MAP + 6)
    local function Place(line, shown)
        line:SetShown(shown)
        if not shown then return end
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", sheet, "TOPLEFT", SHEET_PAD, y)
        line:SetWidth(inner)
        local height = SHEET_LINE
        local ok, textHeight = pcall(line.value.GetStringHeight, line.value)
        if ok and type(textHeight) == "number" and textHeight + 8 > height then height = math.ceil(textHeight + 8) end
        line:SetHeight(height)
        y = y - height
    end
    local petName, petSpeed = CompendiumUI.PetSpeed()
    sheet.speed.value:SetText(CompendiumUI.SpeedWords(entry, petName, petSpeed))
    Place(sheet.speed, true)
    local diet = CompendiumUI.DietWords(entry)
    sheet.eats.value:SetText(diet or "")
    Place(sheet.eats, diet ~= nil)
    local tame, key = CompendiumUI.TameWords(entry)
    sheet.level.value:SetText(tame)
    sheet.level.value:SetTextColor(Theme.Unpack(key))
    Place(sheet.level, true)

    -- What taming it teaches: a tag each, "New for you" beside a skill the
    -- hunter has not got.
    y = y - 12
    sheet.teachHead:ClearAllPoints()
    sheet.teachHead:SetPoint("TOPLEFT", sheet, "TOPLEFT", SHEET_PAD, y)
    y = y - 18
    local skills = C:Skills(entry)
    sheet.nothing:SetShown(#skills == 0)
    sheet.teachHead:SetShown(#skills > 0)
    if #skills == 0 then
        sheet.nothing:ClearAllPoints()
        sheet.nothing:SetPoint("TOPLEFT", sheet, "TOPLEFT", SHEET_PAD, y + 18)
        y = y - 2
    end
    for i, skill in ipairs(skills) do
        local tag = sheet.tags[i]
        if not tag then
            tag = CreateTag(sheet)
            tag:SetHeight(20)
            tag.label:SetFont(Theme.FONT, Theme.sizes.small, "")
            tag.icon:SetSize(14, 14)
            sheet.tags[i] = tag
            sheet.news[i] = Theme.CreateLabel(sheet, "small", "accentHi")
            sheet.news[i]:SetText(L["New for you"])
        end
        local text = ("%s %d"):format(skill.name, skill.rank)
        local icon = ns.PetSkills and ns.PetSkills.Icon(skill.name, skill.rank)
        local color = CompendiumUI.SkillColor(skill)
        tag.label:SetText(text)
        tag.label:SetTextColor(Theme.Unpack(color))
        Theme.SetBorderColor(tag, color == "accentHi" and "accent" or "border", 0.8)
        tag.background:SetColorTexture(Theme.Unpack(color == "accentHi" and "accent" or "well",
            color == "accentHi" and 0.12 or 0.5))
        tag.icon:SetShown(icon ~= nil)
        if icon then tag.icon:SetTexture(icon) end
        local textLeft = icon and (3 + 14 + 5) or 6
        tag.label:ClearAllPoints()
        tag.label:SetPoint("LEFT", tag, "LEFT", textLeft, 0)
        tag:SetWidth(textLeft + math.ceil(Theme.TextWidth("small", text)) + 8)
        tag:ClearAllPoints()
        tag:SetPoint("TOPLEFT", sheet, "TOPLEFT", SHEET_PAD, y)
        tag:Show()
        local new = sheet.news[i]
        new:SetShown(color == "accentHi")
        new:ClearAllPoints()
        new:SetPoint("LEFT", tag, "RIGHT", 8, 0)
        y = y - 24
    end
    for i = #skills + 1, #sheet.tags do
        sheet.tags[i]:Hide()
        sheet.news[i]:Hide()
    end

    -- Show the Way and Show on Map, dim for a beast with no place yet.
    y = y - 10
    sheet.way:ClearAllPoints()
    sheet.way:SetPoint("TOPLEFT", sheet, "TOPLEFT", SHEET_PAD, y)
    for _, button in ipairs({ sheet.way, sheet.pin }) do
        button:SetAlpha(where and 1 or 0.45)
        button:EnableMouse(where)
    end
    sheet.bottom = y - 24
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

--- A click on a heading: the first sorts by it, the second turns it round,
--- the third goes back to the usual order (by beast, A to Z). Filters play
--- no part, so it works the same with any box ticked.
function CompendiumUI:SortBy(key)
    local o = self:Options()
    if (o.sort or "name") ~= key then
        o.sort, o.descending = key, false
    elseif not o.descending then
        o.descending = true
    else
        o.sort, o.descending = "name", false
    end
    self.offset = 0
    self:Refresh()
end

function CompendiumUI:PaintHeadings()
    local o = self:Options()
    local sort = o.sort or "name"
    for _, heading in ipairs(self.headings or {}) do
        local on = heading.sortKey == sort
        heading.label:SetTextColor(Theme.Unpack(on and "text" or "heading"))
        if heading.arrow then
            heading.arrow:SetShown(on)
            if o.descending then heading.arrow:SetTexCoord(0, 1, 1, 0) else heading.arrow:SetTexCoord(0, 1, 0, 1) end
        end
    end
end

function CompendiumUI:ScrollBy(steps)
    self:ScrollTo((self.offset or 0) + steps)
end

--- Show the list from `offset` on; only redraws the rows when it moved.
function CompendiumUI:ScrollTo(offset)
    local most = math.max(0, #(self.lines or {}) - self.visible)
    offset = math.max(0, math.min(most, math.floor(offset + 0.5)))
    if offset == self.offset then return end
    self.offset = offset
    self:Draw()
end

--- How far down the bar the cursor is, in the bar's own pixels, or nil.
function CompendiumUI:CursorOnBar()
    local grip = self.grip
    local top = grip and grip:GetTop()
    if not top then return nil end
    local _, y = GetCursorPosition()
    local scale = grip:GetEffectiveScale() or 1
    if not (y and scale > 0) then return nil end
    return top - y / scale
end

--- Put the thumb's top `pos` pixels down the bar, and the list with it.
function CompendiumUI:ScrollToThumb(pos)
    local total = #(self.lines or {})
    local room = self.visible * ROW_HEIGHT - (self.thumbSize or 0)
    if total <= self.visible or room <= 0 then return end
    self:ScrollTo(math.max(0, math.min(room, pos)) / room * (total - self.visible))
end

--- The mouse went down on the bar: hold the thumb where it was caught, or,
--- off the thumb, jump so the thumb's middle is under the cursor. Until the
--- button comes up, the list follows the cursor (OnUpdate runs only then).
function CompendiumUI:StartScrollDrag()
    if #(self.lines or {}) <= self.visible then return end
    local pos = self:CursorOnBar()
    if not pos then return end
    local top, size = self.thumbTop or 0, self.thumbSize or 0
    if pos >= top and pos <= top + size then
        self.grabAt = pos - top
    else
        self.grabAt = size / 2
        self:ScrollToThumb(pos - self.grabAt)
    end
    self.grip:SetScript("OnUpdate", function()
        local now = CompendiumUI:CursorOnBar()
        if now then CompendiumUI:ScrollToThumb(now - (CompendiumUI.grabAt or 0)) end
    end)
end

function CompendiumUI:StopScrollDrag()
    self.grabAt = nil
    if self.grip then self.grip:SetScript("OnUpdate", nil) end
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
    if total > self.visible then
        local height = self.visible * ROW_HEIGHT
        local size = math.max(16, height * self.visible / total)
        local top = (height - size) * offset / (total - self.visible)
        self.thumbTop, self.thumbSize = top, size
        self.thumb:SetHeight(size)
        self.thumb:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -(self.listRight or PADDING), self.listTop - top)
        self.thumb:Show()
        self.track:Show()
        self.grip:Show()
    else
        self.thumbTop, self.thumbSize = nil, nil
        self.thumb:Hide()
        self.track:Hide()
        self.grip:Hide()
    end
end

--- Read the choices back into the controls, which /bpet commands and other
--- windows may have changed.
function CompendiumUI:SyncControls()
    local o = self:Options()
    self.families = ns.Compendium:Families()
    local known = false
    for _, name in ipairs(self.families) do
        if name == o.family then known = true end
    end
    if o.family and not known then o.family = nil end
    -- The choices follow the families there are, rebuilt only when that
    -- list changed (a tame can add one), not on every redraw.
    local dropdown = self.familyDropdown
    if #dropdown.options ~= #self.families + 1 then dropdown:SetOptions(self:FamilyOptions()) end
    dropdown:SetValue(o.family or false)

    for key, box in pairs(self.ticks) do box:SetChecked(o[key] == true) end
    self:PaintHeadings()
end

function CompendiumUI:Refresh()
    if not (self.frame and self.frame:IsShown()) then return end
    self:SyncControls()

    self.lines = ns.Compendium:List(self:Filter())
    local most = math.max(0, #self.lines - self.visible)
    self.offset = math.min(self.offset or 0, most)
    self:Draw()

    local shown, total = #self.lines, #ns.Compendium:All()
    self.empty:SetShown(shown == 0)
    if shown == 0 then
        self.empty:Set(L["No beast matches. Untick a box or clear the search."], L["Show All"],
            function() CompendiumUI:ShowAll() end)
    end
    if shown == total then
        self.footer:SetText(L.Format("%d beasts", total))
    else
        local hidden = total - shown
        self.footer:SetText(hidden == 1 and L["Your filters hide 1 beast."]
            or L.Format("Your filters hide %d beasts.", hidden))
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
    if ns.PetsTabs then ns.PetsTabs:Save(self.frame) end
end

function CompendiumUI:RestorePosition()
    if not self.frame then return end
    local o = self:Options()
    self.frame:ClearAllPoints()
    self.frame:SetPoint(o.point or "CENTER", UIParent, o.relativePoint or "CENTER", o.x or 0, o.y or 20)
end

function CompendiumUI:Show()
    -- With "One Window:" ticked, the one window opens on Pets instead
    -- (UI/PetsTabs.lua), and lays this window in.
    if ns.PetsTabs and ns.PetsTabs:Route("compendium") then return end
    self:Build()
    if not self.frame:IsShown() then
        local how = ns.PetsTabs and ns.PetsTabs:Take(self)
        if not how then self:RestorePosition() end
        self.frame:Show()
        if not how and ns.PetsTabs then ns.PetsTabs:Settle(self.frame) end
        if how ~= "switch" then
            ns.Motion:Open(self.frame)
            if ns.Titanforged then ns.Titanforged:Opened(self.frame) end
        end
    end
    if ns.FoldWindow then ns.FoldWindow:Unfold(self.frame) end
    self:Refresh()
end

--- The empty block's Show All: every filter off and the search cleared.
function CompendiumUI:ShowAll()
    local o = self:Options()
    o.family, o.tameNow, o.raresOnly, o.newSkills, o.foreverOnly = nil, nil, nil, nil, nil
    self.searchText = nil
    if self.search then self.search:SetText("") end
    self.offset = 0
    self:Refresh()
end

function CompendiumUI:Hide()
    if self.frame then self.frame:Hide() end
end

--- A level-up changes which beasts can be tamed now and which levels show
--- red, so an open compendium draws again a moment later, once the client
--- gives the new level. A closed one does nothing.
function CompendiumUI:OnEnable()
    ns.RegisterEvent(self, "PLAYER_LEVEL_UP", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(1, function() pcall(CompendiumUI.Refresh, CompendiumUI) end)
        else
            pcall(CompendiumUI.Refresh, CompendiumUI)
        end
    end)
end

function CompendiumUI:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

--- Open the compendium searching for `text` (a beast, a zone or a skill),
--- from the first row.
function CompendiumUI:ShowSearch(text)
    self.searchText = tostring(text or ""):match("^%s*(.-)%s*$")
    self:Show()
    if self.search then self.search:SetText(self.searchText) end
    self.offset = 0
    self:Refresh()
end

ns.RegisterCommand("compendium", L["open the Pet Compendium: every beast you can tame"], function(rest)
    if type(rest) == "string" and rest:match("%S") then
        CompendiumUI:ShowSearch(rest)
        return
    end
    CompendiumUI:Toggle()
end)
ns.commands.beasts = ns.commands.compendium

-- Kept folded through a /reload, its round button opens it (UI/FoldWindow.lua).
if ns.FoldWindow and ns.FoldWindow.Opener then
    ns.FoldWindow:Opener("Compendium", { open = function() CompendiumUI:Show() end })
end
