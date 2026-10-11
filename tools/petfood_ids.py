"""Fills in the item IDs in Data/PetFood.lua.

Run from the repository root:

    python tools/petfood_ids.py <pfQuest folder or db/enUS/items.lua>

Data/PetFood.lua is typed by hand, one food a line. A food added by its
English name alone,

        "Tough Jerky",

is rewritten with its item ID in front,

        { 117, "Tough Jerky" },

so the food helper matches it by ID and works on a client in any language.
The ID comes from pfQuest's English item names (github.com/shagu/pfQuest,
db/enUS/items.lua), and only when exactly one item has that name. A food
already carrying an ID is checked against pfQuest and reported if they
disagree; nothing else in the file is touched. A name pfQuest does not have
is left as it is and listed, and the addon keeps matching it by name.

Options:
    --check    change nothing; exit 1 if a food has no ID or a wrong one
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PETFOOD = os.path.join(ROOT, "Data", "PetFood.lua")

ITEM_LINE = re.compile(r'^\s*\[(\d+)\]\s*=\s*"((?:[^"\\]|\\.)*)"', re.M)
BARE = re.compile(r'^(\s*)"((?:[^"\\]|\\.)*)",\s*$')
WITH_ID = re.compile(r'^(\s*)\{\s*(\d+)\s*,\s*"((?:[^"\\]|\\.)*)"\s*\},\s*$')


def load_items(path):
    """English name -> [item IDs]."""
    if os.path.isdir(path):
        path = os.path.join(path, "db", "enUS", "items.lua")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    ids = {}
    for item_id, name in ITEM_LINE.findall(text):
        name = name.replace("\\'", "'").replace('\\"', '"')
        ids.setdefault(name, []).append(int(item_id))
    return ids


def fill(lines, ids):
    """The file's lines with IDs filled in, and what could not be."""
    out, missing, wrong = [], [], []
    inside = False
    for line in lines:
        if line.startswith("local DIETS = {"):
            inside = True
        elif inside and line.rstrip() == "}":
            inside = False
        if inside:
            bare = BARE.match(line)
            have = WITH_ID.match(line)
            if bare:
                indent, name = bare.groups()
                found = ids.get(name, [])
                if len(found) == 1:
                    line = '%s{ %d, "%s" },\n' % (indent, found[0], name)
                else:
                    missing.append((name, found))
            elif have:
                _, item_id, name = have.groups()
                found = ids.get(name, [])
                if found and int(item_id) not in found:
                    wrong.append((name, int(item_id), found))
        out.append(line)
    return out, missing, wrong


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 1:
        print(__doc__)
        return 2
    ids = load_items(args[0])
    with open(PETFOOD, encoding="utf-8") as handle:
        lines = handle.readlines()
    out, missing, wrong = fill(lines, ids)
    for name, found in missing:
        why = "several items: %s" % found if found else "no item by that name"
        print("no ID for %s (%s)" % (name, why))
    for name, item_id, found in wrong:
        print("%s has ID %d, pfQuest says %s" % (name, item_id, found))
    if "--check" in argv:
        return 1 if (missing or wrong or out != lines) else 0
    if out != lines:
        with open(PETFOOD, "w", encoding="utf-8", newline="\n") as handle:
            handle.writelines(out)
        print("wrote %s" % os.path.relpath(PETFOOD, ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
