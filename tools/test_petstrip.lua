-- The Pet Strip: off unless ticked, a hunter's pet only, mood, food left and
-- experience, solid with Feed and the close gem under the mouse, Feed
-- glowing for a hungry pet with no card, a red count for low food, how long
-- the food lasts from the player's own feeding, Feed put away in a fight,
-- On Pet Frame or Free, the close gem, and /bpet strip.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("petstrip")

local ns = env.Load()
local Strip = ns.PetStrip
Strip:OnEnable()

local saved = {}
local GLOBALS = { "GetTime", "UnitClass", "UnitExists", "UnitName", "UnitLevel", "GetPetExperience",
    "C_PetInfo", "C_Container", "C_Item", "InCombatLockdown", "PetFrame" }
for _, k in ipairs(GLOBALS) do saved[k] = rawget(_G, k) end
local savedScale = rawget(UIParent, "GetEffectiveScale")

-- The words without the game's colour codes.
local function Plain(text) return ((text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")) end

local clock = 1000
local class = "HUNTER"
local happiness = 3
local pet = { exists = true, name = "Shadowpaw", level = 23, xp = 6048, max = 8400 }
_G.GetTime = function() return clock end
_G.UnitClass = function() return "Hunter", class end
_G.UnitExists = function(unit) return unit == "pet" and pet.exists end
_G.UnitName = function(unit) return unit == "pet" and pet.name or "Me" end
_G.UnitLevel = function(unit) return unit == "pet" and pet.level or 25 end
_G.GetPetExperience = function() return pet.xp, pet.max end
_G.C_PetInfo = {
    GetPetHappiness = function() return happiness, 100, 5 end,
    GetPetFoodTypes = function() return { "Meat" } end,
}
local bags = { [0] = { [3] = { itemID = 3173, stackCount = 47 } } }
_G.C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and 16 or 0 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
}
_G.C_Item = {
    GetItemInfo = function() return "Haunch of Meat", nil, 1, 25 end,
    GetItemIconByID = function() return 133970 end,
}

local function Refresh() ns.Food:Update() end
local function Fire(event, ...)
    ns.eventFrame:GetScript("OnEvent")(ns.eventFrame, event, ...)
end

suite.check("off unless ticked", ns.db.petStrip == false and not Strip:IsOn())
Refresh()
suite.check("off, nothing shows", Strip.frame == nil or not Strip.frame:IsShown())
suite.check("On Pet Frame is the first place", Strip:OnPetFrame())

Strip:Set(true)
local frame = Strip.frame
-- Where the game laid it out.
frame.GetLeft = function() return 100 end
frame.GetBottom = function() return 500 end
suite.check("ticked, it shows", frame and frame:IsShown())
suite.check("the pet's name", frame.name:GetText() == "Shadowpaw", frame.name:GetText())
suite.check("its level on the badge", frame.face.badge.text:GetText() == "23")
suite.check("its mood", frame.mood:GetText() == "Happy", frame.mood:GetText())
suite.check("the food and how many", Plain(frame.food:GetText()) == "47 Haunch of Meat", frame.food:GetText())
suite.check("no time until feeding says how long one lasts", not frame.lasts:IsShown())
suite.check("the level and the part done", frame.xpLevel:GetText() == "Level 23"
    and frame.xpPercent:GetText() == "72%", frame.xpPercent:GetText())
suite.check("see-through at rest, no Feed and no close gem",
    not Strip.hot and (Strip.feed == nil or not Strip.feed:IsShown()) and not frame.close:IsShown())
local restWidth = frame:GetWidth()

-- Only the part that changed is drawn again.
local drawn = 0
local setText = frame.name.SetText
frame.name.SetText = function(self, ...) drawn = drawn + 1 return setText(self, ...) end
Refresh()
suite.check("the same pet does not draw its name again", drawn == 0, drawn)
frame.name.SetText = setText

-- Under the mouse: solid, Feed and the close gem, wider to hold them.
frame:GetScript("OnEnter")(frame)
suite.check("under the mouse it turns solid", Strip.hot == true)
suite.check("and shows Feed", Strip.feed and Strip.feed:IsShown())
local fp = Strip.feed._point
suite.check("Feed sits over the strip's right end, by screen position",
    fp[1] == "BOTTOMLEFT" and fp[2] == UIParent and fp[4] == 100 + Strip.feedX, tostring(fp[4]))
suite.check("Feed feeds the best food", (Strip.feed:GetAttribute("macrotext") or ""):find("/use 0 3", 1, true),
    Strip.feed:GetAttribute("macrotext"))
suite.check("and the close gem", frame.close:IsShown())
suite.check("the strip grows to hold them", frame:GetWidth() > restWidth)
frame:GetScript("OnLeave")(frame)
suite.check("off the mouse it rests again", not Strip.hot and not Strip.feed:IsShown() and not frame.close:IsShown())
suite.check("back to its width", frame:GetWidth() == restWidth)

-- A hungry pet: the dot follows the mood, Feed shows without the mouse, and
-- there is no card over the strip.
local notes = {}
local realShow = ns.Notice.Show
ns.Notice.Show = function(_, text) notes[#notes + 1] = text return {} end
happiness = 2
ns.PetStatus:Update()
suite.check("a hungry pet shows its mood", frame.mood:GetText() == "Content")
suite.check("and Feed, without the mouse", Strip.feed:IsShown())
suite.check("with no card", #notes == 0, notes[1])
suite.check("the warning still goes to chat", env.ChatText():find("Feed it", 1, true))

-- Low food: the count turns red, still no card.
bags[0][3].stackCount = 3
Refresh()
suite.check("low food says so", Plain(frame.food:GetText()) == "3 Haunch of Meat")
local r, g = unpack(frame.food._color)
suite.check("in red", r > 0.8 and g < 0.5, tostring(r) .. " " .. tostring(g))
suite.check("still no card", #notes == 0, notes[1])

-- Strip off: the card comes back.
Strip:Set(false)
ns.PetStatus.warnedAt = nil
ns.PetStatus:Update()
suite.check("with the strip off the card shows as before", #notes == 1, #notes)
Strip:Set(true)
ns.Notice.Show = realShow

-- In a fight Feed goes away and nothing secure is touched.
Fire("PLAYER_REGEN_DISABLED")
suite.check("a fight puts Feed away", not Strip.feed:IsShown())
_G.InCombatLockdown = function() return true end
happiness = 1
Refresh()
suite.check("and it stays away in the fight", not Strip.feed:IsShown())
suite.check("while the strip keeps up", frame.mood:GetText() == "Unhappy")
_G.InCombatLockdown = nil
Fire("PLAYER_REGEN_ENABLED")
suite.check("after the fight Feed is back", Strip.feed:IsShown())
happiness = 3
bags[0][3].stackCount = 47
Refresh()
suite.check("a happy pet puts Feed away", not Strip.feed:IsShown())

-- How long the food lasts: learned from the player's own feeds.
ns.charDB.petFeedGap = nil
Strip:NoteFed("Shadowpaw")
for _ = 1, 3 do
    clock = clock + 400
    Strip:NoteFed("Shadowpaw")
end
suite.check("three feeds teach how long one lasts", math.abs((Strip:FeedLasts() or 0) - 400) < 1,
    tostring(Strip:FeedLasts()))
Refresh()
-- 47 feeds of 400 seconds is about 5 hours.
suite.check("about 5 hours", frame.lasts:IsShown() and frame.lasts:GetText() == "About 5 hours",
    frame.lasts:GetText())
bags[0][3].stackCount = 3
Refresh()
suite.check("about 20 minutes for 3", frame.lasts:GetText() == "About 20 minutes", frame.lasts:GetText())
bags[0][3].stackCount = 47
clock = clock + 3 * 60 * 60
Strip:NoteFed("Shadowpaw")
suite.check("a long break teaches nothing", math.abs(Strip:FeedLasts() - 400) < 1)
clock = clock + 400
Strip:NoteFed("Ashpaw")
suite.check("another pet teaches nothing", math.abs(Strip:FeedLasts() - 400) < 1)

-- A demon or no pet: nothing.
class = "WARLOCK"
Refresh()
suite.check("a demon gets no strip", not frame:IsShown())
class = "HUNTER"
pet.exists = false
Refresh()
suite.check("no pet, no strip", not frame:IsShown())
pet.exists = true
Refresh()
suite.check("the pet back, the strip back", frame:IsShown())

-- On Pet Frame, under the game's frame; Free drags and keeps its spot.
do
    local petFrame = { shown = true }
    function petFrame:IsVisible() return self.shown end
    function petFrame:GetEffectiveScale() return 1 end
    function petFrame:GetRect() return 40, 600, 120, 50 end
    UIParent.GetEffectiveScale = function() return 1 end
    _G.PetFrame = petFrame
    Strip:SetPlace(true)
    local point, _, relativePoint, x, y = unpack(frame._point)
    suite.check("On Pet Frame it sits just under the pet frame",
        point == "TOPLEFT" and relativePoint == "BOTTOMLEFT" and x == 40 and y == 600 - Strip.FRAME_GAP,
        table.concat({ tostring(point), tostring(x), tostring(y) }, " "))
    local moved = false
    frame.StartMoving = function() moved = true end
    frame:GetScript("OnDragStart")(frame)
    suite.check("and can't be dragged off it", not moved)

    Strip:SetPlace(false)
    suite.check("Free is kept", ns.db.petStripPlace == "free")
    frame:GetScript("OnDragStart")(frame)
    suite.check("Free drags", moved)
    frame.GetLeft = function() return 300 end
    frame.GetBottom = function() return 200 end
    frame:GetScript("OnDragStop")(frame)
    suite.check("and keeps where it was dropped", ns.db.petStripX == 300 and ns.db.petStripY == 200)
    point, _, _, x, y = unpack(frame._point)
    suite.check("placed there", point == "BOTTOMLEFT" and x == 300 and y == 200)
    frame:GetScript("OnMouseUp")(frame, "RightButton")
    suite.check("right-click puts it back", ns.db.petStripX == nil and ns.db.petStripY == nil)
    Strip:SetPlace(true)
    _G.PetFrame = nil
end

-- The close gem turns it off.
frame:GetScript("OnEnter")(frame)
frame.close:GetScript("OnClick")(frame.close)
suite.check("the close gem turns it off", ns.db.petStrip == false and not frame:IsShown())
suite.check("and puts Feed away", not Strip.feed:IsShown())
suite.check("and says so", env.ChatText():find("Pet Strip: off.", 1, true))

-- /bpet strip.
ns.HandleSlash("strip on")
suite.check("/bpet strip on", ns.db.petStrip == true and frame:IsShown())
ns.HandleSlash("strip off")
suite.check("/bpet strip off", ns.db.petStrip == false and not frame:IsShown())

for _, k in ipairs(GLOBALS) do _G[k] = saved[k] end
UIParent.GetEffectiveScale = savedScale

suite.done()
