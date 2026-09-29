-- /bpet probe reads the client and reports; it must never break on a client
-- that is missing something or raises.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("probe")

local ns = env.Load()
ns.HandleSlash("probe")
suite.check("runs on a client with none of the calls",
    env.ChatText():find("has|r  none of them", 1, true), env.ChatText())
suite.check("and lists them as missing on one line",
    env.ChatText():find("missing|r  UnitClass, UnitLevel,", 1, true), env.ChatText())
suite.check("a missing call reads as absent",
    env.ChatText():find("happiness|r  absent", 1, true), env.ChatText())

ns = env.Load()
_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitLevel = function(unit) return unit == "pet" and 11 or 12 end
_G.UnitExists = function() return true end
_G.UnitName = function() error("secret value") end
_G.HasPetUI = function() return true, true end
_G.GetPetHappiness = function() return 3, 125, 0 end
ns.HandleSlash("probe")
local text = env.ChatText()
suite.check("lists the calls it has", text:find("has|r  UnitClass, UnitLevel, UnitExists", 1, true), text)
suite.check("reads the class", text:find("class|r  Hunter, HUNTER", 1, true), text)
suite.check("reads the pet's level", text:find("pet level|r  11", 1, true), text)
suite.check("reads happiness", text:find("happiness|r  3, 125, 0", 1, true), text)
suite.check("a call that raises says so", text:find("pet name|r  raised", 1, true), text)

suite.check("a missing happiness face says so",
    text:find("happiness face|r  absent", 1, true), text)

ns = env.Load()
_G.C_StableInfo = { GetNumActivePets = function() return 1 end }
_G.C_PetJournal = { GetPetStableInfo = function() end }
_G.GetPetHappinessLevel = function() return 2 end
_G.PetFrameHappiness = {
    IsShown = function() return true end,
    GetTexCoord = function() return 0.375, 0.5624, 0, 0.359375 end,
}
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("reads a dotted C_ call", text:find("active pets|r  1", 1, true), text)
suite.check("reads the happiness face",
    text:find("happiness face|r  shown, coords 0.375 0.562 0.000 0.359", 1, true), text)
suite.check("finds pet calls under other names",
    text:find("GetPetHappinessLevel", 1, true), text)
suite.check("finds them inside C_ namespaces",
    text:find("C_StableInfo.GetNumActivePets", 1, true), text)
suite.check("leaves battle pets out",
    not text:find("C_PetJournal", 1, true), text)

-- A secret value: tostring hands back the value itself, and joining it
-- raises, which is what the client did on the first run of the wider probe.
ns = env.Load()
local secret = newproxy(true)
getmetatable(secret).__tostring = function(self) return self end
getmetatable(secret).__concat = function() error("attempt to concatenate a secret value") end
_G.UnitHealth = function() return secret end
_G.UnitHealthMax = function() return 100 end
ns.HandleSlash("probe")
text = env.ChatText()
suite.check("a secret value reads as secret instead of raising",
    text:find("pet health|r  (secret) / 100", 1, true), text)

suite.done()
