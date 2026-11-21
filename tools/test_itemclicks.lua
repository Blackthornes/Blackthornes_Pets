-- Item rows answer the game's item clicks (the owner, 2026-11-21): Shift-click
-- with a chat box open puts the item's link in it, Ctrl-click tries gear on,
-- and the row is left alone otherwise (UI/Widgets.lua ItemClick). The Pet
-- tab's food line is one such row, with the game's tooltip on hover.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("itemclicks")

local ns = env.Load()
local Widgets, UI = ns.Widgets, ns.UI

local LINK = "|cffffffff|Hitem:4592:::::|h[Longjaw Mud Snapper]|h|r"
local keys, chatOpen, inserted, dressed = {}, false, {}, {}
local function Reset() keys, chatOpen, inserted, dressed = {}, false, {}, {} end

_G.IsModifiedClick = function(kind)
    if kind == "CHATLINK" then return keys.shift and true or false end
    if kind == "DRESSUP" then return keys.ctrl and true or false end
    return false
end
_G.ChatEdit_GetActiveWindow = function() return chatOpen and {} or nil end
_G.ChatEdit_InsertLink = function(link)
    if not chatOpen then return false end
    inserted[#inserted + 1] = link
    return true
end
_G.DressUpItemLink = function(link) dressed[#dressed + 1] = link; return false end
local savedItem = _G.C_Item
_G.C_Item = { GetItemInfo = function(id) if id == 4592 then return "Longjaw Mud Snapper", LINK end end }

-- 1. The helper.
do
    Reset()
    suite.check("a plain click is left to the row", Widgets.ItemClick(4592) == false)
    keys.shift = true
    suite.check("Shift with the chat box shut is left to the row", Widgets.ItemClick(4592) == false)
    chatOpen = true
    suite.check("Shift with the chat box open links it", Widgets.ItemClick(4592) == true and inserted[1] == LINK)
    keys.shift, keys.ctrl = false, true
    suite.check("Ctrl on food asks the game, which will not dress it",
        Widgets.ItemClick(4592) == false and dressed[1] == LINK)
end

-- 2. The food line.
do
    Reset()
    _G.UnitClass = function() return "Hunter", "HUNTER" end
    UI:Show()
    local line = UI.foodLine
    suite.check("the food line is built", line ~= nil)
    if line then
        UI.foodItemID = 4592
        keys.shift, chatOpen = true, true
        line:GetScript("OnMouseUp")(line, "LeftButton")
        suite.check("Shift-click on the food line links the food", inserted[1] == LINK)
        line:GetScript("OnMouseUp")(line, "RightButton")
        suite.check("a right-click does not", #inserted == 1)
        UI.foodItemID = nil
        line:GetScript("OnMouseUp")(line, "LeftButton")
        suite.check("with no food there is nothing to link", #inserted == 1)
        local hyper
        _G.GameTooltip.SetHyperlink = function(_, link) hyper = link end
        UI.foodItemID = 4592
        line:GetScript("OnEnter")(line)
        suite.check("hovering shows the game's tooltip for the food", hyper == LINK)
    end
    UI:Hide()
end

_G.IsModifiedClick, _G.ChatEdit_GetActiveWindow, _G.ChatEdit_InsertLink, _G.DressUpItemLink = nil, nil, nil, nil
_G.C_Item = savedItem

suite.done()
