-- Blackthornes Pets -- Locale/ruRU.lua
-- Russian: the words players see, on a Russian client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- Russian. A key with no line here shows in English. The Russian speaks to
-- the player as "ты" and uses the game's own words (питомец, зверь,
-- приручение, обучение зверей, корм, уровень, м). A line may name its values
-- by place ("%2$s ... %1$s") where Russian word order needs it; L.Format
-- puts them in order.
--
-- Beast, family, zone and skill names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "ruRU") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Сохранено для Claude, набери /reload, чтобы записать."
L["module %s:%s failed"] = "модуль %s:%s дал сбой"
L["show this list"] = "показать этот список"
L["unknown command: %s"] = "неизвестная команда: %s"
L["/bpet %s failed: %s"] = "/bpet %s не сработала: %s"

-- The sister note
L["and"] = "и"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "работает с другими аддонами Blackthornes, которых у тебя ещё нет: %s. %s на CurseForge."
L["It's"] = "Его можно найти"
L["They're"] = "Их можно найти"
L["This note shows once."] = "Эта заметка показывается один раз."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "включить или выключить разовую заметку о других аддонах Blackthornes"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "заметка о других аддонах Blackthornes включена. Она покажется один раз для каждого, которого у тебя нет."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "заметка о других аддонах Blackthornes выключена во всех аддонах."
L["where to farm any material"] = "где добыть любой материал"
L["auction prices, crafting profits and a craft queue"] =
    "цены аукциона, доход от ремесла и очередь заказов"
L["which gear is an upgrade for you, and where to get it"] =
    "какие вещи лучше твоих и где их взять"
L["feeding and taming for hunter and warlock pets"] =
    "корм и приручение для питомцев охотника и чернокнижника"
L["what to do with every item in your bags"] = "что делать с каждой вещью в сумках"

-- Diets
L["Meat"] = "Мясо"
L["Fish"] = "Рыба"
L["Bread"] = "Хлеб"
L["Cheese"] = "Сыр"
L["Fruit"] = "Фрукты"
L["Fungus"] = "Грибы"

-- The beast arrow
L["you tamed %s, so the arrow is put away."] = "ты приручил: %s, так что стрелка убрана."
L["your beast"] = "твой зверь"
L["%d,%03d yd"] = "%d %03d м"
L["%d yd"] = "%d м"
L["Inside a raid"] = "В рейде"
L["Inside a dungeon"] = "В подземелье"
L["Far from here. Head for %s"] = "Далеко отсюда. Иди в %s"
L["it"] = "его"
L["No exact spot for it in this zone yet"] = "Точного места в этой зоне пока нет"
L["The middle of the zone, since there's no exact spot yet"] =
    "Середина зоны, потому что точного места пока нет"
L["Where it lived in Classic"] = "Где он жил в Classic"
L["Far away"] = "Далеко"
L["In %s"] = "Зона: %s"
L["this zone"] = "эта зона"
L["You're there"] = "Ты на месте"
L["beast arrow on, pointing at %s."] = "стрелка к зверю включена и указывает на: %s."
L["beast arrow on. Shift-click a beast in the Pet Compendium to aim it."] =
    "стрелка к зверю включена. Нажми Shift и щёлкни по зверю в атласе питомцев, чтобы навести её."
L["beast arrow off. /bpet arrow on shows it."] = "стрелка к зверю выключена. /bpet arrow on покажет её."
L["an arrow to a beast from the Pet Compendium (on, off, clear, check, tomtom, route, reset)"] =
    "стрелка к зверю из атласа питомцев (on, off, clear, check, tomtom, route, reset)"
L["the beast arrow isn't following a beast right now."] = "стрелка сейчас не ведёт ни к какому зверю."
L["beast arrow put back where it started."] = "стрелка к зверю возвращена на место."
L["/bpet arrow on, off, clear, check, tomtom, route or reset."] = "/bpet arrow on, off, clear, check, tomtom, route или reset."

-- The compendium's data
L["Rare"] = "Редкий"
L["Rare elite"] = "Редкий элитный"
L["Elite"] = "Элитный"
L["hours"] = "ч"
L["minutes"] = "мин"
L["%d %s to %d %s"] = "от %d %s до %d %s"
L["dungeon"] = "подземелье"
L["raid"] = "рейд"
L["Seen on Forever"] = "Замечен на Forever"
L["Tamed on Forever"] = "Приручён на Forever"
L["Found on Forever"] = "Найден на Forever"
L["You tamed it on Forever"] = "Ты приручил его на Forever"
L["Beast %d"] = "Зверь %d"

-- Food
L["%s, which it doesn't eat"] = "%s, а это питомец не ест"
L["too low level"] = "слишком низкий уровень"
L["buff food, which you've chosen not to feed"] = "еда с бонусом, которую ты решил не давать"
L["full"] = "полностью"
L["half"] = "наполовину"
L["little"] = "чуть-чуть"
L["refused"] = "не ест"
L["None in your bags"] = "В сумках нет"
L["%s (%s), %d in bags"] = "%s (%s), в сумках: %d"
L["running low"] = "заканчивается"
L["You have no food %s will eat."] = "У тебя нет еды, которую станет есть %s."
L["your pet"] = "твой питомец"
L["Only %d food left that %s will eat."] = "Еды, которую ест %2$s, осталось: %1$d."
L["food: no pet out."] = "еда: питомец не призван."
L["food: %s (level %s) eats %s"] = "еда: %s (уровень %s) ест: %s"
L["item %s"] = "предмет %s"
L[" (level %s)"] = " (уровень %s)"
L[", buff food (fed last)"] = ", еда с бонусом (даётся последней)"
L["not in the food list:"] = "нет в списке еды:"
L["food: %d items in %d slots, %d pieces your pet will eat."] =
    "еда: предметов %d, ячеек %d, из них питомец съест %d."
L["food: %s."] = "еда: %s."
L["food: %s"] = "еда: %s"
L["list the food in your bags and whether your pet will eat it"] =
    "показать еду в сумках и будет ли её есть питомец"

-- The pet's status
L["%s (%d%% damage)"] = "%s (урон %d%%)"
L["falling"] = "падает"
L["rising"] = "растёт"
L["%s free (%d total, %d spent)"] = "Свободно: %s (всего %d, потрачено %d)"
L["Unhappy"] = "Несчастен"
L["Content"] = "Доволен"
L["Happy"] = "Счастлив"
L["Your pet"] = "Твой питомец"
L["%s is %s. Feed it."] = "%s: %s. Покорми его."

-- Tames and pet skills
L["noted what %s teaches: %s"] = "записано, чему учит %s: %s"
L["the beast"] = "этот зверь"
L["nothing"] = "ничему"
L["list the beasts you have tamed and what each taught"] =
    "показать зверей, которых ты приручил, и чему научил каждый"
L["no tamed beasts yet. Tame one and it shows up here."] =
    "прирученных зверей пока нет. Приручи одного, и он появится здесь."
L["beasts you've tamed (%d):"] = "прирученные тобой звери (%d):"
L["list the pet skills this hunter knows"] = "показать навыки питомцев, которые знает этот охотник"
L["no pet skills known yet. Open Beast Training once so Pets can read the list."] =
    "навыки питомцев пока не известны. Открой обучение зверей один раз, чтобы Pets прочитал список."
L["pet skills known (%d): %s"] = "известные навыки питомцев (%d): %s"
L["You haven't opened Beast Training on this character yet."] =
    "Ты ещё не открывал обучение зверей на этом персонаже."
L["%s (Rank %d)"] = "%s (ранг %d)"

-- TomTom
L["TomTom is off. The beast arrow shows its own dial."] = "TomTom выключен. Стрелка к зверю показывает свой циферблат."
L["TomTom is on. Its arrow points where the beast arrow would."] =
    "TomTom включён. Его стрелка указывает туда же, куда указала бы стрелка к зверю."
L["TomTom takes over once it's installed."] = "Когда TomTom установлен, путь показывает он."

-- Map pins
L["there's no exact spot for that one"] = "для него нет точного места"
L["this client can't put a pin on the map"] = "эта игра не умеет ставить метку на карту"
L["couldn't find the map for that zone"] = "не удалось найти карту этой зоны"
L["pinned %s on your map: %s (%s, %s)"] = "метка на карте: %s, %s (%s, %s)"
L["can't pin %s%s: %s"] = "не удалось отметить %s%s: %s"
L["that"] = "это"

-- The arrow's window
L["beast arrow off. The Arrow button in the Pet Compendium, /bpet arrow or Settings brings it back."] =
    "стрелка к зверю выключена. Вернуть её можно кнопкой «Стрелка» в атласе питомцев, командой /bpet arrow или в настройках."
L["Beast arrow"] = "Стрелка к зверю"
L["Can't see you here"] = "Здесь тебя не видно"
L["The game won't say where you are"] = "Игра не говорит, где ты"

-- The compendium window
L["Click a beast to pin it on your map, or Shift-click to point the arrow at it. %s marks what WoW: Forever has shown."] =
    "Щёлкни по зверю, чтобы отметить его на карте, или нажми Shift и щёлкни, чтобы на него указала стрелка. %s отмечает то, что было в WoW: Forever."
L["Settings"] = "Настройки"
L["Arrow"] = "Стрелка"
L["All families"] = "Все семейства"
L["Search beasts, zones or skills"] = "Поиск зверей, зон или навыков"
L["Tameable now"] = "Можно приручить"
L["Only beasts at or below your level."] = "Только звери твоего уровня и ниже."
L["Rares only"] = "Только редкие"
L["Teaches me something new"] = "Научит новому"
L["Only beasts that teach a skill you don't have yet."] = "Только звери, которые учат навыку, которого у тебя ещё нет."
L["Only beasts known to live on WoW: Forever."] = "Только звери, которые точно живут в WoW: Forever."
L["Click again to flip it, and once more to go back."] = "Щёлкни ещё раз, чтобы перевернуть, и ещё раз, чтобы вернуть."
L["Beast"] = "Зверь"
L["Sort by beast"] = "Сортировать по зверю"
L["Family"] = "Семейство"
L["Sort by family"] = "Сортировать по семейству"
L["Level"] = "Уровень"
L["Sort by level"] = "Сортировать по уровню"
L["Speed"] = "Скорость"
L["Sort by speed"] = "Сортировать по скорости"
L["Seconds between its attacks. Lower is faster."] = "Секунды между его атаками. Меньше значит быстрее."
L["Where"] = "Где"
L["Sort by where"] = "Сортировать по месту"
L["Teaches"] = "Учит"
L["Not known yet"] = "Пока неизвестно"
L["Raid"] = "Рейд"
L["Dungeon"] = "Подземелье"
L["tamed"] = "приручён"
L["Nothing"] = "Ничему"
L["beast arrow pointing at %s. Hide it with its red gem, /bpet arrow off or Settings."] =
    "стрелка указывает на: %s. Спрятать её можно красным камнем, командой /bpet arrow off или в настройках."
L["where %s lives isn't known yet, so the arrow can't point at it."] =
    "пока неизвестно, где живёт %s, поэтому стрелка не может туда указать."
L["Family not known yet"] = "Семейство пока неизвестно"
L["Eats %s"] = "Ест: %s"
L["Level %s. You can tame it now."] = "Уровень %s. Его можно приручить уже сейчас."
L["Level %s. You can tame it from level %d."] = "Уровень %s. Приручить можно с уровня %d."
L["Level %s"] = "Уровень %s"
L["Attack speed %s"] = "Скорость атаки %s"
L["Attack speed %s (seen on Forever)"] = "Скорость атаки %s (замечено на Forever)"
L["Where it lives is not known yet."] = "Пока неизвестно, где он живёт."
L["Shift-click to point the arrow at it."] = "Нажми Shift и щёлкни, чтобы на него указала стрелка."
L["Also in %s"] = "Ещё в: %s"
L["Found in %d spots. This one is near the middle."] = "Мест, где его видели: %d. Это место ближе к середине."
L["Comes back after %s"] = "Появляется снова через %s"
L["Taming it teaches nothing new."] = "Если приручить его, ничему новому он не научит."
L["Taming it teaches"] = "Если приручить, научит"
L["(known)"] = "(знаешь)"
L["(not known)"] = "(не знаешь)"
L["Click to pin it on your map."] = "Щёлкни, чтобы отметить его на карте."
L["No exact spot to pin. Shift-click to point the arrow at its zone."] =
    "Точного места для метки нет. Нажми Shift и щёлкни, чтобы стрелка указала на его зону."
L["No place to pin yet."] = "Пока нечего отметить."
L["Beasts a hunter can tame. You are level %d."] = "Звери, которых может приручить охотник. Твой уровень: %d."
L["Beasts a hunter can tame."] = "Звери, которых может приручить охотник."
L["No beast matches. Untick a box or clear the search."] =
    "Ни один зверь не подходит. Сними галочку или очисти поиск."
L["%d beasts"] = "Зверей: %d"
L["open the Pet Compendium: every beast you can tame"] =
    "открыть атлас питомцев: все звери, которых можно приручить"

-- The Feed buttons
L["Feed"] = "Покормить"
L["Feed %s"] = "Покормить: %s"
L["%s is %s."] = "%s: %s."
L["hungry"] = "голоден"

-- The Pet care key
L["the Pet care key feeds a hunter's pet."] = "клавиша ухода за питомцем кормит питомца охотника."
L["you have no pet out."] = "твой питомец не призван."
L["the game did not say what your pet eats."] = "игра не сказала, что ест твой питомец."
L["your bags are still loading. Try again in a moment."] =
    "твои сумки ещё загружаются. Попробуй чуть позже."
L["you have no food in your bags that %s will eat."] = "в сумках нет еды, которую станет есть %s."
L["your pet can't be fed in combat."] = "в бою питомца кормить нельзя."
L["your demon is already out."] = "твой демон уже призван."
L["nothing to feed your pet yet."] = "питомца пока нечем кормить."
L["Pet care key (%s)"] = "Клавиша ухода за питомцем (%s)"
L["Pet care key (not set yet, find it under Options, Keybindings, AddOns)"] =
    "Клавиша ухода за питомцем (ещё не назначена, ищи в разделе Настройки, Назначение клавиш, Модификации)"
L["calls your pet when none is out"] = "призывает питомца, если его нет рядом"
L["revives your pet"] = "воскрешает питомца"
L["summons your demon when none is out"] = "призывает демона, если его нет рядом"
L[", and "] = " и "
L["mends it in combat"] = "лечит его в бою"
L["%s feeds %s%s."] = "%s кормит едой %s%s."
L["%s has nothing to feed: %s"] = "%s: нечем кормить, %s"
L["not checked yet."] = "ещё не проверено."
L["Pet care (call, revive, feed or mend)"] = "Уход за питомцем (призвать, воскресить, покормить или вылечить)"
L["Dismiss pet"] = "Отпустить питомца"

-- The pets window
L["FOOD"] = "ЕДА"
L["IN A FIGHT"] = "В БОЮ"
L["Damage a second"] = "Урон в секунду"
L["Damage a hit"] = "Урон за удар"
L["%s, level %s"] = "%s, уровень %s"
L["1 training point free"] = "Свободно 1 очко обучения"
L["%d training points free"] = "Свободных очков обучения: %d"
L["%d training points over"] = "Лишних очков обучения: %d"
L["%d in your bags (%s)"] = "В сумках: %d (%s)"
L["No food"] = "Нет еды"
L["Enough food for about %.1f hours"] = "Еды хватит примерно на %.1f ч"
L["Not enough food to keep it happy"] = "Еды мало, чтобы питомец был счастлив"
L["Happiness"] = "Настроение"
L["Loyalty"] = "Преданность"
L["Experience"] = "Опыт"
L["Hunter"] = "Охотник"
L["Warlock"] = "Чернокнижник"
L["Training points"] = "Очки обучения"
L["Pets is for hunters and warlocks."] = "Pets сделан для охотников и чернокнижников."
L["Eats"] = "Ест"
L["Health"] = "Здоровье"
L["Attack speed"] = "Скорость атаки"
L["Attack power"] = "Сила атаки"
L["Armor"] = "Броня"
L["Resistances"] = "Сопротивление"
L["Fire"] = "Огонь"
L["Nature"] = "Природа"
L["Frost"] = "Лёд"
L["Shadow"] = "Тьма"
L["Arcane"] = "Тайная магия"
L["%.2f seconds"] = "%.2f сек."
L["%d to %d (%.1f a second)"] = "от %d до %d (%.1f в секунду)"
L["%d to %d"] = "от %d до %d"
L["%s %d"] = "%s %d"
L["open the pets window (so does /bpet on its own)"] = "открыть окно питомца (так же работает просто /bpet)"
L["No pet out."] = "Питомец не призван."

-- The minimap button
L["Click to open"] = "Щёлкни, чтобы открыть"
L["Right-click for settings"] = "Правый щелчок: настройки"
L["Click for settings"] = "Щёлкни, чтобы открыть настройки"
L["Drag to move it round the minimap"] = "Перетащи, чтобы двигать вокруг миникарты"

-- Settings
L["Changes save as you make them."] = "Изменения сохраняются сразу."
L["Reload"] = "Перезагрузить"
L["FEEDING"] = "КОРМЛЕНИЕ"
L["TAMING"] = "ПРИРУЧЕНИЕ"
L["PET COMPENDIUM"] = "АТЛАС ПИТОМЦЕВ"
L["BEAST ARROW"] = "СТРЕЛКА К ЗВЕРЮ"
L["Clear"] = "Сбросить"
L["WINDOWS"] = "ОКНА"
L["HUNTER PET"] = "ПИТОМЕЦ ОХОТНИКА"
L["ADVANCED"] = "ДОПОЛНИТЕЛЬНО"
L["Feeding warnings, the Feed button and taming skills on tooltips"] =
    "Напоминания о корме, кнопка кормления и навыки приручения в подсказках"
L["COMPENDIUM"] = "АТЛАС"
L["The Pet Compendium, the beast arrow and TomTom"] = "Атлас питомцев, стрелка к зверю и TomTom"
L["GENERAL"] = "ОБЩЕЕ"
L["Pets' settings have a window of their own."] = "У настроек Pets есть своё окно."
L["Open Pets settings"] = "Открыть настройки Pets"
L["Or type /bpet settings, or click the minimap button."] =
    "Или набери /bpet settings, или щёлкни кнопку у миникарты."
L["open the settings window"] = "открыть окно настроек"

-- The settings pages
L["Show descriptions"] = "Показывать описания"
L["Find a setting"] = "Найти настройку"
L["Normal"] = "Обычный"
L["Large"] = "Крупный"
L["Larger"] = "Ещё крупнее"

-- The taming tooltip
L["Taming teaches"] = "Приручение научит"
L["Known"] = "Знаешь"
L["Not known"] = "Не знаешь"
L["Open Beast Training once to see which you know"] = "Открой обучение зверей один раз, чтобы увидеть, что ты знаешь"

-- The house frame
L["Close"] = "Закрыть"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Что нового"
L["BLACKTHORNES ADDONS"] = "АДДОНЫ BLACKTHORNES"
L["Here's what changed since you last played."] = "Вот что изменилось с твоей прошлой игры."
L["The newest changes in each of your Blackthornes addons."] = "Свежие изменения в каждом твоём аддоне Blackthornes."
L["Show after updates"] = "Показывать после обновлений"
L["Motion"] = "Анимация"
L["Got it"] = "Понятно"
L["there is no news to show yet."] = "пока нет новостей."
L["open the What's New window for every Blackthornes addon"] = "открыть окно «Что нового» для всех аддонов Blackthornes"

-- ======================================================================
-- Settings rows
L["On"] = "Вкл."
L["Show"] = "Показать"
L["Open"] = "Открыть"
L["Feed Warning:"] = "Напоминание о корме:"
L["Only When Unhappy"] = "Только когда несчастен"
L["Warns you when your pet isn't happy. Only When Unhappy waits until it's unhappy."] =
    "Предупреждает, когда питомец не счастлив. «Только когда несчастен» ждёт, пока он станет несчастен."
L["Low Food Warning:"] = "Мало еды:"
L["Warns you in chat when you have fewer than %d food your pet will eat."] =
    "Предупреждает в чате, когда еды для питомца осталось меньше %d."
L["Never Feed Buff Food:"] = "Не давать еду с бонусом:"
L["Food that gives a buff is always fed last. Tick this to never feed it."] =
    "Еда с бонусом всегда даётся последней. Поставь галочку, чтобы не давать её совсем."
L["Feed Button:"] = "Кнопка кормления:"
L["A Feed button above your quests while your pet is hungry."] =
    "Кнопка «Покормить» над заданиями, пока питомец голоден."
L["Taming Skills:"] = "Навыки приручения:"
L["A beast's tooltip shows what it teaches. Green you know, red you don't."] =
    "Подсказка зверя показывает, чему он учит. Зелёное ты знаешь, красное нет."
L["Pet Compendium:"] = "Атлас питомцев:"
L["Beast Arrow:"] = "Стрелка к зверю:"
L["Points the way to a beast. Shift-click one in the compendium to aim it."] =
    "Показывает путь к зверю. Нажми Shift и щёлкни по зверю в атласе, чтобы навести её."
L["Stop Following:"] = "Перестать вести:"
L["Use TomTom:"] = "Использовать TomTom:"
L["With TomTom installed, its arrow shows the way instead."] = "Если TomTom установлен, путь показывает его стрелка."
L["Pets:"] = "Pets:"
L["Window Position:"] = "Положение окон:"
L["Reset the UI windows to their defaults."] = "Вернуть окна на их обычные места."
L["Set Default"] = "По умолчанию"
L["UI windows set to defaults."] = "Окна возвращены на обычные места."
L["Text Size:"] = "Размер текста:"
L["Window Style:"] = "Стиль окон:"
L["Sister Addons:"] = "Другие аддоны:"
L["Says once in chat which Blackthornes addons you don't have."] = "Один раз пишет в чат, каких аддонов Blackthornes у тебя нет."
L["What's New:"] = "Что нового:"
L["What's New After Updates:"] = "Что нового после обновлений:"
L["Opens What's New the first time you play after an update."] = "Открывает «Что нового», когда ты впервые играешь после обновления."
L["What's New Motion:"] = "Анимация «Что нового»:"
L["Window position, text size and What's New"] = "Положение окна, размер текста и Что нового"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Некоторые из вас спрашивали, использую ли я ИИ, когда делаю свои аддоны. Да, использую."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Я 25 лет занимаюсь разработкой программ и работаю в IT, и я советую разработчикам сегодня пользоваться ИИ, но с умом и осознанно. Для меня это значит, что я решаю, что делать, я задаю правила, которым должен следовать код, я проверяю код и сам тестирую изменения в игре. ИИ помогает мне писать код, запускать тесты и искать ошибки."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Если пользоваться им с умом, это значит больше функций, более быстрые исправления и быстрее выполненные ваши просьбы. Многое в этих аддонах началось с идеи или сообщения об ошибке от игрока."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Если у тебя есть идея или что-то не работает, найди меня в моём Discord: discord.gg/f2geDecrw2. Я читаю каждый комментарий и каждое сообщение."
L["%s, version %s"] = "%s, версия %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Щёлкни по полю, затем нажми Ctrl+C, чтобы скопировать ссылку."
L["REPORT A BUG"] = "СООБЩИТЬ ОБ ОШИБКЕ"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Напиши об этом в моём Discord и расскажи, что ты делал, когда это случилось. Я читаю каждый комментарий и каждое сообщение."
L["THANK YOU"] = "СПАСИБО"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Многое здесь началось с идеи игрока или сообщения об ошибке. Спасибо всем, кто их прислал."
L["installed"] = "установлен"
L["turned off"] = "выключен"
L["not installed"] = "не установлен"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Как делаются эти аддоны"
L["A note from Blackthornes."] = "Пара слов от Blackthornes."
L["ABOUT"] = "ОБ АДДОНЕ"
L["HOW THESE ADDONS ARE MADE"] = "КАК ДЕЛАЮТСЯ ЭТИ АДДОНЫ"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Как делаются эти аддоны, версия, Discord и другие аддоны Blackthornes"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).
L["Off"] = "Выкл"
L["Shift"] = "Shift"
L["Always"] = "Всегда"
L["Hold Shift for more."] = "Зажми Shift, чтобы увидеть больше."
L["Drag to make the window bigger or smaller."] = "Тяни, чтобы сделать окно больше или меньше."
L["Right-click to go back to normal size."] = "Правый щелчок вернёт обычный размер."
L["EFFECTS"] = "ЭФФЕКТЫ"
L["Effects:"] = "Эффекты:"
L["Full"] = "Полностью"
L["Subtle"] = "Слабо"
L["Couldn't tell what your pet eats yet."] = "Пока не удалось узнать, что ест твой питомец."
L["Couldn't read your bags. Try again in a moment."] = "Не удалось прочитать сумки. Попробуй ещё раз чуть позже."
L["Name not loaded yet"] = "Имя ещё не загружено"
L["Your filters hide 1 beast."] = "Фильтры скрывают 1 зверя."
L["Your filters hide %d beasts."] = "Фильтры скрывают зверей: %d."

-- The way there (Logic/Travel.lua, the same in every addon).
L["Fly to %s"] = "Лети в %s"
L["Talk to the flight master"] = "Поговори с распорядителем полетов"
L["Wait here for the boat to %s"] = "Жди здесь корабль до %s"
L["Get on when it stops"] = "Садись, когда он остановится"
L["Take the boat to %s"] = "Садись на корабль до %s"
L["Wait here for the zeppelin to %s"] = "Жди здесь дирижабль до %s"
L["Take the zeppelin to %s"] = "Садись на дирижабль до %s"
L["Use your Hearthstone"] = "Используй камень возвращения"
L["It takes you to %s"] = "Он перенесет тебя в %s"
L["Walk to %s"] = "Иди в %s"
L["toward %s"] = "в сторону %s"
L["Next: %s."] = "Дальше: %s."
L["Your Way There"] = "Твой путь"
L["Show on Map"] = "На карте"
L["Stop"] = "Стоп"
L["Done"] = "Готово"
L["Now"] = "Сейчас"
L["About 1 minute"] = "Около 1 минуты"
L["About %d minutes"] = "Около %d мин."
L["Guide Me:"] = "Веди меня:"
L["Step %d of %d"] = "Шаг %d из %d"
L["The arrow leads you step by step to places far away."] = "Стрелка ведет тебя шаг за шагом в дальние места."
L["The arrow points straight at places far away."] = "Стрелка показывает прямо на дальние места."
L["When the place is in another zone or across the sea, the arrow leads you there step by step."] = "Если место в другой зоне или за морем, стрелка ведет тебя туда шаг за шагом."

-- The Skills card and the window's tabs.
L["%d point"] = "%d очко"
L["%d points"] = "очки: %d"
L["%s Rank %d"] = "%s, ранг %d"
L["CAN LEARN NOW"] = "МОЖНО ВЫУЧИТЬ СЕЙЧАС"
L["COST"] = "ЦЕНА"
L["Click to see the beasts that teach it."] = "Нажми, чтобы увидеть зверей, которые этому учат."
L["Compendium"] = "Атлас"
L["LATER"] = "ПОЗЖЕ"
L["Pet"] = "Питомец"
L["Pet level %d"] = "Питомец %d-го уровня"
L["Pet trainer"] = "Учитель питомцев"
L["Pet trainer: %s"] = "Учитель питомцев: %s"
L["RANK"] = "РАНГ"
L["Rank %d"] = "Ранг %d"
L["SKILLS"] = "НАВЫКИ"
L["Show the Way"] = "Показать путь"
L["Tame a beast that knows it"] = "Приручи зверя, который это умеет"
L["WHEN"] = "КОГДА"
L["YOUR PET KNOWS"] = "ТВОЙ ПИТОМЕЦ УМЕЕТ"
L["from a pet trainer"] = "у учителя питомцев"
L["from your Beast Training"] = "из твоей дрессировки"
