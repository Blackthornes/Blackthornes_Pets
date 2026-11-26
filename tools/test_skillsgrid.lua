-- The Skills Grid on the Pet tab: a List / Grid switch on the Skills card,
-- each skill one line and each rank one box, gold for known, a bright gold
-- edge for what the pet can get now, dim for later.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("skillsgrid")

local ns = env.Load()
local UI, PetSkills = ns.UI, ns.PetSkills

-- A boar at level 12 that knows Bite 1 and Charge 1; the hunter has learned
-- Bite 2 from Beast Training.
ns.charDB.beastTraining = nil
local learned = { [17262] = true }
_G.IsPlayerSpell = function(id) return learned[id] == true end
local plan = PetSkills:Plan({ Bite = 1, Charge = 1 }, 12, 5)

local function Find(name)
    for _, row in ipairs(plan.grid) do
        if row.name == name then return row end
    end
end

local bite = Find("Bite")
suite.check("the grid has a line for each skill the pet can learn", bite ~= nil and Find("Growl") ~= nil)
suite.check("a skill this family can't learn has none", Find("Claw") == nil)
suite.check("every rank is a box", bite and #bite.ranks == #(function()
    local out = {}
    for rank in pairs(ns.PetTrainingData.SKILLS.Bite) do
        if type(rank) == "number" then out[#out + 1] = rank end
    end
    return out
end)())
suite.check("rank 1 is known", bite.ranks[1].state == "known")
suite.check("rank 2 can be had now, as the list says", bite.ranks[2].state == "now" and bite.ranks[2].from == "hunter")
suite.check("rank 3 is later", bite.ranks[3].state == "later")
suite.check("its next step is rank 2", bite.next and bite.next.rank == 2 and bite.next.cost ~= nil)
local learn
for _, entry in ipairs(plan.learn) do if entry.name == "Bite" then learn = entry end end
suite.check("the grid agrees with the list", learn and learn.rank == bite.next.rank)

-- Family skills come first, then the ones every pet can learn.
local firstAll
for index, row in ipairs(plan.grid) do
    if row.all and not firstAll then firstAll = index end
    if firstAll and not row.all then firstAll = -1 end
end
suite.check("family skills come before the shared ones", firstAll and firstAll > 1, firstAll)

-- The note at the right.
local note, now = UI.GridNote(bite)
suite.check("the note names the rank, who teaches it and the cost",
    now and note == ("Rank 2: Beast Training, %d points"):format(bite.next.cost), note)
local stamina = { name = "Great Stamina", ranks = {}, next = { rank = 3, cost = 15, from = "trainer" } }
suite.check("a pet trainer's rank", (UI.GridNote(stamina)) == "Rank 3: pet trainer, 15 points", (UI.GridNote(stamina)))
note, now = UI.GridNote({ name = "Growl", ranks = {}, next = { rank = 4, level = 30 } })
suite.check("a rank waiting on a level", note == "Rank 4 at level 30" and not now, note)
note = UI.GridNote({ name = "Dash", ranks = {}, next = { rank = 1, tame = true } })
suite.check("a rank to tame", note == "Rank 1: Tame a beast that knows it", note)
suite.check("nothing once every rank is known", (UI.GridNote({ name = "Bite", ranks = {} })) == "")

-- A box's hover tells its rank.
local lines = UI.GridBoxLines(bite, bite.ranks[2])
suite.check("the hover names the skill and rank", lines[1] == "Bite Rank 2", lines[1])
suite.check("and says the pet can get it now", lines[2] == "You can get it now", lines[2])
suite.check("its pet level", lines[3] == ("Pet level %d"):format(bite.ranks[2].level), lines[3])
suite.check("and its cost and teacher", lines[4] and lines[4]:find("from your Beast Training", 1, true), lines[4])
suite.check("a known rank says so", UI.GridBoxLines(bite, bite.ranks[1])[2] == "Your pet knows it")
suite.check("a later rank says it needs a level", UI.GridBoxLines(bite, bite.ranks[#bite.ranks])[2] == "Needs a higher level")

-- The card: List by default; Grid kept once picked.
_G.UnitClass = function() return "Hunter", "HUNTER" end
UI:Show()
UI.fullWidth = UI.fullWidth or 784
ns.db.skillsView = nil
suite.check("List is the default", UI.SkillsView() == "list")
UI:ShowSkills(plan, nil, -300)
suite.check("the switch shows for a hunter's pet", UI.skillsSwitch:IsShown())
suite.check("the list shows", UI.skillRows[1] and UI.skillRows[1]:IsShown())
suite.check("the grid doesn't", not (UI.gridRows[1] and UI.gridRows[1]:IsShown()) and not UI.gridKey:IsShown())

local realRefresh = UI.Refresh
UI.Refresh = function(self) self:ShowSkills(plan, nil, -300) end
UI.skillsSwitch.buttons.grid:GetScript("OnClick")(UI.skillsSwitch.buttons.grid)
suite.check("a click on Grid is kept", ns.db.skillsView == "grid")
suite.check("Grid is solid gold with dark letters",
    UI.skillsSwitch.buttons.grid.label._color[1] == select(1, ns.Theme.Unpack("ink")))
suite.check("the list is put away", not UI.skillRows[1]:IsShown())
local row = UI.gridRows[1]
suite.check("a line for each skill", row:IsShown() and #UI.gridRows >= #plan.grid)
suite.check("the first line is a family skill", row.label:GetText() == plan.grid[1].name, row.label:GetText())
local biteRow
for _, r in ipairs(UI.gridRows) do if r.data == bite then biteRow = r end end
suite.check("each rank has a box", biteRow and biteRow.boxes[#bite.ranks]:IsShown())
suite.check("a known rank is gold", biteRow.boxes[1].state == "known")
suite.check("one to get now has a bright edge", biteRow.boxes[2].state == "now")
suite.check("a later one is dim", biteRow.boxes[3].state == "later")
suite.check("the boxes line up across lines",
    UI.gridRows[1].boxes[1]._point[4] == UI.gridRows[2].boxes[1]._point[4])
suite.check("lines take turns light and dark", UI.gridRows[1].glassKey == "glass" and UI.gridRows[2].glassKey == "glassAlt")
suite.check("the key shows under the grid", UI.gridKey:IsShown())
suite.check("the note shows on the line", biteRow.note:GetText():find("Rank 2", 1, true) ~= nil, biteRow.note:GetText())

-- A demon has no grid.
UI:ShowSkills({ kind = "demon", known = { { name = "Firebolt", rank = 1 } }, learn = {}, later = {} }, nil, -300)
suite.check("a demon keeps the list", not UI.skillsSwitch:IsShown() and not UI.gridRows[1]:IsShown()
    and UI.skillRows[1]:IsShown())

-- Restore Defaults puts it back.
local keyed = false
for _, key in ipairs(ns.SettingsUI.SETTING_KEYS) do if key == "skillsView" then keyed = true end end
suite.check("Restore Defaults puts the view back", keyed and ns.DEFAULTS.skillsView == "list")

ns.db.skillsView = nil
UI.Refresh = realRefresh
_G.UnitClass = nil
_G.IsPlayerSpell = nil
suite.done()
