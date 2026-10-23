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

-- Opened another way (the minimap's right-click, Settings' Open button),
-- a window still lights its own tab, not the one picked last on it.
ns.SettingsUI.tabStrip:Select("pet")
ns.SettingsUI:Show()
suite.check("Settings opened on its own lights Settings", ns.SettingsUI.tabStrip.selected == "settings",
    tostring(ns.SettingsUI.tabStrip.selected))
ns.CompendiumUI:Show()
suite.check("and so does the Compendium", ns.CompendiumUI.tabStrip.selected == "compendium",
    tostring(ns.CompendiumUI.tabStrip.selected))
Tabs:Close()

-- One size for every tab, so the window never jumps as they are clicked.
local function SizeOf(window) return window.frame:GetWidth(), window.frame:GetHeight() end
local sizes = {}
for _, key in ipairs({ "pet", "compendium", "settings" }) do
    Tabs:Open(key)
    sizes[key] = { SizeOf(Tabs.Owner(key)) }
end
local width, height = Tabs:Size()
local same = true
for _, size in pairs(sizes) do
    if size[1] ~= width or size[2] ~= height then same = false end
end
local said = ""
for key, size in pairs(sizes) do said = said .. (" %s %s x %s"):format(key, tostring(size[1]), tostring(size[2])) end
suite.check("every tab is the same size", same, ("%d x %d"):format(width, height) .. said)
suite.check("at least the Compendium's", width >= Tabs.WIDTH and height >= Tabs.HEIGHT)

-- A tab that needs more room makes every tab grow, and the Compendium's
-- list fills it with more rows.
local rowsBefore = #ns.CompendiumUI.rows
Tabs:Need("pet", nil, height + 3 * 34)
suite.check("a taller Pet tab makes every tab taller",
    ns.CompendiumUI.frame:GetHeight() == height + 3 * 34 and ns.SettingsUI.frame:GetHeight() == height + 3 * 34)
suite.check("and the Compendium shows more rows", #ns.CompendiumUI.rows == rowsBefore + 3,
    tostring(#ns.CompendiumUI.rows))
Tabs:Need("pet", nil, nil)
suite.check("and they come back down with it", ns.CompendiumUI.frame:GetHeight() == height
    and #ns.CompendiumUI.rows == rowsBefore)

-- One size grip: what it sets, every tab opens at.
ns.db.windowScale = 120
Tabs:Open("compendium")
suite.check("one scale for every tab", math.abs(ns.CompendiumUI.frame:GetScale() - 1.2) < 0.001,
    tostring(ns.CompendiumUI.frame:GetScale()))
ns.db.windowScale = nil
Tabs:Close()

suite.done()
