-- Blackthornes Pets -- Logic/PetXP.lua
-- What the Pet XP bar shows (a player asked, the owner said build it from a
-- mockup, 2026-11-07): a hunter's pet's XP, what it gained this session,
-- XP an hour, about how long and how many kills to the next level.
--
-- Read only, inside a pcall: GetPetExperience (current, needed; 0, 0 for a
-- demon on Forever), UnitLevel and UnitName. The session lives in memory
-- only, one per pet name, so nothing new is saved here.

local _, ns = ...

local PetXP = ns.NewModule("PetXP")

-- XP an hour waits for this many seconds of a session, so one kill a few
-- seconds in does not read as a huge rate.
PetXP.MIN_SECONDS = 60

local function Plain(value)
    local P = ns.PetStatus and ns.PetStatus.Plain
    if P then return P(value) end
    return value
end

local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if not ok then return nil end
    return Plain(a), Plain(b)
end

local function Num(value)
    if type(value) == "number" then return value end
    return nil
end

local function Now()
    return (type(GetTime) == "function" and GetTime()) or 0
end

--- The pet's XP now, or nil when there is no hunter pet that earns any.
--- { name, level, xp, max, playerLevel, capped }
function PetXP:Read()
    local _, class = Call(UnitClass, "player")
    if class ~= nil and class ~= "HUNTER" then return nil end
    if Call(UnitExists, "pet") ~= true then return nil end
    local xp, max = Call(GetPetExperience)
    xp, max = Num(xp), Num(max)
    if not (xp and max and max > 0) then return nil end
    local name = Call(UnitName, "pet")
    if type(name) ~= "string" or name == "" then name = nil end
    local level = Num(Call(UnitLevel, "pet")) or 0
    local playerLevel = Num(Call(UnitLevel, "player")) or level
    return {
        name = name, level = level, xp = xp, max = max,
        playerLevel = playerLevel,
        capped = playerLevel > 0 and level >= playerLevel,
    }
end

--------------------------------------------------------------------------------
-- The session
--------------------------------------------------------------------------------

PetXP.sessions = {}

local function KeyOf(read)
    return read.name or "?"
end

--- The session for this pet, made when first seen.
function PetXP:Session(read)
    local key = KeyOf(read)
    local s = self.sessions[key]
    if not s then
        s = {
            started = Now(), startFraction = read.xp / read.max,
            startLevel = read.level, gained = 0, kills = 0, lastGain = nil,
            lastXP = read.xp, lastLevel = read.level, lastMax = read.max,
            levelStarted = nil,
        }
        self.sessions[key] = s
    end
    return s
end

--- Take a fresh read into its session. Returns the gain and whether the
--- pet went up a level (and the level it reached).
function PetXP:Update(read)
    if not read then return 0, false end
    local s = self:Session(read)
    local gain, leveled = 0, false
    if read.level > s.lastLevel then
        gain = math.max(0, (s.lastMax - s.lastXP)) + read.xp
        leveled = true
        s.lastLevelTook = s.levelStarted and (Now() - s.levelStarted) or nil
        s.levelStarted = Now()
        -- The white mark belongs to this level now.
        s.startFraction = 0
    elseif read.level == s.lastLevel and read.xp > s.lastXP then
        gain = read.xp - s.lastXP
    end
    if gain > 0 then
        s.gained = s.gained + gain
        s.kills = s.kills + 1
        s.lastGain = gain
    end
    s.lastXP, s.lastLevel, s.lastMax = read.xp, read.level, read.max
    return gain, leveled, s.lastLevelTook
end

--- Seconds this session has run.
function PetXP:Seconds(read)
    local s = self:Session(read)
    return math.max(0, Now() - s.started)
end

--- XP an hour, or nil until there is enough behind it.
function PetXP:PerHour(read)
    local s = self:Session(read)
    local seconds = self:Seconds(read)
    if s.gained <= 0 or seconds < self.MIN_SECONDS then return nil end
    return s.gained / (seconds / 3600)
end

--- XP still to go this level.
function PetXP:ToGo(read)
    return math.max(0, read.max - read.xp)
end

--- Whole minutes to the next level at this pace (at least 1), or nil.
function PetXP:MinutesLeft(read)
    local perHour = self:PerHour(read)
    if not perHour or perHour <= 0 then return nil end
    return math.max(1, math.ceil(self:ToGo(read) / perHour * 60))
end

--- Kills of what you fight now to the next level, or nil.
function PetXP:KillsLeft(read)
    local s = self:Session(read)
    if not (s.lastGain and s.lastGain > 0) then return nil end
    return math.max(1, math.ceil(self:ToGo(read) / s.lastGain))
end

--- Whole minutes, at least 1.
function PetXP.Minutes(seconds)
    return math.max(1, math.floor((seconds or 0) / 60 + 0.5))
end

--- Forget every session (tests).
function PetXP:Clear()
    self.sessions = {}
end
