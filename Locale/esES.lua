-- Blackthornes Pets -- Locale/esES.lua
-- Spanish: the words players see, on a Spanish client (Spain or Latin America).
--
-- Each line is the English key (exactly as the code writes it) and its
-- Spanish. A key with no line here shows in English. The Spanish uses the
-- game's own words (mascota, bestia, domesticar, adiestramiento de bestias,
-- comida, nivel, metros) and "tú", so it reads well in Spain and Latin
-- America alike. A line may name its values by place ("%2$s ... %1$s")
-- where Spanish word order needs it; L.Format puts them in order.
--
-- Beast, family, zone and skill names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and (locale == "esES" or locale == "esMX")) then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Guardado para Claude, usa /reload para escribirlo."
L["module %s:%s failed"] = "el módulo %s:%s falló"
L["show this list"] = "muestra esta lista"
L["unknown command: %s"] = "comando desconocido: %s"
L["/bpet %s failed: %s"] = "/bpet %s falló: %s"

-- The sister note
L["and"] = "y"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "funciona con otros addons de Blackthornes que aún no tienes: %s. %s en CurseForge."
L["It's"] = "Lo encuentras"
L["They're"] = "Los encuentras"
L["This note shows once."] = "Este aviso sale solo una vez."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "activa o desactiva el aviso único sobre los otros addons de Blackthornes"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "el aviso sobre los otros addons de Blackthornes está activado. Sale una vez por cada uno que no tengas."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "el aviso sobre los otros addons de Blackthornes está desactivado en todos ellos."
L["where to farm any material"] = "dónde conseguir cualquier material"
L["auction prices, crafting profits and a craft queue"] =
    "precios de subasta, ganancias de fabricación y una cola de fabricación"
L["which gear is an upgrade for you, and where to get it"] =
    "qué equipo es una mejora para ti y dónde conseguirlo"
L["feeding and taming for hunter and warlock pets"] =
    "alimentar y domesticar mascotas de cazador y brujo"
L["what to do with every item in your bags"] = "qué hacer con cada objeto de tus bolsas"

-- Diets
L["Meat"] = "Carne"
L["Fish"] = "Pescado"
L["Bread"] = "Pan"
L["Cheese"] = "Queso"
L["Fruit"] = "Fruta"
L["Fungus"] = "Hongos"

-- The beast arrow
L["you tamed %s, so the arrow is put away."] = "domesticaste a %s, así que la flecha se guarda."
L["your beast"] = "tu bestia"
L["%d,%03d yd"] = "%d.%03d m"
L["%d yd"] = "%d m"
L["Inside a raid"] = "Dentro de una banda"
L["Inside a dungeon"] = "Dentro de una mazmorra"
L["Far from here. Head for %s"] = "Lejos de aquí. Ve hacia %s"
L["it"] = "eso"
L["No exact spot for it in this zone yet"] = "Aún no hay un punto exacto en esta zona"
L["The middle of the zone, since there's no exact spot yet"] =
    "El centro de la zona, porque aún no hay un punto exacto"
L["Where it lived in Classic"] = "Donde vivía en Classic"
L["Far away"] = "Muy lejos"
L["In %s"] = "En %s"
L["this zone"] = "esta zona"
L["You're there"] = "Ya llegaste"
L["beast arrow on, pointing at %s."] = "flecha de bestia activada, apunta a %s."
L["beast arrow on. Shift-click a beast in the Pet Compendium to aim it."] =
    "flecha de bestia activada. Haz Mayús-clic en una bestia del Compendio de mascotas para apuntarla."
L["beast arrow off. /bpet arrow on shows it."] = "flecha de bestia desactivada. /bpet arrow on la muestra."
L["an arrow to a beast from the Pet Compendium (on, off, clear, check, tomtom, route, reset)"] =
    "una flecha hacia una bestia del Compendio de mascotas (on, off, clear, check, tomtom, route, reset)"
L["the beast arrow isn't following a beast right now."] = "la flecha de bestia no sigue a ninguna bestia ahora."
L["beast arrow put back where it started."] = "la flecha de bestia volvió a su sitio de inicio."
L["/bpet arrow on, off, clear, check, tomtom, route or reset."] = "/bpet arrow on, off, clear, check, tomtom, route o reset."

-- The compendium's data
L["Rare"] = "Raro"
L["Rare elite"] = "Élite raro"
L["Elite"] = "Élite"
L["hours"] = "horas"
L["minutes"] = "minutos"
L["%d %s to %d %s"] = "%d %s a %d %s"
L["dungeon"] = "mazmorra"
L["raid"] = "banda"
L["Seen on Forever"] = "Visto en Forever"
L["Tamed on Forever"] = "Domesticado en Forever"
L["Found on Forever"] = "Encontrado en Forever"
L["You tamed it on Forever"] = "Lo domesticaste en Forever"
L["Beast %d"] = "Bestia %d"

-- Food
L["%s, which it doesn't eat"] = "%s, que no come"
L["too low level"] = "nivel demasiado bajo"
L["buff food, which you've chosen not to feed"] = "comida con beneficio, que elegiste no darle"
L["full"] = "mucho"
L["half"] = "a medias"
L["little"] = "poco"
L["refused"] = "la rechaza"
L["None in your bags"] = "No hay en tus bolsas"
L["%s (%s), %d in bags"] = "%s (%s), %d en las bolsas"
L["running low"] = "se acaba"
L["You have no food %s will eat."] = "No tienes comida que %s quiera comer."
L["your pet"] = "tu mascota"
L["Only %d food left that %s will eat."] = "A %2$s solo le queda %1$d de comida."
L["food: no pet out."] = "comida: no tienes mascota fuera."
L["food: %s (level %s) eats %s"] = "comida: %s (nivel %s) come %s"
L["item %s"] = "objeto %s"
L[" (level %s)"] = " (nivel %s)"
L[", buff food (fed last)"] = ", comida con beneficio (se da al final)"
L["not in the food list:"] = "no está en la lista de comida:"
L["food: %d items in %d slots, %d pieces your pet will eat."] =
    "comida: %d objetos en %d huecos, %d que tu mascota quiere comer."
L["food: %s."] = "comida: %s."
L["food: %s"] = "comida: %s"
L["list the food in your bags and whether your pet will eat it"] =
    "muestra la comida de tus bolsas y si tu mascota la come"

-- The pet's status
L["%s (%d%% damage)"] = "%s (%d%% de daño)"
L["falling"] = "bajando"
L["rising"] = "subiendo"
L["%s free (%d total, %d spent)"] = "%s libres (%d en total, %d usados)"
L["Unhappy"] = "Infeliz"
L["Content"] = "A gusto"
L["Happy"] = "Feliz"
L["Your pet"] = "Tu mascota"
L["%s is %s. Feed it."] = "%s está %s. Dale de comer."

-- Tames and pet skills
L["noted what %s teaches: %s"] = "anotado lo que enseña %s: %s"
L["the beast"] = "la bestia"
L["nothing"] = "nada"
L["list the beasts you have tamed and what each taught"] =
    "muestra las bestias que domesticaste y lo que enseñó cada una"
L["no tamed beasts yet. Tame one and it shows up here."] =
    "aún no has domesticado bestias. Domestica una y saldrá aquí."
L["beasts you've tamed (%d):"] = "bestias que domesticaste (%d):"
L["list the pet skills this hunter knows"] = "muestra las habilidades de mascota que conoce este cazador"
L["no pet skills known yet. Open Beast Training once so Pets can read the list."] =
    "aún no se conocen habilidades de mascota. Abre Adiestramiento de bestias una vez para que Pets lea la lista."
L["pet skills known (%d): %s"] = "habilidades de mascota conocidas (%d): %s"
L["You haven't opened Beast Training on this character yet."] =
    "Aún no has abierto Adiestramiento de bestias con este personaje."
L["%s (Rank %d)"] = "%s (Rango %d)"

-- TomTom
L["TomTom is off. The beast arrow shows its own dial."] = "TomTom está desactivado. La flecha de bestia muestra su propio indicador."
L["TomTom is on. Its arrow points where the beast arrow would."] =
    "TomTom está activado. Su flecha apunta adonde apuntaría la flecha de bestia."
L["TomTom takes over once it's installed."] = "TomTom se encarga cuando lo instalas."

-- Map pins
L["there's no exact spot for that one"] = "no hay un punto exacto para eso"
L["this client can't put a pin on the map"] = "este juego no puede poner una marca en el mapa"
L["couldn't find the map for that zone"] = "no se encontró el mapa de esa zona"
L["pinned %s on your map: %s (%s, %s)"] = "%s marcado en tu mapa: %s (%s, %s)"
L["can't pin %s%s: %s"] = "no se puede marcar %s%s: %s"
L["that"] = "eso"

-- The arrow's window
L["beast arrow off. The Arrow button in the Pet Compendium, /bpet arrow or Settings brings it back."] =
    "flecha de bestia desactivada. El botón Flecha del Compendio de mascotas, /bpet arrow o la Configuración la traen de vuelta."
L["Beast arrow"] = "Flecha de bestia"
L["Can't see you here"] = "Aquí no se ve dónde estás"
L["The game won't say where you are"] = "El juego no dice dónde estás"

-- The compendium window
L["Click a beast to pin it on your map, or Shift-click to point the arrow at it. %s marks what WoW: Forever has shown."] =
    "Haz clic en una bestia para marcarla en tu mapa, o Mayús-clic para que la flecha la apunte. %s indica lo que se ha visto en WoW: Forever."
L["Settings"] = "Configuración"
L["Arrow"] = "Flecha"
L["All families"] = "Todas las familias"
L["Search beasts, zones or skills"] = "Busca bestias, zonas o habilidades"
L["Tameable now"] = "Se puede domesticar ya"
L["Only beasts at or below your level."] = "Solo bestias de tu nivel o menos."
L["Rares only"] = "Solo raros"
L["Teaches me something new"] = "Me enseña algo nuevo"
L["Only beasts that teach a skill you don't have yet."] = "Solo bestias que enseñan una habilidad que aún no tienes."
L["Only beasts known to live on WoW: Forever."] = "Solo bestias que se sabe que viven en WoW: Forever."
L["Click again to flip it, and once more to go back."] = "Haz clic otra vez para darle la vuelta, y una más para volver."
L["Beast"] = "Bestia"
L["Sort by beast"] = "Ordenar por bestia"
L["Family"] = "Familia"
L["Sort by family"] = "Ordenar por familia"
L["Level"] = "Nivel"
L["Sort by level"] = "Ordenar por nivel"
L["Speed"] = "Velocidad"
L["Sort by speed"] = "Ordenar por velocidad"
L["Seconds between its attacks. Lower is faster."] = "Segundos entre sus ataques. Menos es más rápido."
L["Where"] = "Dónde"
L["Sort by where"] = "Ordenar por lugar"
L["Teaches"] = "Enseña"
L["Not known yet"] = "Aún no se sabe"
L["Raid"] = "Banda"
L["Dungeon"] = "Mazmorra"
L["tamed"] = "domesticada"
L["Nothing"] = "Nada"
L["beast arrow pointing at %s. Hide it with its red gem, /bpet arrow off or Settings."] =
    "la flecha de bestia apunta a %s. Ocúltala con su gema roja, /bpet arrow off o la Configuración."
L["where %s lives isn't known yet, so the arrow can't point at it."] =
    "aún no se sabe dónde vive %s, así que la flecha no puede apuntarla."
L["Family not known yet"] = "Familia aún desconocida"
L["Eats %s"] = "Come %s"
L["Level %s. You can tame it now."] = "Nivel %s. Ya puedes domesticarla."
L["Level %s. You can tame it from level %d."] = "Nivel %s. Puedes domesticarla desde el nivel %d."
L["Level %s"] = "Nivel %s"
L["Attack speed %s"] = "Velocidad de ataque %s"
L["Attack speed %s (seen on Forever)"] = "Velocidad de ataque %s (vista en Forever)"
L["Where it lives is not known yet."] = "Aún no se sabe dónde vive."
L["Shift-click to point the arrow at it."] = "Haz Mayús-clic para que la flecha la apunte."
L["Also in %s"] = "También en %s"
L["Found in %d spots. This one is near the middle."] = "Vista en %d puntos. Este está cerca del centro."
L["Comes back after %s"] = "Vuelve a salir tras %s"
L["Taming it teaches nothing new."] = "Domesticarla no enseña nada nuevo."
L["Taming it teaches"] = "Domesticarla enseña"
L["(known)"] = "(conocida)"
L["(not known)"] = "(no conocida)"
L["Click to pin it on your map."] = "Haz clic para marcarla en tu mapa."
L["No exact spot to pin. Shift-click to point the arrow at its zone."] =
    "No hay un punto exacto para marcar. Haz Mayús-clic para que la flecha apunte a su zona."
L["No place to pin yet."] = "Aún no hay lugar para marcar."
L["Beasts a hunter can tame. You are level %d."] = "Bestias que un cazador puede domesticar. Eres de nivel %d."
L["Beasts a hunter can tame."] = "Bestias que un cazador puede domesticar."
L["No beast matches. Untick a box or clear the search."] =
    "Ninguna bestia coincide. Desmarca una casilla o borra la búsqueda."
L["%d beasts"] = "%d bestias"
L["open the Pet Compendium: every beast you can tame"] =
    "abre el Compendio de mascotas: todas las bestias que puedes domesticar"

-- The Feed buttons
L["Feed"] = "Alimentar"
L["Feed %s"] = "Dar %s"
L["%s is %s."] = "%s está %s."
L["hungry"] = "con hambre"

-- The Pet care key
L["the Pet care key feeds a hunter's pet."] = "la tecla Cuidar mascota alimenta a la mascota de un cazador."
L["you have no pet out."] = "no tienes mascota fuera."
L["the game did not say what your pet eats."] = "el juego no dijo qué come tu mascota."
L["your bags are still loading. Try again in a moment."] =
    "tus bolsas aún se están cargando. Inténtalo de nuevo en un momento."
L["you have no food in your bags that %s will eat."] = "no tienes comida en tus bolsas que %s quiera comer."
L["your pet can't be fed in combat."] = "no puedes alimentar a tu mascota en combate."
L["your demon is already out."] = "tu demonio ya está fuera."
L["nothing to feed your pet yet."] = "aún no hay nada para darle a tu mascota."
L["Pet care key (%s)"] = "Tecla Cuidar mascota (%s)"
L["Pet care key (not set yet, find it under Options, Keybindings, AddOns)"] =
    "Tecla Cuidar mascota (aún sin asignar, búscala en Opciones, Asignación de teclas, AddOns)"
L["calls your pet when none is out"] = "llama a tu mascota si no hay ninguna fuera"
L["revives your pet"] = "revive a tu mascota"
L["summons your demon when none is out"] = "invoca a tu demonio si no hay ninguno fuera"
L[", and "] = ", y "
L["mends it in combat"] = "la cura en combate"
L["%s feeds %s%s."] = "%s da %s%s."
L["%s has nothing to feed: %s"] = "%s no tiene nada para dar: %s"
L["not checked yet."] = "aún sin revisar."
L["Pet care (call, revive, feed or mend)"] = "Cuidar mascota (llamar, revivir, alimentar o curar)"
L["Dismiss pet"] = "Retirar mascota"

-- The pets window
L["FOOD"] = "COMIDA"
L["IN A FIGHT"] = "EN COMBATE"
L["Damage a second"] = "Daño por segundo"
L["Damage a hit"] = "Daño por golpe"
L["%s, level %s"] = "%s, nivel %s"
L["1 training point free"] = "1 punto de adiestramiento libre"
L["%d training points free"] = "%d puntos de adiestramiento libres"
L["%d training points over"] = "%d puntos de adiestramiento de más"
L["%d in your bags (%s)"] = "%d en tus bolsas (%s)"
L["No food"] = "Sin comida"
L["Enough food for about %.1f hours"] = "Comida para unas %.1f horas"
L["Not enough food to keep it happy"] = "No hay comida suficiente para tenerla feliz"
L["Happiness"] = "Felicidad"
L["Loyalty"] = "Lealtad"
L["Experience"] = "Experiencia"
L["Hunter"] = "Cazador"
L["Warlock"] = "Brujo"
L["Training points"] = "Puntos de adiestramiento"
L["Pets is for hunters and warlocks."] = "Pets es para cazadores y brujos."
L["Eats"] = "Come"
L["Health"] = "Salud"
L["Attack speed"] = "Velocidad de ataque"
L["Attack power"] = "Poder de ataque"
L["Armor"] = "Armadura"
L["Resistances"] = "Resistencias"
L["Fire"] = "Fuego"
L["Nature"] = "Naturaleza"
L["Frost"] = "Escarcha"
L["Shadow"] = "Sombras"
L["Arcane"] = "Arcano"
L["%.2f seconds"] = "%.2f segundos"
L["%d to %d (%.1f a second)"] = "%d a %d (%.1f por segundo)"
L["%d to %d"] = "%d a %d"
L["%s %d"] = "%s %d"
L["open the pets window (so does /bpet on its own)"] = "abre la ventana de mascotas (también /bpet solo)"
L["No pet out."] = "No tienes mascota fuera."

-- The minimap button
L["Click to open"] = "Haz clic para abrir"
L["Right-click for settings"] = "Clic derecho para la configuración"
L["Click for settings"] = "Haz clic para la configuración"
L["Drag to move it round the minimap"] = "Arrastra para moverlo alrededor del minimapa"

-- Settings
L["Changes save as you make them."] = "Los cambios se guardan al hacerlos."
L["Reload"] = "Recargar"
L["FEEDING"] = "ALIMENTACIÓN"
L["TAMING"] = "DOMESTICAR"
L["PET COMPENDIUM"] = "COMPENDIO DE MASCOTAS"
L["BEAST ARROW"] = "FLECHA DE BESTIA"
L["Clear"] = "Borrar"
L["WINDOWS"] = "VENTANAS"
L["HUNTER PET"] = "MASCOTA DE CAZADOR"
L["ADVANCED"] = "AVANZADO"
L["Feeding warnings, the Feed button and taming skills on tooltips"] =
    "Avisos de comida, el botón Alimentar y las habilidades de domesticar en los recuadros de ayuda"
L["COMPENDIUM"] = "COMPENDIO"
L["The Pet Compendium, the beast arrow and TomTom"] = "El Compendio de mascotas, la flecha de bestia y TomTom"
L["GENERAL"] = "GENERAL"
L["Pets' settings have a window of their own."] = "La configuración de Pets tiene su propia ventana."
L["Open Pets settings"] = "Abrir configuración de Pets"
L["Or type /bpet settings, or click the minimap button."] =
    "O escribe /bpet settings, o haz clic en el botón del minimapa."
L["open the settings window"] = "abre la ventana de configuración"

-- The settings pages
L["Show descriptions"] = "Mostrar descripciones"
L["Find a setting"] = "Buscar una opción"
L["Normal"] = "Normal"
L["Large"] = "Grande"
L["Larger"] = "Más grande"

-- The taming tooltip
L["Taming teaches"] = "Domesticar enseña"
L["Known"] = "Conocida"
L["Not known"] = "No conocida"
L["Open Beast Training once to see which you know"] = "Abre Adiestramiento de bestias una vez para ver cuáles conoces"

-- The house frame
L["Close"] = "Cerrar"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Novedades"
L["BLACKTHORNES ADDONS"] = "ADDONS DE BLACKTHORNES"
L["Here's what changed since you last played."] = "Esto es lo que cambió desde la última vez que jugaste."
L["The newest changes in each of your Blackthornes addons."] = "Los cambios más nuevos de cada uno de tus addons de Blackthornes."
L["Show after updates"] = "Mostrar tras actualizar"
L["Motion"] = "Animación"
L["Got it"] = "Entendido"
L["there is no news to show yet."] = "aún no hay novedades que mostrar."
L["open the What's New window for every Blackthornes addon"] = "abre la ventana de Novedades de todos los addons de Blackthornes"

-- ======================================================================
-- Settings rows
L["On"] = "Activar"
L["Show"] = "Mostrar"
L["Open"] = "Abrir"
L["Feed Warning:"] = "Aviso de comida:"
L["Only When Unhappy"] = "Solo si está infeliz"
L["Warns you when your pet isn't happy. Only When Unhappy waits until it's unhappy."] =
    "Te avisa cuando tu mascota no está feliz. Solo si está infeliz espera a que esté infeliz."
L["Low Food Warning:"] = "Aviso de poca comida:"
L["Warns you in chat when you have fewer than %d food your pet will eat."] =
    "Te avisa en el chat cuando te queda menos de %d de comida que tu mascota quiera comer."
L["Never Feed Buff Food:"] = "No dar comida con beneficio:"
L["Food that gives a buff is always fed last. Tick this to never feed it."] =
    "La comida que da un beneficio siempre se da al final. Marca esto para no darla nunca."
L["Feed Button:"] = "Botón Alimentar:"
L["A Feed button above your quests while your pet is hungry."] =
    "Un botón Alimentar encima de tus misiones cuando tu mascota tiene hambre."
L["Taming Skills:"] = "Habilidades al domesticar:"
L["A beast's tooltip shows what it teaches. Green you know, red you don't."] =
    "El recuadro de ayuda de una bestia muestra lo que enseña. En verde lo que conoces, en rojo lo que no."
L["Pet Compendium:"] = "Compendio de mascotas:"
L["Beast Arrow:"] = "Flecha de bestia:"
L["Points the way to a beast. Shift-click one in the compendium to aim it."] =
    "Te muestra el camino hacia una bestia. Haz Mayús-clic en una del compendio para apuntarla."
L["Stop Following:"] = "Dejar de seguir:"
L["Use TomTom:"] = "Usar TomTom:"
L["With TomTom installed, its arrow shows the way instead."] = "Si tienes TomTom, su flecha te muestra el camino."
L["Pets:"] = "Pets:"
L["Window Position:"] = "Posición de ventanas:"
L["Reset the UI windows to their defaults."] = "Devuelve las ventanas a su sitio de inicio."
L["Set Default"] = "Restablecer"
L["UI windows set to defaults."] = "Ventanas devueltas a su sitio de inicio."
L["Text Size:"] = "Tamaño de texto:"
L["Window Style:"] = "Estilo de ventana:"
L["Sister Addons:"] = "Addons hermanos:"
L["Says once in chat which Blackthornes addons you don't have."] = "Dice una vez en el chat qué addons de Blackthornes no tienes."
L["What's New:"] = "Novedades:"
L["What's New After Updates:"] = "Novedades tras actualizar:"
L["Opens What's New the first time you play after an update."] = "Abre Novedades la primera vez que juegas tras una actualización."
L["What's New Motion:"] = "Animación de Novedades:"
L["Window position, text size and What's New"] = "Posición de la ventana, tamaño del texto y Novedades"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Algunos me han preguntado si uso IA para crear mis AddOns. Sí, la uso."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Llevo 25 años creando software y trabajando en informática, y recomiendo a los desarrolladores de hoy que la usen, pero con cuidado y con intención. Para mí eso significa que yo decido qué se crea, yo pongo las reglas que el código tiene que seguir, yo reviso el código y yo mismo pruebo los cambios en el juego. La IA me ayuda a escribir el código, pasar las pruebas y encontrar errores."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Bien usada, significa más funciones, errores arreglados antes y respuestas más rápidas a lo que pides. Mucho de lo que hay en estos addons empezó como una idea o un aviso de error de un jugador."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Si tienes una idea o algo no funciona, búscame en mi Discord: discord.gg/f2geDecrw2. Leo cada comentario y cada aviso."
L["%s, version %s"] = "%s, versión %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Haz clic en el recuadro y pulsa Ctrl+C para copiar el enlace."
L["REPORT A BUG"] = "AVISAR DE UN ERROR"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Escríbelo en mi Discord y cuenta qué hacías cuando pasó. Leo cada comentario y cada aviso."
L["THANK YOU"] = "GRACIAS"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Mucho de lo que hay aquí empezó como la idea o el aviso de error de un jugador. Gracias a todos los que mandaron uno."
L["installed"] = "instalado"
L["turned off"] = "desactivado"
L["not installed"] = "no instalado"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Cómo se hacen estos addons"
L["A note from Blackthornes."] = "Unas palabras de Blackthornes."
L["Thank you"] = "Gracias"
L["Thank you to everyone who sent ideas and bug reports. You helped shape every one of these add-ons. Without you, they would not be what they are today."] = "Gracias a todos los que enviaron ideas e informes de errores. Ayudaron a dar forma a cada uno de estos addons. Sin ustedes, no serían lo que son hoy."
L["There are still some bugs to work out, and those fixes will come with time. If you find one, jump on our Discord and share it. You can find the link on the About page in Settings. Every message gets read."] = "Todavía quedan algunos errores por arreglar, y las correcciones llegarán con el tiempo. Si encuentras uno, entra en nuestro Discord y cuéntanoslo. El enlace está en la página «Acerca de» de los ajustes. Cada mensaje se lee."
L["WoW Forever is almost here, and we can't wait. We look forward to building and improving these add-ons with you from here on."] = "WoW Forever ya casi está aquí, y no podemos esperar. Tenemos muchas ganas de seguir creando y mejorando estos addons con ustedes a partir de ahora."
L["ABOUT"] = "ACERCA DE"
L["HOW THESE ADDONS ARE MADE"] = "CÓMO SE HACEN ESTOS ADDONS"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Cómo se hacen estos addons, la versión, el Discord y los otros addons de Blackthornes"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).
L["Off"] = "Apagado"
L["Shift"] = "Mayús"
L["Always"] = "Siempre"
L["Hold Shift for more."] = "Mantén Mayús para ver más."
L["Drag to make the window bigger or smaller."] = "Arrastra para hacer la ventana más grande o más pequeña."
L["Right-click to go back to normal size."] = "Clic derecho para volver al tamaño normal."
L["EFFECTS"] = "EFECTOS"
L["Effects:"] = "Efectos:"
L["Full"] = "Completo"
L["Subtle"] = "Suave"
L["Couldn't tell what your pet eats yet."] = "Aún no se sabe qué come tu mascota."
L["Couldn't read your bags. Try again in a moment."] = "No se pudieron leer tus bolsas. Inténtalo de nuevo en un momento."
L["Name not loaded yet"] = "Nombre aún no cargado"
L["Your filters hide 1 beast."] = "Tus filtros ocultan 1 bestia."
L["Your filters hide %d beasts."] = "Tus filtros ocultan %d bestias."

-- The way there (Logic/Travel.lua, the same in every addon).
L["Fly to %s"] = "Vuela a %s"
L["Talk to the flight master"] = "Habla con el maestro de vuelo"
L["Wait here for the boat to %s"] = "Espera aquí el barco a %s"
L["Get on when it stops"] = "Sube cuando pare"
L["Take the boat to %s"] = "Toma el barco a %s"
L["Wait here for the zeppelin to %s"] = "Espera aquí el zepelín a %s"
L["Take the zeppelin to %s"] = "Toma el zepelín a %s"
L["Use your Hearthstone"] = "Usa tu piedra de hogar"
L["It takes you to %s"] = "Te lleva a %s"
L["Walk to %s"] = "Camina a %s"
L["toward %s"] = "hacia %s"
L["Next: %s."] = "Siguiente: %s."
L["Your Way There"] = "Tu camino"
L["Show on Map"] = "Ver en el mapa"
L["Stop"] = "Parar"
L["Done"] = "Hecho"
L["Now"] = "Ahora"
L["About 1 minute"] = "Un minuto más o menos"
L["About %d minutes"] = "Unos %d minutos"
L["Guide Me:"] = "Guíame:"
L["Step %d of %d"] = "Paso %d de %d"
L["The arrow leads you step by step to places far away."] = "La flecha te lleva paso a paso a lugares lejanos."
L["The arrow points straight at places far away."] = "La flecha apunta en línea recta a lugares lejanos."
L["When the place is in another zone or across the sea, the arrow leads you there step by step."] = "Cuando el lugar está en otra zona o al otro lado del mar, la flecha te lleva paso a paso."

-- The Skills card and the window's tabs.
L["%d point"] = "%d punto"
L["%d points"] = "%d puntos"
L["%s Rank %d"] = "%s rango %d"
L["CAN LEARN NOW"] = "PUEDE APRENDER YA"
L["COST"] = "COSTE"
L["Click to see the beasts that teach it."] = "Haz clic para ver las bestias que lo enseñan."
L["Compendium"] = "Compendio"
L["LATER"] = "MÁS ADELANTE"
L["Pet"] = "Mascota"
L["Pet level %d"] = "Mascota nivel %d"
L["Pet trainer"] = "Instructor de mascotas"
L["Pet trainer: %s"] = "Instructor de mascotas: %s"
L["RANK"] = "RANGO"
L["Rank %d"] = "Rango %d"
L["SKILLS"] = "HABILIDADES"
L["Show the Way"] = "Mostrar el camino"
L["Tame a beast that knows it"] = "Doma una bestia que lo sepa"
L["WHEN"] = "CUÁNDO"
L["YOUR PET KNOWS"] = "TU MASCOTA SABE"
L["from a pet trainer"] = "de un instructor de mascotas"
L["from your Beast Training"] = "de tu Adiestramiento de bestias"
