-- Show on Map when the game takes no pin (Forever turns its own user
-- waypoint down; a German player found nothing at the Crossroads,
-- 2026-10-29): our own gold marker goes on the beast's spot, the beast arrow
-- shows the way, a beast with only a zone gets "Somewhere in ZONE", and the
-- marker goes once you stand there.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("showonmap")

local ns = env.Load()
local Marker, Waypoints, C = ns.SpotMarker, ns.Waypoints, ns.Compendium

local opened
_G.OpenWorldMap = function(id) opened = id end
local MAPS = {
    [1414] = { name = "Kalimdor", parentMapID = 947 },
    [947] = { name = "Azeroth", parentMapID = 0 },
    [1413] = { name = "The Barrens", parentMapID = 1414 },
    [2521] = { name = "Zephras Isle", parentMapID = 1414 },
}
-- No SetUserWaypoint: the client takes no pin at all.
_G.C_Map = {
    GetBestMapForUnit = function() return 1413 end,
    GetMapInfo = function(id) return MAPS[id] end,
    GetMapChildrenInfo = function()
        return { { name = "The Barrens", mapID = 1413 }, { name = "Zephras Isle", mapID = 2521 } }
    end,
}

-- A client in another language finds these by ID, so they must be listed.
local Z = Waypoints.ZONE_MAPS
suite.check("Forever's own zones have a map ID", Z["Zephras Isle"] == 2521 and Z["Mount Hyjal"] == 2482
    and Z["Riverglades"] == 2548 and Z["Shen'dralas"] == 2652)

-- A beast with a spot: our marker, the arrow, the map.
local followed
local follow = ns.BeastArrow.Follow
ns.BeastArrow.Follow = function(_, entry) followed = entry; return true end
local beast = { id = 3035, name = "Savannah Cub", zone = "The Barrens", x = 52, y = 30 }
local before = #env.chat
suite.check("a beast shows with no game pin", C:Pin(beast) == true)
local said = table.concat(env.chat, "\n", before + 1)
suite.check("chat says where", said:find("Savannah Cub", 1, true) ~= nil, said)
local light = Marker.current
suite.check("our marker sits on the spot", light and light.map == 1413 and light.x == 52 and light.y == 30
    and light.gamePin == false and light.area == false)
suite.check("named for the beast", light and light.name == "Savannah Cub")
suite.check("with the beast arrow to tell when you're there", light and light.arrow == ns.BeastArrow)
suite.check("the arrow follows it", followed == beast)
suite.check("and the map opens on the zone", opened == 1413, opened)

-- Arrival: within the arrow's yards the marker goes, farther it stays.
local arrow = ns.BeastArrow
local here, offset = arrow.Here, arrow.Offset
local away = 80
arrow.Here = function() return { map = 1413, x = 0.5, y = 0.3 } end
arrow.Offset = function() return away, 0 end
Marker.arriveSince = 0
suite.check("it waits a moment before looking", Marker:Done(0.2) == false)
suite.check("far away it stays", Marker:Done(1) == false)
away = 10
suite.check("standing on it, it goes", Marker:Done(1) == true)
arrow.Here, arrow.Offset = here, offset
Marker:Clear()

-- A beast with only a zone: a marker in the middle that says so, and it stays.
followed, opened = nil, nil
before = #env.chat
local roamer = { id = 9999, name = "Isle Roamer", zone = "Zephras Isle" }
suite.check("a zone alone shows too", C:Pin(roamer) == true)
light = Marker.current
suite.check("a marker in the middle of the zone", light and light.map == 2521
    and light.x == 50 and light.y == 50 and light.area == true)
suite.check("that says somewhere in it", light and light.name == "Somewhere in Zephras Isle", light and light.name)
suite.check("chat says to head there", table.concat(env.chat, "\n", before + 1):find("head for Zephras Isle.", 1, true) ~= nil)
suite.check("the arrow heads for it", followed == roamer)
suite.check("and the zone's map opens", opened == 2521, opened)
suite.check("a zone marker never goes by itself", Marker:Done(5) == false)
ns.BeastArrow.Follow = follow

-- A zone with no map says so and leaves the marker as it was.
suite.check("a zone with no map fails", Waypoints:Show({ zone = "Nowhere" }, "it") == false)

-- The marker on the world map: only on its own map, placed by the canvas.
local canvas = env.Stub({ _width = 1000, _height = 600 })
local shownMap = 2521
_G.WorldMapFrame = env.Stub({
    _shown = true,
    GetCanvas = function() return canvas end,
    GetMapID = function() return shownMap end,
    ScrollContainer = { GetCanvasScale = function() return 1 end },
})
Marker.key = nil
Marker:Draw()
suite.check("drawn on its own map", Marker.spot ~= nil and Marker.spot:IsShown() == true)
local point = Marker.spot and Marker.spot._point
suite.check("in the middle of the canvas", point and point[4] == 500 and point[5] == -300,
    point and (tostring(point[4]) .. "," .. tostring(point[5])))
shownMap = 1413
Marker:Draw()
suite.check("hidden on another map", Marker.spot:IsShown() == false)
_G.WorldMapFrame = nil
Marker:Clear()

-- Effects: waves on Full, a still glow on Subtle, nothing moving on Off.
suite.check("waves go out at first on Full", #Marker.Look(1, "full").waves > 0)
suite.check("then only the glow breathes", #Marker.Look(Marker.WAVE_FOR + 1, "full").waves == 0)
suite.check("Subtle has no waves", #Marker.Look(1, "subtle").waves == 0)
suite.check("Off holds still", #Marker.Look(1, "off").waves == 0)

_G.C_Map, _G.OpenWorldMap = nil, nil
suite.done()
