-- Blackthornes Pets -- UI/MainWindow.lua
-- The pets window: where the hunter's stable and the warlock's demons will be
-- shown once there are pet features. For now it is the frame they will go in.
--
-- It is what a click on the minimap button and a bare /bpet open. Built like
-- the settings window (same header, palette and row heights) so the two read
-- as one set, and like Equipment's gear window, which is the same shape.

local _, ns = ...

local UI = ns.NewModule("UI")

local Theme = ns.Theme
local Widgets = ns.Widgets

local PADDING = 18
local HEADER = 36
local WIDTH = 520
local HEIGHT = 360

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
    Theme.Border(frame, "borderLit")

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
    empty:SetText("Nothing here yet.")
    self.emptyLabel = empty

    local footer = Theme.CreateLabel(frame, "small", "muted")
    footer:SetPoint("BOTTOMLEFT", PADDING, 14)
    footer:SetPoint("BOTTOMRIGHT", -PADDING, 14)
    self.footer = footer

    frame:Hide()
    return frame
end

function UI:BuildHeader()
    local frame = self.frame

    local header = Theme.CreatePanel(frame, "header", false)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER)
    Theme.HouseHeader(header, 20)

    local title = Theme.CreateLabel(header, "title", "accent")
    title:SetPoint("LEFT", PADDING, 0)
    title:SetText("Blackthornes Pets")

    local subtitle = Theme.CreateLabel(header, "small", "muted")
    subtitle:SetPoint("LEFT", title, "RIGHT", 10, -1)
    self.subtitle = subtitle

    local close = Widgets.CreateButton(header, "X", function() UI:Hide() end,
        { width = 22, height = 20, danger = true })
    close:SetPoint("RIGHT", -PADDING + 4, 0)

    local settings = Widgets.CreateButton(header, "Settings", function()
        if ns.SettingsUI then ns.SettingsUI:Toggle() end
    end, { width = 70, height = 20 })
    settings:SetPoint("RIGHT", close, "LEFT", -6, 0)

    local divider = Theme.CreateDivider(frame, "borderLit")
    divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    divider:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")
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
    else
        self.footer:SetText("Pets is for hunters and warlocks.")
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
