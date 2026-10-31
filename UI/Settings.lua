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

local COLUMN_GAP = 18
-- Two columns across the width every tab shares (UI/PetsTabs.lua).
local COLUMN_WIDTH = math.floor(((ns.PetsTabs and ns.PetsTabs.WIDTH or 820) - PADDING * 2 - COLUMN_GAP) / 2)
-- Where the controls start: room for a label like "Window Position:" in the
-- game's font, which runs wider than it looks.
local CONTROL_X = 150

local TITLE = "Blackthornes Pets"

-- The pages along the top (UI/SettingsPages.lua), as Tradeskills' Settings
-- tab has them. Every setting kept its saved name; only its place moved.
local PAGES = {
    { key = "pet", text = L["PET"],
      tip = L["Feeding warnings, the Feed button and taming skills on tooltips"] },
    { key = "compendium", text = L["COMPENDIUM"],
      tip = L["The Pet Compendium, the beast arrow and TomTom"] },
    { key = "general", text = L["GENERAL"],
      tip = L["Window position, text size and What's New"] },
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

    -- The fold gem beside the close gem folds the window down to its plate
    -- (UI/FoldWindow.lua, a player asked, 2026-10-24).
    if ns.FoldWindow then
        ns.FoldWindow:Add(frame, { onToggle = function(folded)
            if not folded then SettingsUI:Refresh() end
        end })
    end

    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SettingsUI:SavePosition()
    end)

    -- The house size grip under the bottom right corner (Widgets.WindowGrip),
    -- saved as `windowScale`, the one every tab shares (`settingsScale`,
    -- from before the tabs, stays in the save unread).
    self.sizeGrip = Widgets.WindowGrip(frame, "windowScale", function()
        SettingsUI:SavePosition()
    end)

    -- Escape closes it, like the game's own windows.
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsSettings")
    end

    self.frame = frame
    if ns.PetsTabs then ns.PetsTabs:Attach(self, "settings") end
    -- Inside the one window, it closes with this one.
    frame:HookScript("OnHide", function() if ns.PetsTabs then ns.PetsTabs:Closed(frame) end end)
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
    -- The pages fit their fullest page; the window is then the size every
    -- tab shares, or more when a page needs it (UI/PetsTabs.lua).
    local pages = self.pages
    local fit = pages.Fit
    pages.Fit = function(page)
        fit(page)
        -- What the pages asked for: laid into the one window the frame
        -- fills the area, so its own size would only say how big that is.
        local need = page.need or { frame:GetWidth(), frame:GetHeight() }
        if ns.PetsTabs then ns.PetsTabs:Need("settings", need[1], need[2]) end
    end
    pages:Fit()

    local footer = Theme.CreateLabel(frame, "tiny", "dim")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("BOTTOMRIGHT", -PADDING - 90, 14)
    footer:SetText(L["Changes save as you make them."])
    self.footer = footer

    frame:Hide()
    return frame
end

--- The header row. The addon's name is on the plate across the top edge
--- and the close gem sits on the top right corner (UI/Titanforged.lua), so
--- the row is the rule under the plate.
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

    -- The tab says Settings; the version sits small in the footer's right
    -- corner, as on every tab (the unified look, cards 4 and 5).
    local version = Theme.CreateLabel(frame, "tiny", "dim", "RIGHT")
    version:SetText(ns.VersionLabel())
    version:SetPoint("BOTTOMRIGHT", -PADDING, 14)
end

--- A row whose button runs a /bpet command.
--- Make a row taller by `by`, for a control that sits under the first
--- line, with its description moved down to match (as Farmer has it).
local function GrowRow(row, by)
    local top = row.compactHeight
    row.hint:ClearAllPoints()
    row.hint:SetPoint("TOPLEFT", 0, -(top + by))
    row.compactHeight = top + by
    row.fullHeight = row.fullHeight + by
    local described = ns.db and ns.db.settingsDescriptions == true
    row.shownHeight = described and row.fullHeight or row.compactHeight
    row:SetHeight(row.shownHeight)
end

local function CommandRow(pages, page, column, label, description, buttonText, command)
    local row = pages:Row(page, column, label, description)
    local button = Widgets.CreateButton(row, buttonText, function()
        ns.HandleSlash(command)
    end, { width = 100, height = 20 })
    button:SetPoint("TOPLEFT", CONTROL_X, 0)
    return row, button
end

-- The window styles, in the order their drop-down lists them.
local STYLES = { "titanforged", "blizzard" }
local STYLE_LABELS = { titanforged = "Titanforged", blizzard = "Blizzard" }

--- Titanforged or Blizzard, with Reload under it while the pick differs
--- from what is drawn, as the Text size row has. A drop-down, like Text
--- size.
function SettingsUI.WindowStyleControl(row, x)
    local reload
    local function Drawn()
        local Look = ns.BlizzardLook
        return Look and Look.Style() or "titanforged"
    end

    local stepper = Widgets.CreateChoice(row, {
        min = 1, max = #STYLES, step = 1,
        format = function(value) return STYLE_LABELS[STYLES[value]] end,
        onChange = function(value)
            ns.db.windowStyle = STYLES[value]
            if ns.SharedChoices then ns.SharedChoices:Changed("windowStyle", STYLES[value]) end
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

    -- The warning and its "only when unhappy" share a row: the second tick
    -- only matters while the first is on. The saved keys are unchanged.
    local feedRow = pages:Row("pet", 1, L["Feed Warning:"],
        L["Warns you when your pet isn't happy. Only When Unhappy waits until it's unhappy."])

    controls.feedWarning = Widgets.CreateCheckbox(feedRow, L["On"], function(checked)
        ns.db.feedWarning = checked
    end, true)
    controls.feedWarning:SetPoint("TOPLEFT", CONTROL_X, -2)

    controls.feedWarnOnlyUnhappy = Widgets.CreateCheckbox(feedRow, L["Only When Unhappy"], function(checked)
        ns.db.feedWarnOnlyUnhappy = checked
        -- The Feed button by the quests follows the same line.
        if ns.Food then ns.Food:Update() end
    end, false)
    local gap = 10
    if CONTROL_X + controls.feedWarning:GetWidth() + gap + controls.feedWarnOnlyUnhappy:GetWidth() <= COLUMN_WIDTH then
        controls.feedWarnOnlyUnhappy:SetPoint("LEFT", controls.feedWarning, "RIGHT", gap, 0)
    else
        -- Too wide for one line (German runs longer): it goes under the first.
        controls.feedWarnOnlyUnhappy:SetPoint("TOPLEFT", CONTROL_X, -22)
        GrowRow(feedRow, 20)
    end

    local lowFoodRow = pages:Row("pet", 1, L["Low Food Warning:"],
        L.Format("Warns you in chat when you have fewer than %d food your pet will eat.", ns.Food.LOW_FOOD))

    controls.lowFoodWarning = Widgets.CreateCheckbox(lowFoodRow, L["On"], function(checked)
        ns.db.lowFoodWarning = checked
    end, true)
    controls.lowFoodWarning:SetPoint("TOPLEFT", CONTROL_X, -2)

    local buffFoodRow = pages:Row("pet", 1, L["Never Feed Buff Food:"],
        L["Food that gives a buff is always fed last. Tick this to never feed it."])

    controls.neverFeedBuffFood = Widgets.CreateCheckbox(buffFoodRow, L["On"], function(checked)
        ns.db.neverFeedBuffFood = checked
        if ns.Food then ns.Food:Update() end
    end, false)
    controls.neverFeedBuffFood:SetPoint("TOPLEFT", CONTROL_X, -2)

    local quickFeedRow = pages:Row("pet", 1, L["Feed Button:"],
        L["A Feed button above your quests while your pet is hungry."])

    controls.quickFeed = Widgets.CreateCheckbox(quickFeedRow, L["Show"], function(checked)
        ns.db.quickFeed = checked
        if ns.Food then ns.Food:Update() end
    end, true)
    controls.quickFeed:SetPoint("TOPLEFT", CONTROL_X, -2)

    pages:Section("pet", 2, L["TAMING"])

    local tamingRow = pages:Row("pet", 2, L["Taming Skills:"],
        L["A beast's tooltip shows what it teaches. Green you know, red you don't."])

    -- Off, Shift or Always (UI/TooltipShift.lua): on or off stays in
    -- tamingTooltip, Shift is kept apart.
    local TooltipShift = ns.TooltipShift
    local shiftKey = ns.TamingTooltip.SHIFT_KEY
    controls.tamingTooltip = Widgets.CreateChoice(tamingRow, {
        min = 0, max = 2, step = 1,
        format = function(value) return TooltipShift.NAMES[value] end,
        onChange = function(value)
            TooltipShift:Apply(value, shiftKey, ns.db.tamingTooltip ~= false, function(on)
                ns.db.tamingTooltip = on
            end)
        end,
    })
    ns.SettingsPages.FitStepper(controls.tamingTooltip, TooltipShift.NAMES)
    controls.tamingTooltip:SetPoint("TOPLEFT", CONTROL_X, -2)

    pages:Section("pet", 2, L["WARLOCK"])

    local shardsRow = pages:Row("pet", 2, L["Soul Shards:"],
        L.Format("Shows your soul shards on the Pet tab and warns you at %d or fewer.", ns.SoulShards.LOW))

    controls.soulShards = Widgets.CreateCheckbox(shardsRow, L["On"], function(checked)
        ns.SoulShards:Set(checked)
    end, false)
    controls.soulShards:SetPoint("TOPLEFT", CONTROL_X, -2)

    local stonesRow = pages:Row("pet", 2, L["Stone Reminder:"],
        L["Tells you after a fight when you have no Healthstone, or your Soulstone isn't on anyone."])

    controls.stoneReminder = Widgets.CreateCheckbox(stonesRow, L["On"], function(checked)
        ns.Stones:Set(checked)
    end, false)
    controls.stoneReminder:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- The compendium on the left, the arrow that leads to its beasts on
    -- the right.
    pages:Section("compendium", 1, L["PET COMPENDIUM"])

    local compendiumRow = pages:Row("compendium", 1, L["Pet Compendium:"], nil)

    local openCompendium = Widgets.CreateButton(compendiumRow, L["Open"], function()
        if ns.CompendiumUI then ns.CompendiumUI:Toggle() end
    end, { width = 100, height = 20, primary = true })
    openCompendium:SetPoint("TOPLEFT", CONTROL_X, 0)
    controls.openCompendium = openCompendium

    -- The beast arrow, as the compendium's Arrow button and /bpet arrow
    -- switch it, and /bpet arrow check as a button.
    pages:Section("compendium", 2, L["ARROW"])

    local arrowRow = pages:Row("compendium", 2, L["Beast Arrow:"],
        L["Points the way to a beast. Shift-click one in the compendium to aim it."])
    controls.beastArrow = Widgets.CreateCheckbox(arrowRow, L["Show"], function(checked)
        if ns.BeastArrow then ns.BeastArrow:SetOn(checked) end
    end, false)
    controls.beastArrow:SetPoint("TOPLEFT", CONTROL_X, -2)

    local clearRow = pages:Row("compendium", 2, L["Stop Following:"], nil)
    controls.beastArrowClear = Widgets.CreateButton(clearRow, L["Clear"], function()
        ns.HandleSlash("arrow clear")
    end, { width = 64, height = 20 })
    controls.beastArrowClear:SetPoint("TOPLEFT", CONTROL_X, 0)

    -- TomTom's arrow instead of the dial, when TomTom is installed.
    local tomtomRow = pages:Row("compendium", 2, L["Use TomTom:"],
        L["With TomTom installed, its arrow shows the way instead."])
    controls.useTomTom = Widgets.CreateCheckbox(tomtomRow, L["On"], function(checked)
        if ns.TomTom then ns.TomTom:SetOn(checked) end
    end, true)
    controls.useTomTom:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- A trip step by step to a far place (Logic/Travel.lua), on unless
    -- unticked.
    local routeRow = pages:Row("compendium", 2, L["Guide Me:"],
        L["When the place is in another zone or across the sea, the arrow leads you there step by step."])
    controls.arrowRoute = Widgets.CreateCheckbox(routeRow, L["On"], function(checked)
        if ns.Travel then ns.Travel:SetOn(checked) end
    end, true)
    controls.arrowRoute:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- How big the whole arrow is drawn, 100% unless picked (the owner,
    -- 2026-10-26). The arrow keeps its spot.
    local arrowSizeRow = pages:Row("compendium", 2, L["Arrow Size:"], nil)
    controls.arrowSize = Widgets.CreateChoice(arrowSizeRow, {
        min = 50, max = 100, step = 25, value = 100,
        format = function(percent) return ("%d%%"):format(percent) end,
        onChange = function(percent)
            if ns.BeastArrowUI then ns.BeastArrowUI:SetSize(percent) end
        end,
    })
    ns.SettingsPages.FitStepper(controls.arrowSize, { "50%", "75%", "100%" })
    controls.arrowSize:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- General: the same two sections in every Blackthornes addon (the
    -- owner, 2026-10-29), WINDOWS on the left and ADDONS on the right, then
    -- this addon's own window rows. The minimap button always shows (the
    -- owner, 2026-10-15), alone or in the shared Blackthornes button.
    pages:Section("general", 1, L["WINDOWS"])

    -- Asked 2026-10-10: the game's own look for players who would rather
    -- the windows matched the rest of their screen. Read at login, so it
    -- waits for /reload as Text size does. See UI/BlizzardLook.lua.
    local styleRow = pages:Row("general", 1, L["Window Style:"], nil)
    controls.windowStyle = SettingsUI.WindowStyleControl(styleRow, CONTROL_X)

    -- Bigger letters in the same windows, as Tradeskills has. Every size
    -- is read as text is drawn, so it waits for /reload.
    local textRow = pages:Row("general", 1, L["Text Size:"], nil)
    controls.textSize = ns.SettingsPages.TextSizeControl(textRow, CONTROL_X, function() return ns.db end)

    -- The size the window's grip saves, for all three tabs.
    local sizeRow = pages:Row("general", 1, L["Window Size:"], nil)
    controls.windowScale = ns.SettingsPages.WindowSizeControl(sizeRow, CONTROL_X,
        function() return ns.db and ns.db.windowScale end,
        function(percent) if ns.PetsTabs then ns.PetsTabs:SetScale(percent) end end)

    -- How much the windows move: they rise in, glow and glint at Full,
    -- only fade at Subtle and stay still at Off. Full until picked.
    local effectsRow = pages:Row("general", 1, L["Effects:"], nil)
    local Motion = ns.Motion
    local effectNames = { full = L["Full"], subtle = L["Subtle"], off = L["Off"] }
    local function EffectIndex()
        local level = Motion.Level()
        for index, name in ipairs(Motion.LEVELS) do
            if name == level then return index end
        end
        return 1
    end
    controls.effects = Widgets.CreateChoice(effectsRow, {
        min = 1, max = #Motion.LEVELS, step = 1, value = EffectIndex(),
        format = function(index) return effectNames[Motion.LEVELS[index]] end,
        onChange = function(index) Motion.SetLevel(Motion.LEVELS[index]) end,
    })
    controls.effects:SetPoint("TOPLEFT", CONTROL_X, 0)
    controls.effectsIndex = EffectIndex

    -- One minimap button for every Blackthornes addon (UI/SharedMinimap.lua,
    -- the owner, 2026-10-28): ticked unless unticked, the same in all five.
    local combineRow = pages:Row("general", 1, L["Combine Addon Buttons:"], nil)
    controls.combineButtons = Widgets.CreateCheckbox(combineRow, L["On"], function(checked)
        if ns.SharedMinimap then ns.SharedMinimap.SetCombined(checked) end
    end, true)
    controls.combineButtons:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- One window for every Blackthornes addon (UI/SharedWindow.lua, the
    -- owner, 2026-10-30): on unless unticked, the same in all five. Ticked
    -- or not, Settings opens again where it now belongs.
    local oneRow = pages:Row("general", 1, L["One Window:"], nil)
    controls.oneWindow = Widgets.CreateCheckbox(oneRow, L["On"], function(checked)
        SettingsUI:SetOneWindow(checked)
    end, true)
    controls.oneWindow:SetPoint("TOPLEFT", CONTROL_X, -2)

    local windowRow = pages:Row("general", 1, L["Pets:"], nil)
    controls.openWindow = Widgets.CreateButton(windowRow, L["Open"], function()
        ns.HandleSlash("window")
    end, { width = 100, height = 20, primary = true })
    controls.openWindow:SetPoint("TOPLEFT", CONTROL_X, 0)

    local positionRow = pages:Row("general", 1, L["Window Position:"],
        L["Reset the UI windows to their defaults."])

    local reset = Widgets.CreateButton(positionRow, L["Set Default"], function()
        SettingsUI:ResetPositions()
        ns.Print(L["UI windows set to defaults."])
    end, { width = 110, height = 20 })
    reset:SetPoint("TOPLEFT", CONTROL_X, 0)
    controls.resetPositions = reset

    pages:Section("general", 2, L["ADDONS"])

    -- Debug and the checks are typed only (/bpet debug, probe, arrow check;
    -- the owner, 2026-10-23): players don't need them.
    -- Core/SisterNote.lua: one chat line, once, naming the Blackthornes
    -- addons the player does not have. Off here is off in all of them.
    local sistersRow = pages:Row("general", 2, L["Sister Addons:"],
        L["Says once in chat which Blackthornes addons you don't have."])
    controls.sisters = Widgets.CreateCheckbox(sistersRow, L["On"], function(checked)
        ns.SisterNote:SetOn(checked)
    end, true)
    controls.sisters:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- UI/WhatsNew.lua: one window after an update for every Blackthornes
    -- addon. Off here is off in all of them, as the sister note is.
    local _, whatsNewButton = CommandRow(pages, "general", 2, L["What's New:"], nil,
        L["Open"], "whatsnew")
    controls.whatsnew = whatsNewButton

    local whatsNewRow = pages:Row("general", 2, L["What's New After Updates:"],
        L["Opens What's New the first time you play after an update."])
    controls.whatsNewPopup = Widgets.CreateCheckbox(whatsNewRow, L["On"], function(checked)
        ns.WhatsNew:SetOn(checked)
    end, true)
    controls.whatsNewPopup:SetPoint("TOPLEFT", CONTROL_X, -2)

    local whatsNewMotionRow = pages:Row("general", 2, L["What's New Motion:"], nil)
    controls.whatsNewMotion = Widgets.CreateCheckbox(whatsNewMotionRow, L["On"], function(checked)
        ns.WhatsNew:SetMotionOn(checked)
    end, true)
    controls.whatsNewMotion:SetPoint("TOPLEFT", CONTROL_X, -2)

    -- The chat-only commands (food, taming, tamed, help) have no button
    -- here: they are typed only (the owner, 2026-10-15).
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
    controls.feedWarning:SetChecked(ns.db.feedWarning ~= false)
    controls.feedWarnOnlyUnhappy:SetChecked(ns.db.feedWarnOnlyUnhappy == true)
    controls.lowFoodWarning:SetChecked(ns.db.lowFoodWarning ~= false)
    controls.neverFeedBuffFood:SetChecked(ns.db.neverFeedBuffFood == true)
    controls.quickFeed:SetChecked(ns.db.quickFeed ~= false)
    controls.soulShards:SetChecked(ns.db.soulShards == true)
    controls.stoneReminder:SetChecked(ns.db.stoneReminder == true)
    controls.tamingTooltip:SetValue(ns.TooltipShift:Mode(ns.db.tamingTooltip ~= false,
        ns.TamingTooltip.SHIFT_KEY), true)
    controls.sisters:SetChecked(ns.SisterNote:IsOn())
    controls.combineButtons:SetChecked(not ns.SharedMinimap or ns.SharedMinimap.Combined())
    local One = ns.PetsTabs and ns.PetsTabs.One()
    controls.oneWindow:SetChecked(One ~= nil and One.On() == true)
    controls.whatsNewPopup:SetChecked(ns.WhatsNew:IsOn())
    controls.whatsNewMotion:SetChecked(ns.WhatsNew:IsMotionOn())
    controls.beastArrow:SetChecked(ns.db.beastArrow == true)
    controls.useTomTom:SetChecked(ns.db.useTomTom ~= false)
    controls.arrowRoute:SetChecked(ns.db.arrowRoute ~= false)
    controls.arrowSize:SetValue(ns.BeastArrowUI and ns.BeastArrowUI.Size() or 100, true)
    controls.textSize:Sync()
    controls.windowStyle:Sync()
    controls.effects:SetValue(controls.effectsIndex(), true)
    controls.windowScale:Sync()
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
    if ns.PetsTabs then ns.PetsTabs:Save(self.frame) end
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
    -- With "One Window:" ticked, the one window opens on Pets instead
    -- (UI/PetsTabs.lua), and lays this window in.
    if ns.PetsTabs and ns.PetsTabs:Route("settings") then return end
    self:Build()

    if not self.frame:IsShown() then
        local how = ns.PetsTabs and ns.PetsTabs:Take(self)
        if not how then self:RestorePosition() end
        self.frame:Show()
        if not how and ns.PetsTabs then ns.PetsTabs:Settle(self.frame) end
        if how ~= "switch" then ns.Motion:Open(self.frame) end
    end
    if ns.FoldWindow then ns.FoldWindow:Unfold(self.frame) end

    self:Refresh()
end

--- Tick or untick "One Window:" in every loaded addon, and open Settings
--- again in the one window, or in its own.
function SettingsUI:SetOneWindow(on)
    local Tabs = ns.PetsTabs
    local One = Tabs and Tabs.One()
    if not One then return end
    local inside = Tabs:Hosted()
    One.SetOn(on)
    if on and not inside and self.frame and self.frame:IsShown() then
        Tabs.switching = true
        self.frame:Hide()
        Tabs.switching = false
        self:Show()
    elseif not on and inside then
        self:Show()
    end
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

--------------------------------------------------------------------------------
-- Choices every Blackthornes addon shares (UI/SharedChoices.lua): a change
-- made in a sister is written here the way this addon writes it itself.
--------------------------------------------------------------------------------

if ns.SharedChoices then
    ns.SharedChoices:Join("Pets", function(choice, value)
        if not ns.db then return end
        if choice == "textSize" then
            if ns.Theme.TEXT_STEPS and ns.Theme.TEXT_STEPS[value] then ns.db.textSize = value end
        elseif choice == "windowStyle" then
            if value == "titanforged" or value == "blizzard" then ns.db.windowStyle = value end
        elseif choice == "effects" then
            if value == "full" or value == "subtle" or value == "off" then ns.Motion.SetLevel(value) end
        elseif choice == "useTomTom" then
            if ns.TomTom then ns.TomTom:SetOn(value and true or false) end
        elseif choice == "arrowRoute" then
            if ns.Travel then ns.Travel:SetOn(value and true or false) end
        elseif choice == "arrowSize" then
            if ns.BeastArrowUI then ns.BeastArrowUI:SetSize(value) end
        end
        if ns.SettingsUI and ns.SettingsUI.Refresh and ns.SettingsUI.frame and ns.SettingsUI.frame:IsShown() then pcall(ns.SettingsUI.Refresh, ns.SettingsUI) end
    end)
end
