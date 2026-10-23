-- The beast arrow: Farmer's and Equipment's arrow, pointing at a beast from
-- the Pet Compendium, and only one Blackthornes arrow up at a time.
--
-- What matters: it is off until turned on, and /bpet arrow, the
-- compendium's Arrow button and Settings share the switch; a Shift-click on
-- a beast follows it (a plain click still pins the map); it measures in
-- yards and turns the right way for where you face; close enough is "You're
-- there"; a zone with no spot points at its middle and says so, and a beast
-- inside a dungeon gets no arrow; inside a dungeon it hides; and when
-- another addon's arrow is aimed later, this one waits hidden until that one
-- is put away.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("beastarrow")

local ns = env.Load()
local Arrow, ArrowUI, C, UI = ns.BeastArrow, ns.BeastArrowUI, ns.Compendium, ns.CompendiumUI

local clock = 100
_G.GetTime = function() return clock end
local inside = false
_G.IsInInstance = function() return inside, inside and "party" or "none" end
local facing = 0
_G.GetPlayerFacing = function() return facing end
local zone = "Elwynn Forest"
_G.GetRealZoneText = function() return zone end
local shift = false
_G.IsShiftKeyDown = function() return shift end

local MAPS = {
    [37] = { name = "Elwynn Forest", mapType = 3, parentMapID = 13, continent = 0,
        top = 0, left = 0, width = 3000, height = 2000 },
    [52] = { name = "Westfall", mapType = 3, parentMapID = 13, continent = 0,
        top = -1500, left = 2600, width = 2500, height = 1700 },
    [13] = { name = "Eastern Kingdoms", mapType = 2, parentMapID = 947 },
    [1] = { name = "Durotar", mapType = 3, parentMapID = 12, continent = 1,
        top = 0, left = 0, width = 2000, height = 2000 },
    [12] = { name = "Kalimdor", mapType = 2, parentMapID = 947 },
    [947] = { name = "Azeroth", mapType = 1 },
}

_G.CreateVector2D = function(x, y) return { x = x, y = y, GetXY = function(self) return self.x, self.y end } end
local where = { map = 37, x = 0.45, y = 0.50 }

_G.C_Map = {
    GetBestMapForUnit = function() return where.map end,
    GetPlayerMapPosition = function() return _G.CreateVector2D(where.x, where.y) end,
    GetMapInfo = function(mapID)
        local map = MAPS[mapID]
        if not map then return nil end
        return { name = map.name, mapType = map.mapType, parentMapID = map.parentMapID, mapID = mapID }
    end,
    GetMapChildrenInfo = function(mapID)
        local children = {}
        local function Under(parent)
            for id, map in pairs(MAPS) do
                if map.parentMapID == parent then
                    children[#children + 1] = { name = map.name, mapType = map.mapType, mapID = id }
                    Under(id)
                end
            end
        end
        Under(mapID)
        return children
    end,
    GetWorldPosFromMapPos = function(mapID, vector)
        local map = MAPS[mapID]
        if not (map and map.width) then return nil end
        local north = map.top - vector.y * map.height
        local west = map.left - vector.x * map.width
        return map.continent, { GetXY = function() return north, west end }
    end,
    GetMapWorldSize = function(mapID)
        local map = MAPS[mapID]
        if map and map.width then return map.width, map.height end
        return nil
    end,
}

local function near(a, b, within) return a and b and math.abs(a - b) < (within or 0.01) end

--------------------------------------------------------------------------------
-- Off until asked for
--------------------------------------------------------------------------------

suite.check("off by default", ns.db.beastArrow == false and Arrow:State(clock).mode == "off")
ns.HandleSlash("arrow")
suite.check("/bpet arrow turns it on", Arrow.IsOn())
suite.check("with no beast picked there is nothing to follow", Arrow:State(clock).mode == "none")
ArrowUI:Refresh()
suite.check("and the dial stays hidden", not (ArrowUI.frame and ArrowUI.frame:IsShown()))
ns.HandleSlash("arrow off")

--------------------------------------------------------------------------------
-- Shift-click a beast
--------------------------------------------------------------------------------

local fang = C:Get(471)
suite.check("Mother Fang is in the compendium with a spot", fang and fang.x and fang.zone == "Elwynn Forest")

UI:Show()
local row = UI.rows and UI.rows[1]
suite.check("the compendium has rows", row ~= nil)
row.entry = fang

local pinned
local savedPin = C.Pin
C.Pin = function(_, entry) pinned = entry end
row:GetScript("OnClick")(row)
suite.check("a plain click still pins the map", pinned == fang and not Arrow.IsOn())
shift = true
pinned = nil
row:GetScript("OnClick")(row)
shift = false
C.Pin = savedPin
suite.check("a Shift-click follows it instead", pinned == nil and Arrow.IsOn() and ns.charDB.arrowBeast == 471)
suite.check("and says so", env.ChatText():find("pointing at Mother Fang", 1, true) ~= nil)

UI:ShowTooltip(row)
local tip = table.concat(GameTooltip._lines, "\n")
suite.check("the beast's tooltip says Shift-click aims the arrow", tip:find("Shift-click to point the arrow", 1, true) ~= nil, tip)

local state = Arrow:State(clock)
suite.check("points", state.mode == "point", state.mode)
local north = -(fang.y / 100 - 0.50) * 2000
local west = -(fang.x / 100 - 0.45) * 3000
local yards, bearing = math.sqrt(north * north + west * west), math.atan2(west, north)
suite.check("the distance in yards", near(state.yards, yards, 0.5), state.yards)
suite.check("the right way", near(state.bearing, bearing), state.bearing)
suite.check("named with its level", state.name == "Mother Fang  10", state.name)
suite.check("and where the spot comes from", state.note == "Where it lived in Classic", state.note)
facing = bearing
suite.check("facing it, straight ahead", near(Arrow:State(clock).turn, 0))
facing = 0

ArrowUI:Refresh()
suite.check("the dial shows", ArrowUI.frame and ArrowUI.frame:IsShown())
suite.check("the plate names the beast", ArrowUI.title:GetText() == "Mother Fang  10", ArrowUI.title:GetText())
suite.check("the arrow is up", ArrowUI.arrow:IsShown())

--------------------------------------------------------------------------------
-- TomTom: its arrow instead of the dial, when it is installed
--------------------------------------------------------------------------------

do
    local TomTom = ns.TomTom
    local dial = ArrowUI.frame
    ArrowUI:Draw(true)
    suite.check("without TomTom the dial shows", dial:IsShown() and TomTom.uid == nil)
    suite.check("the TomTom switch is on unless unticked", TomTom.IsOn())

    -- A TomTom keeping its waypoints, as the real one's calls take them.
    local points = {}
    _G.TomTom = {
        AddWaypoint = function(self, map, x, y, opts)
            local uid = { map, x, y, title = opts and opts.title }
            points[uid] = opts
            return uid
        end,
        RemoveWaypoint = function(self, uid) points[uid] = nil end,
    }
    local function Count()
        local count = 0
        for _ in pairs(points) do count = count + 1 end
        return count
    end

    local shownState = ArrowUI.state
    ArrowUI:Draw(true)
    local uid = TomTom.uid
    suite.check("with TomTom the dial hides", not dial:IsShown(), ArrowUI.state.mode)
    suite.check("and TomTom gets one waypoint", Count() == 1, Count())
    suite.check("at the dial's place", uid and uid[1] == ArrowUI.state.target.map
        and uid[2] == ArrowUI.state.target.mx and uid[3] == ArrowUI.state.target.my)
    suite.check("named for what it follows", uid and uid.title:find("Mother Fang  10: ", 1, true) ~= nil,
        uid and uid.title)
    suite.check("on TomTom's arrow, not saved in its list",
        uid and points[uid].crazy == true and points[uid].persistent == false)
    suite.check("this arrow still holds the screen over the others", _G.BlackthornesArrows.wants["Pets"])

    ArrowUI:Draw(true)
    suite.check("drawn again, the same waypoint stays", TomTom.uid == uid and Count() == 1)

    -- TomTom clears a waypoint on arrival (or the player removes it): the
    -- dial comes back rather than leaving nothing pointing the way.
    _G.TomTom.IsValidWaypoint = function(self, id) return points[id] ~= nil end
    points[uid] = nil
    ArrowUI:Draw(true)
    suite.check("a waypoint TomTom dropped brings the dial back", dial:IsShown() and Count() == 0)
    ArrowUI:Draw(true)
    suite.check("and it is not put back on TomTom for the same place", dial:IsShown() and Count() == 0)
    _G.TomTom.IsValidWaypoint = nil
    ns.HandleSlash("arrow off")
    ns.HandleSlash("arrow on")
    ArrowUI:Draw(true)
    uid = TomTom.uid
    suite.check("turned off and on, TomTom is tried again", not dial:IsShown() and Count() == 1)

    -- Another Blackthornes arrow aimed later: TomTom's goes too.
    local shared = _G.BlackthornesArrows
    shared.wants.Other, shared.claims.Other = true, 1e12
    ArrowUI:Draw(true)
    suite.check("another addon's arrow aimed later takes it away", Count() == 0)
    shared.wants.Other, shared.claims.Other = nil, nil
    ArrowUI:Draw(true)
    suite.check("and it comes back once that one is put away", Count() == 1)

    ns.HandleSlash("arrow tomtom off")
    ArrowUI:Draw(true)
    suite.check("arrow tomtom off: the dial again", ns.db.useTomTom == false and dial:IsShown() and Count() == 0)
    ns.HandleSlash("arrow tomtom on")
    ArrowUI:Draw(true)
    suite.check("and on: TomTom again", not dial:IsShown() and Count() == 1)

    ns.SettingsUI:Show()
    local box = ns.SettingsUI.controls.useTomTom
    suite.check("Settings has the TomTom switch, ticked", box and box:GetChecked() == true)
    box:GetScript("OnClick")(box)
    suite.check("which unticks it", ns.db.useTomTom == false and Count() == 0)
    box:GetScript("OnClick")(box)
    suite.check("and ticks it again", ns.db.useTomTom == true)
    ns.SettingsUI:Hide()
    ArrowUI:Draw(true)

    ns.HandleSlash("arrow off")
    suite.check("the arrow off takes the waypoint away", Count() == 0)
    ns.HandleSlash("arrow on")

    -- A TomTom that raises, or lacks the calls: the dial, and no error.
    _G.TomTom.AddWaypoint = function() error("different version") end
    TomTom:Clear()
    TomTom.refused = nil
    local okDraw = pcall(ArrowUI.Draw, ArrowUI, true)
    suite.check("a TomTom that raises falls back to the dial", okDraw and dial:IsShown())
    _G.TomTom = { AddWaypoint = "no" }
    TomTom.refused = nil
    ArrowUI:Draw(true)
    suite.check("so does one without the calls", dial:IsShown() and not TomTom.Installed())
    local okCheck, errCheck = pcall(ns.HandleSlash, "arrow check")
    suite.check("arrow check says what TomTom does", okCheck and env.ChatText():find("TomTom", 1, true) ~= nil, errCheck)
    _G.TomTom = nil
    TomTom.refused = nil
    ArrowUI.state = shownState
end

where = { map = 37, x = fang.x / 100 + 0.002, y = fang.y / 100 }
clock = clock + 5
suite.check("close by is You're there", Arrow:State(clock).mode == "arrived")
where = { map = 37, x = 0.45, y = 0.50 }

-- Forever's spot wins and is named.
local copy = {}
for key, value in pairs(fang) do copy[key] = value end
copy.forever = "seen"
suite.check("a Forever spot says so", Arrow.Note({ exact = true }, copy) == "Seen on Forever")

--------------------------------------------------------------------------------
-- No spot, inside, far
--------------------------------------------------------------------------------

local savedGet = C.Get
local beast = { id = 9001, name = "Plains Stalker", zone = "Westfall", min = 12, max = 13 }
C.Get = function(self, id) if id == 9001 then return beast end return savedGet(self, id) end
Arrow:Follow(beast)
clock = clock + 5
state = Arrow:State(clock)
suite.check("a zone with no spot: its middle", state.mode == "point" and state.target.area, state.mode)
suite.check("and says so", state.note:find("no exact spot", 1, true) ~= nil, state.note)

beast.instance, beast.zone = "dungeon", "Wailing Caverns"
clock = clock + 5
state = Arrow:State(clock)
suite.check("a beast in a dungeon: no arrow", state.mode == "far" and state.note == "Inside a dungeon", state.note)
beast.instance, beast.zone = nil, "Westfall"

zone = "Durotar"
where = { map = 1, x = 0.5, y = 0.5 }
clock = clock + 5
suite.check("from another continent: just the zone", Arrow:State(clock).distance == "Westfall")
zone = "Elwynn Forest"
where = { map = 37, x = 0.45, y = 0.50 }

suite.check("a beast with nowhere known cannot be followed",
    not Arrow:Follow({ id = 9002, name = "Mystery" }))
C.Get = savedGet
Arrow:Follow(fang)

inside = true
suite.check("inside a dungeon it hides", Arrow:State(clock).mode == "inside")
ArrowUI:Draw(true)
suite.check("the dial too", not ArrowUI.frame:IsShown())
inside = false
ArrowUI:Draw(true)
suite.check("and comes back outside", ArrowUI.frame:IsShown())

--------------------------------------------------------------------------------
-- One Blackthornes arrow at a time
--------------------------------------------------------------------------------

local shared = _G.BlackthornesArrows
suite.check("it shares its place in one table", type(shared) == "table" and shared.wants.Pets == true)

-- Farmer's arrow is aimed after this one: this one waits.
clock = clock + 5
shared.wants.Farmer = true
shared.claims.Farmer = clock
ArrowUI:Draw(true)
suite.check("another addon's arrow aimed later hides this one", not ArrowUI.frame:IsShown())
suite.check("still wanting its turn", shared.wants.Pets == true and Arrow.IsOn())

-- Aiming this one again brings it back on top.
clock = clock + 5
Arrow:Follow(fang)
ArrowUI:Draw(true)
suite.check("aiming this one brings it back", ArrowUI.frame:IsShown())
ArrowUI.Wins(true)
suite.check("over the other", shared.claims.Pets > shared.claims.Farmer)

-- Farmer's aimed again, then put away: this one comes back.
clock = clock + 5
shared.claims.Farmer = clock
ArrowUI:Draw(true)
suite.check("hidden again", not ArrowUI.frame:IsShown())
shared.wants.Farmer = nil
ArrowUI:Refresh()
suite.check("the other put away, this one shows", ArrowUI.frame:IsShown())

-- Turned off, it lets the others go.
ns.HandleSlash("arrow off")
suite.check("turned off, it stops wanting", shared.wants.Pets == nil and not ArrowUI.frame:IsShown())

--------------------------------------------------------------------------------
-- The compendium's Arrow button, Settings, check
--------------------------------------------------------------------------------

suite.check("the compendium has an Arrow button", UI.arrowButton ~= nil)
UI.arrowButton:GetScript("OnClick")(UI.arrowButton)
suite.check("which turns it on", Arrow.IsOn())
UI.arrowButton:GetScript("OnEnter")(UI.arrowButton)
tip = table.concat(GameTooltip._lines, "\n")
suite.check("and says what it does", tip:find("Points the way to a beast", 1, true) ~= nil, tip)

ns.SettingsUI:Show()
suite.check("Settings has the switch", ns.SettingsUI.controls.beastArrow:GetChecked() == true)
ns.SettingsUI.controls.beastArrow:GetScript("OnClick")(ns.SettingsUI.controls.beastArrow)
suite.check("which turns it off", not Arrow.IsOn())
env.chat = {}
suite.check("the check is typed only", ns.SettingsUI.controls.beastArrowCheck == nil)
ns.HandleSlash("arrow check")
local text = env.ChatText()
suite.check("/bpet arrow check runs", text:find("beast arrow check", 1, true) ~= nil
    and text:find("world position", 1, true) ~= nil, text)

ns.db.beastArrowX, ns.db.beastArrowY = 10, 10
ns.SettingsUI:ResetPositions()
suite.check("Put it back moves the dial too", ns.db.beastArrowX == nil)
ns.SettingsUI:Hide()

ns.HandleSlash("arrow on")
ArrowUI:Close()
suite.check("the red gem turns it off", not Arrow.IsOn())

-- The dial only moves and closes: no click, no tooltip.
ns.HandleSlash("arrow on")
local dial = ArrowUI.frame
local opened = 0
ns.CompendiumUI.Show = function() opened = opened + 1 end
suite.check("no click on the dial", dial:GetScript("OnMouseUp") == nil and ArrowUI.OnClick == nil)
suite.check("no tooltip on the dial", dial:GetScript("OnEnter") == nil and ArrowUI.ShowTooltip == nil)
dial:GetScript("OnDragStart")(dial)
dial:GetScript("OnDragStop")(dial)
suite.check("a drag opens nothing", opened == 0)
ns.HandleSlash("arrow off")

suite.done()
