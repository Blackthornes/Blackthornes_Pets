"""Writes Data/PetTraining.lua: every rank of every pet skill a hunter can
teach, the pet level each one needs, its training point cost, which ones a pet
trainer teaches, and where the pet trainers stand.

Run from the repository root:

    python tools/make_pet_training.py <tables folder> --build <build> \\
        <world_full_14_june_2021.sql> <pfQuest>

  <tables folder>   the Forever client's game tables as CSV (SkillLineAbility,
                    SpellName, Spell, SpellLevels, SpellEffect,
                    CreatureFamily, FactionTemplate). Which skills Beast
                    Training lists, each rank's pet level and which pet
                    families can learn it come from here, so Forever's own
                    skills are in too. Never commit the tables.
  <...sql>          the vmangos world database, the same one Data/BeastSkills.lua
                    and Data/Compendium.lua were made from: the training point
                    cost of each pet spell (skill_line_ability), which ranks the
                    pet trainers teach (npc_trainer_template) and who the pet
                    trainers are (creature_template).
  <pfQuest>         its db/ folder: where each pet trainer stands.

Never edit the output by hand: rerun the tool.
"""

import argparse
import collections
import csv
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_compendium import tables, load_pfquest, spots_of, central, lua_string, num  # noqa: E402

BEAST_TRAINING = 261     # the hunter's Beast Training skill line
PET_GENERAL = 270        # pet spells every family can learn
LEARN_PET_SPELL = 36     # the spell effect that teaches the pet a spell
PATCH = 10               # creature_template rows up to patch 1.12
LAST_BUILD = 5875        # Classic 1.12.1


def read_csv(folder, name):
    with open(folder / (name + ".csv"), encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def rank_of(text):
    m = re.search(r"(\d+)", text or "")
    return int(m.group(1)) if m else None


def main():
    p = argparse.ArgumentParser()
    p.add_argument("tables")
    p.add_argument("dump")
    p.add_argument("pfquest")
    p.add_argument("--build", required=True)
    args = p.parse_args()
    folder = Path(args.tables)
    repo = Path(__file__).resolve().parent.parent

    names = {r["ID"]: r["Name_lang"] for r in read_csv(folder, "SpellName")}
    subtext = {r["ID"]: r.get("NameSubtext_lang", "") for r in read_csv(folder, "Spell")}
    levels = {}
    for r in read_csv(folder, "SpellLevels"):
        levels[r["SpellID"]] = max(int(r["SpellLevel"] or 0), int(r["BaseLevel"] or 0))
    teaches = {}
    for r in read_csv(folder, "SpellEffect"):
        if r["Effect"] == str(LEARN_PET_SPELL) and r["EffectTriggerSpell"] not in ("", "0"):
            teaches[r["SpellID"]] = r["EffectTriggerSpell"]
    family_of_line = {}
    for r in read_csv(folder, "CreatureFamily"):
        for key in ("SkillLine_0", "SkillLine_1"):
            if r[key] not in ("", "0"):
                family_of_line[r[key]] = int(r["ID"])

    abilities = read_csv(folder, "SkillLineAbility")
    lines_of = collections.defaultdict(set)
    for r in abilities:
        lines_of[r["Spell"]].add(r["SkillLine"])

    data = tables(Path(args.dump), {"skill_line_ability", "npc_trainer_template",
                                    "creature_template", "spell_template"})
    cost = {}
    for r in data["skill_line_ability"]:
        if r["req_train_points"]:
            cost[str(r["spell_id"])] = r["req_train_points"]
    classic_lines = collections.defaultdict(set)
    for r in data["skill_line_ability"]:
        classic_lines[str(r["spell_id"])].add(str(r["skill_id"]))

    templates = {}
    for r in data["creature_template"]:
        if r["patch"] > PATCH:
            continue
        old = templates.get(r["entry"])
        if old is None or r["patch"] > old["patch"]:
            templates[r["entry"]] = r
    pet_trainers = {e: t for e, t in templates.items()
                    if t["trainer_type"] == 3 and t["trainer_class"] == 3 and t["trainer_id"]
                    and t["subname"] == "Pet Trainer"}
    trainer_ids = {t["trainer_id"] for t in pet_trainers.values()}

    # The trainer's spells teach the hunter a Beast Training rank.
    trigger = {}
    for r in data["spell_template"]:
        if r.get("effect1") == 36 and r.get("effectTriggerSpell1"):
            trigger[str(r["entry"])] = str(r["effectTriggerSpell1"])
    taught_by_trainer = set()
    for r in data["npc_trainer_template"]:
        if r["entry"] in trainer_ids and r["build_max"] >= LAST_BUILD:
            teach = trigger.get(str(r["spell"]))
            if teach:
                taught_by_trainer.add(teach)

    skills = collections.defaultdict(dict)
    spells = {}
    for r in abilities:
        if r["SkillLine"] != str(BEAST_TRAINING):
            continue
        teach = r["Spell"]
        pet = teaches.get(teach)
        name, rank = names.get(teach), rank_of(subtext.get(teach))
        if not (pet and name and rank):
            continue
        level = max(levels.get(teach, 0), levels.get(pet, 0), 1)
        lines = lines_of.get(pet) or classic_lines.get(pet) or set()
        everyone = str(PET_GENERAL) in lines
        families = sorted({family_of_line[l] for l in lines if l in family_of_line})
        entry = {"spell": int(pet), "teach": int(teach), "level": level}
        if pet in cost:
            entry["cost"] = cost[pet]
        if teach in taught_by_trainer:
            entry["trainer"] = True
        if r["AcquireMethod"] == "1":
            entry["free"] = True
        old = skills[name].get(rank)
        if old and old.get("trainer") and not entry.get("trainer"):
            continue
        skills[name][rank] = entry
        skill_families = skills[name].setdefault("_families", set())
        if everyone:
            skills[name]["_all"] = True
        skill_families.update(families)
        spells[int(pet)] = (name, rank)

    # Pet trainers and where they stand.
    sides = {}
    for r in read_csv(folder, "FactionTemplate"):
        group = int(r["FactionGroup"] or 0)
        sides[int(r["ID"])] = "A" if group & 2 else "H" if group & 4 else None
    pfq = load_pfquest(Path(args.pfquest))
    units, zone_names = pfq["units"]["data"], pfq["zones"]["enUS"]
    trainers = []
    for entry, t in sorted(pet_trainers.items()):
        side = sides.get(t["faction"])
        spots = spots_of(units[entry]) if units[entry] else []
        if not side or not spots:
            continue
        by_zone = collections.defaultdict(list)
        for zone, x, y in spots:
            by_zone[zone].append((x, y))
        zone = max(by_zone, key=lambda z: len(by_zone[z]))
        if not zone_names[zone]:
            continue
        x, y = central(by_zone[zone])
        trainers.append({"id": entry, "name": t["name"], "side": side,
                         "zone": zone_names[zone], "x": x, "y": y})

    out = []
    w = out.append
    w("-- Blackthornes Pets -- Data/PetTraining.lua")
    w("-- Every rank of every pet skill Beast Training can teach, and the pet")
    w("-- trainers.")
    w("--")
    w("-- Generated by tools/make_pet_training.py from the Forever client's game")
    w("-- tables (build %s: which skills Beast Training lists, the pet level each" % args.build)
    w("-- rank needs, which families can learn it) and Classic 1.12 data (each")
    w("-- rank's training point cost, which ranks a pet trainer teaches, and the")
    w("-- trainers). Never edit it by hand: rerun the tool.")
    w("--")
    w("-- SKILLS[name] = { all = every family can learn it, families = { family")
    w("-- id, ... }, [rank] = { spell (the pet's), teach (the hunter's), level")
    w("-- (the pet's), cost (training points), trainer (a pet trainer teaches it),")
    w("-- free (every pet gets it) } }. SPELLS[pet spell] = { name, rank }.")
    w("")
    w("local _, ns = ...")
    w("")
    w("local PetTraining = {}")
    w("ns.PetTrainingData = PetTraining")
    w("")
    w("PetTraining.SKILLS = {")
    for name in sorted(skills):
        s = skills[name]
        head = []
        if s.get("_all"):
            head.append("all = true")
        fams = sorted(s.get("_families", ()))
        if fams and not s.get("_all"):
            head.append("families = { %s }" % ", ".join(str(f) for f in fams))
        w("    [%s] = {%s" % (lua_string(name), (" " + ", ".join(head) + ",") if head else ""))
        for rank in sorted(k for k in s if isinstance(k, int)):
            e = s[rank]
            parts = ["spell = %d" % e["spell"], "teach = %d" % e["teach"], "level = %d" % e["level"]]
            if "cost" in e:
                parts.append("cost = %d" % e["cost"])
            if e.get("trainer"):
                parts.append("trainer = true")
            if e.get("free"):
                parts.append("free = true")
            w("        [%d] = { %s }," % (rank, ", ".join(parts)))
        w("    },")
    w("}")
    w("")
    w("PetTraining.SPELLS = {")
    for spell in sorted(spells):
        name, rank = spells[spell]
        w("    [%d] = { %s, %d }," % (spell, lua_string(name), rank))
    w("}")
    w("")
    w("-- Pet trainers: id, name, side (A or H), zone, x, y.")
    w("PetTraining.TRAINERS = {")
    for t in trainers:
        w("    { id = %d, name = %s, side = %s, zone = %s, x = %s, y = %s }," % (
            t["id"], lua_string(t["name"]), lua_string(t["side"]), lua_string(t["zone"]),
            num(t["x"]), num(t["y"])))
    w("}")
    (repo / "Data" / "PetTraining.lua").write_text("\n".join(out) + "\n", encoding="utf-8")
    print("skills %d, pet spells %d, trainers %d" % (len(skills), len(spells), len(trainers)))


if __name__ == "__main__":
    main()
