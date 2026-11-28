-- The My Pets tab: every pet a hunter owns, out and in the stable, as each
-- was last seen, saved per character by GUID. The stable's lists are shaped
-- as /bpet stable read them on Forever (2026-11-26).

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("mypets")

local ns = env.Load()
local MyPets, Window, Tabs = ns.MyPets, ns.MyPetsUI, ns.PetsTabs

local GUID = "Player-1-0000ABCD"
_G.UnitGUID = function(unit) return unit == "player" and GUID or nil end

-- Not a hunter: no tab, nothing read.
suite.check("no My Pets tab for other classes", #Tabs.Tabs() == 3)
suite.check("nothing read for other classes", MyPets:ReadOut() == false and MyPets:ReadStable() == false)

_G.UnitClass = function() return "Hunter", "HUNTER" end
suite.check("a hunter has the tab, second", #Tabs.Tabs() == 4 and Tabs.Tabs()[2].key == "mypets"
    and Tabs.Tabs()[2].text == "My Pets" and Tabs.Owner("mypets") == Window)

-- The stable, as the game gave it.
local cat = { creatureID = 2384, familyName = "Cat", happinessLevel = 3, icon = 132185, level = 26,
    loyaltyLevel = 5, loyaltyName = "Faithful", name = "Cat", petNumber = 2493004, slotID = 1, type = "Beast" }
local scorpid = { creatureID = 3127, familyName = "Scorpid", happinessLevel = 3, icon = 132195, level = 12,
    loyaltyLevel = 3, loyaltyName = "Submissive", name = "Scorpid", petNumber = 1570543, slotID = 2, type = "Beast" }
local atStable = true
_G.C_StableInfo = {
    IsAtStableMaster = function() return atStable end,
    GetActivePetList = function() return { cat } end,
    GetStabledPetList = function() return { scorpid } end,
    GetNumStableSlots = function() return 1 end,
    GetStablePetFoodTypes = function(slot) return slot == 1 and { "Meat", "Fish" } or { "Meat" } end,
}

suite.check("the stable is read", MyPets:ReadStable() == true)
local record = ns.db.myPets and ns.db.myPets[GUID]
suite.check("saved under the character's GUID", record ~= nil)
local list = MyPets:List()
suite.check("both pets", #list == 2, #list)
suite.check("the one out first", list[1].name == "Cat" and list[1].active == true and list[2].active == false)
suite.check("with what the stable says", list[2].family == "Scorpid" and list[2].level == 12
    and list[2].loyalty == "Submissive" and list[2].icon == 132195)
suite.check("and what each eats", list[1].foods[2] == "Fish" and list[2].foods[1] == "Meat")
local used, total = MyPets:Slots()
suite.check("one of one stable slot used", used == 1 and total == 1, tostring(used) .. "/" .. tostring(total))

-- A GUID the client won't read writes nothing.
_G.UnitGUID = function() return nil end
local before = ns.db.myPets
suite.check("no GUID, no list", #MyPets:List() == 0)
suite.check("and nothing written", MyPets:ReadStable() == false and ns.db.myPets == before
    and ns.db.myPets[GUID] == record)
_G.UnitGUID = function(unit) return unit == "player" and GUID or nil end

-- The pet out: its skills, speed and level, kept on the same record.
_G.UnitExists = function() return true end
_G.UnitName = function() return "Cat" end
_G.UnitLevel = function(unit) return unit == "pet" and 27 or 28 end
_G.UnitCreatureFamily = function() return "Cat", 2 end
_G.UnitAttackSpeed = function() return 1.5 end
local realKnown = ns.PetSkills.Known
ns.PetSkills.Known = function() return { Bite = 3, Claw = 3 } end
suite.check("the pet out is read", MyPets:ReadOut() == true)
list = MyPets:List()
suite.check("still two pets", #list == 2, #list)
suite.check("its new level", list[1].level == 27, list[1].level)
suite.check("its skills", list[1].known.Bite == 3 and list[1].familyID == 2)
suite.check("its speed", list[1].speed == 1.5)

-- Away from the stable, a pet missing from the list is kept.
atStable = false
_G.C_StableInfo.GetStabledPetList = function() return {} end
MyPets:ReadStable()
suite.check("away from the stable nothing is gone", #MyPets:List() == 2)
-- At the stable, it is gone (hidden, not deleted).
atStable = true
MyPets:ReadStable()
list = MyPets:List()
suite.check("abandoned at the stable, it is hidden", #list == 1 and list[1].name == "Cat")
suite.check("but still in the save", record.pets.n1570543 and record.pets.n1570543.gone == true)
_G.C_StableInfo.GetStabledPetList = function() return { scorpid } end
MyPets:ReadStable()
suite.check("seen again, it is back", #MyPets:List() == 2)

-- A pet first seen out, before the stable, takes its number later.
GUID = "Player-1-0000BEEF"
_G.UnitGUID = function(unit) return unit == "player" and GUID or nil end
MyPets:ReadOut()
local alt = ns.db.myPets[GUID]
suite.check("another character has its own record", alt and alt ~= record and alt.pets["p:Cat:Cat"] ~= nil)
MyPets:ReadStable()
suite.check("the stable gives it its number, one record",
    alt.pets["p:Cat:Cat"] == nil and alt.pets.n2493004 and alt.pets.n2493004.known.Bite == 3)

-- The words.
suite.check("never seen out", Window.FindText(nil) == "Call it out once to see its skills.")
suite.check("nothing to find", Window.FindText({ now = {} }) == "Has every skill for its level")
suite.check("one to find", Window.FindText({ now = { {} } }) == "1 skill to find")
local text, _, button = Window.FindText({ now = { {}, {} } })
suite.check("two to find, with Show Them", text == "2 skills to find" and button == true)
suite.check("one slot", Window.SlotsText(1, 1) == "1 of 1 stable slot used. Visit a stable master to swap pets.",
    Window.SlotsText(1, 1))
suite.check("more slots", Window.SlotsText(1, 2) == "1 of 2 stable slots used. Visit a stable master to swap pets.")
suite.check("no stable yet, no line", Window.SlotsText(nil, nil) == nil)

-- The tab.
local realToFind = ns.PetSkills.ToFind
ns.PetSkills.ToFind = function() return { now = { { name = "Bite", rank = 4 } }, later = {}, done = {} } end
Tabs:Open("mypets")
suite.check("the tab opens", Window.frame and Window.frame:IsShown())
suite.check("a card for each pet", Window.cards[1]:IsShown() and Window.cards[2]:IsShown()
    and not (Window.cards[3] and Window.cards[3]:IsShown()))
local first, second = Window.cards[1], Window.cards[2]
suite.check("the pet out says Out Now", first.tag.label:GetText() == "Out Now" and first.edge:IsShown())
suite.check("the stabled one In the Stable", second.tag.label:GetText() == "In the Stable"
    and not second.edge:IsShown())
suite.check("name, family and level", first.name:GetText() == "Cat" and first.family:GetText() == "Cat"
    and first.badge.label:GetText() == "27")
suite.check("its skills as chips", first.chips[1]:IsShown() and first.chips[1].label:GetText() == "Bite 3"
    and first.chips[2].label:GetText() == "Claw 3")
suite.check("what it still has to find", first.find:GetText() == "1 skill to find" and first.show:IsShown())
suite.check("a pet never out says so", second.find:GetText() == "Call it out once to see its skills."
    and not second.show:IsShown())
suite.check("the slots under the cards", Window.footer:GetText() == "1 of 1 stable slot used. Visit a stable master to swap pets.",
    Window.footer:GetText())
suite.check("the Compendium makes way", not (ns.CompendiumUI.frame and ns.CompendiumUI.frame:IsShown()))

-- Show Them on the stabled pet opens Skills to Find for it.
alt.pets.n2493004.active = false
local stabled = alt.pets.n2493004
Window:ShowThem(stabled)
suite.check("Show Them opens Skills to Find", ns.CompendiumUI.frame:IsShown() and ns.CompendiumUI.view == "find")
suite.check("for that pet", ns.SkillsToFindUI.pet == stabled)
suite.check("its name in the summary", ns.SkillsToFindUI.summary:GetText():find("^Cat has") ~= nil,
    ns.SkillsToFindUI.summary:GetText())
ns.CompendiumUI:ShowView("find")
suite.check("the switch goes back to the pet out", ns.SkillsToFindUI.pet == nil)
ns.CompendiumUI:Hide()

-- Show Them, then the Compendium closed and opened again: the pet out.
Window:ShowThem(stabled)
suite.check("Show Them again", ns.SkillsToFindUI.pet == stabled)
ns.CompendiumUI:Hide()
ns.CompendiumUI:Show()
suite.check("opened again, it is back on the pet out", ns.SkillsToFindUI.pet == nil)
-- And once that pet is the one out, its own list.
Window:ShowThem(stabled)
stabled.active = true
ns.SkillsToFindUI:Refresh()
suite.check("called out, it is the pet out", ns.SkillsToFindUI.pet == nil)
stabled.active = false
ns.CompendiumUI:Hide()

-- No pets yet: the empty line.
GUID = "Player-1-0000F00D"
_G.UnitGUID = function(unit) return unit == "player" and GUID or nil end
_G.UnitExists = function() return false end
Tabs:Open("mypets")
suite.check("no pets says how to see them", Window.empty:IsShown()
    and Window.empty:GetText() == "Call your pet or open the stable to see your pets here.")

ns.PetSkills.Known, ns.PetSkills.ToFind = realKnown, realToFind
_G.C_StableInfo, _G.UnitGUID, _G.UnitCreatureFamily, _G.UnitAttackSpeed = nil, nil, nil, nil
suite.done()
