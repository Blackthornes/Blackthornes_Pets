-- Blackthornes Pets -- Logic/Compendium.lua
-- Every beast a hunter can tame: what it is, where it lives, what taming it
-- teaches, and what WoW: Forever has shown that Classic did not.
--
-- Three layers, the later winning, because what the Forever client showed
-- beats what 1.12 said:
--
--   1. Classic (Data/Compendium.lua): every tameable beast of patch 1.12.
--   2. Forever, shipped (Data/ForeverBeasts.lua): where beasts were seen on
--      Forever (SEEN, by name), beasts tamed there (TAMED, by creature id)
--      and new beasts a Forever source names (FOUND).
--   3. This account's own tames (Logic/TameRecord.lua, `tamedBeasts`).
--
-- A field nothing knows stays empty; nothing here guesses.

local _, ns = ...

local Compendium = ns.NewModule("Compendium")

local function Plain(value) return ns.PetStatus.Plain(value) end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return Plain(a), Plain(b)
end

-- Forever's (and later clients') names for a Classic family.
local FAMILY_NAMES = { ["Bird of Prey"] = "Owl" }

--- A family id or name as { name, diet }; diet is nil for a family Classic
--- did not have.
local function Family(family)
    local data = ns.CompendiumData
    if type(family) == "number" then
        local known = data and data.FAMILIES[family]
        if known then return known[1], known[2] end
        return nil
    end
    if type(family) == "string" and family ~= "" then
        family = FAMILY_NAMES[family] or family
        for _, known in pairs(data and data.FAMILIES or {}) do
            if known[1] == family then return known[1], known[2] end
        end
        return family
    end
    return nil
end

--- Lay a Forever spot over an entry, keeping what Classic said beside it.
local function Overlay(entry, spot, why)
    if type(spot) ~= "table" then return end
    if spot.zone and spot.zone ~= entry.zone or spot.x then
        entry.classic = entry.classic or {
            zone = entry.zone, x = entry.x, y = entry.y, min = entry.min, max = entry.max,
        }
    end
    if spot.zone then
        entry.zone, entry.x, entry.y = spot.zone, spot.x, spot.y
        entry.instance = nil
    end
    if spot.min then entry.min = spot.min end
    if spot.max then entry.max = spot.max end
    if spot.level and not spot.min then
        entry.min = math.min(entry.min or spot.level, spot.level)
        entry.max = math.max(entry.max or spot.level, spot.level)
    end
    -- A speed read off a real tamed pet beats Classic's number.
    if type(spot.speed) == "number" and spot.speed > 0 then
        if entry.classicSpeed == nil and not entry.speedSeen then entry.classicSpeed = entry.speed end
        entry.speed, entry.speedSeen = spot.speed, true
    end
    entry.forever = entry.forever or why
end

--- A beast tamed on Forever, as an entry of its own: one Classic never had.
local function TamedEntry(id, record, why)
    local family, diet = Family(record.family)
    return {
        id = id, name = record.name or ("Beast " .. id), family = family, diet = diet,
        min = record.level, max = record.level,
        zone = record.zone, x = record.x, y = record.y,
        speed = type(record.speed) == "number" and record.speed or nil,
        speedSeen = type(record.speed) == "number" or nil,
        forever = why,
    }
end

--- Every beast, built once (and again when the player tames something).
function Compendium:All()
    if self.entries then return self.entries end

    local data = ns.CompendiumData
    local forever = ns.ForeverBeasts or {}
    local entries, byID, byName = {}, {}, {}

    for id, beast in pairs(data and data.BEASTS or {}) do
        local family, diet = Family(beast.family)
        local entry = {
            id = id, name = beast.name, family = family, diet = diet,
            min = beast.min, max = beast.max, rank = beast.rank,
            zone = beast.zone, x = beast.x, y = beast.y, instance = beast.instance,
            also = beast.also, spawns = beast.spawns, respawn = beast.respawn,
            speed = beast.speed,
        }
        entries[#entries + 1] = entry
        byID[id] = entry
        byName[beast.name] = byName[beast.name] or entry
    end

    -- Seen on Forever: by name, since the harvest that saw them keeps no ids.
    for name, spot in pairs(forever.SEEN or {}) do
        local entry = byName[name]
        if entry then Overlay(entry, spot, "seen") end
    end

    -- New beasts a Forever source names.
    for _, found in ipairs(forever.FOUND or {}) do
        -- By id when the source gives one: Forever reuses Classic names for
        -- new creatures (a second Galestrider, a Greater Tarantula of its own).
        local entry
        if found.id then entry = byID[found.id] else entry = byName[found.name] end
        if entry then
            Overlay(entry, found, "found")
            entry.source = found.source
            entry.rank = entry.rank or found.rank
            entry.respawn = entry.respawn or found.respawn
        else
            local family, diet = Family(found.family)
            entry = {
                id = found.id, name = found.name, family = family, diet = diet,
                min = found.min, max = found.max, rank = found.rank,
                zone = found.zone, x = found.x, y = found.y, respawn = found.respawn,
                source = found.source, forever = "found",
            }
            entries[#entries + 1] = entry
            if found.id then byID[found.id] = entry end
            byName[found.name] = byName[found.name] or entry
        end
        -- Skills a Forever source says it teaches, beside Classic's.
        if found.skills then entry.foreverSkills = found.skills end
    end

    -- Tamed on Forever: shipped first, then this account's own.
    local function AddTamed(store, why)
        for id, record in pairs(store or {}) do
            if type(id) == "number" and type(record) == "table" then
                local entry = byID[id]
                if entry then
                    Overlay(entry, record, why)
                    if record.family and not entry.family then
                        entry.family, entry.diet = Family(record.family)
                    end
                else
                    entry = TamedEntry(id, record, why)
                    entries[#entries + 1] = entry
                    byID[id] = entry
                end
            end
        end
    end
    AddTamed(forever.TAMED, "tamed")
    AddTamed(ns.db and ns.db.tamedBeasts, "mine")

    self.entries, self.byID = entries, byID
    return entries
end

--- Forget the built list, so the next look takes in a new tame.
function Compendium:Invalidate()
    self.entries, self.byID = nil, nil
end

function Compendium:Get(id)
    self:All()
    return self.byID[id]
end

--- What taming the beast teaches: { name, rank, teach } each.
function Compendium:Skills(entry)
    local skills = entry.id and ns.Taming:SkillsFor(entry.id) or {}
    local out, have = {}, {}
    for _, skill in ipairs(skills) do
        out[#out + 1] = skill
        have[skill.name .. "#" .. skill.rank] = true
    end
    -- A tame seen on Forever is the whole answer; a source's word adds to
    -- Classic's list.
    local tamed = skills[1] and skills[1].seen
    for _, skill in ipairs(not tamed and entry.foreverSkills or {}) do
        if not have[skill.name .. "#" .. skill.rank] then
            have[skill.name .. "#" .. skill.rank] = true
            out[#out + 1] = { name = skill.name, rank = skill.rank, forever = true }
        end
    end
    return out
end

--- The family names there are, sorted, for the family chooser.
function Compendium:Families()
    local seen, out = {}, {}
    for _, entry in ipairs(self:All()) do
        if entry.family and not seen[entry.family] then
            seen[entry.family] = true
            out[#out + 1] = entry.family
        end
    end
    table.sort(out)
    return out
end

--- The hunter's level, or nil when it cannot be read.
function Compendium:PlayerLevel()
    local level = Call(_G.UnitLevel, "player")
    if type(level) == "number" and level > 0 then return level end
    return nil
end

--- Can a hunter of this level tame it? A hunter tames beasts up to their own
--- level. nil when either level is unknown.
function Compendium:CanTame(entry, level)
    level = level or self:PlayerLevel()
    if not (level and entry.min) then return nil end
    return entry.min <= level
end

--- Does taming it teach a skill this hunter has not got?
function Compendium:TeachesNew(entry)
    for _, skill in ipairs(self:Skills(entry)) do
        if ns.Taming:Knows(skill) == false then return true end
    end
    return false
end

local function Lower(text) return type(text) == "string" and text:lower() or "" end

--- Does the search text match the beast's name, family, zone or a skill?
function Compendium:Matches(entry, text)
    text = Lower(text)
    if text == "" then return true end
    local plain = function(value) return Lower(value):find(text, 1, true) ~= nil end
    if plain(entry.name) or plain(entry.family) or plain(entry.zone) then return true end
    if entry.family == "Owl" and plain("Bird of Prey") then return true end
    for _, zone in ipairs(entry.also or {}) do
        if plain(zone) then return true end
    end
    for _, skill in ipairs(self:Skills(entry)) do
        if plain(skill.name) then return true end
    end
    return false
end

local RANK_ORDER = { rareelite = 1, rare = 2, elite = 3 }

local SORTS = {
    name = function(a, b) return a.name < b.name end,
    family = function(a, b)
        if (a.family or "") ~= (b.family or "") then return (a.family or "~") < (b.family or "~") end
        return nil
    end,
    level = function(a, b)
        if (a.min or 999) ~= (b.min or 999) then return (a.min or 999) < (b.min or 999) end
        return nil
    end,
    zone = function(a, b)
        if (a.zone or "") ~= (b.zone or "") then return (a.zone or "~") < (b.zone or "~") end
        return nil
    end,
    -- Fastest first within each family, so the top of each family's run
    -- is the quickest pet of that kind.
    speed = function(a, b, descending)
        if (a.family or "~") ~= (b.family or "~") then
            local before = (a.family or "~") < (b.family or "~")
            if descending then return not before end
            return before
        end
        if a.speed ~= b.speed then return a.speed < b.speed end
        return nil
    end,
    rank = function(a, b)
        local ra, rb = RANK_ORDER[a.rank] or 9, RANK_ORDER[b.rank] or 9
        if ra ~= rb then return ra < rb end
        return nil
    end,
}
Compendium.SORT_KEYS = { "name", "family", "level", "zone", "rank", "speed" }

--- The beasts that pass `filter`, sorted.
-- filter: family (a name or nil), text, tameNow, raresOnly, newSkills,
-- foreverOnly, sort (a key of SORTS), descending.
function Compendium:List(filter)
    filter = filter or {}
    local level = self:PlayerLevel()
    local out = {}
    for _, entry in ipairs(self:All()) do
        local keep = (not filter.family or entry.family == filter.family)
            and (not filter.tameNow or self:CanTame(entry, level) ~= false)
            and (not filter.raresOnly or entry.rank == "rare" or entry.rank == "rareelite")
            and (not filter.foreverOnly or entry.forever ~= nil)
            and self:Matches(entry, filter.text)
            and (not filter.newSkills or self:TeachesNew(entry))
        if keep then out[#out + 1] = entry end
    end

    local first = SORTS[filter.sort] or SORTS.name
    local descending = filter.descending
    -- What a beast lacks for the sort, it goes last for, either way round
    -- (for speed, last in its family).
    local field = ({ level = "min", family = "family", zone = "zone", rank = "rank",
        speed = "speed" })[filter.sort]
    table.sort(out, function(a, b)
        if field and (a[field] == nil) ~= (b[field] == nil)
            and (filter.sort ~= "speed" or a.family == b.family) then
            return b[field] == nil
        end
        local x, y = a, b
        if descending then x, y = b, a end
        -- Speed keeps the families in name order either way round; only the
        -- order within each family turns.
        local result = first(x, y, descending)
        if result ~= nil then return result end
        if (a.min or 999) ~= (b.min or 999) then return (a.min or 999) < (b.min or 999) end
        if a.name ~= b.name then return a.name < b.name end
        return (a.id or 0) < (b.id or 0)
    end)
    return out
end

--------------------------------------------------------------------------------
-- Words
--------------------------------------------------------------------------------

function Compendium.LevelText(entry)
    if not entry.min then return "" end
    if entry.max and entry.max ~= entry.min then return ("%d-%d"):format(entry.min, entry.max) end
    return tostring(entry.min)
end

local RANK_WORDS = { rare = "Rare", rareelite = "Rare elite", elite = "Elite" }
function Compendium.RankText(entry) return RANK_WORDS[entry.rank] end

--- "2 hours", "45 minutes", "2-4 hours".
local function Span(seconds)
    if seconds >= 5400 then return math.floor(seconds / 3600 + 0.5), "hours" end
    return math.max(1, math.floor(seconds / 60 + 0.5)), "minutes"
end

function Compendium.RespawnText(entry)
    local respawn = entry.respawn
    if type(respawn) ~= "table" or not respawn[1] then return nil end
    local low, unitLow = Span(respawn[1])
    local high, unitHigh = Span(respawn[2] or respawn[1])
    if low == high and unitLow == unitHigh then return ("%d %s"):format(low, unitLow) end
    if unitLow == unitHigh then return ("%d-%d %s"):format(low, high, unitHigh) end
    return ("%d %s to %d %s"):format(low, unitLow, high, unitHigh)
end

--- "1.2", "1.25", "2.0": seconds between swings, as players write them.
function Compendium.SpeedText(entry)
    if type(entry.speed) ~= "number" then return nil end
    local text = ("%.2f"):format(entry.speed):gsub("0$", "")
    return text
end

--- "Duskwood 32.6, 25.8", "Wailing Caverns (dungeon)" or just the zone.
function Compendium.PlaceText(entry)
    if not entry.zone then return "" end
    if entry.x and entry.y then return ("%s %.1f, %.1f"):format(entry.zone, entry.x, entry.y) end
    if entry.instance then return ("%s (%s)"):format(entry.zone, entry.instance) end
    return entry.zone
end

local WHY = {
    seen = "Seen on Forever",
    tamed = "Tamed on Forever",
    found = "Found on Forever",
    mine = "You tamed it on Forever",
}
function Compendium.ForeverText(entry) return entry.forever and WHY[entry.forever] end

--------------------------------------------------------------------------------
-- Map
--------------------------------------------------------------------------------

--- Put the game's map pin on where the beast lives.
function Compendium:Pin(entry)
    if not ns.Waypoints then return false end
    return ns.Waypoints:Show({ zone = entry.zone, x = entry.x, y = entry.y }, entry.name)
end
