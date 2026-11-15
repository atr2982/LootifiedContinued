## Unreleased

- Fixed Lootified startup errors caused by using the unavailable os.date library in Forever; data dates now use the client's supported date() function.

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
