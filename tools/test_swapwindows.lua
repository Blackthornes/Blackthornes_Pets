-- The swap gem on the Pets windows and the one window (UI/SharedWindow.lua
-- AddSwap and Swap, PetsTabs' tab, show and hide; the owner said build it,
-- 2026-11-19).
--
-- What must hold:
--   1. The Pet, Compendium and Settings windows carry a join gem; the one
--      window a split gem.
--   2. Split from the one window on the Compendium: the one window closes
--      and the Compendium opens on its own; the One Window box reads
--      unticked.
--   3. Join from the own Settings window: the one window opens on Pets,
--      still on Settings, and the box reads ticked.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("swapwindows")

_G.BlackthornesWindow = nil
local ns = env.Load()
local UI, Compendium, SettingsUI, Tabs, SW = ns.UI, ns.CompendiumUI, ns.SettingsUI, ns.PetsTabs, ns.SharedWindow

ns.MinimapButton.button = env.Stub()
ns.MinimapButton:JoinShared()
local hub = _G.BlackthornesWindow

-- The game runs a frame's OnHide as it hides; the fake game does not.
local function HidesLikeTheGame(frame)
    local hide = frame.Hide
    frame.Hide = function(self)
        local was = self:IsShown()
        hide(self)
        local onHide = was and self:GetScript("OnHide")
        if onHide then onHide(self) end
    end
end

local function Gem(frame) return frame and rawget(frame, "blackthornesSwap") end

-- 1.
SW.SetOn(true)
Tabs:Open("compendium")
HidesLikeTheGame(hub.frame)
local oneGem = Gem(hub.frame)
suite.check("the one window has the split gem", oneGem and rawget(oneGem, "join") == false)
UI:Build()
SettingsUI:Build()
for _, window in ipairs({ UI, Compendium, SettingsUI }) do
    local gem = Gem(window.frame)
    suite.check("each tab's window has the join gem", gem and rawget(gem, "join") == true
        and rawget(gem, "swapKey") == "pets")
end
suite.check("on the Compendium in the one window", Tabs:Hosted() and Tabs:Current() == "compendium")

-- 2.
oneGem:GetScript("OnClick")(oneGem)
suite.check("split: the choice is off", not SW.On() and ns.db.oneWindow == false)
suite.check("the one window closed", not hub.frame:IsShown())
suite.check("the Compendium opens on its own", not Tabs:Hosted() and Compendium.frame:IsShown()
    and Compendium.frame:GetParent() == UIParent)
Tabs:Open("settings")
SettingsUI:Refresh()
suite.check("the One Window box reads unticked", SettingsUI.controls.oneWindow:GetChecked() == false)

-- 3.
suite.check("Settings is up on its own", Tabs:Current() == "settings" and SettingsUI.frame:GetParent() == UIParent)
local settingsGem = Gem(SettingsUI.frame)
settingsGem:GetScript("OnClick")(settingsGem)
suite.check("join: the choice is on", SW.On() and ns.db.oneWindow == true)
suite.check("the one window opens on Pets", hub.frame:IsShown() and hub.current == hub.entries.pets)
suite.check("still on Settings, inside it", Tabs:Hosted() and Tabs:Current() == "settings"
    and SettingsUI.frame:GetParent() == hub.frame.area)
SettingsUI:Refresh()
suite.check("the One Window box reads ticked", SettingsUI.controls.oneWindow:GetChecked() == true)

SW.SetOn(false)
_G.BlackthornesWindow = nil
suite.done()
