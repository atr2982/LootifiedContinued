# Best in Slot stat-priority sources

Reviewed 2026-11-16 for the WoW: Forever addon. The orders in `Core/StatPrio.lua` follow Forever-specific PvE guides. They express general priorities, not universal numerical weights: hit and expertise change value at their caps, and a tank's threat and mitigation needs can differ by encounter. The addon's Percent score is a general gear comparison, not a character-specific simulator.

## Forever class and spec guides consulted

- **Druid**
  - [Feral Druid DPS and tank priority](https://www.icy-veins.com/wow-forever/feral-druid-melee-dps-and-tank-pve-stat-priority) separates threat/DPS (weapon DPS, expertise, hit, agility, strength, then crit/AP) from tank mitigation (armor, defense, stamina, agility, dodge). Bear defaults place mitigation first and retain threat stats.
  - [Feral Druid leveling](https://www.icy-veins.com/wow-forever/feral-druid-leveling/) gives weapon DPS, hit/expertise, and crit for leveling.
  - [Balance Druid](https://www.icy-veins.com/wow-forever/balance-druid-ranged-dps-pve-stat-priority) and [Restoration Druid](https://www.icy-veins.com/wow-forever/restoration-druid-healer-pve-guide/) guide the caster/healer order.
- **Warrior**
  - [Arms](https://www.icy-veins.com/wow-forever/arms-warrior-melee-dps-pve-stat-priority), [Fury](https://www.icy-veins.com/wow-forever/fury-warrior-melee-dps-pve-stat-priority), and [Protection](https://www.icy-veins.com/wow-forever/protection-warrior-tank-pve-stat-priority): weapon damage, hit/expertise and offensive stats for DPS. Protection separates offensive and defensive orders; its combined default puts stamina, armor, agility, avoidance, and defense first, then threat stats.
- **Paladin**
  - [Retribution](https://www.icy-veins.com/wow-forever/retribution-paladin-melee-dps-pve-stat-priority), [Holy](https://www.icy-veins.com/wow-forever/holy-paladin-healer-pve-stat-priority), and [Protection](https://www.icy-veins.com/wow-forever/protection-paladin-tank-pve-stat-priority): hit/expertise and strength/offense for Retribution, healing/intellect/regen for Holy, and the guide's explicit Protection order of Stamina, Defense, Spell Power, Intellect, Strength.
- **Hunter**
  - [Beast Mastery](https://www.icy-veins.com/wow-forever/beast-mastery-hunter-ranged-dps-pve-stat-priority), [Marksmanship](https://www.icy-veins.com/wow-forever/marksmanship-hunter-ranged-dps-pve-stat-priority), and [Survival](https://www.icy-veins.com/wow-forever/survival-hunter-melee-dps-pve-stat-priority): hit, crit, agility, attack power, and weapon value; Survival's guide emphasizes weapon damage and Agility while leveling.
- **Rogue**
  - [Assassination](https://www.icy-veins.com/wow-forever/assassination-rogue-melee-dps-pve-stat-priority), [Combat](https://www.icy-veins.com/wow-forever/combat-rogue-melee-dps-pve-stat-priority), and [Subtlety](https://www.icy-veins.com/wow-forever/subtlety-rogue-melee-dps-pve-stat-priority): hit/expertise, agility, weapon damage and offensive secondaries; ranking keeps caps in mind but cannot dynamically know every target's level.
- **Priest**
  - [Discipline](https://www.icy-veins.com/wow-forever/discipline-priest-healer-pve-stat-priority), [Holy](https://www.icy-veins.com/wow-forever/holy-priest-healer-pve-stat-priority), and [Shadow](https://www.icy-veins.com/wow-forever/shadow-priest-ranged-dps-pve-guide/): healing/intellect/regen for healers and hit/spell power/offensive secondaries for damage specs. Damage variants use their corresponding damage school when available.
- **Shaman**
  - [Elemental](https://www.icy-veins.com/wow-forever/elemental-shaman-ranged-dps-pve-stat-priority), [Enhancement](https://www.icy-veins.com/wow-forever/enhancement-shaman-melee-dps-pve-stat-priority), and [Restoration](https://www.icy-veins.com/wow-forever/restoration-shaman-healer-pve-stat-priority): spell power and hit for Elemental, weapon DPS/hit/expertise/Strength for Enhancement, and healing/intellect/regen for Restoration. Enhancement page was updated 2026-11-13.
- **Mage**
  - [Arcane](https://www.icy-veins.com/wow-forever/arcane-mage-ranged-dps-pve-stat-priority), [Fire](https://www.icy-veins.com/wow-forever/fire-mage-ranged-dps-pve-stat-priority), and [Frost](https://www.icy-veins.com/wow-forever/frost-mage-ranged-dps-pve-stat-priority): spell hit, spell power and each spec's damage secondaries, followed by intellect and mana support.
- **Warlock**
  - [Affliction](https://www.icy-veins.com/wow-forever/affliction-warlock-ranged-dps-pve-stat-priority), [Demonology](https://www.icy-veins.com/wow-forever/demonology-warlock-ranged-dps-pve-stat-priority), and [Destruction](https://www.icy-veins.com/wow-forever/destruction-warlock-ranged-dps-pve-stat-priority): spell hit and spell power lead; damage-school power and the spec's crit/haste balance follow.

## How the defaults are applied

Only stats supported by a spec's existing Forever item-weight data appear, including weapon DPS where the spec's model scores it. That spec's original weight values are assigned in descending order to its researched stat ranks. This keeps a separate scoring model for every spec, makes displayed bars match the scoring order, and avoids inventing a new numeric value for the gap between adjacent priorities. Generic Spell Power is excluded from Feral Cat scoring because the Forever Feral DPS guide does not treat it as a damage priority; this prevents spell-power-heavy caster weapons from being recommended as Cat upgrades over better feral weapons. Legacy saved drag multipliers are discarded because they could contradict the corrected class/spec defaults.

Guides primarily discuss endgame PvE and often describe separate caps or situational tank/healing priorities. Lootified's static Percent comparison cannot dynamically model a hit/Expertise cap for every target or replace a full combat simulator; users can still use the listed order as a consistent general gear-ranking default.

## Display and scoring audit (2026-11-16)

The priority tab is a read-only view of the active Percent scorer. It must remain available when a player changes specs; hiding it when the optional simulator reports that it ranks items removed the user's ability to inspect the active stat order. `Core/StatPrio.lua` now exposes weapon DPS and Rogue Subtlety Weapon Skill as rows when those values are scored. The scorer no longer silently adds fallback Haste, Expertise, or Weapon Skill value to an item without a corresponding visible spec row.

The sourced lead priorities used for each available spec are:

| Class | Spec | Default order highlights |
| --- | --- | --- |
| Druid | Feral (Cat) | Weapon DPS, Expertise, Hit, Agility, Strength, Crit/AP |
| Druid | Feral (Bear) | Armor, Defense, Stamina, Weapon DPS, Expertise/Hit, Agility/Dodge |
| Druid | Balance | Hit, Spell Power, Nature/Arcane power, Crit, Haste, Intellect |
| Druid | Restoration | Healing, Intellect, Spirit/MP5, Crit, Haste |
| Warrior | Arms | Weapon DPS, Hit, Expertise, Crit, Strength/AP |
| Warrior | Fury | Main/off-hand DPS, Hit, Expertise, Crit, Strength/AP |
| Warrior | Protection | Stamina, Armor, Agility, Dodge/Parry, Defense; then Expertise/Hit and threat stats |
| Paladin | Holy | Healing, Intellect, Spirit, MP5, Crit |
| Paladin | Protection | Stamina, Defense, Spell Power, Intellect, Strength; then Armor/Block/Avoidance and remaining threat stats |
| Paladin | Retribution | Weapon DPS, Hit, Expertise, Strength, Holy/Spell Power, AP/Crit |
| Hunter | Beast Mastery | Ranged Weapon DPS, Hit, Crit, Agility, Ranged AP/AP |
| Hunter | Marksmanship | Ranged Weapon DPS, Hit, Crit, Agility, Ranged AP/AP |
| Hunter | Survival | Weapon DPS, Hit, Crit, Agility, AP; the guide describes the melee build |
| Rogue | Assassination | Expertise, Hit, Agility, Weapon DPS, then Crit/AP |
| Rogue | Combat | Expertise, Hit, Agility, Weapon DPS, then Crit/AP |
| Rogue | Subtlety | Weapon DPS, Expertise, Hit, Weapon Skill, Agility, then Crit/AP |
| Priest | Discipline | Healing, MP5, Spirit, Intellect, Crit |
| Priest | Holy | Healing, Intellect, Spirit, MP5, Crit |
| Priest | Shadow | Spell Hit, Spell Power/Shadow Power, Crit/Haste, Intellect/regen |
| Shaman | Elemental | Spell Power/Nature power, Spell Hit, Crit/Haste, Intellect/regen |
| Shaman | Enhancement | Weapon DPS, Hit, Expertise, Strength, Intellect, Spell Power |
| Shaman | Restoration | Healing, Intellect, MP5, Spirit, Crit/Haste |
| Mage | Arcane | Spell Hit, Spell Power/Arcane power, Crit/Haste, Intellect/regen |
| Mage | Fire | Spell Hit, Spell Power/Fire power, Crit/Haste, Intellect/regen |
| Mage | Frost | Spell Hit, Spell Power/Frost power, Crit, Intellect/Haste |
| Warlock | Affliction | Spell Hit, Spell Power/Shadow power, Crit/Haste, Intellect |
| Warlock | Demonology | Spell Hit, Spell Power, Crit/Haste, Intellect |
| Warlock | Destruction | Spell Hit, Spell Power/Fire power, Haste/Crit, Intellect |

These are rank orders, not claims that adjacent stats have equal value. The addon retains its existing per-spec numeric score curve, then maps it to the researched order. Unusable caster inputs are excluded from pure physical specs; Enhancement and Retribution retain the documented hybrid spell stats. All item stat-weight keys in the current `Data/BiS.lua` were checked against the visible registry on this date; no unregistered weight keys were found.

## Item and UI findings

Forever client extraction build 1.60.1.70938 and the Forever UI source were used to verify the client stat APIs. The local `Data/ItemStats.lua` does not record its generation build. Staff of Jordan's baked record differs from the user's current in-game tooltip: it lacks the visible +1.5% Hit line and has different Intellect/Spirit values. Shipped data is therefore a fallback: when Forever has cached the item, Lootified prefers current client item stats and `Equip:` tooltip lines. If the client has not loaded the item, the scorer still uses the bundled snapshot.

Spec switching could leave the Dressing Room model without gear because `TryOn` was attempted before the model and item records finished loading, and the outfit signature was cached before that attempt succeeded. The page now waits for the player model and selected item data, reuses the loaded model on spec changes, and records the signature after applying the items.

Primary references for the ordering and parsing decisions are the linked Forever class guides above and the Forever UI source [PaperDollFrameStats.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua). API behavior was checked against Forever client extraction build 1.60.1.70938. Item loading and live stat behavior use the installed Forever APIs (`C_Item.GetItemStats`, `C_TooltipInfo`, `C_Item.RequestLoadItemDataByID`, and `ITEM_DATA_LOAD_RESULT`).
