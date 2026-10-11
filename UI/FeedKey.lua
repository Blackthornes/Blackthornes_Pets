-- Blackthornes Pets -- UI/FeedKey.lua
-- The "Pet care" key binding, under Options, Keybindings, AddOns. One key
-- does whatever the pet needs (the owner, 2026-10-11: the addons should do
-- the work): a hunter's key calls the pet when none is out, revives it when
-- it is dead, and otherwise feeds it the same food the Feed buttons would
-- pick, the first stack Food:Scan lists. A warlock's key summons the last
-- demon used when none is out. Each press is still the player's own.
--
-- Bindings.xml binds the key to a click on a secure action button that is
-- never shown (a CLICK binding clicks the button whether it shows or not).
-- Its attributes can only change out of combat, so its macro is kept up to
-- date whenever the bags or the pet change out of combat, and leans on the
-- game's macro conditions ([nopet], [@pet,dead], [combat]) for what changes
-- in a fight: a pet that dies mid-fight is revived by the same macro.
-- Feeding stops in combat (Feed Pet cannot be cast there, and the food
-- would otherwise be eaten). In combat, with the pet alive, the same key
-- casts Mend Pet instead (a player asked, the owner agreed 2026-10-11).
--
-- A second key, "Revive pet", casts Revive Pet and nothing else, for a
-- player who wants it on its own button. It is a second secure button built
-- the same way.

local _, ns = ...

local FeedKey = ns.NewModule("FeedKey")

FeedKey.BUTTON = "BlackthornesPetsFeedKey"
FeedKey.BINDING = "CLICK " .. FeedKey.BUTTON .. ":LeftButton"
FeedKey.REVIVE_BUTTON = "BlackthornesPetsReviveKey"
FeedKey.REVIVE_BINDING = "CLICK " .. FeedKey.REVIVE_BUTTON .. ":LeftButton"

-- Names for Bindings.xml, shown under Options, Keybindings, AddOns. The
-- button keeps its old name, so a key already bound stays bound.
_G.BINDING_HEADER_BLACKTHORNESPETS = "Blackthornes Pets"
_G["BINDING_NAME_" .. FeedKey.BINDING] = "Pet care (call, revive, feed or mend)"
_G["BINDING_NAME_" .. FeedKey.REVIVE_BINDING] = "Revive pet"

FeedKey.CALL_PET = 883
FeedKey.REVIVE_PET = 982
FeedKey.MEND_PET = 136
-- Summon Imp, Voidwalker, Succubus and Felhunter, the first known one used
-- until the warlock summons one (kept per character in lastDemon).
FeedKey.DEMONS = { 688, 697, 712, 691 }

local function InCombat()
    if type(InCombatLockdown) ~= "function" then return false end
    local ok, locked = pcall(InCombatLockdown)
    return ok and locked == true
end

local function Global(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        value = type(value) == "table" and value[part] or nil
    end
    return type(value) == "function" and value or nil
end

--- The spell's name in the client's language, or the English one.
function FeedKey.SpellName(spellID, english)
    local fn = Global("C_Spell.GetSpellName") or Global("GetSpellInfo")
    if fn then
        local ok, name = pcall(fn, spellID)
        if ok and type(name) == "string" then
            local copied, plain = pcall(function() return name .. "" end)
            if copied and plain ~= "" then return plain end
        end
    end
    return english
end

--- Does the character know the spell? True when the client cannot say.
function FeedKey.Knows(spellID)
    for _, path in ipairs({ "IsPlayerSpell", "C_SpellBook.IsSpellKnown", "IsSpellKnown" }) do
        local fn = Global(path)
        if fn then
            local ok, known = pcall(fn, spellID)
            if ok and type(known) == "boolean" then return known end
        end
    end
    return true
end

local function PetIsDead()
    local fn = Global("UnitIsDead")
    if not fn then return false end
    local ok, dead = pcall(fn, "pet")
    return ok and dead == true
end

--- A hidden secure button a key binding can click.
local function NewKeyButton(name)
    local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    button:Hide()
    -- A key binding clicks the button twice, once as the key goes down and
    -- once as it comes up. Registered for the release only, with
    -- useOnKeyDown off so the ActionButtonUseKeyDown setting cannot make the
    -- button wait for a press it never gets, it feeds once per key press.
    -- Tradeskills' Disenchant key does the same (its API findings: a secure
    -- button set to act on key down never cast on Forever).
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("useOnKeyDown", false)
    return button
end

function FeedKey:Build()
    if self.button then return self.button end
    local button = NewKeyButton(self.BUTTON)
    -- Runs after the secure click, and only says why nothing happened, so it
    -- touches nothing protected.
    button:HookScript("OnClick", function() FeedKey:OnPressed() end)
    self.button = button
    self.reviveButton = NewKeyButton(self.REVIVE_BUTTON)
    return button
end

--- The revive key's macro: Revive Pet for a hunter who knows it, else nil.
function FeedKey:ReviveMacro(status)
    if not (status and status.class == "HUNTER") then return nil end
    if not self.Knows(self.REVIVE_PET) then return nil end
    return "/cast " .. self.SpellName(self.REVIVE_PET, "Revive Pet")
end

--- Why the key has nothing to feed, or nil when it has food to feed.
function FeedKey:Why(status, stacks)
    if not status or status.class ~= "HUNTER" then
        return "the Pet care key feeds a hunter's pet."
    end
    if not status.exists then return "you have no pet out." end
    if not status.foods then return "the game did not say what your pet eats." end
    if not (stacks and stacks[1]) then
        if stacks and stacks.incomplete then return "your bags are still loading. Try again in a moment." end
        return ("you have no food in your bags that %s will eat."):format(status.name or "your pet")
    end
    return nil
end

--- The demon a warlock's key summons: the last one summoned, else the
--- first one known. Its spell ID, or nil.
function FeedKey:Demon()
    local last = ns.charDB and tonumber(ns.charDB.lastDemon)
    if last and self.Knows(last) then return last end
    for _, spellID in ipairs(self.DEMONS) do
        if self.Knows(spellID) then return spellID end
    end
    return nil
end

local DEMON_NAMES = { [688] = "Summon Imp", [697] = "Summon Voidwalker",
    [712] = "Summon Succubus", [691] = "Summon Felhunter" }

--- The key's macro for this pet and these bags, and what it is set to do
--- with no pet out ("call", "revive", "summon" or nil); third, whether it
--- mends the pet in combat.
function FeedKey:Macro(status, stacks)
    local lines, absent, mend = {}, nil, nil
    if status and status.class == "HUNTER" then
        local call = self.Knows(self.CALL_PET) and self.SpellName(self.CALL_PET, "Call Pet")
        local revive = self.Knows(self.REVIVE_PET) and self.SpellName(self.REVIVE_PET, "Revive Pet")
        if revive and self.petDead and not status.exists then
            -- It died and its body is gone: Call Pet would only say so.
            lines[#lines + 1] = ("/cast [nopet][@pet,dead] %s"):format(revive)
            absent = "revive"
        elseif revive and call then
            lines[#lines + 1] = ("/cast [@pet,dead] %s; [nopet] %s"):format(revive, call)
            absent = "call"
        elseif call then
            lines[#lines + 1] = ("/cast [nopet] %s"):format(call)
            absent = "call"
        elseif revive then
            lines[#lines + 1] = ("/cast [@pet,dead] %s"):format(revive)
        end
        mend = self.Knows(self.MEND_PET) and self.SpellName(self.MEND_PET, "Mend Pet") or nil
        if mend then
            -- Only a living pet in a fight: the call/revive line above has
            -- the other cases, and feeding stops at [combat] below.
            lines[#lines + 1] = ("/cast [@pet,exists,nodead,combat] %s"):format(mend)
        end
        local stack = not self:Why(status, stacks) and stacks[1]
        if stack then
            lines[#lines + 1] = "/stopmacro [nopet][@pet,dead][combat]"
            lines[#lines + 1] = ns.Food:FeedMacro(stack)
        end
    elseif status and status.class == "WARLOCK" then
        local demon = self:Demon()
        if demon then
            lines[#lines + 1] = ("/cast [nopet] %s"):format(self.SpellName(demon, DEMON_NAMES[demon]))
            absent = "summon"
        end
    end
    if #lines == 0 then return nil, nil end
    return table.concat(lines, "\n"), absent, mend ~= nil
end

--- Point the button at what the pet needs, or at nothing with the reason
--- kept for a key press. Out of combat only; whether the pet is dead is
--- noted in combat too, for the next update.
function FeedKey:Update(status, stacks)
    if status and status.exists then self.petDead = PetIsDead() end
    if InCombat() then return end
    local button = self:Build()

    local macro, absent, mends = self:Macro(status, stacks)
    local why = self:Why(status, stacks)
    if macro then
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", macro)
    else
        button:SetAttribute("type", nil)
        button:SetAttribute("macrotext", nil)
    end
    self.stack = not why and stacks and stacks[1] or nil
    self.absent = absent
    self.mends = mends
    self.isWarlock = status and status.class == "WARLOCK" or false
    self.why = why

    local revive = self.reviveButton
    local reviveMacro = self:ReviveMacro(status)
    if revive then
        if reviveMacro then
            revive:SetAttribute("type", "macro")
            revive:SetAttribute("macrotext", reviveMacro)
        else
            revive:SetAttribute("type", nil)
            revive:SetAttribute("macrotext", nil)
        end
    end
end

--- After a key press: nothing to say when the key did something; the game
--- reports its own errors. Otherwise why nothing happened.
function FeedKey:OnPressed()
    local status = ns.PetStatus and ns.PetStatus:Read() or {}
    if not status.exists or PetIsDead() then
        if self.absent then return end
    elseif InCombat() and self.mends then
        return
    elseif self.stack then
        if InCombat() then ns.Print("your pet can't be fed in combat.") end
        return
    elseif self.isWarlock then
        ns.Print("your demon is already out.")
        return
    end
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
    local bound = key and ("Pet care key (%s)"):format(key)
        or "Pet care key (not set; Options, Keybindings, AddOns)"
    local absent = self.absent == "call" and "calls your pet when none is out"
        or self.absent == "revive" and "revives your pet"
        or self.absent == "summon" and "summons your demon when none is out" or nil
    if self.mends then absent = (absent and (absent .. ", and ") or "") .. "mends it in combat" end
    if self.stack then
        return ("%s feeds %s%s."):format(bound, self.stack.name, absent and (", and " .. absent) or "")
    end
    if absent then return ("%s %s."):format(bound, absent) end
    return ("%s has nothing to feed: %s"):format(bound, self.why or "not checked yet.")
end

--- A warlock summoned a demon: the key summons that one from now on.
function FeedKey:OnCast(spellID)
    for _, demon in ipairs(self.DEMONS) do
        if spellID == demon then
            if ns.charDB then ns.charDB.lastDemon = demon end
            if ns.PetStatus and not InCombat() then ns.PetStatus:Update() end
            return true
        end
    end
    return false
end

function FeedKey:OnEnable()
    self:Build()
    -- The pet dying is noted at once, so the key revives rather than calls
    -- once its body is gone; the fight ending re-arms the key.
    ns.RegisterPetEvent(self, "UNIT_HEALTH", function(_, _, unit)
        if unit == "pet" and PetIsDead() then FeedKey.petDead = true end
    end)
    ns.RegisterPetEvent(self, "UNIT_SPELLCAST_SUCCEEDED", function(_, _, unit, _, spellID)
        if unit == "player" then FeedKey:OnCast(spellID) end
    end)
    ns.RegisterEvent(self, "PLAYER_REGEN_ENABLED", function()
        if ns.PetStatus then ns.PetStatus:Update() end
    end)
end
