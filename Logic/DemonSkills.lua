-- Blackthornes Pets -- Logic/DemonSkills.lua
-- The warlock's demon books, for the Skills card in the pets window (the
-- owner asked what Pets could do for warlocks and said build it from a
-- mockup, 2026-10-24): what the demon knows, the grimoires the warlock can
-- buy now and the ones that come later, and the nearest demon trainer.
--
-- Every rank, its grimoire, level and price come from Data/DemonBooks.lua.
-- What the demon out knows is read from its own spell book, as the
-- hunter's pet's is (PetSkills.SpellBook), and kept per character in
-- demonSkills[demon] = { [skill] = rank } (never rename it), so the other
-- demons' books can be shown while one is out.
--
-- Where demon trainers stand is not in the game's tables, so a spot is
-- learned when one's window opens (a vendor that sells a grimoire), kept
-- account wide in demonTrainers[npc ID] = { id, name, zone, x, y, side, at }
-- with the prices it asked in demonBookPrices[item ID] = copper (never
-- rename either). The spot the game saw is the only one used: until one is
-- seen, the card names no trainer. Everything the client is asked is read
-- only and inside a pcall.

local _, ns = ...

local DemonSkills = ns.NewModule("DemonSkills")

-- How many "later" lines the card shows at most, the nearest first.
DemonSkills.LATER_MOST = 4
-- The demons in the order the warlock gets them, with each one's summon
-- spell (the same as UI/FeedKey.lua's).
DemonSkills.ORDER = {
    { name = "Imp", summon = 688 },
    { name = "Voidwalker", summon = 697 },
    { name = "Succubus", summon = 712 },
    { name = "Felhunter", summon = 691 },
}
-- How long after a vendor's window opens its list is read, so it has
-- filled in.
DemonSkills.READ_AFTER = 0.3

local function Plain(value) return ns.PetStatus.Plain(value) end

local function Read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return Plain(a), Plain(b), Plain(c), Plain(d)
end

local function Data() return ns.DemonBooksData end

--------------------------------------------------------------------------------
-- The demon
--------------------------------------------------------------------------------

--- Is the player a warlock?
function DemonSkills.IsWarlock()
    local _, token = Read(_G.UnitClass, "player")
    return token == "WARLOCK"
end

--- The player's level, or 0.
function DemonSkills.PlayerLevel()
    local level = Read(_G.UnitLevel, "player")
    return type(level) == "number" and level or 0
end

local familyToDemon, nameToDemon

local function Lookups()
    if familyToDemon then return end
    familyToDemon, nameToDemon = {}, {}
    local info = _G.C_CreatureInfo and _G.C_CreatureInfo.GetCreatureFamilyInfo
    for demon, entry in pairs(Data().DEMONS) do
        nameToDemon[demon] = demon
        for _, family in ipairs(entry.families) do
            familyToDemon[family] = demon
            local ok, name = pcall(function()
                local row = info and info(family)
                return row and Plain(row.name)
            end)
            if ok and type(name) == "string" then nameToDemon[name] = demon end
        end
    end
end

--- The demon out as the data names it ("Voidwalker"), or nil. The client
--- gives the family's name in its own language and, on newer clients, its
--- ID beside it.
function DemonSkills.DemonOut()
    if not Read(_G.UnitExists, "pet") then return nil end
    Lookups()
    local name, id = Read(_G.UnitCreatureFamily, "pet")
    if type(id) == "number" and familyToDemon[id] then return familyToDemon[id] end
    if type(name) == "string" then return nameToDemon[name] end
    return nil
end

local clientNames

--- A spell as { skill, rank } in the data's English, or nil. A spell the
--- data does not number is matched by the client's own name for it.
local function SkillOf(spellID, name, subtext)
    local data = Data()
    local known = type(spellID) == "number" and data.SPELLS[spellID]
    if known then return known[1], known[2] end
    if type(name) ~= "string" then return nil end
    if not clientNames then
        clientNames = {}
        local get = (_G.C_Spell and _G.C_Spell.GetSpellName) or _G.GetSpellInfo
        for id, row in pairs(data.SPELLS) do
            local shown = Read(get, id)
            if type(shown) == "string" then clientNames[shown] = row[1] end
        end
    end
    local skill = clientNames[name] or name
    for _, entry in pairs(data.DEMONS) do
        if entry.skills[skill] then
            local rank = type(subtext) == "string" and tonumber(subtext:match("(%d+)")) or 1
            return skill, rank
        end
    end
    return nil
end

--- What the demon out knows: { [skill] = best rank }.
function DemonSkills:Known()
    local known = {}
    for _, spell in ipairs(ns.PetSkills.SpellBook()) do
        local skill, rank = SkillOf(spell[1], spell[2], spell[3])
        if skill and rank and rank > (known[skill] or 0) then known[skill] = rank end
    end
    return known
end

--- What a demon knows: read for the one out (and kept), else as it was
--- last seen on this character.
function DemonSkills:KnownBy(demon, out)
    local saved = ns.charDB and ns.charDB.demonSkills
    if demon == out then
        local known = self:Known()
        if next(known) and ns.charDB then
            ns.charDB.demonSkills = saved or {}
            ns.charDB.demonSkills[demon] = known
        end
        return known
    end
    return type(saved) == "table" and type(saved[demon]) == "table" and saved[demon] or {}
end

local function Knows(spellID)
    local book = _G.C_SpellBook
    if type(book) == "table" and type(book.IsSpellKnown) == "function" then
        local known = Read(book.IsSpellKnown, spellID)
        if known ~= nil then return known == true end
    end
    return Read(_G.IsSpellKnown, spellID) == true
end

--- The demons this warlock can summon, in the order they come, with the
--- one out and any seen before: { "Imp", "Voidwalker", ... }.
function DemonSkills:Demons(out)
    local saved = ns.charDB and ns.charDB.demonSkills or {}
    local list = {}
    for _, demon in ipairs(DemonSkills.ORDER) do
        if demon.name == out or saved[demon.name] or Knows(demon.summon) then
            list[#list + 1] = demon.name
        end
    end
    return list
end

--------------------------------------------------------------------------------
-- The plan
--------------------------------------------------------------------------------

local function Ranks(skill)
    local ranks = {}
    for rank in pairs(skill) do ranks[#ranks + 1] = rank end
    table.sort(ranks)
    return ranks
end

--- What a grimoire costs: the price a demon trainer asked, else the data's.
function DemonSkills.Price(row)
    local seen = ns.db and ns.db.demonBookPrices
    local price = type(seen) == "table" and tonumber(seen[row.book])
    return price or row.cost
end

--- Work out the three lists for a demon from what it knows and the
--- warlock's level:
---   { demon, known = { { name, rank } },
---     learn = { { name, rank, book, cost } },
---     later = { { name, rank, book, level } } }
--- The ranks a demon starts with count as known. Each list in name order,
--- later by level.
function DemonSkills:Plan(demon, known, level)
    local entry = Data().DEMONS[demon]
    if not entry then return nil end
    local plan = { demon = demon, kind = "demon", known = {}, learn = {}, later = {} }
    level = level or 0
    for name, skill in pairs(entry.skills) do
        local have = known[name] or 0
        for _, rank in ipairs(Ranks(skill)) do
            if skill[rank].free and rank > have then have = rank end
        end
        if have > 0 then plan.known[#plan.known + 1] = { name = name, rank = have } end

        local best
        for _, rank in ipairs(Ranks(skill)) do
            local row = skill[rank]
            if rank > have and not row.free and row.level <= level then
                best = { name = name, rank = rank, book = row.book, cost = DemonSkills.Price(row) }
            end
        end
        if best then plan.learn[#plan.learn + 1] = best end

        local after = best and best.rank or have
        for _, rank in ipairs(Ranks(skill)) do
            local row = skill[rank]
            if rank > after and not row.free then
                if row.level > level then
                    plan.later[#plan.later + 1] = { name = name, rank = rank, book = row.book, level = row.level }
                end
                break
            end
        end
    end
    local byName = function(a, b) return a.name < b.name end
    table.sort(plan.known, byName)
    table.sort(plan.learn, byName)
    table.sort(plan.later, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)
    while #plan.later > DemonSkills.LATER_MOST do table.remove(plan.later) end
    return plan
end

--- The plan for `pick` (a demon's name), else the demon out, or nil for a
--- character that is not a warlock with a demon out. The plan carries the
--- demons to pick from in `demons`.
function DemonSkills:Current(pick)
    if not DemonSkills.IsWarlock() then return nil end
    local out = DemonSkills.DemonOut()
    if not out then return nil end
    local demons = self:Demons(out)
    local demon = out
    for _, name in ipairs(demons) do
        if name == pick then demon = pick end
    end
    local plan = self:Plan(demon, self:KnownBy(demon, out), DemonSkills.PlayerLevel())
    if plan then plan.demons, plan.out = demons, out end
    return plan
end

--- A grimoire's name: the client's, else the data's English one.
function DemonSkills.BookName(skill)
    local name = skill.book and Read(_G.C_Item and _G.C_Item.GetItemNameByID, skill.book)
    if type(name) == "string" and name ~= "" then return name end
    return ("Grimoire of %s (Rank %d)"):format(skill.name, skill.rank)
end

--------------------------------------------------------------------------------
-- Demon trainers
--------------------------------------------------------------------------------

local books

--- { [grimoire item ID] = true }, laid out once.
function DemonSkills.Books()
    if not books then
        books = {}
        for _, entry in pairs(Data().DEMONS) do
            for _, skill in pairs(entry.skills) do
                for _, row in pairs(skill) do
                    if row.book then books[row.book] = true end
                end
            end
        end
    end
    return books
end

--- The demon trainers this account has seen, as a list.
function DemonSkills:Trainers()
    local list = {}
    local seen = ns.db and ns.db.demonTrainers
    if type(seen) ~= "table" then return list end
    for _, trainer in pairs(seen) do
        if type(trainer) == "table" and type(trainer.zone) == "string" and tonumber(trainer.x) then
            list[#list + 1] = trainer
        end
    end
    table.sort(list, function(a, b) return (tonumber(a.id) or 0) < (tonumber(b.id) or 0) end)
    return list
end

--- The nearest demon trainer of the player's side that has been seen, or
--- nil.
function DemonSkills:Trainer()
    return ns.PetSkills.Nearest(self:Trainers())
end

--- One merchant line: item ID and price in copper, or nil.
local function MerchantItem(index)
    local id = Read(_G.GetMerchantItemID, index)
    local price
    local frame = _G.C_MerchantFrame
    if type(frame) == "table" and type(frame.GetItemInfo) == "function" then
        local ok, info = pcall(frame.GetItemInfo, index)
        if ok and type(info) == "table" then price = Plain(info.price) end
    end
    if price == nil then
        local _, _, legacy = Read(_G.GetMerchantItemInfo, index)
        price = legacy
    end
    return type(id) == "number" and id or nil, type(price) == "number" and price or nil
end

--- A vendor's window is open: if it sells grimoires, keep where it stands
--- and what it asks. Nothing is kept inside a dungeon, where the game keeps
--- the position to itself. True when it was a demon trainer.
function DemonSkills:ReadMerchant()
    if not ns.db then return false end
    local count = Read(_G.GetMerchantNumItems)
    if type(count) ~= "number" or count < 1 then return false end
    local known, prices = DemonSkills.Books(), {}
    local any = false
    for i = 1, count do
        local id, price = MerchantItem(i)
        if id and known[id] then
            any = true
            if price and price > 0 then prices[id] = price end
        end
    end
    if not any then return false end

    ns.db.demonBookPrices = type(ns.db.demonBookPrices) == "table" and ns.db.demonBookPrices or {}
    for id, price in pairs(prices) do ns.db.demonBookPrices[id] = price end

    local npc = ns.Taming:NpcID(Read(_G.UnitGUID, "npc"))
    local here = not (ns.BeastArrow.Inside and ns.BeastArrow.Inside()) and ns.BeastArrow:Here()
    if npc and here and here.zone then
        ns.db.demonTrainers = type(ns.db.demonTrainers) == "table" and ns.db.demonTrainers or {}
        ns.db.demonTrainers[npc] = {
            id = npc,
            name = Read(_G.UnitName, "npc"),
            zone = here.zone,
            x = math.floor(here.x * 1000 + 0.5) / 10,
            y = math.floor(here.y * 1000 + 0.5) / 10,
            side = ns.Travel and ns.Travel.Side(),
            at = time and time() or nil,
        }
    end
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
    return true
end

function DemonSkills:OnMerchant()
    if not DemonSkills.IsWarlock() then return end
    if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(DemonSkills.READ_AFTER, function() DemonSkills:ReadMerchant() end)
    else
        self:ReadMerchant()
    end
end

function DemonSkills:OnEnable()
    ns.RegisterEvent(self, "MERCHANT_SHOW", self.OnMerchant)
end
