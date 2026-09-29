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

`canaccesstable` is also a global on this client, next to `issecretvalue`.

Still to probe: a warlock with a demon out, and a hunter at the stable
master with the stable open.
