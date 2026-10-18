-- The translations: on a German client the windows and settings speak
-- Deutsch, on a Simplified Chinese client Chinese, on any other English, and
-- a word with no line falls back to its English key. L.Format puts values named by place
-- ("%2$s ... %1$d") in order, which the tests' Lua 5.1 cannot do itself.

local env = dofile(lfs_cwd .. "/tools/testenv.lua")
local suite = env.NewSuite("locale")

--- Every row label on every settings page, as one lookup.
local function SettingsLabels(ns)
    for _, module in ipairs(ns.moduleOrder) do
        if module.OnEnable then module:OnEnable() end
    end
    ns.SettingsUI:Show()
    local labels = {}
    for _, page in pairs(ns.SettingsUI.pages.pages) do
        for _, row in ipairs(page.rows or {}) do
            if row.labelText then labels[row.labelText] = true end
        end
    end
    return labels
end

-- English first.
local ns = env.Load()
local L = ns.L
suite.check("English shows English", L["Feed"] == "Feed")
suite.check("and formats as before", L.Format("Feed %s", "Bread") == "Feed Bread")
_G.UnitClass = function() return "Hunter", "HUNTER" end
ns.UI:Show()
suite.check("the pets window in English", ns.UI.subtitle:GetText() == "Hunter", ns.UI.subtitle:GetText())
suite.check("with no pet, in English", ns.UI.emptyLabel:GetText() == "No pet out.")
suite.check("the settings rows in English", SettingsLabels(ns)["Feed Warning:"] == true)

-- A German client.
ns = env.Load("deDE")
L = ns.L
_G.UnitClass = function() return "Jäger", "HUNTER" end
ns.UI:Show()
suite.check("the pets window speaks Deutsch", ns.UI.subtitle:GetText() == "Jäger", ns.UI.subtitle:GetText())
suite.check("with no pet out", ns.UI.emptyLabel:GetText() == "Kein Begleiter draußen.",
    ns.UI.emptyLabel:GetText())
local labels = SettingsLabels(ns)
suite.check("the settings rows speak Deutsch", labels["Futterwarnung:"] == true)
suite.check("and none is left in English", labels["Feed Warning:"] == nil)
suite.check("the diet words", ns.PetFood.Label("Cheese") == "Käse")
suite.check("the key binding's name", _G["BINDING_NAME_" .. ns.FeedKey.BINDING]
    == "Begleiterpflege (rufen, wiederbeleben, füttern oder heilen)")
suite.check("a word with no German line falls back to English",
    L["A string nobody translated"] == "A string nobody translated")
suite.check("and formats in English", L.Format("%d wolves, %s", 3, "grey") == "3 wolves, grey")
suite.check("values named by place go where German puts them",
    L.Format("Only %d food left that %s will eat.", 4, "Eber") == "Für Eber ist nur noch 4 Futter übrig.",
    L.Format("Only %d food left that %s will eat.", 4, "Eber"))
suite.check("a %% stays a percent sign",
    L.Format("%s (%d%% damage)", "Glücklich", 25) == "Glücklich (25% Schaden)")
suite.check("yards are metres", L.Format("%d,%03d yd", 1, 250) == "1.250 m")

-- A Simplified Chinese client.
ns = env.Load("zhCN")
L = ns.L
_G.UnitClass = function() return "猎人", "HUNTER" end
ns.UI:Show()
suite.check("the pets window speaks Simplified Chinese", ns.UI.emptyLabel:GetText() == "没有召唤宠物。",
    ns.UI.emptyLabel:GetText())
labels = SettingsLabels(ns)
suite.check("the settings rows in Simplified Chinese", labels["喂食提醒："] == true)
suite.check("and none is left in English", labels["Feed Warning:"] == nil)
suite.check("the diet words in Simplified Chinese", ns.PetFood.Label("Cheese") == "奶酪")
suite.check("values named by place go where Chinese puts them",
    L.Format("Only %d food left that %s will eat.", 4, "野猪") == "野猪愿意吃的食物只剩4份了。",
    L.Format("Only %d food left that %s will eat.", 4, "野猪"))
suite.check("a word with no Chinese line falls back to English",
    L["A string nobody translated"] == "A string nobody translated")

-- A French client.
ns = env.Load("frFR")
L = ns.L
_G.UnitClass = function() return "Chasseur", "HUNTER" end
ns.UI:Show()
suite.check("the pets window speaks French", ns.UI.emptyLabel:GetText() == "Aucun familier sorti.",
    ns.UI.emptyLabel:GetText())
labels = SettingsLabels(ns)
suite.check("the settings rows in French", labels["Alerte pour nourrir :"] == true)
suite.check("and none is left in English (French)", labels["Feed Warning:"] == nil)
suite.check("the diet words in French", ns.PetFood.Label("Cheese") == "Fromage")
suite.check("values go where French puts them",
    L.Format("Only %d food left that %s will eat.", 4, "Sanglier") == "Sanglier n'a plus que 4 nourriture à manger.",
    L.Format("Only %d food left that %s will eat.", 4, "Sanglier"))
suite.check("a word with no French line falls back to English",
    L["A string nobody translated"] == "A string nobody translated")

-- A Spanish (Spain) client.
ns = env.Load("esES")
L = ns.L
_G.UnitClass = function() return "Cazador", "HUNTER" end
ns.UI:Show()
suite.check("the pets window speaks Spanish (Spain)", ns.UI.emptyLabel:GetText() == "No tienes mascota fuera.",
    ns.UI.emptyLabel:GetText())
labels = SettingsLabels(ns)
suite.check("the settings rows in Spanish (Spain)", labels["Aviso de comida:"] == true)
suite.check("and none is left in English (Spanish (Spain))", labels["Feed Warning:"] == nil)
suite.check("the diet words in Spanish (Spain)", ns.PetFood.Label("Cheese") == "Queso")
suite.check("values go where Spanish (Spain) puts them",
    L.Format("Only %d food left that %s will eat.", 4, "Jabalí") == "A Jabalí solo le queda 4 de comida.",
    L.Format("Only %d food left that %s will eat.", 4, "Jabalí"))
suite.check("a word with no Spanish (Spain) line falls back to English",
    L["A string nobody translated"] == "A string nobody translated")

-- A Spanish (Latin America) client.
ns = env.Load("esMX")
L = ns.L
_G.UnitClass = function() return "Cazador", "HUNTER" end
ns.UI:Show()
suite.check("the pets window speaks Spanish (Latin America)", ns.UI.emptyLabel:GetText() == "No tienes mascota fuera.",
    ns.UI.emptyLabel:GetText())
labels = SettingsLabels(ns)
suite.check("the settings rows in Spanish (Latin America)", labels["Aviso de comida:"] == true)
suite.check("and none is left in English (Spanish (Latin America))", labels["Feed Warning:"] == nil)
suite.check("the diet words in Spanish (Latin America)", ns.PetFood.Label("Cheese") == "Queso")
suite.check("values go where Spanish (Latin America) puts them",
    L.Format("Only %d food left that %s will eat.", 4, "Jabalí") == "A Jabalí solo le queda 4 de comida.",
    L.Format("Only %d food left that %s will eat.", 4, "Jabalí"))
suite.check("a word with no Spanish (Latin America) line falls back to English",
    L["A string nobody translated"] == "A string nobody translated")

-- A Russian client.
ns = env.Load("ruRU")
L = ns.L
_G.UnitClass = function() return "Охотник", "HUNTER" end
ns.UI:Show()
suite.check("the pets window speaks Russian", ns.UI.emptyLabel:GetText() == "Питомец не призван.",
    ns.UI.emptyLabel:GetText())
labels = SettingsLabels(ns)
suite.check("the settings rows in Russian", labels["Напоминание о корме:"] == true)
suite.check("and none is left in English (Russian)", labels["Feed Warning:"] == nil)
suite.check("the diet words in Russian", ns.PetFood.Label("Cheese") == "Сыр")
suite.check("values go where Russian puts them",
    L.Format("Only %d food left that %s will eat.", 4, "Кабан") == "Еды, которую ест Кабан, осталось: 4.",
    L.Format("Only %d food left that %s will eat.", 4, "Кабан"))
suite.check("a word with no Russian line falls back to English",
    L["A string nobody translated"] == "A string nobody translated")

-- Another language that has no file shows English.
ns = env.Load("itIT")
suite.check("a client in a language with no file shows English", ns.L["Feed"] == "Feed")

_G.UnitClass, _G.GetLocale = nil, nil
suite.done()
