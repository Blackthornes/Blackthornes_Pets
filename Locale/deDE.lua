-- Blackthornes Pets -- Locale/deDE.lua
-- Deutsch (German): the words players see, on a German client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- German. A key with no line here shows in English. The German speaks to
-- the player as "du", the way the game's own German does, and uses the
-- game's words (Begleiter, Wildtier, Zähmen, Tierausbildung, Futter, Stufe,
-- Meter). A line may name its values by place ("%2$s ... %1$s") where
-- German word order needs it; L.Format puts them in order.
--
-- Beast, family, zone and skill names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "deDE") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Für Claude gespeichert, /reload schreibt es."
L["module %s:%s failed"] = "Modul %s:%s fehlgeschlagen"
L["show this list"] = "zeigt diese Liste"
L["unknown command: %s"] = "unbekannter Befehl: %s"
L["/bpet %s failed: %s"] = "/bpet %s fehlgeschlagen: %s"

-- The sister note
L["and"] = "und"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "arbeitet mit weiteren Blackthornes-Addons zusammen, die dir noch fehlen: %s. %s auf CurseForge."
L["It's"] = "Du findest es"
L["They're"] = "Du findest sie"
L["This note shows once."] = "Dieser Hinweis erscheint nur einmal."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "schaltet den einmaligen Hinweis auf die anderen Blackthornes-Addons ein oder aus"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "der Hinweis auf die anderen Blackthornes-Addons ist an. Er erscheint einmal für jedes, das dir fehlt."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "der Hinweis auf die anderen Blackthornes-Addons ist aus, in allen."
L["where to farm any material"] = "wo du jedes Material farmen kannst"
L["auction prices, crafting profits and a craft queue"] =
    "Auktionspreise, Gewinne beim Herstellen und eine Herstellungsliste"
L["which gear is an upgrade for you, and where to get it"] =
    "welche Ausrüstung für dich besser ist und wo du sie bekommst"
L["feeding and taming for hunter and warlock pets"] =
    "Füttern und Zähmen für Begleiter von Jägern und Hexenmeistern"
L["what to do with every item in your bags"] = "was du mit jedem Gegenstand in deinen Taschen tun solltest"

-- Diets
L["Meat"] = "Fleisch"
L["Fish"] = "Fisch"
L["Bread"] = "Brot"
L["Cheese"] = "Käse"
L["Fruit"] = "Obst"
L["Fungus"] = "Pilze"

-- The beast arrow
L["you tamed %s, so the arrow is put away."] = "Du hast %s gezähmt, also ist der Pfeil weggepackt."
L["your beast"] = "dein Wildtier"
L["%d,%03d yd"] = "%d.%03d m"
L["%d yd"] = "%d m"
L["Inside a raid"] = "In einem Schlachtzug"
L["Inside a dungeon"] = "In einem Dungeon"
L["Far from here. Head for %s"] = "Weit weg. Geh nach %s"
L["it"] = "es"
L["No exact spot for it in this zone yet"] = "Noch keine genaue Stelle in dieser Zone"
L["The middle of the zone, since there's no exact spot yet"] =
    "Die Mitte der Zone, weil es noch keine genaue Stelle gibt"
L["Where it lived in Classic"] = "Wo es in Classic lebte"
L["Far away"] = "Weit weg"
L["In %s"] = "In %s"
L["this zone"] = "dieser Zone"
L["You're there"] = "Du bist da"
L["beast arrow on, pointing at %s."] = "Wildtierpfeil an, er zeigt auf %s."
L["beast arrow on. Shift-click a beast in the Pet Compendium to aim it."] =
    "Wildtierpfeil an. Shift-Klick auf ein Wildtier im Begleiterkompendium richtet ihn darauf aus."
L["beast arrow off. /bpet arrow on shows it."] = "Wildtierpfeil aus. /bpet arrow on zeigt ihn wieder."
L["an arrow to a beast from the Pet Compendium (on, off, clear, check, tomtom, reset)"] =
    "ein Pfeil zu einem Wildtier aus dem Begleiterkompendium (on, off, clear, check, tomtom, reset)"
L["the beast arrow isn't following a beast right now."] = "Der Wildtierpfeil folgt gerade keinem Wildtier."
L["beast arrow put back where it started."] = "Wildtierpfeil an seinen Anfangsplatz zurückgesetzt."
L["/bpet arrow on, off, clear, check, tomtom or reset."] = "/bpet arrow on, off, clear, check, tomtom oder reset."

-- The compendium's data
L["Rare"] = "Selten"
L["Rare elite"] = "Seltene Elite"
L["Elite"] = "Elite"
L["hours"] = "Stunden"
L["minutes"] = "Minuten"
L["%d %s to %d %s"] = "%d %s bis %d %s"
L["dungeon"] = "Dungeon"
L["raid"] = "Schlachtzug"
L["Seen on Forever"] = "Auf Forever gesehen"
L["Tamed on Forever"] = "Auf Forever gezähmt"
L["Found on Forever"] = "Auf Forever gefunden"
L["You tamed it on Forever"] = "Du hast es auf Forever gezähmt"
L["Beast %d"] = "Wildtier %d"

-- Food
L["%s, which it doesn't eat"] = "%s, das es nicht frisst"
L["too low level"] = "zu niedrige Stufe"
L["buff food, which you've chosen not to feed"] = "Buff-Essen, das du nicht verfüttern willst"
L["full"] = "voll"
L["half"] = "halb"
L["little"] = "wenig"
L["refused"] = "verweigert"
L["None in your bags"] = "Keins in deinen Taschen"
L["%s (%s), %d in bags"] = "%s (%s), %d in den Taschen"
L["running low"] = "wird knapp"
L["You have no food %s will eat."] = "Du hast kein Futter, das %s frisst."
L["your pet"] = "dein Begleiter"
L["Only %d food left that %s will eat."] = "Für %2$s ist nur noch %1$d Futter übrig."
L["food: no pet out."] = "Futter: kein Begleiter draußen."
L["food: the client did not say what your pet eats."] =
    "Futter: Das Spiel hat nicht gesagt, was dein Begleiter frisst."
L["food: %s (level %s) eats %s"] = "Futter: %s (Stufe %s) frisst %s"
L["item %s"] = "Gegenstand %s"
L[" (level %s)"] = " (Stufe %s)"
L[", buff food (fed last)"] = ", Buff-Essen (wird zuletzt verfüttert)"
L["no name from the client"] = "kein Name vom Spiel"
L["not in the food list:"] = "nicht in der Futterliste:"
L["food: could not read your bags on this client."] =
    "Futter: Deine Taschen konnten in diesem Spiel nicht gelesen werden."
L["food: %d items in %d slots, %d pieces your pet will eat."] =
    "Futter: %d Gegenstände in %d Plätzen, %d Stück davon frisst dein Begleiter."
L["food: %s."] = "Futter: %s."
L["food: %s"] = "Futter: %s"
L["list the food in your bags and whether your pet will eat it"] =
    "zeigt das Futter in deinen Taschen und ob dein Begleiter es frisst"

-- The pet's status
L["%s (%d%% damage)"] = "%s (%d%% Schaden)"
L["falling"] = "sinkt"
L["rising"] = "steigt"
L["%s free (%d total, %d spent)"] = "%s frei (%d insgesamt, %d ausgegeben)"
L["Unhappy"] = "Unglücklich"
L["Content"] = "Zufrieden"
L["Happy"] = "Glücklich"
L["Your pet"] = "Dein Begleiter"
L["%s is %s. Feed it."] = "%s ist %s. Zeit zum Füttern."

-- Tames and pet skills
L["noted what %s teaches: %s"] = "notiert, was %s lehrt: %s"
L["the beast"] = "das Wildtier"
L["nothing"] = "nichts"
L["list the beasts you have tamed and what each taught"] =
    "listet die Wildtiere, die du gezähmt hast, und was jedes gelehrt hat"
L["no tamed beasts yet. Tame one and it shows up here."] =
    "noch keine gezähmten Wildtiere. Zähme eins, dann taucht es hier auf."
L["beasts you've tamed (%d):"] = "Wildtiere, die du gezähmt hast (%d):"
L["list the pet skills this hunter knows"] = "listet die Begleiterfertigkeiten, die dieser Jäger kennt"
L["no pet skills known yet. Open Beast Training once so Pets can read the list."] =
    "noch keine Begleiterfähigkeiten bekannt. Öffne einmal die Tierausbildung, damit Pets die Liste lesen kann."
L["pet skills known (%d): %s"] = "bekannte Begleiterfertigkeiten (%d): %s"
L["You haven't opened Beast Training on this character yet."] =
    "Du hast die Tierausbildung mit diesem Charakter noch nicht geöffnet."
L["%s (Rank %d)"] = "%s (Rang %d)"

-- TomTom
L["TomTom is off. The beast arrow shows its own dial."] = "TomTom ist aus. Der Wildtierpfeil zeigt seine eigene Scheibe."
L["TomTom is on. Its arrow points where the beast arrow would."] =
    "TomTom ist an. Sein Pfeil zeigt dorthin, wohin der Wildtierpfeil zeigen würde."
L["TomTom takes over once it's installed."] = "TomTom übernimmt, sobald es installiert ist."

-- Map pins
L["there's no exact spot for that one"] = "für dieses gibt es keine genaue Stelle"
L["this client can't put a pin on the map"] = "dieses Spiel kann keine Markierung auf die Karte setzen"
L["couldn't find the map for that zone"] = "die Karte dieser Zone war nicht zu finden"
L["pinned %s on your map: %s (%s, %s)"] = "%s auf deiner Karte markiert: %s (%s, %s)"
L["can't pin %s%s: %s"] = "%s%s kann nicht markiert werden: %s"
L["that"] = "das"

-- The arrow's window
L["beast arrow off. The Arrow button in the Pet Compendium, /bpet arrow or Settings brings it back."] =
    "Wildtierpfeil aus. Die Schaltfläche Pfeil im Begleiterkompendium, /bpet arrow oder die Einstellungen holen ihn zurück."
L["Beast arrow"] = "Wildtierpfeil"
L["Click to open the Pet Compendium."] = "Klick öffnet das Begleiterkompendium."
L["Drag to move it."] = "Ziehen verschiebt ihn."
L["Can't see you here"] = "Hier nicht zu sehen"
L["The game won't say where you are"] = "Das Spiel sagt nicht, wo du bist"

-- The compendium window
L["Pet Compendium"] = "Begleiterkompendium"
L["Click a beast to pin it on your map, or Shift-click to point the arrow at it. %s marks what WoW: Forever has shown."] =
    "Klick auf ein Wildtier markiert es auf deiner Karte, Shift-Klick richtet den Pfeil darauf aus. %s zeigt, was WoW: Forever gezeigt hat."
L["Settings"] = "Einstellungen"
L["Arrow"] = "Pfeil"
L["All families"] = "Alle Familien"
L["Search beasts, zones or skills"] = "Wildtier, Zone oder Fertigkeit suchen"
L["Tameable now"] = "Jetzt zähmbar"
L["Only beasts at or below your level."] = "Nur Wildtiere bis zu deiner Stufe."
L["Rares only"] = "Nur Seltene"
L["Teaches me something new"] = "Lehrt mich etwas Neues"
L["Only beasts that teach a skill you don't have yet."] = "Nur Wildtiere, die dir eine Fähigkeit lehren, die du noch nicht hast."
L["Only beasts known to live on WoW: Forever."] = "Nur Wildtiere, die es auf WoW: Forever sicher gibt."
L["Click again to flip it, and once more to go back."] = "Klick noch mal zum Umdrehen und ein weiteres Mal zum Zurücksetzen."
L["Beast"] = "Wildtier"
L["Sort by beast"] = "Nach Wildtier sortieren"
L["Family"] = "Familie"
L["Sort by family"] = "Nach Familie sortieren"
L["Level"] = "Stufe"
L["Sort by level"] = "Nach Stufe sortieren"
L["Speed"] = "Tempo"
L["Sort by speed"] = "Nach Tempo sortieren"
L["Seconds between its attacks. Lower is faster."] = "Sekunden zwischen seinen Angriffen. Weniger ist schneller."
L["Where"] = "Wo"
L["Sort by where"] = "Nach Ort sortieren"
L["Teaches"] = "Lehrt"
L["Not known yet"] = "Noch nicht bekannt"
L["Raid"] = "Schlachtzug"
L["Dungeon"] = "Dungeon"
L["tamed"] = "gezähmt"
L["Nothing"] = "Nichts"
L["beast arrow pointing at %s. Hide it with its red gem, /bpet arrow off or Settings."] =
    "Wildtierpfeil zeigt auf %s. Ausblenden kannst du ihn mit seinem roten Edelstein, /bpet arrow off oder in den Einstellungen."
L["where %s lives isn't known yet, so the arrow can't point at it."] =
    "wo %s lebt, ist noch nicht bekannt, also kann der Pfeil nicht darauf zeigen."
L["Family not known yet"] = "Familie noch nicht bekannt"
L["Eats %s"] = "Frisst %s"
L["Level %s. You can tame it now."] = "Stufe %s. Du kannst es jetzt zähmen."
L["Level %s. You can tame it from level %d."] = "Stufe %s. Du kannst es ab Stufe %d zähmen."
L["Level %s"] = "Stufe %s"
L["Attack speed %s"] = "Angriffstempo %s"
L["Attack speed %s (seen on Forever)"] = "Angriffstempo %s (auf Forever gesehen)"
L["Where it lives is not known yet."] = "Wo es lebt, ist noch nicht bekannt."
L["Shift-click to point the arrow at it."] = "Umschalt-Klick richtet den Pfeil darauf."
L["Also in %s"] = "Auch in %s"
L["Found in %d spots. This one is near the middle."] = "An %d Stellen zu finden. Diese liegt etwa in der Mitte."
L["Comes back after %s"] = "Taucht nach %s wieder auf"
L["Taming it teaches nothing new."] = "Es zu zähmen lehrt nichts Neues."
L["Taming it teaches"] = "Es zu zähmen lehrt"
L["(known)"] = "(bekannt)"
L["(not known)"] = "(nicht bekannt)"
L["Click to pin it on your map."] = "Klicken markiert es auf deiner Karte."
L["No exact spot to pin. Shift-click to point the arrow at its zone."] =
    "Keine genaue Stelle zum Markieren. Shift-Klick richtet den Pfeil auf seine Zone aus."
L["No place to pin yet."] = "Noch kein Ort zum Markieren."
L["Beasts a hunter can tame. You are level %d."] = "Wildtiere, die ein Jäger zähmen kann. Du bist Stufe %d."
L["Beasts a hunter can tame."] = "Wildtiere, die ein Jäger zähmen kann."
L["No beast matches. Untick a box or clear the search."] =
    "Kein Wildtier passt. Nimm einen Haken weg oder leere die Suche."
L["%d beasts"] = "%d Wildtiere"
L["%d of %d beasts"] = "%d von %d Wildtieren"
L["open the Pet Compendium: every beast you can tame"] =
    "öffnet das Begleiterkompendium: jedes Wildtier, das du zähmen kannst"

-- The Feed buttons
L["Feed"] = "Füttern"
L["Feed %s"] = "%s füttern"
L["%s is %s."] = "%s ist %s."
L["hungry"] = "hungrig"

-- The Pet care key
L["the Pet care key feeds a hunter's pet."] = "die Begleiterpflege-Taste füttert den Begleiter eines Jägers."
L["you have no pet out."] = "du hast keinen Begleiter draußen."
L["the game did not say what your pet eats."] = "das Spiel hat nicht gesagt, was dein Begleiter frisst."
L["your bags are still loading. Try again in a moment."] =
    "deine Taschen laden noch. Versuch es gleich noch einmal."
L["you have no food in your bags that %s will eat."] = "du hast kein Futter in den Taschen, das %s frisst."
L["your pet can't be fed in combat."] = "dein Begleiter kann im Kampf nicht gefüttert werden."
L["your demon is already out."] = "dein Dämon ist schon draußen."
L["nothing to feed your pet yet."] = "noch nichts, womit du deinen Begleiter füttern kannst."
L["Pet care key (%s)"] = "Begleiterpflege-Taste (%s)"
L["Pet care key (not set yet, find it under Options, Keybindings, AddOns)"] =
    "Begleiterpflege-Taste (noch nicht belegt, du findest sie unter Optionen, Tastaturbelegung, AddOns)"
L["calls your pet when none is out"] = "ruft deinen Begleiter, wenn keiner draußen ist"
L["revives your pet"] = "belebt deinen Begleiter wieder"
L["summons your demon when none is out"] = "beschwört deinen Dämon, wenn keiner draußen ist"
L[", and "] = " und "
L["mends it in combat"] = "heilt ihn im Kampf"
L["%s feeds %s%s."] = "%s füttert %s%s."
L["%s has nothing to feed: %s"] = "%s hat nichts zum Füttern: %s"
L["not checked yet."] = "noch nicht geprüft."
L["Pet care (call, revive, feed or mend)"] = "Begleiterpflege (rufen, wiederbeleben, füttern oder heilen)"
L["Dismiss pet"] = "Begleiter entlassen"

-- The pets window
L["level %s"] = "Stufe %s"
L["Pet"] = "Begleiter"
L["Happiness"] = "Zufriedenheit"
L["Loyalty"] = "Treue"
L["Experience"] = "Erfahrung"
L["Hunter"] = "Jäger"
L["Warlock"] = "Hexenmeister"
L["Training points"] = "Trainingspunkte"
L["Pets is for hunters and warlocks."] = "Pets ist für Jäger und Hexenmeister."
L["Eats"] = "Frisst"
L["Food"] = "Futter"
L["Health"] = "Gesundheit"
L["Attack speed"] = "Angriffstempo"
L["Damage"] = "Schaden"
L["Attack power"] = "Angriffskraft"
L["Armor"] = "Rüstung"
L["Resistances"] = "Widerstände"
L["Fire"] = "Feuer"
L["Nature"] = "Natur"
L["Frost"] = "Frost"
L["Shadow"] = "Schatten"
L["Arcane"] = "Arkan"
L["%.2f seconds"] = "%.2f Sekunden"
L["%d to %d (%.1f a second)"] = "%d bis %d (%.1f pro Sekunde)"
L["%d to %d"] = "%d bis %d"
L["%s %d"] = "%s %d"
L["open the pets window (so does /bpet on its own)"] = "öffnet das Begleiterfenster (wie /bpet allein)"
L["No pet out."] = "Kein Begleiter draußen."

-- The minimap button
L["Click to open"] = "Klicken zum Öffnen"
L["Right-click for settings"] = "Rechtsklick für die Einstellungen"
L["Click for settings"] = "Klicken für die Einstellungen"
L["Drag to move it round the minimap"] = "Ziehen verschiebt ihn um die Minikarte"

-- Settings
L["Changes save as you make them."] = "Änderungen werden sofort gespeichert."
L["Reload"] = "Neu laden"
L["FEEDING"] = "FÜTTERN"
L["TAMING"] = "ZÄHMEN"
L["PET COMPENDIUM"] = "BEGLEITERKOMPENDIUM"
L["BEAST ARROW"] = "WILDTIERPFEIL"
L["Check"] = "Prüfen"
L["Clear"] = "Lösen"
L["WINDOWS"] = "FENSTER"
L["HUNTER PET"] = "JÄGERBEGLEITER"
L["ADVANCED"] = "ERWEITERT"
L["Feeding warnings, the Feed button and taming skills on tooltips"] =
    "Futterwarnungen, der Füttern-Knopf und Zähmfertigkeiten in Tooltips"
L["COMPENDIUM"] = "KOMPENDIUM"
L["The Pet Compendium, the beast arrow and TomTom"] = "Das Begleiterkompendium, der Wildtierpfeil und TomTom"
L["GENERAL"] = "ALLGEMEIN"
L["Pets' settings have a window of their own."] = "Die Einstellungen von Pets haben ein eigenes Fenster."
L["Open Pets settings"] = "Einstellungen von Pets öffnen"
L["Or type /bpet settings, or click the minimap button."] =
    "Oder tippe /bpet settings, oder klicke auf den Minikartenknopf."
L["open the settings window"] = "öffnet das Einstellungsfenster"

-- The settings pages
L["Show descriptions"] = "Beschreibungen zeigen"
L["Find a setting"] = "Einstellung suchen"
L["Normal"] = "Normal"
L["Large"] = "Groß"
L["Larger"] = "Größer"

-- The taming tooltip
L["Taming teaches"] = "Zähmen lehrt"
L["Known"] = "Bekannt"
L["Not known"] = "Nicht bekannt"
L["Open Beast Training once to see which you know"] = "Öffne einmal die Tierausbildung, um zu sehen, welche du kennst"

-- The house frame
L["Close"] = "Schließen"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Neuigkeiten"
L["BLACKTHORNES ADDONS"] = "BLACKTHORNES-ADDONS"
L["Here's what changed since you last played."] = "Das hat sich seit deinem letzten Spiel geändert."
L["The newest changes in each of your Blackthornes addons."] = "Die neuesten Änderungen in jedem deiner Blackthornes-Addons."
L["Show after updates"] = "Nach Updates zeigen"
L["Motion"] = "Bewegung"
L["Got it"] = "Alles klar"
L["there is no news to show yet."] = "es gibt noch keine Neuigkeiten."
L["open the What's New window for every Blackthornes addon"] = "öffnet das Neuigkeiten-Fenster für alle Blackthornes-Addons"

-- ======================================================================
-- Settings rows (the owner's walk-through, 2026-10-15)
L["On"] = "An"
L["Show"] = "Anzeigen"
L["Open"] = "Öffnen"
L["Feed Warning:"] = "Futterwarnung:"
L["Only When Unhappy"] = "Nur wenn unglücklich"
L["Warns you when your pet isn't happy. Only When Unhappy waits until it's unhappy."] =
    "Warnt dich, wenn dein Begleiter nicht glücklich ist. Mit Nur wenn unglücklich wartet sie, bis er unglücklich ist."
L["Low Food Warning:"] = "Warnung bei wenig Futter:"
L["Warns you in chat when you have fewer than %d food your pet will eat."] =
    "Warnt dich im Chat, wenn du weniger als %d Futter hast, das dein Begleiter frisst."
L["Never Feed Buff Food:"] = "Nie Buff-Essen füttern:"
L["Food that gives a buff is always fed last. Tick this to never feed it."] =
    "Essen mit einem Buff wird immer zuletzt verfüttert. Setz den Haken, damit es nie verfüttert wird."
L["Feed Button:"] = "Füttern-Knopf:"
L["A Feed button above your quests while your pet is hungry."] =
    "Ein Füttern-Knopf über deinen Quests, solange dein Begleiter Hunger hat."
L["Taming Skills:"] = "Zähmfertigkeiten:"
L["A beast's tooltip shows what it teaches. Green you know, red you don't."] =
    "Der Tooltip eines Wildtiers zeigt, was es lehrt. Grün kennst du, rot nicht."
L["Pet Compendium:"] = "Begleiterkompendium:"
L["Beast Arrow:"] = "Wildtierpfeil:"
L["Points the way to a beast. Shift-click one in the compendium to aim it."] =
    "Zeigt den Weg zu einem Wildtier. Umschalt-Klick auf eins im Kompendium richtet ihn aus."
L["Check the Arrow:"] = "Pfeil prüfen:"
L["Lists in chat what the arrow can read here."] = "Zeigt im Chat, was der Pfeil hier lesen kann."
L["Stop Following:"] = "Nicht mehr folgen:"
L["Use TomTom:"] = "TomTom nutzen:"
L["With TomTom installed, its arrow shows the way instead."] = "Ist TomTom installiert, zeigt stattdessen sein Pfeil den Weg."
L["Pets:"] = "Pets:"
L["Window Position:"] = "Fensterposition:"
L["Reset the UI windows to their defaults."] = "Setzt die Fenster auf ihre Standardplätze zurück."
L["Set Default"] = "Zurücksetzen"
L["UI windows set to defaults."] = "Fenster auf ihre Standardplätze zurückgesetzt."
L["Text Size:"] = "Textgröße:"
L["Window Style:"] = "Fensterstil:"
L["Debug:"] = "Debug:"
L["Extra chat messages to help track down a problem."] = "Zusätzliche Chat-Nachrichten, um einem Problem auf die Spur zu kommen."
L["Sister Addons:"] = "Schwester-Addons:"
L["Says once in chat which Blackthornes addons you don't have."] = "Sagt einmal im Chat, welche Blackthornes-Addons dir fehlen."
L["What's New:"] = "Neuigkeiten:"
L["What's New After Updates:"] = "Neuigkeiten nach Updates:"
L["Opens What's New the first time you play after an update."] = "Öffnet die Neuigkeiten, wenn du nach einem Update zum ersten Mal spielst."
L["What's New Motion:"] = "Bewegung der Neuigkeiten:"
L["Client Check:"] = "Spiel prüfen:"
L["Lists in chat what the game tells Pets about your pet."] = "Zeigt im Chat, was das Spiel Pets über deinen Begleiter verrät."
L["Window position, text size and debug output"] = "Fensterposition, Textgröße und Debug-Ausgabe"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Einige von euch haben gefragt, ob beim Erstellen meiner AddOns KI genutzt wird. Ja, das wird sie."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Ich entwickle seit 25 Jahren Software und arbeite in der IT, und ich empfehle Entwicklern heute, KI zu nutzen, aber mit Sorgfalt und Absicht. Für mich heißt das: Ich entscheide, was gebaut wird, ich lege die Regeln fest, an die sich der Code halten muss, ich prüfe den Code, und ich teste Änderungen selbst im Spiel. KI hilft mir, den Code zu schreiben, die Tests laufen zu lassen und Fehler aufzuspüren."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Gut eingesetzt heißt das mehr Funktionen, schnellere Fehlerbehebungen und schnellere Umsetzung eurer Wünsche. Vieles in diesen Addons begann als Idee oder Fehlermeldung eines Spielers."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Wenn du eine Idee hast oder etwas nicht funktioniert, schau auf meinem Discord unter discord.gg/f2geDecrw2 vorbei. Ich lese jeden Kommentar und jede Meldung."
L["%s, version %s"] = "%s, Version %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Klicke in das Feld und drücke Strg+C, um den Link zu kopieren."
L["REPORT A BUG"] = "FEHLER MELDEN"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Schreib es auf meinem Discord, mit dem, was du gerade gemacht hast, als es passiert ist. Ich lese jeden Kommentar und jede Meldung."
L["THANK YOU"] = "DANKE"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Vieles hier begann als Idee oder Fehlermeldung eines Spielers. Danke an alle, die eine geschickt haben."
L["installed"] = "installiert"
L["turned off"] = "ausgeschaltet"
L["not installed"] = "nicht installiert"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Wie diese Addons entstehen"
L["A note from Blackthornes."] = "Ein Hinweis von Blackthornes."
L["ABOUT"] = "ÜBER"
L["HOW THESE ADDONS ARE MADE"] = "WIE DIESE ADDONS ENTSTEHEN"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Wie diese Addons entstehen, die Version, der Discord und die anderen Blackthornes-Addons"
