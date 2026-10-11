-- The "Pet care" key: a hidden secure button kept on the best food out of
-- combat, hungry or not, left alone in combat, and saying why in chat when it
-- has nothing to do. It calls the pet when none is out, revives a dead one,
-- and summons a warlock's last demon.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("feedkey")

local ns = env.Load()
local FeedKey = ns.FeedKey

-- Remember how the button asks for clicks.
local create = _G.CreateFrame
_G.CreateFrame = function(...)
    local frame = create(...)
    function frame:RegisterForClicks(...) self._clicks = { ... } end
    return frame
end
local button = FeedKey:Build()
_G.CreateFrame = create

suite.check("the button has the binding's name", _G.BlackthornesPetsFeedKey == button)
suite.check("it is never shown", not button:IsShown())
suite.check("it acts once, as the key comes up",
    #button._clicks == 1 and button._clicks[1] == "AnyUp"
        and button:GetAttribute("useOnKeyDown") == false,
    table.concat(button._clicks, ","))

-- The binding's names, and Bindings.xml naming the same button.
suite.check("the header is named", _G.BINDING_HEADER_BLACKTHORNESPETS == "Blackthornes Pets")
suite.check("the key is named", _G["BINDING_NAME_CLICK BlackthornesPetsFeedKey:LeftButton"] == "Pet care (call, revive, feed or mend)")
local handle = assert(io.open(lfs_cwd .. "/Bindings.xml", "r"))
local xml = handle:read("*a")
handle:close()
suite.check("Bindings.xml binds the same click",
    xml:find('name="' .. FeedKey.BINDING .. '"', 1, true)
        and xml:find('header="BLACKTHORNESPETS"', 1, true) and xml:find('category="ADDONS"', 1, true))

local happiness = 3
_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Scorpid" end
_G.UnitLevel = function() return 12 end
_G.C_PetInfo = {
    GetPetHappiness = function() return happiness, 100, 5 end,
    GetPetFoodTypes = function() return { "Meat" } end,
}
local levels = { [117] = 5, [2287] = 8 }
local names = { [117] = "Tough Jerky", [2287] = "Haunch of Meat" }
local bags = { [0] = {
    [3] = { itemID = 2287, stackCount = 10 },
    [5] = { itemID = 117, stackCount = 30 },
} }
_G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and 16 or 0 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
}
_G.C_Item = { GetItemInfo = function(id) return names[id], nil, 1, levels[id] end }

local MEND = "\n/cast [@pet,exists,nodead,combat] Mend Pet"
local function Refresh() ns.Food:Update() end
local function Pressed()
    env.chat = {}
    button:GetScript("OnClick")(button, "LeftButton", false)
    return env.ChatText()
end

Refresh()
suite.check("a happy pet still gets its food armed", button:GetAttribute("type") == "macro")
local text = button:GetAttribute("macrotext") or ""
suite.check("the best food, as the Feed buttons pick",
    text:find(ns.Food:FeedMacro(ns.Food:Scan()[1]), 1, true) and text:find("/use 0 5", 1, true), text)
suite.check("first it calls or revives the pet when it needs it",
    text:find("/cast [@pet,dead] Revive Pet; [nopet] Call Pet\n", 1, true) == 1, text)
suite.check("and feeding stops with no pet, a dead one or in combat",
    text:find("/stopmacro [nopet][@pet,dead][combat]\n/cast", 1, true) ~= nil, text)
suite.check("a living pet in a fight is mended, before the feeding stops",
    text:find(MEND .. "\n/stopmacro", 1, true) ~= nil, text)
suite.check("/bpet food says it mends", FeedKey:State():find("mends it in combat", 1, true), FeedKey:State())
suite.check("the revive key only revives",
    FeedKey.reviveButton:GetAttribute("type") == "macro"
        and FeedKey.reviveButton:GetAttribute("macrotext") == "/cast Revive Pet",
    tostring(FeedKey.reviveButton:GetAttribute("macrotext")))
suite.check("it is never shown and acts as the key comes up",
    not FeedKey.reviveButton:IsShown() and FeedKey.reviveButton:GetAttribute("useOnKeyDown") == false)
suite.check("it has its own binding name",
    _G["BINDING_NAME_CLICK BlackthornesPetsReviveKey:LeftButton"] == "Revive pet"
        and xml:find('name="CLICK BlackthornesPetsReviveKey:LeftButton"', 1, true) ~= nil)
suite.check("a press with food says nothing", Pressed() == "")
suite.check("/bpet food names the food", FeedKey:State():find("feeds Tough Jerky", 1, true), FeedKey:State())

-- Combat: the last food stays armed, whatever changes.
_G.InCombatLockdown = function() return true end
bags[0] = {}
Refresh()
suite.check("in combat nothing is changed",
    (button:GetAttribute("macrotext") or ""):find("/use 0 5", 1, true))
_G.InCombatLockdown = nil

Refresh()
suite.check("out of combat with no food it only calls or revives",
    button:GetAttribute("macrotext") == "/cast [@pet,dead] Revive Pet; [nopet] Call Pet" .. MEND,
    button:GetAttribute("macrotext"))
suite.check("and a press says why", Pressed():find("no food in your bags that Scorpid will eat", 1, true),
    env.ChatText())

bags[0] = { [7] = { itemID = 117, stackCount = 4 } }
Refresh()
suite.check("food back, armed again", (button:GetAttribute("macrotext") or ""):find("/use 0 7", 1, true))

_G.UnitExists = function() return false end
ns.PetStatus:Update()
suite.check("no pet: the key calls it", button:GetAttribute("macrotext") == "/cast [@pet,dead] Revive Pet; [nopet] Call Pet" .. MEND)
suite.check("and a press says nothing", Pressed() == "", env.ChatText())
suite.check("/bpet food says so", FeedKey:State():find("calls your pet", 1, true), FeedKey:State())

-- It dies, and its body goes: Call Pet would only say it is dead.
_G.UnitExists = function() return true end
_G.UnitIsDead = function() return true end
_G.InCombatLockdown = function() return true end
ns.PetStatus:Update()
_G.InCombatLockdown = nil
_G.UnitExists = function() return false end
ns.PetStatus:Update()
suite.check("a pet that died is revived, not called",
    button:GetAttribute("macrotext") == "/cast [nopet][@pet,dead] Revive Pet" .. MEND, button:GetAttribute("macrotext"))
_G.UnitExists, _G.UnitIsDead = function() return true end, nil
ns.PetStatus:Update()
suite.check("alive again: back to calling and feeding",
    (button:GetAttribute("macrotext") or ""):find("[nopet] Call Pet", 1, true) ~= nil)

-- A hunter too young for Call Pet: nothing but food.
_G.IsPlayerSpell = function(id) return id ~= ns.FeedKey.CALL_PET and id ~= ns.FeedKey.REVIVE_PET and id ~= ns.FeedKey.MEND_PET end
ns.PetStatus:Update()
suite.check("no Call Pet known: just the food", (button:GetAttribute("macrotext") or ""):find("/stopmacro", 1, true) == 1,
    button:GetAttribute("macrotext"))
_G.IsPlayerSpell = nil

-- In combat with food armed, a press says it can't feed now.
_G.InCombatLockdown = function() return true end
suite.check("in combat a press says it can't feed", Pressed():find("can't be fed in combat", 1, true), env.ChatText())
_G.InCombatLockdown = nil

-- A warlock: the last demon summoned, else the first known.
_G.UnitClass = function() return "Warlock", "WARLOCK" end
_G.UnitExists = function() return false end
ns.PetStatus:Update()
suite.check("a warlock with no demon out summons the Imp",
    button:GetAttribute("macrotext") == "/cast [nopet] Summon Imp", button:GetAttribute("macrotext"))
FeedKey:OnCast(697)
suite.check("a Voidwalker summoned is remembered", ns.charDB.lastDemon == 697)
suite.check("and the key summons it", button:GetAttribute("macrotext") == "/cast [nopet] Summon Voidwalker",
    button:GetAttribute("macrotext"))
suite.check("other spells are not demons", FeedKey:OnCast(133) == false and ns.charDB.lastDemon == 697)
suite.check("a press with no demon out says nothing", Pressed() == "", env.ChatText())
_G.UnitExists = function() return true end
ns.PetStatus:Update()
suite.check("with the demon out, a press says so", Pressed():find("already out", 1, true), env.ChatText())

_G.UnitClass = function() return "Mage", "MAGE" end
ns.PetStatus:Update()
suite.check("not a hunter or warlock, nothing armed", button:GetAttribute("macrotext") == nil)
suite.check("and a press says what it is for", Pressed():find("hunter's pet", 1, true), env.ChatText())

_G.C_Container, _G.C_Item, _G.C_PetInfo = nil, nil, nil
_G.UnitExists, _G.UnitName, _G.UnitLevel, _G.UnitClass = nil, nil, nil, nil

suite.done()
