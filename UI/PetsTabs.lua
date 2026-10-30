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

--- The tabs, in order, and the window behind each. Settings is always
--- last, flush right.
function PetsTabs.Tabs()
    return {
        { key = "pet", text = L["Pet"] },
        { key = "compendium", text = L["Compendium"] },
        { key = "settings", text = L["Settings"], right = true },
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
    -- Inside the one window it fills the area, which grows instead.
    if self.area then
        self:Grow()
        return
    end
    local width, height = self:Size()
    local okW, oldW = pcall(frame.GetWidth, frame)
    frame:SetSize(width, height)
    -- Settings stays flush right as the window grows.
    local strip = rawget(window, "tabStrip")
    if strip and strip.SetRoom and not (okW and oldW == width) then
        strip:SetRoom(width - 2 * PetsTabs.INSET)
    end
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
    -- The one window has its own scale.
    if PetsTabs.area then return end
    Widgets.ApplySize(frame, ns.db[PetsTabs.SCALE_KEY])
end

--- Settings' Window Size: every tab drawn at `percent`, the one showing
--- kept by its top left corner.
function PetsTabs:SetScale(percent)
    if not ns.db then return end
    ns.db[PetsTabs.SCALE_KEY] = tonumber(percent)
    for _, tab in ipairs(PetsTabs.Tabs()) do
        local frame = FrameOf(Owner(tab.key))
        if frame then
            local left, top = PetsTabs.TopLeft(frame)
            PetsTabs.ApplyScale(frame)
            if left and Shown(frame) then PetsTabs.PlaceAt(frame, left, top) end
        end
    end
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
    if self.area then
        local One = PetsTabs.One()
        if One and One.Close then pcall(One.Close) end
        return
    end
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
    if not (ns.db and frame) or self.area then return end
    local left, top = PetsTabs.TopLeft(frame)
    if left then ns.db.windowLeft, ns.db.windowTop = left, top end
end

--- A window opened at its old place: anchor it by its top left corner, so
--- a change of height keeps its top still, and keep that as the place.
function PetsTabs:Settle(frame)
    if not frame or self.area then return end
    local left, top = PetsTabs.TopLeft(frame)
    if not left then return end
    PetsTabs.PlaceAt(frame, left, top)
    if ns.db then ns.db.windowLeft, ns.db.windowTop = left, top end
end

-- True while one tab hides to make way for another.
PetsTabs.switching = false

--- A window is about to show. The tab showing makes way for it, and it
--- takes that tab's place, else the place kept. Says "switch" when it took
--- another tab's place, "placed" when it went to the place kept, nil when
--- the window should restore its own old place.
function PetsTabs:Take(window)
    local frame = FrameOf(window)
    if not frame then return nil end
    -- Inside the one window: laid in, and the other tab steps aside.
    if self.area then
        self:LayIn(window)
        local strip = rawget(window, "tabStrip")
        local key = self:KeyOf(window)
        if strip and strip.Select and key then strip:Select(key) end
        for _, tab in ipairs(PetsTabs.Tabs()) do
            local other = Owner(tab.key)
            if other ~= window and Shown(FrameOf(other)) then
                self.switching = true
                local ok, err = pcall(other.Hide, other)
                self.switching = false
                if not ok and ns.Debug then ns.Debug("tab switch:", tostring(err)) end
            end
        end
        return "switch"
    end
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
            self.switching = true
            other:Hide()
            self.switching = false
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

--------------------------------------------------------------------------------
-- The one window
--
-- With "One Window:" ticked (UI/SharedWindow.lua, the owner said build it,
-- 2026-10-30), the Pet, Compendium and Settings tabs show inside the one
-- Blackthornes window: each window is laid into its area, filling it,
-- without its own rim, plate, portrait, gems or size grip, since the one
-- window has its own. Their tabs still hang below, under the one window's
-- edge. Unticked, or when another addon is picked on the rail, they go
-- back to their own place, size and scale. The Feed buttons are untouched:
-- they are placed by screen position, wherever the window is.
--------------------------------------------------------------------------------

-- The one window's area while the pages are in it, else nil.
PetsTabs.area = nil
-- The tab to show when the one window lays Pets in.
PetsTabs.wanted = nil
-- True while the pages go back, so their OnHide does not close the one
-- window too.
PetsTabs.leaving = false

--- The copy of the one window that draws it, or nil.
function PetsTabs.One()
    local SharedWindow = ns.SharedWindow
    if not (SharedWindow and SharedWindow.Drawer) then return nil end
    local ok, drawer = pcall(SharedWindow.Drawer)
    local api = ok and type(drawer) == "table" and drawer.api or nil
    return type(api) == "table" and api or nil
end

--- True while the pages show in the one window.
function PetsTabs:Hosted()
    return self.area ~= nil
end

-- What a window's own frame wears, put out of sight inside the one window
-- and back after: the trim (plate, portrait, close and fold gems, corners),
-- the size grip and the rim drawn on the frame itself.
local function Bare(window, bare)
    local frame = FrameOf(window)
    if not frame then return end
    local trim = rawget(window, "trim") or rawget(frame, "titan")
    if trim and trim.SetShown then trim:SetShown(not bare) end
    local grip = rawget(window, "sizeGrip")
    if grip and grip.SetShown then grip:SetShown(not bare) end
    if bare then
        local kept = {}
        local ok, regions = pcall(function() return { frame:GetRegions() } end)
        for _, region in ipairs(ok and regions or {}) do
            local okLayer, layer = pcall(region.GetDrawLayer, region)
            if okLayer and layer == "BORDER" and region:IsShown() then
                region:Hide()
                kept[#kept + 1] = region
            end
        end
        window.bareRim = kept
        pcall(frame.RegisterForDrag, frame)
    else
        for _, region in ipairs(rawget(window, "bareRim") or {}) do region:Show() end
        window.bareRim = nil
        pcall(frame.RegisterForDrag, frame, "LeftButton")
    end
end

--- Lay one window into the area, filling it.
function PetsTabs:LayIn(window)
    local frame, area = FrameOf(window), self.area
    if not (frame and area) then return end
    if frame:GetParent() ~= area then frame:SetParent(area) end
    frame:ClearAllPoints()
    frame:SetAllPoints(area)
    frame:SetScale(1)
    Bare(window, true)
    local strip = rawget(window, "tabStrip")
    if strip then
        -- Hung from the one window's own bottom edge, not the area's.
        local one = area:GetParent()
        local drop = 8
        if one then
            local okA, a = pcall(area.GetBottom, area)
            local okO, o = pcall(one.GetBottom, one)
            if okA and okO and type(a) == "number" and type(o) == "number" then drop = a - o end
        end
        strip:ClearAllPoints()
        strip:SetPoint("TOPLEFT", area, "BOTTOMLEFT", PetsTabs.INSET, -drop)
        local ok, width = pcall(area.GetWidth, area)
        if ok and type(width) == "number" and width > 0 and strip.SetRoom then
            strip:SetRoom(width - 2 * PetsTabs.INSET)
        end
    end
    local okW, width = pcall(area.GetWidth, area)
    local okH, height = pcall(area.GetHeight, area)
    if okW and okH and type(window.OnTabSize) == "function" then window:OnTabSize(width, height) end
end

--- Give one window back its own place, size and scale.
function PetsTabs:LayOut(window)
    local frame = FrameOf(window)
    if not frame then return end
    frame:SetParent(UIParent)
    Bare(window, false)
    local strip = rawget(window, "tabStrip")
    if strip then
        strip:ClearAllPoints()
        strip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", PetsTabs.INSET, 0)
    end
    frame:ClearAllPoints()
    PetsTabs.ApplyScale(frame)
    local db = ns.db
    if db and type(db.windowLeft) == "number" and type(db.windowTop) == "number" then
        PetsTabs.PlaceAt(frame, db.windowLeft, db.windowTop)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    end
    -- Fit keeps a size it already has, so ask for it afresh.
    frame:SetWidth(1)
    self:Fit(window)
end

--- Grow the one window until its area holds the size every tab shares.
function PetsTabs:Grow()
    local area = self.area
    local one = area and area:GetParent()
    if not one then return end
    local width, height = self:Size()
    local okW, areaW = pcall(area.GetWidth, area)
    local okH, areaH = pcall(area.GetHeight, area)
    if okW and type(areaW) == "number" and areaW > 0 and areaW < width then
        one:SetWidth(one:GetWidth() + (width - areaW))
    end
    if okH and type(areaH) == "number" and areaH > 0 and areaH < height then
        one:SetHeight(one:GetHeight() + (height - areaH))
    end
end

--- The pages go into the one window: called by it (host.enter).
function PetsTabs:Enter(area)
    if not area then return end
    self.area = area
    for _, tab in ipairs(PetsTabs.Tabs()) do
        local window = Owner(tab.key)
        if FrameOf(window) then self:LayIn(window) end
    end
    self:Grow()
    local key = self.wanted or "pet"
    self.wanted = nil
    self:Open(key)
end

--- The pages go back: called by the one window (host.leave).
function PetsTabs:Leave()
    if not self.area then return end
    self.leaving = true
    for _, tab in ipairs(PetsTabs.Tabs()) do
        local window = Owner(tab.key)
        if Shown(FrameOf(window)) then
            local ok, err = pcall(window.Hide, window)
            if not ok and ns.Debug then ns.Debug("one window leave:", tostring(err)) end
        end
    end
    self.area = nil
    for _, tab in ipairs(PetsTabs.Tabs()) do
        local window = Owner(tab.key)
        if FrameOf(window) then self:LayOut(window) end
    end
    self.leaving = false
end

--- What Pets gives the one window when it joins.
PetsTabs.host = {
    enter = function(area) PetsTabs:Enter(area) end,
    leave = function() PetsTabs:Leave() end,
}

--- A tab is asked to open. With "One Window:" ticked and Pets not in it
--- yet, the one window opens on Pets instead, on that tab. True when it
--- did, so the caller stops there.
function PetsTabs:Route(key)
    if self.area then return false end
    local One = PetsTabs.One()
    if not (One and One.Hosts and One.Hosts("pets")) then return false end
    self.wanted = key
    local ok, opened = pcall(One.Open, "pets")
    if ok and opened then return true end
    self.wanted = nil
    return false
end

--- One of the tabs closed by itself (Escape, its close gem): inside the
--- one window, the one window closes with it.
function PetsTabs:Closed(frame)
    if not self.area or self.leaving or self.switching then return end
    -- A window built for the first time hides itself before it is laid
    -- in, and that is no close: only one inside the area counts.
    if frame and frame.GetParent and frame:GetParent() ~= self.area then return end
    local One = PetsTabs.One()
    if One and One.Close then pcall(One.Close) end
end
