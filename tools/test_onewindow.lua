-- The Pets tabs in the one Blackthornes window (UI/PetsTabs.lua, the owner
-- said build it, 2026-10-30).
--
-- What must hold:
--   1. On unless unticked; unticked, the Pets window opens in its own place.
--   2. Ticked, opening Pets opens the one window on Pets, with the Pet tab
--      laid into its area, bare of its own rim and grip.
--   3. The Compendium and Settings open in the same area; one tab at a time.
--   Swapping addons on the rail keeps the one window up.
--   4. Closing the one window gives the pages back their own place.
--   5. "One Window:" on the General page writes every save.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("onewindow")

_G.BlackthornesWindow = nil
local ns = env.Load()
local UI, Compendium, SettingsUI, Tabs, SW = ns.UI, ns.CompendiumUI, ns.SettingsUI, ns.PetsTabs, ns.SharedWindow

ns.MinimapButton.button = env.Stub()
ns.MinimapButton:JoinShared()
local hub = _G.BlackthornesWindow
suite.check("Pets joins with its pages", hub.entries.pets and hub.entries.pets.host == Tabs.host)
suite.check("the one window is Pets' own copy", Tabs.One() == SW)

-- 1.
ns.db.oneWindow = nil
suite.check("on unless unticked", SW.On())
ns.db.oneWindow = false
UI:Show()
suite.check("off: the Pets window opens by itself", UI.frame:IsShown() and not Tabs:Hosted())
UI:Hide()

-- 2.
SW.SetOn(true)
UI:Show()
local area = hub.frame and hub.frame.area
suite.check("on: the one window opens", hub.frame and hub.frame:IsShown())
suite.check("on Pets", hub.current == hub.entries.pets and ns.db.oneWindowPick == "pets")
suite.check("the Pet tab is in it", Tabs:Hosted() and UI.frame:GetParent() == area and UI.frame:IsShown())
suite.check("without its own rim", UI.trim and not UI.trim:IsShown())
suite.check("or its own size grip", UI.sizeGrip and not UI.sizeGrip:IsShown())

-- 3.
Tabs:Open("compendium")
suite.check("the Compendium is in the same area", Compendium.frame:GetParent() == area and Compendium.frame:IsShown())
suite.check("and the Pet tab stepped aside", not UI.frame:IsShown())
suite.check("the one window stays up", hub.frame:IsShown() and Tabs:Hosted())
Tabs:Open("settings")
suite.check("Settings is in the same area", SettingsUI.frame:GetParent() == area and Tabs:Current() == "settings")

-- Show Descriptions makes the pages taller: the one window grows to hold
-- them. On the client Settings fills the area, so its own size only says
-- how big the area is; the stand-in frame is made to answer the same way.
do
    local frame = SettingsUI.frame
    local getW, getH = frame.GetWidth, frame.GetHeight
    frame.GetWidth = function() return area:GetWidth() end
    frame.GetHeight = function() return area:GetHeight() end
    local before, oneBefore = area:GetHeight(), hub.frame:GetHeight()
    SettingsUI.pages:ShowDescriptions(true)
    local need = SettingsUI.pages.need
    suite.check("descriptions on: the pages say how tall they are", type(need) == "table" and need[2] > before)
    suite.check("Settings says what the pages need", Tabs.needs.settings and Tabs.needs.settings[2] == need[2])
    -- The test's frames don't follow their anchors, so the area keeps its
    -- old height; the one window around it is what grows.
    suite.check("and the one window grows to hold them",
        hub.frame:GetHeight() - oneBefore >= need[2] - before)
    SettingsUI.pages:ShowDescriptions(false)
    frame.GetWidth, frame.GetHeight = getW, getH
end

-- A window built for the first time hides itself before it is laid in
-- (a player's report, 2026-10-30: picking another addon on the rail once
-- turned the one window into that addon's own window).
local fresh = { GetParent = function() return UIParent end }
Tabs:Closed(fresh)
suite.check("a window not yet laid in hiding keeps the one window", hub.frame:IsShown() and Tabs:Hosted())

-- Swapping to another addon on the rail hands Pets' pages back without
-- closing the one window, so Pets never falls back to its own window.
local entered, left = 0, 0
SW:Join({ key = "farmer", order = 1, name = "Farmer", db = function() return {} end,
    host = { enter = function() entered = entered + 1 end, leave = function() left = left + 1 end } })
SW.Pick("farmer")
suite.check("swapping keeps the one window up", hub.frame:IsShown() and hub.current == hub.entries.farmer)
suite.check("the other addon moved in", entered == 1)
suite.check("Pets' pages went home, hidden", not Tabs:Hosted() and SettingsUI.frame:GetParent() == UIParent
    and not SettingsUI.frame:IsShown() and not UI.frame:IsShown())
SW.Pick("pets")
suite.check("back on Pets in the same window", hub.frame:IsShown() and hub.current == hub.entries.pets
    and Tabs:Hosted() and left == 1)
suite.check("a Pets tab is in the area", (UI.frame:GetParent() == hub.frame.area and UI.frame:IsShown())
    or (SettingsUI.frame:GetParent() == hub.frame.area and SettingsUI.frame:IsShown()))
hub.entries.farmer = nil

-- 4.
ns.db.windowLeft, ns.db.windowTop = 300, 650
hub.frame:Hide()
local onHide = hub.frame:GetScript("OnHide")
if onHide then onHide(hub.frame) end
suite.check("closing it lets Pets go", not Tabs:Hosted() and hub.current == nil)
suite.check("the pages are back on their own", UI.frame:GetParent() == UIParent
    and Compendium.frame:GetParent() == UIParent and SettingsUI.frame:GetParent() == UIParent)
suite.check("hidden", not UI.frame:IsShown() and not SettingsUI.frame:IsShown())
suite.check("with their rim", UI.trim:IsShown() and UI.sizeGrip:IsShown())

-- 5.
local other = {}
SW:Join({ key = "butler", order = 2, name = "Butler", db = function() return other end })
SettingsUI:Show()
suite.check("Settings opens in the one window", Tabs:Hosted() and SettingsUI.frame:GetParent() == hub.frame.area)
SettingsUI:SetOneWindow(false)
local onHideAgain = hub.frame:GetScript("OnHide")
if onHideAgain then onHideAgain(hub.frame) end
suite.check("unticked in every save", ns.db.oneWindow == false and other.oneWindow == false)
SettingsUI:Show()
suite.check("Settings opens on its own again", not Tabs:Hosted() and SettingsUI.frame:GetParent() == UIParent
    and SettingsUI.frame:IsShown())
SettingsUI:SetOneWindow(true)
suite.check("ticked again in every save", ns.db.oneWindow == true and other.oneWindow == true)
suite.check("and Settings moves into the one window", Tabs:Hosted() and SettingsUI.frame:GetParent() == hub.frame.area)

_G.BlackthornesWindow = nil
suite.done()
