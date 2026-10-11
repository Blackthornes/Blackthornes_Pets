"""Writes Data/ForeverBeasts.lua: what WoW: Forever has shown about tameable
beasts that Classic's data (Data/Compendium.lua) does not say.

Run from the repository root:

    python tools/forever_beasts.py [--harvest <Data_Harvested.lua>] [saved file ...]

Three kinds of finding go in, and in game the Pet Compendium lays them over
the Classic data, because what the Forever client showed beats what 1.12
said:

  SEEN   Tameable beasts killed on Forever, with the zone, spot and levels the
         game showed. Read from Blackthornes Farmer's Data/Data_Harvested.lua
         (`--harvest`), which holds mob names, zones and coordinates only.
         A name is kept only when Data/Compendium.lua has a beast of that
         name, so nothing that is not tameable creeps in.
  TAMED  Beasts tamed on Forever, by creature id: name, level, family, where,
         its attack speed and the skills the new pet came with. Read from
         Pets' own account save, Blackthornes_Pets.lua in the game's
         WTF/Account/<account>/SavedVariables folder; only its `tamedBeasts`
         table is read, so nothing about the player or their characters is
         copied. Tames already in the file are kept; a reading with more
         skills replaces one with fewer.
  FOUND  New beasts, and new skills on old ones, that a published Forever
         source names. Typed below, one source each. Add a beast here only
         with a source that names it; never fill a gap by guessing.

Options:
    --stdout   print the file instead of writing it
"""

import collections
import os
import sys

from lupa import lua51

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT = os.path.join(ROOT, "Data", "ForeverBeasts.lua")

MMONSTER = "https://mmonster.co/wow-forever/guides/hunter-pets/"
WFP = "https://wowforeverpets.com/"

# Read 2026-10-07. The sources say this is beta data (client 1.60.1). Ids are
# the Forever NPC ids those pages give (checked against Wowhead's /forever/
# pages for Vuldren, Vuldren Alpha, Slydris and Coldrasp). A field a source
# does not give is left out.
FOUND = [
    # Zephras Isle, the Skyborne starting area.
    dict(id=250873, name="Juvenile Vuldren", family="Fox", min=1, max=1, zone="Zephras Isle",
         skills=[("Bite", 1)], source=MMONSTER + "fox"),
    dict(id=250868, name="Vuldren", family="Fox", min=6, max=6, zone="Zephras Isle",
         skills=[("Bite", 1)], source=MMONSTER + "fox"),
    dict(id=250874, name="Vuldren Alpha", family="Fox", min=10, max=10, zone="Zephras Isle",
         skills=[("Trickster's Dance", 1)], source=MMONSTER + "fox"),
    dict(id=255887, name="Slydris", family="Fox", rank="rareelite", zone="Zephras Isle",
         source="https://www.wowhead.com/forever/npc=255887"),
    dict(id=254589, name="Vulgara the Insatiable", family="Wolf", min=8, max=8, rank="elite",
         zone="Zephras Isle", x=42.6, y=52.2, skills=[("Bite", 2)],
         source=WFP + "rares"),
    dict(id=250926, name="Scrawny Ursera", family="Bear", min=3, max=4, zone="Zephras Isle",
         x=39, y=27, skills=[("Claw", 1)], source=MMONSTER + "bear"),
    dict(id=250937, name="Ursera Scavenger", family="Bear", min=4, max=4, zone="Zephras Isle",
         x=37, y=26, skills=[("Claw", 1)], source=MMONSTER + "bear"),
    dict(id=251115, name="Urs'anah", family="Bear", min=5, max=5, zone="Zephras Isle",
         x=35.5, y=25.7, skills=[("Claw", 1)], source=MMONSTER + "bear"),
    dict(id=250928, name="Highlands Ursera", family="Bear", min=7, max=8, zone="Zephras Isle",
         source=MMONSTER + "bear"),
    dict(id=250927, name="Shadowgale Ursera", family="Bear", min=10, max=11, zone="Zephras Isle",
         skills=[("Claw", 3)], source=MMONSTER + "bear"),
    dict(id=251245, name="Prideclaw", family="Cat", min=5, max=6, zone="Zephras Isle",
         skills=[("Cower", 1)], source=MMONSTER + "cat"),
    dict(id=251661, name="Galestrider", family="Tallstrider", min=5, max=6, zone="Zephras Isle",
         skills=[("Dust Cloud", 1)], source=MMONSTER + "tallstrider"),
    dict(id=251707, name="Ornery Galestrider", family="Tallstrider", min=8, max=9,
         zone="Zephras Isle", skills=[("Dust Cloud", 1)], source=MMONSTER + "tallstrider"),
    dict(id=256492, name="Fernfeather", family="Tallstrider", min=10, max=10, rank="rare",
         zone="Zephras Isle", x=52, y=82, source=MMONSTER + "tallstrider"),
    dict(id=254588, name="Windsong Crawler", family="Crab", min=8, max=9, zone="Zephras Isle",
         skills=[("Claw", 2)], source=MMONSTER + "crab"),
    dict(id=253282, name="Shriekling Fledgling", family="Raptor", min=8, max=9,
         zone="Zephras Isle", x=51, y=66, skills=[("Cower", 1)], source=MMONSTER + "raptor"),
    dict(id=253283, name="Shriekling Matriarch", family="Raptor", min=9, max=9,
         zone="Zephras Isle", x=52.4, y=66, skills=[("Savage Rend", 1)],
         source=MMONSTER + "raptor"),
    dict(id=259388, name="Mystmane", min=13, max=13, rank="rare", zone="Zephras Isle",
         x=57.6, y=37, skills=[("Savage Rend", 1)], source=WFP + "rares"),
    dict(id=256108, name="Shadowgale Shrieker", family="Bird of Prey", min=10, max=10,
         zone="Zephras Isle", x=57.5, y=39.5, source=MMONSTER + "bird-of-prey"),
    # Its sources disagree on the skill (Savage Rend or Mine!), so none is given.
    dict(id=256092, name="Shadowgale Shriekling", family="Bird of Prey", min=10, max=11,
         zone="Zephras Isle", source=MMONSTER + "bird-of-prey"),

    # Marked new in Forever elsewhere.
    dict(id=276111, name="Ghostfang", family="Cat", min=10, max=10, rank="rare",
         zone="Dun Morogh", source=MMONSTER + "cat"),
    dict(id=276101, name="Nightscreech", family="Bird of Prey", min=10, max=10, rank="rare",
         zone="Teldrassil", x=38.4, y=28.1, source=WFP + "rares"),
    dict(id=266851, name="Ukorsbane", family="Spider", min=8, max=8, rank="elite",
         zone="Durotar", source=MMONSTER + "spider"),
    dict(id=274300, name="Coldrasp", family="Wolf", min=12, max=12, rank="rare",
         zone="Tirisfal Glades", x=19.7, y=65.6, respawn=(9000, 32400),
         skills=[("Furious Howl", 1)], source=WFP + "pets/coldrasp"),

    # Forever's own creature ids, listed on the family pages.
    dict(id=269075, name="Snow Leopard Prowler", family="Cat", min=6, max=6, zone="Dun Morogh",
         source=MMONSTER + "cat"),
    dict(id=260157, name="Elder Snow Leopard", family="Cat", min=9, max=10, zone="Dun Morogh",
         source=MMONSTER + "cat"),
    dict(id=276198, name="Shal'ma", family="Cat", min=9, max=9, rank="rare", zone="Durotar",
         source=MMONSTER + "cat"),
    dict(id=205382, name="Mokwa", family="Cat", min=7, max=7, rank="rare", zone="Mulgore",
         source=MMONSTER + "cat"),
    dict(id=208124, name="Raluk", family="Cat", min=7, max=7, rank="rare", zone="Durotar",
         source=MMONSTER + "cat"),
    dict(id=268530, name="Bloodtalon Matriarch", family="Raptor", min=9, max=9, zone="Durotar",
         source=MMONSTER + "raptor"),
    dict(id=262523, name="Galestrider", family="Tallstrider", min=10, max=10, zone="Mulgore",
         source=MMONSTER + "tallstrider"),
    dict(id=263348, name="Roving Tallstrider", family="Tallstrider", min=37, max=38,
         zone="Riverglades", source=MMONSTER + "tallstrider"),
    dict(id=270298, name="Child of Jai'vhanel", family="Bird of Prey", min=10, max=12,
         zone="Darkshore", source=MMONSTER + "bird-of-prey"),
    dict(id=270196, name="Jai'vhanel", family="Bird of Prey", min=12, max=12, zone="Darkshore",
         source=MMONSTER + "bird-of-prey"),
    dict(id=211965, name="Carrodin", family="Bird of Prey", min=25, max=25, rank="rare",
         zone="Wetlands", source=MMONSTER + "bird-of-prey"),
    dict(id=266850, name="Ridgeshade Creeper", family="Spider", min=5, max=6, zone="Durotar",
         source=MMONSTER + "spider"),
    dict(id=266849, name="Ridgeshade Lurker", family="Spider", min=5, max=6, zone="Durotar",
         source=MMONSTER + "spider"),
    dict(id=272096, name="Befouled Webwood", family="Spider", min=10, max=11, zone="Teldrassil",
         source=MMONSTER + "spider"),
    dict(id=271898, name="Greater Tarantula", family="Spider", min=18, max=19,
         zone="Redridge Mountains", source=MMONSTER + "spider"),
    dict(id=221169, name="Black Widow Broodmother", family="Spider", min=26, max=26,
         zone="Duskwood", source=MMONSTER + "spider"),
    dict(id=260803, name="Highland Spider", family="Spider", min=27, max=28, zone="Wetlands",
         source=MMONSTER + "spider"),
    dict(id=221258, name="Dreamthorn Stalker", family="Spider", min=41, max=41, zone="Ashenvale",
         source=MMONSTER + "spider"),
    dict(id=210107, name="Kackle", family="Crocolisk", min=15, max=16, rank="rare",
         zone="Loch Modan", source=MMONSTER + "crocolisk"),
    dict(id=270693, name="Daggerfang", family="Crocolisk", min=15, max=15, zone="Loch Modan",
         source=MMONSTER + "crocolisk"),
    dict(id=259046, name="Freshwater Crocolisk", family="Crocolisk", min=38, max=39,
         zone="Riverglades", source=MMONSTER + "crocolisk"),
    dict(id=208638, name="Fyodi", family="Boar", min=7, max=7, rank="elite", zone="Dun Morogh",
         source=MMONSTER + "boar"),
    dict(id=258331, name="Young Paletusk", family="Boar", min=36, max=39, zone="Riverglades",
         source=MMONSTER + "boar"),
    dict(id=255851, name="Mature Paletusk", family="Boar", min=36, max=39, zone="Riverglades",
         source=MMONSTER + "boar"),
    dict(id=213795, name="Gharrik", family="Carrion Bird", min=40, max=40, zone="Badlands",
         source=MMONSTER + "carrion-bird"),
    dict(id=222243, name="Zopilote", family="Carrion Bird", min=43, max=43, rank="rareelite",
         zone="Tanaris", source=MMONSTER + "carrion-bird"),
    dict(id=222699, name="Enraged Stormcrow", family="Carrion Bird", min=45, max=45,
         zone="Searing Gorge", source=MMONSTER + "carrion-bird"),
    dict(id=259269, name="High Plains Buzzard", family="Carrion Bird", min=37, max=39,
         zone="Riverglades", source=MMONSTER + "carrion-bird"),
    dict(id=263343, name="Low Plains Buzzard", family="Carrion Bird", min=37, max=39,
         zone="Riverglades", source=MMONSTER + "carrion-bird"),
    dict(id=255901, name="Sand Crawler", family="Crab", min=37, max=37, zone="Riverglades",
         source=MMONSTER + "crab"),
    dict(id=260235, name="Trapclaw", family="Crab", min=42, max=42, zone="Riverglades",
         source=MMONSTER + "crab"),
    dict(id=211951, name="Koartul", family="Turtle", min=25, max=25, rank="rareelite",
         zone="Hillsbrad Foothills", source=MMONSTER + "turtle"),
    dict(id=260809, name="Highland Tortoise", family="Turtle", min=26, max=26, zone="Wetlands",
         source=MMONSTER + "turtle"),
    dict(id=221328, name="Dreamwater Vicejaw", family="Turtle", min=51, max=51,
         zone="The Hinterlands", source=MMONSTER + "turtle"),
    dict(id=262037, name="Roosting Duskbat", family="Bat", min=37, max=38, zone="Riverglades",
         source=MMONSTER + "bat"),

    # Classic beasts that teach one of Forever's new skills.
    dict(id=1797, name="Giant Grizzled Bear", skills=[("Swipe", 1)],
         source=MMONSTER + "abilities"),
    dict(id=1780, name="Moss Stalker", skills=[("Web", 1)], source=MMONSTER + "abilities"),
]

RANKS = {"rare", "rareelite", "elite"}


def lua_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def num(x):
    x = round(float(x), 1)
    return str(int(x)) if x == int(x) else str(x)


def new_lua():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    return lua


def run_file(lua, path, ns_expr="ns"):
    chunk = lua.eval("function(path) return assert(loadfile(path)) end")(path)
    chunk("Blackthornes_Pets", lua.eval(ns_expr))


def compendium_names(lua):
    lua.execute("ns = {}")
    run_file(lua, os.path.join(ROOT, "Data", "Compendium.lua"))
    beasts = lua.eval("ns.CompendiumData.BEASTS")
    return {beasts[k].name for k in beasts}


def harvest(lua, path, names):
    """name -> { zone, x, y, min, max } from Farmer's harvest."""
    lua.execute("""
        seen = {}
        ns = { DB = { RegisterItem = function(_, item)
            for _, s in ipairs(item.sources or {}) do
                if s.provenance == "forever" and s.name and s.zone then
                    seen[#seen + 1] = s
                end
            end
        end } }
    """)
    run_file(lua, path)
    rows = collections.defaultdict(list)
    for i in lua.eval("seen"):
        s = lua.eval("seen")[i]
        if s.name in names:
            rows[s.name].append(s)
    out = {}
    for name, found in rows.items():
        zones = collections.Counter(s.zone for s in found)
        zone = zones.most_common(1)[0][0]
        here = [s for s in found if s.zone == zone]
        spot = next((s for s in here if s.coords), None)
        levels = [s.minLevel for s in found if s.minLevel] + [s.maxLevel for s in found if s.maxLevel]
        row = {"zone": zone}
        if spot:
            row["x"], row["y"] = float(spot.coords[1]), float(spot.coords[2])
        if levels:
            row["min"], row["max"] = min(levels), max(levels)
        out[name] = row
    return out


def tamed_from(lua, path):
    """creature id -> record, from a Blackthornes_Pets.lua account save."""
    lua.execute("BlackthornesPetsDB = nil")
    lua.execute(open(path, encoding="utf-8").read())
    store = lua.eval("BlackthornesPetsDB and BlackthornesPetsDB.tamedBeasts")
    out = {}
    if store is None:
        return out
    for npc_id in store:
        r = store[npc_id]
        skills = []
        for i in (r.skills or {}):
            s = r.skills[i]
            if s.name:
                skills.append((s.name, int(s.rank or 1)))
        rec = {"name": r.name, "level": r.level, "family": r.family,
               "zone": r.zone, "x": r.x, "y": r.y, "speed": r.speed, "skills": skills}
        out[int(npc_id)] = {k: v for k, v in rec.items() if v is not None}
    return out


def shipped_tamed(lua):
    if not os.path.exists(OUTPUT):
        return {}
    lua.execute("ns = {}")
    run_file(lua, OUTPUT)
    store = lua.eval("ns.ForeverBeasts and ns.ForeverBeasts.TAMED")
    out = {}
    for npc_id in (store or {}):
        r = store[npc_id]
        skills = [(r.skills[i].name, int(r.skills[i].rank)) for i in (r.skills or {})]
        rec = {"name": r.name, "level": r.level, "family": r.family,
               "zone": r.zone, "x": r.x, "y": r.y, "speed": r.speed, "skills": skills}
        out[int(npc_id)] = {k: v for k, v in rec.items() if v is not None}
    return out


def shipped_seen(lua):
    if not os.path.exists(OUTPUT):
        return {}
    lua.execute("ns = {}")
    run_file(lua, OUTPUT)
    store = lua.eval("ns.ForeverBeasts and ns.ForeverBeasts.SEEN")
    out = {}
    for name in (store or {}):
        r = store[name]
        row = {k: r[k] for k in ("zone", "x", "y", "min", "max") if r[k] is not None}
        out[name] = row
    return out


def skills_lua(skills):
    return "{ " + ", ".join(f"{{ name = {lua_string(n)}, rank = {r} }}" for n, r in skills) + " }"


def render(seen, tamed):
    out = []
    w = out.append
    w("-- Blackthornes Pets -- Data/ForeverBeasts.lua")
    w("-- What WoW: Forever has shown about tameable beasts, laid over the Classic")
    w("-- data (Data/Compendium.lua) by the Pet Compendium, because what the Forever")
    w("-- client showed beats what 1.12 said.")
    w("--")
    w("-- Generated by tools/forever_beasts.py; never edit it by hand. SEEN is where")
    w("-- beasts were killed on Forever (Farmer's harvest, by name), TAMED what")
    w("-- beasts tamed on Forever came with (Pets' own tame record, by creature id),")
    w("-- and FOUND the new beasts and skills published Forever sources name, each")
    w("-- with its source.")
    w("")
    w("local _, ns = ...")
    w("")
    w("local ForeverBeasts = {}")
    w("ns.ForeverBeasts = ForeverBeasts")
    w("")
    w("ForeverBeasts.SEEN = {")
    for name in sorted(seen):
        r = seen[name]
        parts = [f"zone = {lua_string(r['zone'])}"]
        if "x" in r:
            parts.append(f"x = {num(r['x'])}, y = {num(r['y'])}")
        if "min" in r:
            parts.append(f"min = {int(r['min'])}, max = {int(r['max'])}")
        w(f"    [{lua_string(name)}] = {{ " + ", ".join(parts) + " },")
    w("}")
    w("")
    w("ForeverBeasts.TAMED = {")
    for npc_id in sorted(tamed):
        r = tamed[npc_id]
        parts = []
        if r.get("name"):
            parts.append(f"name = {lua_string(r['name'])}")
        if r.get("level"):
            parts.append(f"level = {int(r['level'])}")
        if r.get("family"):
            parts.append(f"family = {lua_string(r['family'])}")
        if r.get("zone"):
            parts.append(f"zone = {lua_string(r['zone'])}")
        if r.get("x") is not None and r.get("y") is not None:
            parts.append(f"x = {num(r['x'])}, y = {num(r['y'])}")
        if r.get("speed"):
            parts.append(f"speed = {float(r['speed']):g}")
        parts.append("skills = " + skills_lua(r.get("skills", [])))
        w(f"    [{npc_id}] = {{ " + ", ".join(parts) + " },")
    w("}")
    w("")
    w("ForeverBeasts.FOUND = {")
    for f in FOUND:
        parts = []
        if f.get("id"):
            parts.append(f"id = {f['id']}")
        parts.append(f"name = {lua_string(f['name'])}")
        if f.get("family"):
            parts.append(f"family = {lua_string(f['family'])}")
        if f.get("min"):
            parts.append(f"min = {f['min']}, max = {f['max']}")
        if f.get("rank"):
            assert f["rank"] in RANKS, f
            parts.append(f"rank = {lua_string(f['rank'])}")
        if f.get("zone"):
            parts.append(f"zone = {lua_string(f['zone'])}")
        if f.get("x") is not None:
            parts.append(f"x = {num(f['x'])}, y = {num(f['y'])}")
        if f.get("respawn"):
            parts.append(f"respawn = {{ {f['respawn'][0]}, {f['respawn'][1]} }}")
        if f.get("skills"):
            parts.append("skills = " + skills_lua(f["skills"]))
        parts.append(f"source = {lua_string(f['source'])}")
        w("    { " + ", ".join(parts) + " },")
    w("}")
    w("")
    return "\n".join(out)


def main(argv):
    args = list(argv)
    to_stdout = "--stdout" in args
    if to_stdout:
        args.remove("--stdout")
    harvest_path = None
    if "--harvest" in args:
        i = args.index("--harvest")
        harvest_path = args[i + 1]
        del args[i:i + 2]

    lua = new_lua()
    names = compendium_names(lua)
    seen = shipped_seen(lua)
    if harvest_path:
        seen = harvest(lua, harvest_path, names)

    tamed = shipped_tamed(lua)
    for path in args:
        for npc_id, rec in tamed_from(lua, path).items():
            old = tamed.get(npc_id)
            if old and len(old.get("skills", [])) > len(rec.get("skills", [])):
                for key in ("zone", "x", "y", "family", "speed"):
                    if key in rec and key not in old:
                        old[key] = rec[key]
                continue
            tamed[npc_id] = rec

    text = render(seen, tamed)
    if to_stdout:
        print(text)
    else:
        with open(OUTPUT, "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        print(f"{len(seen)} seen, {len(tamed)} tamed, {len(FOUND)} found written to "
              f"{os.path.relpath(OUTPUT, ROOT)}")


if __name__ == "__main__":
    main(sys.argv[1:])
