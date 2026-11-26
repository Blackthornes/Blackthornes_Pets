-- Blackthornes Pets -- Logic/MyPets.lua
-- Every pet a hunter owns, the one out and the ones in the stable, for the
-- My Pets tab (the owner said build it from a mockup, 2026-11-26).
--
-- The game lists the stable only while it is open (C_StableInfo, checked
-- with /bpet stable on 2026-11-26: name, family, level, loyalty, icon and
-- slot for each pet, and the stable's slots). So each pet is remembered as
-- it was last seen: when the stable opens or changes, and when a pet is out
-- (then its skills, food and attack speed too, which the stable list does
-- not give). Saved account wide in `myPets[guid]`, one record per character
-- by its GUID (never rename it). A GUID the client won't read writes
-- nothing. A pet the open stable no longer lists is marked `gone` and
-- hidden, not deleted; it comes back if it is seen again.

local _, ns = ...

local MyPets = ns.NewModule("MyPets")

local function Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c
end

local function Text(value)
    if type(value) ~= "string" then return nil end
    local plain = ns.PetStatus and ns.PetStatus.Plain and ns.PetStatus.Plain(value) or value
    if type(plain) ~= "string" or plain == "" then return nil end
    return plain
end

local function Number(value)
    if type(value) ~= "number" or value ~= value then return nil end
    return value
end

local function Stable(name)
    local api = _G.C_StableInfo
    return api and type(api[name]) == "function" and api[name] or nil
end

--- The character playing, by GUID, or nil when the client won't say.
function MyPets.Key()
    local guid = Read(_G.UnitGUID, "player")
    if type(guid) ~= "string" then return nil end
    local ok, readable = pcall(function() return guid:match("^Player%-") ~= nil end)
    return ok and readable and guid or nil
end

--- This character's saved record { pets = {}, slots }, made when `make`.
function MyPets:Record(make)
    local key = MyPets.Key()
    local db = ns.db
    if not (key and db) then return nil end
    if type(db.myPets) ~= "table" then
        if not make then return nil end
        db.myPets = {}
    end
    local record = db.myPets[key]
    if type(record) ~= "table" then
        if not make then return nil end
        record = { pets = {} }
        db.myPets[key] = record
    end
    if type(record.pets) ~= "table" then record.pets = {} end
    return record
end

local function Now()
    local now = Read(_G.time)
    return type(now) == "number" and now or 0
end

--- The saved pet with this name and family, and its key, or nil.
local function Find(pets, name, family)
    for key, pet in pairs(pets) do
        if pet.name == name and pet.family == family then return key, pet end
    end
    return nil
end

--------------------------------------------------------------------------------
-- The stable
--------------------------------------------------------------------------------

local function FoodsOf(slot)
    local fn = Stable("GetStablePetFoodTypes")
    local foods = fn and slot and Read(fn, slot)
    if type(foods) ~= "table" then return nil end
    local list = {}
    for _, food in ipairs(foods) do
        local name = Text(food)
        if name then list[#list + 1] = name end
    end
    return #list > 0 and list or nil
end

--- One pet from the stable's list into the save.
local function Note(record, info, active, seen)
    local name, family = Text(info.name), Text(info.familyName)
    if not (name and family) then return nil end
    local number = Number(info.petNumber)
    local key = number and ("n" .. number) or ("p:" .. name .. ":" .. family)
    local pet = record.pets[key]
    -- A pet first seen out (no number yet) gets its number now.
    if not pet then
        local oldKey, old = Find(record.pets, name, family)
        if old and oldKey:sub(1, 2) == "p:" then
            record.pets[oldKey] = nil
            pet = old
        end
    end
    pet = pet or {}
    record.pets[key] = pet
    pet.name, pet.family = name, family
    pet.level = Number(info.level) or pet.level
    pet.loyalty = Text(info.loyaltyName) or pet.loyalty
    pet.icon = Number(info.icon) or pet.icon
    pet.slot = Number(info.slotID) or pet.slot
    pet.active = active
    pet.foods = FoodsOf(pet.slot) or pet.foods
    pet.gone = nil
    pet.seen = Now()
    seen[key] = true
    return pet
end

--- Read the stable's lists, when the game gives them. True when it did.
function MyPets:ReadStable()
    if not (ns.PetSkills and ns.PetSkills.IsHunter()) then return false end
    local activeList = Stable("GetActivePetList")
    local stabledList = Stable("GetStabledPetList")
    local active = activeList and Read(activeList)
    local stabled = stabledList and Read(stabledList)
    if type(active) ~= "table" and type(stabled) ~= "table" then return false end
    local record = self:Record(true)
    if not record then return false end
    local seen = {}
    for _, info in ipairs(type(active) == "table" and active or {}) do
        if type(info) == "table" then Note(record, info, true, seen) end
    end
    for _, info in ipairs(type(stabled) == "table" and stabled or {}) do
        if type(info) == "table" then Note(record, info, false, seen) end
    end
    -- Only the open stable lists every pet, so only then is one gone.
    local atStable = Stable("IsAtStableMaster")
    if atStable and Read(atStable) == true then
        for key, pet in pairs(record.pets) do
            if not seen[key] then pet.gone = true end
        end
        local slots = Number((Read(Stable("GetNumStableSlots"))))
        if slots then record.slots = slots end
    end
    self:Changed()
    return true
end

--------------------------------------------------------------------------------
-- The pet out
--------------------------------------------------------------------------------

--- The pet out into the save: its level, loyalty, food, speed and skills.
function MyPets:ReadOut()
    local PetSkills = ns.PetSkills
    if not (PetSkills and PetSkills.IsHunter()) then return false end
    if Read(_G.UnitExists, "pet") ~= true then return false end
    local name = Text(Read(_G.UnitName, "pet"))
    local family, familyID = Read(_G.UnitCreatureFamily, "pet")
    family = Text(family)
    if not (name and family) then return false end
    local record = self:Record(true)
    if not record then return false end
    local key, pet = Find(record.pets, name, family)
    if not pet then
        key, pet = "p:" .. name .. ":" .. family, { name = name, family = family }
        record.pets[key] = pet
    end
    -- Only one pet is out.
    for _, other in pairs(record.pets) do
        if other ~= pet then other.active = false end
    end
    local status = ns.PetStatus and ns.PetStatus:Read() or {}
    local stats = ns.PetStatus and ns.PetStatus:ReadStats() or {}
    pet.active = true
    pet.gone = nil
    pet.familyID = Number(familyID) or PetSkills.FamilyID() or pet.familyID
    pet.level = PetSkills.PetLevel() or pet.level
    pet.loyalty = status.loyalty or pet.loyalty
    pet.foods = status.foods or pet.foods
    pet.speed = stats.speed or pet.speed
    local ok, known = pcall(PetSkills.Known, PetSkills)
    if ok and type(known) == "table" then pet.known = known end
    pet.seen = Now()
    self:Changed()
    return true
end

--------------------------------------------------------------------------------
-- What the tab reads
--------------------------------------------------------------------------------

--- This character's pets as last seen: the one out first, then by stable
--- slot, then by name. Gone pets are left out.
function MyPets:List()
    local record = self:Record(false)
    local list = {}
    for key, pet in pairs(record and record.pets or {}) do
        if not pet.gone then
            pet.key = key
            list[#list + 1] = pet
        end
    end
    table.sort(list, function(a, b)
        if (a.active == true) ~= (b.active == true) then return a.active == true end
        local sa, sb = a.slot or 999, b.slot or 999
        if sa ~= sb then return sa < sb end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

--- Stable slots: how many pets are in the stable, and how many slots there
--- are, or nil when the stable has never been opened.
function MyPets:Slots()
    local record = self:Record(false)
    if not (record and record.slots) then return nil end
    local used = 0
    for _, pet in pairs(record.pets) do
        if not pet.gone and not pet.active then used = used + 1 end
    end
    return used, record.slots
end

--- Skills to find for one saved pet (PetSkills:ToFind), or nil when its
--- skills have never been seen (a pet never out since this was built).
function MyPets:ToFind(pet)
    local PetSkills = ns.PetSkills
    if not (pet and pet.known and PetSkills) then return nil end
    local hunterLevel = Read(_G.UnitLevel, "player")
    hunterLevel = type(hunterLevel) == "number" and hunterLevel or nil
    local family = pet.familyID or PetSkills.FamilyByName(pet.family)
    return PetSkills:ToFind(pet.known, pet.level, family, hunterLevel, PetSkills.ZoneHere())
end

--- Something in the save changed: an open tab draws again.
function MyPets:Changed()
    local window = ns.MyPetsUI
    if window and window.Refresh then pcall(window.Refresh, window) end
end

--- Bursts of pet events read the pet out once, a moment later.
function MyPets:ReadOutSoon()
    if self.pending then return end
    self.pending = true
    local function Go()
        MyPets.pending = nil
        MyPets:ReadOut()
    end
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0.5, Go)
    else
        Go()
    end
end

function MyPets:OnEnable()
    if not (ns.PetSkills and ns.PetSkills.IsHunter()) then return end
    -- Either may be unknown to Forever; ns.RegisterEvent shrugs that off.
    for _, event in ipairs({ "PET_STABLE_SHOW", "PET_STABLE_UPDATE" }) do
        ns.RegisterEvent(self, event, function() MyPets:ReadStable() end)
    end
    ns.RegisterPetEvent(self, "UNIT_PET", function(_, _, unit)
        if unit == nil or unit == "player" then MyPets:ReadOutSoon() end
    end)
    ns.RegisterPetEvent(self, "UNIT_LEVEL", function(_, _, unit)
        if unit == "pet" then MyPets:ReadOutSoon() end
    end)
    for _, event in ipairs({ "PET_UI_UPDATE", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD" }) do
        ns.RegisterEvent(self, event, function() MyPets:ReadOutSoon() end)
    end
end
