-- Blackthornes Pets -- Logic/NextStep.lua
-- The Next Step line under the pet on the Pet tab (the owner said build it
-- from a mockup, 2026-11-26): the one thing most worth doing next, and one
-- button for it. The most pressing wins, in this order:
--
--   1. the pet is hungry and there is food in the bags: Feed
--   2. fewer than Food.LOW_FOOD pieces of food it will eat: Okay (put away
--      until the bags are restocked)
--   3. a skill from a trainer or Beast Training the pet can afford now
--      (for a warlock, a demon book the gold in the bags pays for)
--   4. a skill rank to find by taming a beast: Show the Way
--   5. nothing left for its level
--
-- It only reads what the Pet tab already works out (Logic/PetStatus.lua,
-- Logic/Food.lua, Logic/PetSkills.lua, Logic/DemonSkills.lua), when the tab
-- redraws, never on a timer of its own.

local _, ns = ...
local L = ns.L

local NextStep = ns.NewModule("NextStep")

-- A low food line put away with Okay, for that pet, until its food is back
-- at Food.LOW_FOOD or more. For this session only.
NextStep.dismissed = nil

local function Plain(text)
    if type(text) ~= "string" then return "" end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

--- "A Coyote Packleader in Westfall teaches it." A rare goes by its name
--- alone.
function NextStep.BeastLine(beast)
    local rare = beast.rank == "rare" or beast.rank == "rareelite"
    if rare then return L.Format("%s in %s teaches it.", beast.name, beast.zone or "") end
    return L.Format("A %s in %s teaches it.", beast.name, beast.zone or "")
end

--- The trainer line: "Karrina Mekenda in Stormwind City teaches it."
local function TrainerLine(trainer)
    if not (trainer and trainer.name and trainer.zone) then return nil end
    return L.Format("%s in %s teaches it.", trainer.name, trainer.zone)
end

--- Work the line out. `input`:
---   status   PetStatus:Read()
---   stacks   Food:Latest(status), the food the pet eats, best first
---   plan     PetSkills:Current() or DemonSkills:Current()
---   trainer  the nearest pet or demon trainer, or nil
---   find     PetSkills:CurrentToFind(), or nil
---   money    copper in the bags (for demon books)
--- Returns nil when there is nothing to say, else
---   { kind = "feed" | "food" | "train" | "find" | "done",
---     text, sub, button (words), stack, trainer, beast }
function NextStep.Pick(input)
    local status = input.status or {}
    if not status.exists then return nil end
    local name = status.name or L["Your pet"]
    local stacks = input.stacks or {}
    local Food = ns.Food

    -- 1. Hungry, with food to give.
    local below = ns.PetStatus and ns.PetStatus:WarnBelow() or 3
    local best = stacks[1]
    if status.happiness and status.happiness < below and best then
        return {
            kind = "feed",
            text = L.Format("%s is hungry.", name),
            sub = L.Format("%d %s in your bags.", best.count or 0, Plain(Food.ShownName(best))),
            button = L["Feed"],
            stack = best,
        }
    end

    -- 2. Running low on food.
    if status.foods and not stacks.incomplete and Food then
        local total = Food:Count(stacks)
        local dismissed = NextStep.dismissed
        if total >= Food.LOW_FOOD then
            if dismissed == (status.name or true) then NextStep.dismissed = nil end
        elseif dismissed ~= (status.name or true) then
            return {
                kind = "food",
                text = L.Format("You have %d pet food left.", total),
                sub = L.Format("%s eats %s.", name, ns.PetStatus:FoodText(status) or ""),
                button = L["Okay"],
            }
        end
    end

    local plan = input.plan
    -- 3. Something to learn now that can be paid for.
    if plan and plan.kind == "demon" then
        local money = input.money
        for _, skill in ipairs(plan.learn or {}) do
            if skill.cost and money and skill.cost <= money then
                local trainer = TrainerLine(input.trainer)
                return {
                    kind = "train",
                    text = L.Format("%s Rank %d costs %s.", skill.name, skill.rank,
                        ns.UI and ns.UI.Money and ns.UI.Money(skill.cost) or tostring(skill.cost)),
                    sub = trainer,
                    button = trainer and L["Show the Way"] or nil,
                    trainer = trainer and input.trainer or nil,
                }
            end
        end
        if #(plan.learn or {}) == 0 and status.level then
            return { kind = "done", text = L.Format("%s has everything for level %d.", name, status.level) }
        end
        return nil
    end

    local free = status.trainingFree
    if plan then
        for _, skill in ipairs(plan.learn or {}) do
            if skill.cost and free and skill.cost <= free then
                local text = skill.cost == 1
                    and L.Format("%s Rank %d costs 1 point. You have %d.", skill.name, skill.rank, free)
                    or L.Format("%s Rank %d costs %d points. You have %d.", skill.name, skill.rank, skill.cost, free)
                if skill.from == "hunter" then
                    return { kind = "train", text = text, sub = L["Open Beast Training to teach it."] }
                end
                local trainer = TrainerLine(input.trainer)
                return {
                    kind = "train",
                    text = text,
                    sub = trainer,
                    button = trainer and L["Show the Way"] or nil,
                    trainer = trainer and input.trainer or nil,
                }
            end
        end
    end

    -- 4. A rank to find by taming a beast.
    local find = input.find
    local first = find and find.now and find.now[1]
    if first then
        return {
            kind = "find",
            text = L.Format("%s Rank %d is ready to learn.", first.name, first.rank),
            sub = NextStep.BeastLine(first.beast),
            button = L["Show the Way"],
            beast = first.beast,
        }
    end

    -- 5. Nothing left for its level.
    if plan and #(plan.learn or {}) == 0 and status.level then
        for _, later in ipairs(find and find.later or {}) do
            -- A rank it is old enough for, waiting on the hunter's level.
            local row = ns.PetTrainingData.SKILLS[later.name]
            row = row and row[later.rank]
            if row and row.level <= status.level then return nil end
        end
        return { kind = "done", text = L.Format("%s has everything for level %d.", name, status.level) }
    end
    return nil
end

--- Okay on the low food line: put away for this pet until it is restocked.
function NextStep:Dismiss(petName)
    NextStep.dismissed = petName or true
end
