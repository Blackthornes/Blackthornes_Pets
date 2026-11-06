-- The Shard Tracker: off unless ticked, nothing until Drain Soul is
-- learned, a stone's slot only once its spell is learned, counts and their
-- states, the Soulstone dot and holder, size and place, and /bpet tracker.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("shardtracker")

local ns = env.Load()
local Tracker = ns.ShardTracker

local counts = { [6265] = 5, [5512] = 0, [5232] = 0 }
local known = {}
local buffs = {}
_G.C_Item = _G.C_Item or {}
_G.C_Item.GetItemCount = function(id) return counts[id] or 0 end
_G.IsPlayerSpell = function(id) return known[id] == true end
_G.IsSpellKnown = nil
_G.UnitClass = function() return "Warlock", "WARLOCK" end
_G.IsInRaid = function() return false end
_G.GetNumGroupMembers = function() return 2 end
_G.GetUnitName = function(unit) return unit == "party1" and "Ana Brightwood" or "Me" end
_G.C_UnitAuras = _G.C_UnitAuras or {}
_G.C_UnitAuras.GetAuraDataByIndex = function(unit, index)
    local list = buffs[unit] or {}
    return list[index]
end

local function Keys(slots)
    local keys = {}
    for _, slot in ipairs(slots or {}) do keys[#keys + 1] = slot.key end
    return table.concat(keys, ",")
end

suite.check("off unless ticked", ns.db.shardTracker == false and not Tracker:IsOn())
suite.check("off, nothing to show", Tracker:Slots() == nil and Tracker:Refresh() == false)

-- On, but Drain Soul not learned yet: nothing.
Tracker:Set(true)
suite.check("before Drain Soul, nothing", Tracker:Slots() == nil)
suite.check("and no frame on screen", not (Tracker.frame and Tracker.frame:IsShown()))

known[1120] = true
local slots = Tracker:Slots()
suite.check("Drain Soul learned, shards only", Keys(slots) == "shards", Keys(slots))
suite.check("it shows", Tracker:Refresh() == true and Tracker.frame:IsShown())
suite.check("the count shows", Tracker.frame.slots[1].count:GetText() == "5",
    Tracker.frame.slots[1].count:GetText())
suite.check("five is not low", slots[1].low == false)

counts[6265] = 2
slots = Tracker:Slots()
suite.check("two is low", slots[1].low == true)
Tracker:Refresh()
local color = Tracker.frame.slots[1].count._color
suite.check("low reads red", color and math.abs(color[1] - Tracker.RED[1]) < 0.01)

-- Healthstone once Create Healthstone is learned.
known[6202] = true
slots = Tracker:Slots()
suite.check("Healthstone joins once learned", Keys(slots) == "shards,health", Keys(slots))
suite.check("none in the bags is empty", slots[2].count == 0 and slots[2].empty == true)
Tracker:Refresh()
suite.check("the frame grows for it", Tracker.frame:GetWidth() == 2 * Tracker.SLOT + (Tracker.RIM + Tracker.PAD) * 2)

counts[5512] = 1
slots = Tracker:Slots()
suite.check("one Healthstone is not empty", slots[2].count == 1 and not slots[2].empty)

-- Soulstone once Create Soulstone is learned.
known[693] = true
counts[5232] = 1
slots = Tracker:Slots()
suite.check("Soulstone joins once learned", Keys(slots) == "shards,health,soul", Keys(slots))
suite.check("not on anyone yet", not slots[3].onSomeone)
buffs.party1 = { { spellId = 20707, sourceUnit = "player" } }
slots = Tracker:Slots()
suite.check("on someone shows the dot", slots[3].onSomeone == true)
Tracker:Refresh()
suite.check("the dot is drawn", Tracker.frame.slots[3].dot:IsShown())
suite.check("the holder is named in full", ns.Stones:SoulstoneHolderName() == "Ana Brightwood")
Tracker:ShowTooltip(Tracker.frame.slots[3])
local tip = table.concat(GameTooltip._lines, " | ")
suite.check("the hover says who has it", tip:find("On Ana Brightwood", 1, true) ~= nil, tip)

-- Not a warlock: nothing.
_G.UnitClass = function() return "Hunter", "HUNTER" end
suite.check("a hunter sees nothing", Tracker:Slots() == nil and Tracker:Refresh() == false)
suite.check("and it hides", not Tracker.frame:IsShown())
_G.UnitClass = function() return "Warlock", "WARLOCK" end
Tracker:Refresh()

-- Size: 75, 100 or 125; 100 saves nothing.
suite.check("usual size is 100", Tracker:Size() == 100 and ns.db.shardTrackerScale == nil)
Tracker:SetSize(125)
suite.check("bigger is kept", ns.db.shardTrackerScale == 125 and Tracker.frame:GetScale() == 1.25)
Tracker:SetSize(60)
suite.check("an odd size falls back to 100", ns.db.shardTrackerScale == nil and Tracker:Size() == 100)

-- Place: kept where it is dropped, back to the first spot on reset.
Tracker.frame.GetLeft = function() return 300 end
Tracker.frame.GetBottom = function() return 700 end
Tracker:SaveSpot()
suite.check("a drop is kept", ns.db.shardTrackerX == 300 and ns.db.shardTrackerY == 700)
local point = Tracker.frame._point
suite.check("and placed there", point and point[1] == "BOTTOMLEFT" and point[4] == 300, point and point[1])
env.chat = {}
Tracker:Reset()
suite.check("reset forgets the spot", ns.db.shardTrackerX == nil and ns.db.shardTrackerY == nil)
suite.check("reset says so", env.ChatText():find("back in its first spot", 1, true) ~= nil, env.ChatText())
point = Tracker.frame._point
suite.check("and it is back at the top", point and point[1] == "TOP", point and point[1])

-- /bpet tracker
ns.commands.tracker.fn("off")
suite.check("tracker off", ns.db.shardTracker == false and not Tracker.frame:IsShown())
suite.check("says off", env.ChatText():find("Shard tracker: off.", 1, true) ~= nil)
ns.commands.tracker.fn("on")
suite.check("tracker on", ns.db.shardTracker == true and Tracker.frame:IsShown())
ns.commands.tracker.fn("")
suite.check("no word flips it", ns.db.shardTracker == false)

-- The low warning and chip wait for Drain Soul too.
known[1120] = nil
ns.db.soulShards = true
suite.check("no chip before Drain Soul", ns.SoulShards:Chip() == nil)

suite.done()
