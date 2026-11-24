-- The Compendium's rows: each beast wears its family's icon, and each skill
-- it teaches is a small tag with the skill's icon, gold when it is new to the
-- hunter and grey when they have it.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("compendiumrows")

local ns = env.Load()
local UI = ns.CompendiumUI

_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.C_Spell = _G.C_Spell or {}
local realTexture = _G.C_Spell.GetSpellTexture
_G.C_Spell.GetSpellTexture = function(spell) return 100000 + spell end

-- Where the client can say it lacks a file, that family wears Beast Taming's.
_G.GetFileIDFromPath = function(path)
    if path:find("CoreHound", 1, true) then return nil end
    return 132
end
suite.check("a family whose icon the client lacks wears Beast Taming's",
    UI.FamilyIcon("Core Hound") == [[Interface\Icons\Ability_Hunter_BeastTaming]], UI.FamilyIcon("Core Hound"))
suite.check("one it has wears its own", UI.FamilyIcon("Bear") == [[Interface\Icons\Ability_Hunter_Pet_Bear]])
_G.GetFileIDFromPath = function() error("secret value") end
suite.check("a call that raises keeps the family's own icon",
    UI.FamilyIcon("Bat") == [[Interface\Icons\Ability_Hunter_Pet_Bat]])
_G.GetFileIDFromPath = nil

suite.check("a wolf wears the wolf icon",
    UI.FamilyIcon("Wolf") == [[Interface\Icons\Ability_Hunter_Pet_Wolf]], UI.FamilyIcon("Wolf"))
suite.check("a carrion bird the vulture's",
    UI.FamilyIcon("Carrion Bird") == [[Interface\Icons\Ability_Hunter_Pet_Vulture]])
suite.check("a family with no icon of its own wears Beast Taming's",
    UI.FamilyIcon("Fox") == [[Interface\Icons\Ability_Hunter_BeastTaming]]
        and UI.FamilyIcon(nil) == [[Interface\Icons\Ability_Hunter_BeastTaming]])
for _, family in pairs(ns.CompendiumData.FAMILIES) do
    local icon = UI.FamilyIcon(family[1])
    suite.check(family[1] .. " has an icon", type(icon) == "string" and icon:find("^Interface\\Icons\\%w"), icon)
end

-- What the hunter knows: Bite 1 only.
local realKnows = ns.Taming.Knows
ns.Taming.Knows = function(_, skill)
    if skill.name == "Bite" then return skill.rank <= 1 end
    if skill.name == "Mystery" then return nil end
    return false
end

UI:Show()
local row = UI.rows[1]
suite.check("the first row is filled", row:IsShown() and rawget(row, "entry") ~= nil)
suite.check("with its family's icon", row.familyIcon._texture == UI.FamilyIcon(row.entry.family), row.familyIcon._texture)
suite.check("the name starts past the icon", row.name._point[4] == 10 + 22 + 8, row.name._point[4])

-- A row of our own, to lay tags on.
local function Lay(skills)
    local fits = UI:LayTags(row, skills)
    return fits, rawget(row, "tags")
end

local fits, tags = Lay({ { name = "Bite", rank = 1 }, { name = "Dash", rank = 2 } })
suite.check("two skills fit", fits == true)
suite.check("each is a tag with its name and rank",
    tags[1]:IsShown() and tags[1].label:GetText() == "Bite 1" and tags[2].label:GetText() == "Dash 2")
suite.check("a skill the hunter has is grey", tags[1].colorKey == "muted", tags[1].colorKey)
suite.check("a skill new to the hunter is gold", tags[2].colorKey == "accentHi", tags[2].colorKey)
suite.check("each tag has the skill's icon", tags[1].icon:IsShown() and type(tags[1].icon._texture) == "number")
suite.check("the second tag sits right of the first, on one line",
    tags[2]._point[5] == tags[1]._point[5] and tags[2]._point[4] == tags[1]._point[4] + tags[1]._width + 4,
    tags[2]._point[4])
suite.check("one line of tags sits in the middle of the row", tags[1]._point[5] == -math.floor((34 - 15) / 2),
    tags[1]._point[5])

fits, tags = Lay({ { name = "Mystery", rank = 1 } })
suite.check("a skill nothing can say about is plain", fits and tags[1].colorKey == "text", tags[1].colorKey)
suite.check("a skill with no icon has none", not tags[1].icon:IsShown())
suite.check("a tag not needed is put away", not tags[2]:IsShown())

-- Tags too wide for one line go on to a second.
fits, tags = Lay({ { name = "Furious Howl", rank = 4 }, { name = "Lightning Breath", rank = 6 } })
suite.check("two long skills still fit", fits == true)
local lines = {}
for i = 1, 2 do lines[tags[i]._point[5]] = true end
local count = 0
for _ in pairs(lines) do count = count + 1 end
suite.check("on two lines", count == 2, count)
suite.check("two lines of tags start at the top of the row", tags[1]._point[5] == -1 and tags[2]._point[5] == -18,
    tags[2]._point[5])
suite.check("no tag runs past the column", (function()
    local left = tags[1]._point[4]
    for i = 1, 2 do
        if tags[i]._point[4] - left + tags[i]._width > 188 then return false end
    end
    return true
end)())

-- More than two lines of tags: the row shows them as words, which wrap.
local many = {}
for i = 1, 8 do many[i] = { name = "Lightning Breath", rank = i } end
fits, tags = Lay(many)
suite.check("too many tags do not fit", fits == false)
suite.check("and every tag is put away", (function()
    for _, tag in ipairs(tags) do
        if tag:IsShown() then return false end
    end
    return true
end)())
local words = UI.SkillText({ { name = "Bite", rank = 1 }, { name = "Dash", rank = 2 }, { name = "Mystery", rank = 1 } })
local Theme = ns.Theme
local function Hex(key)
    local r, g, b = Theme.Unpack(key)
    return ("|cff%02x%02x%02x"):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
suite.check("as words a known skill is grey, a new one gold and an unsure one plain",
    words == Hex("muted") .. "Bite 1|r, " .. Hex("accentHi") .. "Dash 2|r, Mystery 1", words)

-- Filling a row: tags when the beast teaches something, "Nothing" when not.
local teaches, nothing
for _, entry in ipairs(ns.Compendium:All()) do
    local n = #ns.Compendium:Skills(entry)
    if n > 0 and not teaches then teaches = entry end
    if n == 0 and not nothing then nothing = entry end
end
UI:FillRow(row, teaches, 60)
suite.check("a beast that teaches shows tags, not words",
    row.skills:GetText() == "" and rawget(row, "tags")[1]:IsShown(), row.skills:GetText())
UI:FillRow(row, nothing, 60)
suite.check("a beast that teaches nothing says so", row.skills:GetText():find("Nothing", 1, true)
    and not rawget(row, "tags")[1]:IsShown(), row.skills:GetText())

ns.Taming.Knows = realKnows
_G.C_Spell.GetSpellTexture = realTexture
_G.UnitClass = nil
suite.done()
