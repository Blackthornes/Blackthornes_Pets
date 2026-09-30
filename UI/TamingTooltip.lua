-- Blackthornes Pets -- UI/TamingTooltip.lua
-- On a tameable beast's tooltip, for a hunter: the pet skills taming it would
-- teach, green when the hunter already knows the skill and red when not.
--
-- Hooked the way Equipment's UI/Tooltip.lua and Tradeskills' item tooltip
-- are. Their measurement on Forever is that retail's TooltipDataProcessor is
-- what fires; the older OnTooltipSetUnit script is installed too, in case, and
-- a guard stops the lines going on twice. Blizzard's tooltip is added to,
-- never replaced.

local _, ns = ...

local TamingTooltip = ns.NewModule("TamingTooltip")

local Taming = ns.Taming

local ICON = "|TInterface\\Icons\\Ability_Hunter_BeastTaming:14:14:0:0:64:64:5:59:5:59|t"

local function Field(object, key)
    if type(object) ~= "table" then return nil end
    local ok, value = pcall(function() return object[key] end)
    if ok then return value end
    return nil
end

local function Colored(colorKey, text)
    return ("|c%s%s|r"):format(ns.COLORS[colorKey] or ns.COLORS.text, text)
end

function TamingTooltip:IsEnabled()
    return not (ns.db and ns.db.tamingTooltip == false)
end

local function IsHunter()
    if type(UnitClass) ~= "function" then return false end
    local ok, _, class = pcall(UnitClass, "player")
    return ok and ns.PetStatus.Plain(class) == "HUNTER"
end

--- The GUID of the unit a tooltip shows, however this client offers it.
function TamingTooltip:GuidFor(tooltip, data)
    local guid = ns.PetStatus.Plain(Field(data, "guid"))
    if type(guid) == "string" then return guid end

    local getUnit = Field(tooltip, "GetUnit")
    local unit
    if type(getUnit) == "function" then
        local ok, _, shown = pcall(getUnit, tooltip)
        if ok then unit = ns.PetStatus.Plain(shown) end
    end
    unit = unit or "mouseover"
    if type(UnitGUID) ~= "function" then return nil end
    local ok, value = pcall(UnitGUID, unit)
    if not ok then return nil end
    return ns.PetStatus.Plain(value)
end

--- The lines for a creature: a heading, then one line a skill with whether
--- it is known on the right. Nil when the creature teaches nothing.
function TamingTooltip:Lines(npcID)
    local skills = Taming:SkillsFor(npcID)
    if #skills == 0 then return nil end

    local lines = { { left = ICON .. " " .. Colored("accent", "Taming teaches") } }
    local unsure = false
    for _, skill in ipairs(skills) do
        local known = Taming:Knows(skill)
        local line = { left = "   " .. Taming.Label(skill) }
        if known == true then
            line.color, line.right = "good", "Known"
        elseif known == false then
            line.color, line.right = "bad", "Not known"
        else
            line.color, unsure = "text", true
        end
        line.left = Colored(line.color, line.left)
        if line.right then line.right = Colored(line.color, line.right) end
        lines[#lines + 1] = line
    end
    if unsure then
        lines[#lines + 1] = { left = Colored("muted", "   Open Beast Training once to see which you know") }
    end
    return lines
end

-- Which tooltip already carries the lines, for which unit and at what length.
-- Cleared when the tooltip is, so the next showing gets them again.
local decorated = setmetatable({}, { __mode = "k" })

function TamingTooltip.Forget(tooltip)
    decorated[tooltip] = nil
end

local function LineCount(tooltip)
    local numLines = Field(tooltip, "NumLines")
    if type(numLines) ~= "function" then return nil end
    local ok, count = pcall(numLines, tooltip)
    if ok and type(count) == "number" then return count end
    return nil
end

--- Put the lines on a tooltip.
-- @return "added", "quiet" (nothing to say), "duplicate" or "nounit"
function TamingTooltip:Decorate(tooltip, data)
    if not self:IsEnabled() then return "quiet" end
    if tooltip ~= _G.GameTooltip then return "quiet" end
    if self.writing then return "duplicate" end
    if not IsHunter() then return "quiet" end

    local guid = self:GuidFor(tooltip, data)
    local npcID = Taming:NpcID(guid)
    if not npcID then return "nounit" end

    local mark = decorated[tooltip]
    if mark and mark.guid == guid then
        local now = LineCount(tooltip)
        if not now or now >= mark.lines then return "duplicate" end
    end

    local lines = self:Lines(npcID)
    if not lines then return "quiet" end

    local addLine = Field(tooltip, "AddLine")
    local addDouble = Field(tooltip, "AddDoubleLine")
    if type(addLine) ~= "function" then return "nounit" end

    self.writing = true
    for _, line in ipairs(lines) do
        if line.right and type(addDouble) == "function" then
            pcall(addDouble, tooltip, line.left, line.right)
        elseif line.right then
            pcall(addLine, tooltip, line.left .. "  " .. line.right)
        else
            pcall(addLine, tooltip, line.left)
        end
    end

    -- Adding lines needs the tooltip resized, which Show does; on a client
    -- where that re-enters the hook, `writing` is what stops it.
    local show = Field(tooltip, "Show")
    if type(show) == "function" then pcall(show, tooltip) end
    self.writing = false

    decorated[tooltip] = { guid = guid, lines = LineCount(tooltip) or 0 }
    return "added"
end

--- Every hook comes through here, so one odd unit costs its lines and never
--- a Lua error on hover.
function TamingTooltip:OnTooltip(tooltip, data, source)
    local ok, outcome = pcall(self.Decorate, self, tooltip, data)
    if not ok then
        self.writing = false
        return "nounit"
    end
    if outcome == "added" then
        self.fired[source] = (self.fired[source] or 0) + 1
    end
    return outcome
end

function TamingTooltip:InstallDataProcessor()
    local processor = _G.TooltipDataProcessor
    local dataType = Field(Field(_G.Enum, "TooltipDataType"), "Unit")
    local add = Field(processor, "AddTooltipPostCall")
    if type(add) ~= "function" or dataType == nil then return false end

    return (pcall(add, dataType, function(tooltip, data)
        TamingTooltip:OnTooltip(tooltip, data, "TooltipDataProcessor")
    end))
end

function TamingTooltip:InstallScriptHooks()
    local tooltip = _G.GameTooltip
    local hook = Field(tooltip, "HookScript")
    if type(hook) ~= "function" then return false end
    local installed = pcall(hook, tooltip, "OnTooltipSetUnit", function(shown)
        TamingTooltip:OnTooltip(shown, nil, "OnTooltipSetUnit")
    end)
    pcall(hook, tooltip, "OnTooltipCleared", function(shown)
        TamingTooltip.Forget(shown)
    end)
    return installed
end

function TamingTooltip:OnEnable()
    self.fired = {}
    self.installed = {
        TooltipDataProcessor = self:InstallDataProcessor(),
        OnTooltipSetUnit = self:InstallScriptHooks(),
    }
end
