"""Writes Data/Compendium.lua: every beast a hunter can tame in Classic, and
where it lives.

Run from the repository root with two Classic 1.12 databases on disk:

    python tools/make_compendium.py <world_full_14_june_2021.sql> <pfQuest>

  github.com/brotalnia/database    world_full_14_june_2021.7z, unpacked: the
                                   vmangos world database, the same one
                                   Data/BeastSkills.lua was made from. Its
                                   creature_template says which beasts are
                                   tameable (type_flags bit 1), their family,
                                   levels, rank (rare, elite) and attack
                                   speed (base_attack_time), and its
                                   creature table where each one spawns and
                                   how long it takes to come back
  github.com/shagu/pfQuest         db/: where every creature stands, in zone
                                   map coordinates, with zone names

Nothing in the output is typed by hand except FAMILIES and INSTANCES below,
which are the client's own names for the pet families and dungeon maps. What
a beast teaches stays in Data/BeastSkills.lua; the compendium reads it from
there. A beast that never spawns in the world (summoned, scripted, unused) is
left out, because there is nowhere to send a hunter to tame it.

Forever's own findings (Data/ForeverBeasts.lua) are laid over this file in
game; they are never mixed into it.
"""

import collections
import math
import re
import sys
from pathlib import Path

import lupa.lua51 as lua51

PATCH = 10       # creature_template rows up to patch 1.12

# The tameable pet families of patch 1.12, by CreatureFamily id, with what
# each eats (the family's diet in the client).
FAMILIES = {
    1: ("Wolf", "Meat"),
    2: ("Cat", "Meat, Fish"),
    3: ("Spider", "Meat"),
    4: ("Bear", "Meat, Fish, Cheese, Bread, Fungus, Fruit"),
    5: ("Boar", "Meat, Fish, Cheese, Bread, Fungus, Fruit"),
    6: ("Crocolisk", "Meat, Fish"),
    7: ("Carrion Bird", "Meat, Fish"),
    8: ("Crab", "Fish, Bread, Fungus, Fruit"),
    9: ("Gorilla", "Fungus, Fruit"),
    11: ("Raptor", "Meat"),
    12: ("Tallstrider", "Cheese, Fungus, Fruit"),
    20: ("Scorpid", "Meat"),
    21: ("Turtle", "Fish, Fungus, Fruit"),
    24: ("Bat", "Fungus, Fruit"),
    25: ("Hyena", "Meat, Fruit"),
    26: ("Owl", "Meat"),
    27: ("Wind Serpent", "Fish, Cheese, Bread"),
}

# Dungeon and raid maps, which pfQuest gives no coordinates for.
INSTANCES = {
    33: "Shadowfang Keep", 34: "The Stockade", 36: "The Deadmines",
    43: "Wailing Caverns", 47: "Razorfen Kraul", 48: "Blackfathom Deeps",
    70: "Uldaman", 90: "Gnomeregan", 109: "Sunken Temple",
    129: "Razorfen Downs", 189: "Scarlet Monastery", 209: "Zul'Farrak",
    229: "Blackrock Spire", 230: "Blackrock Depths", 289: "Scholomance",
    309: "Zul'Gurub", 329: "Stratholme", 349: "Maraudon",
    389: "Ragefire Chasm", 409: "Molten Core", 429: "Dire Maul",
    469: "Blackwing Lair", 509: "Ruins of Ahn'Qiraj",
    531: "Temple of Ahn'Qiraj", 533: "Naxxramas",
}
RAIDS = {309, 409, 469, 509, 531, 533}

# creature_template.rank
RANKS = {1: "elite", 2: "rareelite", 4: "rare"}

BAD_NAME = re.compile(r"UNUSED|DEPRECATED|\bOLD\b|<|\[|TEST|NYI|ZZOLD", re.I)

INSERT = re.compile(r"INSERT INTO `(\w+)` \(([^)]*)\) VALUES")


def parse_row(line):
    """One `(a,'b',c)` row as a list of values, or None when it runs on."""
    values, cur, in_str, quoted = [], [], False, False
    j, n = 1, len(line)
    while j < n:
        ch = line[j]
        if in_str:
            if ch == "\\":
                cur.append(line[j + 1])
                j += 2
                continue
            if ch == "'":
                in_str = False
            else:
                cur.append(ch)
        elif ch == "'":
            in_str, quoted, cur = True, True, []
        elif ch in ",)":
            text = "".join(cur)
            if quoted:
                values.append(text)
            else:
                text = text.strip()
                try:
                    values.append(int(text))
                except ValueError:
                    try:
                        values.append(float(text))
                    except ValueError:
                        values.append(text)
            cur, quoted = [], False
            if ch == ")":
                return values
        else:
            cur.append(ch)
        j += 1
    return None


def tables(path, wanted):
    """Every row of the tables in `wanted` from one mysqldump file, as dicts.
    Rows may sit one to a line or many to a line after the INSERT."""
    out = {t: [] for t in wanted}
    current, columns = None, None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            m = INSERT.match(line)
            if m:
                current = m.group(1) if m.group(1) in wanted else None
                columns = [c.strip(" `") for c in m.group(2).split(",")]
                rest = line[m.end():].strip()
                if current and rest.startswith("("):
                    line = rest
                else:
                    continue
            if current is None or not line.startswith("("):
                if line and not line.startswith("("):
                    current = None
                continue
            for chunk in re.split(r"\),\s*\(", line.rstrip(";,")):
                chunk = chunk if chunk.startswith("(") else "(" + chunk
                chunk = chunk if chunk.endswith(")") else chunk + ")"
                values = parse_row(chunk)
                if values is not None and len(values) == len(columns):
                    out[current].append(dict(zip(columns, values)))
    return out


def load_pfquest(folder):
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute("pfDB = setmetatable({}, {__index = function(t, k) "
                "local v = {} rawset(t, k, v) return v end})")
    db = folder / "db"
    for name in ["units.lua", "zones.lua", "enUS/units.lua", "enUS/zones.lua"]:
        lua.execute((db / name).read_text(encoding="utf-8"))
    return lua.eval("pfDB")


def spots_of(entry):
    """[(zone id, x, y)] for a pfQuest unit."""
    coords = entry and entry["coords"]
    if not coords:
        return []
    out = []
    for i in coords:
        s = coords[i]
        out.append((int(s[3]), float(s[1]), float(s[2])))
    return out


def central(points):
    """The spot nearest the middle of a zone's spots: one a hunter can walk
    to and find the beast near."""
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    return min(points, key=lambda p: math.hypot(p[0] - cx, p[1] - cy))


def lua_string(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def num(x):
    x = round(x, 1)
    return str(int(x)) if x == int(x) else str(x)


def main():
    dump, pfq_dir = Path(sys.argv[1]), Path(sys.argv[2])
    repo = Path(__file__).resolve().parent.parent

    data = tables(dump, {"creature_template", "creature"})
    templates = {}
    for r in data["creature_template"]:
        if r["patch"] > PATCH:
            continue
        old = templates.get(r["entry"])
        if old is None or r["patch"] > old["patch"]:
            templates[r["entry"]] = r

    spawns = collections.defaultdict(list)
    for r in data["creature"]:
        if r["patch_min"] > PATCH:
            continue
        for key in ("id", "id2", "id3", "id4"):
            if r.get(key):
                spawns[r[key]].append(r)

    pfq = load_pfquest(pfq_dir)
    units = pfq["units"]["data"]
    zone_names = pfq["zones"]["enUS"]

    beasts, skipped = [], []
    for entry, t in sorted(templates.items()):
        if t["type"] != 1 or not (t["type_flags"] & 1):
            continue
        if t["pet_family"] not in FAMILIES or BAD_NAME.search(t["name"]):
            continue
        rows = spawns.get(entry, [])
        spots = spots_of(units[entry]) if units[entry] else []

        beast = {
            "id": entry, "name": t["name"], "family": t["pet_family"],
            "min": t["level_min"], "max": t["level_max"],
            "rank": RANKS.get(t["rank"]),
        }
        # Seconds between melee swings. A Classic pet keeps the speed of the
        # beast it was tamed from, so this is the tamed pet's speed too.
        if t["base_attack_time"] and t["base_attack_time"] > 0:
            beast["speed"] = round(t["base_attack_time"] / 1000, 2)

        by_zone = collections.defaultdict(list)
        for zone, x, y in spots:
            by_zone[zone].append((x, y))
        if by_zone:
            ordered = sorted(by_zone, key=lambda z: -len(by_zone[z]))
            names = [zone_names[z] for z in ordered if zone_names[z]]
            if not names:
                skipped.append(t["name"])
                continue
            x, y = central(by_zone[ordered[0]])
            beast.update(zone=names[0], x=x, y=y, spawns=len(spots), also=names[1:4])
        else:
            maps = collections.Counter(r["map"] for r in rows if r["map"] in INSTANCES)
            if not maps:
                skipped.append(t["name"])
                continue
            m = maps.most_common(1)[0][0]
            beast.update(zone=INSTANCES[m], instance="raid" if m in RAIDS else "dungeon",
                         spawns=sum(maps.values()))

        if beast["rank"] in ("rare", "rareelite") and rows:
            low = min(r["spawntimesecsmin"] for r in rows)
            high = max(r["spawntimesecsmax"] for r in rows)
            if low > 0:
                beast["respawn"] = (low, high)
        beasts.append(beast)

    out = []
    w = out.append
    w("-- Blackthornes Pets -- Data/Compendium.lua")
    w("-- Every beast a hunter can tame in Classic, with where it lives.")
    w("--")
    w("-- Generated by tools/make_compendium.py from the vmangos world database")
    w("-- (14 June 2021; which beasts are tameable, their family, levels, rank and")
    w("-- respawn, as of patch 1.12) and pfQuest's database (where each one stands,")
    w("-- in zone map coordinates). Never edit it by hand: rerun the tool.")
    w("--")
    w("-- What taming a beast teaches is in Data/BeastSkills.lua, and what Forever")
    w("-- has shown differently is in Data/ForeverBeasts.lua and the player's own")
    w("-- tames (Logic/TameRecord.lua); Logic/Compendium.lua lays those over this.")
    w("--")
    w("-- A beast: name, family (FAMILIES), min and max level, rank (\"rare\",")
    w("-- \"rareelite\", \"elite\" or none), the zone it mostly lives in and a spot")
    w("-- there near the middle of its spawns (x, y), how many spawn points it has,")
    w("-- other zones it is also found in, `instance` for a dungeon or raid beast")
    w("-- (no coordinates), for a rare the respawn time in seconds, low and high,")
    w("-- and `speed`, the seconds between its melee swings (base_attack_time), which")
    w("-- a Classic pet keeps from the beast it was tamed from.")
    w("")
    w("local _, ns = ...")
    w("")
    w("local Compendium = {}")
    w("ns.CompendiumData = Compendium")
    w("")
    w("-- Family id = { name, what it eats }")
    w("Compendium.FAMILIES = {")
    for fid, (name, diet) in sorted(FAMILIES.items()):
        w(f"    [{fid}] = {{ {lua_string(name)}, {lua_string(diet)} }},")
    w("}")
    w("")
    w("Compendium.BEASTS = {")
    for b in beasts:
        parts = [f"name = {lua_string(b['name'])}", f"family = {b['family']}",
                 f"min = {b['min']}", f"max = {b['max']}"]
        if b["rank"]:
            parts.append(f"rank = {lua_string(b['rank'])}")
        parts.append(f"zone = {lua_string(b['zone'])}")
        if "x" in b:
            parts.append(f"x = {num(b['x'])}, y = {num(b['y'])}")
        if b.get("instance"):
            parts.append(f"instance = {lua_string(b['instance'])}")
        parts.append(f"spawns = {b['spawns']}")
        if b.get("also"):
            parts.append("also = { " + ", ".join(lua_string(z) for z in b["also"]) + " }")
        if b.get("respawn"):
            parts.append(f"respawn = {{ {b['respawn'][0]}, {b['respawn'][1]} }}")
        if b.get("speed"):
            parts.append(f"speed = {b['speed']:g}")
        w(f"    [{b['id']}] = {{ " + ", ".join(parts) + " },")
    w("}")
    w("")

    target = repo / "Data" / "Compendium.lua"
    target.write_text("\n".join(out), encoding="utf-8", newline="\n")
    print(f"{len(beasts)} beasts written to {target.relative_to(repo)}; "
          f"{len(skipped)} left out with no spawn: {', '.join(sorted(skipped))}")


if __name__ == "__main__":
    main()
