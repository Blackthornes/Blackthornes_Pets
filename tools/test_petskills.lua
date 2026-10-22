-- The Skills card in the pets window: what the pet knows, what it can learn
-- now and what comes later, the nearest pet trainer, the arrow to it, and a
-- skill's click opening the Compendium on the beasts that teach it.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("petskills")

local ns = env.Load()
local PetSkills, Data = ns.PetSkills, ns.PetTrainingData

-- The data.
local broken
for name, skill in pairs(Data.SKILLS) do
    for rank, row in pairs(skill) do
        if type(rank) == "number" and not (type(row.spell) == "number" and type(row.level) == "number") then
            broken = name
        end
    end
end
suite.check("every rank has the pet's spell and a level", broken == nil, broken)
suite.check("the pet's spell names its skill and rank",
    Data.SPELLS[17255] and Data.SPELLS[17255][1] == "Bite" and Data.SPELLS[17255][2] == 2)
suite.check("there are pet trainers of both sides", (function()
    local a, h = false, false
    for _, t in ipairs(Data.TRAINERS) do
        if t.side == "A" then a = true elseif t.side == "H" then h = true end
    end
    return a and h
end)())

-- A boar at level 12 that knows Bite 1 and Charge 1; the hunter has learned
-- Bite 2 from Beast Training.
ns.charDB.beastTraining = nil
local learned = { [17262] = true }
_G.IsPlayerSpell = function(id) return learned[id] == true end
local plan = PetSkills:Plan({ Bite = 1, Charge = 1 }, 12, 5)

local function Find(list, name)
    for _, entry in ipairs(list) do
        if entry.name == name then return entry end
    end
    return nil
end

suite.check("it knows Bite and Charge", Find(plan.known, "Bite") and Find(plan.known, "Charge")
    and Find(plan.known, "Bite").rank == 1)
local bite = Find(plan.learn, "Bite")
suite.check("Bite 2 can be learned now, from Beast Training",
    bite and bite.rank == 2 and bite.from == "hunter" and bite.cost == 4, bite and bite.rank)
suite.check("Charge 2 is not offered, the hunter never learned it", Find(plan.learn, "Charge") == nil)
local charge = Find(plan.later, "Charge")
suite.check("so it waits on a beast to tame", charge and charge.rank == 2 and charge.tame == true)
local arcane = Find(plan.later, "Arcane Resistance")
suite.check("a trainer's skill waits for the pet's level", arcane == nil or arcane.level == 20)
suite.check("later comes nearest first", (function()
    local last = 0
    for _, entry in ipairs(plan.later) do
        if (entry.level or 0) < last then return false end
        last = entry.level or 0
    end
    return true
end)())
suite.check("later shows a few lines at most", #plan.later <= PetSkills.LATER_MOST)
suite.check("a cat's skill is not offered to a boar", Find(plan.learn, "Claw") == nil
    and Find(plan.later, "Claw") == nil)

learned[17263] = true
plan = PetSkills:Plan({ Bite = 1 }, 16, 5)
suite.check("the best rank it can reach is offered", Find(plan.learn, "Bite").rank == 3)
plan = PetSkills:Plan({ Bite = 3 }, 16, 5)
suite.check("nothing to learn once it has it", Find(plan.learn, "Bite") == nil)
_G.IsPlayerSpell = nil

-- The nearest pet trainer.
ns.Travel.Side = function() return "H" end
local here = { zone = "Durotar" }
local realHere = ns.BeastArrow.Here
ns.BeastArrow.Here = function() return here end
local trainer = PetSkills:Trainer()
suite.check("the trainer in the zone you are in", trainer and trainer.zone == "Durotar")
here = { zone = "Nowhere At All" }
trainer = PetSkills:Trainer()
suite.check("else one of your side", trainer and trainer.side == "H")
ns.Travel.Side = function() return "A" end
trainer = PetSkills:Trainer()
suite.check("never one of the other side", trainer and trainer.side == "A")
ns.BeastArrow.Here = realHere

-- Show the Way: the arrow follows the trainer, and lets go at its window.
local followed = { id = 3620, name = "Harruk", zone = "Durotar", x = 52, y = 43.5 }
suite.check("the arrow follows the trainer", ns.BeastArrow:FollowPlace(followed) == true)
local beast = ns.BeastArrow:Beast()
suite.check("as a place, by name", beast and beast.place and beast.name == "Harruk" and beast.npc == 3620)
_G.UnitGUID = function(unit) if unit == "npc" then return "Creature-0-1-2-3-9999-0001" end end
ns.BeastArrow:OnTrainer()
suite.check("another trainer's window keeps it", ns.charDB.arrowPlace ~= nil)
_G.UnitGUID = function(unit) if unit == "npc" then return "Creature-0-1-2-3-3620-0001" end end
ns.BeastArrow:OnTrainer()
suite.check("that trainer's window puts it away", ns.charDB.arrowPlace == nil)
_G.UnitGUID = nil
suite.check("a place with no zone is not followed", ns.BeastArrow:FollowPlace({ name = "x" }) == false)

-- A click on a skill opens the Compendium on the beasts that teach it.
local UI = ns.UI
UI:Show()
UI:ShowBeastsFor("Charge")
suite.check("the Compendium opens", ns.CompendiumUI.frame:IsShown())
suite.check("searching for the skill", ns.CompendiumUI.search:GetText() == "Charge")
suite.check("in the Pet tab's place", not UI.frame:IsShown())

suite.done()
