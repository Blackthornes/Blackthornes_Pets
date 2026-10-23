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
    "C_Spell.GetSpellInfo", "UnitPowerType",
    "C_PetInfo.GetPetHappiness", "C_PetInfo.GetPetLoyalty",
    "C_PetInfo.GetPetFoodTypes", "C_PetInfo.GetPetTrainingPoints",
    "C_StableInfo.GetActivePetList", "C_StableInfo.IsAtStableMaster",
    "IsPlayerSpell", "GetNumCrafts", "GetCraftInfo", "GetCraftDisplaySkillLine",
    "TooltipDataProcessor.AddTooltipPostCall",
}

-- Words that mark a call as a classic pet mechanic. The first run on a
-- hunter found GetPetHappiness and friends absent while the pet frame still
-- showed a happiness face, so the client may keep them under other names.
-- Battle pets are left out: they are a different system.
-- The second run found them in C_PetInfo. "Stable" is matched with its capital
-- so Adjustable, TasksTable and canaccesstable stay out of the list.
local HINTS = { "happi", "loyal", "diet", "petfood", "trainingpoint", "feedpet" }
local SKIP = { C_PetJournal = true, C_PetBattles = true }

local function Resolve(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return nil end
        value = value[part]
    end
    return value
end

local function Has(path)
    return type(Resolve(path)) == "function"
end

local function Line(label, value)
    local ok, text = pcall(tostring, value)
    ns.PrintRaw(("  |c%s%s|r  %s"):format(ns.COLORS.muted, label, ok and text or "(unreadable)"))
end

--- A client value as plain text. In instances and on some units Forever hands
--- back secret values. tostring of one stays secret, and so does joining it
--- with "..", which the client allows; only table.concat and comparisons
--- raise. So ask the client first, where it can say, and otherwise prove the
--- text survives table.concat before handing it on.
local function Text(value)
    local isSecret = _G.issecretvalue
    if type(isSecret) == "function" then
        local ok, secret = pcall(isSecret, value)
        if not ok or secret then return "(secret)" end
    end
    local ok, text = pcall(function()
        local plain = tostring(value)
        return table.concat({ plain })
    end)
    return ok and text or "(secret)"
end

--- A table a call returned, as its size and up to eight of its fields, so a
--- list of pets or a pet's info can be read without a second probe. A list
--- shows its first entry's fields.
local function Summary(tbl)
    local ok, text = pcall(function()
        local count = 0
        for _ in pairs(tbl) do count = count + 1 end
        local sample, label = tbl, "table of " .. count
        if type(tbl[1]) == "table" then
            sample, label = tbl[1], label .. ", first"
        end
        local keys = {}
        for key in pairs(sample) do keys[#keys + 1] = Text(key) end
        table.sort(keys)
        local parts = {}
        for i = 1, math.min(#keys, 8) do
            local value = sample[keys[i]]
            if value == nil then value = sample[tonumber(keys[i])] end
            parts[i] = keys[i] .. "=" .. (type(value) == "table" and "table" or Text(value))
        end
        return label .. (#parts > 0 and (": " .. table.concat(parts, ", ")) or "")
    end)
    return ok and text or "a table (unreadable)"
end

--- Call a global (or a dotted C_ path) inside a pcall and join what it
--- returns, or say why not.
local function Read(name, ...)
    if not Has(name) then return "absent" end
    local results = { pcall(Resolve(name), ...) }
    if not results[1] then return "raised" end
    if #results == 1 then return "nothing" end
    if type(results[2]) == "table" then return Summary(results[2]) end

    local parts = {}
    for i = 2, #results do parts[#parts + 1] = Text(results[i]) end
    return table.concat(parts, ", ")
end

local function Hinted(name)
    if name:find("Stable", 1, true) then return true end
    local lower = name:lower()
    for _, hint in ipairs(HINTS) do
        if lower:find(hint, 1, true) then return true end
    end
    return false
end

--- Every global function, and every function in a C_ namespace, whose name
--- looks like a classic pet mechanic.
local function PetCalls()
    local found = {}
    for key, value in pairs(_G) do
        if type(key) == "string" then
            if type(value) == "function" and Hinted(key) then
                found[#found + 1] = key
            elseif type(value) == "table" and key:sub(1, 2) == "C_" and not SKIP[key] then
                for inner, fn in pairs(value) do
                    if type(inner) == "string" and type(fn) == "function"
                        and (Hinted(inner) or Hinted(key)) then
                        found[#found + 1] = key .. "." .. inner
                    end
                end
            end
        end
    end
    table.sort(found)
    return found
end

--- Whether the default pet frame's happiness face is showing, and which part
--- of its texture it shows (the texture coordinates pick the face).
local function HappinessFace()
    local face = _G.PetFrameHappiness
    if type(face) ~= "table" then return "absent" end
    local ok, shown = pcall(face.IsShown, face)
    if not ok then return "raised" end
    local texture = _G.PetFrameHappinessTexture or face
    local okCoord, coords = pcall(function() return { texture:GetTexCoord() } end)
    local okShown, text = pcall(function() return shown and "shown" or "hidden" end)
    if not okShown then text = "(secret)" end
    if okCoord and #coords > 0 then
        local parts = {}
        for i, v in ipairs(coords) do
            local okFormat, part = pcall(string.format, "%.3f", v)
            parts[i] = okFormat and Text(part) or "(secret)"
        end
        text = text .. ", coords " .. table.concat(parts, " ")
    end
    return text
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

    -- The Blizzard window style draws with the game's own art; this says
    -- which pieces the client has (UI/BlizzardLook.lua).
    if ns.BlizzardLook then
        for _, text in ipairs(ns.BlizzardLook.ProbeLines()) do
            local name, value = text:match("^(.-): (.*)$")
            Line(name or "style", value or text)
        end
    end

    -- The long list first, so the readings people look for end up at the
    -- bottom of the chat window.
    local calls = PetCalls()
    Line("pet-like calls", #calls > 0 and table.concat(calls, ", ") or "none found")

    Line("class", Read("UnitClass", "player"))
    Line("level", Read("UnitLevel", "player"))

    Line("pet out", Read("UnitExists", "pet"))
    Line("pet name", Read("UnitName", "pet"))
    Line("pet family", Read("UnitCreatureFamily", "pet"))
    Line("pet level", Read("UnitLevel", "pet"))
    Line("pet UI", Read("HasPetUI"))
    Line("experience", Read("GetPetExperience"))
    Line("pet health", Read("UnitHealth", "pet") .. " / " .. Read("UnitHealthMax", "pet"))
    Line("pet power", Read("UnitPowerType", "pet") .. "; " .. Read("UnitPower", "pet")
        .. " / " .. Read("UnitPowerMax", "pet"))
    Line("happiness face", HappinessFace())

    Line("active pets", Read("C_StableInfo.GetNumActivePets"))
    Line("stabled pets", Read("C_StableInfo.GetNumStablePets"))
    Line("at stable", Read("C_StableInfo.IsAtStableMaster"))
    Line("active list", Read("C_StableInfo.GetActivePetList"))

    Line("happiness", Read("C_PetInfo.GetPetHappiness"))
    Line("loyalty", Read("C_PetInfo.GetPetLoyalty"))
    Line("food types", Read("C_PetInfo.GetPetFoodTypes"))
    Line("training points", Read("C_PetInfo.GetPetTrainingPoints"))

    -- Which way the taming tooltip can tell a known skill. 17254 is the spell
    -- a hunter learns for Bite (Rank 1), 7370 for Charge (Rank 1). The craft
    -- calls answer only while the Beast Training window is open.
    Line("knows Bite 1", Read("IsPlayerSpell", 17254) .. "; " .. Read("IsSpellKnown", 17254))
    Line("knows Charge 1", Read("IsPlayerSpell", 7370) .. "; " .. Read("IsSpellKnown", 7370))
    -- The Pet care key's macro leans on these conditions (2026-10-11).
    Line("macro conditions", Read("SecureCmdOptionParse", "[nopet] no pet; [@pet,dead] dead; [combat] fighting; ready"))
    Line("knows Call/Revive Pet", Read("IsPlayerSpell", 883) .. "; " .. Read("IsPlayerSpell", 982))
    Line("pet dead", Read("UnitIsDead", "pet"))
    Line("craft window", Read("GetCraftDisplaySkillLine") .. "; " .. Read("GetNumCrafts")
        .. "; first " .. Read("GetCraftInfo", 1))
end

ns.RegisterHiddenCommand("probe", function()
    ns.KeepCheck("probe", Probe.Run, Probe)
end)
