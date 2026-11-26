## 1.2.0.30 — 2026-11-25

- Remove beta and Classic loot-status notes from dungeon Journal hover cards.

## 1.2.0.29 — 2026-11-25

- Avoid calculating a loot-roll upgrade verdict twice when a group-loot prompt appears, reducing synchronous scoring work on the popup.

## 1.2.0.28 — 2026-11-25

- Use one consistent percent-based gear scorer across Best in Slot, For You, Journal, item lists, and tooltips, with correct replacement-slot and paired-weapon comparisons.
- Keep Best in Slot items and the character preview synchronized with the selected spec, equipped set, armor filters, loot sources, and drop-chance filter.
- Fix upgrade results and counts across Journal and For You, and stop background item-data events and mouseovers from repeatedly rebuilding or reordering those pages.
- Apply class and equipment eligibility consistently so suggestions do not include gear the character cannot use.
- Add `/lf levels` to capture the live dungeon-finder ranges, and correct dungeon level ranges from the captured Forever client data.
- Refresh the packaged Forever item, quest, NPC, and dungeon data from client build 1.60.1.71139 and the ForeverDB 1.60.1.71091 snapshot; update enabled locale packs for new strings.
- Remove the unused external Best in Slot feed from the addon and refresh utilities.

## 1.2.0.27 — 2026-11-23

- Refresh dungeon Journal upgrade badges and item rows when Forever item data finishes loading, and clear stale comparison results when Lootified closes.

## 1.2.0.26 — 2026-11-23

- Prevent tooltips from marking gear as an upgrade when the character's class cannot equip that item type.

## 1.2.0.25 — 2026-11-23

- Translate the newly added Krol'dok quest names, objectives, and giver locations in Russian.
- Translate quest-giver names from locale dictionaries even when Forever quest records have no NPC ID.

## 1.2.0.24 — 2026-11-22

- Gate Onyxia's Lair, Barrow Deeps, and Hyjal Summit gear from active Best in Slot and upgrade recommendations until their announced December 9 opening, using the in-game calendar and refreshing cached results when availability changes.
- Exclude Naxxramas-only tier and Atiesh quest rewards, plus Naxxramas placeholder items, while keeping future/reference data available for browsing.
- Keep dungeon access independent from loot-data confidence labels so currently available dungeons remain eligible.
## 1.2.0.23 — 2026-11-21

- Keep item upgrade percentages consistent across tooltips, Best in Slot, Journal, Open World, and item pickers by comparing each item with the gear it replaces.
- Show every positive weighted upgrade, including small gains, and format sub-0.1% results clearly.

## 1.2.0.22 — 2026-11-21

- Make Lootified's percent-based gear scoring standalone with embedded stat scales and upgrade evaluation.
- Use consistent percent-based upgrade results in item tooltips, Best in Slot, Open World, and Journal views, including when the best item is already equipped.
- Keep dungeon quest lists focused on actual dungeon quests while preserving their prerequisite chains; audit all current dungeon mappings and correct missing quest records, faction assignments, and misclassified dungeon quests.
- Correct dungeon quest placements and data, including Blackrock Depths, Dire Maul West, Scholomance, Blackmaw Hold, Wailing Caverns, and Zul'Farrak.

## 1.2.0.21 — 2026-11-21

- Use selected-spec scoring and upgrade verdicts for Lootified's gear comparisons, and remove the obsolete stat-priority page and controls.
- Keep above-level item comparisons available while respecting class and Feral gear eligibility; exclude caster-effect items from Cat and Bear recommendations and show only relics that benefit the selected Feral spec.
- Include eligible equipped gear in Best in Slot rankings so the currently worn best item is correctly identified.
- Remove healer damage pseudo-specs from Lootified.
- Exclude ForeverDB items marked speculative from obtainable gear lists when no verified source is recorded.
## 1.2.0.20 — 2026-11-20

- Fixed dungeon quest-chain missing counts so available or in-progress earlier quests are not counted as missing.
- Restored the Krol'dok Stronghold prerequisite steps in quest chains, including the shared Horde chain for Eye of Mugg, Tome of Twilight, and A Token of Vengeance.
- Added verified Riverglades map buttons for Krol'dok quest givers and turn-ins, including Da'grosh, Krom'rosh, Tran'gul, Kreza Darkthorn, Crag'rog, and Clugfist.

## 1.2.0.19 — 2026-11-20

- Show Open World drops as indented item rows beneath collapsible mob and rare rows. Rows start collapsed, show the drop count and a larger chevron, and keep the map action visible.
- Fix Open World upgrade filtering so known mob drops are compared directly against equipped gear, regardless of character level or the generic loot-list drop-chance threshold.
- Show percent-based tooltip comparisons for gear above the character's level while retaining armor-training and class usability restrictions.
- Enable the packaged German, Spanish, French, Korean, Portuguese, Russian, and Chinese translations. Korean and Chinese choices appear only in matching game-client locales.

## 1.2.0.18 — 2026-11-17

- Fixed class-locked quest rewards appearing in Best in Slot for classes that cannot obtain them, including when an empty slot triggers the fallback item search. Items with another recorded source remain eligible.
- Correctly read class restrictions from ForeverDB quest categories for all nine classes, and carry the restriction to matching same-title faction quest variants when their reward overlaps.
- Separate dungeon quests that are unavailable because of class or faction, so players can see why those quests do not apply to their character.
- Refreshed collected item and quest data from Forever client build 1.60.1.70959, updated the packaged ForeverDB catalog snapshot, and refreshed dungeon notable-loot picks.

## 1.2.0.17 — 2026-11-17

- Fixed the Open World and dungeon quest views failing when they checked quests added by the late-loaded ForeverDB catalog. Quest IDs and reverse indexes are now built again after all data sources load, and invalid IDs are kept out of the Forever completion API.
- Added and corrected quest-chain, faction, prerequisite, and quest-location data for the newly available dungeons, including the missing chain steps needed to track quests across instance pages.

## 1.2.0.16 — 2026-11-16

- Removed runtime date lookups from packaged data files; refresh tools now write the date when generating data so Forever's addon sandbox does not abort data loading.
- Updated the data refresh generators to keep future ForeverDB refreshes compatible with the Forever addon sandbox.

## 1.2.0.15 — 2026-11-16

- Dungeon cards now count only quests your character can still do, hiding the quest badge when all eligible quests are complete.
- Corrected Hall of Thanes' Important Heirlooms quest to be available to both factions, so Horde characters can track it too.

## 1.2.0.14 — 2026-11-16

- Updated item, quest, NPC, and dungeon catalog data for Forever client build 1.60.1.70938.
- Refreshed the ForeverDB item catalog and dungeon details; retained reviewed guide data when its source was unavailable.
- Fixed data version reporting so the current client collection is not replaced by an older curated override.

## 1.2.0.13

- Match dungeon and boss upgrade counts and loot-row badges to the live item percent comparison.
- Include useful drops from higher-level dungeons while continuing to apply class, armor, source, ownership, and profession filters.

## 1.2.0.12

- Show dungeon and raid upgrade counts on cards at every level, using the same upgrade rows counted inside the instance.
- Show the total number of quests for the character on each card, including quests that are not currently open.

## 1.2.0.11

- Added verified quest giver and turn-in details for quests in Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, Shaper's Terrace, City of Dalaran, and Excavation Site. Giver names now appear with their locations, and missing location rows stay hidden.
- Added boss, rare, trash, and loot information for newly opened dungeons, plus the newly available dungeon items.
- Updated the Hyjal Summit opening date shown in the dungeon journal.

## 1.2.0.10 — 2026-11-15

- Fixed startup errors in Forever by using the client-supported date function for Lootified data timestamps.

# Lootified

## 1.2.0.9 — 2026-11-14

- Fixed dungeon overview upgrade counts so they match eligible item rows in each dungeon.
- Show upgrade percentages consistently for scorable loot, including low positive upgrades.
- Make Best in Slot armor and source filters apply immediately to recommendations and prevent excluded armor types from appearing as upgrades.
- Set ordered default stat priorities for every class spec, using the author's configured Druid order and researched starting orders for the other specs.
## 1.2.0.8 — 2026-11-14

- Fixed filtered-out armor appearing as a `0.0%` Journal upgrade when legacy saved scoring data was present.
- Made Percent scoring the only active upgrade source across Journal, Best in Slot, For You, tooltips, and next-upgrade lists.
- Kept future-item percentage previews in the Database view separate from current filtered upgrade recommendations.

## 1.2.0.7 — 2026-11-13

- Added percent upgrade and downgrade ratings throughout the database item view, including future-level items and class-usable but untrained weapons.
- Added percent ratings for every scorable item instead of hiding the value because of the item's required level.
- Corrected Forever class weapon eligibility so class-usable weapons are not incorrectly marked as unusable.
- Removed retired quest tooltip lines, wishlist controls, custom set controls, and simulator wording from the active interface.
- Kept database navigation, item details, mob details, places, and main-view navigation working after the UI cleanup.
- Added the latest Forever-specific quest and data corrections, including City of Dalaran quest giver details.
