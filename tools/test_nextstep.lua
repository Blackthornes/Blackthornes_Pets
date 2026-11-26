-- The Next Step line under the pet on the Pet tab: the one thing most worth
-- doing next, the order the lines win in, and the button each one has.
-- Also the skills to find by taming, which the line shares with the
-- Compendium.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("nextstep")

local ns = env.Load()
local NextStep, PetSkills = ns.NextStep, ns.PetSkills

local function Stacks(count)
    if count == 0 then return {} end
    return { { name = "Haunch of Meat", itemID = 2287, count = count, effect = "full", bag = 0, slot = 1 } }
end

local cat = {
    exists = true, name = "Shadowpaw", level = 23, happiness = 3,
    foods = { "Meat", "Fish" }, trainingFree = 23,
}
local function With(fields)
    local status = {}
    for key, value in pairs(cat) do status[key] = value end
    for key, value in pairs(fields or {}) do status[key] = value end
    return status
end

local trainer = { name = "Karrina Mekenda", zone = "Stormwind City", side = "A" }
local stamina = { name = "Great Stamina", rank = 3, cost = 15, from = "trainer" }
local plan = { known = {}, learn = { stamina }, later = {} }
local beast = { name = "Coyote Packleader", zone = "Westfall", min = 11, max = 12, x = 40, y = 50 }
local find = { now = { { name = "Bite", rank = 4, beast = beast } }, later = {}, done = {} }

-- 1. Hungry, with food: Feed.
local step = NextStep.Pick({ status = With({ happiness = 2 }), stacks = Stacks(47), plan = plan,
    trainer = trainer, find = find })
suite.check("a hungry pet comes first", step and step.kind == "feed", step and step.kind)
suite.check("it says so", step.text == "Shadowpaw is hungry.", step.text)
suite.check("and how much food is there", step.sub == "47 Haunch of Meat in your bags.", step.sub)
suite.check("with Feed", step.button == "Feed" and step.stack and step.stack.itemID == 2287)

-- Hungry with no food: the low food line instead.
step = NextStep.Pick({ status = With({ happiness = 2 }), stacks = Stacks(0), plan = plan })
suite.check("hungry with no food says the food is gone", step.kind == "food" and step.text == "You have 0 pet food left.",
    step.text)

-- 2. Low food: Okay puts it away until the bags are restocked.
step = NextStep.Pick({ status = With(), stacks = Stacks(3), plan = plan, trainer = trainer, find = find })
suite.check("low food comes next", step.kind == "food" and step.text == "You have 3 pet food left.", step.text)
suite.check("and what it eats", step.sub == "Shadowpaw eats Meat, Fish.", step.sub)
suite.check("with Okay", step.button == "Okay")
NextStep:Dismiss("Shadowpaw")
step = NextStep.Pick({ status = With(), stacks = Stacks(3), plan = plan, trainer = trainer, find = find })
suite.check("Okay puts it away", step.kind == "train", step.kind)
NextStep.Pick({ status = With(), stacks = Stacks(30), plan = plan, trainer = trainer, find = find })
step = NextStep.Pick({ status = With(), stacks = Stacks(3), plan = plan, trainer = trainer, find = find })
suite.check("until the bags are restocked", step.kind == "food", step.kind)
step = NextStep.Pick({ status = With(), stacks = { incomplete = true }, plan = plan })
suite.check("bags not read yet say nothing of food", step == nil or step.kind ~= "food")

-- 3. A trainer skill the pet can afford.
step = NextStep.Pick({ status = With(), stacks = Stacks(40), plan = plan, trainer = trainer, find = find })
suite.check("an affordable trainer skill", step.kind == "train"
    and step.text == "Great Stamina Rank 3 costs 15 points. You have 23.", step.text)
suite.check("names the trainer", step.sub == "Karrina Mekenda in Stormwind City teaches it.", step.sub)
suite.check("with Show the Way to them", step.button == "Show the Way" and step.trainer == trainer)
step = NextStep.Pick({ status = With({ trainingFree = 10 }), stacks = Stacks(40), plan = plan,
    trainer = trainer, find = find })
suite.check("one it can't afford is passed over", step.kind == "find", step.kind)
step = NextStep.Pick({ status = With(), stacks = Stacks(40), trainer = trainer,
    plan = { known = {}, learn = { { name = "Bite", rank = 4, cost = 10, from = "hunter" } }, later = {} } })
suite.check("one the hunter knows is taught from Beast Training",
    step.kind == "train" and step.sub == "Open Beast Training to teach it." and step.button == nil, step.sub)
step = NextStep.Pick({ status = With({ trainingFree = 1 }), stacks = Stacks(40), trainer = trainer,
    plan = { known = {}, learn = { { name = "Cower", rank = 1, cost = 1, from = "trainer" } }, later = {} } })
suite.check("one point is one point", step.text == "Cower Rank 1 costs 1 point. You have 1.", step.text)

-- 4. A skill to find by taming.
step = NextStep.Pick({ status = With({ trainingFree = 0 }), stacks = Stacks(40), plan = plan,
    trainer = trainer, find = find })
suite.check("a skill to find", step.kind == "find" and step.text == "Bite Rank 4 is ready to learn.", step.text)
suite.check("names the beast and where", step.sub == "A Coyote Packleader in Westfall teaches it.", step.sub)
suite.check("with Show the Way to the beast", step.button == "Show the Way" and step.beast == beast)
suite.check("a rare goes by its name alone",
    NextStep.BeastLine({ name = "Snarler", zone = "Feralas", rank = "rare" }) == "Snarler in Feralas teaches it.")

-- 5. Nothing left.
step = NextStep.Pick({ status = With(), stacks = Stacks(40), plan = { known = {}, learn = {}, later = {} },
    find = { now = {}, later = {}, done = {} } })
suite.check("nothing left for its level", step.kind == "done"
    and step.text == "Shadowpaw has everything for level 23." and step.button == nil, step.text)
step = NextStep.Pick({ status = With(), stacks = Stacks(40), plan = { known = {}, learn = { stamina }, later = {} },
    find = { now = {}, later = {}, done = {} }, trainer = trainer })
suite.check("a skill too dear is not everything", step and step.kind == "train" or step == nil)
step = NextStep.Pick({ status = With({ trainingFree = 0 }), stacks = Stacks(40),
    plan = { known = {}, learn = { stamina }, later = {} }, find = { now = {}, later = {}, done = {} } })
suite.check("and says nothing rather than everything", step == nil, step and step.kind)
suite.check("no pet, no line", NextStep.Pick({ status = { exists = false } }) == nil)

-- A warlock's demon: a book the gold in the bags pays for.
local demonPlan = { kind = "demon", known = {}, later = {},
    learn = { { name = "Firebolt", rank = 3, cost = 1800 } } }
step = NextStep.Pick({ status = { exists = true, name = "Imp", level = 20 }, plan = demonPlan,
    money = 5000, trainer = { name = "Kartosh", zone = "Orgrimmar" } })
suite.check("a demon book it can buy", step.kind == "train" and step.text:find("Firebolt Rank 3 costs", 1, true)
    and step.sub == "Kartosh in Orgrimmar teaches it.", step.text)
step = NextStep.Pick({ status = { exists = true, name = "Imp", level = 20 }, plan = demonPlan, money = 100 })
suite.check("not one it can't", step == nil)
step = NextStep.Pick({ status = { exists = true, name = "Imp", level = 20 },
    plan = { kind = "demon", known = {}, later = {}, learn = {} } })
suite.check("a demon with every book", step.kind == "done" and step.text == "Imp has everything for level 20.")

-- Skills to find, from the shipped data: a level 24 cat that knows Bite 3
-- and Claw 3, a level 25 hunter who learned none of it.
ns.charDB.beastTraining = nil
_G.IsPlayerSpell = function() return false end
local found = PetSkills:ToFind({ Bite = 3, Claw = 3 }, 24, 2, 25, "Westfall")
local function In(list, name, rank)
    for _, entry in ipairs(list) do
        if entry.name == name and entry.rank == rank then return entry end
    end
    return nil
end
local bite4 = In(found.now, "Bite", 4)
suite.check("Bite 4 is one to find now", bite4 ~= nil)
suite.check("from a beast the hunter can tame", bite4 and bite4.beast and bite4.beast.min <= 25,
    bite4 and bite4.beast and bite4.beast.min)
suite.check("Bite 5 comes later", In(found.later, "Bite", 5) ~= nil)
suite.check("what it has is done", In(found.done, "Bite", 3) and In(found.done, "Claw", 3))
suite.check("a trainer's skill is not one to find", In(found.now, "Great Stamina", 3) == nil
    and In(found.now, "Growl", 3) == nil)
suite.check("a wolf's skill is not offered to a cat", In(found.now, "Furious Howl", 1) == nil)
suite.check("it counts ranks: Bite has 3 of 4", found.have < found.of and found.have >= 6, found.have .. "/" .. found.of)
local closest = PetSkills:ClosestBeast("Bite", 4, "Westfall", 25)
suite.check("the closest beast is near", closest and PetSkills.ZonesAway("Westfall", closest.zone) <= 2,
    closest and closest.zone)
suite.check("the same zone is no zones away", PetSkills.ZonesAway("Westfall", "Westfall") == 0)
suite.check("a zone beside it is one", PetSkills.ZonesAway("Westfall", "Elwynn Forest") == 1)
suite.check("another continent is far", PetSkills.ZonesAway("Westfall", "Durotar") == PetSkills.FAR)
_G.IsPlayerSpell = function(id) return id == ns.PetTrainingData.SKILLS["Bite"][4].teach end
found = PetSkills:ToFind({ Bite = 3, Claw = 3 }, 24, 2, 25, "Westfall")
suite.check("a rank the hunter learned is taught, not found", In(found.now, "Bite", 4) == nil)
_G.IsPlayerSpell = nil

-- On the Pet tab: the line sits under the top card, the cards move down.
_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Shadowpaw" end
_G.UnitLevel = function() return 23 end
_G.C_PetInfo = {
    GetPetHappiness = function() return 2, 100, 5 end,
    GetPetFoodTypes = function() return { "Meat" } end,
    GetPetTrainingPoints = function() return 30, 7 end,
}
local realLatest = ns.Food.Latest
ns.Food.Latest = function() return Stacks(47) end
ns.UI:Show()
local UI = ns.UI
suite.check("the line shows", UI.nextLine:IsShown())
suite.check("under the top card", UI.nextLine._point[5] == -(88 + 10), UI.nextLine._point[5])
suite.check("saying the pet is hungry", UI.nextText:GetText() == "Shadowpaw is hungry.", UI.nextText:GetText())
suite.check("with the secure Feed button over it", UI.nextFeedButton:IsShown()
    and UI.nextFeedButton:GetAttribute("type") == "macro")
suite.check("and not the plain one", not UI.nextButton:IsShown())
suite.check("the food card moves down", UI.foodCard._point[5] == -(88 + 10) - UI.nextExtra, UI.foodCard._point[5])
UI:PlaceFeedButton(nil, true)
suite.check("combat starting takes the Feed button away", not UI.nextFeedButton:IsShown())

_G.C_PetInfo.GetPetHappiness = function() return 3, 125, 5 end
ns.Food.Latest = function() return Stacks(3) end
NextStep.dismissed = nil
UI:Refresh()
suite.check("low food shows Okay", UI.nextButton:IsShown() and UI.nextButton.label:GetText() == "Okay"
    and not UI.nextFeedButton:IsShown())
UI.nextButton:GetScript("OnClick")(UI.nextButton, "LeftButton")
suite.check("a click on Okay moves on", UI.nextStep == nil or UI.nextStep.kind ~= "food",
    UI.nextStep and UI.nextStep.kind)
ns.Food.Latest = realLatest
UI:Hide()
suite.check("closing the window takes the Feed button too", not UI.nextFeedButton:IsShown())

suite.done()
