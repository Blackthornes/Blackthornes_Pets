-- The map pin for a beast: only a pin the game kept is called pinned, a map
-- that takes no pin uses the map around it, and a cave sharing a zone's
-- name never takes the zone's place.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("waypoints")

local ns = env.Load()
local Waypoints = ns.Waypoints
local place = { zone = "Elwynn Forest", x = 42.1, y = 65.9 }

local waypoint, opened
_G.UiMapPoint = { CreateFromCoordinates = function(id, x, y) return { id = id, x = x, y = y } end }
_G.C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end }
_G.OpenWorldMap = function(id) opened = id end
local MAPS = {
    [1415] = { name = "Eastern Kingdoms", parentMapID = 947 },
    [947] = { name = "Azeroth", parentMapID = 0 },
    [1429] = { name = "Elwynn Forest", parentMapID = 1415 },
}
_G.C_Map = {
    GetBestMapForUnit = function() return 1429 end,
    GetMapInfo = function(id) return MAPS[id] end,
    GetMapChildrenInfo = function()
        return { { name = "Eastern Kingdoms", mapID = 1415 },
            { name = "Elwynn Forest", mapID = 2000, mapType = 4 },
            { name = "Elwynn Forest", mapID = 1429, mapType = 3 } }
    end,
    SetUserWaypoint = function(point) waypoint = point end,
    HasUserWaypoint = function() return waypoint ~= nil end,
}

suite.check("a zone's own map beats a cave of the same name", Waypoints:MapFor("Elwynn Forest") == 1429)
suite.check("pinning works", Waypoints:Show(place, "it") == true and waypoint and waypoint.id == 1429)
suite.check("and opens that map", opened == 1429)

-- A pin the game turns down is never called pinned.
_G.C_Map.HasUserWaypoint = function() return false end
local before = #env.chat
suite.check("a pin the game turns down fails", Waypoints:Show(place, "it") == false)
local said = table.concat(env.chat, "\n", before + 1)
suite.check("and never says pinned", said ~= "" and said:find("pinned", 1, true) == nil, said)
_G.C_Map.HasUserWaypoint = function() return waypoint ~= nil end

-- A map that takes no pin: the map around it, the spot moved over.
_G.C_Map.CanSetUserWaypointOnMap = function(id) return id ~= 1429 end
_G.C_Map.GetMapRectOnMap = function(id, parent)
    if id == 1429 and parent == 1415 then return 0.4, 0.6, 0.5, 0.7 end
end
opened, waypoint = nil, nil
suite.check("a zone that takes no pin pins the map around it", Waypoints:Show(place, "it") == true
    and waypoint and waypoint.id == 1415, waypoint and waypoint.id)
suite.check("at the same spot on it", waypoint and math.abs(waypoint.x - (0.4 + 0.421 * 0.2)) < 1e-9
    and math.abs(waypoint.y - (0.5 + 0.659 * 0.2)) < 1e-9)
suite.check("and opens that map", opened == 1415, opened)
_G.C_Map.CanSetUserWaypointOnMap = function() return false end
suite.check("no map up the line takes one: it fails", select(2, Waypoints:Pin(place)) == "noclient")

_G.C_Map, _G.UiMapPoint, _G.C_SuperTrack, _G.OpenWorldMap = nil, nil, nil, nil
suite.done()
