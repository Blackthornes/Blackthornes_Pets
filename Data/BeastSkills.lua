-- Blackthornes Pets -- Data/BeastSkills.lua
-- Which pet skills taming a beast teaches a hunter, by the beast's creature id.
--
-- Generated from Classic 1.12 data, not typed by hand: the vmangos world
-- database (14 June 2021), whose pet_spell_data table is the client's
-- CreatureSpellData.dbc (rows up to build 5875, patch 1.12.1) and whose
-- creature_template gives each tameable beast its list. A beast that is not
-- here teaches nothing when tamed. Growl and the resistances come from the pet
-- trainer, never from taming, so they are not here either.
--
-- SKILLS is keyed by the pet's spell; `teach` is the spell the hunter learns,
-- the one the Beast Training window lists.

local _, ns = ...

local BeastSkills = {}
ns.BeastSkills = BeastSkills

BeastSkills.SKILLS = {
    [17253] = { name = "Bite", rank = 1, teach = 17254 },
    [17255] = { name = "Bite", rank = 2, teach = 17262 },
    [17256] = { name = "Bite", rank = 3, teach = 17263 },
    [17257] = { name = "Bite", rank = 4, teach = 17264 },
    [17258] = { name = "Bite", rank = 5, teach = 17265 },
    [17259] = { name = "Bite", rank = 6, teach = 17266 },
    [17260] = { name = "Bite", rank = 7, teach = 17267 },
    [17261] = { name = "Bite", rank = 8, teach = 17268 },
    [7371] = { name = "Charge", rank = 1, teach = 7370 },
    [26177] = { name = "Charge", rank = 2, teach = 26184 },
    [26178] = { name = "Charge", rank = 3, teach = 26185 },
    [26201] = { name = "Charge", rank = 5, teach = 26202 },
    [27685] = { name = "Charge", rank = 6, teach = 28343 },
    [16827] = { name = "Claw", rank = 1, teach = 2980 },
    [16828] = { name = "Claw", rank = 2, teach = 2981 },
    [16829] = { name = "Claw", rank = 3, teach = 2982 },
    [16830] = { name = "Claw", rank = 4, teach = 3667 },
    [16831] = { name = "Claw", rank = 5, teach = 2975 },
    [16832] = { name = "Claw", rank = 6, teach = 2976 },
    [3010] = { name = "Claw", rank = 7, teach = 2977 },
    [3009] = { name = "Claw", rank = 8, teach = 3666 },
    [1742] = { name = "Cower", rank = 1, teach = 1747 },
    [1753] = { name = "Cower", rank = 2, teach = 1748 },
    [1754] = { name = "Cower", rank = 3, teach = 1749 },
    [1755] = { name = "Cower", rank = 4, teach = 1750 },
    [1756] = { name = "Cower", rank = 5, teach = 1751 },
    [16697] = { name = "Cower", rank = 6, teach = 16698 },
    [23099] = { name = "Dash", rank = 1, teach = 23100 },
    [23109] = { name = "Dash", rank = 2, teach = 23111 },
    [23110] = { name = "Dash", rank = 3, teach = 23112 },
    [23145] = { name = "Dive", rank = 1, teach = 23146 },
    [23147] = { name = "Dive", rank = 2, teach = 23149 },
    [23148] = { name = "Dive", rank = 3, teach = 23150 },
    [24604] = { name = "Furious Howl", rank = 1, teach = 24609 },
    [24605] = { name = "Furious Howl", rank = 2, teach = 24608 },
    [24603] = { name = "Furious Howl", rank = 3, teach = 24607 },
    [24597] = { name = "Furious Howl", rank = 4, teach = 24599 },
    [25008] = { name = "Lightning Breath", rank = 2, teach = 25013 },
    [25009] = { name = "Lightning Breath", rank = 3, teach = 25014 },
    [25010] = { name = "Lightning Breath", rank = 4, teach = 25015 },
    [25011] = { name = "Lightning Breath", rank = 5, teach = 25016 },
    [25012] = { name = "Lightning Breath", rank = 6, teach = 25017 },
    [24450] = { name = "Prowl", rank = 1, teach = 24451 },
    [24452] = { name = "Prowl", rank = 2, teach = 24454 },
    [24453] = { name = "Prowl", rank = 3, teach = 24455 },
    [24640] = { name = "Scorpid Poison", rank = 1, teach = 24641 },
    [24583] = { name = "Scorpid Poison", rank = 2, teach = 24584 },
    [24586] = { name = "Scorpid Poison", rank = 3, teach = 24588 },
    [24587] = { name = "Scorpid Poison", rank = 4, teach = 24589 },
    [24423] = { name = "Screech", rank = 1, teach = 24424 },
    [24577] = { name = "Screech", rank = 2, teach = 24580 },
    [24578] = { name = "Screech", rank = 3, teach = 24581 },
    [24579] = { name = "Screech", rank = 4, teach = 24582 },
    [26064] = { name = "Shell Shield", rank = 1, teach = 26065 },
    [26090] = { name = "Thunderstomp", rank = 1, teach = 26094 },
    [26187] = { name = "Thunderstomp", rank = 2, teach = 26189 },
    [26188] = { name = "Thunderstomp", rank = 3, teach = 26190 },
}

-- Creature id = { pet spells }, with the beast's name and level for reading.
BeastSkills.BEASTS = {
    [30] = { 17253 }, -- Forest Spider (5-6)
    [113] = { 7371 }, -- Stonetusk Boar (5-6)
    [118] = { 17255 }, -- Prowler (9-10)
    [119] = { 7371 }, -- Longsnout (10-11)
    [154] = { 24423 }, -- Greater Fleshripper (16-17)
    [157] = { 26177 }, -- Goretusk (14-15)
    [330] = { 7371 }, -- Princess (9)
    [345] = { 26178 }, -- Bellygrub (24)
    [390] = { 7371 }, -- Porcine Entourage (7)
    [442] = { 17255 }, -- Tarantula (15-16)
    [454] = { 26177 }, -- Young Goretusk (12-13)
    [471] = { 17255 }, -- Mother Fang (10)
    [505] = { 17256 }, -- Greater Tarantula (19-20)
    [521] = { 17256 }, -- Lupos (23)
    [524] = { 7371 }, -- Rockhide Boar (7-8)
    [547] = { 26177 }, -- Great Goretusk (16-17)
    [569] = { 17256 }, -- Green Recluse (21-22)
    [574] = { 17257 }, -- Naraxis (27)
    [616] = { 17256 }, -- Chatter (23)
    [628] = { 17257 }, -- Black Ravager (24-25)
    [681] = { 1754 }, -- Young Stranglethorn Tiger (30-31)
    [682] = { 23099 }, -- Stranglethorn Tiger (32-33)
    [683] = { 1754 }, -- Young Panther (30-31)
    [684] = { 24450 }, -- Shadowmaw Panther (37-38)
    [708] = { 7371 }, -- Small Crag Boar (3)
    [728] = { 23109 }, -- Bhag'thera (40)
    [729] = { 23099 }, -- Sin'Dall (37)
    [731] = { 23109, 16832 }, -- King Bangalash (43)
    [736] = { 1754 }, -- Panther (32-33)
    [767] = { 23099 }, -- Swamp Jaguar (36-37)
    [768] = { 24450 }, -- Shadow Panther (39-40)
    [769] = { 17259 }, -- Deathstrike Tarantula (40-41)
    [822] = { 16828 }, -- Young Forest Bear (8-9)
    [833] = { 17255, 24604 }, -- Coyote Packleader (11-12)
    [834] = { 17255 }, -- Coyote (10-11)
    [922] = { 16832 }, -- Silt Crawler (40-41)
    [976] = { 23099 }, -- Kurzen War Tiger (32-33)
    [1087] = { 17259 }, -- Sawtooth Snapper (41-42)
    [1088] = { 16832 }, -- Monstrous Crawler (43-44)
    [1108] = { 26090 }, -- Mistvale Gorilla (32-33)
    [1112] = { 17257 }, -- Leech Widow (24)
    [1114] = { 26090 }, -- Jungle Thunderer (37-38)
    [1125] = { 7371 }, -- Crag Boar (5-6)
    [1126] = { 7371 }, -- Large Crag Boar (6-7)
    [1127] = { 7371 }, -- Elder Crag Boar (7-8)
    [1129] = { 16827 }, -- Black Bear (6-7)
    [1130] = { 16828 }, -- Bjarn (12)
    [1131] = { 17253 }, -- Winter Wolf (7-8)
    [1132] = { 17255 }, -- Timber (10)
    [1133] = { 17255 }, -- Starving Winter Wolf (8-9)
    [1138] = { 17253 }, -- Snow Tracker Wolf (6-7)
    [1185] = { 17256 }, -- Wood Lurker (17-18)
    [1189] = { 16829 }, -- Black Bear Patriarch (16-17)
    [1190] = { 7371 }, -- Mountain Boar (10-11)
    [1191] = { 26177 }, -- Mangy Mountain Boar (14-15)
    [1192] = { 26177 }, -- Elder Mountain Boar (16-17)
    [1195] = { 17255 }, -- Forest Lurker (10-11)
    [1196] = { 16827 }, -- Ice Claw Bear (7-8)
    [1199] = { 1742 }, -- Juvenile Snow Leopard (5-6)
    [1216] = { 16829 }, -- Shore Crawler (17-18)
    [1225] = { 16829 }, -- Ol' Sooty (20)
    [1258] = { 17257, 24605 }, -- Black Ravager Mastiff (25-26)
    [1505] = { 17253 }, -- Night Web Spider (3-4)
    [1509] = { 17253 }, -- Ragged Scavenger (2-3)
    [1553] = { 1742 }, -- Greater Duskbat (6-7)
    [1555] = { 17255 }, -- Vicious Night Web Spider (9-10)
    [1557] = { 26187 }, -- Elder Mistvale Gorilla (40-41)
    [1688] = { 17253 }, -- Night Web Matriarch (5)
    [1689] = { 7371 }, -- Scarred Crag Boar (9-10)
    [1693] = { 17255 }, -- Loch Crocolisk (14-15)
    [1713] = { 23109, 24452 }, -- Elder Shadowmaw Panther (42-43)
    [1765] = { 17255, 24604 }, -- Worg (10-11)
    [1778] = { 16828 }, -- Ferocious Grizzled Bear (11-12)
    [1809] = { 23148, 24578 }, -- Carrion Vulture (50-52)
    [1816] = { 3010 }, -- Diseased Grizzly (55-56)
    [1817] = { 17260 }, -- Diseased Wolf (53-54)
    [1824] = { 17260 }, -- Plague Lurker (54-55)
    [1922] = { 17253 }, -- Gray Forest Wolf (7-8)
    [1923] = { 17256 }, -- Bloodsnout Worg (16-17)
    [1961] = { 16828 }, -- Mangeclaw (11)
    [1984] = { 7371 }, -- Young Thistle Boar (1-2)
    [1985] = { 7371 }, -- Thistle Boar (2-3)
    [1994] = { 17253 }, -- Githyiss the Vile (5)
    [1995] = { 16827 }, -- Strigid Owl (5-6)
    [1997] = { 16828 }, -- Strigid Hunter (8-9)
    [1999] = { 17253 }, -- Webwood Venomfang (7-8)
    [2000] = { 17255 }, -- Webwood Silkspinner (8-9)
    [2001] = { 17255 }, -- Giant Webwood Spider (10-11)
    [2042] = { 1742 }, -- Nightsaber (5-6)
    [2070] = { 1742 }, -- Moonstalker Runt (10-17)
    [2089] = { 17257 }, -- Giant Wetlands Crocolisk (25-26)
    [2163] = { 16828 }, -- Thistle Bear (11-12)
    [2232] = { 16828 }, -- Tide Crawler (12-14)
    [2237] = { 1753 }, -- Moonstalker Sire (17-18)
    [2321] = { 1742 }, -- Foreststrider Fledgling (11-13)
    [2323] = { 1753 }, -- Giant Foreststrider (17-19)
    [2348] = { 17257 }, -- Elder Moss Creeper (26-27)
    [2349] = { 17257 }, -- Giant Moss Creeper (24-25)
    [2350] = { 17256 }, -- Forest Moss Creeper (20-21)
    [2351] = { 16829 }, -- Gray Bear (21-22)
    [2384] = { 1753 }, -- Starving Mountain Lion (23-24)
    [2385] = { 1754 }, -- Feral Mountain Lion (27-28)
    [2406] = { 24450 }, -- Mountain Lion (32-33)
    [2408] = { 17257, 26064 }, -- Snapjaw (30-31)
    [2476] = { 17256 }, -- Large Loch Crocolisk (22)
    [2505] = { 17260 }, -- Saltwater Snapjaw (49-50)
    [2522] = { 1756, 24453 }, -- Jaguero Stalker (50)
    [2563] = { 17258 }, -- Plains Creeper (32-33)
    [2565] = { 17258 }, -- Giant Plains Creeper (35-36)
    [2578] = { 23145 }, -- Young Mesa Buzzard (31-32)
    [2579] = { 23145 }, -- Mesa Buzzard (34-35)
    [2681] = { 17260, 23110 }, -- Vilebranch Raiding Wolf (50-51)
    [2686] = { 17259 }, -- Witherbark Broodguard (44-45)
    [2727] = { 17258, 23099 }, -- Crag Coyote (35-36)
    [2728] = { 23099 }, -- Feral Crag Coyote (37-38)
    [2729] = { 23099, 24605 }, -- Elder Crag Coyote (39-40)
    [2730] = { 23109 }, -- Rabid Crag Coyote (42-43)
    [2731] = { 1755, 24450 }, -- Ridge Stalker (36-37)
    [2732] = { 1755 }, -- Ridge Huntress (38-39)
    [2734] = { 23109, 24452 }, -- Ridge Stalker Patriarch (40-41)
    [2753] = { 17259 }, -- Barnabus (38)
    [2850] = { 23099 }, -- Broken Tooth (37)
    [2924] = { 24603 }, -- Silvermane Wolf (43-44)
    [2925] = { 24605 }, -- Silvermane Howler (45-46)
    [2926] = { 23109 }, -- Silvermane Stalker (47-48)
    [2931] = { 23148 }, -- Zaricotl (55)
    [2954] = { 7371 }, -- Bristleback Battleboar (4-5)
    [2957] = { 1742 }, -- Elder Plainstrider (8-9)
    [2958] = { 17253 }, -- Prairie Wolf (5-6)
    [2959] = { 17253 }, -- Prairie Stalker (7-8)
    [2960] = { 17255, 24604 }, -- Prairie Wolf Alpha (9-10)
    [2966] = { 7371 }, -- Battleboar (3-4)
    [3035] = { 1742 }, -- Flatland Cougar (7-8)
    [3068] = { 1742 }, -- Mazzranache (9)
    [3098] = { 7371 }, -- Mottled Boar (1-2)
    [3099] = { 7371 }, -- Dire Mottled Boar (6-7)
    [3100] = { 7371 }, -- Elder Mottled Boar (8-9)
    [3106] = { 16827 }, -- Pygmy Surf Crawler (5-6)
    [3108] = { 16828 }, -- Encrusted Surf Crawler (9-10)
    [3110] = { 17253 }, -- Dreadmaw Crocolisk (9-11)
    [3121] = { 1742 }, -- Durotar Tiger (7-8)
    [3124] = { 16827 }, -- Scorpid Worker (3)
    [3127] = { 16828, 24640 }, -- Venomtail Scorpid (9-10)
    [3225] = { 7371 }, -- Corrupted Mottled Boar (10-11)
    [3226] = { 24640 }, -- Corrupted Scorpid (10-11)
    [3241] = { 1753 }, -- Savannah Patriarch (15-16)
    [3245] = { 1753 }, -- Ornery Plainstrider (16-17)
    [3246] = { 1742 }, -- Fleeting Plainstrider (12-13)
    [3247] = { 25008 }, -- Thunderhawk Hatchling (18-20)
    [3249] = { 25008 }, -- Greater Thunderhawk (23-24)
    [3250] = { 24640 }, -- Silithid Creeper (20-21)
    [3252] = { 24640 }, -- Silithid Swarmer (21-22)
    [3281] = { 16827 }, -- Sarkoth (4)
    [3424] = { 25008 }, -- Thunderhawk Cloudscraper (20-22)
    [3461] = { 17255 }, -- Oasis Snapjaw (15-16)
    [3472] = { 25009 }, -- Washte Pawne (25)
    [3581] = { 17260 }, -- Sewer Beast (50)
    [3619] = { 16829 }, -- Ghost Saber (19-20)
    [3630] = { 25008 }, -- Deviate Coiler (15-16)
    [3631] = { 25008 }, -- Deviate Stinglash (16-17)
    [3653] = { 17256, 26064 }, -- Kresh (20)
    [3809] = { 16829 }, -- Ashenvale Bear (21-22)
    [3810] = { 16830 }, -- Elder Ashenvale Bear (25-26)
    [3812] = { 16829 }, -- Clattering Crawler (19-20)
    [3821] = { 17257 }, -- Wildthorn Lurker (28-29)
    [3823] = { 17256 }, -- Ghostpaw Runner (19-20)
    [3825] = { 17257, 24605 }, -- Ghostpaw Alpha (27-28)
    [4005] = { 17256 }, -- Deepmoss Creeper (16-17)
    [4006] = { 17256 }, -- Deepmoss Webspinner (19-20)
    [4067] = { 1753 }, -- Twilight Runner (23-24)
    [4117] = { 25009 }, -- Cloud Serpent (25-26)
    [4118] = { 25009 }, -- Venomous Cloud Serpent (26-28)
    [4119] = { 25009 }, -- Elder Cloud Serpent (27-29)
    [4126] = { 1754 }, -- Crag Stalker (25-26)
    [4139] = { 24583 }, -- Scorpid Terror (33-34)
    [4140] = { 16830, 24583 }, -- Scorpid Reaver (31-32)
    [4143] = { 17258 }, -- Sparkleshell Snapper (34-35)
    [4158] = { 24577 }, -- Salt Flats Vulture (32-34)
    [4304] = { 23099 }, -- Scarlet Tracking Hound (33-34)
    [4341] = { 17258 }, -- Drywallow Crocolisk (35-36)
    [4343] = { 16831 }, -- Drywallow Snapper (37-38)
    [4344] = { 17258 }, -- Mottled Drywallow Crocolisk (38-39)
    [4345] = { 17259 }, -- Drywallow Daggermaw (40-41)
    [4346] = { 23145 }, -- Noxious Flayer (35-36)
    [4347] = { 23145, 25010 }, -- Noxious Reaver (37-38)
    [4348] = { 23145, 25010 }, -- Noxious Shredder (38-39)
    [4396] = { 17258 }, -- Mudrock Tortoise (36-37)
    [4400] = { 17259 }, -- Mudrock Snapjaw (41-42)
    [4411] = { 17258 }, -- Darkfang Lurker (36-37)
    [4412] = { 17258 }, -- Darkfang Creeper (38-39)
    [4413] = { 17258 }, -- Darkfang Spider (35-36)
    [4425] = { 1754, 23145 }, -- Blind Hunter (32)
    [4511] = { 26178 }, -- Agam'ar (24-25)
    [4512] = { 26178 }, -- Rotting Agam'ar (28)
    [4514] = { 26178 }, -- Raging Agam'ar (25-26)
    [4538] = { 1754, 23145 }, -- Kraul Bat (30-31)
    [4539] = { 23145 }, -- Greater Kraul Bat (32)
    [4662] = { 23099 }, -- Magram Bonepaw (37-38)
    [4688] = { 23099 }, -- Bonepaw Hyena (33-35)
    [4693] = { 23145 }, -- Dread Flyer (36-37)
    [4694] = { 24577 }, -- Dread Ripper (39-40)
    [4696] = { 16830, 24583 }, -- Scorpashi Snapper (30-31)
    [4697] = { 16831, 24583 }, -- Scorpashi Lasher (34-35)
    [4699] = { 24583 }, -- Scorpashi Venomlash (38-39)
    [4821] = { 16829 }, -- Skittering Crustacean (22-23)
    [4822] = { 16829 }, -- Snapping Crustacean (23-24)
    [4823] = { 16830 }, -- Barbed Crustacean (25-26)
    [4824] = { 17256, 26064 }, -- Aku'mai Fisher (23-24)
    [4825] = { 17257, 26064 }, -- Aku'mai Snapjaw (26-27)
    [4841] = { 17259 }, -- Deadmire (45)
    [4861] = { 1755, 23145, 24577 }, -- Shrike Bat (38-39)
    [4887] = { 17257, 26064 }, -- Ghamoo-ra (25)
    [4950] = { 23099 }, -- Spot (35)
    [5053] = { 17256 }, -- Deviate Crocolisk (18-19)
    [5056] = { 25008 }, -- Deviate Dreadfang (20-21)
    [5262] = { 26187 }, -- Groddoc Thunderer (49-50)
    [5268] = { 16832 }, -- Ironfur Bear (41-42)
    [5274] = { 3010 }, -- Ironfur Patriarch (48-49)
    [5286] = { 17259, 23109, 24603 }, -- Longtooth Runner (40-41)
    [5287] = { 24605 }, -- Longtooth Howler (43-44)
    [5291] = { 25011 }, -- Hakkari Frostwing (49-50)
    [5307] = { 23147, 25010 }, -- Vale Screecher (41-43)
    [5308] = { 23147, 25010 }, -- Rogue Vale Screecher (44-46)
    [5349] = { 23147, 25011 }, -- Arash-ethis (49)
    [5352] = { 16832 }, -- Old Grizzlegut (43)
    [5356] = { 17259, 24603 }, -- Snarler (42)
    [5422] = { 16832, 24586 }, -- Scorpid Hunter (40-41)
    [5423] = { 24586 }, -- Scorpid Tail Lasher (43-44)
    [5424] = { 24586 }, -- Scorpid Dunestalker (46-47)
    [5425] = { 23109 }, -- Starving Blisterpaw (41-42)
    [5426] = { 23109 }, -- Blisterpaw Hyena (44-45)
    [5427] = { 23109 }, -- Rabid Blisterpaw (47-48)
    [5428] = { 23147 }, -- Roc (41-43)
    [5429] = { 23147 }, -- Fire Roc (43-45)
    [5430] = { 23147 }, -- Searing Roc (47-49)
    [5432] = { 17260, 26064 }, -- Giant Surf Glider (48-50)
    [5708] = { 23148, 25011 }, -- Spawn of Hakkar (51)
    [5756] = { 25008 }, -- Deviate Venomwing (20-21)
    [5766] = { 1742 }, -- Savannah Cub (4-5)
    [5823] = { 16828, 24640 }, -- Death Flayer (11)
    [5937] = { 16831, 24583 }, -- Vile Sting (35)
    [5988] = { 24586 }, -- Scorpok Stinger (50-51)
    [5992] = { 26201 }, -- Ashmane Boar (48-49)
    [6013] = { 23145 }, -- Wayward Buzzard (35-37)
    [6250] = { 16828 }, -- Crawler (11-12)
    [6516] = { 26188 }, -- Un'Goro Thunderer (52-53)
    [6585] = { 17260 }, -- Uhk'loc (52-53)
    [6788] = { 16829 }, -- Den Mother (18-19)
    [7022] = { 16831 }, -- Venomlash Scorpid (39-40)
    [7055] = { 23110 }, -- Blackrock Worg (54-55)
    [7078] = { 24583 }, -- Cleft Scorpid (35-36)
    [7097] = { 23147, 24578 }, -- Ironbeak Owl (48-49)
    [7098] = { 23148 }, -- Ironbeak Screecher (52-53)
    [7099] = { 3010, 23148 }, -- Ironbeak Hunter (50-51)
    [7319] = { 17255 }, -- Lady Sathrah (12)
    [7405] = { 24586 }, -- Deadly Cleft Scorpid (42-43)
    [7430] = { 16697 }, -- Frostsaber Cub (55-56)
    [7432] = { 23110, 24453 }, -- Frostsaber Stalker (59-60)
    [7433] = { 23110 }, -- Frostsaber Huntress (58-59)
    [7444] = { 3010 }, -- Shardtooth Bear (53-54)
    [7445] = { 3009 }, -- Elder Shardtooth (57-58)
    [7455] = { 3010, 23148 }, -- Winterspring Owl (54-56)
    [7456] = { 3009, 23148, 24579 }, -- Winterspring Screecher (57-59)
    [7803] = { 24586 }, -- Scorpid Duneburrower (46-47)
    [8207] = { 23147 }, -- Greater Firebird (46)
    [8208] = { 23109 }, -- Murderous Blisterpaw (44)
    [8211] = { 17259, 23109 }, -- Old Cliff Jumper (42)
    [8213] = { 17260, 26064 }, -- Ironback (51)
    [8277] = { 17260 }, -- Rekk'tilac (48)
    [8299] = { 23148 }, -- Spiteflayer (52)
    [8300] = { 23110 }, -- Ravage (51)
    [8301] = { 3010, 24586 }, -- Clack the Reaver (53)
    [8303] = { 23110, 26201 }, -- Grunter (50)
    [8336] = { 25011 }, -- Hakkari Sapper (49-50)
    [8600] = { 1756, 23148 }, -- Plaguebat (53-55)
    [8601] = { 1756 }, -- Noxious Plaguebat (54-56)
    [8602] = { 16697, 24579 }, -- Monstrous Plaguebat (56-58)
    [8762] = { 17259 }, -- Timberweb Recluse (47-48)
    [8926] = { 3010, 24586 }, -- Deep Stinger (50-52)
    [8927] = { 1756, 23148, 24578 }, -- Dark Screecher (50-52)
    [8933] = { 17260 }, -- Cave Creeper (50-52)
    [8958] = { 3010 }, -- Angerclaw Mauler (49-50)
    [8959] = { 17259, 24603 }, -- Felpaw Wolf (47-48)
    [8961] = { 17260 }, -- Felpaw Ravager (51-52)
    [9416] = { 23110 }, -- Scarshield Worg (53-54)
    [9622] = { 26188 }, -- U'cha (55)
    [9691] = { 24586 }, -- Venomtip Scorpid (52-53)
    [9695] = { 3010, 24586 }, -- Deathlash Scorpid (54-55)
    [9696] = { 17261, 23110, 24597 }, -- Bloodaxe Worg (56-57)
    [9698] = { 24587 }, -- Firetail Scorpid (56-57)
    [10200] = { 23110 }, -- Rak'shiri (57)
    [10644] = { 24604 }, -- Mist Howler (22)
    [11357] = { 25012 }, -- Son of Hakkar (60)
    [11365] = { 23110 }, -- Zulian Panther (60)
    [11370] = { 23148 }, -- Razzashi Broodwidow (61)
    [11735] = { 24586 }, -- Stonelash Scorpid (54-55)
    [11736] = { 24587 }, -- Stonelash Pincer (56)
    [11737] = { 24587 }, -- Stonelash Flayer (57-58)
    [11921] = { 17256 }, -- Besseleth (21)
    [13599] = { 17255 }, -- Stolid Snapjaw (46-47)
    [14223] = { 17257, 26064 }, -- Cranky Benj (32)
    [14233] = { 17259 }, -- Ripscale (39)
    [14266] = { 17256 }, -- Shanda the Spinner (25)
    [14279] = { 17256 }, -- Creepthess (24)
    [14339] = { 17259, 24603 }, -- Death Howl (49)
    [14343] = { 3010, 23148 }, -- Olm the Wise (52)
    [14344] = { 3010 }, -- Mongress (50)
    [14476] = { 24587 }, -- Krellack (56)
    [15067] = { 23110, 24453 }, -- Zulian Stalker (61)
    [15101] = { 23110, 24453 }, -- Zulian Prowler (60)
    [16117] = { 27685 }, -- Plagued Swine (60)
}
