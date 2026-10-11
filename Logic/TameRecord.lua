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

--- Is this spell Tame Beast? A spell id the client made secret is not: it
--- raises when compared, and every spell the player casts comes through here.
function TameRecord:IsTameBeast(spellID)
    spellID = Plain(spellID)
    if type(spellID) ~= "number" then return false end
    if spellID == TAME_BEAST then return true end
    local name = SpellName(spellID)
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
    if Plain(unit) ~= "player" or not self:IsTameBeast(spellID) then return end
    local guid = Call(_G.UnitGUID, "target")
    local npcID = ns.Taming:NpcID(guid)
    if not npcID then return end
    local zone, x, y = self:Where()
    self.pending = {
        npcID = npcID,
        name = Call(_G.UnitName, "target"),
        level = Call(_G.UnitLevel, "target"),
        zone = zone, x = x, y = y,
        at = Now(),
    }
end

--- The zone the hunter is in and their spot on its map (0-100), as the
--- beast's home for the Pet Compendium. Any of the three may be nil: inside
--- a dungeon the client gives no position, and a secret value is no answer.
function TameRecord:Where()
    local map = _G.C_Map
    if type(map) ~= "table" then return nil end
    local mapID = Call(map.GetBestMapForUnit, "player")
    if type(mapID) ~= "number" then return Call(_G.GetZoneText), nil, nil end

    local zone
    local info = Call(map.GetMapInfo, mapID)
    if type(info) == "table" then
        local ok, name = pcall(function() return info.name end)
        zone = ok and Plain(name) or nil
    end
    zone = zone or Call(_G.GetZoneText)

    local x, y
    local ok, px, py = pcall(function()
        local position = map.GetPlayerMapPosition(mapID, "player")
        if position then return position:GetXY() end
    end)
    px, py = Plain(px), Plain(py)
    if ok and type(px) == "number" and type(py) == "number" and (px > 0 or py > 0) then
        x = math.floor(px * 1000 + 0.5) / 10
        y = math.floor(py * 1000 + 0.5) / 10
    end
    if type(zone) ~= "string" or zone == "" then zone = nil end
    return zone, x, y
end

--- The creature id in the pet's GUID ("Pet-0-1-2-3-4512-...", or a
--- "Creature-" one), or nil when the client does not say.
local function PetNpcID()
    local guid = Call(_G.UnitGUID, "pet")
    if type(guid) ~= "string" then return nil end
    local kind, npc = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind == "Pet" or kind == "Creature" then return tonumber(npc) end
    return nil
end

--- Is the pet that is out the beast being tamed? A tame that failed leaves
--- `pending` behind, and the hunter's old pet called back within the minute
--- must not be written down as what that beast teaches. The pet's GUID names
--- its creature, which settles it; without one, a pet whose name and level
--- both differ from the beast's is another pet.
function TameRecord:IsTamedPet(pending)
    local npcID = PetNpcID()
    if npcID then return npcID == pending.npcID end
    local name = Call(_G.UnitName, "pet")
    local level = Call(_G.UnitLevel, "pet")
    local nameDiffers = type(name) == "string" and type(pending.name) == "string"
        and name ~= pending.name
    local levelDiffers = type(level) == "number" and type(pending.level) == "number"
        and level ~= pending.level
    return not (nameDiffers and levelDiffers)
end

--- Tame Beast was interrupted: forget the beast, so no later pet is taken
--- for it.
function TameRecord:OnCastFailed(_, unit, _, spellID)
    if Plain(unit) ~= "player" or not self:IsTameBeast(spellID) then return end
    self.pending = nil
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
    if not self:IsTamedPet(pending) then return nil end
    local skills = self:PetSkills()
    local store = Store()
    if not store then return nil end

    local old = store[pending.npcID]
    if old and type(old.skills) == "table" and #old.skills > #skills then
        -- Kept, but a record from before the Compendium learns where the
        -- beast lives and what it is.
        if not old.zone and pending.zone then
            old.zone, old.x, old.y = pending.zone, pending.x, pending.y
        end
        old.family = old.family or Call(_G.UnitCreatureFamily, "pet")
        old.speed = old.speed or self:PetSpeed()
        return old
    end

    local record = {
        name = pending.name,
        level = pending.level,
        skills = skills,
        seen = type(time) == "function" and time() or 0,
        -- Where it was tamed and what it is, for the Pet Compendium.
        family = Call(_G.UnitCreatureFamily, "pet"),
        zone = pending.zone, x = pending.x, y = pending.y,
        -- Seconds between its melee swings, read off the real pet: the
        -- compendium's Speed column trusts it over Classic's number.
        speed = self:PetSpeed(),
    }
    store[pending.npcID] = record
    if ns.Compendium then ns.Compendium:Invalidate() end
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

--- The pet's melee speed, seconds between swings to two places, or nil
--- when the client will not say. Read out of combat only, where a haste
--- effect is least likely to be on it.
function TameRecord:PetSpeed()
    local locked = Call(_G.InCombatLockdown)
    if locked == true then return nil end
    local speed = Call(_G.UnitAttackSpeed, "pet")
    if type(speed) ~= "number" or speed <= 0 or speed > 10 then return nil end
    return math.floor(speed * 100 + 0.5) / 100
end

--- A pet tamed before speeds were kept: when it is called out, its speed
--- is added to its record. Once per pet; nothing is ever taken away.
function TameRecord:NoteSpeed()
    local npcID = PetNpcID()
    local record = npcID and self:Get(npcID)
    if type(record) ~= "table" or record.speed then return nil end
    local speed = self:PetSpeed()
    if not speed then return nil end
    record.speed = speed
    if ns.Compendium then ns.Compendium:Invalidate() end
    return speed
end

function TameRecord:OnPet(_, unit)
    if unit and unit ~= "player" then return end
    local after = self.pending and function() TameRecord:Capture() end
        or function() TameRecord:NoteSpeed() end
    if C_Timer and C_Timer.After then
        C_Timer.After(SETTLE, after)
    else
        after()
    end
end

function TameRecord:OnEnable()
    -- Tame Beast is channelled on some clients and cast on others.
    for _, event in ipairs({ "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_START" }) do
        ns.RegisterPetEvent(self, event, self.OnCastStart)
    end
    -- Not UNIT_SPELLCAST_FAILED: pressing Tame Beast again mid-tame fails
    -- that press, while the tame itself carries on.
    ns.RegisterPetEvent(self, "UNIT_SPELLCAST_INTERRUPTED", self.OnCastFailed)
    ns.RegisterPetEvent(self, "UNIT_PET", self.OnPet)
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
        local where = ""
        if record.zone then
            where = record.x and (" in %s %.1f, %.1f"):format(record.zone, record.x, record.y)
                or (" in %s"):format(record.zone)
        end
        if type(record.speed) == "number" then where = where .. (", %.2f speed"):format(record.speed) end
        lines[#lines + 1] = ("%d %s (%s)%s%s: %s"):format(id, record.name or "?",
            tostring(record.level or "?"), record.family and (", " .. record.family) or "", where,
            #spells > 0 and table.concat(spells, ", ") or "nothing")
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
