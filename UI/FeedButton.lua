-- Blackthornes Pets -- UI/FeedButton.lua
-- A small Feed button just above the quest tracker's "All Objectives", shown
-- only while a hunter's pet needs feeding and there is food it will eat.
--
-- Like the window's Feed button it is a secure action button (Feed Pet is
-- protected), so it can only be shown, hidden or moved out of combat. It is
-- put away as combat starts, which is no loss: Feed Pet cannot be cast in
-- combat anyway.
--
-- Drag moves it (the owner said build it, 2026-11-05), out of combat only.
-- The spot is kept per character in `BlackthornesPetsCharDB.feedButtonSpot`
-- (`{ x, y }`, its bottom left on UIParent; never rename it). Until it is
-- dragged it sits above the quest tracker as before, and a right-click puts
-- it back there.

local _, ns = ...
local L = ns.L

local FeedButton = ns.NewModule("FeedButton")

-- How far above the tracker's top edge the button sits.
local GAP = 4

-- Where it goes when there is no quest tracker on screen: the top right,
-- under the minimap, where the tracker usually starts.
local FALLBACK_X, FALLBACK_Y = -60, -230

local function InCombat()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    return ok and locked == true
end

function FeedButton:Build()
    if self.button then return self.button end

    -- The gold plaque (UI/Plaque.lua, the owner's pick, 2026-10-27): the
    -- food's icon, "Feed NAME" and the food with how many are carried, and
    -- a soft glow while the pet waits.
    local button = ns.Plaque.Create(UIParent, {
        name = "BlackthornesPetsQuickFeed",
        template = "SecureActionButtonTemplate",
    })
    button:SetLines(L["Feed"])
    button:SetFrameStrata("HIGH")
    button:RegisterForClicks("AnyUp", "AnyDown")
    -- Feed on the mouse going up, so a drag does not feed first.
    button:SetAttribute("useOnKeyDown", false)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        if InCombat() then return end
        self:StartMoving()
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- The game would keep the spot in its own layout file too; ours is
        -- the only one kept.
        local setUserPlaced = self.SetUserPlaced
        if setUserPlaced then setUserPlaced(self, false) end
        FeedButton:SaveSpot()
    end)
    button:HookScript("OnMouseUp", function(_, mouse)
        if mouse == "RightButton" then FeedButton:ResetSpot() end
    end)
    button:HookScript("OnEnter", function(self)
        local stack = FeedButton.stack
        if not (stack and GameTooltip) then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L.Format("Feed %s", ns.Food.ShownName(stack)))
        GameTooltip:AddLine(L.Format("%s is %s.", FeedButton.petName or L["Your pet"],
            FeedButton.mood or L["hungry"]), 0.7, 0.7, 0.7)
        GameTooltip:AddLine(L["Drag to move it. Right-click to put it back."], 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    button:HookScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:Hide()
    self.button = button
    return button
end

--- The quest tracker, if this client has one and it is on screen.
local function Tracker()
    local tracker = _G.ObjectiveTrackerFrame
    if type(tracker) ~= "table" then return nil end
    local ok, shown = pcall(tracker.IsVisible, tracker)
    if not (ok and shown) then return nil end
    return tracker
end

--- Put the button just above the tracker's top left corner. It is placed by
--- screen position rather than anchored to the tracker, so the tracker stays
--- free to move itself in combat.
function FeedButton:Place()
    local button = self.button
    button:ClearAllPoints()

    local spot = self:Spot()
    if spot then
        button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", spot[1], spot[2])
        return
    end

    local tracker = Tracker()
    if tracker then
        local ok, left, top, scale = pcall(function()
            return tracker:GetLeft(), tracker:GetTop(),
                tracker:GetEffectiveScale() / UIParent:GetEffectiveScale()
        end)
        if ok and type(left) == "number" and type(top) == "number" and type(scale) == "number" then
            button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * scale, top * scale + GAP)
            return
        end
    end
    button:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", FALLBACK_X, FALLBACK_Y)
end

--- The spot the player dragged it to, or nil.
function FeedButton:Spot()
    local spot = ns.charDB and ns.charDB.feedButtonSpot
    if type(spot) == "table" and type(spot[1]) == "number" and type(spot[2]) == "number" then
        return spot
    end
    return nil
end

--- Keep where it was dropped, as its bottom left on UIParent.
function FeedButton:SaveSpot()
    local button = self.button
    if not (button and ns.charDB) then return end
    local ok, left, bottom, scale = pcall(function()
        return button:GetLeft(), button:GetBottom(),
            button:GetEffectiveScale() / UIParent:GetEffectiveScale()
    end)
    if not (ok and type(left) == "number" and type(bottom) == "number" and type(scale) == "number") then
        return
    end
    ns.charDB.feedButtonSpot = { left * scale, bottom * scale }
    if not InCombat() then self:Place() end
end

--- Back above the quest tracker, out of combat.
function FeedButton:ResetSpot()
    if InCombat() or not ns.charDB then return end
    ns.charDB.feedButtonSpot = nil
    if self.button and self.button:IsShown() then self:Place() end
end

--- Whether the pet needs feeding: below the feed warning's line.
function FeedButton:Hungry(status)
    local level = status and status.exists and status.happiness
    return level ~= nil and level < ns.PetStatus:WarnBelow()
end

--- Show the button pointed at the best food while the pet is hungry, and
--- hide it otherwise. Out of combat only, unless `beforeCombat` says combat
--- is only about to start, when it can still be put away.
function FeedButton:Update(status, stacks, beforeCombat)
    local button = self.button
    if not button then return end
    if InCombat() and not beforeCombat then return end

    local stack = stacks and stacks[1]
    local wanted = not beforeCombat
        and ns.db and ns.db.quickFeed ~= false
        and stack and self:Hungry(status)

    if wanted then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", ns.Food:FeedMacro(stack))
        self:Place()
        button:Show()
        self.stack = stack
        self.petName = status.name
        self:Dress(status, stack, stacks)
        local info = ns.PetStatus.HAPPINESS[status.happiness]
        self.mood = info and info.name:lower()
    else
        button:Hide()
        button:SetGlowing(false)
        button:ClearAllPoints()
        button:SetAttribute("macrotext", nil)
        self.stack = nil
    end
end

--- The icon of an item, by its ID, or nil.
local function ItemIcon(itemID)
    if not itemID then return nil end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
        if ok and icon then return icon end
    end
    if type(GetItemIcon) == "function" then
        local ok, icon = pcall(GetItemIcon, itemID)
        if ok and icon then return icon end
    end
    return nil
end

--- How many of the stack's food the bags hold, over every stack of it.
function FeedButton.Carried(stack, stacks)
    local total = 0
    for _, other in ipairs(stacks or { stack }) do
        if other.itemID == stack.itemID then total = total + (tonumber(other.count) or 1) end
    end
    return math.max(total, tonumber(stack.count) or 1)
end

--- The plaque's words and icon: "Feed Cat", then "Roasted Quail x5".
function FeedButton:Dress(status, stack, stacks)
    local button = self.button
    local pet = status and type(status.name) == "string" and status.name ~= "" and status.name
    local first = pet and L.Format("Feed %s", pet) or L["Feed"]
    local food = ns.Food.ShownName(stack) or stack.name
    local second = food and L.Format("%s x%d", food, FeedButton.Carried(stack, stacks)) or nil
    button:SetIcon(ItemIcon(stack.itemID))
    button:SetLines(first, second)
    button:SetGlowing(true)
end

function FeedButton:OnEnable()
    self:Build()
    ns.RegisterEvent(self, "PLAYER_REGEN_DISABLED", function()
        FeedButton:Update(nil, nil, true)
    end)
end
