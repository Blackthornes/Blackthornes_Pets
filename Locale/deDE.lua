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
L["has sister addons that share what they know: %s. %s on CurseForge."] =
    "hat Schwester-Addons, die ihr Wissen teilen: %s. %s auf CurseForge."
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
L["tamed %s, arrow put away."] = "%s gezähmt, Pfeil weggepackt."
L["your beast"] = "dein Wildtier"
L["%d,%03d yd"] = "%d.%03d m"
L["%d yd"] = "%d m"
L["Inside a raid"] = "In einem Schlachtzug"
L["Inside a dungeon"] = "In einem Dungeon"
L["Far from here: head for %s"] = "Weit weg: geh nach %s"
L["it"] = "es"
L["No exact spot known in this zone"] = "Keine genaue Stelle in dieser Zone bekannt"
L["The middle of the zone: no exact spot known"] = "Die Mitte der Zone: keine genaue Stelle bekannt"
L["Where it lived in Classic"] = "Wo es in Classic lebte"
L["Far away"] = "Weit weg"
L["In %s"] = "In %s"
L["this zone"] = "dieser Zone"
L["You're there"] = "Du bist da"
L["beast arrow on, pointing at %s."] = "Wildtierpfeil an, er zeigt auf %s."
L["beast arrow on. Shift-click a beast in the Pet Compendium for it to point at."] =
    "Wildtierpfeil an. Klicke mit Umschalt auf ein Wildtier im Begleiterkompendium, damit er darauf zeigt."
L["beast arrow off. /bpet arrow on shows it."] = "Wildtierpfeil aus. /bpet arrow on zeigt ihn wieder."
L["an arrow to a beast from the Pet Compendium (on, off, clear, check, tomtom, reset)"] =
    "ein Pfeil zu einem Wildtier aus dem Begleiterkompendium (on, off, clear, check, tomtom, reset)"
L["beast arrow is not following a beast now."] = "Der Wildtierpfeil folgt jetzt keinem Wildtier."
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
L["%s, which it does not eat"] = "%s, das es nicht frisst"
L["too low level"] = "zu niedrige Stufe"
L["buff food, which you chose never to feed"] = "Buff-Essen, das du nie verfüttern wolltest"
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
L["list the food in your bags and whether your pet will eat it (reads only)"] =
    "listet das Futter in deinen Taschen und ob dein Begleiter es frisst (liest nur)"

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
L["recorded what %s teaches: %s"] = "notiert, was %s lehrt: %s"
L["the beast"] = "das Wildtier"
L["nothing"] = "nichts"
L["list the beasts you have tamed and what each taught"] =
    "listet die Wildtiere, die du gezähmt hast, und was jedes gelehrt hat"
L["no tamed beasts recorded yet. Tame one and it is written down."] =
    "noch keine gezähmten Wildtiere notiert. Zähme eins, dann wird es aufgeschrieben."
L["tamed beasts recorded (%d):"] = "notierte gezähmte Wildtiere (%d):"
L["list the pet skills this hunter knows"] = "listet die Begleiterfertigkeiten, die dieser Jäger kennt"
L["no pet skills known yet. Open Beast Training once so the list can be read."] =
    "noch keine Begleiterfertigkeiten bekannt. Öffne einmal die Tierausbildung, damit die Liste gelesen werden kann."
L["pet skills known (%d): %s"] = "bekannte Begleiterfertigkeiten (%d): %s"
L["Beast Training has not been opened on this character yet."] =
    "Die Tierausbildung wurde mit diesem Charakter noch nicht geöffnet."
L["%s (Rank %d)"] = "%s (Rang %d)"

-- TomTom
L["TomTom not used: the beast arrow shows its own dial."] =
    "TomTom wird nicht genutzt: Der Wildtierpfeil zeigt seine eigene Scheibe."
L["TomTom used: its arrow shows the beast arrow's place."] =
    "TomTom wird genutzt: Sein Pfeil zeigt den Ort des Wildtierpfeils."
L["TomTom will be used once it is installed."] = "TomTom wird genutzt, sobald es installiert ist."

-- Map pins
L["no exact spot is known for that one"] = "für dieses ist keine genaue Stelle bekannt"
L["this client cannot put a pin on the map"] = "dieses Spiel kann keine Markierung auf die Karte setzen"
L["the map for that zone could not be found"] = "die Karte dieser Zone wurde nicht gefunden"
L["pinned %s on your map: %s (%s, %s)"] = "%s auf deiner Karte markiert: %s (%s, %s)"
L["can't pin %s%s: %s"] = "%s%s kann nicht markiert werden: %s"
L["that"] = "das"

-- The arrow's window
L["beast arrow off. The Arrow button in the Pet Compendium, /bpet arrow or Settings brings it back."] =
    "Wildtierpfeil aus. Die Schaltfläche Pfeil im Begleiterkompendium, /bpet arrow oder die Einstellungen holen ihn zurück."
L["Beast arrow"] = "Wildtierpfeil"
L["Click to open the Pet Compendium; Shift-click a beast there to follow it."] =
    "Klicken öffnet das Begleiterkompendium; Umschalt-Klick auf ein Wildtier dort, um ihm zu folgen."
L["Drag to move it. The red gem closes it."] = "Ziehen verschiebt ihn. Der rote Edelstein schließt ihn."
L["Can't see you here"] = "Hier nicht zu sehen"
L["The game won't say where you are"] = "Das Spiel sagt nicht, wo du bist"

-- The compendium window
L["Pet Compendium"] = "Begleiterkompendium"
L["Click a beast to pin it on your map, Shift-click to point the arrow at it. %s marks what WoW: Forever has shown; the rest is Classic 1.12."] =
    "Klicke auf ein Wildtier, um es auf der Karte zu markieren, Umschalt-Klick richtet den Pfeil darauf. %s kennzeichnet, was WoW: Forever gezeigt hat; der Rest ist Classic 1.12."
L["Settings"] = "Einstellungen"
L["Arrow"] = "Pfeil"
L["A dial that turns as you turn, pointing the way to a beast. Shift-click a beast to aim it. Click again to hide it."] =
    "Eine Scheibe, die sich mit dir dreht und den Weg zu einem Wildtier zeigt. Umschalt-Klick auf ein Wildtier richtet sie aus. Noch ein Klick blendet sie aus."
L["All families"] = "Alle Familien"
L["Search beasts, zones or skills"] = "Wildtier, Zone oder Fertigkeit suchen"
L["Tameable now"] = "Jetzt zähmbar"
L["Only beasts at or below your level, which you can tame now."] =
    "Nur Wildtiere bis zu deiner Stufe, die du jetzt zähmen kannst."
L["Rares only"] = "Nur Seltene"
L["Only rare and rare elite beasts."] = "Nur seltene Wildtiere und seltene Elite."
L["Teaches me something new"] = "Lehrt mich etwas Neues"
L["Only beasts whose taming teaches a skill this hunter has not got."] =
    "Nur Wildtiere, deren Zähmung eine Fertigkeit lehrt, die dieser Jäger noch nicht hat."
L["Only beasts WoW: Forever has shown: seen, tamed or named by a Forever guide."] =
    "Nur Wildtiere, die WoW: Forever gezeigt hat: gesehen, gezähmt oder von einem Forever-Leitfaden genannt."
L["Click again to turn the order round, and a third time to go back to sorting by beast."] =
    "Noch ein Klick dreht die Reihenfolge um, ein dritter sortiert wieder nach Wildtier."
L["Beast"] = "Wildtier"
L["Sort by beast"] = "Nach Wildtier sortieren"
L["Family"] = "Familie"
L["Sort by family"] = "Nach Familie sortieren"
L["Level"] = "Stufe"
L["Sort by level"] = "Nach Stufe sortieren"
L["Speed"] = "Tempo"
L["Sort by speed"] = "Nach Tempo sortieren"
L["Seconds between its bites and claws: lower is faster. Sorts fastest first."] =
    "Sekunden zwischen seinen Bissen und Klauenhieben: weniger ist schneller. Sortiert die schnellsten zuerst."
L["Where"] = "Wo"
L["Sort by where"] = "Nach Ort sortieren"
L["Teaches"] = "Lehrt"
L["Not known yet"] = "Noch nicht bekannt"
L["Raid"] = "Schlachtzug"
L["Dungeon"] = "Dungeon"
L["tamed"] = "gezähmt"
L["Nothing"] = "Nichts"
L["beast arrow pointing at %s. Its red gem, /bpet arrow off or Settings hides it."] =
    "Wildtierpfeil zeigt auf %s. Sein roter Edelstein, /bpet arrow off oder die Einstellungen blenden ihn aus."
L["where %s lives is not known yet, so the arrow cannot point at it."] =
    "wo %s lebt, ist noch nicht bekannt, also kann der Pfeil nicht darauf zeigen."
L["Family not known yet"] = "Familie noch nicht bekannt"
L["Eats %s"] = "Frisst %s"
L["Level %s. You can tame it now."] = "Stufe %s. Du kannst es jetzt zähmen."
L["Level %s. You can tame it from level %d."] = "Stufe %s. Du kannst es ab Stufe %d zähmen."
L["Level %s"] = "Stufe %s"
L["read off a tamed pet on Forever"] = "an einem gezähmten Begleiter auf Forever abgelesen"
L["Classic data"] = "Classic-Daten"
L["Attack speed %s (%s)"] = "Angriffstempo %s (%s)"
L["Classic said %s."] = "Laut Classic %s."
L["Where it lives is not known yet."] = "Wo es lebt, ist noch nicht bekannt."
L["Shift-click to point the arrow at it."] = "Umschalt-Klick richtet den Pfeil darauf."
L["Also in %s"] = "Auch in %s"
L["%d spawn points; the spot shown is near the middle."] =
    "%d Fundorte; die gezeigte Stelle liegt nahe der Mitte."
L["Comes back after %s"] = "Taucht nach %s wieder auf"
L["Taming it teaches nothing new."] = "Es zu zähmen lehrt nichts Neues."
L["Taming it teaches"] = "Es zu zähmen lehrt"
L["(known)"] = "(bekannt)"
L["(not known)"] = "(nicht bekannt)"
L["Classic had it in %s."] = "In Classic war es in %s."
L["Click to pin it on your map."] = "Klicken markiert es auf deiner Karte."
L["No exact spot to pin; Shift-click to point the arrow at its zone."] =
    "Keine genaue Stelle zum Markieren; Umschalt-Klick richtet den Pfeil auf seine Zone."
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
L["Pet care key (not set; Options, Keybindings, AddOns)"] =
    "Begleiterpflege-Taste (nicht belegt; Optionen, Tastaturbelegung, AddOns)"
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
L["open the pets window (so does /bpet on its own)"] = "öffnet das Begleiterfenster (wie /bpet allein)"
L["No pet out."] = "Kein Begleiter draußen."

-- The minimap button
L["Click to open"] = "Klicken zum Öffnen"
L["Right-click for settings"] = "Rechtsklick für die Einstellungen"
L["Click for settings"] = "Klicken für die Einstellungen"
L["Drag to move it round the minimap"] = "Ziehen verschiebt ihn um die Minikarte"
L["show or hide the minimap button"] = "zeigt den Minikartenknopf oder blendet ihn aus"
L["minimap button shown."] = "Minikartenknopf eingeblendet."
L["minimap button hidden. /bpet minimap brings it back."] =
    "Minikartenknopf ausgeblendet. /bpet minimap holt ihn zurück."

-- Settings
L["Changes save as you make them."] = "Änderungen werden sofort gespeichert."
L["Reload"] = "Neu laden"
L["Reload the interface so the new window style shows (/reload)"] =
    "Lädt die Oberfläche neu, damit der neue Fensterstil erscheint (/reload)"
L["FEEDING"] = "FÜTTERN"
L["Feed warning"] = "Futterwarnung"
L["A warning in chat and on screen when your pet is no longer happy."] =
    "Eine Warnung im Chat und auf dem Bildschirm, wenn dein Begleiter nicht mehr glücklich ist."
L["Warn me"] = "Warnen"
L["Only when unhappy"] = "Nur wenn unglücklich"
L["Stay quiet while the pet is content, and warn only once it is unhappy."] =
    "Bleibt still, solange der Begleiter zufrieden ist, und warnt erst, wenn er unglücklich ist."
L["Enabled"] = "Aktiviert"
L["Low food warning"] = "Warnung bei wenig Futter"
L["A warning in chat when you have fewer than %d food your pet will eat."] =
    "Eine Warnung im Chat, wenn du weniger als %d Futter hast, das dein Begleiter frisst."
L["Buff food"] = "Buff-Essen"
L["Food that gives a buff, like stat food, is always fed last. Tick this to never feed it."] =
    "Essen mit einem Buff, etwa Werte-Essen, wird immer zuletzt verfüttert. Setz den Haken, damit dein Begleiter es nie bekommt."
L["Never feed it"] = "Nie verfüttern"
L["Feed button by quests"] = "Füttern-Knopf bei den Quests"
L["A small Feed button above the quest list while your pet needs feeding."] =
    "Ein kleiner Füttern-Knopf über der Questliste, solange dein Begleiter Futter braucht."
L["Show it"] = "Anzeigen"
L["Food in your bags"] = "Futter in deinen Taschen"
L["Lists in chat the food in your bags and whether your pet will eat it. Same as /bpet food."] =
    "Listet im Chat das Futter in deinen Taschen und ob dein Begleiter es frisst. Wie /bpet food."
L["List it"] = "Auflisten"
L["TAMING"] = "ZÄHMEN"
L["Taming skills"] = "Fertigkeiten beim Zähmen"
L["On a beast's tooltip, the pet skills taming it teaches: green if you know them, red if not."] =
    "Im Tooltip eines Wildtiers die Begleiterfertigkeiten, die das Zähmen lehrt: grün, wenn du sie kennst, sonst rot."
L["Show them"] = "Anzeigen"
L["Your pet skills"] = "Deine Begleiterfertigkeiten"
L["Lists in chat the pet skills this hunter knows. Same as /bpet taming."] =
    "Listet im Chat die Begleiterfertigkeiten, die dieser Jäger kennt. Wie /bpet taming."
L["List them"] = "Auflisten"
L["Beasts you tamed"] = "Deine gezähmten Wildtiere"
L["Lists in chat the beasts you have tamed and what each one taught. Same as /bpet tamed."] =
    "Listet im Chat die Wildtiere, die du gezähmt hast, und was jedes gelehrt hat. Wie /bpet tamed."
L["PET COMPENDIUM"] = "BEGLEITERKOMPENDIUM"
L["Every beast you can tame: what it teaches, its level, where it lives and how rare it is. Also /bpet compendium."] =
    "Jedes Wildtier, das du zähmen kannst: was es lehrt, seine Stufe, wo es lebt und wie selten es ist. Auch /bpet compendium."
L["Open it"] = "Öffnen"
L["BEAST ARROW"] = "WILDTIERPFEIL"
L["A dial that points the way to a beast. Shift-click one in the compendium to aim it. Also /bpet arrow."] =
    "Eine Scheibe, die den Weg zu einem Wildtier zeigt. Umschalt-Klick auf eins im Kompendium richtet sie aus. Auch /bpet arrow."
L["Check the arrow"] = "Pfeil prüfen"
L["Lists in chat what the arrow can read where you stand: your spot, your facing, the map. Same as /bpet arrow check."] =
    "Listet im Chat, was der Pfeil dort lesen kann, wo du stehst: deine Position, deine Blickrichtung, die Karte. Wie /bpet arrow check."
L["Check"] = "Prüfen"
L["Use TomTom"] = "TomTom nutzen"
L["With TomTom installed, its arrow points the way instead of this one. Same as /bpet arrow tomtom."] =
    "Ist TomTom installiert, zeigt dessen Pfeil den Weg statt dieses. Wie /bpet arrow tomtom."
L["When installed"] = "Wenn installiert"
L["WINDOWS"] = "FENSTER"
L["Pets window"] = "Begleiterfenster"
L["The pet that is out, how it is doing and its food. Same as /bpet window, or /bpet on its own."] =
    "Der Begleiter, der draußen ist, wie es ihm geht und sein Futter. Wie /bpet window oder /bpet allein."
L["Minimap button"] = "Minikartenknopf"
L["Click it for the pets window, right-click for this page. Drag it to move it. Also /bpet minimap."] =
    "Klick öffnet das Begleiterfenster, Rechtsklick diese Seite. Ziehen verschiebt ihn. Auch /bpet minimap."
L["Window position"] = "Fensterposition"
L["Moves this window and the beast arrow back where they started, if one ends up off screen."] =
    "Setzt dieses Fenster und den Wildtierpfeil an ihren Anfangsplatz zurück, falls eins außerhalb des Bildschirms landet."
L["Put it back"] = "Zurücksetzen"
L["Text size"] = "Textgröße"
L["Large and Larger add a point or two to all of this addon's text. Takes effect after /reload."] =
    "Groß und Größer machen den ganzen Text dieses Addons ein bis zwei Punkte größer. Wirkt nach /reload."
L["Window style"] = "Fensterstil"
L["Titanforged is the house look, with a gold rim and glowing edges. Blizzard uses the game's own frames, red buttons and tick boxes. Takes effect after /reload."] =
    "Titanforged ist der Hausstil, mit goldenem Rand und leuchtenden Kanten. Blizzard nutzt die eigenen Fenster, roten Knöpfe und Kästchen des Spiels. Wirkt nach /reload."
L["HUNTER PET"] = "JÄGERBEGLEITER"
L["ADVANCED"] = "ERWEITERT"
L["Debug output"] = "Debug-Ausgabe"
L["Extra messages in chat, to help track down a problem."] =
    "Zusätzliche Meldungen im Chat, um einem Problem auf die Spur zu kommen."
L["Feeding warnings, the Feed button and taming skills on tooltips"] =
    "Futterwarnungen, der Füttern-Knopf und Zähmfertigkeiten in Tooltips"
L["Sister addons"] = "Schwester-Addons"
L["Once, a few seconds after login, says in chat which Blackthornes addons you don't have and what each adds. Turning it off here turns it off in all of them. Same as /bpet sisters."] =
    "Sagt einmal, ein paar Sekunden nach dem Einloggen, im Chat, welche Blackthornes-Addons dir fehlen und was jedes bietet. Hier aus heißt in allen aus. Wie /bpet sisters."
L["Mention them"] = "Erwähnen"
L["Client check"] = "Spiel prüfen"
L["COMPENDIUM"] = "KOMPENDIUM"
L["Lists in chat which pet calls this client has, to help track down a problem. It only reads. Same as /bpet probe."] =
    "Listet im Chat, welche Begleiterfunktionen dieses Spiel hat, um einem Problem auf die Spur zu kommen. Liest nur. Wie /bpet probe."
L["Commands"] = "Befehle"
L["Lists every /bpet command in chat. Same as /bpet help."] = "Listet jeden /bpet-Befehl im Chat. Wie /bpet help."
L["The Pet Compendium, the beast arrow and TomTom"] = "Das Begleiterkompendium, der Wildtierpfeil und TomTom"
L["GENERAL"] = "ALLGEMEIN"
L["The minimap button, window position, text size and debug output"] =
    "Minikartenknopf, Fensterposition, Textgröße und Debug-Ausgabe"
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
L["Reload the interface so the new text size shows (/reload)"] =
    "Lädt die Oberfläche neu, damit die neue Textgröße erscheint (/reload)"

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
L["Opens the What's New window: what changed in each of your Blackthornes addons. Same as /bpet whatsnew."] = "Öffnet das Neuigkeiten-Fenster: was sich in jedem deiner Blackthornes-Addons geändert hat. Wie /bpet whatsnew."
L["After an update"] = "Nach einem Update"
L["Brings up the What's New window the first time you play after a Blackthornes addon updates. Turning it off here turns it off in all of them."] = "Zeigt das Neuigkeiten-Fenster, wenn du nach einem Update eines Blackthornes-Addons zum ersten Mal spielst. Hier ausgeschaltet ist es in allen aus."
L["Show What's New"] = "Neuigkeiten zeigen"
L["What's New motion"] = "Bewegung der Neuigkeiten"
L["The What's New window rises in, and its news slides up and glows. Turning it off here turns it off in all of them."] = "Das Neuigkeiten-Fenster gleitet herein, und seine Neuigkeiten schieben sich hoch und leuchten. Hier ausgeschaltet ist es in allen aus."
