-- The Pet Compendium: the Classic list, Forever's findings laid over it (and
-- winning), the filters and sorting, the window, and the tame record now
-- noting where a beast was tamed.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("compendium")

local ns = env.Load()
local C = ns.Compendium
local data = ns.CompendiumData

-- The shipped data.
local count, bad = 0, nil
for id, beast in pairs(data.BEASTS) do
    count = count + 1
    if not (type(beast.name) == "string" and data.FAMILIES[beast.family]
        and beast.min and beast.max and beast.min <= beast.max and beast.zone) then
        bad = bad or id
    end
    if beast.x and not (beast.x >= 0 and beast.x <= 100 and beast.y >= 0 and beast.y <= 100) then
        bad = bad or id
    end
end
suite.check("the Classic list holds hundreds of beasts", count > 400, count)
suite.check("every beast has a name, family, levels and a zone", bad == nil, bad)

local ids, dupe = {}, nil
for _, found in ipairs(ns.ForeverBeasts.FOUND) do
    suite.check("every Forever find names its source", type(found.source) == "string"
        and found.source:find("^https://"), found.name)
    if found.id then
        if ids[found.id] then dupe = found.id end
        ids[found.id] = true
    end
end
suite.check("no Forever find is listed twice", dupe == nil, dupe)

-- Classic, as it was.
local fang = C:Get(471)
suite.check("Mother Fang is a rare spider in Elwynn", fang and fang.rank == "rare"
    and fang.family == "Spider" and fang.zone == "Elwynn Forest")
suite.check("with what she eats", fang.diet == "Meat")
suite.check("and when she comes back", C.RespawnText(fang) == "3 hours", C.RespawnText(fang))
suite.check("she teaches Bite 2", C:Skills(fang)[1] and C:Skills(fang)[1].name == "Bite"
    and C:Skills(fang)[1].rank == 2)

-- Seen on Forever: Farmer's harvest wins over Classic, and Classic is kept.
local scorpid
for _, entry in ipairs(C:All()) do
    if entry.name == "Armored Scorpid" then scorpid = entry end
end
suite.check("a beast seen on Forever is marked", scorpid and scorpid.forever == "seen")
local seen = ns.ForeverBeasts.SEEN["Armored Scorpid"]
suite.check("and its Forever spot wins", scorpid.x == seen.x and scorpid.y == seen.y
    and scorpid.min == seen.min)
suite.check("with Classic's kept beside it", scorpid.classic and scorpid.classic.zone == "Durotar")

-- New on Forever.
local alpha = C:Get(250874)
suite.check("a new Forever fox is in the list", alpha and alpha.family == "Fox"
    and alpha.forever == "found" and alpha.zone == "Zephras Isle")
local skills = C:Skills(alpha)
suite.check("teaching Trickster's Dance", skills[1] and skills[1].name == "Trickster's Dance")
suite.check("a fox has no Classic diet to show", alpha.diet == nil)
suite.check("Forever's second Galestrider is a beast of its own",
    C:Get(251661).zone == "Zephras Isle" and C:Get(262523).zone == "Mulgore")
suite.check("a bird of prey is filed with Classic's owls", C:Get(276101).family == "Owl")

-- A Classic beast that teaches one of Forever's new skills keeps Classic's too.
local bear = C:Get(1797)
local names = {}
for _, skill in ipairs(C:Skills(bear)) do names[#names + 1] = skill.name .. skill.rank end
local list = table.concat(names, ",")
suite.check("the Giant Grizzled Bear teaches Swipe on Forever", list:find("Swipe1", 1, true), list)
suite.check("a Forever skill is never listed twice", select(2, list:gsub("Swipe1", "")) == 1)

-- This account's own tame wins over everything else.
ns.db.tamedBeasts = { [471] = { name = "Mother Fang", level = 11, zone = "Elwynn Forest", x = 63, y = 49,
    skills = { { name = "Bite", rank = 2 }, { name = "Web", rank = 1 } } } }
C:Invalidate()
fang = C:Get(471)
suite.check("a beast you tamed is marked yours", fang.forever == "mine")
suite.check("where you tamed it wins", fang.x == 63 and fang.max == 11)
suite.check("and what it taught you is the list", #C:Skills(fang) == 2)
ns.db.tamedBeasts = { [999001] = { name = "Strange Fox", level = 7, family = "Fox", zone = "Zephras Isle",
    skills = {} } }
C:Invalidate()
suite.check("a tame Classic never had gets an entry", C:Get(999001) and C:Get(999001).family == "Fox")
ns.db.tamedBeasts = nil
C:Invalidate()

-- Filters.
_G.UnitLevel = function(unit) if unit == "player" then return 10 end end
local all = C:List({})
suite.check("with no filter every beast is listed", #all == #C:All())
local now = C:List({ tameNow = true })
local over
for _, entry in ipairs(now) do if entry.min and entry.min > 10 then over = entry.name end end
suite.check("tameable now leaves out beasts above your level", #now > 0 and #now < #all and not over, over)
local rares = C:List({ raresOnly = true })
local notRare
for _, entry in ipairs(rares) do
    if entry.rank ~= "rare" and entry.rank ~= "rareelite" then notRare = entry.name end
end
suite.check("rares only is only rares", #rares > 20 and not notRare, notRare)
local cats = C:List({ family = "Cat" })
suite.check("a family shows only that family", #cats > 10 and cats[1].family == "Cat")
local prowl = C:List({ text = "prowl" })
local hasProwler = false
for _, entry in ipairs(prowl) do
    if entry.name == "Zulian Stalker" then hasProwler = true end
end
suite.check("the search finds a skill", hasProwler)
suite.check("and a zone", #C:List({ text = "zephras" }) > 10)
local forever = C:List({ foreverOnly = true })
suite.check("seen on Forever is the Forever beasts", #forever > 50 and forever[1].forever ~= nil)

-- New skills: a hunter whose Beast Training lists Bite 2 only.
ns.charDB.beastTraining = { readAt = 1, known = { ["Bite#2"] = true } }
local newSkills = C:List({ newSkills = true, family = "Spider" })
local fangListed = false
for _, entry in ipairs(newSkills) do if entry.id == 471 then fangListed = true end end
suite.check("a beast teaching only what you know is left out", not fangListed)
suite.check("one teaching something new stays", #newSkills > 0)
ns.charDB.beastTraining = nil

-- Sorting.
local byLevel = C:List({ sort = "level" })
suite.check("sorted by level", (byLevel[1].min or 0) <= (byLevel[#byLevel].min or 999))
local down = C:List({ sort = "level", descending = true })
local lastKnown = down[#down]
for i = #down, 1, -1 do if down[i].min then lastKnown = down[i] break end end
suite.check("and the other way round", down[1].min >= lastKnown.min)
suite.check("a beast with no level known goes last", down[#down].min == nil or down[1].min ~= nil)

-- Words.
suite.check("a level range reads 5-6", C.LevelText({ min = 5, max = 6 }) == "5-6")
suite.check("a spread of respawns reads as hours",
    C.RespawnText({ respawn = { 14400, 21600 } }) == "4-6 hours")
suite.check("a dungeon beast says so", C.PlaceText({ zone = "Wailing Caverns", instance = "dungeon" })
    == "Wailing Caverns (dungeon)")

-- The window.
local UI = ns.CompendiumUI
ns.HandleSlash("compendium")
suite.check("/bpet compendium opens it", UI.frame and UI.frame:IsShown())
suite.check("it wears the house frame", UI.frame.titan and UI.frame.titan.plate.label:GetText()
    == "Pet Compendium")
suite.check("the first row is filled", UI.rows[1]:IsShown() and UI.rows[1].name:GetText() ~= "")
suite.check("the footer counts the beasts", UI.footer:GetText():find("beasts", 1, true))

UI.ticks.raresOnly:GetScript("OnClick")(UI.ticks.raresOnly)
suite.check("ticking a box is saved", ns.db.compendium.raresOnly == true)
suite.check("and filters the list", UI.footer:GetText():find(" of ", 1, true), UI.footer:GetText())

UI:SortBy("level")
suite.check("a heading sorts", ns.db.compendium.sort == "level" and not ns.db.compendium.descending)
UI:SortBy("level")
suite.check("and again turns it round", ns.db.compendium.descending == true)

UI.familyStepper.plus:GetScript("OnClick")()
suite.check("the family chooser picks a family", ns.db.compendium.family == UI.families[1])

UI.rows[1]:GetScript("OnEnter")(UI.rows[1])
local text = table.concat(GameTooltip._lines, "\n")
suite.check("hovering a beast shows where and what it teaches",
    text:find(UI.rows[1].entry.name, 1, true) and text:find("Click to pin", 1, true), text)

ns.HandleSlash("compendium vuldren")
suite.check("/bpet compendium with words searches", UI.search:GetText() == "vuldren")

-- The settings page and the pets window open it too.
ns.CompendiumUI:Hide()
ns.SettingsUI:Show()
ns.SettingsUI.controls.openCompendium:GetScript("OnClick")(ns.SettingsUI.controls.openCompendium)
suite.check("Settings has a button for it", UI.frame:IsShown())
ns.CompendiumUI:Hide()
ns.UI:Show()
ns.UI.compendiumButton:GetScript("OnClick")(ns.UI.compendiumButton)
suite.check("so does the pets window", UI.frame:IsShown())

-- The tame record notes where a beast was tamed and what it is.
local map = {
    GetBestMapForUnit = function() return 1411 end,
    GetMapInfo = function() return { name = "Durotar" } end,
    GetPlayerMapPosition = function()
        return { GetXY = function() return 0.523, 0.418 end }
    end,
}
_G.C_Map = map
local zone, x, y = ns.TameRecord:Where()
suite.check("where the hunter stands is read", zone == "Durotar" and x == 52.3 and y == 41.8, tostring(x))
map.GetPlayerMapPosition = function() error("secret value") end
zone, x = ns.TameRecord:Where()
suite.check("an unreadable spot still keeps the zone", zone == "Durotar" and x == nil)
_G.C_Map = nil

suite.done()
