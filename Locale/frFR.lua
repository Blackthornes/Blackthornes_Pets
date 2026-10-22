-- Blackthornes Pets -- Locale/frFR.lua
-- French: the words players see, on a French client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- French. A key with no line here shows in English. The French speaks to
-- the player as "tu" and uses the game's own words (familier, bête,
-- apprivoiser, dressage des bêtes, nourriture, niveau, mètres). A line may
-- name its values by place ("%2$s ... %1$s") where French word order needs
-- it; L.Format puts them in order.
--
-- Beast, family, zone and skill names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "frFR") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "Gardé pour Claude, /reload pour l'écrire."
L["module %s:%s failed"] = "le module %s:%s a échoué"
L["show this list"] = "affiche cette liste"
L["unknown command: %s"] = "commande inconnue : %s"
L["/bpet %s failed: %s"] = "/bpet %s a échoué : %s"

-- The sister note
L["and"] = "et"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "marche avec d'autres addons Blackthornes que tu n'as pas encore : %s. %s sur CurseForge."
L["It's"] = "Tu le trouves"
L["They're"] = "Tu les trouves"
L["This note shows once."] = "Ce message ne s'affiche qu'une fois."
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "active ou coupe le message unique sur les autres addons Blackthornes"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "le message sur les autres addons Blackthornes est activé. Il s'affiche une fois pour chaque addon que tu n'as pas."
L["the note about the other Blackthornes addons is off, in all of them."] =
    "le message sur les autres addons Blackthornes est coupé, dans tous."
L["where to farm any material"] = "où farmer chaque matériau"
L["auction prices, crafting profits and a craft queue"] =
    "les prix de l'hôtel des ventes, les gains d'artisanat et une liste de fabrication"
L["which gear is an upgrade for you, and where to get it"] =
    "quel équipement est mieux pour toi, et où le trouver"
L["feeding and taming for hunter and warlock pets"] =
    "nourrir et apprivoiser les familiers des chasseurs et des démonistes"
L["what to do with every item in your bags"] = "quoi faire de chaque objet dans tes sacs"

-- Diets
L["Meat"] = "Viande"
L["Fish"] = "Poisson"
L["Bread"] = "Pain"
L["Cheese"] = "Fromage"
L["Fruit"] = "Fruits"
L["Fungus"] = "Champignons"

-- The beast arrow
L["you tamed %s, so the arrow is put away."] = "tu as apprivoisé %s, alors la flèche est rangée."
L["your beast"] = "ta bête"
L["%d,%03d yd"] = "%d %03d m"
L["%d yd"] = "%d m"
L["Inside a raid"] = "Dans un raid"
L["Inside a dungeon"] = "Dans un donjon"
L["Far from here. Head for %s"] = "Loin d'ici. Va vers %s"
L["it"] = "ça"
L["No exact spot for it in this zone yet"] = "Pas encore d'endroit précis dans cette zone"
L["The middle of the zone, since there's no exact spot yet"] =
    "Le milieu de la zone, car il n'y a pas encore d'endroit précis"
L["Where it lived in Classic"] = "Où elle vivait dans Classic"
L["Far away"] = "Très loin"
L["In %s"] = "Dans %s"
L["this zone"] = "cette zone"
L["You're there"] = "Tu y es"
L["beast arrow on, pointing at %s."] = "flèche des bêtes activée, elle montre %s."
L["beast arrow on. Shift-click a beast in the Pet Compendium to aim it."] =
    "flèche des bêtes activée. Fais Maj-clic sur une bête dans le Compendium des familiers pour la viser."
L["beast arrow off. /bpet arrow on shows it."] = "flèche des bêtes coupée. /bpet arrow on la remet."
L["an arrow to a beast from the Pet Compendium (on, off, clear, check, tomtom, route, reset)"] =
    "une flèche vers une bête du Compendium des familiers (on, off, clear, check, tomtom, route, reset)"
L["the beast arrow isn't following a beast right now."] = "la flèche des bêtes ne suit aucune bête pour le moment."
L["beast arrow put back where it started."] = "flèche des bêtes remise à sa place de départ."
L["/bpet arrow on, off, clear, check, tomtom, route or reset."] = "/bpet arrow on, off, clear, check, tomtom, route ou reset."

-- The compendium's data
L["Rare"] = "Rare"
L["Rare elite"] = "Élite rare"
L["Elite"] = "Élite"
L["hours"] = "heures"
L["minutes"] = "minutes"
L["%d %s to %d %s"] = "%d %s à %d %s"
L["dungeon"] = "donjon"
L["raid"] = "raid"
L["Seen on Forever"] = "Vue sur Forever"
L["Tamed on Forever"] = "Apprivoisée sur Forever"
L["Found on Forever"] = "Trouvée sur Forever"
L["You tamed it on Forever"] = "Tu l'as apprivoisée sur Forever"
L["Beast %d"] = "Bête %d"

-- Food
L["%s, which it doesn't eat"] = "%s, qu'il ne mange pas"
L["too low level"] = "niveau trop bas"
L["buff food, which you've chosen not to feed"] = "nourriture à bonus, que tu as choisi de ne pas donner"
L["full"] = "plein"
L["half"] = "moitié"
L["little"] = "peu"
L["refused"] = "refusé"
L["None in your bags"] = "Rien dans tes sacs"
L["%s (%s), %d in bags"] = "%s (%s), %d dans les sacs"
L["running low"] = "bientôt épuisé"
L["You have no food %s will eat."] = "Tu n'as aucune nourriture que %s mange."
L["your pet"] = "ton familier"
L["Only %d food left that %s will eat."] = "%2$s n'a plus que %1$d nourriture à manger."
L["food: no pet out."] = "nourriture : aucun familier n'est sorti."
L["food: %s (level %s) eats %s"] = "nourriture : %s (niveau %s) mange %s"
L["item %s"] = "objet %s"
L[" (level %s)"] = " (niveau %s)"
L[", buff food (fed last)"] = ", nourriture à bonus (donnée en dernier)"
L["not in the food list:"] = "pas dans la liste de nourriture :"
L["food: %d items in %d slots, %d pieces your pet will eat."] =
    "nourriture : %d objets dans %d emplacements, dont %d que ton familier mange."
L["food: %s."] = "nourriture : %s."
L["food: %s"] = "nourriture : %s"
L["list the food in your bags and whether your pet will eat it"] =
    "liste la nourriture dans tes sacs et dit si ton familier la mange"

-- The pet's status
L["%s (%d%% damage)"] = "%s (%d%% de dégâts)"
L["falling"] = "en baisse"
L["rising"] = "en hausse"
L["%s free (%d total, %d spent)"] = "%s libres (%d au total, %d dépensés)"
L["Unhappy"] = "Mécontent"
L["Content"] = "Satisfait"
L["Happy"] = "Content"
L["Your pet"] = "Ton familier"
L["%s is %s. Feed it."] = "%s est %s. Donne-lui à manger."

-- Tames and pet skills
L["noted what %s teaches: %s"] = "noté ce que %s apprend : %s"
L["the beast"] = "la bête"
L["nothing"] = "rien"
L["list the beasts you have tamed and what each taught"] =
    "liste les bêtes que tu as apprivoisées et ce que chacune t'a appris"
L["no tamed beasts yet. Tame one and it shows up here."] =
    "aucune bête apprivoisée pour l'instant. Apprivoises-en une et elle apparaîtra ici."
L["beasts you've tamed (%d):"] = "bêtes que tu as apprivoisées (%d) :"
L["list the pet skills this hunter knows"] = "liste les techniques de familier que ce chasseur connaît"
L["no pet skills known yet. Open Beast Training once so Pets can read the list."] =
    "aucune technique de familier connue pour l'instant. Ouvre le Dressage des bêtes une fois pour que Pets lise la liste."
L["pet skills known (%d): %s"] = "techniques de familier connues (%d) : %s"
L["You haven't opened Beast Training on this character yet."] =
    "Tu n'as pas encore ouvert le Dressage des bêtes avec ce personnage."
L["%s (Rank %d)"] = "%s (Rang %d)"

-- TomTom
L["TomTom is off. The beast arrow shows its own dial."] = "TomTom est coupé. La flèche des bêtes montre son propre cadran."
L["TomTom is on. Its arrow points where the beast arrow would."] =
    "TomTom est activé. Sa flèche montre là où la flèche des bêtes irait."
L["TomTom takes over once it's installed."] = "TomTom prend le relais dès qu'il est installé."

-- Map pins
L["there's no exact spot for that one"] = "il n'y a pas d'endroit précis pour celle-là"
L["this client can't put a pin on the map"] = "ce jeu ne peut pas mettre de repère sur la carte"
L["couldn't find the map for that zone"] = "impossible de trouver la carte de cette zone"
L["pinned %s on your map: %s (%s, %s)"] = "%s marqué sur ta carte : %s (%s, %s)"
L["can't pin %s%s: %s"] = "impossible de marquer %s%s : %s"
L["that"] = "ça"

-- The arrow's window
L["beast arrow off. The Arrow button in the Pet Compendium, /bpet arrow or Settings brings it back."] =
    "flèche des bêtes coupée. Le bouton Flèche du Compendium des familiers, /bpet arrow ou les options la remettent."
L["Beast arrow"] = "Flèche des bêtes"
L["Click to open the Pet Compendium."] = "Clique pour ouvrir le Compendium des familiers."
L["Drag to move it."] = "Fais-la glisser pour la déplacer."
L["Can't see you here"] = "Impossible de te voir ici"
L["The game won't say where you are"] = "Le jeu ne dit pas où tu es"

-- The compendium window
L["Click a beast to pin it on your map, or Shift-click to point the arrow at it. %s marks what WoW: Forever has shown."] =
    "Clique sur une bête pour la marquer sur ta carte, ou fais Maj-clic pour que la flèche la montre. %s marque ce que WoW: Forever a montré."
L["Settings"] = "Options"
L["Arrow"] = "Flèche"
L["All families"] = "Toutes les familles"
L["Search beasts, zones or skills"] = "Cherche une bête, une zone ou une technique"
L["Tameable now"] = "Apprivoisable maintenant"
L["Only beasts at or below your level."] = "Seulement les bêtes de ton niveau ou moins."
L["Rares only"] = "Rares seulement"
L["Teaches me something new"] = "M'apprend quelque chose de nouveau"
L["Only beasts that teach a skill you don't have yet."] = "Seulement les bêtes qui apprennent une technique que tu n'as pas encore."
L["Only beasts known to live on WoW: Forever."] = "Seulement les bêtes qu'on sait vivre sur WoW: Forever."
L["Click again to flip it, and once more to go back."] = "Clique encore pour inverser, et une fois de plus pour revenir."
L["Beast"] = "Bête"
L["Sort by beast"] = "Trier par bête"
L["Family"] = "Famille"
L["Sort by family"] = "Trier par famille"
L["Level"] = "Niveau"
L["Sort by level"] = "Trier par niveau"
L["Speed"] = "Vitesse"
L["Sort by speed"] = "Trier par vitesse"
L["Seconds between its attacks. Lower is faster."] = "Secondes entre ses attaques. Moins, c'est plus rapide."
L["Where"] = "Où"
L["Sort by where"] = "Trier par lieu"
L["Teaches"] = "Apprend"
L["Not known yet"] = "Pas encore connu"
L["Raid"] = "Raid"
L["Dungeon"] = "Donjon"
L["tamed"] = "apprivoisée"
L["Nothing"] = "Rien"
L["beast arrow pointing at %s. Hide it with its red gem, /bpet arrow off or Settings."] =
    "la flèche des bêtes montre %s. Cache-la avec sa gemme rouge, /bpet arrow off ou les options."
L["where %s lives isn't known yet, so the arrow can't point at it."] =
    "on ne sait pas encore où vit %s, alors la flèche ne peut pas la montrer."
L["Family not known yet"] = "Famille pas encore connue"
L["Eats %s"] = "Mange %s"
L["Level %s. You can tame it now."] = "Niveau %s. Tu peux l'apprivoiser maintenant."
L["Level %s. You can tame it from level %d."] = "Niveau %s. Tu peux l'apprivoiser dès le niveau %d."
L["Level %s"] = "Niveau %s"
L["Attack speed %s"] = "Vitesse d'attaque %s"
L["Attack speed %s (seen on Forever)"] = "Vitesse d'attaque %s (vue sur Forever)"
L["Where it lives is not known yet."] = "On ne sait pas encore où elle vit."
L["Shift-click to point the arrow at it."] = "Fais Maj-clic pour que la flèche la montre."
L["Also in %s"] = "Aussi dans %s"
L["Found in %d spots. This one is near the middle."] = "Trouvée à %d endroits. Celui-ci est vers le milieu."
L["Comes back after %s"] = "Revient après %s"
L["Taming it teaches nothing new."] = "L'apprivoiser n'apprend rien de nouveau."
L["Taming it teaches"] = "L'apprivoiser apprend"
L["(known)"] = "(connue)"
L["(not known)"] = "(pas connue)"
L["Click to pin it on your map."] = "Clique pour la marquer sur ta carte."
L["No exact spot to pin. Shift-click to point the arrow at its zone."] =
    "Pas d'endroit précis à marquer. Fais Maj-clic pour que la flèche montre sa zone."
L["No place to pin yet."] = "Pas encore d'endroit à marquer."
L["Beasts a hunter can tame. You are level %d."] = "Les bêtes qu'un chasseur peut apprivoiser. Tu es niveau %d."
L["Beasts a hunter can tame."] = "Les bêtes qu'un chasseur peut apprivoiser."
L["No beast matches. Untick a box or clear the search."] =
    "Aucune bête ne correspond. Décoche une case ou vide la recherche."
L["%d beasts"] = "%d bêtes"
L["open the Pet Compendium: every beast you can tame"] =
    "ouvre le Compendium des familiers : toutes les bêtes que tu peux apprivoiser"

-- The Feed buttons
L["Feed"] = "Nourrir"
L["Feed %s"] = "Nourrir %s"
L["%s is %s."] = "%s est %s."
L["hungry"] = "affamé"

-- The Pet care key
L["the Pet care key feeds a hunter's pet."] = "la touche Soin du familier nourrit le familier d'un chasseur."
L["you have no pet out."] = "tu n'as pas de familier sorti."
L["the game did not say what your pet eats."] = "le jeu n'a pas dit ce que mange ton familier."
L["your bags are still loading. Try again in a moment."] =
    "tes sacs sont encore en train de charger. Réessaie dans un instant."
L["you have no food in your bags that %s will eat."] = "tu n'as aucune nourriture dans tes sacs que %s mange."
L["your pet can't be fed in combat."] = "ton familier ne peut pas manger en combat."
L["your demon is already out."] = "ton démon est déjà sorti."
L["nothing to feed your pet yet."] = "rien à donner à ton familier pour l'instant."
L["Pet care key (%s)"] = "Touche Soin du familier (%s)"
L["Pet care key (not set yet, find it under Options, Keybindings, AddOns)"] =
    "Touche Soin du familier (pas encore choisie, tu la trouves dans Options, Raccourcis, AddOns)"
L["calls your pet when none is out"] = "appelle ton familier quand aucun n'est sorti"
L["revives your pet"] = "ressuscite ton familier"
L["summons your demon when none is out"] = "invoque ton démon quand aucun n'est sorti"
L[", and "] = " et "
L["mends it in combat"] = "le soigne en combat"
L["%s feeds %s%s."] = "%s nourrit avec %s%s."
L["%s has nothing to feed: %s"] = "%s n'a rien à donner : %s"
L["not checked yet."] = "pas encore vérifié."
L["Pet care (call, revive, feed or mend)"] = "Soin du familier (appeler, ressusciter, nourrir ou soigner)"
L["Dismiss pet"] = "Renvoyer le familier"

-- The pets window
L["FOOD"] = "NOURRITURE"
L["IN A FIGHT"] = "EN COMBAT"
L["Damage a second"] = "Dégâts par seconde"
L["Damage a hit"] = "Dégâts par coup"
L["%s, level %s"] = "%s, niveau %s"
L["1 training point free"] = "1 point de dressage libre"
L["%d training points free"] = "%d points de dressage libres"
L["%d training points over"] = "%d points de dressage en trop"
L["%d in your bags (%s)"] = "%d dans tes sacs (%s)"
L["No food"] = "Pas de nourriture"
L["Enough food for about %.1f hours"] = "Assez de nourriture pour environ %.1f heures"
L["Not enough food to keep it happy"] = "Pas assez de nourriture pour le garder content"
L["Happiness"] = "Humeur"
L["Loyalty"] = "Loyauté"
L["Experience"] = "Expérience"
L["Hunter"] = "Chasseur"
L["Warlock"] = "Démoniste"
L["Training points"] = "Points de dressage"
L["Pets is for hunters and warlocks."] = "Pets est fait pour les chasseurs et les démonistes."
L["Eats"] = "Mange"
L["Health"] = "Vie"
L["Attack speed"] = "Vitesse d'attaque"
L["Attack power"] = "Puissance d'attaque"
L["Armor"] = "Armure"
L["Resistances"] = "Résistances"
L["Fire"] = "Feu"
L["Nature"] = "Nature"
L["Frost"] = "Givre"
L["Shadow"] = "Ombre"
L["Arcane"] = "Arcanes"
L["%.2f seconds"] = "%.2f secondes"
L["%d to %d (%.1f a second)"] = "%d à %d (%.1f par seconde)"
L["%d to %d"] = "%d à %d"
L["%s %d"] = "%s %d"
L["open the pets window (so does /bpet on its own)"] = "ouvre la fenêtre des familiers (/bpet tout seul aussi)"
L["No pet out."] = "Aucun familier sorti."

-- The minimap button
L["Click to open"] = "Clique pour ouvrir"
L["Right-click for settings"] = "Clic droit pour les options"
L["Click for settings"] = "Clique pour les options"
L["Drag to move it round the minimap"] = "Fais-le glisser pour le déplacer autour de la minicarte"

-- Settings
L["Changes save as you make them."] = "Tes changements sont gardés tout de suite."
L["Reload"] = "Recharger"
L["FEEDING"] = "NOURRIR"
L["TAMING"] = "APPRIVOISER"
L["PET COMPENDIUM"] = "COMPENDIUM DES FAMILIERS"
L["BEAST ARROW"] = "FLÈCHE DES BÊTES"
L["Check"] = "Vérifier"
L["Clear"] = "Retirer"
L["WINDOWS"] = "FENÊTRES"
L["HUNTER PET"] = "FAMILIER DE CHASSEUR"
L["ADVANCED"] = "AVANCÉ"
L["Feeding warnings, the Feed button and taming skills on tooltips"] =
    "Alertes de nourriture, le bouton Nourrir et les techniques à apprivoiser dans les infobulles"
L["COMPENDIUM"] = "COMPENDIUM"
L["The Pet Compendium, the beast arrow and TomTom"] = "Le Compendium des familiers, la flèche des bêtes et TomTom"
L["GENERAL"] = "GÉNÉRAL"
L["Pets' settings have a window of their own."] = "Les options de Pets ont leur propre fenêtre."
L["Open Pets settings"] = "Ouvrir les options de Pets"
L["Or type /bpet settings, or click the minimap button."] =
    "Ou tape /bpet settings, ou clique sur le bouton de la minicarte."
L["open the settings window"] = "ouvre la fenêtre des options"

-- The settings pages
L["Show descriptions"] = "Afficher les descriptions"
L["Find a setting"] = "Chercher une option"
L["Normal"] = "Normal"
L["Large"] = "Grand"
L["Larger"] = "Plus grand"

-- The taming tooltip
L["Taming teaches"] = "L'apprivoiser apprend"
L["Known"] = "Connue"
L["Not known"] = "Pas connue"
L["Open Beast Training once to see which you know"] = "Ouvre le Dressage des bêtes une fois pour voir celles que tu connais"

-- The house frame
L["Close"] = "Fermer"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "Nouveautés"
L["BLACKTHORNES ADDONS"] = "ADDONS BLACKTHORNES"
L["Here's what changed since you last played."] = "Voici ce qui a changé depuis ta dernière partie."
L["The newest changes in each of your Blackthornes addons."] = "Les derniers changements de chacun de tes addons Blackthornes."
L["Show after updates"] = "Afficher après les mises à jour"
L["Motion"] = "Animation"
L["Got it"] = "Compris"
L["there is no news to show yet."] = "il n'y a pas encore de nouveautés à montrer."
L["open the What's New window for every Blackthornes addon"] = "ouvre la fenêtre des nouveautés pour tous les addons Blackthornes"

-- ======================================================================
-- Settings rows (the owner's walk-through, 2026-10-15)
L["On"] = "Activé"
L["Show"] = "Afficher"
L["Open"] = "Ouvrir"
L["Feed Warning:"] = "Alerte pour nourrir :"
L["Only When Unhappy"] = "Seulement si mécontent"
L["Warns you when your pet isn't happy. Only When Unhappy waits until it's unhappy."] =
    "T'avertit quand ton familier n'est pas content. Seulement si mécontent attend qu'il soit mécontent."
L["Low Food Warning:"] = "Alerte de nourriture basse :"
L["Warns you in chat when you have fewer than %d food your pet will eat."] =
    "T'avertit dans la discussion quand tu as moins de %d nourriture que ton familier mange."
L["Never Feed Buff Food:"] = "Jamais de nourriture à bonus :"
L["Food that gives a buff is always fed last. Tick this to never feed it."] =
    "La nourriture qui donne un bonus est toujours donnée en dernier. Coche ici pour ne jamais la donner."
L["Feed Button:"] = "Bouton Nourrir :"
L["A Feed button above your quests while your pet is hungry."] =
    "Un bouton Nourrir au-dessus de tes quêtes quand ton familier a faim."
L["Taming Skills:"] = "Techniques à apprivoiser :"
L["A beast's tooltip shows what it teaches. Green you know, red you don't."] =
    "L'infobulle d'une bête montre ce qu'elle apprend. En vert ce que tu connais, en rouge ce que tu ne connais pas."
L["Pet Compendium:"] = "Compendium des familiers :"
L["Beast Arrow:"] = "Flèche des bêtes :"
L["Points the way to a beast. Shift-click one in the compendium to aim it."] =
    "Montre le chemin vers une bête. Fais Maj-clic sur une bête du compendium pour la viser."
L["Check the Arrow:"] = "Vérifier la flèche :"
L["Lists in chat what the arrow can read here."] = "Liste dans la discussion ce que la flèche peut lire ici."
L["Stop Following:"] = "Arrêter de suivre :"
L["Use TomTom:"] = "Utiliser TomTom :"
L["With TomTom installed, its arrow shows the way instead."] = "Si TomTom est installé, c'est sa flèche qui montre le chemin."
L["Pets:"] = "Pets :"
L["Window Position:"] = "Position des fenêtres :"
L["Reset the UI windows to their defaults."] = "Remet les fenêtres à leur place de départ."
L["Set Default"] = "Par défaut"
L["UI windows set to defaults."] = "Fenêtres remises à leur place de départ."
L["Text Size:"] = "Taille du texte :"
L["Window Style:"] = "Style des fenêtres :"
L["Debug:"] = "Débogage :"
L["Extra chat messages to help track down a problem."] = "Plus de messages dans la discussion pour aider à trouver un problème."
L["Sister Addons:"] = "Addons associés :"
L["Says once in chat which Blackthornes addons you don't have."] = "Dit une fois dans la discussion quels addons Blackthornes tu n'as pas."
L["What's New:"] = "Nouveautés :"
L["What's New After Updates:"] = "Nouveautés après les mises à jour :"
L["Opens What's New the first time you play after an update."] = "Ouvre les nouveautés la première fois que tu joues après une mise à jour."
L["What's New Motion:"] = "Animation des nouveautés :"
L["Client Check:"] = "Vérifier le jeu :"
L["Lists in chat what the game tells Pets about your pet."] = "Liste dans la discussion ce que le jeu dit à Pets sur ton familier."
L["Window position, text size and debug output"] = "Position des fenêtres, taille du texte et messages de débogage"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "Certains d'entre vous m'ont demandé si l'IA sert à créer mes AddOns. Oui, elle sert."
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "Je développe des logiciels et je travaille dans l'informatique depuis 25 ans, et je conseille aux développeurs d'aujourd'hui de s'en servir, mais avec soin et en sachant pourquoi. Pour moi, ça veut dire que je décide de ce qui est construit, je fixe les règles que le code doit suivre, je relis le code, et je teste moi-même les changements en jeu. L'IA m'aide à écrire le code, à lancer les tests et à trouver les bugs."
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "Bien utilisée, elle apporte plus de fonctions, des bugs corrigés plus vite et des réponses plus rapides à vos demandes. Une bonne partie de ces addons a commencé par une idée ou un rapport de bug d'un joueur."
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "Si tu as une idée ou si quelque chose ne marche pas, viens me voir sur mon Discord : discord.gg/f2geDecrw2. Je lis chaque commentaire et chaque rapport."
L["%s, version %s"] = "%s, version %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "Clique dans la case, puis appuie sur Ctrl+C pour copier le lien."
L["REPORT A BUG"] = "SIGNALER UN BUG"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "Écris-le sur mon Discord, avec ce que tu faisais quand c'est arrivé. Je lis chaque commentaire et chaque rapport."
L["THANK YOU"] = "MERCI"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "Une bonne partie de ce qui est ici a commencé par l'idée ou le rapport de bug d'un joueur. Merci à tous ceux qui en ont envoyé un."
L["installed"] = "installé"
L["turned off"] = "désactivé"
L["not installed"] = "pas installé"
L["%s (%s)"] = "%s (%s)"
L["How these addons are made"] = "Comment ces addons sont faits"
L["A note from Blackthornes."] = "Un mot de Blackthornes."
L["ABOUT"] = "À PROPOS"
L["HOW THESE ADDONS ARE MADE"] = "COMMENT CES ADDONS SONT FAITS"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "Comment ces addons sont faits, la version, le Discord et les autres addons Blackthornes"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).
L["Off"] = "Aucun"
L["Shift"] = "Maj"
L["Always"] = "Toujours"
L["Hold Shift for more."] = "Maintiens Maj pour en voir plus."
L["Drag to make the window bigger or smaller."] = "Fais glisser pour agrandir ou réduire la fenêtre."
L["Right-click to go back to normal size."] = "Clic droit pour revenir à la taille normale."
L["EFFECTS"] = "EFFETS"
L["Effects:"] = "Effets :"
L["Full"] = "Complet"
L["Subtle"] = "Discret"
L["Couldn't tell what your pet eats yet."] = "Impossible de savoir encore ce que mange ton familier."
L["Couldn't read your bags. Try again in a moment."] = "Impossible de lire tes sacs. Réessaie dans un instant."
L["Name not loaded yet"] = "Nom pas encore chargé"
L["Your filters hide 1 beast."] = "Tes filtres cachent 1 bête."
L["Your filters hide %d beasts."] = "Tes filtres cachent %d bêtes."

-- The way there (Logic/Travel.lua, the same in every addon).
L["Fly to %s"] = "Vole jusqu'à %s"
L["Talk to the flight master"] = "Parle au maître de vol"
L["Wait here for the boat to %s"] = "Attends ici le bateau pour %s"
L["Get on when it stops"] = "Monte quand il s'arrête"
L["Take the boat to %s"] = "Prends le bateau pour %s"
L["Wait here for the zeppelin to %s"] = "Attends ici le zeppelin pour %s"
L["Take the zeppelin to %s"] = "Prends le zeppelin pour %s"
L["Use your Hearthstone"] = "Utilise ta pierre de foyer"
L["It takes you to %s"] = "Elle t'emmène à %s"
L["Walk to %s"] = "Marche jusqu'à %s"
L["toward %s"] = "vers %s"
L["Next: %s."] = "Ensuite : %s."
L["Your Way There"] = "Ton chemin"
L["Show on Map"] = "Voir sur la carte"
L["Stop"] = "Arrêter"
L["Done"] = "Fini"
L["Now"] = "Maintenant"
L["About 1 minute"] = "Environ 1 minute"
L["About %d minutes"] = "Environ %d minutes"
L["Guide Me:"] = "Guide-moi :"
L["Step %d of %d"] = "Étape %d sur %d"
L["The arrow leads you step by step to places far away."] = "La flèche te mène étape par étape aux endroits lointains."
L["The arrow points straight at places far away."] = "La flèche pointe tout droit vers les endroits lointains."
L["When the place is in another zone or across the sea, the arrow leads you there step by step."] = "Quand l'endroit est dans une autre zone ou de l'autre côté de la mer, la flèche t'y mène étape par étape."

-- The Skills card and the window's tabs.
L["%d point"] = "%d point"
L["%d points"] = "%d points"
L["%s Rank %d"] = "%s rang %d"
L["CAN LEARN NOW"] = "À APPRENDRE MAINTENANT"
L["COST"] = "COÛT"
L["Click to see the beasts that teach it."] = "Clique pour voir les bêtes qui l'enseignent."
L["Compendium"] = "Compendium"
L["LATER"] = "PLUS TARD"
L["Pet"] = "Familier"
L["Pet level %d"] = "Familier niveau %d"
L["Pet trainer"] = "Maître des familiers"
L["Pet trainer: %s"] = "Maître des familiers : %s"
L["RANK"] = "RANG"
L["Rank %d"] = "Rang %d"
L["SKILLS"] = "TECHNIQUES"
L["Show the Way"] = "Montrer le chemin"
L["Tame a beast that knows it"] = "Dresse une bête qui la connaît"
L["WHEN"] = "QUAND"
L["YOUR PET KNOWS"] = "TON FAMILIER CONNAÎT"
L["from a pet trainer"] = "chez un maître des familiers"
L["from your Beast Training"] = "de ton Dressage des bêtes"
