-- Blackthornes Pets -- UI/MainWindow.lua
-- The pets window: the pet that is out and how it is doing. The hunter's
-- stable and the warlock's demons will join it here.
--
-- It is what a click on the minimap button and a bare /bpet open. Built like
-- the settings window (same header, palette and row heights) so the two read
-- as one set, and like Equipment's gear window, which is the same shape.

local _, ns = ...

local UI = ns.NewModule("UI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local PADDING = 18
-- From the window's top to the gold rule under the header row.
local HEADER = 44
-- The metal rim sits on the window's edge and reaches this far inward, with
-- room to spare (UI/Titanforged.lua).
local EDGE_PAD = 11
local WIDTH = 520
local HEIGHT = 360

-- The status rows: a label on the left, its value beside it.
local ROW_HEIGHT = 24
local VALUE_X = 150

-- In the order they are shown. A row whose value the client does not give
-- (a demon has no happiness) is hidden, and the rows below close up.
local ROWS = {
    { key = "pet", label = "Pet" },
    { key = "happiness", label = "Happiness" },
    { key = "loyalty", label = "Loyalty" },
    { key = "experience", label = "Experience" },
    { key = "training", label = "Training points" },
    { key = "foods", label = "Eats" },
    { key = "food", label = "Food" },
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

    -- Escape closes it, like the game's own windows.
    if type(UISpecialFrames) == "table" then
        table.insert(UISpecialFrames, "BlackthornesPetsWindow")
    end

    self.frame = frame
    self:BuildHeader()

    local empty = Theme.CreateLabel(frame, "normal", "muted")
    empty:SetPoint("CENTER", 0, 0)
    empty:SetText("No pet out.")
    self.emptyLabel = empty

    self:BuildStatus()
    self:BuildFeedButton()

    -- The Feed button lives outside the window (see BuildFeedButton), so it
    -- has to be told when the window goes.
    frame:HookScript("OnHide", function() UI:PlaceFeedButton(nil) end)

    local footer = Theme.CreateLabel(frame, "small", "muted")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    self.footer = footer

    frame:Hide()
    return frame
end

--- The header row. The window's name is on the plate across the top edge
--- and the close gem sits on the top right corner (UI/Titanforged.lua), so
--- the row holds whose pets these are and the Settings button, clear of the
--- portrait on the left.
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

    -- Below the close gem on the corner.
    local settings = Widgets.CreateButton(header, "Settings", function()
        if ns.SettingsUI then ns.SettingsUI:Toggle() end
    end, { width = 70, height = 20 })
    settings:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -10, 4)
end

function UI:BuildStatus()
    self.rows = {}
    for _, spec in ipairs(ROWS) do
        local label = Theme.CreateLabel(self.frame, "small", "muted")
        label:SetText(spec.label)

        local value = Theme.CreateLabel(self.frame, "normal", "text")
        value:SetWidth(WIDTH - VALUE_X - PADDING)
        value:SetWordWrap(true)

        self.rows[spec.key] = { label = label, value = value }
    end
end

--- The Feed button. It is a secure action button, because casting Feed Pet
--- is protected, and it belongs to UIParent rather than to this window: a
--- window holding a secure button cannot be closed or moved in combat. It is
--- anchored over the window only while out of combat, and let go of as
--- combat starts, which PLAYER_REGEN_DISABLED fires just before.
function UI:BuildFeedButton()
    local button = Widgets.CreateButton(UIParent, "Feed", nil, {
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

    if stack and self.frame and self.frame:IsShown() then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", ns.Food:FeedMacro(stack))
        button:SetText("Feed " .. stack.name)
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -PADDING, 10)
        button:SetFrameLevel(self.frame:GetFrameLevel() + 10)
        button:Show()
        self.feedStack = stack
    else
        button:Hide()
        button:ClearAllPoints()
        button:SetAttribute("macrotext", nil)
        self.feedStack = nil
    end
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

--- Fill the status rows from a PetStatus reading, hiding the ones with
--- nothing to say and closing up the gaps.
function UI:ShowStatus(status)
    local PetStatus = ns.PetStatus
    local values = {}

    if status.exists then
        local pet = status.name or "Your pet"
        local details = {}
        if status.family and status.family ~= status.name then details[#details + 1] = status.family end
        if status.level then details[#details + 1] = "level " .. status.level end
        if #details > 0 then pet = pet .. ", " .. table.concat(details, ", ") end

        values.pet = pet
        values.happiness = PetStatus:HappinessText(status)
        values.loyalty = PetStatus:LoyaltyText(status)
        values.experience = PetStatus:ExperienceText(status)
        values.training = PetStatus:TrainingText(status)
        values.foods = PetStatus:FoodText(status)

        if status.foods then
            local stacks = ns.Food:Scan(status)
            values.food = ns.Food:Summary(stacks)
            self:PlaceFeedButton(stacks[1])
        else
            self:PlaceFeedButton(nil)
        end
    else
        self:PlaceFeedButton(nil)
    end

    local y = -(HEADER + 14)
    for _, spec in ipairs(ROWS) do
        local row = self.rows[spec.key]
        local text = values[spec.key]
        row.label:SetShown(text ~= nil)
        row.value:SetShown(text ~= nil)
        if text then
            row.label:SetPoint("TOPLEFT", PADDING, y - 1)
            row.value:SetPoint("TOPLEFT", VALUE_X, y)
            row.value:SetText(text)
            -- A value that wraps onto a second line pushes the rows below
            -- down, rather than running into the next one.
            local step = ROW_HEIGHT
            local ok, height = pcall(row.value.GetStringHeight, row.value)
            if ok and type(height) == "number" and height + 10 > step then
                step = math.ceil(height + 10)
            end
            y = y - step
        end
    end

    self.emptyLabel:SetShown(not status.exists)
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
        self.subtitle:SetText("Hunter")
    elseif class == "WARLOCK" then
        self.subtitle:SetText("Warlock")
    else
        self.subtitle:SetText("")
    end

    if self:HasPetClass() then
        self.footer:SetText(ns.VersionLabel())
        self:ShowStatus(ns.PetStatus:Read())
    else
        self.footer:SetText("Pets is for hunters and warlocks.")
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
        self:RestorePosition()
        self.frame:Show()
        ns.Motion:Open(self.frame)
        -- A light runs round the portrait as it opens.
        if ns.Titanforged then ns.Titanforged:Opened(self.frame) end
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

ns.RegisterCommand("window", "open the pets window (so does /bpet on its own)", function()
    UI:Toggle()
end)
