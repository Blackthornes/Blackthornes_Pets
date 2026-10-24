-- Blackthornes Pets -- Logic/PetSkills.lua
-- The hunter's pet skills, for the Skills card in the pets window (a player
-- asked, the owner said build it from a mockup, 2026-10-22): what the pet
-- knows, what it can learn now and what comes later, and the nearest pet
-- trainer.
--
-- What every rank needs comes from Data/PetTraining.lua. What the pet knows
-- is read from its own spell book, else its action bar, by spell ID and,
-- for a spell Forever renumbered, by name and rank. Everything the client
-- is asked is read only and inside a pcall.
--
-- A rank can be learned now when the pet is old enough, its family can
-- learn the skill, and either the hunter knows that rank (Beast Training)
-- or a pet trainer teaches it. The ranks every pet gets for free are never
-- offered. Later lists the next rank of each skill the pet has or could
-- learn: a pet level away, or a beast to tame for a rank no trainer teaches.

local _, ns = ...

local PetSkills = ns.NewModule("PetSkills")

-- How many "later" lines the card shows at most, the nearest first.
PetSkills.LATER_MOST = 4

local function Plain(value) return ns.PetStatus.Plain(value) end

local function Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return Plain(a), Plain(b), Plain(c), Plain(d)
end

local function Data() return ns.PetTrainingData end

--------------------------------------------------------------------------------
-- The pet
--------------------------------------------------------------------------------

--- Is the player a hunter? Only hunters' pets learn skills this way.
function PetSkills.IsHunter()
    local _, token = Read(_G.UnitClass, "player")
    return token == "HUNTER"
end

--- The pet's level, or nil.
function PetSkills.PetLevel()
    local level = Read(_G.UnitLevel, "pet")
    return type(level) == "number" and level > 0 and level or nil
end

local familyByName

--- The pet's family as the data numbers it (Boar is 5), or nil. The client
--- gives a name in its own language and, on newer clients, the ID beside
--- it; the name is matched against the client's own names for the IDs the
--- data uses.
function PetSkills.FamilyID()
    local name, id = Read(_G.UnitCreatureFamily, "pet")
    if type(id) == "number" then return id end
    if type(name) ~= "string" or name == "" then return nil end
    if not familyByName then
        familyByName = {}
        local info = _G.C_CreatureInfo and _G.C_CreatureInfo.GetCreatureFamilyInfo
        local ids = {}
        for _, skill in pairs(Data().SKILLS) do
            for _, family in ipairs(skill.families or {}) do ids[family] = true end
        end
        for family in pairs(ids) do
            local ok, found = pcall(function()
                local row = info and info(family)
                return row and Plain(row.name)
            end)
            if ok and type(found) == "string" then familyByName[found] = family end
        end
    end
    return familyByName[name]
end

--- Can a pet of this family learn the skill? Unknown families only learn
--- what every pet can.
function PetSkills.FamilyCan(skill, family)
    if skill.all then return true end
    if not family then return false end
    for _, id in ipairs(skill.families or {}) do
        if id == family then return true end
    end
    return false
end

--- A spell as { name, rank } in the data's English, or nil.
local function SkillOf(spellID, name, subtext)
    local data = Data()
    local known = type(spellID) == "number" and data.SPELLS[spellID]
    if known then return known[1], known[2] end
    if type(name) ~= "string" then return nil end
    local english = ns.Taming:EnglishName(name)
    if not data.SKILLS[english] then return nil end
    local rank = type(subtext) == "string" and tonumber(subtext:match("(%d+)")) or 1
    return english, rank
end

--- The spells in the pet's spell book: { { spell, name, subtext } }. Both
--- ways the client may have it are tried.
local function SpellBook()
    local out = {}
    local book = _G.C_SpellBook
    if type(book) == "table" and type(book.HasPetSpells) == "function" then
        local count = Read(book.HasPetSpells)
        local bank = _G.Enum and _G.Enum.SpellBookSpellBank and _G.Enum.SpellBookSpellBank.Pet or 1
        for i = 1, (type(count) == "number" and count or 0) do
            local ok, spell, name, sub = pcall(function()
                local info = book.GetSpellBookItemInfo(i, bank)
                if type(info) ~= "table" then return nil end
                return info.spellID or info.actionID, info.name, info.subName
            end)
            if ok then out[#out + 1] = { Plain(spell), Plain(name), Plain(sub) } end
        end
        if #out > 0 then return out end
    end
    local count = Read(_G.HasPetSpells)
    local bookType = _G.BOOKTYPE_PET or "pet"
    for i = 1, (type(count) == "number" and count or 0) do
        local name, sub, spell = Read(_G.GetSpellBookItemName, i, bookType)
        if type(spell) ~= "number" then
            local _, id = Read(_G.GetSpellBookItemInfo, i, bookType)
            spell = id
        end
        out[#out + 1] = { spell, name, sub }
    end
    return out
end
-- Logic/DemonSkills.lua reads the demon's book the same way.
PetSkills.SpellBook = SpellBook

--- What the pet knows: { [English name] = best rank }.
function PetSkills:Known()
    local known = {}
    local function Note(name, rank)
        if name and rank and rank > (known[name] or 0) then known[name] = rank end
    end
    for _, spell in ipairs(SpellBook()) do
        Note(SkillOf(spell[1], spell[2], spell[3]))
    end
    if ns.TameRecord and ns.TameRecord.PetSkills then
        local ok, bar = pcall(ns.TameRecord.PetSkills, ns.TameRecord)
        for _, skill in ipairs(ok and bar or {}) do
            local name, rank = SkillOf(skill.spell, skill.name, nil)
            Note(name, rank and math.max(rank, skill.rank or 1))
        end
    end
    return known
end

--------------------------------------------------------------------------------
-- The plan
--------------------------------------------------------------------------------

local function Ranks(skill)
    local ranks = {}
    for rank in pairs(skill) do
        if type(rank) == "number" then ranks[#ranks + 1] = rank end
    end
    table.sort(ranks)
    return ranks
end

local function HunterKnows(name, rank)
    local ok, knows = pcall(ns.Taming.Knows, ns.Taming, { name = name, rank = rank })
    return ok and knows == true
end

--- Work out the three lists from what the pet knows, its level and family:
---   { known = { { name, rank } },
---     learn = { { name, rank, cost, from = "hunter" | "trainer" } },
---     later = { { name, rank, level } or { name, rank, tame = true } } }
--- Each list in name order, later by when it comes.
function PetSkills:Plan(known, level, family)
    local plan = { known = {}, learn = {}, later = {} }
    level = level or 0
    for name, skill in pairs(Data().SKILLS) do
        local have = known[name] or 0
        if have > 0 then plan.known[#plan.known + 1] = { name = name, rank = have } end
        if have > 0 or PetSkills.FamilyCan(skill, family) then
            local ranks, best = Ranks(skill), nil
            for _, rank in ipairs(ranks) do
                local row = skill[rank]
                if rank > have and row.level <= level and not row.free then
                    local hunter = HunterKnows(name, rank)
                    if hunter or row.trainer then
                        best = { name = name, rank = rank, cost = row.cost,
                            from = hunter and "hunter" or "trainer" }
                    end
                end
            end
            if best then plan.learn[#plan.learn + 1] = best end

            local after = best and best.rank or have
            for _, rank in ipairs(ranks) do
                local row = skill[rank]
                if rank > after and not row.free then
                    local reachable = row.trainer or HunterKnows(name, rank)
                    if row.level > level and (reachable or after > 0) then
                        plan.later[#plan.later + 1] = { name = name, rank = rank, level = row.level }
                    elseif row.level <= level and not reachable and after > 0 then
                        plan.later[#plan.later + 1] = { name = name, rank = rank, tame = true }
                    end
                    break
                end
            end
        end
    end
    local byName = function(a, b) return a.name < b.name end
    table.sort(plan.known, byName)
    table.sort(plan.learn, byName)
    table.sort(plan.later, function(a, b)
        local la, lb = a.level or 0, b.level or 0
        if la ~= lb then return la < lb end
        return a.name < b.name
    end)
    while #plan.later > PetSkills.LATER_MOST do table.remove(plan.later) end
    return plan
end

--- The plan for the pet out now, or nil for a pet that is not a hunter's.
function PetSkills:Current()
    if not (PetSkills.IsHunter() and Read(_G.UnitExists, "pet")) then return nil end
    return self:Plan(self:Known(), PetSkills.PetLevel(), PetSkills.FamilyID())
end

--------------------------------------------------------------------------------
-- The pet trainer
--------------------------------------------------------------------------------

--- The nearest of `trainers` ({ { name, side, zone, x, y } }, x and y 0 to
--- 100) of the player's side: one in the zone you are in, else the nearest
--- the arrow can measure, else the first in a city. Logic/DemonSkills.lua
--- asks it for demon trainers.
function PetSkills.Nearest(trainers)
    local side = ns.Travel and ns.Travel.Side()
    local here = ns.BeastArrow and ns.BeastArrow:Here()
    local best, bestYards
    for _, trainer in ipairs(trainers) do
        if not side or trainer.side == side then
            if here and here.zone == trainer.zone then return trainer end
            local mapID = here and ns.Waypoints and ns.Waypoints:MapFor(trainer.zone)
            local north, west = mapID and ns.BeastArrow.Offset(here, mapID, trainer.x / 100, trainer.y / 100)
            if north then
                local yards = math.sqrt(north * north + west * west)
                if not bestYards or yards < bestYards then best, bestYards = trainer, yards end
            end
        end
    end
    if best then return best end
    for _, city in ipairs({ "Orgrimmar", "Stormwind City", "Ironforge", "Undercity", "Darnassus", "Teldrassil" }) do
        for _, trainer in ipairs(trainers) do
            if trainer.zone == city and (not side or trainer.side == side) then return trainer end
        end
    end
    for _, trainer in ipairs(trainers) do
        if not side or trainer.side == side then return trainer end
    end
    return nil
end

--- The nearest pet trainer of the player's side.
function PetSkills:Trainer()
    return PetSkills.Nearest(Data().TRAINERS)
end
