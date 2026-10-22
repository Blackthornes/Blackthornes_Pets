-- Blackthornes Pets -- Logic/Taming.lua
-- Which pet skills taming a beast would teach, and which of them the hunter
-- already knows.
--
-- What a beast teaches comes from Data/BeastSkills.lua, by the creature id in
-- its GUID. What the hunter knows is asked two ways, because the probe has
-- not yet shown which one Forever answers:
--
--   * the spell the hunter learns for each skill (`teach` in the data), asked
--     with IsPlayerSpell and IsSpellKnown;
--   * the Beast Training window, read whenever it opens and remembered per
--     character, since it lists every skill the hunter can teach.
--
-- Either one saying yes is enough. Until the window has been read once, a no
-- from the spell check is only as good as that check, so the tooltip says so.

local _, ns = ...
local L = ns.L

local Taming = ns.NewModule("Taming")

local function Plain(value) return ns.PetStatus.Plain(value) end

local function Resolve(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return nil end
        value = value[part]
    end
    if type(value) == "function" then return value end
    return nil
end

--- Call a global inside a pcall; nil if it is absent, raises or is secret.
local function Call(path, ...)
    local fn = Resolve(path)
    if not fn then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then return nil end
    return Plain(a), Plain(b), Plain(c)
end

--- "Bite (Rank 3)", the way the game writes it.
function Taming.Label(skill)
    return L.Format("%s (Rank %d)", skill.name, skill.rank)
end

local function Key(name, rank)
    return name .. "#" .. rank
end

--------------------------------------------------------------------------------
-- Beasts
--------------------------------------------------------------------------------

--- The creature id in a GUID ("Creature-0-1-2-3-3099-000..."), or nil for a
--- player, a pet, a secret GUID or anything else.
function Taming:NpcID(guid)
    guid = Plain(guid)
    if type(guid) ~= "string" then return nil end
    local ok, id = pcall(function()
        local kind, npc = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
        if kind == "Creature" then return tonumber(npc) end
        return nil
    end)
    return ok and id or nil
end

--- The client's name for each skill, in its own language, to the English
--- name the data uses: read off the spells' IDs (the pet's spell and the
--- one the hunter learns), once, when first asked. A client that names no
--- spell yet is asked again, a few times at most.
local NAME_TRIES = 3

function Taming:SkillNames()
    if self.skillNames then return self.skillNames end
    local names, any = {}, false
    local canAsk = Resolve("C_Spell.GetSpellName") ~= nil
    for spell, skill in pairs(ns.BeastSkills.SKILLS) do
        names[skill.name] = skill.name
        for _, id in ipairs(canAsk and { spell, skill.teach } or {}) do
            local name = Call("C_Spell.GetSpellName", id)
            if type(name) == "string" and name ~= "" then
                any = true
                names[name] = names[name] or skill.name
            end
        end
    end
    self.skillNameTries = (self.skillNameTries or 0) + 1
    if any or not canAsk or self.skillNameTries >= NAME_TRIES then self.skillNames = names end
    return names
end

--- The data's English name for a skill named by the client ("Beißen" on a
--- German one), or the name itself when nothing matches.
function Taming:EnglishName(name)
    if type(name) ~= "string" then return name end
    return self:SkillNames()[name] or name
end

--- The Classic skill of this name and rank, for the spell a hunter learns.
local function ClassicSkill(name, rank)
    name = Taming:EnglishName(name)
    for _, skill in pairs(ns.BeastSkills.SKILLS) do
        if skill.name == name and skill.rank == rank then return skill end
    end
    return nil
end

--- The skills taming this creature teaches; an empty list when it teaches
--- none or is not a beast we know. A beast this account has tamed on Forever
--- (Logic/TameRecord.lua), or one shipped as tamed there
--- (Data/ForeverBeasts.lua), is answered from what the game showed then,
--- ahead of the Classic table.
function Taming:SkillsFor(npcID)
    local out = {}
    local tamed = ns.TameRecord and ns.TameRecord:Get(npcID)
    if not (tamed and type(tamed.skills) == "table") then
        tamed = ns.ForeverBeasts and npcID and ns.ForeverBeasts.TAMED[npcID]
    end
    if tamed and type(tamed.skills) == "table" then
        for _, skill in ipairs(tamed.skills) do
            local classic = ClassicSkill(skill.name, skill.rank)
            out[#out + 1] = {
                name = skill.name, rank = skill.rank,
                teach = classic and classic.teach, seen = true,
            }
        end
        return out
    end

    local data = ns.BeastSkills
    local list = data and npcID and data.BEASTS[npcID]
    if not list then return out end
    for _, spell in ipairs(list) do
        local skill = data.SKILLS[spell]
        if skill then out[#out + 1] = skill end
    end
    return out
end

--------------------------------------------------------------------------------
-- What the hunter knows
--------------------------------------------------------------------------------

local function Record()
    if not ns.charDB then return nil end
    local record = ns.charDB.beastTraining
    if type(record) ~= "table" then return nil end
    if type(record.known) ~= "table" then record.known = {} end
    return record
end

--- Has the Beast Training window been read on this character?
function Taming:HasRecord()
    local record = Record()
    return record ~= nil and record.readAt ~= nil
end

--- The spell the hunter learns for each rank of each skill, by the data's
--- English name: { [name] = { [rank] = teach } }. Laid out once.
function Taming:Ranks()
    if self.ranks then return self.ranks end
    local ranks = {}
    for _, skill in pairs(ns.BeastSkills.SKILLS) do
        ranks[skill.name] = ranks[skill.name] or {}
        ranks[skill.name][skill.rank] = skill.teach
    end
    self.ranks = ranks
    return ranks
end

--- true, false, or nil when nothing can say. A rank counts as known when it
--- or a higher rank of the same skill is: the game stops calling a lower
--- rank known once the next one is learned. The same name and rank always
--- gets the same answer, whatever list it came from.
function Taming:Knows(skill)
    local name = self:EnglishName(skill.name)
    local rank = tonumber(skill.rank) or 1
    local record = Record()
    if record then
        for key in pairs(record.known) do
            local knownName, knownRank = key:match("^(.-)#(%d+)$")
            if knownName == name and tonumber(knownRank) >= rank then return true end
        end
    end

    local teaches = {}
    for r, teach in pairs(self:Ranks()[name] or {}) do
        if r >= rank then teaches[#teaches + 1] = teach end
    end
    if skill.teach and #teaches == 0 then teaches[1] = skill.teach end

    local spellSays
    for _, teach in ipairs(teaches) do
        for _, api in ipairs({ "IsPlayerSpell", "IsSpellKnown" }) do
            local known = Call(api, teach)
            if known == true then return true end
            if known == false then spellSays = false end
        end
    end

    if record and record.readAt then return false end
    return spellSays
end

--- Read the Beast Training window, if that is what the craft window shows,
--- and remember every skill in it. Adds to what is saved, never takes away:
--- a hunter does not forget a skill.
-- @return how many skills it read, or nil if the window was not readable
function Taming:ReadBeastTraining()
    local count = Call("GetNumCrafts")
    if type(count) ~= "number" or count < 1 then return nil end

    -- The window names skills in the client's language: kept by the
    -- data's English name.
    local names = self:SkillNames()

    local found = {}
    for i = 1, count do
        local name, subText, kind = Call("GetCraftInfo", i)
        local english = type(name) == "string" and names[name]
        if english and kind ~= "header" then
            local rank = type(subText) == "string" and tonumber(subText:match("(%d+)"))
            if rank then found[#found + 1] = Key(english, rank) end
        end
    end
    -- An enchanting window, or a pet with nothing learned: not ours to read.
    if #found == 0 then return nil end

    if type(ns.charDB.beastTraining) ~= "table" then ns.charDB.beastTraining = {} end
    local record = Record()
    for _, key in ipairs(found) do record.known[key] = true end
    record.readAt = time and time() or 0
    return #found
end

function Taming:OnCraftWindow()
    local read = self:ReadBeastTraining()
    if read then ns.Debug("Beast Training read:", read, "skills") end
end

function Taming:OnEnable()
    -- The classic craft window's events; either may be unknown to Forever.
    for _, event in ipairs({ "CRAFT_SHOW", "CRAFT_UPDATE" }) do
        ns.RegisterEvent(self, event, self.OnCraftWindow)
    end
end

--- Every skill the hunter is known to have, "Bite (Rank 1)" style, sorted.
function Taming:KnownList()
    local seen, out = {}, {}
    for _, skill in pairs(ns.BeastSkills.SKILLS) do
        local label = Taming.Label(skill)
        if not seen[label] and self:Knows(skill) then
            seen[label] = true
            out[#out + 1] = label
        end
    end
    table.sort(out)
    return out
end

ns.RegisterCommand("taming", L["list the pet skills this hunter knows"], function()
    local known = Taming:KnownList()
    if #known == 0 then
        ns.Print(L["no pet skills known yet. Open Beast Training once so Pets can read the list."])
    else
        ns.Print(L.Format("pet skills known (%d): %s", #known, table.concat(known, ", ")))
    end
    if not Taming:HasRecord() then
        ns.PrintRaw(("  |c%s%s|r"):format(ns.COLORS.muted,
            L["You haven't opened Beast Training on this character yet."]))
    end
end)
