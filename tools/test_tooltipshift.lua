-- Off, Shift or Always for the taming skills on a beast's tooltip
-- (UI/TooltipShift.lua, UI/TamingTooltip.lua).
--
-- What matters: nobody's settings change (on reads as Always, off as Off,
-- and nothing is written for a player who never picks), Shift holds the
-- lines back until Shift is down, the hint goes on once, and the Settings
-- stepper writes the same values.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("tooltipshift")

local ns = env.Load()
local Shift, Tip = ns.TooltipShift, ns.TamingTooltip

local function Tooltip()
    local tip = env.Stub({ _lines = {} })
    tip.AddLine = function(self, text) self._lines[#self._lines + 1] = text end
    tip.AddDoubleLine = function(self, left, right) self._lines[#self._lines + 1] = left .. " || " .. right end
    tip.NumLines = function(self) return #self._lines end
    -- The game's own clear, which runs OnTooltipCleared.
    tip.ClearLines = function(self)
        self._lines = {}
        local cleared = self:GetScript("OnTooltipCleared")
        if cleared then cleared(self) end
    end
    return tip
end

local tip = Tooltip()
_G.GameTooltip = tip
_G.UnitClass = function() return "Hunter", "HUNTER" end
for _, module in ipairs(ns.moduleOrder) do
    if module.OnEnable then module:OnEnable() end
end

local shiftDown = false
_G.IsShiftKeyDown = function() return shiftDown end

local HINT = "Hold Shift for more."
local function Count(text)
    local n = 0
    for _, line in ipairs(tip._lines) do
        if line == text then n = n + 1 end
    end
    return n
end
local function Has(text)
    for _, line in ipairs(tip._lines) do
        if tostring(line):find(text, 1, true) then return true end
    end
    return false
end
local function Hover()
    tip:ClearLines()
    return Tip:OnTooltip(tip, { guid = "Creature-0-1-2-3-3099-0000000001" }, "test")
end

local KEY = Tip.SHIFT_KEY
suite.check("the line's key is listed", Shift.KEYS[1] == KEY)

-- Nobody's settings change.
suite.check("a line that is on reads as Always", Shift:Mode(ns.db.tamingTooltip ~= false, KEY) == Shift.ALWAYS)
suite.check("a line that is off reads as Off", Shift:Mode(false, KEY) == Shift.OFF)
suite.check("nothing is written for a player who never picks", ns.db.tooltipShift == nil)
suite.check("Always shows the lines as before", Hover() == "added" and Has("Taming teaches") and Count(HINT) == 0)

-- The Settings stepper.
local SettingsUI = ns.SettingsUI
SettingsUI:Show()
local stepper = SettingsUI.controls.tamingTooltip
suite.check("the row is a stepper showing Always", stepper.GetValue and stepper:GetValue() == Shift.ALWAYS
    and stepper.text:GetText() == "Always", stepper.text and stepper.text:GetText())
stepper.minus:GetScript("OnClick")(stepper.minus)
suite.check("one step down is Shift, and it is kept", ns.db.tooltipShift and ns.db.tooltipShift[KEY] == true
    and ns.db.tamingTooltip == true and stepper.text:GetText() == "Shift")

-- Shift up: the lines wait, the hint goes on once.
shiftDown = false
suite.check("with Shift up the lines are held back", Hover() == "held" and not Has("Taming teaches"))
suite.check("and the hint goes on", Count(HINT) == 1)
-- Both hooks fire on Forever; the hint still goes on once.
Tip:OnTooltip(tip, { guid = "Creature-0-1-2-3-3099-0000000001" }, "OnTooltipSetUnit")
suite.check("only once, however many hooks ask", Count(HINT) == 1)

-- Shift down: the shared frame redraws the tooltip, which clears and builds it again.
shiftDown = true
local refreshed = 0
tip.RefreshData = function(self)
    refreshed = refreshed + 1
    Hover()
end
tip:Show()
Shift.shared.OnModifier("LSHIFT")
suite.check("Shift down redraws the tooltip", refreshed == 1)
suite.check("and the lines come back after the redraw", Has("Taming teaches") and Count(HINT) == 0)
Shift.shared.OnModifier("LCTRL")
suite.check("another key redraws nothing", refreshed == 1)

-- Off and back to Always.
stepper.minus:GetScript("OnClick")(stepper.minus)
suite.check("Off turns the line's own setting off", ns.db.tamingTooltip == false and stepper.text:GetText() == "Off")
suite.check("and nothing shows", Hover() == "quiet" and #tip._lines == 0)
stepper.plus:GetScript("OnClick")(stepper.plus)
stepper.plus:GetScript("OnClick")(stepper.plus)
suite.check("Always turns it on again", ns.db.tamingTooltip == true and stepper:GetValue() == Shift.ALWAYS)
suite.check("and Shift is no longer kept", ns.db.tooltipShift[KEY] == nil)
shiftDown = false
suite.check("Always shows the lines with Shift up", Hover() == "added" and Has("Taming teaches"))
refreshed = 0
Shift.shared.OnModifier("LSHIFT")
suite.check("with nothing on Shift, Shift redraws nothing", refreshed == 0)

-- The settings page shows what is saved.
ns.db.tooltipShift = { [KEY] = true }
SettingsUI:Refresh()
suite.check("Refresh shows Shift from the save", stepper:GetValue() == Shift.SHIFT and ns.db.tamingTooltip == true)
ns.db.tamingTooltip = false
SettingsUI:Refresh()
suite.check("and Off when the line is off", stepper:GetValue() == Shift.OFF
    and ns.db.tooltipShift[KEY] == true)

suite.done()
