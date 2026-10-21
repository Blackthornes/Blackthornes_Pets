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

local WIDTH = 820
local HEIGHT = 586
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
    { key = "name", label = L["Beast"], sortTip = L["Sort by beast"], x = 10, width = 186 },
    { key = "family", label = L["Family"], sortTip = L["Sort by family"], x = 200, width = 88 },
    { key = "level", label = L["Level"], sortTip = L["Sort by level"], x = 292, width = 48 },
    { key = "speed", label = L["Speed"], sortTip = L["Sort by speed"], x = 344, width = 46,
      tip = L["Seconds between its attacks. Lower is faster."] },
    { key = "zone", label = L["Where"], sortTip = L["Sort by where"], x = 394, width = 180 },
    { key = "skills", label = L["Teaches"], x = 578, width = 188 },
}

-- A pet's usual swing time; quicker is green, slower amber.
local USUAL_SPEED = 2.0

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
            title = L["Pet Compendium"],
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

    -- The house size grip under the bottom right corner (Widgets.WindowGrip),
    -- saved as `compendiumScale`.
    self.sizeGrip = Widgets.WindowGrip(frame, "compendiumScale", function()
        CompendiumUI:SavePosition()
    end)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta) CompendiumUI:ScrollBy(-delta) end)

    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsCompendium")
    end

    self.frame = frame
    -- The pets window puts its Feed button away while this is open.
    if ns.UI and ns.UI.WatchCover then ns.UI:WatchCover(frame) end
    self:BuildHeader()
    self:BuildBar()
    self:BuildHeadings()
    self:BuildList()

    local hint = Theme.CreateLabel(frame, "tiny", "dim")
    hint:SetPoint("BOTTOMLEFT", PADDING, 12)
    hint:SetWidth(WIDTH - PADDING * 2)
    hint:SetWordWrap(true)
    hint:SetText(L.Format("Click a beast to pin it on your map, or Shift-click to point the arrow at it. %s marks what WoW: Forever has shown.",
        Colored("good", "Forever")))
    self.hint = hint

    -- Sits on the hint's top, so a hint that wraps to a second line (the
    -- German one, or a larger text size) pushes it up rather than under it.
    local footer = Theme.CreateLabel(frame, "small", "text")
    footer:SetPoint("BOTTOMLEFT", hint, "TOPLEFT", 0, 4)
    footer:SetWidth(WIDTH - PADDING * 2)
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

    -- Past the portrait, which reaches 48 pixels into the window.
    local subtitle = Theme.CreateLabel(header, "small", "muted")
    subtitle:SetPoint("LEFT", header, "LEFT", 48, -4)
    self.subtitle = subtitle

    local settings = Widgets.CreateButton(header, L["Settings"], function()
        if ns.SettingsUI then ns.SettingsUI:Toggle() end
    end, { width = 70, height = 20 })
    settings:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -10, 4)

    -- The beast arrow: lit green while it is up.
    local arrow = Widgets.CreateButton(header, L["Arrow"], function()
        if ns.BeastArrow then ns.HandleSlash(ns.BeastArrow.IsOn() and "arrow off" or "arrow on") end
    end, { width = 60, height = 20 })
    arrow:SetPoint("RIGHT", settings, "LEFT", -8, 0)
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

    local familyLabel = Theme.CreateLabel(frame, "small", "muted")
    familyLabel:SetPoint("TOPLEFT", PADDING, top - 4)
    familyLabel:SetText(L["Family"])

    -- A dropdown of every family (a player asked, the owner agreed
    -- 2026-10-11; it was a stepper that went one family at a time), wide
    -- enough for the longest name in either language.
    local options = self:FamilyOptions()
    local family = Widgets.CreateDropdown(frame, options, function(value)
        CompendiumUI:Options().family = value or nil
        CompendiumUI.offset = 0
        CompendiumUI:Refresh()
    end, { width = Widgets.DropdownWidth(options, 170) })
    family:SetPoint("LEFT", familyLabel, "RIGHT", 8, 0)
    family:SetValue(false)
    self.familyDropdown = family

    local search = Widgets.CreateSearchBox(frame, L["Search beasts, zones or skills"], function(text)
        CompendiumUI.searchText = text
        CompendiumUI.offset = 0
        CompendiumUI:Refresh()
    end)
    search:SetPoint("LEFT", family, "RIGHT", 14, 0)
    search:SetWidth(260)
    self.search = search

    local ticks = {
        { key = "tameNow", text = L["Tameable now"],
          tip = L["Only beasts at or below your level."] },
        { key = "raresOnly", text = L["Rares only"] },
        { key = "newSkills", text = L["Teaches me something new"],
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
            box:SetPoint("TOPLEFT", PADDING, top - 32)
        end
        -- A box whose label says it all has no hover.
        if spec.tip then
            box:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:AddLine(spec.text, 1, 1, 1)
                GameTooltip:AddLine(spec.tip, 0.9, 0.9, 0.9, true)
                GameTooltip:Show()
            end)
            box:HookScript("OnLeave", function() GameTooltip:Hide() end)
        end
        self.ticks[spec.key] = box
        previous = box
    end

    self.barBottom = top - 32 - 18 - BAR_GAP
end

--- The headings, which sort the list: a click sorts by that column, a
--- second click turns it round, a third goes back to sorting by beast.
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

    local well = Theme.CreatePanel(frame, "panel", "border")
    well:SetPoint("TOPLEFT", PADDING - 3, self.listTop + 3)
    well:SetPoint("TOPRIGHT", -(PADDING - 3), self.listTop + 3)
    well:SetHeight(VISIBLE * ROW_HEIGHT + 6)
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
    track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PADDING, self.listTop)
    track:SetSize(self.scrollWidth, VISIBLE * ROW_HEIGHT)
    track:SetColorTexture(Theme.Unpack("rowAlt"))
    self.track = track

    -- What the mouse catches: the bar and a little either side, above the
    -- rows. Holding it drags the thumb; a click on the bar jumps there.
    local grip = CreateFrame("Frame", nil, frame)
    grip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(PADDING - (GRIP_WIDTH - self.scrollWidth) / 2), self.listTop)
    grip:SetSize(GRIP_WIDTH, VISIBLE * ROW_HEIGHT)
    grip:SetFrameLevel(frame:GetFrameLevel() + 10)
    grip:EnableMouse(true)
    grip:SetScript("OnMouseDown", function(_, button)
        if button == nil or button == "LeftButton" then CompendiumUI:StartScrollDrag() end
    end)
    grip:SetScript("OnMouseUp", function() CompendiumUI:StopScrollDrag() end)
    grip:SetScript("OnHide", function() CompendiumUI:StopScrollDrag() end)
    self.grip = grip

    self.rows = {}
    for index = 1, VISIBLE do self.rows[index] = self:BuildRow(index) end

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
    row:SetPoint("TOPRIGHT", -(PADDING + (self.scrollWidth or SCROLL_WIDTH) + 2), self.listTop - (index - 1) * ROW_HEIGHT)
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

    row.name = Cell(row, COLUMNS[1], "small", "text")
    row.family = Cell(row, COLUMNS[2], "small", "text")
    row.level = Cell(row, COLUMNS[3], "small", "text")
    row.speed = Cell(row, COLUMNS[4], "small", "text")
    row.zone = Cell(row, COLUMNS[5], "small", "text")
    row.skills = Cell(row, COLUMNS[6], "tiny", "text")

    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function(self)
        local entry = rawget(self, "entry")
        if not entry then return end
        local shift = type(IsShiftKeyDown) == "function" and select(2, pcall(IsShiftKeyDown))
        if shift then
            CompendiumUI:AimArrow(entry)
        else
            ns.Compendium:Pin(entry)
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
        self.background:SetColorTexture(Theme.Unpack(self.rest))
        self.stripe:Hide()
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

--- Each skill coloured: green when the hunter knows it, red when not, plain
--- when nothing can say.
function CompendiumUI.SkillText(skills)
    local parts = {}
    for i, skill in ipairs(skills) do
        local text = ("%s %d"):format(skill.name, skill.rank)
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
    if not entry.zone then return Colored("dim", L["Not known yet"]) end
    local where = entry.zone
    if entry.x and entry.y then
        where = where .. "\n" .. Colored("dim", ("%.1f, %.1f"):format(entry.x, entry.y))
    elseif entry.instance then
        where = where .. "\n" .. Colored("dim", entry.instance == "raid" and L["Raid"] or L["Dungeon"])
    end
    return where
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
    if entry.speedSeen then text = text .. "\n" .. Colored("good", L["tamed"]) end
    return text
end

function CompendiumUI:FillRow(row, entry, level)
    row.entry = entry
    if not entry then
        row:Hide()
        return
    end
    row.name:SetText(self:NameText(entry))
    row.family:SetText(entry.family or Colored("dim", L["Not known yet"]))
    local levelText = Compendium().LevelText(entry)
    if Compendium():CanTame(entry, level) == false then levelText = Colored("loss", levelText) end
    row.level:SetText(levelText)
    row.speed:SetText(self:SpeedCell(entry))
    row.zone:SetText(self:ZoneText(entry))
    local skills = Compendium():Skills(entry)
    row.skills:SetText(#skills > 0 and self.SkillText(skills) or Colored("dim", L["Nothing"]))
    row:Show()
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
    if entry.zone then
        GameTooltip:AddLine(L["Shift-click to point the arrow at it."], Theme.Unpack("accent"))
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
            local key = known == true and "good" or known == false and "loss" or "text"
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
    -- Only a beast with a spot can be pinned (Waypoints:Pin); the arrow
    -- can still point at its zone.
    local pinText = (entry.zone and entry.x and entry.y) and L["Click to pin it on your map."]
        or entry.zone and L["No exact spot to pin. Shift-click to point the arrow at its zone."]
        or L["No place to pin yet."]
    GameTooltip:AddLine(pinText, 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
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
    local sort = self:Options().sort or "name"
    for _, heading in ipairs(self.headings or {}) do
        heading.label:SetTextColor(Theme.Unpack(heading.sortKey == sort and "accent" or "muted"))
    end
end

function CompendiumUI:ScrollBy(steps)
    self:ScrollTo((self.offset or 0) + steps)
end

--- Show the list from `offset` on; only redraws the rows when it moved.
function CompendiumUI:ScrollTo(offset)
    local most = math.max(0, #(self.lines or {}) - VISIBLE)
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
    local room = VISIBLE * ROW_HEIGHT - (self.thumbSize or 0)
    if total <= VISIBLE or room <= 0 then return end
    self:ScrollTo(math.max(0, math.min(room, pos)) / room * (total - VISIBLE))
end

--- The mouse went down on the bar: hold the thumb where it was caught, or,
--- off the thumb, jump so the thumb's middle is under the cursor. Until the
--- button comes up, the list follows the cursor (OnUpdate runs only then).
function CompendiumUI:StartScrollDrag()
    if #(self.lines or {}) <= VISIBLE then return end
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
    if total > VISIBLE then
        local height = VISIBLE * ROW_HEIGHT
        local size = math.max(16, height * VISIBLE / total)
        local top = (height - size) * offset / (total - VISIBLE)
        self.thumbTop, self.thumbSize = top, size
        self.thumb:SetHeight(size)
        self.thumb:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -PADDING, self.listTop - top)
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
    local most = math.max(0, #self.lines - VISIBLE)
    self.offset = math.min(self.offset or 0, most)
    self:Draw()

    local level = ns.Compendium:PlayerLevel()
    self.subtitle:SetText(level and L.Format("Beasts a hunter can tame. You are level %d.", level)
        or L["Beasts a hunter can tame."])

    local shown, total = #self.lines, #ns.Compendium:All()
    self.empty:SetShown(shown == 0)
    self.empty:SetText(L["No beast matches. Untick a box or clear the search."])
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

ns.RegisterCommand("compendium", L["open the Pet Compendium: every beast you can tame"], function(rest)
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
