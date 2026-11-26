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

-- The Soulstone's time and holder on the slot (2026-11-26).
local timers = {}
local realTimer = _G.C_Timer
_G.C_Timer = { After = function(wait, fn) timers[#timers + 1] = { wait = wait, fn = fn } end }
local clock = 1000
_G.GetTime = function() return clock end
buffs.party1 = { { spellId = 20707, sourceUnit = "player", expirationTime = clock + 18 * 60 - 20 } }
slots = Tracker:Slots()
suite.check("the time left is read", slots[3].left and math.abs(slots[3].left - (18 * 60 - 20)) < 0.01,
    tostring(slots[3].left))
suite.check("and who has it", slots[3].holder == "Ana Brightwood")
Tracker:Refresh()
local soul = Tracker.frame.slots[3]
suite.check("the slot shows minutes", soul.count:GetText() == "18 min", soul.count:GetText())
suite.check("in green", soul.count._color and math.abs(soul.count._color[1] - Tracker.GREEN[1]) < 0.01)
suite.check("over the whole name", soul.sub:IsShown() and soul.sub:GetText() == "On Ana Brightwood",
    tostring(soul.sub:GetText()))
local wide = soul:GetWidth()
suite.check("the slot grows to fit the name", wide > Tracker.SLOT, tostring(wide))
suite.check("and so does the plaque", Tracker.frame:GetWidth()
    == 2 * Tracker.SLOT + soul:GetWidth() + (Tracker.RIM + Tracker.PAD) * 2, tostring(Tracker.frame:GetWidth()))
suite.check("one timer for the next minute", #timers == 1 and timers[1].wait > 39 and timers[1].wait < 41,
    #timers .. " " .. tostring(timers[1] and timers[1].wait))
Tracker:Refresh()
suite.check("never two at once", #timers == 1)
clock = clock + 14 * 60
timers[1].fn()
suite.check("under five minutes it turns orange", soul.count:GetText() == "4 min"
    and math.abs(soul.count._color[1] - Tracker.ORANGE[1]) < 0.01, soul.count:GetText())
suite.check("the next minute is asked for", #timers == 2)

-- A dungeon hides the time: the name alone, and no timer.
timers = {}
Tracker.ticking = nil
buffs.party1 = { { spellId = 20707, sourceUnit = "player",
    expirationTime = setmetatable({}, { __tostring = function() error("secret value") end }) } }
_G.issecretvalue = function(value) return type(value) == "table" end
slots = Tracker:Slots()
suite.check("a hidden time is no time", slots[3].onSomeone == true and slots[3].left == nil)
Tracker:Refresh()
suite.check("the count stays, with the name", soul.count:GetText() == "1"
    and soul.sub:GetText() == "On Ana Brightwood", soul.count:GetText())
suite.check("no timer without a time", #timers == 0)
_G.issecretvalue = nil

-- On nobody with one in the bags: Ready.
buffs.party1 = nil
slots = Tracker:Slots()
suite.check("in the bags and on nobody is ready", slots[3].ready == true and not slots[3].holder)
Tracker:Refresh()
suite.check("the slot says Ready", soul.count:GetText() == "Ready" and not soul.sub:IsShown(),
    soul.count:GetText())
suite.check("and shrinks back to fit Ready", soul:GetWidth() < wide
    and soul:GetWidth() >= 4 + Tracker.ICON + 4 + 6 + soul.count:GetStringWidth(), tostring(soul:GetWidth()))
counts[5232] = 0
slots = Tracker:Slots()
suite.check("none in the bags is not ready", not slots[3].ready and slots[3].empty)
counts[5232] = 1
_G.C_Timer = realTimer
_G.GetTime = nil

-- Firestone once Create Firestone is learned, between Healthstone and Soulstone.
known[17951] = true
slots = Tracker:Slots()
suite.check("Firestone joins once learned", Keys(slots) == "shards,health,fire,soul", Keys(slots))
suite.check("no Firestone is empty", slots[3].count == 0 and slots[3].empty and not slots[3].held)

-- Spellstone once Create Spellstone is learned, after the Firestone (the
-- owner's warlock had one and no slot for it, 2026-11-19).
known[2362] = true
slots = Tracker:Slots()
suite.check("Spellstone joins once learned", Keys(slots) == "shards,health,fire,spell,soul", Keys(slots))
suite.check("no Spellstone is empty", slots[4].count == 0 and slots[4].empty)
counts[5522] = 1
slots = Tracker:Slots()
suite.check("one Spellstone counts", slots[4].count == 1 and not slots[4].empty)
counts[5522] = 0

-- No red gems on the ends.
local source = io.open(lfs_cwd .. "/UI/ShardTracker.lua"):read("*a")
suite.check("no red gems", source:find("CloseGem", 1, true) == nil)

-- What a click does.
_G.GetSpellInfo = function(id) return "Spell " .. id end
_G.C_Spell = nil
local function Act(key) return Tracker:ActionFor({ key = key }) end
suite.check("shards are a count only", Act("shards") == nil)
local act = Act("health")
suite.check("a Healthstone in the bags is used", act.type == "item" and act.item == "item:5512", act.item)
counts[5512] = 0
act = Act("health")
suite.check("no Healthstone makes one", act.type == "spell" and act.spell == "Spell 6202", tostring(act.spell))
suite.check("and says so", act.words == "Click to make one. Uses 1 shard.")
known[11729] = true
act = Act("health")
suite.check("with the best rank known", act.spell == "Spell 11729", tostring(act.spell))
act = Act("soul")
suite.check("a Soulstone goes on your target or you", act.type == "macro"
    and act.macrotext:find("[@target,help,nodead][@player]", 1, true) ~= nil, act.macrotext)
act = Act("fire")
suite.check("no Firestone makes one", act.type == "spell" and act.spell == "Spell 17951", tostring(act.spell))
counts[13699] = 1
act = Act("fire")
suite.check("a Firestone in the bags is held", act.type == "macro" and act.macrotext:find("^/equip ") ~= nil, act.macrotext)
_G.GetInventoryItemID = function(_, slot) return slot == 17 and 13699 or nil end
act = Act("fire")
suite.check("holding your only one does nothing", act.type == nil and act.words == "You are holding one.")
_G.GetInventoryItemID = nil
-- Forever's Firestone and Spellstone are used from the bags, not held.
local equipLoc = {}
_G.C_Item.GetItemInfoInstant = function(id) return id, nil, nil, equipLoc[id] or "INVTYPE_HOLDABLE" end
equipLoc[13699] = "INVTYPE_NON_EQUIP_IGNORE"
act = Act("fire")
suite.check("a Firestone that can't be held is used", act.type == "item" and act.item == "item:13699", tostring(act.item))
counts[13699] = 0
act = Act("spell")
suite.check("no Spellstone makes one", act.type == "spell" and act.spell == "Spell 2362", tostring(act.spell))
known[17727] = true
act = Act("spell")
suite.check("with the best rank known", act.spell == "Spell 17727", tostring(act.spell))
counts[5522] = 1
equipLoc[5522] = "INVTYPE_NON_EQUIP_IGNORE"
act = Act("spell")
suite.check("a Spellstone in the bags is used", act.type == "item" and act.item == "item:5522"
    and act.words == "Click to use it.", tostring(act.item))
equipLoc[5522] = nil
act = Act("spell")
suite.check("a Spellstone that can be held is held", act.type == "macro" and act.macrotext:find("^/equip ") ~= nil, tostring(act.macrotext))
_G.C_Item.GetItemInfoInstant = nil
counts[5522] = 0
counts[5512] = 1

-- Click to Make Stones: off for a new player, so no buttons.
suite.check("clicks start off", not Tracker:ClicksOn())
Tracker:Refresh()
suite.check("no buttons while it is off", Tracker.frame.buttons[2] == nil)
Tracker:SetClicks(true)
suite.check("ticked, clicks are on", ns.db.shardTrackerClicks == true and Tracker:ClicksOn())

-- The buttons: set out of combat, waiting in a fight.
Tracker:Refresh()
local button = Tracker.frame.buttons[2]
suite.check("a Healthstone button is made", button ~= nil and button:GetAttribute("type") == "item")
suite.check("no button for shards", Tracker.frame.buttons[1] == nil)
_G.InCombatLockdown = function() return true end
counts[5512] = 0
Tracker:Refresh()
suite.check("in a fight it waits", Tracker.buttonsWaiting == true and button:GetAttribute("type") == "item")
_G.InCombatLockdown = function() return false end
Tracker:UpdateButtons()
suite.check("after the fight it catches up", not Tracker.buttonsWaiting and button:GetAttribute("type") == "spell")
counts[5512] = 1

-- Unticked, the buttons go away.
Tracker:SetClicks(false)
suite.check("unticked, the button hides", not button:IsShown() and button:GetAttribute("type") == nil)
Tracker:SetClicks(true)
suite.check("ticked again, it is back", button:IsShown())

-- A player who had the tracker on before keeps clicking; a new one starts off.
ns.db.shardTrackerClicks, ns.db.shardTracker = nil, true
Tracker:ClicksStart()
suite.check("the tracker on before keeps clicks", ns.db.shardTrackerClicks == true)
ns.db.shardTrackerClicks, ns.db.shardTracker = nil, false
Tracker:ClicksStart()
suite.check("a new player starts off", ns.db.shardTrackerClicks == false)
ns.db.shardTrackerClicks = false
ns.db.shardTracker = true
Tracker:ClicksStart()
suite.check("and only once", ns.db.shardTrackerClicks == false)
ns.db.shardTrackerClicks = true

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
