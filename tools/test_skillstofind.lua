-- Skills to Find, the Compendium's second view: the switch at the top, the
-- ranks the pet out lacks with the closest beast, later and done, the
-- summary, Show the Way, and back to All Beasts.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("skillstofind")

local ns = env.Load()
local UI, Find, PetSkills = ns.CompendiumUI, ns.SkillsToFindUI, ns.PetSkills

-- The lines, from a list worked out by PetSkills.
local beast = { name = "Coyote Packleader", zone = "Westfall", min = 11, max = 12, x = 40, y = 50 }
local snarler = { name = "Snarler", zone = "Feralas", min = 30, max = 31, x = 40, y = 50, rank = "rare" }
local found = {
    now = { { name = "Bite", rank = 4, beast = beast }, { name = "Claw", rank = 4, beast = beast } },
    later = { { name = "Bite", rank = 5, level = 30, beast = snarler } },
    done = { { name = "Bite", rank = 3 }, { name = "Claw", rank = 3 } },
    have = 6, of = 9,
}
local lines = Find.Lines(found)
suite.check("a heading for what can be tamed now first", lines[1].kind == "head"
    and lines[1].text == "YOU CAN TAME THESE NOW", lines[1].text)
suite.check("then its ranks", lines[2].name == "Bite" and lines[2].rank == 4 and lines[2].section == "now")
suite.check("the first is marked closest", lines[2].first == true and not lines[3].first)
suite.check("then later", lines[4].kind == "head" and lines[4].text == "LATER" and lines[5].rank == 5)
suite.check("then done", lines[6].text == "DONE" and lines[7].section == "done" and #lines == 8, #lines)
suite.check("an empty section has no heading", #Find.Lines({ now = {}, later = {}, done = found.done }) == 3)
suite.check("the summary", Find.SummaryText("Shadowpaw", found, 23) == "Shadowpaw has 6 of 9 skill ranks for level 23.",
    Find.SummaryText("Shadowpaw", found, 23))

-- In the Compendium: a hunter with a level 23 cat out.
_G.UnitClass = function() return "Hunter", "HUNTER" end
_G.UnitExists = function() return true end
_G.UnitName = function() return "Shadowpaw" end
_G.UnitLevel = function(unit) return unit == "pet" and 23 or 25 end
local realFind = PetSkills.CurrentToFind
PetSkills.CurrentToFind = function() return found end
UI:Show()
suite.check("the switch is at the top left", UI.viewSwitch and UI.viewSwitch.picked == "all")
suite.check("All Beasts shows the list", UI.search:IsShown() and UI.well:IsShown() and not Find.panel:IsShown())

Find.well.GetHeight = function() return 400 end
local firstBeast = ns.Compendium:All()[1]
if UI.OpenSheet then UI:OpenSheet(firstBeast) end
UI.viewSwitch.buttons.find:GetScript("OnClick")()
suite.check("the Beast Sheet closes", not (UI.sheet and UI.sheet:IsShown()))
suite.check("Skills to Find picks the view", UI.view == "find" and UI.viewSwitch.picked == "find")
suite.check("it shows the list of ranks", Find.panel:IsShown())
suite.check("and puts the beast list away", not UI.search:IsShown() and not UI.well:IsShown()
    and not UI.familyDropdown:IsShown())
suite.check("and every beast row", (function()
    for _, row in ipairs(UI.allRows) do if row:IsShown() then return false end end
    return true
end)())
suite.check("the summary is shown", Find.summary:GetText() == "Shadowpaw has 6 of 9 skill ranks for level 23.",
    Find.summary:GetText())
suite.check("the hint is under it", UI.footer:GetText() == "Tame the beast, use the skill until you learn it, then teach it to your pet.")

local rows = Find.rows
suite.check("the first rank row names the skill", rows[2].skill:GetText() == "Bite Rank 4", rows[2].skill:GetText())
suite.check("the beast", rows[2].beast:GetText() == "Coyote Packleader")
suite.check("its level and that it is closest", rows[2].beastSub:GetText() == "Level 11-12. Closest beast that teaches it.",
    rows[2].beastSub:GetText())
suite.check("where it lives", rows[2].zone:GetText() == "Westfall")
suite.check("with Show the Way", rows[2].way:IsShown())
suite.check("the next beast is not called closest", rows[3].beastSub:GetText() == "Level 11-12", rows[3].beastSub:GetText())
suite.check("a later rank says when", rows[5].zone:GetText() == "At level 30" and not rows[5].way:IsShown(),
    rows[5].zone:GetText())
suite.check("a done rank has a check and no beast", rows[7].check:IsShown() and not rows[7].beast:IsShown()
    and rows[7].skill:GetText():find("Bite Rank 3", 1, true))
suite.check("rows take turns light and dark", rows[2].rest == "glass" and rows[3].rest == "glassAlt")

local aimed
local realAim = UI.AimArrow
UI.AimArrow = function(_, entry) aimed = entry return true end
rows[2].way:GetScript("OnClick")(rows[2].way, "LeftButton")
suite.check("Show the Way points the arrow at the beast", aimed == beast)
UI.AimArrow = realAim

-- A short window shows what fits, and the wheel scrolls the rest.
Find.well.GetHeight = function() return 100 end
Find:Refresh()
suite.check("only what fits is drawn", Find.drawn < #Find.lines, Find.drawn)
UI.frame:GetScript("OnMouseWheel")(UI.frame, -1)
suite.check("the wheel scrolls the list", Find.offset == 1, Find.offset)
Find.well.GetHeight = function() return 400 end

-- A click on a rank row goes back to All Beasts, searching for the skill.
rows = Find.rows
Find:Show()
rows[2]:GetScript("OnClick")(rows[2])
suite.check("a row's click shows the beasts that teach it", UI.view == "all" and UI.searchText == "Bite"
    and UI.search:IsShown() and not Find.panel:IsShown(), UI.searchText)

-- No pet out.
PetSkills.CurrentToFind = function() return nil end
UI:ShowView("find")
suite.check("no pet says to call one", Find.empty:IsShown()
    and Find.empty:GetText() == "Call your pet to see what it still has to learn.", Find.empty:GetText())
_G.UnitClass = function() return "Mage", "MAGE" end
Find:Refresh()
suite.check("not a hunter says it is for hunters' pets", Find.empty:GetText() == "Skills to Find is for hunters' pets.")
PetSkills.CurrentToFind = realFind
_G.UnitClass = function() return "Hunter", "HUNTER" end

-- Opening the Compendium on a search goes to All Beasts.
UI:ShowSearch("Dash")
suite.check("a search from the Pet tab opens All Beasts", UI.view == "all" and UI.viewSwitch.picked == "all")

suite.done()
