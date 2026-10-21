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

suite.check("there is no minimap row", controls.minimap == nil)

-- Effects: Full until picked, so nobody's windows change.
suite.check("effects start at Full", ns.Motion.Level() == "full" and controls.effects.text:GetText() == "Full",
    controls.effects.text:GetText())
controls.effects:SetValue(2)
suite.check("Subtle is kept", ns.db.effectsLevel == "subtle" and ns.Motion.Level() == "subtle")
controls.effects:SetValue(3)
suite.check("Off is kept", ns.db.effectsLevel == "off" and ns.Motion.Level() == "off")
controls.effects:SetValue(1)
suite.check("Full saves nothing", ns.db.effectsLevel == nil and ns.Motion.Level() == "full")

-- Debug.
controls.debug:GetScript("OnClick")(controls.debug)
suite.check("the debug box sets debug", ns.db.debug == true)

-- The sister note (Core/SisterNote.lua).
suite.check("the sister addons box starts ticked", controls.sisters:GetChecked())
controls.sisters:GetScript("OnClick")(controls.sisters)
suite.check("unticking it turns the note off", ns.db.sisterNote == false)
ns.HandleSlash("sisters")
suite.check("/bpet sisters turns it back on", ns.db.sisterNote == true and controls.sisters:GetChecked())

-- The pages along the top, as Tradeskills' Settings tab has them.
local pages = SettingsUI.pages
suite.check("it opens on the first page", pages.shown == "pet")
suite.check("with the feeding rows showing", pages.pages.pet.content:IsShown()
    and not pages.pages.general.content:IsShown())
local generalPart
for _, part in ipairs(pages.switch) do
    if part.key == "general" then generalPart = part end
end
generalPart.button:GetScript("OnClick")(generalPart.button)
suite.check("a click on the switch shows that page", pages.pages.general.content:IsShown()
    and not pages.pages.pet.content:IsShown())
suite.check("and the page is remembered", ns.db.settingsPage == "general")
suite.check("the page picked is gold", generalPart.label._color[1] == ns.Theme.colors.accent[1])
SettingsUI:Hide()
SettingsUI:Show()
suite.check("it opens again on the page left", pages.shown == "general")

-- What a setting does is a tooltip until Show descriptions is ticked.
local feedRow
for _, row in ipairs(pages.pages.pet.rows) do
    if row.labelText == "Feed Warning:" then feedRow = row end
end
suite.check("descriptions start hidden", ns.db.settingsDescriptions == false
    and not feedRow.hint:IsShown())
GameTooltip._lines = {}
feedRow:GetScript("OnEnter")(feedRow)
suite.check("a row lights under the mouse", feedRow.hover:IsShown())
suite.check("and says what it does in a tooltip", GameTooltip._lines[1] and
    GameTooltip._lines[1]:find("isn't happy") ~= nil)
local before = SettingsUI.frame:GetHeight()
pages.describe:GetScript("OnClick")(pages.describe)
suite.check("Show descriptions is saved", ns.db.settingsDescriptions == true)
suite.check("and puts the words under the rows", feedRow.hint:IsShown())
-- The window fits its fullest page, which may already have room for them.
suite.check("and the row grows to fit them", feedRow:GetHeight() > feedRow.compactHeight
    and SettingsUI.frame:GetHeight() >= before)
pages.describe:GetScript("OnClick")(pages.describe)
suite.check("unticked, the window goes back", SettingsUI.frame:GetHeight() == before)

-- Find a setting.
pages.find:SetText("tomtom")
pages:Search("tomtom")
suite.check("the search shows the page that has it", pages.shown == "compendium")
local lit = 0
for _, entry in ipairs(pages.searchables) do
    if entry.glow:IsShown() then lit = lit + 1 end
end
suite.check("and lights only what matches", lit == 1)
pages:Search("")
lit = 0
for _, entry in ipairs(pages.searchables) do
    if entry.glow:IsShown() then lit = lit + 1 end
end
suite.check("an empty search lights nothing", lit == 0)

-- Text size, saved as a word, waits for a reload.
controls.textSize.plus:GetScript("OnClick")(controls.textSize.plus)
suite.check("Text size saves Large", ns.db.textSize == "large")
suite.check("and offers Reload", controls.textSize.reload:IsShown())
suite.check("under the stepper, at its right edge", controls.textSize.reload._point[1] == "TOPRIGHT"
    and controls.textSize.reload._point[2] == controls.textSize
    and controls.textSize.reload._point[3] == "BOTTOMRIGHT")
suite.check("the Window style's Reload sits the same way", controls.windowStyle.reload._point[1] == "TOPRIGHT"
    and controls.windowStyle.reload._point[2] == controls.windowStyle
    and controls.windowStyle.reload._point[3] == "BOTTOMRIGHT")
do
    local width = controls.windowStyle:GetWidth()
    local word = ns.Theme.TextWidth("small", "Titanforged")
    suite.check("the style's box holds Titanforged", width - 22 * 2 - 4 * 2 >= word, width)
end
controls.textSize.minus:GetScript("OnClick")(controls.textSize.minus)
suite.check("back to Normal needs no reload", ns.db.textSize == "normal"
    and not controls.textSize.reload:IsShown())

-- Every /bpet command has a button here.
local ran = {}
local realSlash = ns.HandleSlash
ns.HandleSlash = function(text) ran[#ran + 1] = text end
for _, key in ipairs({ "openWindow", "probe", "beastArrowCheck" }) do
    controls[key]:GetScript("OnClick")(controls[key])
end
ns.HandleSlash = realSlash
suite.check("the command buttons run their commands",
    table.concat(ran, ",") == "window,probe,arrow check")

-- Chat-only commands are typed only (the owner, 2026-10-15): the ones
-- that just list things in chat have no button here, but still work.
for _, key in ipairs({ "food", "taming", "tamed", "help" }) do
    suite.check("no button for /bpet " .. key, controls[key] == nil)
    suite.check("and /bpet " .. key .. " is still a command", ns.commands[key] ~= nil)
end

-- A row with nothing to say has no tooltip, and nothing under it.
local compendiumRow
for _, row in ipairs(pages.pages.compendium.rows) do
    if row.labelText == "Pet Compendium:" then compendiumRow = row end
end
GameTooltip._lines = {}
compendiumRow:GetScript("OnEnter")(compendiumRow)
suite.check("an empty row shows no tooltip", #GameTooltip._lines == 0)
pages.describe:GetScript("OnClick")(pages.describe)
suite.check("and nothing under it with descriptions on", compendiumRow.description == ""
    and compendiumRow.fullHeight == compendiumRow.compactHeight)
pages.describe:GetScript("OnClick")(pages.describe)

-- Feed warning and Only when unhappy share one row.
suite.check("the two feed ticks share a row",
    controls.feedWarnOnlyUnhappy:GetParent() == controls.feedWarning:GetParent())

-- Window position says so in chat.
local printed = {}
local realPrint = ns.Print
ns.Print = function(...) printed[#printed + 1] = table.concat({ ... }, " ") end
controls.resetPositions:GetScript("OnClick")(controls.resetPositions)
ns.Print = realPrint
suite.check("Set Default says so in chat", printed[1] == "UI windows set to defaults.", printed[1])

-- Position.
ns.db.settingsX = 400
SettingsUI:ResetPositions()
suite.check("putting it back forgets where it was dragged", ns.db.settingsX == nil)

-- A client with neither options API still loads.
local ns2 = env.Load()
_G.UnitClass = function() return "Hunter", "HUNTER" end
suite.check("no options API is not an error", ns2.SettingsUI:RegisterGameOptions() == false)

suite.done()
