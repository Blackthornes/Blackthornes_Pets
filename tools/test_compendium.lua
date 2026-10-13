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
    suite.check("no Forever find names a website", found.source == nil, found.name)
    if found.id then
        if ids[found.id] then dupe = found.id end
        ids[found.id] = true
    end
end
suite.check("no Forever find is listed twice", dupe == nil, dupe)

-- Families the Forever client has and 1.12 did not.
suite.check("Fox and Core Hound are known families that eat meat",
    data.FAMILIES[319] and data.FAMILIES[319][1] == "Fox" and data.FAMILIES[319][2] == "Meat"
    and data.FAMILIES[312] and data.FAMILIES[312][1] == "Core Hound" and data.FAMILIES[312][2] == "Meat")

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

-- Seen inside a dungeon: the spot is on the instance's own map, which the
-- pin and the arrow cannot use, so Classic's place outside it stays.
local coiler = C:Get(3630)
suite.check("a beast seen inside The Wailing Caverns is still marked", coiler and coiler.forever == "seen")
suite.check("and keeps its spot in The Barrens", coiler.zone == "The Barrens"
    and coiler.x == 46.1 and coiler.y == 34.6, coiler.zone)
suite.check("so it can still be pinned", C.PlaceText(coiler) == "The Barrens 46.1, 34.6", C.PlaceText(coiler))

-- New on Forever.
local alpha = C:Get(250874)
suite.check("a new Forever fox is in the list", alpha and alpha.family == "Fox"
    and alpha.forever == "found" and alpha.zone == "Zephras Isle")
local skills = C:Skills(alpha)
suite.check("teaching Trickster's Dance", skills[1] and skills[1].name == "Trickster's Dance")
suite.check("a fox shows the diet the Forever client gives its family", alpha.diet == "Meat")
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


-- Attack speed: Classic's swing time, fastest first, and
-- a tamed pet's real speed winning.
local tooth
for _, entry in ipairs(C:All()) do
    if entry.name == "Broken Tooth" then tooth = entry end
end
suite.check("Broken Tooth carries Classic's 1.0 speed", tooth and tooth.speed == 1, tooth and tooth.speed)
suite.check("written as players write it", C.SpeedText(tooth) == "1.0", C.SpeedText(tooth))
suite.check("1.25 keeps both places", C.SpeedText({ speed = 1.25 }) == "1.25")
-- Fastest first across every family, beasts of no known speed last, and
-- turned round the slowest first, with or without a box ticked.
local function Ordered(list, slowFirst)
    local last, seenNil = nil, false
    for _, entry in ipairs(list) do
        if entry.speed == nil then
            seenNil = true
        elseif seenNil then
            return false
        elseif last and (slowFirst and entry.speed > last or not slowFirst and entry.speed < last) then
            return false
        end
        last = entry.speed or last
    end
    return true
end
local fast = C:List({ sort = "speed" })
suite.check("speed sorts fastest first", Ordered(fast) and fast[1].speed == 1, fast[1].speed)
local slow = C:List({ sort = "speed", descending = true })
suite.check("and turned round, slowest first", Ordered(slow, true) and slow[1].speed > fast[1].speed)
for _, box in ipairs({ "foreverOnly", "raresOnly" }) do
    local up = C:List({ sort = "speed", [box] = true })
    local down = C:List({ sort = "speed", [box] = true, descending = true })
    suite.check("with " .. box .. " ticked it still turns round", #up > 1 and Ordered(up)
        and Ordered(down, true) and up[1].speed ~= down[1].speed, #up)
end
local cats = C:List({ sort = "speed", family = "Cat" })
suite.check("the fastest cat comes first", cats[1].name == "Broken Tooth", cats[1].name)
local slowCats = C:List({ sort = "speed", family = "Cat", descending = true })
local slowest = 0
for _, entry in ipairs(slowCats) do slowest = math.max(slowest, entry.speed or 0) end
suite.check("and turned round, the slowest", slowCats[1].speed == slowest, slowCats[1].speed)
suite.check("with a cat of no known speed still last", slowCats[#slowCats].speed == nil)
ns.db.tamedBeasts = { [2850] = { name = "Broken Tooth", level = 37, speed = 1.5, skills = {} } }
C:Invalidate()
tooth = C:Get(2850)
suite.check("a tamed pet's real speed wins", tooth.speed == 1.5 and tooth.speedSeen)
suite.check("with Classic's kept for the tooltip", tooth.classicSpeed == 1)
ns.db.tamedBeasts = nil
C:Invalidate()

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

-- A row under the mouse lights the house way: lighter glass, a gold edge
-- and a gold wash, only on that row, the wash hidden again on leaving.
local hovered, beside = UI.rows[1], UI.rows[2]
hovered:GetScript("OnEnter")(hovered)
suite.check("a row under the mouse shows its gold edge and wash",
    hovered.stripe:IsShown() and hovered.wash:IsShown() and not beside.wash:IsShown())
hovered:GetScript("OnLeave")(hovered)
suite.check("leaving, the edge and wash are hidden", not hovered.stripe:IsShown() and not hovered.wash:IsShown())

UI.ticks.raresOnly:GetScript("OnClick")(UI.ticks.raresOnly)
suite.check("ticking a box is saved", ns.db.compendium.raresOnly == true)
suite.check("and filters the list", UI.footer:GetText():find(" of ", 1, true), UI.footer:GetText())

local before = ns.db.compendium.raresOnly
ns.db.compendium.raresOnly = false
UI:SortBy("speed")
suite.check("the Speed heading sorts by speed", ns.db.compendium.sort == "speed")
suite.check("and the first row shows its speed", UI.rows[1].speed:GetText():find("%d%.%d"),
    UI.rows[1].speed:GetText())
ns.db.compendium.raresOnly = before
UI:SortBy("level")
suite.check("a heading sorts", ns.db.compendium.sort == "level" and not ns.db.compendium.descending)
UI:SortBy("level")
suite.check("and again turns it round", ns.db.compendium.descending == true)
UI:SortBy("level")
suite.check("a third time goes back to sorting by beast",
    ns.db.compendium.sort == "name" and not ns.db.compendium.descending)
ns.db.compendium.foreverOnly, ns.db.compendium.raresOnly = true, false
UI:SortBy("speed")
local fastest = UI.lines[1]
UI:SortBy("speed")
suite.check("with Seen on Forever ticked, Speed turns round", ns.db.compendium.descending == true
    and UI.lines[1] ~= fastest and (UI.lines[1].speed or 0) > (fastest.speed or 0))
ns.db.compendium.foreverOnly, ns.db.compendium.raresOnly = false, before
UI:Refresh()

-- The scroll bar: holding it drags the list, not the window.
UI.grip._top = 400
suite.check("the bar catches the mouse", UI.grip:IsShown())
local oldCursor = GetCursorPosition
GetCursorPosition = function() return 0, 400 - 2 end
UI:ScrollTo(0)
UI.grip:GetScript("OnMouseDown")(UI.grip, "LeftButton")
suite.check("catching the thumb holds it", UI.offset == 0 and UI.grip:GetScript("OnUpdate"))
GetCursorPosition = function() return 0, 400 - 2 - 374 / 2 end
UI.grip:GetScript("OnUpdate")(UI.grip)
local most = #UI.lines - 11
suite.check("dragging it scrolls the list", UI.offset > most * 0.3 and UI.offset < most * 0.7, UI.offset)
GetCursorPosition = function() return 0, 0 end
UI.grip:GetScript("OnUpdate")(UI.grip)
suite.check("and no further than the end", UI.offset == most, UI.offset)
UI.grip:GetScript("OnMouseUp")(UI.grip)
suite.check("letting go stops it", UI.grip:GetScript("OnUpdate") == nil)
GetCursorPosition = function() return 0, 400 - 370 end
UI:ScrollTo(0)
UI.grip:GetScript("OnMouseDown")(UI.grip, "LeftButton")
suite.check("a click lower on the bar jumps there", UI.offset > most * 0.8, UI.offset)
UI.grip:GetScript("OnMouseUp")(UI.grip)
suite.check("the bar sits above the rows", UI.grip:GetFrameLevel() > UI.frame:GetFrameLevel())
GetCursorPosition = oldCursor
UI:ScrollTo(0)

-- The family dropdown.
local picker = UI.familyDropdown
suite.check("the family picker starts on every family", picker:GetValue() == false)
suite.check("and lists every family after All families", #picker.options == #UI.families + 1
    and picker.options[1].text == "All families", #picker.options)
picker:GetScript("OnMouseDown")(picker)
suite.check("a click opens its menu", picker.menu:IsShown())
local shownEntries = 0
for _, entry in ipairs(picker.entries) do if entry:IsShown() then shownEntries = shownEntries + 1 end end
suite.check("a long list shows 12 at a time", shownEntries == math.min(12, #picker.options), shownEntries)
picker.entries[2]:GetScript("OnClick")()
suite.check("picking one filters by that family", ns.db.compendium.family == UI.families[1]
    and UI.lines[1].family == UI.families[1], ns.db.compendium.family)
suite.check("and closes the menu", not picker.menu:IsShown())
suite.check("the box names the family", picker:GetValue() == UI.families[1])
picker:GetScript("OnMouseDown")(picker)
picker.menu:GetScript("OnMouseWheel")(picker.menu, -1)
picker.entries[1]:GetScript("OnClick")()
suite.check("All families clears it", ns.db.compendium.family == nil, ns.db.compendium.family)
picker:GetScript("OnMouseDown")(picker)
picker.entries[2]:GetScript("OnClick")()

UI.rows[1]:GetScript("OnEnter")(UI.rows[1])
local text = table.concat(GameTooltip._lines, "\n")
local first = UI.rows[1].entry
suite.check("hovering a beast shows where and what it teaches",
    text:find(first.name, 1, true) and text:find(first.zone, 1, true), text)
-- Only a beast with a spot offers a pin: Waypoints:Pin turns the rest down.
suite.check("and offers a pin only where there is a spot",
    text:find((first.x and first.y) and "Click to pin" or "No exact spot to pin", 1, true), text)

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

-- The tame record keeps the real pet's speed, out of combat only, and adds
-- it to a pet tamed before speeds were kept.
_G.UnitAttackSpeed = function(unit) if unit == "pet" then return 1.2999, 0 end end
_G.InCombatLockdown = function() return false end
suite.check("the pet's speed is read to two places", ns.TameRecord:PetSpeed() == 1.3)
_G.InCombatLockdown = function() return true end
suite.check("but not in combat", ns.TameRecord:PetSpeed() == nil)
_G.InCombatLockdown = function() return false end
_G.UnitAttackSpeed = function() error("secret value") end
suite.check("a secret speed is no answer", ns.TameRecord:PetSpeed() == nil)
_G.UnitAttackSpeed = function(unit) if unit == "pet" then return 1.5 end end
_G.UnitGUID = function(unit) if unit == "pet" then return "Pet-0-1-2-3-2850-0000001" end end
ns.db.tamedBeasts = { [2850] = { name = "Broken Tooth", level = 37, skills = {} } }
suite.check("an old tame gets its speed when called out", ns.TameRecord:NoteSpeed() == 1.5
    and ns.db.tamedBeasts[2850].speed == 1.5)
suite.check("only once", ns.TameRecord:NoteSpeed() == nil)

-- A speed (or anything else) learned while the compendium is open shows at
-- once: the list is built again and the window drawn again.
ns.db.tamedBeasts = { [2850] = { name = "Broken Tooth", level = 37, skills = {} } }
C:Invalidate()
ns.db.compendium.family, ns.db.compendium.raresOnly = nil, false
ns.db.compendium.tameNow, ns.db.compendium.newSkills = false, false
ns.HandleSlash("compendium Broken Tooth")
suite.check("the open window shows Classic's speed first",
    UI.lines[1] and UI.lines[1].id == 2850 and not UI.lines[1].speedSeen)
ns.TameRecord:NoteSpeed()
suite.check("and the tamed speed as soon as it is noted",
    UI.lines[1] and UI.lines[1].speed == 1.5 and UI.lines[1].speedSeen == true,
    UI.lines[1] and UI.lines[1].speed)

-- Taming a beast already recorded with more skills keeps the old record but
-- still adds what it lacked, and the open window shows it.
ns.db.tamedBeasts = { [2850] = { name = "Broken Tooth", level = 37,
    skills = { { name = "Bite", rank = 1, spell = 1 }, { name = "Dash", rank = 1, spell = 2 } } } }
C:Invalidate()
UI:Refresh()
_G.UnitExists = function(unit) return unit == "pet" end
_G.GetPetActionInfo = function() end
ns.TameRecord.pending = { npcID = 2850, name = "Broken Tooth", level = 37, at = GetTime and GetTime() or 0 }
local kept = ns.TameRecord:Capture()
suite.check("a longer old record is kept", kept and #kept.skills == 2)
suite.check("but learns the speed it lacked", kept and kept.speed == 1.5)
suite.check("which the open window shows", UI.lines[1] and UI.lines[1].speedSeen == true)
_G.UnitExists, _G.GetPetActionInfo = nil, nil
ns.CompendiumUI:Hide()
ns.db.tamedBeasts = nil
_G.UnitGUID, _G.UnitAttackSpeed, _G.InCombatLockdown = nil, nil, nil

suite.done()
