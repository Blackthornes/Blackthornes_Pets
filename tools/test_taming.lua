-- The taming skills on a beast's tooltip: the data holds together, the
-- creature id comes out of the GUID, known skills are green and new ones red,
-- and nothing breaks on a client that says less than we hope.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("taming")

local ns = env.Load()
local Taming, Tip, Data = ns.Taming, ns.TamingTooltip, ns.BeastSkills

-- The data.
local beasts, broken = 0, nil
for npc, list in pairs(Data.BEASTS) do
    beasts = beasts + 1
    if #list == 0 then broken = npc end
    for _, spell in ipairs(list) do
        if not Data.SKILLS[spell] then broken = npc end
    end
end
suite.check("every beast lists skills that are in the skill table", broken == nil, broken)
suite.check("the table has the Classic beasts", beasts > 300, beasts)
for spell, skill in pairs(Data.SKILLS) do
    if not (type(skill.name) == "string" and skill.rank >= 1 and type(skill.teach) == "number") then
        broken = spell
    end
end
suite.check("every skill has a name, a rank and the spell a hunter learns", broken == nil, broken)
local boar = Taming:SkillsFor(3099)
suite.check("a Dire Mottled Boar teaches Charge (Rank 1)",
    #boar == 1 and Taming.Label(boar[1]) == "Charge (Rank 1)", boar[1] and Taming.Label(boar[1]))
suite.check("a beast that teaches nothing has no skills", #Taming:SkillsFor(2956) == 0)

-- The creature id.
suite.check("reads the creature id from a creature's GUID",
    Taming:NpcID("Creature-0-4378-1-17-3099-00004C3A2B") == 3099)
suite.check("a pet's GUID is not a beast to tame",
    Taming:NpcID("Pet-0-4378-1-17-3099-01004C3A2B") == nil)
suite.check("a player is not either", Taming:NpcID("Player-4378-0A1B2C3D") == nil)
suite.check("nothing is nothing", Taming:NpcID(nil) == nil)
_G.issecretvalue = function(value) return value == "SECRET" end
suite.check("a secret GUID is left alone", Taming:NpcID("SECRET") == nil)
_G.issecretvalue = nil

-- What the hunter knows.
local charge = Taming:SkillsFor(3099)[1]
suite.check("with no way to tell, it says it cannot", Taming:Knows(charge) == nil)

local known = {}
_G.IsPlayerSpell = function(id) return known[id] == true end
suite.check("the spell check can say no", Taming:Knows(charge) == false)
known[7370] = true
suite.check("and yes", Taming:Knows(charge) == true)
local claw1 = Data.SKILLS[16827]
known[2981] = true
suite.check("knowing Claw 2 means Claw 1 is known too", Taming:Knows(claw1) == true)
suite.check("but not Claw 3", Taming:Knows(Data.SKILLS[16829]) == false)
suite.check("a Claw 1 with no spell to check says the same",
    Taming:Knows({ name = "Claw", rank = 1 }) == true)
_G.IsPlayerSpell = function() error("secret value") end
suite.check("a spell check that raises says nothing", Taming:Knows(charge) == nil)
_G.IsPlayerSpell = nil

-- The Beast Training window.
local crafts = {
    { "Beast Training", nil, "header" },
    { "Bite", "Rank 2", "used" },
    { "Charge", "Rank 1", "used" },
    { "Growl", "Rank 1", "used" },
}
_G.GetNumCrafts = function() return #crafts end
_G.GetCraftInfo = function(i) return unpack(crafts[i]) end
suite.check("reads the Beast Training window", Taming:ReadBeastTraining() == 2)
suite.check("and remembers it on the character", ns.charDB.beastTraining.known["Charge#1"] == true)
suite.check("a skill in it is known", Taming:Knows(charge) == true)
suite.check("once read, a skill missing from it is not known",
    Taming:Knows(Data.SKILLS[17256]) == false)
suite.check("a lower rank of a skill in it is known", Taming:Knows(Data.SKILLS[17253]) == true)
suite.check("a skill named with no spell to check gets the same answer",
    Taming:Knows({ name = "Bite", rank = 1, forever = true }) == true
    and Taming:Knows({ name = "Bite", rank = 3, forever = true }) == false)
crafts = { { "Enchant Bracer - Stamina", "", "optimal" } }
suite.check("an enchanting window is not read", Taming:ReadBeastTraining() == nil)
suite.check("and forgets nothing", Taming:Knows(charge) == true)
_G.GetNumCrafts, _G.GetCraftInfo = nil, nil

-- The tooltip.
local function Tooltip()
    local tip = env.Stub({ _lines = {} })
    tip.AddLine = function(self, text) self._lines[#self._lines + 1] = text end
    tip.AddDoubleLine = function(self, left, right) self._lines[#self._lines + 1] = left .. " || " .. right end
    tip.NumLines = function(self) return #self._lines end
    return tip
end

ns = env.Load()
Taming, Tip = ns.Taming, ns.TamingTooltip
local tip = Tooltip()
_G.GameTooltip = tip
local unitClass = "HUNTER"
_G.UnitClass = function() return "Hunter", unitClass end
_G.IsPlayerSpell = function(id) return id == 7370 end -- Charge (Rank 1)
for _, module in ipairs(ns.moduleOrder) do
    if module.OnEnable then module:OnEnable() end
end

-- Any beast teaching two skills will do.
local pairNpc
for npc, list in pairs(ns.BeastSkills.BEASTS) do
    if #list == 2 then pairNpc = npc break end
end

local guid = "Creature-0-1-2-3-4-0000000001"
local function Hover(npc)
    tip._lines = {}
    Tip.Forget(tip)
    return Tip:OnTooltip(tip, { guid = ("Creature-0-1-2-3-%d-0000000001"):format(npc) }, "test")
end

-- A boar that teaches Charge (Rank 2).
local charge2
for npc, list in pairs(ns.BeastSkills.BEASTS) do
    if #list == 1 and list[1] == 26177 then charge2 = npc break end
end
suite.check("found a beast that teaches Charge (Rank 2)", charge2 ~= nil)
suite.check("the lines go on a hunter's tooltip", Hover(charge2) == "added")
local text = table.concat(tip._lines, "\n")
suite.check("under a heading", text:find("Taming teaches", 1, true), text)
suite.check("a skill not known is red and says so",
    text:find("|c" .. ns.COLORS.bad .. "   Charge (Rank 2)|r || |c" .. ns.COLORS.bad .. "Not known|r", 1, true), text)

suite.check("a beast teaching Charge (Rank 1) is added", Hover(3099) == "added")
text = table.concat(tip._lines, "\n")
suite.check("a known skill is green and says so",
    text:find("|c" .. ns.COLORS.good .. "   Charge (Rank 1)|r || |c" .. ns.COLORS.good .. "Known|r", 1, true), text)
suite.check("no hint while the client can tell", not text:find("Beast Training", 1, true), text)

suite.check("two skills get a line each", Hover(pairNpc) == "added" and #tip._lines == 3, #tip._lines)

tip._lines = {}
Tip.Forget(tip)
Tip:OnTooltip(tip, { guid = guid:gsub("%-4%-", "-3099-") }, "test")
local count = #tip._lines
suite.check("the same beast is not added twice",
    Tip:OnTooltip(tip, { guid = guid:gsub("%-4%-", "-3099-") }, "test") == "duplicate" and #tip._lines == count)

suite.check("nothing for a beast that teaches nothing", Hover(2956) == "quiet" and #tip._lines == 0)

_G.IsPlayerSpell = nil
Hover(3099)
text = table.concat(tip._lines, "\n")
suite.check("when nothing can tell, the skill is plain and the hint shows",
    text:find("|c" .. ns.COLORS.text .. "   Charge (Rank 1)|r", 1, true)
        and text:find("Open Beast Training once", 1, true), text)

unitClass = "WARLOCK"
suite.check("nothing for a warlock", Hover(3099) == "quiet" and #tip._lines == 0)
unitClass = "HUNTER"

ns.db.tamingTooltip = false
suite.check("nothing when turned off in settings", Hover(3099) == "quiet")
ns.db.tamingTooltip = true

suite.check("another tooltip is left alone",
    Tip:OnTooltip(Tooltip(), { guid = "Creature-0-1-2-3-3099-01" }, "test") == "quiet")

-- No GUID in the data: ask the tooltip for its unit.
_G.UnitGUID = function(unit) if unit == "mouseover" then return "Creature-0-1-2-3-3099-01" end end
tip._lines = {}
Tip.Forget(tip)
suite.check("falls back on the unit under the mouse", Tip:OnTooltip(tip, nil, "test") == "added")
_G.UnitGUID = function() error("secret value") end
tip._lines = {}
Tip.Forget(tip)
suite.check("a unit that raises costs its lines, not an error", Tip:OnTooltip(tip, nil, "test") == "nounit")
_G.UnitGUID = nil

-- The command.
_G.IsPlayerSpell = function(id) return id == 7370 end
env.chat = {}
ns.HandleSlash("taming")
text = env.ChatText()
suite.check("/bpet taming lists what is known", text:find("pet skills known (1): Charge (Rank 1)", 1, true), text)
suite.check("and says Beast Training has not been read", text:find("haven't opened Beast Training", 1, true), text)
_G.IsPlayerSpell, _G.UnitClass = nil, nil

suite.done()
