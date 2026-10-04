-- The settings window.
--
-- What matters is that every way in opens it, that each control changes the
-- same saved value its chat command does, and that the page shows what is
-- saved rather than what it last drew.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("settings")

local ns = env.Load()
_G.UnitClass = function() return "Hunter", "HUNTER" end

local SettingsUI = ns.SettingsUI

-- A client with retail's Settings API, recording what is registered.
local registered = {}
_G.Settings = {
    RegisterCanvasLayoutCategory = function(panel, name) return { panel = panel, name = name } end,
    RegisterAddOnCategory = function(category) registered[#registered + 1] = category end,
}

for _, module in ipairs(ns.moduleOrder) do
    if module.OnEnable then module:OnEnable() end
end

suite.check("it is listed under the game's AddOns options",
    registered[1] and registered[1].name == "Blackthornes Pets")

-- Ways in.
ns.HandleSlash("settings")
suite.check("/bpet settings opens it", SettingsUI.frame:IsShown())
ns.HandleSlash("settings")
suite.check("and closes it", not SettingsUI.frame:IsShown())
ns.HandleSlash("options")
suite.check("/bpet options works too", SettingsUI.frame:IsShown())
suite.check("options is not listed twice in help",
    not (function()
        for _, name in ipairs(ns.commandOrder) do
            if name == "options" or name == "config" then return true end
        end
    end)())

-- The house frame: the plate and close gem, without the portrait.
local trim = SettingsUI.frame.titan
suite.check("settings wears the house frame", trim ~= nil)
suite.check("with the name on the plate", trim and trim.plate.label:GetText() == "Blackthornes Pets")
-- A stub answers any field it lacks with a function, so "no portrait"
-- means no portrait frame.
suite.check("and no portrait", trim and type(trim.portrait) ~= "table")
trim.closeButton:GetScript("OnClick")(trim.closeButton)
suite.check("the close gem closes it", not SettingsUI.frame:IsShown())
SettingsUI:Show()

local controls = SettingsUI.controls

-- The minimap checkbox.
local minimapBox = controls.minimap
suite.check("the minimap box starts ticked", minimapBox:GetChecked())
minimapBox:GetScript("OnClick")(minimapBox)
suite.check("unticking hides the button",
    ns.db.minimapHidden == true and not ns.MinimapButton.button:IsShown())
ns.HandleSlash("minimap")
suite.check("/bpet minimap ticks it again", minimapBox:GetChecked())

-- Debug.
controls.debug:GetScript("OnClick")(controls.debug)
suite.check("the debug box sets debug", ns.db.debug == true)

-- Position.
ns.db.settingsX = 400
SettingsUI:ResetPositions()
suite.check("putting it back forgets where it was dragged", ns.db.settingsX == nil)

-- A client with neither options API still loads.
local ns2 = env.Load()
_G.UnitClass = function() return "Hunter", "HUNTER" end
suite.check("no options API is not an error", ns2.SettingsUI:RegisterGameOptions() == false)

suite.done()
