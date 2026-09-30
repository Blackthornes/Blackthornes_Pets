# What the WoW: Forever client actually does, for pets

Found with `/bpet probe` in the game, not taken from documentation.
Tradeskills and Equipment keep files like this one for professions, the
auction house, gear and talents; read them too before relying on any API.

## Hunter, level 10, Boar out (first probe, 2026-09-29)

`/bpet probe` on an orc hunter in Durotar with a level 7 Boar out.

**Present:** `UnitClass`, `UnitLevel`, `UnitExists`, `UnitName`,
`UnitCreatureFamily`, `UnitHealth`, `UnitHealthMax`, `UnitPower`,
`UnitPowerMax`, `HasPetUI`, `GetPetExperience`, `GetPetActionInfo`,
`C_StableInfo.GetStablePetInfo`, `C_StableInfo.GetNumActivePets`,
`C_StableInfo.GetNumStablePets`, `IsSpellKnown`, `C_Spell.GetSpellName`,
`C_Container.GetContainerItemInfo`, `C_Item.GetItemCount`.

**Absent:** `HasPetSpells`, `GetPetHappiness`, `GetPetLoyalty`,
`GetPetFoodTypes`, `GetPetTrainingPoints`, `GetNumStablePets`,
`GetStablePetInfo`, `GetNumStableSlots`, `GetSpellInfo`, `GetItemCount`.

What they returned:

| Call | Returned |
| --- | --- |
| `UnitClass("player")` | `Hunter, HUNTER, 3` |
| `UnitName("pet")` | `Boar` |
| `UnitCreatureFamily("pet")` | `Boar, 5` (name and family id, the retail shape) |
| `UnitLevel("pet")` | `7` (player 10) |
| `HasPetUI()` | `true, true` |
| `GetPetExperience()` | `0, 1125` (current, needed for next level) |

What that means for features:

- **The stable is the retail one.** Use `C_StableInfo`, never the classic
  `GetNumStablePets` / `GetStablePetInfo` / `GetNumStableSlots`.
- **No happiness, loyalty, diet or training-point calls under their classic
  names.** Yet the default pet frame still draws a happiness face beside the
  pet portrait. So either the mechanic lives under another name or only the
  frame is left. The probe now reads `PetFrameHappiness` and lists every
  global or `C_` function whose name looks like happiness, loyalty, diet,
  food, stable or training points; the next run answers it.
- **Pet experience works**, so a pet XP bar needs nothing new.
- **Spell and item lookups are the modern ones:** `C_Spell.*` and
  `C_Item.GetItemCount`, not `GetSpellInfo` or `GetItemCount`.

**Pet health is a secret value, even in town out of combat.** The widened
probe's second run (in Razor Hill, next to the hunter trainer) stopped at the
pet health line: `UnitHealth("pet")` came back secret. `tostring` of it
stays secret, and so does joining it with `..` (the client allows that);
only `table.concat` and comparisons raise. So a check that a value is plain
has to use `issecretvalue` where the client has it, or try `table.concat`
inside a pcall; a `..` inside a pcall proves nothing. The probe now prints "(secret)" for any value like
that. A pet frame or health warning cannot read the pet's health as a number;
it has to hand the value straight to a status bar or find another source.

**The classic mechanics are all there, under `C_PetInfo`.** The third run
(Durotar, level 7 Boar, no stable open) listed these pet-like calls:

- `C_PetInfo.GetPetHappiness`, `C_PetInfo.GetPetLoyalty`,
  `C_PetInfo.GetPetFoodTypes`, `C_PetInfo.GetPetTrainingPoints`
- `C_PlayerInfo.GetPetStableCreatureDisplayInfoID`
- `C_StableInfo`: `BuyStableSlot`, `ClosePetStables`, `GetActivePetList`,
  `GetAvailablePetSpecInfos`, `GetNextStableSlotCost`, `GetNumActivePets`,
  `GetNumStablePets`, `GetNumStableSlots`, `GetStablePetFoodTypes`,
  `GetStablePetInfo`, `GetStabledPetList`, `IsAtStableMaster`,
  `IsBonusPetSlotAvailable`, `IsPetFavorite`, `PickupStablePet`,
  `SetPetFavorite`, `SetPetSlot`

`GetNumActivePets` returned 1 and `GetNumStablePets` 0. What the four
`C_PetInfo` calls return is not recorded yet; the probe now reads them, and
summarises `GetActivePetList`, at the bottom of its output.

**What they return (fourth run, same Boar, now level 8, out of combat, not
at a stable).** They use the classic return shapes, except the food types,
which come back as a table:

| Call | Returned | Reading |
| --- | --- | --- |
| `C_PetInfo.GetPetHappiness()` | `1, 75, -10` | happiness level (1 unhappy, 2 content, 3 happy), damage percent, loyalty rate |
| `C_PetInfo.GetPetLoyalty()` | `Rebellious` | the loyalty level's name only, no number |
| `C_PetInfo.GetPetFoodTypes()` | `{ "Meat", "Fish", "Cheese", "Bread", "Fungus", "Fruit" }` | a list, not several return values |
| `C_PetInfo.GetPetTrainingPoints()` | `0, 5` | classic order is total points, points spent |
| `GetPetExperience()` | `92, 1350` | current, needed |
| `UnitPowerType("pet")` | `2, FOCUS` | the pet runs on focus, max 100 |
| `UnitHealthMax("pet")` | `231` | readable; only the current health is secret |
| `UnitPower("pet")` | secret | current focus is secret too |
| `C_StableInfo.IsAtStableMaster()` | `false` | |
| `C_StableInfo.GetActivePetList()` | a list of 1 | fields include `creatureID`, `displayID`, `experience`, `experienceNeeded`, `familyName`, `happinessLevel`, `icon`, `isExotic` (the probe shows the first eight) |

The pet frame's happiness face was shown, and the pet frame drew it red,
which matches level 1. The active list's `experience=0,
experienceNeeded=1125` was out of date against `GetPetExperience`, so read
experience from `GetPetExperience`.

The training points order still needs one check: a pet that has learned
something from a trainer should show its spent points move.

`canaccesstable` is also a global on this client, next to `issecretvalue`.

**Feeding (2026-09-30, a hunter with a scorpid).**

- A secure action button whose macro is `/cast Feed Pet` then `/use <bag>
  <slot>` feeds the pet: Feed Pet takes the food the `/use` names. The spell
  name comes from `C_Spell.GetSpellName(6991)`.
- `C_Container.GetContainerItemInfo` gave no `itemName` for the food, so
  names are read from `hyperlink` (`|h[Name]|h`), with the item cache after.
- Just after login the bags read empty, or items come back with no name,
  until the client sends them (`BAG_UPDATE_DELAYED`), so a scan then says
  nothing about how much food there is.
- `ObjectiveTrackerFrame` exists and gives its edges, so a button can be
  placed above the quest list.

Still to probe: a warlock with a demon out, and a hunter at the stable
master with the stable open.
