-- Blackthornes Pets -- UI/PetsTabs.lua
-- One Pets window with its tabs hanging below it: Pet, Compendium and
-- Settings (a player asked, the owner said build it from a mockup,
-- 2026-10-22), as Tradeskills' and Farmer's windows wear theirs.
--
-- Each tab is still its own window underneath (UI/MainWindow.lua,
-- UI/CompendiumWindow.lua, UI/Settings.lua), each with its own size and its
-- own size grip, so nothing they save moves. Only one shows at a time: a
-- tab opens in the place the last one stood, top left corner on top left
-- corner, so it reads as one window that changes size with the tab. That
-- place is kept account wide in `windowLeft` and `windowTop` (screen
-- units from the bottom left; never rename them). A window that has never
-- had one opens where it was saved before the tabs.

local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local PetsTabs = ns.NewModule("PetsTabs")

-- How far in from the window's left edge the first tab hangs.
PetsTabs.INSET = 34

-- How far below the window the tabs reach, kept on screen with it.
PetsTabs.REACH = 32

--- The tabs, in order, and the window behind each.
function PetsTabs.Tabs()
    return {
        { key = "pet", text = L["Pet"] },
        { key = "compendium", text = L["Compendium"] },
        { key = "settings", text = L["Settings"] },
    }
end

local function Owner(key)
    if key == "pet" then return ns.UI end
    if key == "compendium" then return ns.CompendiumUI end
    if key == "settings" then return ns.SettingsUI end
    return nil
end
PetsTabs.Owner = Owner

local function FrameOf(window)
    return window and rawget(window, "frame")
end

local function Shown(frame)
    if not frame then return false end
    local ok, shown = pcall(frame.IsShown, frame)
    return ok and shown == true
end

--- The tab showing now, and its window, or nil.
function PetsTabs:Current()
    for _, tab in ipairs(PetsTabs.Tabs()) do
        local window = Owner(tab.key)
        if Shown(FrameOf(window)) then return tab.key, window end
    end
    return nil
end

--- Hang the tabs under one tab's window, with `key` lit. Called as each
--- window is built.
function PetsTabs:Attach(window, key)
    local frame = FrameOf(window)
    if not (frame and Widgets and Widgets.CreateTabStrip) then return nil end
    local ok, width = pcall(frame.GetWidth, frame)
    if not (ok and type(width) == "number" and width > 0) then width = 400 end
    local strip = Widgets.CreateTabStrip(frame, PetsTabs.Tabs(), function(picked)
        PetsTabs:Open(picked)
    end, { width = width - 2 * PetsTabs.INSET, hanging = true })
    strip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", PetsTabs.INSET, 0)
    strip:Select(key)
    window.tabStrip = strip

    -- Kept on screen tabs and all.
    local trim = rawget(window, "trim")
    if trim and ns.Titanforged and ns.Titanforged.Reach and frame.SetClampRectInsets then
        local left, right, top, bottom = ns.Titanforged.Reach(trim)
        frame:SetClampRectInsets(-left, right, top, -math.max(bottom or 0, PetsTabs.REACH))
    end
    return strip
end

--- Open a tab. The tab showing already stays as it is.
function PetsTabs:Open(key)
    local window = Owner(key)
    if window and window.Show then window:Show() end
end

--- Close the whole window, whichever tab is up.
function PetsTabs:Close()
    local _, window = self:Current()
    if window and window.Hide then window:Hide() end
end

--- Open the Pet tab, or close the window if any tab is up: the minimap
--- button's click.
function PetsTabs:Toggle()
    if self:Current() then
        self:Close()
    else
        self:Open("pet")
    end
end

--------------------------------------------------------------------------------
-- The one place
--------------------------------------------------------------------------------

local function ScaleOf(frame)
    local ok, scale = pcall(frame.GetScale, frame)
    return ok and type(scale) == "number" and scale > 0 and scale or 1
end

--- Where a window's top left corner is, in screen units, or nil.
function PetsTabs.TopLeft(frame)
    local okLeft, left = pcall(frame.GetLeft, frame)
    local okTop, top = pcall(frame.GetTop, frame)
    if not (okLeft and okTop and type(left) == "number" and type(top) == "number") then return nil end
    local scale = ScaleOf(frame)
    return left * scale, top * scale
end

--- Put a window's top left corner at a place in screen units.
function PetsTabs.PlaceAt(frame, left, top)
    local scale = ScaleOf(frame)
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / scale, top / scale)
end

--- Keep where a window stands as the place every tab opens.
function PetsTabs:Save(frame)
    if not (ns.db and frame) then return end
    local left, top = PetsTabs.TopLeft(frame)
    if left then ns.db.windowLeft, ns.db.windowTop = left, top end
end

--- A window opened at its old place: anchor it by its top left corner, so
--- a change of height keeps its top still, and keep that as the place.
function PetsTabs:Settle(frame)
    if not frame then return end
    local left, top = PetsTabs.TopLeft(frame)
    if not left then return end
    PetsTabs.PlaceAt(frame, left, top)
    if ns.db then ns.db.windowLeft, ns.db.windowTop = left, top end
end

--- A window is about to show. The tab showing makes way for it, and it
--- takes that tab's place, else the place kept. Says "switch" when it took
--- another tab's place, "placed" when it went to the place kept, nil when
--- the window should restore its own old place.
function PetsTabs:Take(window)
    local frame = FrameOf(window)
    if not frame then return nil end
    for _, tab in ipairs(PetsTabs.Tabs()) do
        local other = Owner(tab.key)
        local otherFrame = FrameOf(other)
        if other ~= window and Shown(otherFrame) then
            local left, top = PetsTabs.TopLeft(otherFrame)
            other:Hide()
            if left then
                PetsTabs.PlaceAt(frame, left, top)
                if ns.db then ns.db.windowLeft, ns.db.windowTop = left, top end
                return "switch"
            end
        end
    end
    local db = ns.db
    if db and type(db.windowLeft) == "number" and type(db.windowTop) == "number" then
        PetsTabs.PlaceAt(frame, db.windowLeft, db.windowTop)
        return "placed"
    end
    return nil
end
