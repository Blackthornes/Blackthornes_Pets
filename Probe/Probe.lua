-- Blackthornes Pets -- Probe/Probe.lua
-- /bpet probe: ask the running client what it actually supports for pets,
-- rather than trusting documentation written for another version of the game.
--
-- Same idea as Tradeskills' /bts probe and Equipment's /beq probe. It only
-- reads: nothing is changed, saved or sent anywhere. Every call is inside a
-- pcall, because Forever hands out secret values in instances that raise when
-- touched.
--
-- No pet feature leans on any of these yet. The probe is here so the first
-- one can be built on what the client answers, recorded in
-- docs/FOREVER_API_FINDINGS.md, instead of on a guess.

local _, ns = ...

local Probe = ns.NewModule("Probe")

-- The calls a pet addon might want: the current pet, its happiness, loyalty
-- and experience (hunter), its spells and action bar, the stable (hunter,
-- classic and retail shapes both), and the demon summons (warlock).
local APIS = {
    "UnitClass", "UnitLevel", "UnitExists", "UnitName", "UnitCreatureFamily",
    "UnitHealth", "UnitHealthMax", "UnitPower", "UnitPowerMax",
    "HasPetUI", "HasPetSpells", "GetPetHappiness", "GetPetLoyalty",
    "GetPetExperience", "GetPetFoodTypes", "GetPetTrainingPoints",
    "GetPetActionInfo", "GetNumStablePets", "GetStablePetInfo",
    "GetNumStableSlots", "C_StableInfo.GetStablePetInfo",
    "C_StableInfo.GetNumActivePets", "C_StableInfo.GetNumStablePets",
    "IsSpellKnown", "C_Spell.GetSpellName", "GetSpellInfo",
    "C_Container.GetContainerItemInfo", "GetItemCount", "C_Item.GetItemCount",
}

local function Has(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return false end
        value = value[part]
    end
    return type(value) == "function"
end

local function Line(label, value)
    local ok, text = pcall(tostring, value)
    ns.PrintRaw(("  |c%s%s|r  %s"):format(ns.COLORS.muted, label, ok and text or "(unreadable)"))
end

--- Call a global by name inside a pcall and join what it returns, or say why
--- not.
local function Read(name, ...)
    if not Has(name) then return "absent" end
    local results = { pcall(_G[name], ...) }
    if not results[1] then return "raised" end
    if #results == 1 then return "nothing" end

    local parts = {}
    for i = 2, #results do parts[#parts + 1] = tostring(results[i]) end
    return table.concat(parts, ", ")
end

function Probe:Run()
    ns.Print("probe: what this client supports for pets")

    -- Two lines rather than one per call, so the whole probe fits in the
    -- chat window without scrolling.
    local present, missing = {}, {}
    for _, api in ipairs(APIS) do
        if Has(api) then
            present[#present + 1] = api
        else
            missing[#missing + 1] = api
        end
    end
    Line("has", #present > 0 and table.concat(present, ", ") or "none of them")
    Line("missing", #missing > 0 and table.concat(missing, ", ") or "nothing")

    Line("class", Read("UnitClass", "player"))
    Line("level", Read("UnitLevel", "player"))

    Line("pet out", Read("UnitExists", "pet"))
    Line("pet name", Read("UnitName", "pet"))
    Line("pet family", Read("UnitCreatureFamily", "pet"))
    Line("pet level", Read("UnitLevel", "pet"))
    Line("pet UI", Read("HasPetUI"))
    Line("happiness", Read("GetPetHappiness"))
    Line("loyalty", Read("GetPetLoyalty"))
    Line("experience", Read("GetPetExperience"))
    Line("food types", Read("GetPetFoodTypes"))
    Line("stable slots", Read("GetNumStableSlots"))
end

ns.RegisterCommand("probe", "check what this client supports for pets (reads only)", function()
    Probe:Run()
end)
