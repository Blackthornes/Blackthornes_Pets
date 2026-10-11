-- Blackthornes Pets -- Logic/BeastArrow.lua
-- The beast arrow: which way to walk to a beast picked in the Pet
-- Compendium (the owner asked 2026-10-08 for Farmer's arrow in Pets too).
-- Farmer's goal arrow and Equipment's quest arrow are where this comes
-- from; the addons ship apart, so it is a copy, not a call. Only one
-- Blackthornes arrow is on screen at a time (UI/BeastArrow.lua).
--
-- Shift-click a beast in the compendium and the arrow follows it, kept per
-- character. It points at the beast's spot from the compendium, which is
-- Forever's where Forever has shown one (your own tames, then the shipped
-- Forever data, then Classic). A beast with a zone and no spot points at the
-- zone's middle and says so; in that zone already, it says the beast is
-- about this zone; a zone whose map cannot be found, or on the other
-- continent, gets no arrow, only the zone. Nothing here makes up a
-- coordinate.
--
-- Direction and distance come from the game's world coordinates
-- (C_Map.GetWorldPosFromMapPos), which run across a continent in yards. A
-- client without them still gets an arrow within the map the player is on,
-- measured with the map's size. Everything the client is asked is read only
-- and inside a pcall; inside a dungeon the arrow hides.

local _, ns = ...

local BeastArrow = ns.NewModule("BeastArrow")

-- How close counts as there, in yards: a beast's spot is the middle of
-- where it wanders.
local ARRIVED = 35
BeastArrow.ARRIVED = ARRIVED

-- How often the place is worked out again, seconds. The pointing and the
-- distance are redone every time the dial draws.
BeastArrow.REFRESH = 2

-- Map types, as the client numbers them (Enum.UIMapType).
local CONTINENT = 2

local function Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local result = { pcall(fn, ...) }
    if not result[1] then return nil end
    return unpack(result, 2)
end

local function Plain(value)
    local ok, copy = pcall(function()
        if type(value) == "string" and value ~= "" then return value .. "" end
    end)
    return ok and copy or nil
end

local function Number(value)
    local ok, copy = pcall(function()
        local number = tonumber(value)
        if number and number == number then return number + 0 end
    end)
    return ok and copy or nil
end

local function Map() return type(_G.C_Map) == "table" and _G.C_Map or nil end


--------------------------------------------------------------------------------
-- The switch
--------------------------------------------------------------------------------

function BeastArrow.IsOn()
    return ns.db ~= nil and ns.db.beastArrow == true
end

function BeastArrow:SetOn(on)
    ns.db.beastArrow = on and true or false
    if on and ns.BeastArrowUI and ns.BeastArrowUI.Claim then ns.BeastArrowUI:Claim() end
    self:Changed()
    for _, name in ipairs({ "CompendiumUI", "SettingsUI" }) do
        local module = ns[name]
        if module and module.OnBeastArrowChanged then pcall(module.OnBeastArrowChanged, module) end
    end
end

--- Something the arrow shows changed: work it out again on the next draw.
function BeastArrow:Changed()
    self.listedAt = nil
    if ns.BeastArrowUI and ns.BeastArrowUI.Refresh then ns.BeastArrowUI:Refresh() end
end

--------------------------------------------------------------------------------
-- What it follows
--------------------------------------------------------------------------------

--- The beast the arrow follows: its compendium entry, or nil.
function BeastArrow:Beast()
    local id = ns.charDB and tonumber(ns.charDB.arrowBeast)
    if not (id and ns.Compendium) then return nil end
    local ok, entry = pcall(ns.Compendium.Get, ns.Compendium, id)
    return ok and type(entry) == "table" and entry or nil
end

--- Follow a compendium entry, and turn the arrow on. False for an entry
--- with nowhere known.
function BeastArrow:Follow(entry)
    if type(entry) ~= "table" or not tonumber(entry.id) then return false end
    if not entry.zone then return false end
    ns.charDB.arrowBeast = tonumber(entry.id)
    if not BeastArrow.IsOn() then
        self:SetOn(true)
    elseif ns.BeastArrowUI and ns.BeastArrowUI.Claim then
        ns.BeastArrowUI:Claim()
    end
    self:Changed()
    return true
end

--- Stop following any beast.
function BeastArrow:Clear()
    if ns.charDB then ns.charDB.arrowBeast = nil end
    self:Changed()
end

--- A beast was just tamed (TameRecord:Capture): if the arrow was following
--- it, its job is done, so it is put away (the owner, 2026-10-11: the
--- addons should finish what they start). Matched by NPC ID, else by name.
--- True when it was.
function BeastArrow:Tamed(npcID, name)
    local followed = ns.charDB and tonumber(ns.charDB.arrowBeast)
    if not followed then return false end
    local entry = self:Beast()
    local same = tonumber(npcID) == followed
    if not same and type(name) == "string" and entry and type(entry.name) == "string" then
        same = entry.name:lower() == name:lower()
    end
    if not same then return false end
    self:Clear()
    ns.Print(("tamed %s, arrow put away."):format(name or (entry and entry.name) or "your beast"))
    return true
end

--------------------------------------------------------------------------------
-- Where the player is
--------------------------------------------------------------------------------

local function MapInfo(mapID)
    local map = Map()
    if not (map and mapID) then return nil end
    local info = Read(map.GetMapInfo, mapID)
    if type(info) ~= "table" then return nil end
    local ok, name, kind, parent = pcall(function()
        return info.name, info.mapType, info.parentMapID
    end)
    if not ok then return nil end
    return { name = Plain(name), mapType = Number(kind), parent = Number(parent) }
end

--- A point on a map as world coordinates: continent, north, west (yards).
--- Nil when the client will not say.
function BeastArrow.WorldPos(mapID, x, y)
    local map = Map()
    if not (map and mapID and x and y) then return nil end
    if type(map.GetWorldPosFromMapPos) ~= "function" or type(_G.CreateVector2D) ~= "function" then
        return nil
    end
    local ok, continent, position = pcall(map.GetWorldPosFromMapPos, mapID, _G.CreateVector2D(x, y))
    if not ok or type(position) ~= "table" then return nil end
    local read, north, west = pcall(position.GetXY, position)
    if not read then return nil end
    continent, north, west = Number(continent), Number(north), Number(west)
    if not (continent and north and west) then return nil end
    return continent, north, west
end

local mapSizes = {}

--- How big a map is, in yards: width, height. Nil when the client will not
--- say. Kept once read.
function BeastArrow.MapSize(mapID)
    local kept = mapSizes[mapID]
    if kept then return kept[1], kept[2] end
    if kept == false then return nil end
    local map = Map()
    if not (map and mapID) then return nil end

    local width, height
    local ok, w, h = pcall(map.GetMapWorldSize, mapID)
    if ok then width, height = Number(w), Number(h) end

    -- The older way round: where the map's two corners are in the world.
    -- Across a map is along the world's west axis, down it along north.
    if not (width and height and width > 0 and height > 0) then
        local _, ax, ay = BeastArrow.WorldPos(mapID, 0, 0)
        local _, bx, by = BeastArrow.WorldPos(mapID, 1, 1)
        if ax and ay and bx and by then
            width, height = math.abs(ay - by), math.abs(ax - bx)
        end
    end

    if width and height and width > 0 and height > 0 then
        mapSizes[mapID] = { width, height }
        return width, height
    end
    mapSizes[mapID] = false
    return nil
end

--- Which way the player faces, radians anticlockwise from north. Nil if
--- not read.
function BeastArrow.Facing()
    return Number(Read(_G.GetPlayerFacing))
end

--- Where the player stands: { map, x, y (0-1), continent, north, west,
--- zone }, or nil when the client will not say (inside an instance,
--- usually).
function BeastArrow:Here()
    local map = Map()
    if not map then return nil end
    local mapID = Number(Read(map.GetBestMapForUnit, "player"))
    if not mapID then return nil end
    local position = Read(map.GetPlayerMapPosition, mapID, "player")
    if position == nil then return nil end
    local ok, x, y = pcall(function()
        if type(position) == "table" and position.GetXY then
            local px, py = position:GetXY()
            return px + 0, py + 0
        end
        return position + 0, nil
    end)
    if not ok or not x or not y or (x == 0 and y == 0) then return nil end

    local here = { map = mapID, x = x, y = y }
    here.continent, here.north, here.west = BeastArrow.WorldPos(mapID, x, y)
    here.zone = Plain(Read(_G.GetRealZoneText))
    return here
end

--- Inside a dungeon, raid or battleground: the game keeps the position to
--- itself there.
function BeastArrow.Inside()
    local ok, inside = pcall(function()
        return type(_G.IsInInstance) == "function" and _G.IsInInstance() and true or false
    end)
    return ok and inside or false
end

--- The continent map the map `mapID` sits on, or nil.
function BeastArrow.ContinentOf(mapID)
    for _ = 1, 8 do
        local info = MapInfo(mapID)
        if not info then return nil end
        if info.mapType == CONTINENT then return mapID end
        if not info.parent or info.parent <= 0 then return nil end
        mapID = info.parent
    end
    return nil
end

--------------------------------------------------------------------------------
-- Measuring
--------------------------------------------------------------------------------

--- Yards north and west from `here` to a point `x`, `y` (0-1) on map
--- `mapID`, or nil when the two cannot be put on one grid. A target's world
--- position is read once and kept on it.
function BeastArrow.Offset(here, mapID, x, y, target)
    if not (here and mapID and x and y) then return nil end

    if here.continent then
        local continent, north, west
        if target and target.world then
            continent, north, west = target.world[1], target.world[2], target.world[3]
        else
            continent, north, west = BeastArrow.WorldPos(mapID, x, y)
            if target and continent then target.world = { continent, north, west } end
        end
        if continent and continent == here.continent then
            return north - here.north, west - here.west
        end
        if continent then return nil end
    end

    -- No world coordinates: only the map the player is on can be measured.
    if mapID ~= here.map then return nil end
    local width, height = BeastArrow.MapSize(mapID)
    if not (width and height) then return nil end

    -- Map x runs east, map y runs south.
    return (here.y - y) * height, (here.x - x) * width
end

--- How far, in yards, and which way: radians anticlockwise from north.
function BeastArrow.Measure(north, west)
    return math.sqrt(north * north + west * west), math.atan2(west, north)
end

--- Which way the arrow turns on screen: the bearing less the facing,
--- anticlockwise, as a texture's rotation reads it. North up without a
--- facing.
function BeastArrow.Turn(bearing, facing)
    local turn = bearing - (facing or 0)
    while turn > math.pi do turn = turn - 2 * math.pi end
    while turn < -math.pi do turn = turn + 2 * math.pi end
    return turn
end

local COMPASS = { "north", "northwest", "west", "southwest", "south", "southeast", "east", "northeast" }

--- A bearing as a word: "northwest".
function BeastArrow.Compass(bearing)
    local step = math.floor((bearing / (math.pi / 4)) + 0.5) % 8
    return COMPASS[step + 1]
end

--- Rounded yards: "8 yd", "140 yd", "1,250 yd".
function BeastArrow.Yards(yards)
    local whole = math.floor(yards + 0.5)
    if whole >= 1000 then
        return ("%d,%03d yd"):format(math.floor(whole / 1000), whole % 1000)
    end
    if whole >= 100 then whole = math.floor(whole / 10 + 0.5) * 10 end
    return ("%d yd"):format(whole)
end


--------------------------------------------------------------------------------
-- The target
--------------------------------------------------------------------------------

--- The beast's place as a target from `here`, with { map, exact, area,
--- here, far } worked out.
function BeastArrow:Target(entry, here)
    local target = { zone = entry.zone, name = entry.name, x = tonumber(entry.x), y = tonumber(entry.y),
        forever = entry.forever }
    if entry.instance then
        target.far = true
        return target
    end
    local mapID = ns.Waypoints and ns.Waypoints:MapFor(entry.zone)
    target.map = mapID
    if mapID and target.x and target.y then
        target.mx, target.my = target.x / 100, target.y / 100
        if BeastArrow.Offset(here, mapID, target.mx, target.my, target) then
            target.exact = true
        else
            target.far = true
        end
    elseif mapID and here and entry.zone == here.zone then
        target.here = true
    elseif mapID then
        target.mx, target.my, target.area = 0.5, 0.5, true
        if not BeastArrow.Offset(here, mapID, 0.5, 0.5, target) then
            target.area, target.far = nil, true
        end
    else
        target.far = true
    end
    return target
end

--- The note under the place: where the spot comes from, or why there is
--- none.
function BeastArrow.Note(target, entry)
    if entry and entry.instance then return "Inside " .. (entry.instance == "raid" and "a raid" or "a dungeon"), "muted" end
    if target.far then return "Far from here: head for " .. (target.zone or "it"), "muted" end
    if target.here then return "No exact spot known in this zone", "accent" end
    if target.area then return "The middle of the zone: no exact spot known", "accent" end
    local why = ns.Compendium and ns.Compendium.ForeverText and ns.Compendium.ForeverText(entry)
    if why then return why, "good" end
    return "Where it lived in Classic", "muted"
end

--- Everything the dial needs for this moment:
---   { mode, beast, name, target, turn, yards, distance, place, note,
---     noteColor }
--- `mode` is "off", "inside", "none" (no beast picked), "blind" (no
--- position), "point", "arrived", "here" or "far".
function BeastArrow:State(clock)
    if not BeastArrow.IsOn() then return { mode = "off" } end
    if BeastArrow.Inside() then return { mode = "inside" } end

    local entry = self:Beast()
    if not entry then return { mode = "none" } end

    local here = self:Here()
    local level = entry.min and (entry.max and entry.max ~= entry.min
        and ("%d-%d"):format(entry.min, entry.max) or tostring(entry.min))
    local state = { beast = entry, name = level and ("%s  %s"):format(entry.name or "?", level) or entry.name }

    clock = clock or 0
    if self.stamp ~= entry.id or not self.listedAt or clock - self.listedAt >= BeastArrow.REFRESH
        or clock < self.listedAt then
        self.target = self:Target(entry, here)
        self.listedAt = clock
        self.stamp = entry.id
    end

    if not here then
        state.mode = "blind"
        return state
    end

    local target = self.target
    state.target = target
    state.place = target.zone or "?"
    state.note, state.noteColor = BeastArrow.Note(target, entry)

    if target.far then
        state.mode = "far"
        state.distance = target.zone or "Far away"
        return state
    end
    if target.here then
        state.mode = "here"
        state.distance = "In " .. (target.zone or "this zone")
        return state
    end

    local north, west = BeastArrow.Offset(here, target.map, target.mx, target.my, target)
    if not north then
        state.mode = "far"
        state.distance = target.zone or "Far away"
        return state
    end

    local yards, bearing = BeastArrow.Measure(north, west)
    local facing = BeastArrow.Facing()
    state.yards, state.bearing = yards, bearing
    state.turn = BeastArrow.Turn(bearing, facing)
    state.facing = facing ~= nil

    if not target.area and yards <= ARRIVED then
        state.mode = "arrived"
        state.distance = "You're there"
        return state
    end

    state.mode = "point"
    if target.area then
        state.distance = ("%s, %s"):format(target.zone or "?", BeastArrow.Yards(yards))
    else
        state.distance = BeastArrow.Yards(yards)
    end
    return state
end

--------------------------------------------------------------------------------
-- Checking what the client allows
--------------------------------------------------------------------------------

local function YesNo(ok)
    local colors = ns.COLORS
    return ("|c%s%s|r"):format(ok and colors.good or colors.warn, ok and "yes" or "no")
end

--- /bpet arrow check: what the arrow can read here, line by line.
function BeastArrow:Check()
    ns.Print("beast arrow check:")
    local here = self:Here()
    ns.PrintRaw(("  map position: %s%s"):format(YesNo(here),
        here and (" (map %d, %.1f, %.1f)"):format(here.map, here.x * 100, here.y * 100) or ""))

    local facing = BeastArrow.Facing()
    ns.PrintRaw(("  facing: %s%s"):format(YesNo(facing),
        facing and (" (%.2f, %s)"):format(facing, BeastArrow.Compass(facing)) or ""))

    ns.PrintRaw(("  world position: %s%s"):format(YesNo(here and here.continent),
        here and here.continent and (" (continent %d, %.0f, %.0f)"):format(here.continent, here.north, here.west)
        or ", so it only points within the map you are on"))

    local width, height
    if here then width, height = BeastArrow.MapSize(here.map) end
    ns.PrintRaw(("  map size: %s%s"):format(YesNo(width),
        width and (" (%.0f by %.0f yards)"):format(width, height) or ""))

    ns.PrintRaw(("  in an instance: %s"):format(BeastArrow.Inside() and "yes, so the arrow hides" or "no"))
    if ns.TomTom then ns.PrintRaw(ns.TomTom.CheckLine()) end

    local state = self:State(Number(Read(_G.GetTime)) or 0)
    if state.beast then
        ns.PrintRaw(("  following: %s, %s"):format(state.beast.name or "?", state.distance or state.mode))
    else
        ns.PrintRaw("  following: no beast. Shift-click one in the Pet Compendium.")
    end
end

--------------------------------------------------------------------------------
-- /bpet arrow
--------------------------------------------------------------------------------

local function Status()
    if BeastArrow.IsOn() then
        local entry = BeastArrow:Beast()
        if entry then
            ns.Print(("beast arrow on, pointing at %s."):format(entry.name or "?"))
        else
            ns.Print("beast arrow on. Shift-click a beast in the Pet Compendium for it to point at.")
        end
    else
        ns.Print("beast arrow off. /bpet arrow on shows it.")
    end
end

ns.RegisterCommand("arrow", "an arrow to a beast from the Pet Compendium (on, off, clear, check, tomtom, reset)", function(rest)
    local word = (rest or ""):lower():match("^%s*(%a*)") or ""
    if word == "" then
        BeastArrow:SetOn(not BeastArrow.IsOn())
        Status()
    elseif word == "on" or word == "off" then
        BeastArrow:SetOn(word == "on")
        Status()
    elseif word == "clear" then
        BeastArrow:Clear()
        ns.Print("beast arrow is not following a beast now.")
    elseif word == "check" then
        ns.KeepCheck("arrow check", BeastArrow.Check, BeastArrow)
    elseif word == "tomtom" then
        ns.TomTom:Command((rest or ""):lower():match("^%s*%a+%s+(%a+)"))
    elseif word == "reset" then
        if ns.BeastArrowUI and ns.BeastArrowUI.ResetPosition then ns.BeastArrowUI:ResetPosition() end
        ns.Print("beast arrow put back where it started.")
    else
        ns.Print("/bpet arrow on, off, clear, check, tomtom or reset.")
    end
end)
