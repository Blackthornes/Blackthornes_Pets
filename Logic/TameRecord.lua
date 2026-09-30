-- Blackthornes Pets -- Logic/TameRecord.lua
-- Writes down what a beast really teaches on Forever, by watching the hunter
-- tame it.
--
-- A freshly tamed pet knows exactly the skills taming it teaches, so right
-- after Tame Beast lands the pet's action bar is the answer. This records the
-- beast's creature id, name and level with the skills on that bar, account
-- wide (it is about the world, not the character), and never overwrites a
-- beast already recorded with a shorter list. `/bpet tamed` prints what has
-- been recorded so it can be added to the addon's data for everyone.
--
-- The tooltip (Logic/Taming.lua) shows a recorded beast's skills ahead of the
-- Classic table's, because what the game showed beats what 1.12 said.

local _, ns = ...

local TameRecord = ns.NewModule("TameRecord")

-- Classic's Tame Beast. Matched by name too, in case Forever renumbered it.
local TAME_BEAST = 1515

-- How long after starting to tame the new pet may take to show up, seconds.
local WINDOW = 60

-- How long to let the pet's bar fill in once the pet is out, seconds.
local SETTLE = 1.5

local function Plain(value) return ns.PetStatus.Plain(value) end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g = pcall(fn, ...)
    if not ok then return nil end
    return Plain(a), Plain(b), Plain(c), Plain(d), Plain(e), Plain(f), Plain(g)
end

local function Now()
    return (type(GetTime) == "function" and GetTime()) or 0
end

local function SpellName(id)
    return Call(C_Spell and C_Spell.GetSpellName, id)
end

--- Is this spell Tame Beast?
function TameRecord:IsTameBeast(spellID)
    if spellID == TAME_BEAST then return true end
    local name = type(spellID) == "number" and SpellName(spellID)
    return name ~= nil and name == SpellName(TAME_BEAST)
end

local function Store()
    if not ns.db then return nil end
    if type(ns.db.tamedBeasts) ~= "table" then ns.db.tamedBeasts = {} end
    return ns.db.tamedBeasts
end

--- What has been recorded for a creature, or nil.
function TameRecord:Get(npcID)
    local store = ns.db and ns.db.tamedBeasts
    return type(store) == "table" and npcID and store[npcID] or nil
end

--------------------------------------------------------------------------------
-- Watching the tame
--------------------------------------------------------------------------------

--- Tame Beast has started: remember who is being tamed.
function TameRecord:OnCastStart(_, unit, _, spellID)
    if unit ~= "player" or not self:IsTameBeast(spellID) then return end
    local guid = Call(_G.UnitGUID, "target")
    local npcID = ns.Taming:NpcID(guid)
    if not npcID then return end
    self.pending = {
        npcID = npcID,
        name = Call(_G.UnitName, "target"),
        level = Call(_G.UnitLevel, "target"),
        at = Now(),
    }
end

--- The skills on the pet's action bar: { spell, name, rank } each, leaving
--- out Attack, Follow and the other commands the bar also carries.
function TameRecord:PetSkills()
    local skills = {}
    local getInfo = _G.GetPetActionInfo
    if type(getInfo) ~= "function" then return skills end
    for slot = 1, (_G.NUM_PET_ACTION_SLOTS or 10) do
        local name, _, isToken, _, _, _, spellID = Call(getInfo, slot)
        if name and not isToken and type(spellID) == "number" then
            local subtext = Call(C_Spell and C_Spell.GetSpellSubtext, spellID)
            local rank = type(subtext) == "string" and tonumber(subtext:match("(%d+)"))
            skills[#skills + 1] = {
                spell = spellID,
                name = SpellName(spellID) or name,
                rank = rank or 1,
            }
        end
    end
    table.sort(skills, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return a.rank < b.rank
    end)
    return skills
end

--- The new pet is out: write down what it came with.
-- @return the record, or nil if this was not a pet just tamed
function TameRecord:Capture()
    local pending = self.pending
    if not pending then return nil end
    if Now() - pending.at > WINDOW then
        self.pending = nil
        return nil
    end
    if Call(_G.UnitExists, "pet") ~= true then return nil end

    self.pending = nil
    local skills = self:PetSkills()
    local store = Store()
    if not store then return nil end

    local old = store[pending.npcID]
    if old and type(old.skills) == "table" and #old.skills > #skills then
        return old
    end

    local record = {
        name = pending.name,
        level = pending.level,
        skills = skills,
        seen = type(time) == "function" and time() or 0,
    }
    store[pending.npcID] = record
    ns.Print(("recorded what %s teaches: %s"):format(record.name or "the beast",
        #skills > 0 and self:SkillText(skills) or "nothing"))
    return record
end

function TameRecord:SkillText(skills)
    local parts = {}
    for i, skill in ipairs(skills) do
        parts[i] = ns.Taming.Label(skill)
    end
    return table.concat(parts, ", ")
end

function TameRecord:OnPet(_, unit)
    if unit and unit ~= "player" then return end
    if not self.pending then return end
    if C_Timer and C_Timer.After then
        C_Timer.After(SETTLE, function() TameRecord:Capture() end)
    else
        self:Capture()
    end
end

function TameRecord:OnEnable()
    -- Tame Beast is channelled on some clients and cast on others.
    for _, event in ipairs({ "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_START" }) do
        ns.RegisterEvent(self, event, self.OnCastStart)
    end
    ns.RegisterEvent(self, "UNIT_PET", self.OnPet)
end

--------------------------------------------------------------------------------
-- Reporting
--------------------------------------------------------------------------------

--- One line a recorded beast, in creature id order, ready to paste.
function TameRecord:Lines()
    local store = ns.db and ns.db.tamedBeasts
    local ids = {}
    if type(store) == "table" then
        for id in pairs(store) do ids[#ids + 1] = id end
    end
    table.sort(ids)
    local lines = {}
    for _, id in ipairs(ids) do
        local record = store[id]
        local spells = {}
        for i, skill in ipairs(record.skills or {}) do
            spells[i] = ("%s %d [%d]"):format(skill.name, skill.rank, skill.spell or 0)
        end
        lines[#lines + 1] = ("%d %s (%s): %s"):format(id, record.name or "?",
            tostring(record.level or "?"), #spells > 0 and table.concat(spells, ", ") or "nothing")
    end
    return lines
end

ns.RegisterCommand("tamed", "list the beasts you have tamed and what each taught", function()
    local lines = TameRecord:Lines()
    if #lines == 0 then
        ns.Print("no tamed beasts recorded yet. Tame one and it is written down.")
        return
    end
    ns.Print(("tamed beasts recorded (%d):"):format(#lines))
    for _, line in ipairs(lines) do ns.PrintRaw("  " .. line) end
end)
