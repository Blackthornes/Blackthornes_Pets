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

suite.done()
