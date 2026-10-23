-- One Pets window with its tabs hanging below: Pet, Compendium and Settings.
-- Only one shows at a time, each opens where the last stood, the minimap
-- button opens and closes it, and the place is kept.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("petstabs")

local ns = env.Load()
local Tabs = ns.PetsTabs

suite.check("three tabs, Pet first", #Tabs.Tabs() == 3 and Tabs.Tabs()[1].key == "pet"
    and Tabs.Tabs()[3].key == "settings")

ns.UI:Show()
suite.check("the Pet tab shows", Tabs:Current() == "pet")
suite.check("with the tabs hanging under it", ns.UI.tabStrip ~= nil)

ns.CompendiumUI:Show()
suite.check("the Compendium takes its place", Tabs:Current() == "compendium"
    and not ns.UI.frame:IsShown())
suite.check("and wears the tabs too", ns.CompendiumUI.tabStrip ~= nil)

Tabs:Open("settings")
suite.check("Settings is a tab too", Tabs:Current() == "settings"
    and not ns.CompendiumUI.frame:IsShown() and ns.SettingsUI.tabStrip ~= nil)

-- One place for all three, top left corner on top left corner.
local spot = { left = 300, top = 700 }
local frame = ns.SettingsUI.frame
frame.GetLeft = function() return spot.left end
frame.GetTop = function() return spot.top end
frame.GetScale = function() return 1 end
Tabs:Open("pet")
suite.check("a new tab opens where the last stood",
    ns.db.windowLeft == 300 and ns.db.windowTop == 700)
local point = { ns.UI.frame:GetPoint(1) }
suite.check("by its top left corner", point[1] == "TOPLEFT" and point[4] == 300 and point[5] == 700,
    tostring(point[1]))

-- The minimap button's click opens the Pet tab or closes the window.
Tabs:Toggle()
suite.check("the minimap click closes it", Tabs:Current() == nil)
Tabs:Toggle()
suite.check("and opens the Pet tab", Tabs:Current() == "pet")
suite.check("at the place kept", ({ ns.UI.frame:GetPoint(1) })[4] == 300)
Tabs:Close()
suite.check("Close shuts whichever tab is up", Tabs:Current() == nil)

-- The plate reads the same on every tab.
ns.CompendiumUI:Show()
suite.check("the Compendium's plate names the addon",
    ns.CompendiumUI.frame.titan.plate.label:GetText() == "Blackthornes Pets")
Tabs:Close()

-- A tab picked again lights itself on its own strip at once, though that
-- strip was last lit for another tab.
ns.UI.tabStrip:Select("settings")
Tabs:Open("pet")
suite.check("the tab opened is the one lit", ns.UI.tabStrip.selected == "pet",
    tostring(ns.UI.tabStrip.selected))
Tabs:Close()

suite.done()
