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
suite.check("and said in chat", env.ChatText():find("recorded what Rabid Crag Boar teaches: Charge (Rank 2), Swipe (Rank 1)", 1, true), env.ChatText())

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

-- The tooltip answers from the record, and finds Classic's teach spell.
local skills = Taming:SkillsFor(4512)
suite.check("a recorded beast's skills come from the record",
    #skills == 2 and skills[1].seen and skills[1].teach == 26184, skills[1] and skills[1].teach)
suite.check("a skill new to Forever has no Classic teach spell", skills[2].teach == nil)
_G.IsPlayerSpell = function() return false end
suite.check("and the spell check is not asked about it", Taming:Knows(skills[2]) == nil)
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
suite.check("and says so when there is nothing", env.ChatText():find("no tamed beasts recorded yet", 1, true))

_G.GetTime, _G.C_Spell, _G.UnitGUID, _G.UnitName, _G.UnitLevel = nil, nil, nil, nil, nil
_G.UnitExists, _G.GetPetActionInfo = nil, nil

suite.done()
