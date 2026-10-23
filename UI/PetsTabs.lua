-- Blackthornes Pets -- UI/PetsTabs.lua
-- One Pets window with its tabs hanging below it: Pet, Compendium and
-- Settings (a player asked, the owner said build it from a mockup,
-- 2026-10-22), as Tradeskills' and Farmer's windows wear theirs.
--
-- Each tab is still its own window underneath (UI/MainWindow.lua,
-- UI/CompendiumWindow.lua, UI/Settings.lua), but they are all one size and
-- share one size grip (the owner, 2026-10-23: the window jumped as the tabs
-- were clicked). The size is the Compendium's, or more when a tab needs it
-- (`PetsTabs:Need`), and the scale is `windowScale`. Only one shows at a
-- time: a tab opens in the place the last one stood, top left corner on
-- top left corner, so it reads as one window. That
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

-- The one size every tab shares, the Compendium's, unless a tab needs more.
PetsTabs.WIDTH = 820
PetsTabs.HEIGHT = 586

-- The one size grip's saved scale, for every tab.
PetsTabs.SCALE_KEY = "windowScale"

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

--- The tab a window is, or nil.
function PetsTabs:KeyOf(window)
    for _, tab in ipairs(PetsTabs.Tabs()) do
        if Owner(tab.key) == window then return tab.key end
    end
    return nil
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

--------------------------------------------------------------------------------
-- The one size
--------------------------------------------------------------------------------

-- What each tab needs at least, { width, height }, as it last said.
PetsTabs.needs = {}

--- The size every tab shares: the usual one, or the most any tab needs.
function PetsTabs:Size()
    local width, height = PetsTabs.WIDTH, PetsTabs.HEIGHT
    for _, need in pairs(self.needs) do
        if need[1] and need[1] > width then width = need[1] end
        if need[2] and need[2] > height then height = need[2] end
    end
    return math.ceil(width), math.ceil(height)
end

--- Size one tab's window to the shared size, and tell it, so it can lay
--- out again what follows its height.
function PetsTabs:Fit(window)
    local frame = FrameOf(window)
    if not frame then return end
    local width, height = self:Size()
    frame:SetSize(width, height)
    if type(window.OnTabSize) == "function" then window:OnTabSize(width, height) end
end

--- Size every tab's window built so far.
function PetsTabs:FitAll()
    for _, tab in ipairs(PetsTabs.Tabs()) do self:Fit(Owner(tab.key)) end
end

--- A tab says how much room it needs; nil for either keeps the usual. Every
--- window follows when that moves the shared size.
function PetsTabs:Need(key, width, height)
    local before1, before2 = self:Size()
    self.needs[key] = { width, height }
    local after1, after2 = self:Size()
    if before1 ~= after1 or before2 ~= after2 then
        self:FitAll()
    else
        self:Fit(Owner(key))
    end
end

--- Give a window the shared scale, which the one size grip sets.
function PetsTabs.ApplyScale(frame)
    if not (frame and Widgets and Widgets.ApplySize and ns.db) then return end
    Widgets.ApplySize(frame, ns.db[PetsTabs.SCALE_KEY])
end

--- Open a tab. The tab showing already stays as it is.
function PetsTabs:Open(key)
    local window = Owner(key)
    if window and window.Show then window:Show() end
    -- Each window keeps its own strip, so light the tab it now shows.
    local strip = window and rawget(window, "tabStrip")
    if strip and strip.Select then strip:Select(key) end
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
    -- One size and one scale, whichever grip set it last, and its own tab
    -- lit, however it was opened.
    self:Fit(window)
    PetsTabs.ApplyScale(frame)
    local strip = rawget(window, "tabStrip")
    local key = self:KeyOf(window)
    if strip and strip.Select and key then strip:Select(key) end
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
