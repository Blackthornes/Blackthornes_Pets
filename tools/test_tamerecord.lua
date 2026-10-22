-- Recording what a beast teaches on Forever by watching the hunter tame it:
-- only a pet that was just tamed is written down, the commands on the pet bar
-- are left out, a shorter list never replaces a longer one, and the tooltip
-- then answers from the record.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("tamerecord")

local ns = env.Load()
local Record, Taming = ns.TameRecord, ns.Taming

local clock = 100
_G.GetTime = function() return clock end
_G.C_Spell = {
    GetSpellName = function(id)
        return ({ [1515] = "Tame Beast", [133] = "Fireball", [26177] = "Charge", [99999] = "Swipe" })[id]
    end,
    GetSpellSubtext = function(id)
        return ({ [26177] = "Rank 2", [99999] = "Rank 1" })[id]
    end,
}
local target = { guid = "Creature-0-1-2-3-4512-00001", name = "Rabid Crag Boar", level = 12 }
_G.UnitGUID = function(unit) if unit == "target" then return target.guid end end
_G.UnitName = function(unit) if unit == "target" then return target.name end end
_G.UnitLevel = function(unit) if unit == "target" then return target.level end end
local petOut = false
_G.UnitExists = function(unit) return unit == "pet" and petOut end
local bar = {
    { "Attack", nil, true },
    { "Follow", nil, true },
    { "Charge", nil, false, false, true, false, 26177 },
    { "Swipe", nil, false, false, true, false, 99999 },
}
_G.GetPetActionInfo = function(slot)
    local entry = bar[slot]
    if entry then return unpack(entry, 1, 7) end
end

suite.check("Tame Beast is known by its id", Record:IsTameBeast(1515))
suite.check("another spell is not it", not Record:IsTameBeast(133))

-- A spell id the client made secret raises when compared; it is not Tame
-- Beast, and casting it records nothing.
local secretSpell = newproxy(true)
getmetatable(secretSpell).__tostring = function(self) return self end
getmetatable(secretSpell).__eq = function() error("secret value") end
getmetatable(secretSpell).__lt = function() error("secret value") end
suite.check("a secret spell id is not Tame Beast", Record:IsTameBeast(secretSpell) == false)
Record:OnCastStart("UNIT_SPELLCAST_START", "player", "cast", secretSpell)
suite.check("and casting it remembers nothing", Record.pending == nil)

-- A pet showing up without a tame (called back, say) is not recorded.
petOut = true
suite.check("a pet that was not just tamed is not recorded", Record:Capture() == nil)

Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
suite.check("taming remembers the beast", Record.pending and Record.pending.npcID == 4512)
local rec = Record:Capture()
suite.check("the new pet's skills are recorded", rec and #rec.skills == 2, rec and #rec.skills)
suite.check("without the pet bar's commands",
    rec.skills[1].name == "Charge" and rec.skills[1].rank == 2 and rec.skills[2].name == "Swipe")
suite.check("with the beast's name and level", rec.name == "Rabid Crag Boar" and rec.level == 12)
suite.check("saved for the whole account", ns.db.tamedBeasts[4512] == rec)
suite.check("and said in chat", env.ChatText():find("noted what Rabid Crag Boar teaches: Charge (Rank 2), Swipe (Rank 1)", 1, true), env.ChatText())

-- A client that gives no rank text: a skill Classic knows keeps Classic's rank.
target.guid = "Creature-0-1-2-3-4517-00001"
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
local fullBar = bar
bar = { { "Bite", nil, false, false, true, false, 17255 } }
local noRank = Record:Capture()
suite.check("a known skill with no rank text keeps Classic's rank",
    noRank and noRank.skills[1].rank == 2, noRank and noRank.skills[1].rank)
bar = fullBar
ns.db.tamedBeasts[4517] = nil
target.guid = "Creature-0-1-2-3-4512-00001"

-- A later tame whose bar has not filled in does not wipe the list.
Record:OnCastStart("UNIT_SPELLCAST_START", "player", "cast", 1515)
local saved = bar
bar = {}
Record:Capture()
suite.check("a shorter list never replaces a longer one", #ns.db.tamedBeasts[4512].skills == 2)
bar = saved

-- Too long between starting to tame and the pet showing up.
target.guid = "Creature-0-1-2-3-4513-00001"
Record:OnCastStart("UNIT_SPELLCAST_START", "player", "cast", 1515)
clock = clock + 120
suite.check("a pet long after the tame is not recorded", Record:Capture() == nil and not ns.db.tamedBeasts[4513])

-- Another player's cast, or another spell.
Record:OnCastStart("UNIT_SPELLCAST_START", "party1", "cast", 1515)
suite.check("someone else's tame is ignored", Record.pending == nil)
Record:OnCastStart("UNIT_SPELLCAST_START", "player", "cast", 133)
suite.check("another spell is ignored", Record.pending == nil)

-- A tame that failed, then the old pet called back within the minute: the
-- old pet's skills are not the beast's. Its GUID names another creature.
local pet = {}
_G.UnitGUID = function(unit)
    if unit == "target" then return target.guid end
    if unit == "pet" then return pet.guid end
end
_G.UnitName = function(unit)
    if unit == "target" then return target.name end
    if unit == "pet" then return pet.name end
end
_G.UnitLevel = function(unit)
    if unit == "target" then return target.level end
    if unit == "pet" then return pet.level end
end
clock = 200
target.guid, target.name, target.level = "Creature-0-1-2-3-4514-00001", "Ashmane Boar", 13
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
pet.guid, pet.name, pet.level = "Pet-0-1-2-3-3099-0000ABCD", "Fang", 20
suite.check("a pet called back after a failed tame is not recorded",
    Record:Capture() == nil and not ns.db.tamedBeasts[4514])
suite.check("and the failed tame is let go", Record.pending == nil)

-- With no GUID to go on, a pet whose name and level both differ is another pet.
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
pet.guid = nil
suite.check("nor one whose name and level are another pet's",
    Record:Capture() == nil and not ns.db.tamedBeasts[4514])

-- An interrupted tame is forgotten at once.
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
Record:OnCastFailed("UNIT_SPELLCAST_INTERRUPTED", "player", "cast", 1515)
suite.check("an interrupted tame is forgotten", Record.pending == nil)
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
Record:OnCastFailed("UNIT_SPELLCAST_INTERRUPTED", "player", "cast", 133)
suite.check("another spell's interruption does not touch it", Record.pending ~= nil)

-- The beast itself, its GUID now a pet's, is recorded.
pet.guid, pet.name, pet.level = "Pet-0-1-2-3-4514-0000ABCE", "Ashmane Boar", 13
local tamed = Record:Capture()
suite.check("the tamed beast is recorded by its pet GUID",
    tamed and ns.db.tamedBeasts[4514] == tamed)
-- And with no GUID, the same name is enough.
target.guid = "Creature-0-1-2-3-4515-00001"
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
pet.guid, pet.level = nil, 99
suite.check("without a GUID the beast's name is enough",
    Record:Capture() ~= nil and ns.db.tamedBeasts[4515] ~= nil)
ns.db.tamedBeasts[4514], ns.db.tamedBeasts[4515] = nil, nil

-- The beast arrow was following the beast just tamed: it is put away.
ns.charDB.arrowBeast = 9999
target.guid, target.name = "Creature-0-1-2-3-4516-00001", "Broken Tooth"
pet.guid, pet.name = nil, "Broken Tooth"
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
Record:Capture()
suite.check("an arrow following another beast keeps it", ns.charDB.arrowBeast == 9999)
ns.charDB.arrowBeast = 4516
Record:OnCastStart("UNIT_SPELLCAST_CHANNEL_START", "player", "cast", 1515)
Record:Capture()
suite.check("taming the beast it follows puts the arrow away", ns.charDB.arrowBeast == nil)
suite.check("and says so", env.ChatText():find("tamed Broken Tooth, so the arrow is put away.", 1, true), env.ChatText())
ns.db.tamedBeasts[4516] = nil

-- The tooltip answers from the record, and finds Classic's teach spell.
local skills = Taming:SkillsFor(4512)
suite.check("a recorded beast's skills come from the record",
    #skills == 2 and skills[1].seen and skills[1].teach == 26184, skills[1] and skills[1].teach)
suite.check("a skill new to Forever has no Classic teach spell", skills[2].teach == nil)
_G.IsPlayerSpell = function() return false end
suite.check("but Beast Training lists its rank, so the spell check is asked", Taming:Knows(skills[2]) == false)
_G.IsPlayerSpell = nil

-- The report.
env.chat = {}
ns.HandleSlash("tamed")
local text = env.ChatText()
suite.check("/bpet tamed lists what was recorded",
    text:find("4512 Rabid Crag Boar (12): Charge 2 [26177], Swipe 1 [99999]", 1, true), text)
ns.db.tamedBeasts = nil
env.chat = {}
ns.HandleSlash("tamed")
suite.check("and says so when there is nothing", env.ChatText():find("no tamed beasts yet", 1, true))

_G.GetTime, _G.C_Spell, _G.UnitGUID, _G.UnitName, _G.UnitLevel = nil, nil, nil, nil, nil
_G.UnitExists, _G.GetPetActionInfo = nil, nil

suite.done()
