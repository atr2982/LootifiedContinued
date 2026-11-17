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
