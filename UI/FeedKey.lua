-- Blackthornes Pets -- UI/FeedKey.lua
-- The "Feed pet" key binding, under Options, Keybindings, AddOns. Pressing
-- the key feeds the hunter's pet the same food the Feed buttons would pick:
-- the first stack Food:Scan lists.
--
-- Bindings.xml binds the key to a click on a secure action button that is
-- never shown (a CLICK binding clicks the button whether it shows or not).
-- Its attributes can only change out of combat, so it is kept pointed at the
-- best food whenever the bags or the pet change out of combat, hungry or not,
-- so a player can top the pet up. In combat it keeps the last food it had,
-- which is no loss: Feed Pet cannot be cast in combat anyway.

local _, ns = ...

local FeedKey = ns.NewModule("FeedKey")

FeedKey.BUTTON = "BlackthornesPetsFeedKey"
FeedKey.BINDING = "CLICK " .. FeedKey.BUTTON .. ":LeftButton"

-- Names for Bindings.xml, shown under Options, Keybindings, AddOns.
_G.BINDING_HEADER_BLACKTHORNESPETS = "Blackthornes Pets"
_G["BINDING_NAME_" .. FeedKey.BINDING] = "Feed pet"

local function InCombat()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    return ok and locked == true
end

function FeedKey:Build()
    if self.button then return self.button end

    local button = CreateFrame("Button", self.BUTTON, UIParent, "SecureActionButtonTemplate")
    button:Hide()
    -- A key binding clicks the button twice, once as the key goes down and
    -- once as it comes up. Registered for the release only, with
    -- useOnKeyDown off so the ActionButtonUseKeyDown setting cannot make the
    -- button wait for a press it never gets, it feeds once per key press.
    -- Tradeskills' Disenchant key does the same (its API findings: a secure
    -- button set to act on key down never cast on Forever).
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("useOnKeyDown", false)
    -- Runs after the secure click, and only says why nothing happened, so it
    -- touches nothing protected.
    button:HookScript("OnClick", function() FeedKey:OnPressed() end)
    self.button = button
    return button
end

--- Why the key has nothing to feed, or nil when it has food to feed.
function FeedKey:Why(status, stacks)
    if not status or status.class ~= "HUNTER" then
        return "the Feed pet key is for hunters."
    end
    if not status.exists then return "you have no pet out." end
    if not status.foods then return "the game did not say what your pet eats." end
    if not (stacks and stacks[1]) then
        if stacks and stacks.incomplete then return "your bags are still loading. Try again in a moment." end
        return ("you have no food in your bags that %s will eat."):format(status.name or "your pet")
    end
    return nil
end

--- Point the button at the best food, or at nothing with the reason kept for
--- a key press. Out of combat only.
function FeedKey:Update(status, stacks)
    if InCombat() then return end
    local button = self:Build()

    local stack = stacks and stacks[1]
    local why = self:Why(status, stacks)
    if why then
        button:SetAttribute("type", nil)
        button:SetAttribute("macrotext", nil)
        self.stack = nil
    else
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", ns.Food:FeedMacro(stack))
        self.stack = stack
    end
    self.why = why
end

--- After a key press: nothing to say when there was food to feed; the
--- game reports its own errors, such as feeding in combat.
function FeedKey:OnPressed()
    if self.stack then return end
    ns.Print(self.why or "nothing to feed your pet yet.")
end

--- The key the player bound, or nil.
function FeedKey:Key()
    if type(GetBindingKey) ~= "function" then return nil end
    local ok, key = pcall(GetBindingKey, self.BINDING)
    if ok and type(key) == "string" and key ~= "" then return key end
    return nil
end

--- One line on the key, for /bpet food.
function FeedKey:State()
    local key = self:Key()
    local bound = key and ("Feed pet key (%s)"):format(key)
        or "Feed pet key (not set; Options, Keybindings, AddOns)"
    if self.stack then
        return ("%s feeds %s."):format(bound, self.stack.name)
    end
    return ("%s has nothing to feed: %s"):format(bound, self.why or "not checked yet.")
end

function FeedKey:OnEnable()
    self:Build()
end
