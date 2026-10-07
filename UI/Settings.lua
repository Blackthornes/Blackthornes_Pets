-- Blackthornes Pets -- UI/Settings.lua
-- The settings window: every switch the addon has, in one place.
--
-- Built the way Equipment's and Farmer's settings pages and Tradeskills'
-- Settings tab are, so they read as one set: a row is [label .. control] on one line with
-- what it does underneath, and rows are a fixed height so nothing slides
-- under the control beside it.
--
-- Open it with /bpet settings, a click on the minimap button, or from the
-- game's own Options > AddOns list. Nothing here deletes anything.

local _, ns = ...

local SettingsUI = ns.NewModule("SettingsUI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local PADDING = 18
-- From the window's top to the gold rule under the header row.
local HEADER = 44
-- The metal rim sits on the window's edge and reaches this far inward, with
-- room to spare (UI/Titanforged.lua).
local EDGE_PAD = 11

local COLUMN_WIDTH = 330
-- Where the controls start: room for a label like "Minimap button" in the
-- game's font, which runs wider than it looks.
local CONTROL_X = 150

local WIDTH = COLUMN_WIDTH + PADDING * 2
local HEIGHT = 736

local ROW_HEIGHT = 50
local ROW_GAP = -6
local SECTION_GAP = -16

local TITLE = "Blackthornes Pets"

--------------------------------------------------------------------------------
-- Layout helpers
--------------------------------------------------------------------------------

--- Section heading with a rule underneath. Returns a frame to anchor rows to.
local function CreateSection(parent, text, opts)
    local section = CreateFrame("Frame", nil, parent)
    section:SetSize(COLUMN_WIDTH, 18)

    if opts.anchor then
        section:SetPoint("TOPLEFT", opts.anchor, "BOTTOMLEFT", 0, SECTION_GAP)
    else
        section:SetPoint("TOPLEFT", opts.x, opts.y)
    end

    local heading = Theme.CreateLabel(section, "tiny", "accent")
    heading:SetPoint("TOPLEFT", 0, 0)
    heading:SetText(text)

    local divider = Theme.CreateDivider(section, "border")
    divider:SetPoint("TOPLEFT", 0, -14)
    divider:SetWidth(COLUMN_WIDTH)

    return section
end

--- One setting: label and control on a line, what it does underneath.
local function CreateRow(parent, anchor, labelText, description)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, ROW_GAP)
    row:SetSize(COLUMN_WIDTH, ROW_HEIGHT)

    local label = Theme.CreateLabel(row, "small", "text")
    label:SetPoint("TOPLEFT", 0, -4)
    label:SetWidth(CONTROL_X - 8)
    label:SetText(labelText)

    -- Never cut short: a label too long for the room before the control
    -- wraps onto a second line, and the hint and the row move down for it.
    local extra = 0
    if Theme.TextWidth("small", labelText) > CONTROL_X - 8 then
        label:SetWordWrap(true)
        extra = 13
        row:SetHeight(ROW_HEIGHT + extra)
    end

    local hint = Theme.CreateLabel(row, "tiny", "dim")
    hint:SetPoint("TOPLEFT", 0, -25 - extra)
    hint:SetWidth(COLUMN_WIDTH)
    hint:SetWordWrap(true)
    hint:SetText(description or "")

    row.label = label
    row.hint = hint
    return row
end

--- Put the settings window back where it started.
function SettingsUI:ResetPositions()
    ns.db.settingsPoint = nil
    ns.db.settingsRelativePoint = nil
    ns.db.settingsX = nil
    ns.db.settingsY = nil
    self:RestorePosition()
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function SettingsUI:Build()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "BlackthornesPetsSettings", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")

    Theme.Fill(frame, "window")

    -- The house frame (UI/Titanforged.lua): the gold rim, the name on a
    -- plate and the red close gem. No portrait: on a window this narrow it
    -- would sit over the first section's heading.
    if ns.Titanforged then
        local trim = ns.Titanforged:Dress(frame, {
            title = TITLE,
            close = function() SettingsUI:Hide() end,
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
        SettingsUI:SavePosition()
    end)

    -- Escape closes it, like the game's own windows.
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsSettings")
    end

    self.frame = frame
    self.controls = {}

    self:BuildHeader()
    self:BuildColumn()

    local footer = Theme.CreateLabel(frame, "tiny", "dim")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    footer:SetText("Changes save as you make them.")
    self.footer = footer

    frame:Hide()
    return frame
end

--- The header row. The addon's name is on the plate across the top edge
--- and the close gem sits on the top right corner (UI/Titanforged.lua), so
--- the row says which page this is and which version is running.
function SettingsUI:BuildHeader()
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

    local subtitle = Theme.CreateLabel(header, "small", "muted")
    subtitle:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", PADDING - EDGE_PAD, 7)
    subtitle:SetText("Settings")

    local version = Theme.CreateLabel(header, "tiny", "dim", "RIGHT")
    version:SetText(ns.VersionLabel())
    version:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -(PADDING - EDGE_PAD), 8)
end

function SettingsUI:BuildColumn()
    local frame = self.frame
    local controls = self.controls

    local windows = CreateSection(frame, "WINDOWS", { x = PADDING, y = -(HEADER + 16) })

    local minimapRow = CreateRow(frame, windows, "Minimap button",
        "Click it for the pets window, right-click for this page. Drag it to move it.")

    controls.minimap = Widgets.CreateCheckbox(minimapRow, "Show it", function(checked)
        ns.db.minimapHidden = not checked
        if ns.MinimapButton then ns.MinimapButton:ApplyVisibility() end
    end, true)
    controls.minimap:SetPoint("TOPLEFT", CONTROL_X, -2)

    local positionRow = CreateRow(frame, minimapRow, "Window position",
        "Moves this window back to the middle of the screen, if it ends up off screen.")

    local reset = Widgets.CreateButton(positionRow, "Put it back", function()
        SettingsUI:ResetPositions()
    end, { width = 100, height = 20 })
    reset:SetPoint("TOPLEFT", CONTROL_X, 0)

    local hunter = CreateSection(frame, "HUNTER PET", { anchor = positionRow })

    local feedRow = CreateRow(frame, hunter, "Feed warning",
        "A warning in chat and on screen when your pet is no longer happy.")

    controls.feedWarning = Widgets.CreateCheckbox(feedRow, "Warn me", function(checked)
        ns.db.feedWarning = checked
    end, true)
    controls.feedWarning:SetPoint("TOPLEFT", CONTROL_X, -2)

    local unhappyRow = CreateRow(frame, feedRow, "Only when unhappy",
        "Stay quiet while the pet is content, and warn only once it is unhappy.")

    controls.feedWarnOnlyUnhappy = Widgets.CreateCheckbox(unhappyRow, "Enabled", function(checked)
        ns.db.feedWarnOnlyUnhappy = checked
        -- The Feed button by the quests follows the same line.
        if ns.Food then ns.Food:Update() end
    end, false)
    controls.feedWarnOnlyUnhappy:SetPoint("TOPLEFT", CONTROL_X, -2)

    local lowFoodRow = CreateRow(frame, unhappyRow, "Low food warning",
        ("A warning in chat when you have fewer than %d food your pet will eat."):format(ns.Food.LOW_FOOD))

    controls.lowFoodWarning = Widgets.CreateCheckbox(lowFoodRow, "Warn me", function(checked)
        ns.db.lowFoodWarning = checked
    end, true)
    controls.lowFoodWarning:SetPoint("TOPLEFT", CONTROL_X, -2)

    local quickFeedRow = CreateRow(frame, lowFoodRow, "Feed button by quests",
        "A small Feed button above the quest list while your pet needs feeding.")

    controls.quickFeed = Widgets.CreateCheckbox(quickFeedRow, "Show it", function(checked)
        ns.db.quickFeed = checked
        if ns.Food then ns.Food:Update() end
    end, true)
    controls.quickFeed:SetPoint("TOPLEFT", CONTROL_X, -2)

    local tamingRow = CreateRow(frame, quickFeedRow, "Taming skills",
        "On a beast's tooltip, the pet skills taming it teaches: green if you know them, red if not.")

    controls.tamingTooltip = Widgets.CreateCheckbox(tamingRow, "Show them", function(checked)
        ns.db.tamingTooltip = checked
    end, true)
    controls.tamingTooltip:SetPoint("TOPLEFT", CONTROL_X, -2)

    local compendium = CreateSection(frame, "PET COMPENDIUM", { anchor = tamingRow })

    local compendiumRow = CreateRow(frame, compendium, "Pet Compendium",
        "Every beast you can tame: what it teaches, its level, where it lives and how rare it is. Also /bpet compendium.")

    local openCompendium = Widgets.CreateButton(compendiumRow, "Open it", function()
        if ns.CompendiumUI then ns.CompendiumUI:Toggle() end
    end, { width = 100, height = 20, primary = true })
    openCompendium:SetPoint("TOPLEFT", CONTROL_X, 0)
    controls.openCompendium = openCompendium

    local advanced = CreateSection(frame, "ADVANCED", { anchor = compendiumRow })

    local debugRow = CreateRow(frame, advanced, "Debug output",
        "Extra messages in chat, to help track down a problem.")

    controls.debug = Widgets.CreateCheckbox(debugRow, "Enabled", function(checked)
        ns.db.debug = checked
    end, false)
    controls.debug:SetPoint("TOPLEFT", CONTROL_X, -2)
end

--------------------------------------------------------------------------------
-- Refresh
--------------------------------------------------------------------------------

--- Put every control back in step with what is saved. Called whenever the
--- page opens and after any /bpet command, because each of these can also be
--- changed by typing.
function SettingsUI:Refresh()
    if not (self.frame and self.frame:IsShown() and ns.db) then return end

    local controls = self.controls
    controls.minimap:SetChecked(not ns.db.minimapHidden)
    controls.feedWarning:SetChecked(ns.db.feedWarning ~= false)
    controls.feedWarnOnlyUnhappy:SetChecked(ns.db.feedWarnOnlyUnhappy == true)
    controls.lowFoodWarning:SetChecked(ns.db.lowFoodWarning ~= false)
    controls.quickFeed:SetChecked(ns.db.quickFeed ~= false)
    controls.tamingTooltip:SetChecked(ns.db.tamingTooltip ~= false)
    controls.debug:SetChecked(ns.db.debug == true)
end

--------------------------------------------------------------------------------
-- Position
--------------------------------------------------------------------------------

function SettingsUI:SavePosition()
    if not (ns.db and self.frame) then return end

    local point, _, relativePoint, x, y = self.frame:GetPoint()

    ns.db.settingsPoint = point
    ns.db.settingsRelativePoint = relativePoint
    ns.db.settingsX = x
    ns.db.settingsY = y
end

function SettingsUI:RestorePosition()
    if not self.frame then return end

    local db = ns.db or {}

    self.frame:ClearAllPoints()
    self.frame:SetPoint(db.settingsPoint or "CENTER", UIParent,
        db.settingsRelativePoint or "CENTER", db.settingsX or 0, db.settingsY or 0)
end

--------------------------------------------------------------------------------
-- Visibility
--------------------------------------------------------------------------------

function SettingsUI:Show()
    self:Build()

    if not self.frame:IsShown() then
        self:RestorePosition()
        self.frame:Show()
        ns.Motion:Open(self.frame)
    end

    self:Refresh()
end

function SettingsUI:Hide()
    if self.frame then self.frame:Hide() end
end

function SettingsUI:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

--------------------------------------------------------------------------------
-- The game's own AddOns options list
--
-- As in Farmer: a small launcher under Options > AddOns rather than this page
-- squeezed into Blizzard's frame. Every call is guarded, because a missing
-- options entry is no reason for the addon to fail to load.
--------------------------------------------------------------------------------

function SettingsUI:RegisterGameOptions()
    if self.optionsPanel then return end

    local panel = CreateFrame("Frame")
    panel.name = TITLE

    local title = Theme.CreateLabel(panel, "title", "accent")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(TITLE)

    local blurb = Theme.CreateLabel(panel, "normal", "text")
    blurb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    blurb:SetText("Pets' settings have a window of their own.")

    local open = Widgets.CreateButton(panel, "Open Pets settings", function()
        -- Close the game's panel first, or the two windows fight for the
        -- keyboard.
        if SettingsPanel and HideUIPanel then
            pcall(HideUIPanel, SettingsPanel)
        end
        SettingsUI:Show()
    end, { width = 190, height = 24 })
    open:SetPoint("TOPLEFT", blurb, "BOTTOMLEFT", 0, -14)

    local hint = Theme.CreateLabel(panel, "small", "muted")
    hint:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -10)
    hint:SetText("Or type /bpet settings, or click the minimap button.")

    self.optionsPanel = panel

    local registered = false

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        registered = pcall(function()
            local category = Settings.RegisterCanvasLayoutCategory(panel, TITLE)
            Settings.RegisterAddOnCategory(category)
            SettingsUI.optionsCategory = category
        end)
    end

    -- The older options API, in case this client still has it instead.
    if not registered and type(InterfaceOptions_AddCategory) == "function" then
        registered = pcall(InterfaceOptions_AddCategory, panel)
    end

    if not registered then
        ns.Debug("no game options panel to register with; /bpet settings still works")
    end

    return registered
end

function SettingsUI:OnEnable()
    local ok, err = pcall(self.RegisterGameOptions, self)
    if not ok then
        ns.Debug("could not add Pets to the game's options:", tostring(err))
    end
end

ns.RegisterCommand("settings", "open the settings window", function()
    SettingsUI:Toggle()
end)

-- Common names for the same thing, so a guess works. Kept out of the help
-- list, which would otherwise print the same line three times.
ns.commands.options = ns.commands.settings
ns.commands.config = ns.commands.settings
