"""Tests for tools/forever_beasts.py's `--taught` rows: which beasts teach
each Beast Training rank on Forever."""

import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import forever_beasts as fb  # noqa: E402

DISMEMBER_2 = 1264927
SWIPE_1 = 1264494
BITE_3 = 17256
SONIC_BLAST_1 = 1264478   # not on the client's Beast Training list


class TaughtTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def write(self, name, text):
        path = os.path.join(self.dir, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        return path

    def run_taught(self, rows, harvest=None, found=None):
        path = self.write("taught.json", json.dumps(rows))
        return fb.taught(fb.new_lua(), path, harvest, {}, found or {})

    def test_classic_beast_gets_a_new_skill(self):
        new, _, _ = self.run_taught([{"id": DISMEMBER_2, "crs": [1151], "in_prof": 261}])
        self.assertEqual(new[1151], {"id": 1151, "name": "Saltwater Crocolisk",
                                     "skills": [("Dismember", 2)]})

    def test_a_known_rank_of_the_skill_wins(self):
        # Loch Crocolisk already teaches Bite 2 in Classic's list.
        new, _, _ = self.run_taught([{"id": BITE_3, "crs": [1693]}])
        self.assertNotIn(1693, new)

    def test_a_typed_find_wins(self):
        # Wetlands Crocolisk is typed with Dismember 1.
        new, _, _ = self.run_taught([{"id": DISMEMBER_2, "crs": [1400]}])
        self.assertNotIn(1400, new)

    def test_rank_beast_training_does_not_list_is_left_out(self):
        new, left_out, _ = self.run_taught([{"id": SONIC_BLAST_1, "crs": [1151], "in_prof": 261}])
        self.assertEqual(new, {})
        self.assertEqual(left_out, [SONIC_BLAST_1])

    def test_new_beast_needs_a_name_and_a_one_family_skill(self):
        self.write("NpcNames.lua", 'local names = {\n    [990001] = "Test Bear",\n'
                                   '    [990002] = "Test Biter",\n}\n')
        harvest = self.write("Data_Harvested.lua", """
local _, ns = ...
ns.DB:RegisterItem({ sources = {
    { name = "Test Bear", zone = "Duskwood", coords = { 40.5, 50.5 }, minLevel = 20, maxLevel = 21, provenance = "forever" },
} })
""")
        new, _, skipped = self.run_taught(
            [{"id": SWIPE_1, "crs": [990001, 990003]}, {"id": BITE_3, "crs": [990002]}], harvest)
        self.assertEqual(new[990001], {"id": 990001, "name": "Test Bear", "family": "Bear",
                                       "skills": [("Swipe", 1)], "zone": "Duskwood",
                                       "x": 40.5, "y": 50.5, "min": 20, "max": 21})
        # No name for 990003; Bite is learned by many families, so 990002 has none.
        self.assertEqual(skipped, [990002, 990003])

    def test_added_rows_are_written_and_merged_into_typed_ones(self):
        typed = next(f for f in fb.FOUND if f.get("id") and f.get("skills"))
        found = fb.merge_found({}, {typed["id"]: {"id": typed["id"], "skills": [("Swipe", 5)]},
                                    1151: {"id": 1151, "name": "Saltwater Crocolisk",
                                           "skills": [("Dismember", 2)]}})
        text = fb.render({}, {}, found)
        self.assertIn('{ id = 1151, name = "Saltwater Crocolisk", skills = '
                      '{ { name = "Dismember", rank = 2 } } },', text)
        line = next(l for l in text.splitlines() if f"id = {typed['id']}," in l)
        self.assertIn('{ name = "Swipe", rank = 5 }', line)
        self.assertEqual(text.count(f"id = {typed['id']},"), 1)


if __name__ == "__main__":
    unittest.main()
