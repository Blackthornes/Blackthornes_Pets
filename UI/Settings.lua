-- Blackthornes Pets -- UI/Settings.lua
-- The settings window: every switch the addon has, in one place.
--
-- Built the way Tradeskills' Settings tab is (UI/SettingsPages.lua): pages
-- picked along the top, two columns of rows a page, a row being [label ..
-- control] on one line, and what it does in the row's tooltip or, with Show
-- descriptions ticked, underneath it.
--
-- Open it with /bpet settings, a click on the minimap button, or from the
-- game's own Options > AddOns list. Nothing here deletes anything.

local _, ns = ...
local L = ns.L

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
local COLUMN_GAP = 18
-- Where the controls start: room for a label like "Minimap button" in the
-- game's font, which runs wider than it looks.
local CONTROL_X = 150

local TITLE = "Blackthornes Pets"

-- The pages along the top (UI/SettingsPages.lua), as Tradeskills' Settings
-- tab has them. Every setting kept its saved name; only its place moved.
local PAGES = {
    { key = "pet", text = L["HUNTER PET"],
      tip = L["Feeding warnings, the Feed button and taming skills on tooltips"] },
    { key = "compendium", text = L["COMPENDIUM"],
      tip = L["The Pet Compendium, the beast arrow and TomTom"] },
    { key = "general", text = L["GENERAL"],
      tip = L["The minimap button, window position, text size and debug output"] },
    { key = "about", text = L["ABOUT"],
      tip = L["How these addons are made, the version, the Discord and the other Blackthornes addons"] },
}

--- Put the settings window back where it started.
function SettingsUI:ResetPositions()
    ns.db.settingsPoint = nil
    ns.db.settingsRelativePoint = nil
    ns.db.settingsX = nil
    ns.db.settingsY = nil
    self:RestorePosition()
    if ns.BeastArrowUI and ns.BeastArrowUI.frame then
        ns.BeastArrowUI:ResetPosition()
    else
        -- Not built this session: the saved spot goes, so it starts in place.
        ns.db.beastArrowX, ns.db.beastArrowY = nil, nil
    end
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function SettingsUI:Build()
    if self.frame then return self.frame end

    local frame = CreateFrame("Frame", "BlackthornesPetsSettings", UIParent)
    frame:SetSize(COLUMN_WIDTH * 2 + COLUMN_GAP + PADDING * 2, 600)
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
    -- The pets window puts its Feed button away while this is open.
    if ns.UI and ns.UI.WatchCover then ns.UI:WatchCover(frame) end
    self.controls = {}

    self:BuildHeader()

    self.pages = ns.SettingsPages.New(frame, {
        pages = PAGES,
        top = HEADER + 4,
        bottom = 40,
        padding = PADDING,
        columnWidth = COLUMN_WIDTH,
        columnGap = COLUMN_GAP,
        controlX = CONTROL_X,
        db = function() return ns.db end,
    })
    self:BuildPages()
    -- About (UI/About.lua): the note on how the addons are made, then the
    -- version, the Discord and the other Blackthornes addons.
    if ns.About then
        local pages = self.pages
        pages:Section("about", 1, L["HOW THESE ADDONS ARE MADE"])
        local note = pages:Place("about", 1, ns.About:Note(pages.pages.about.content, COLUMN_WIDTH))
        pages:Searchable("about", note, note.words)
        pages:Section("about", 2, L["ABOUT"])
        local info = pages:Place("about", 2, ns.About:Info(pages.pages.about.content, COLUMN_WIDTH))
        pages:Searchable("about", info, info.words)
    end
    self.pages:Fit()

    local footer = Theme.CreateLabel(frame, "tiny", "dim")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    footer:SetText(L["Changes save as you make them."])
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
    subtitle:SetText(L["Settings"])

    local version = Theme.CreateLabel(header, "tiny", "dim", "RIGHT")
    version:SetText(ns.VersionLabel())
    version:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -(PADDING - EDGE_PAD), 8)
end

--- A row whose button runs a /bpet command, so every command has a button
--- here (a house rule).
local function CommandRow(pages, page, column, label, description, buttonText, command)
    local row = pages:Row(page, column, label, description)
    local button = Widgets.CreateButton(row, buttonText, function()
        ns.HandleSlash(command)
    end, { width = 100, height = 20 })
    button:SetPoint("TOPLEFT", CONTROL_X, 0)
    return row, button
end

-- The window styles, in the order the stepper steps through them.
local STYLES = { "titanforged", "blizzard" }
local STYLE_LABELS = { titanforged = "Titanforged", blizzard = "Blizzard" }

--- Titanforged or Blizzard, with Reload under it while the pick differs
--- from what is drawn, as the Text size row has. Pets has no dropdown, so
--- it is a stepper like Text size.
function SettingsUI.WindowStyleControl(row, x)
    local reload
    local function Drawn()
        local Look = ns.BlizzardLook
        return Look and Look.Style() or "titanforged"
    end

    local stepper = Widgets.CreateStepper(row, {
        min = 1, max = #STYLES, step = 1,
        format = function(value) return STYLE_LABELS[STYLES[value]] end,
        onChange = function(value)
            ns.db.windowStyle = STYLES[value]
            reload:SetShown(STYLES[value] ~= Drawn())
        end,
    })
    ns.SettingsPages.FitStepper(stepper, STYLE_LABELS)
    stepper:SetPoint("TOPLEFT", x, -2)

    -- ReloadUI is allowed from a click, and saves everything first.
    reload = Widgets.CreateButton(row, L["Reload"], function()
        if ReloadUI then ReloadUI() end
    end, { width = 60, height = 20 })
    ns.SettingsPages.ReloadUnder(row, stepper, reload)
    reload:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Reload the interface so the new window style shows (/reload)"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    reload:HookScript("OnLeave", function() GameTooltip:Hide() end)
    reload:Hide()
    stepper.reload = reload

    function stepper:Sync()
        local Look = ns.BlizzardLook
        local wanted = Look and Look.Wanted() or "titanforged"
        self:SetValue(wanted == "blizzard" and 2 or 1, true)
        reload:SetShown(wanted ~= Drawn())
    end

    return stepper
end

function SettingsUI:BuildPages()
    local controls = self.controls
    local pages = self.pages

    -- Hunter pet: feeding on the left, taming on the right.
    pages:Section("pet", 1, L["FEEDING"])

    local feedRow = pages:Row("pet", 1, L["Feed warning"],
        L["A warning in chat and on screen when your pet is no longer happy."])

    controls.feedWarning = Widgets.CreateCheckbox(feedRow, L["Warn me"], function(checked)
        ns.db.feedWarning = checked
    end, true)
    controls.feedWarning:SetPoint("TOPLEFT", CONTROL_X, -2)

    local unhappyRow = pages:Row("pet", 1, L["Only when unhappy"],
        L["Stay quiet while the pet is content, and warn only once it is unhappy."])

    controls.feedWarnOnlyUnhappy = Widgets.CreateCheckbox(unhappyRow, L["Enabled"], function(checked)
        ns.db.feedWarnOnlyUnhappy = checked
        -- The Feed button by the quests follows the same line.
        if ns.Food then ns.Food:Update() end
    end, false)
    controls.feedWarnOnlyUnhappy:SetPoint("TOPLEFT", CONTROL_X, -2)

    local lowFoodRow = pages:Row("pet", 1, L["Low food warning"],
        L.Format("A warning in chat when you have fewer than %d food your pet will eat.", ns.Food.LOW_FOOD))

    controls.lowFoodWarning = Widgets.CreateCheckbox(lowFoodRow, L["Warn me"], function(checked)
        ns.db.lowFoodWarning = checked
    end, true)
    controls.lowFoodWarning:SetPoint("TOPLEFT", CONTROL_X, -2)

    local buffFoodRow = pages:Row("pet", 1, L["Buff food"],
        L["Food that gives a buff, like stat food, is always fed last. Tick this to never feed it."])

    controls.neverFeedBuffFood = Widgets.CreateCheckbox(buffFoodRow, L["Never feed it"], function(checked)
        ns.db.neverFeedBuffFood = checked
        if ns.Food then ns.Food:Update() end
    end, false)
    controls.neverFeedBuffFood:SetPoint("TOPLEFT", CONTROL_X, -2)

    local quickFeedRow = pages:Row("pet", 1, L["Feed button by quests"],
        L["A small Feed button above the quest list while your pet needs feeding."])

    controls.quickFeed = Widgets.CreateCheckbox(quickFeedRow, L["Show it"], function(checked)
        ns.db.quickFeed = checked
        if ns.Food then ns.Food:Update() end
    end, true)
    controls.quickFeed:SetPoint("TOPLEFT", CONTROL_X, -2)

    local _, foodButton = CommandRow(pages, "pet", 1, L["Food in your bags"],
        L["Lists in chat the food in your bags and whether your pet will eat it. Same as /bpet food."],
        L["List it"], "food")
    controls.food = foodButton

    pages:Section("pet", 2, L["TAMING"])

    local tamingRow = pages:Row("pet", 2, L["Taming skills"],
        L["On a beast's tooltip, the pet skills taming it teaches: green if you know them, red if not."])

    controls.tamingTooltip = Widgets.CreateCheckbox(tamingRow, L["Show them"], function(checked)
        ns.db.tamingTooltip = checked
    end, true)
    controls.tamingTooltip:SetPoint("TOPLEFT", CONTROL_X, -2)

    local _, skillsButton = CommandRow(pages, "pet", 2, L["Your pet skills"],
        L["Lists in chat the pet skills this hunter knows. Same as /bpet taming."],
        L["List them"], "taming")
    controls.taming = skillsButton

    local _, tamedButton = CommandRow(pages, "pet", 2, L["Beasts you tamed"],
        L["Lists in chat the beasts you have tamed and what each one taught. Same as /bpet tamed."],
        L["List them"], "tamed")
    controls.tamed = tamedButton

    -- The compendium on the left, the arrow that leads to its beasts on
    -- the right.
    pages:Section("compendium", 1, L["PET COMPENDIUM"])

    local compendiumRow = pages:Row("compendium", 1, L["Pet Compendium"],
        L["Every beast you can tame: what it teaches, its level, where it lives and how rare it is. Also /bpet compendium."])

    local openCompendium = Widgets.CreateButton(compendiumRow, L["Open it"], function()
        if ns.CompendiumUI then ns.CompendiumUI:Toggle() end
    end, { width = 100, height = 20, primary = true })
    openCompendium:SetPoint("TOPLEFT", CONTROL_X, 0)
    controls.openCompendium = openCompendium

    -- The beast arrow, as the compendium's Arrow button and /bpet arrow
    -- switch it, and /bpet arrow check as a button.
    pages:Section("compendium", 2, L["BEAST ARROW"])

    local arrowRow = pages:Row("compendium", 2, L["Beast arrow"],
        L["A dial that points the way to a beast. Shift-click one in the compendium to aim it. Also /bpet arrow."])
    controls.beastArrow = Widgets.CreateCheckbox(arrowRow, L["Show it"], function(checked)
        if ns.BeastArrow then ns.BeastArrow:SetOn(checked) end
    end, false)
    controls.beastArrow:SetPoint("TOPLEFT", CONTROL_X, -2)

    local checkRow = pages:Row("compendium", 2, L["Check the arrow"],
        L["Lists in chat what the arrow can read where you stand: your spot, your facing, the map. Same as /bpet arrow check."])
    controls.beastArrowCheck = Widgets.CreateButton(checkRow, L["Check"], function()
        ns.HandleSlash("arrow check")
    end, { width = 64, height = 20 })
    controls.beastArrowCheck:SetPoint("TOPLEFT", CONTROL_X, 0)

    -- TomTom's arrow instead of the dial, when TomTom is installed.
    local tomtomRow = pages:Row("compendium", 2, L["Use TomTom"],
        L["With TomTom installed, its arrow points the way instead of this one. Same as /bpet arrow tomtom."])
    controls.useTomTom = Widgets.CreateCheckbox(tomtomRow, L["When installed"], function(checked)
        if ns.TomTom then ns.TomTom:SetOn(checked) end
    end, true)
    controls.useTomTom:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- General: windows and text on the left, debug on the right.
    pages:Section("general", 1, L["WINDOWS"])

    local windowRow = pages:Row("general", 1, L["Pets window"],
        L["The pet that is out, how it is doing and its food. Same as /bpet window, or /bpet on its own."])
    controls.openWindow = Widgets.CreateButton(windowRow, L["Open it"], function()
        ns.HandleSlash("window")
    end, { width = 100, height = 20, primary = true })
    controls.openWindow:SetPoint("TOPLEFT", CONTROL_X, 0)

    local minimapRow = pages:Row("general", 1, L["Minimap button"],
        L["Click it for the pets window, right-click for this page. Drag it to move it. Also /bpet minimap."])

    controls.minimap = Widgets.CreateCheckbox(minimapRow, L["Show it"], function(checked)
        ns.db.minimapHidden = not checked
        if ns.MinimapButton then ns.MinimapButton:ApplyVisibility() end
    end, true)
    controls.minimap:SetPoint("TOPLEFT", CONTROL_X, -2)

    local positionRow = pages:Row("general", 1, L["Window position"],
        L["Moves this window and the beast arrow back where they started, if one ends up off screen."])

    local reset = Widgets.CreateButton(positionRow, L["Put it back"], function()
        SettingsUI:ResetPositions()
    end, { width = 100, height = 20 })
    reset:SetPoint("TOPLEFT", CONTROL_X, 0)

    -- Bigger letters in the same windows, as Tradeskills has. Every size
    -- is read as text is drawn, so it waits for /reload.
    local textRow = pages:Row("general", 1, L["Text size"],
        L["Large and Larger add a point or two to all of this addon's text. Takes effect after /reload."])
    controls.textSize = ns.SettingsPages.TextSizeControl(textRow, CONTROL_X, function() return ns.db end)

    -- Asked 2026-10-10: the game's own look for players who would rather
    -- the windows matched the rest of their screen. Read at login, so it
    -- waits for /reload as Text size does. See UI/BlizzardLook.lua.
    local styleRow = pages:Row("general", 1, L["Window style"],
        L["Titanforged is the house look, with a gold rim and glowing edges. Blizzard uses the game's own frames, red buttons and tick boxes. Takes effect after /reload."])
    controls.windowStyle = SettingsUI.WindowStyleControl(styleRow, CONTROL_X)

    pages:Section("general", 2, L["ADVANCED"])

    local debugRow = pages:Row("general", 2, L["Debug output"],
        L["Extra messages in chat, to help track down a problem."])

    controls.debug = Widgets.CreateCheckbox(debugRow, L["Enabled"], function(checked)
        ns.db.debug = checked
    end, false)
    controls.debug:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- Core/SisterNote.lua: one chat line, once, naming the Blackthornes
    -- addons the player does not have. Off here is off in all of them.
    local sistersRow = pages:Row("general", 2, L["Sister addons"],
        L["Once, a few seconds after login, says in chat which Blackthornes addons you don't have and what each adds. Turning it off here turns it off in all of them. Same as /bpet sisters."])
    controls.sisters = Widgets.CreateCheckbox(sistersRow, L["Mention them"], function(checked)
        ns.SisterNote:SetOn(checked)
    end, true)
    controls.sisters:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- UI/WhatsNew.lua: one window after an update for every Blackthornes
    -- addon. Off here is off in all of them, as the sister note is.
    local _, whatsNewButton = CommandRow(pages, "general", 2, L["What's New"],
        L["Opens the What's New window: what changed in each of your Blackthornes addons. Same as /bpet whatsnew."],
        L["Show it"], "whatsnew")
    controls.whatsnew = whatsNewButton

    local whatsNewRow = pages:Row("general", 2, L["After an update"],
        L["Brings up the What's New window the first time you play after a Blackthornes addon updates. Turning it off here turns it off in all of them."])
    controls.whatsNewPopup = Widgets.CreateCheckbox(whatsNewRow, L["Show What's New"], function(checked)
        ns.WhatsNew:SetOn(checked)
    end, true)
    controls.whatsNewPopup:SetPoint("TOPLEFT", CONTROL_X, -2)

    local whatsNewMotionRow = pages:Row("general", 2, L["What's New motion"],
        L["The What's New window rises in, and its news slides up and glows. Turning it off here turns it off in all of them."])
    controls.whatsNewMotion = Widgets.CreateCheckbox(whatsNewMotionRow, L["Motion"], function(checked)
        ns.WhatsNew:SetMotionOn(checked)
    end, true)
    controls.whatsNewMotion:SetPoint("TOPLEFT", CONTROL_X, -2)

    local _, probeButton = CommandRow(pages, "general", 2, L["Client check"],
        L["Lists in chat which pet calls this client has, to help track down a problem. It only reads. Same as /bpet probe."],
        L["Check"], "probe")
    controls.probe = probeButton

    local _, helpButton = CommandRow(pages, "general", 2, L["Commands"],
        L["Lists every /bpet command in chat. Same as /bpet help."],
        L["List them"], "help")
    controls.help = helpButton
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
    controls.neverFeedBuffFood:SetChecked(ns.db.neverFeedBuffFood == true)
    controls.quickFeed:SetChecked(ns.db.quickFeed ~= false)
    controls.tamingTooltip:SetChecked(ns.db.tamingTooltip ~= false)
    controls.debug:SetChecked(ns.db.debug == true)
    controls.sisters:SetChecked(ns.SisterNote:IsOn())
    controls.whatsNewPopup:SetChecked(ns.WhatsNew:IsOn())
    controls.whatsNewMotion:SetChecked(ns.WhatsNew:IsMotionOn())
    controls.beastArrow:SetChecked(ns.db.beastArrow == true)
    controls.useTomTom:SetChecked(ns.db.useTomTom ~= false)
    controls.textSize:Sync()
    controls.windowStyle:Sync()
    self.pages:Refresh()
end

function SettingsUI:OnBeastArrowChanged()
    self:Refresh()
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
    blurb:SetText(L["Pets' settings have a window of their own."])

    local open = Widgets.CreateButton(panel, L["Open Pets settings"], function()
        -- The game's panel is left as it is: hiding a stock frame runs the
        -- game's own code as this addon and taints it (Equipment's Edit
        -- Mode error, 2026-10-10). Pets' window is top level in the dialog
        -- layer, so it comes up over the panel.
        SettingsUI:Show()
    end, { width = 190, height = 24 })
    open:SetPoint("TOPLEFT", blurb, "BOTTOMLEFT", 0, -14)

    local hint = Theme.CreateLabel(panel, "small", "muted")
    hint:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -10)
    hint:SetText(L["Or type /bpet settings, or click the minimap button."])

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

ns.RegisterCommand("settings", L["open the settings window"], function()
    SettingsUI:Toggle()
end)

-- Common names for the same thing, so a guess works. Kept out of the help
-- list, which would otherwise print the same line three times.
ns.commands.options = ns.commands.settings
ns.commands.config = ns.commands.settings
