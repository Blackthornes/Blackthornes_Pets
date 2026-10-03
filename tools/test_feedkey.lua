-- The "Feed pet" key: a hidden secure button kept on the best food out of
-- combat, hungry or not, left alone in combat, cleared with no food, and
-- saying why in chat when it has nothing to feed.

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
suite.check("the key is named", _G["BINDING_NAME_CLICK BlackthornesPetsFeedKey:LeftButton"] == "Feed pet")
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

local function Refresh() ns.Food:Update() end
local function Pressed()
    env.chat = {}
    button:GetScript("OnClick")(button, "LeftButton", false)
    return env.ChatText()
end

Refresh()
suite.check("a happy pet still gets its food armed", button:GetAttribute("type") == "macro")
suite.check("the best food, as the Feed buttons pick",
    button:GetAttribute("macrotext") == ns.Food:FeedMacro(ns.Food:Scan()[1])
        and (button:GetAttribute("macrotext") or ""):find("/use 0 5", 1, true),
    button:GetAttribute("macrotext"))
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
suite.check("out of combat with no food it is cleared",
    button:GetAttribute("macrotext") == nil and button:GetAttribute("type") == nil)
suite.check("and a press says why", Pressed():find("no food in your bags that Scorpid will eat", 1, true),
    env.ChatText())

bags[0] = { [7] = { itemID = 117, stackCount = 4 } }
Refresh()
suite.check("food back, armed again", (button:GetAttribute("macrotext") or ""):find("/use 0 7", 1, true))

_G.UnitExists = function() return false end
ns.PetStatus:Update()
suite.check("no pet, cleared", button:GetAttribute("macrotext") == nil)
suite.check("and a press says so", Pressed():find("no pet out", 1, true), env.ChatText())
_G.UnitExists = function() return true end

_G.UnitClass = function() return "Warlock", "WARLOCK" end
Refresh()
suite.check("not a hunter, nothing armed", button:GetAttribute("macrotext") == nil)
suite.check("and a press says it is for hunters", Pressed():find("for hunters", 1, true), env.ChatText())

_G.C_Container, _G.C_Item, _G.C_PetInfo = nil, nil, nil
_G.UnitExists, _G.UnitName, _G.UnitLevel, _G.UnitClass = nil, nil, nil, nil

suite.done()
