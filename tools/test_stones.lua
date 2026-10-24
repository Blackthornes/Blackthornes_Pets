-- A warlock's Healthstone and Soulstone reminder: off unless ticked, once a
-- stone is missing and again only after it was put right, only for a stone
-- the warlock can make, and /bpet stones.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("stones")

local ns = env.Load()
local Stones = ns.Stones

local healthstones, known, buffs = 0, { [5699] = true, [693] = true }, {}
_G.C_Item = _G.C_Item or {}
_G.C_Item.GetItemCount = function(id) return id == 5509 and healthstones or 0 end
_G.IsPlayerSpell = function(id) return known[id] == true end
_G.IsSpellKnown = nil
_G.UnitClass = function() return "Warlock", "WARLOCK" end
_G.UnitIsDeadOrGhost = function() return false end
_G.IsInRaid = function() return false end
_G.GetNumGroupMembers = function() return 2 end
_G.C_UnitAuras = _G.C_UnitAuras or {}
_G.C_UnitAuras.GetAuraDataByIndex = function(unit, index)
    local list = buffs[unit] or {}
    return list[index]
end
local warned = {}
ns.Warn = function(text) warned[#warned + 1] = text end
ns.PetStatus.Alert = function() end

suite.check("off unless ticked", ns.db.stoneReminder == false and not Stones:IsOn())
suite.check("off, no note", Stones:Check() == 0 and #warned == 0)

Stones:Set(true)
suite.check("no stones, two notes", Stones:Check() == 2
    and warned[1] == "You have no Healthstone."
    and warned[2] == "Your Soulstone isn't on anyone.", table.concat(warned, " | "))
suite.check("only once", Stones:Check() == 0 and #warned == 2)

healthstones = 1
buffs.party1 = { { spellId = 20762, sourceUnit = "player" } }
suite.check("put right, quiet", Stones:Check() == 0)
healthstones = 0
buffs.party1 = { { spellId = 20762, sourceUnit = "party2" } }
suite.check("used up, and another warlock's stone does not count", Stones:Check() == 2 and #warned == 4)

-- A stone the warlock can't make is never asked for.
Stones:Set(true)
known = {}
suite.check("too low to make them, nothing", Stones:Check() == 0)
known = { [5699] = true, [693] = true }

-- Dead, or not a warlock: nothing.
_G.UnitIsDeadOrGhost = function() return true end
suite.check("dead, nothing", Stones:Check() == 0)
_G.UnitIsDeadOrGhost = function() return false end
_G.UnitClass = function() return "Hunter", "HUNTER" end
suite.check("a hunter gets nothing", Stones:Check() == 0)
_G.UnitClass = function() return "Warlock", "WARLOCK" end

-- The client won't say.
_G.C_Item.GetItemCount = function() error("secret value") end
_G.C_UnitAuras.GetAuraDataByIndex = function() error("secret value") end
Stones:Set(true)
known = { [5699] = true }
suite.check("an unreadable bag says nothing", Stones:Check() == 0)

-- The command.
ns.commands.stones.fn("off")
suite.check("/bpet stones off", ns.db.stoneReminder == false)
ns.commands.stones.fn("on")
suite.check("/bpet stones on", ns.db.stoneReminder == true)

suite.done()
