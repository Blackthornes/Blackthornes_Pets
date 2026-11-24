-- The skills card on the Pet tab: two columns, what the pet knows on the
-- left and what it can learn now and later on the right, each skill with the
-- game's own icon.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("skillscard")

local ns = env.Load()
local UI = ns.UI
local PetSkills = ns.PetSkills

-- The client's icon for a spell, by its number.
local asked = 0
_G.C_Spell = _G.C_Spell or {}
local realTexture = _G.C_Spell.GetSpellTexture
_G.C_Spell.GetSpellTexture = function(spell)
    asked = asked + 1
    return 100000 + spell
end

local bite3 = ns.PetTrainingData.SKILLS["Bite"][3].spell
suite.check("a skill's icon is its spell's", PetSkills.Icon("Bite", 3) == 100000 + bite3, PetSkills.Icon("Bite", 3))
local before = asked
PetSkills.Icon("Bite", 3)
suite.check("asked once, then kept", asked == before, asked - before)
suite.check("a rank the data lacks takes another rank's icon", PetSkills.Icon("Bite", 99) ~= nil)
suite.check("a skill nobody knows has none", PetSkills.Icon("Juggling", 1) == nil)
suite.check("a demon's skill has one too", PetSkills.Icon("Blood Pact", 1) == 100000 + 6307, PetSkills.Icon("Blood Pact", 1))

-- A client that raises, or answers nothing, means no icon and no error.
_G.C_Spell.GetSpellTexture = function() error("secret value") end
local claw = ns.PetTrainingData.SKILLS["Claw"][1].spell
suite.check("a call that raises gives no icon", PetSkills.SpellIcon(claw) == nil)
_G.C_Spell.GetSpellTexture = function(spell) return 100000 + spell end

_G.UnitClass = function() return "Hunter", "HUNTER" end
UI:Show()
UI.fullWidth = UI.fullWidth or 784

local plan = {
    kind = "pet",
    known = { { name = "Bite", rank = 3 }, { name = "Growl", rank = 3 }, { name = "Cower", rank = 2 } },
    learn = { { name = "Great Stamina", rank = 3, cost = 15, from = "trainer" } },
    later = { { name = "Bite", rank = 4, level = 24 }, { name = "Dash", rank = 1, tame = true } },
}
local trainer = { name = "Harruk", zone = "Durotar" }
local height = UI:ShowSkills(plan, trainer, -300)
local rows, heads = UI.skillRows, UI.skillHeads
local left = UI.skillColumns[1]

suite.check("two columns", #UI.skillColumns == 2 and left >= 220 and left <= math.floor((UI.fullWidth - 2) * 0.45), left)
suite.check("the columns fill the card", UI.skillColumns[1] + UI.skillColumns[2] + 1 == UI.fullWidth - 2)
suite.check("what the pet knows heads the left", heads.known:IsShown() and heads.known._point[4] == 1)
suite.check("what it can learn heads the right, level with it",
    heads.learn._point[4] == left + 2 and heads.learn._point[5] == heads.known._point[5], heads.learn._point[4])
suite.check("the first known skill is on the left", rows[1].label:GetText() == "Bite" and rows[1]._point[4] == 1)
suite.check("with its rank", rows[1].value:GetText() == "Rank 3")
suite.check("and its icon", rows[1].iconSlot:IsShown() and rows[1].icon._texture == 100000 + bite3, rows[1].icon._texture)
suite.check("the name starts past the icon", rows[1].label._point[4] == 12 + 16 + 8, rows[1].label._point[4])
suite.check("a skill to learn is on the right", rows[4].label:GetText():find("Great Stamina Rank 3", 1, true)
    and rows[4]._point[4] == left + 2, rows[4]._point[4])
suite.check("with its cost", rows[4].value:GetText() == "15 points", rows[4].value:GetText())
suite.check("later comes under it, in the same column",
    heads.later._point[4] == left + 2 and heads.later._point[5] == rows[4]._point[5] - 22, heads.later._point[5])
suite.check("rows take turns light and dark", rows[1].glassKey == "glass" and rows[2].glassKey == "glassAlt")
suite.check("a line splits the columns", UI.skillDivide:IsShown() and UI.skillDivide._point[4] == left + 1)

-- The card is as tall as its taller column, with the trainer's line under.
local head, row, foot = 20, 22, 34
local leftTall = head + 3 * row
local rightTall = head + row + head + 2 * row
suite.check("as tall as the taller column", height == 25 + math.max(leftTall, rightTall) + 2 + foot + 2, height)
suite.check("the trainer is named", UI.skillTrainer:GetText() == "Pet trainer: Harruk, Durotar", UI.skillTrainer:GetText())

-- A name too long for its line wraps, the line grows and the next moves down.
rows[5].label.GetStringHeight = function() return 30 end
UI:ShowSkills(plan, trainer, -300)
suite.check("a wrapped line grows", rows[5]._height == 38, rows[5]._height)
suite.check("and the next line moves down", rows[6]._point[5] == rows[5]._point[5] - 38, rows[6]._point[5])
rows[5].label.GetStringHeight = nil

-- Only one side to show: it takes the whole card.
UI:ShowSkills({ kind = "pet", known = plan.known, learn = {}, later = {} }, nil, -300)
suite.check("known skills alone take the whole card",
    #UI.skillColumns == 1 and rows[1]._width == UI.fullWidth - 2, rows[1]._width)
suite.check("with no line between", not UI.skillDivide:IsShown())
suite.check("and no heading for the empty side", not heads.learn:IsShown() and not heads.later:IsShown())
suite.check("rows not needed are put away", not rows[4]:IsShown())

-- With no icon to show, the name starts where the icon would.
_G.C_Spell.GetSpellTexture = function() return nil end
local dash = UI.SkillLines({ kind = "pet", known = { { name = "Prowl", rank = 1 } }, learn = {}, later = {} }, "known")
suite.check("a skill with no icon has none on its line", dash[1].icon == nil)
UI:ShowSkills({ kind = "pet", known = { { name = "Prowl", rank = 1 } }, learn = {}, later = {} }, nil, -300)
suite.check("so its name starts at the edge", not rows[1].iconSlot:IsShown() and rows[1].label._point[4] == 12,
    rows[1].label._point[4])

_G.C_Spell.GetSpellTexture = realTexture
_G.UnitClass = nil
suite.done()
