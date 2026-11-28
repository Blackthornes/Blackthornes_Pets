-- My Pets away from the stable: a pet let go or given a new name must not
-- stay on the tab as a second pet, and the slot count must not go past the
-- stable's slots. Found by the bug pass on 2026-11-28.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("mypetsgone")

local ns = env.Load()
local MyPets = ns.MyPets

local GUID = "Player-1-0000ABCD"
_G.UnitGUID = function(unit) return unit == "player" and GUID or nil end
_G.UnitClass = function() return "Hunter", "HUNTER" end

local function Names()
    local names = {}
    for _, pet in ipairs(MyPets:List()) do
        names[#names + 1] = pet.name .. (pet.active and " (out)" or "")
    end
    return table.concat(names, ", ")
end

-- At the stable: Boar out, Shadow the Cat stabled, one slot.
local boar = { familyName = "Boar", icon = 1, level = 12, loyaltyName = "Submissive", name = "Boar",
    petNumber = 22, slotID = 1 }
local cat = { familyName = "Cat", icon = 2, level = 26, loyaltyName = "Faithful", name = "Shadow",
    petNumber = 11, slotID = 2 }
local atStable, activeList, stabledList = true, { boar }, { cat }
_G.C_StableInfo = {
    IsAtStableMaster = function() return atStable end,
    GetActivePetList = function() return activeList end,
    GetStabledPetList = function() return stabledList end,
    GetNumStableSlots = function() return 1 end,
    GetStablePetFoodTypes = function() return { "Meat" } end,
}
local out = { name = "Boar", family = "Boar", id = 5 }
_G.UnitExists = function() return out ~= nil end
_G.UnitName = function() return out.name end
_G.UnitLevel = function() return 20 end
_G.UnitCreatureFamily = function() return out.family, out.id end
local realKnown = ns.PetSkills.Known
local known = { Charge = 1 }
ns.PetSkills.Known = function() return known end

MyPets:ReadStable()
MyPets:ReadOut()
suite.check("two pets to start", Names() == "Boar (out), Shadow", Names())

-- Away from the stable the lists answer nothing.
atStable = false
_G.C_StableInfo.GetActivePetList = function() return nil end
_G.C_StableInfo.GetStabledPetList = function() return nil end

-- The Boar is let go and a Wolf tamed for its Bite.
out, known = { name = "Wolf", family = "Wolf", id = 1 }, { Bite = 3 }
MyPets:ReadOut()
suite.check("the pet let go leaves the tab", Names() == "Wolf (out), Shadow", Names())
local used, total = MyPets:Slots()
suite.check("and the slots stay one of one", used == 1 and total == 1, tostring(used) .. "/" .. tostring(total))
local record = ns.db.myPets[GUID]
suite.check("it is hidden, not deleted", record.pets.n22 ~= nil and record.pets.n22.gone == true)

-- The Wolf is given a name: the same pet, one card.
out = { name = "Fang", family = "Wolf", id = 1 }
MyPets:ReadOut()
suite.check("a new name is the same pet", Names() == "Fang (out), Shadow", Names())
used, total = MyPets:Slots()
suite.check("the slots still one of one", used == 1 and total == 1, tostring(used) .. "/" .. tostring(total))
local kept = 0
for _, pet in pairs(record.pets) do
    if pet.family == "Wolf" and not pet.gone then kept = kept + 1 end
end
suite.check("under one record", kept == 1, kept)

-- A pet with a number from the stable, renamed away from it.
atStable = true
local fang = { familyName = "Wolf", icon = 3, level = 20, loyaltyName = "Submissive", name = "Fang",
    petNumber = 33, slotID = 1 }
activeList = { fang }
_G.C_StableInfo.GetActivePetList = function() return activeList end
_G.C_StableInfo.GetStabledPetList = function() return stabledList end
MyPets:ReadStable()
suite.check("the stable gives it its number", record.pets.n33 ~= nil and Names() == "Fang (out), Shadow", Names())
atStable = false
out = { name = "Ghost", family = "Wolf", id = 1 }
MyPets:ReadOut()
suite.check("renamed again, still one card", Names() == "Ghost (out), Shadow", Names())
suite.check("and it keeps its skills", record.pets.n33.name == "Ghost" and record.pets.n33.known.Bite == 3)
atStable = true
fang.name = "Ghost"
MyPets:ReadStable()
suite.check("the stable agrees", Names() == "Ghost (out), Shadow", Names())

-- Two pets with one name and family: the skills go on the one out.
local twin = { familyName = "Wolf", icon = 3, level = 9, loyaltyName = "Submissive", name = "Ghost",
    petNumber = 44, slotID = 3 }
stabledList = { cat, twin }
for round = 1, 20 do
    record.pets.n33.known, record.pets.n44 = nil, nil
    MyPets:ReadStable()
    known = { Bite = round }
    MyPets:ReadOut()
    if record.pets.n44.known or not record.pets.n33.known then break end
end
suite.check("the stabled twin is not given the skills of the one out",
    record.pets.n44.known == nil and record.pets.n33.known ~= nil and record.pets.n33.active == true
    and record.pets.n44.active == false)

-- Swapped at the stable: the old one out is stabled, never gone.
activeList, stabledList = { cat }, { fang }
MyPets:ReadStable()
out = { name = "Shadow", family = "Cat", id = 2 }
atStable = false
MyPets:ReadOut()
suite.check("a swap at the stable hides nothing", Names() == "Shadow (out), Ghost", Names())

ns.PetSkills.Known = realKnown
_G.C_StableInfo, _G.UnitGUID, _G.UnitCreatureFamily = nil, nil, nil
suite.done()
