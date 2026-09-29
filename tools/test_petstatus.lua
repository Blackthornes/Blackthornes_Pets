-- Reading the pet, and the warning when a hunter's pet needs feeding.
--
-- The client values are the ones the fourth /bpet probe found on Forever:
-- C_PetInfo in the classic shapes, food types as a list, and the pet's
-- current health secret.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("petstatus")

local ns = env.Load()
local PetStatus = ns.PetStatus

local happiness = 3
local function Hunter()
    _G.UnitClass = function() return "Hunter", "HUNTER" end
    _G.UnitExists = function() return true end
    _G.UnitName = function() return "Boar" end
    _G.UnitCreatureFamily = function() return "Boar", 5 end
    _G.UnitLevel = function() return 8 end
    _G.GetPetExperience = function() return 92, 1350 end
    _G.C_PetInfo = {
        GetPetHappiness = function()
            return happiness, ({ 75, 100, 125 })[happiness], happiness == 1 and -10 or 5
        end,
        GetPetLoyalty = function() return "Rebellious" end,
        GetPetFoodTypes = function() return { "Meat", "Fish" } end,
        GetPetTrainingPoints = function() return 0, 5 end,
    }
end
Hunter()

-- Reading.
local status = PetStatus:Read()
suite.check("sees the pet", status.exists and status.name == "Boar" and status.level == 8)
suite.check("reads happiness", status.happiness == 3 and status.damagePercent == 125)
suite.check("reads the food list", status.foods and #status.foods == 2 and status.foods[2] == "Fish")
suite.check("works out free training points", status.trainingFree == -5)

-- The pet's current health is secret on Forever; Read never touches it, and
-- a secret max health is dropped rather than raising.
local secret = newproxy(true)
getmetatable(secret).__tostring = function(self) return self end
getmetatable(secret).__concat = function() return secret end
_G.UnitHealthMax = function() return secret end
status = PetStatus:Read()
suite.check("a secret value is left out", status.healthMax == nil and status.name == "Boar")
_G.UnitHealthMax = nil

_G.UnitExists = function() return false end
suite.check("no pet out", PetStatus:Read().exists == false)
_G.UnitExists = function() error("secret") end
suite.check("an unreadable pet counts as none", PetStatus:Read().exists == false)
Hunter()

-- The warning.
local shown = {}
_G.UIErrorsFrame = { AddMessage = function(_, text) shown[#shown + 1] = text end }

happiness = 3
suite.check("a happy pet is left alone", PetStatus:CheckFeed() == false and #env.chat == 0)

happiness = 2
suite.check("content warns by default", PetStatus:CheckFeed() == true)
suite.check("in chat", env.ChatText():find("Boar is content. Feed it.", 1, true), env.ChatText())
suite.check("and on screen", shown[1] == "Boar is content. Feed it.", shown[1])
suite.check("only once while it stays content", PetStatus:CheckFeed() == false)

happiness = 1
suite.check("again when it drops to unhappy", PetStatus:CheckFeed() == true)
suite.check("not again after that", PetStatus:CheckFeed() == false)

happiness = 3
PetStatus:CheckFeed()
happiness = 2
suite.check("fed and let slip, it warns again", PetStatus:CheckFeed() == true)

-- Where the client has the raid warning frame, the warning goes there, with
-- its sound, rather than on the red error line that fades too fast.
local raid, sounds = {}, {}
_G.RaidWarningFrame = {}
_G.RaidNotice_AddMessage = function(_, text) raid[#raid + 1] = text end
_G.SOUNDKIT = { RAID_WARNING = 8959 }
_G.PlaySound = function(id) sounds[#sounds + 1] = id end
local before = #shown
happiness = 3
PetStatus:CheckFeed()
happiness = 1
PetStatus:CheckFeed()
suite.check("the warning goes to the raid warning frame", raid[1] == "Boar is unhappy. Feed it.", raid[1])
suite.check("not the error line", #shown == before)
suite.check("with the raid warning sound", sounds[1] == 8959)
_G.RaidWarningFrame, _G.RaidNotice_AddMessage, _G.SOUNDKIT, _G.PlaySound = nil, nil, nil, nil

-- Only when unhappy.
happiness = 3
PetStatus:CheckFeed()
ns.db.feedWarnOnlyUnhappy = true
happiness = 2
suite.check("the switch keeps a content pet quiet", PetStatus:CheckFeed() == false)
happiness = 1
suite.check("but not an unhappy one", PetStatus:CheckFeed() == true)

-- Off.
happiness = 3
PetStatus:CheckFeed()
ns.db.feedWarning = false
happiness = 1
suite.check("turned off it says nothing", PetStatus:CheckFeed() == false)
ns.db.feedWarning = true

-- A demon has no happiness to warn about.
_G.C_PetInfo = {}
suite.check("a pet without happiness is left alone", PetStatus:CheckFeed() == false)

-- The settings page switches are the same saved values.
ns.db.feedWarnOnlyUnhappy = false
ns.SettingsUI:Show()
local controls = ns.SettingsUI.controls
suite.check("the settings page shows the warning on", controls.feedWarning:GetChecked())
controls.feedWarning:GetScript("OnClick")(controls.feedWarning)
suite.check("unticking it turns the warning off", ns.db.feedWarning == false)
controls.feedWarnOnlyUnhappy:GetScript("OnClick")(controls.feedWarnOnlyUnhappy)
suite.check("the unhappy box sets its switch", ns.db.feedWarnOnlyUnhappy == true)

_G.UIErrorsFrame, _G.C_PetInfo = nil, nil
_G.UnitExists, _G.UnitName, _G.UnitCreatureFamily, _G.UnitLevel, _G.GetPetExperience = nil, nil, nil, nil, nil

suite.done()
