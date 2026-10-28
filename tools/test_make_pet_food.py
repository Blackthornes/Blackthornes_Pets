"""Tests for tools/make_pet_food.py."""

import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_pet_food  # noqa: E402


def item(item_id, diet, cls="0"):
    return {"ID": str(item_id), "ClassID": cls, "ItemPetFoodID": str(diet)}


def sparse(item_id, name, flags=0):
    return {"ID": str(item_id), "Display_lang": name, "Flags_0": str(flags)}


class BuildTest(unittest.TestCase):
    def run_build(self, items, names, hand=None):
        return make_pet_food.build(items, names, hand or {})

    def test_diets(self):
        foods, _ = self.run_build(
            [item(1, 1), item(2, 2), item(3, 6)],
            [sparse(1, "Steak"), sparse(2, "Trout"), sparse(3, "Apple")])
        self.assertEqual(foods, [("Meat", 1, "Steak"), ("Fish", 2, "Trout"), ("Fruit", 3, "Apple")])

    def test_left_out(self):
        foods, _ = self.run_build(
            [item(1, 7), item(2, 1, cls="12"), item(3, 4), item(4, 1), item(5, 2)],
            [sparse(1, "Flesh"), sparse(2, "Quest Meat"), sparse(3, "Conjured Bread", flags=2),
             sparse(5, "UNUSED ITEM")])
        self.assertEqual(foods, [])

    def test_not_food(self):
        _, not_food = self.run_build([item(9, 0), item(10, 0)], [], {9: "Snout"})
        self.assertEqual(not_food, [(9, "Snout")])

    def test_render_quotes(self):
        text = make_pet_food.render([("Meat", 5, 'Dirge\'s "Chops"')], [], "1")
        self.assertIn('[5] = { "Meat", "Dirge\'s \\"Chops\\"" },', text)
        self.assertIn("build 1", text)


if __name__ == "__main__":
    unittest.main()
