-- A warlock's soul shards: the chip on the Pet tab, the warning at 2 or
-- fewer, off unless ticked, and /bpet shards.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("soulshards")

local ns = env.Load()
local SoulShards, UI = ns.SoulShards, ns.UI

local shards = 5
_G.C_Item = _G.C_Item or {}
_G.C_Item.GetItemCount = function(id) return id == 6265 and shards or 0 end
_G.UnitClass = function() return "Warlock", "WARLOCK" end
local warned = {}
local realWarn = ns.Warn
ns.Warn = function(text) warned[#warned + 1] = text end
SoulShards.ready = true

suite.check("off unless ticked", ns.db.soulShards == false and not SoulShards:IsOn())
suite.check("off, no chip", SoulShards:Chip() == nil)
shards = 1
suite.check("off, no warning", SoulShards:Check() == false and #warned == 0)

SoulShards:Set(true)
suite.check("turning it on warns at once when low", #warned == 1
    and warned[1] == "Only 1 soul shard left.", warned[1])
local text, color = SoulShards:Chip()
suite.check("one shard reads as one", text == "1 soul shard" and color == "loss", text)
suite.check("it warns only once", SoulShards:Check() == false and #warned == 1)

shards = 0
suite.check("and not again on the way down", SoulShards:Check() == false and #warned == 1)
shards = 6
SoulShards:Check()
text, color = SoulShards:Chip()
suite.check("plenty reads plain", text == "6 soul shards" and color == "muted", text)
shards = 2
suite.check("after a restock it warns again at 2", SoulShards:Check() == true
    and warned[2] == "Only 2 soul shards left.", warned[2])
shards = 5
SoulShards:Check()
shards = 0
SoulShards:Check()
suite.check("none says none", warned[3] == "You have no soul shards.", warned[3])

-- Not a warlock: nothing.
_G.UnitClass = function() return "Hunter", "HUNTER" end
SoulShards.warned = nil
suite.check("a hunter gets no chip", SoulShards:Chip() == nil)
suite.check("or warning", SoulShards:Check() == false)
_G.UnitClass = function() return "Warlock", "WARLOCK" end

-- The client won't say.
_G.C_Item.GetItemCount = function() error("secret value") end
suite.check("an unreadable count shows nothing", SoulShards:Chip() == nil
    and SoulShards:Check() == false)
_G.C_Item.GetItemCount = function(id) return id == 6265 and shards or 0 end

-- Not until the bags settle after a loading screen.
SoulShards.ready = false
SoulShards.warned = nil
suite.check("waits for the bags after login", SoulShards:Check() == false)
SoulShards.ready = true

-- The chip on the Pet tab, with a demon out.
shards = 3
_G.UnitExists = function() return true end
_G.UnitName = function() return "Grel'zok" end
_G.UnitCreatureFamily = function() return "Imp" end
_G.UnitLevel = function() return 8 end
UI:Show()
suite.check("the Pet tab shows the shards", UI.shardChip:IsShown()
    and UI.shardChip.label:GetText() == "3 soul shards", UI.shardChip.label:GetText())

-- /bpet shards.
ns.HandleSlash("shards off")
suite.check("/bpet shards off turns it off", ns.db.soulShards == false and not UI.shardChip:IsShown())
ns.HandleSlash("shards")
suite.check("/bpet shards on its own flips it", ns.db.soulShards == true)
ns.HandleSlash("shards off")

ns.Warn = realWarn
_G.UnitExists, _G.UnitName, _G.UnitCreatureFamily, _G.UnitLevel = nil, nil, nil, nil
suite.done()
