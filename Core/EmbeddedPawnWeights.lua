local _, LJ = ...
local ns = { locale = nil }

-- Default stat weights for every class and spec.
--
-- A weight is what one point of the stat is worth, relative to the spec's
-- headline stat at 1 (Strength, Agility, spell damage, healing or Stamina).
-- HIT, CRIT, EXPERTISE, HASTE, DODGE, PARRY and BLOCK are per 1%; the DPS
-- stats are per point of weapon damage-per-second.
--
-- The percentage stats, DEFENSE and WEAPON_SKILL are written at what they
-- are worth at LEVEL 60 and scaled down below that (see Scales.lua): one
-- percent of hit is one percent of what the character already does, which
-- is little at level 10 and a lot at 60.
--
-- The *_SPEED weights are per second of weapon speed and start at 0 in every
-- scale: hit damage already accounts for speed. They are there for players
-- who want a plain preference on top (positive for slow, negative for fast).
--
-- A main-hand or ranged weapon is worth DPS x its DPS weight plus average
-- hit x its hit-damage weight. The second part is for attacks that strike
-- for weapon damage (Sinister Strike, Mortal Strike, Aimed Shot...): they
-- make a slow weapon better than a fast one of the same DPS. The split is
-- sized so a weapon of typical speed is worth what the sims say per DPS;
-- how much goes to hit damage is an estimate from how often those attacks
-- are used, not a published figure.
--
-- Where they come from (researched October 2026, beta cap 30):
--   * Stat ORDER follows the published Forever beta guides - Icy Veins,
--     wow.gg, Leprestore and Warcraft Tavern - where they agree.
--   * MAGNITUDES lean on the few Forever sims that publish numbers:
--     foreverdb.net (level 30; warrior, rogue, hunter), Forever Mage Lab and
--     Forever Warlock Lab (level 60). The level 30 figures for hit and crit
--     are doubled to give the level 60 worth, which lands close to what the
--     same percentages cost in item budget.
--   * Nobody has published tested level 60 weights for Forever yet, and no
--     source has numbers for tanks, healers, paladins, shamans or druids.
--     Paladin, shaman and druid damage scales are the guides' orderings
--     turned into numbers by item budget.
--   * TANK survival stats come from effective health rather than a guide.
--     With damage reduction armor / (armor + K), one point of armor is worth
--     health / (10 * (armor + K)) stamina; one percent of dodge or parry
--     removes one percent of what gets through the other avoidance (about
--     80%), worth health / 800 stamina; a point of defense is 0.04% each of
--     dodge, parry, block, being missed and not being crit, about 0.16 of a
--     dodge percent. The tables hold the result for a level 60 tank with
--     6000 health and 6000 armor, and scales flagged `tank` are re-sized to
--     the character's own health and armor (see Scales.lua). Threat stats
--     still follow the guides. Bears are not flagged: their health and
--     armor change with form.
--   * HEALER sizes come from a mana model over a three minute fight: a
--     point of healing adds about 60 healing (72 casts at a 0.86
--     coefficient), a point of intellect 15 mana at about 2.5 healing per
--     mana, plus a little crit, a point of mp5 36 mana, and a point of
--     spirit the class's regen rate times the share its talents let through
--     while casting. One percent of crit is half a percent more healing,
--     and for paladins a refund of the spell's cost. This agrees with the
--     guides' ordering; the sizes are the model's, not a sim's.
--   * Expertise and haste are not on beta gear yet; their weights are
--     placeholders next to hit.
--   * WARLOCK health regen (HP5) is worth what mp5 is: Life Tap turns health
--     into mana at least one for one (more with spirit, per Icy Veins' Forever
--     guide), so health that comes back on its own is mana. General spell
--     damage counts in full: the same guide says a point of it does for
--     Shadow spells what a point of Shadow damage does, and helps Fire too.
--   * CASTER weapon damage changes with level, so Scales.lua sizes it the way
--     it sizes hit. A caster with no wand spends the gaps between spells
--     hitting things, which at level 1 is most of the damage it does: every
--     spell scale gets a main-hand DPS weight written at its level 1 worth
--     (one point of spell damage), which fades to nothing by level 20 and is
--     dropped the moment a wand is worn. Wand DPS is written at its level 60
--     worth; while levelling, finishing mobs with the wand is a big share of
--     a caster's damage (more so under level 20, where low-rank spells get
--     only part of their spell damage bonus), so it counts up to 2.5 times
--     as much below level 20 and comes down to the written weight at 60.
--   * ROGUE stamina (0.25) is a judgement, not a sim figure: a DPS sim gives
--     it nothing, but a rogue levels and runs dungeons in melee with no way
--     to heal itself. At 0.1, ten stamina came to less than one agility, and
--     a blue with agility and stamina lost to a green with the attack power
--     of its agility alone (Tigerstrike Mantle and Archer's Cloak of Power).
--
-- Each scale: key (saved with the player's changes - do not rename), name,
-- tab and match (talent tree position and lower-case English name, for
-- following the spec), leveling (class default before a tree is chosen),
-- weights, note.
--
-- Where a talent changes what a stat does, the table holds the weight
-- WITHOUT the talent and ns.talentWeights (below the scales) adds the rest.

local GUIDES = "Order from the Icy Veins, wow.gg, Leprestore and Warcraft Tavern beta guides (Oct 2026)"

ns.defaultScales = {
    WARRIOR = {
        {
            key = "ARMS", name = "Arms", tab = 1, match = "arms", leveling = true,
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim. Assumes a two-hander.",
            weights = {
                STRENGTH = 1, AGILITY = 0.6, STAMINA = 0.15, ATTACK_POWER = 0.5,
                HIT = 11.5, CRIT = 10.5, EXPERTISE = 12, WEAPON_SKILL = 3, HASTE = 4.5,
                MELEE_DPS = 4.2, MELEE_HIT = 0.83, OFFHAND_DPS = 1.5,
            },
        },
        {
            key = "FURY", name = "Fury", tab = 2, match = "fury",
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim, which predates the Oct 1 talent changes.",
            weights = {
                STRENGTH = 1, AGILITY = 0.65, STAMINA = 0.15, ATTACK_POWER = 0.5,
                HIT = 9, CRIT = 12, EXPERTISE = 11, WEAPON_SKILL = 3, HASTE = 6,
                MELEE_DPS = 3.4, MELEE_HIT = 0.3, OFFHAND_DPS = 2,
            },
        },
        {
            key = "PROTECTION", name = "Protection", tab = 3, match = "protection",
            tank = true,
            note = "Survival stats come from an effective-health model sized to your own health and armor, not from a "
                .. "sim; threat stats follow the guides, which disagree. See Defaults.lua.",
            weights = {
                -- the launch guides (Icy Veins, wow.gg) put expertise first for threat, and agility above strength
                STAMINA = 1, STRENGTH = 0.6, AGILITY = 0.65, ATTACK_POWER = 0.3,
                HIT = 8, CRIT = 3, EXPERTISE = 9, WEAPON_SKILL = 1.5, MELEE_DPS = 4,
                ARMOR = 0.05, DEFENSE = 1.2, DODGE = 7.5, PARRY = 7.5, BLOCK = 4, BLOCK_VALUE = 0.3, HP5 = 0.3,
            },
        },
    },

    ROGUE = {
        {
            key = "ASSASSINATION", name = "Assassination", tab = 1, match = "assassination",
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim (run with a non-dagger setup). Hit damage "
                .. "assumes Sinister Strike - lower it for a dagger build.",
            weights = {
                AGILITY = 1, STRENGTH = 0.6, STAMINA = 0.25, ATTACK_POWER = 0.57,
                HIT = 11, CRIT = 11, EXPERTISE = 11, WEAPON_SKILL = 3, HASTE = 6.5,
                MELEE_DPS = 3.6, MELEE_HIT = 0.9, OFFHAND_DPS = 2.8,
            },
        },
        {
            key = "COMBAT", name = "Combat", tab = 2, match = "combat", leveling = true,
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim.",
            weights = {
                AGILITY = 1, STRENGTH = 0.6, STAMINA = 0.25, ATTACK_POWER = 0.57,
                HIT = 9, CRIT = 10.5, EXPERTISE = 10, WEAPON_SKILL = 3, HASTE = 5,
                MELEE_DPS = 3.6, MELEE_HIT = 0.75, OFFHAND_DPS = 2.9,
            },
        },
        {
            key = "SUBTLETY", name = "Subtlety", tab = 3, match = "subtlety",
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim (run with a non-dagger setup).",
            weights = {
                AGILITY = 1, STRENGTH = 0.6, STAMINA = 0.25, ATTACK_POWER = 0.57,
                HIT = 9, CRIT = 10.5, EXPERTISE = 10, WEAPON_SKILL = 3, HASTE = 4,
                MELEE_DPS = 3.6, MELEE_HIT = 0.9, OFFHAND_DPS = 2.5,
            },
        },
    },

    HUNTER = {
        {
            key = "BEAST_MASTERY", name = "Beast Mastery", tab = 1, match = "beast", leveling = true,
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim. The ranged weapon comes first.",
            weights = {
                AGILITY = 1, INTELLECT = 0.3, STAMINA = 0.05, SPIRIT = 0.1,
                ATTACK_POWER = 0.38, RANGED_AP = 0.38, HIT = 12, CRIT = 8, HASTE = 8,
                RANGED_DPS = 3.8, RANGED_HIT = 0.5, MELEE_DPS = 0.3, OFFHAND_DPS = 0.15,
            },
        },
        {
            key = "MARKSMANSHIP", name = "Marksmanship", tab = 2, match = "marksman",
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim. Intellect rises with Careful Aim.",
            weights = {
                AGILITY = 1, INTELLECT = 0.3, STAMINA = 0.05, SPIRIT = 0.1,
                ATTACK_POWER = 0.36, RANGED_AP = 0.36, HIT = 12, CRIT = 10, HASTE = 4.5,
                RANGED_DPS = 3.4, RANGED_HIT = 0.55, MELEE_DPS = 0.3, OFFHAND_DPS = 0.15,
            },
        },
        {
            key = "SURVIVAL", name = "Survival (melee)", tab = 3, match = "survival",
            note = GUIDES .. "; sizes from the foreverdb.net level 30 sim. Two-hander versus dual wield is unsettled.",
            weights = {
                AGILITY = 1, STRENGTH = 0.58, INTELLECT = 0.15, STAMINA = 0.1,
                ATTACK_POWER = 0.55, RANGED_AP = 0.1, HIT = 12, CRIT = 11, EXPERTISE = 11, WEAPON_SKILL = 3, HASTE = 7,
                MELEE_DPS = 6, MELEE_HIT = 0.45, OFFHAND_DPS = 2.5, RANGED_DPS = 1,
            },
        },
    },

    MAGE = {
        {
            key = "ARCANE", name = "Arcane", tab = 1, match = "arcane",
            note = GUIDES .. "; sizes from the Forever Mage Lab level 60 sim. Intellect rises with Arcane Blast.",
            weights = {
                -- the guides' level 60 Arcane build does a little over a third of its damage with Fire spells
                SPELL_DAMAGE = 1, ARCANE_DAMAGE = 0.6, FIRE_DAMAGE = 0.4, HIT = 15, CRIT = 10.5, HASTE = 6.5,
                INTELLECT = 0.45, SPIRIT = 0.25, MP5 = 0.4, STAMINA = 0.1, SPELL_PEN = 0.1, SPELL_PIERCE = 1.5, RANGED_DPS = 1,
            },
        },
        {
            key = "FIRE", name = "Fire", tab = 2, match = "fire",
            note = GUIDES .. "; sizes from the Forever Mage Lab level 60 sim. Fire is the mana-hungry spec, so regen "
                .. "counts for more.",
            weights = {
                SPELL_DAMAGE = 1, FIRE_DAMAGE = 0.9, ARCANE_DAMAGE = 0.1, HIT = 14, CRIT = 11, HASTE = 5,
                INTELLECT = 0.4, SPIRIT = 0.2, MP5 = 0.35, STAMINA = 0.1, SPELL_PEN = 0.1, SPELL_PIERCE = 1.5, RANGED_DPS = 1,
            },
        },
        {
            key = "FROST", name = "Frost", tab = 3, match = "frost", leveling = true,
            note = GUIDES .. "; sizes from the Forever Mage Lab level 60 sim.",
            weights = {
                SPELL_DAMAGE = 1, FROST_DAMAGE = 0.9, ARCANE_DAMAGE = 0.1, HIT = 15, CRIT = 9, HASTE = 10,
                INTELLECT = 0.3, SPIRIT = 0.15, MP5 = 0.3, STAMINA = 0.15, SPELL_PEN = 0.1, SPELL_PIERCE = 1.5, RANGED_DPS = 1,
            },
        },
    },

    WARLOCK = {
        {
            key = "AFFLICTION", name = "Affliction", tab = 1, match = "affliction", leveling = true,
            note = GUIDES .. "; hit and crit from the Forever Warlock Lab level 60 sim. Spirit feeds Life Tap.",
            weights = {
                SPELL_DAMAGE = 1, SHADOW_DAMAGE = 1, HIT = 7, CRIT = 10, HASTE = 2.5,
                INTELLECT = 0.25, SPIRIT = 0.25, STAMINA = 0.35, MP5 = 0.15, HP5 = 0.15, SPELL_PEN = 0.1, SPELL_PIERCE = 0.5,
                RANGED_DPS = 0.8,
            },
        },
        {
            key = "DEMONOLOGY", name = "Demonology", tab = 2, match = "demonology",
            note = GUIDES .. "; hit and crit from the Forever Warlock Lab level 60 sim. Pet scaling is unpublished.",
            weights = {
                SPELL_DAMAGE = 1, SHADOW_DAMAGE = 0.8, FIRE_DAMAGE = 0.2, HIT = 12.5, CRIT = 9.5, HASTE = 7,
                INTELLECT = 0.4, SPIRIT = 0.2, STAMINA = 0.3, MP5 = 0.25, HP5 = 0.25, SPELL_PEN = 0.1, SPELL_PIERCE = 1.5,
                RANGED_DPS = 0.8,
            },
        },
        {
            key = "DESTRUCTION", name = "Destruction", tab = 3, match = "destruction",
            note = GUIDES .. "; hit and crit from the Forever Warlock Lab level 60 sim. Shadow and fire damage are "
                .. "split evenly - shift them to match your build.",
            weights = {
                SPELL_DAMAGE = 1, SHADOW_DAMAGE = 0.5, FIRE_DAMAGE = 0.5, HIT = 12, CRIT = 9, HASTE = 8.5,
                INTELLECT = 0.35, SPIRIT = 0.15, STAMINA = 0.3, MP5 = 0.25, HP5 = 0.25, SPELL_PEN = 0.1, SPELL_PIERCE = 1.5,
                RANGED_DPS = 0.8,
            },
        },
    },

    PRIEST = {
        {
            key = "DISCIPLINE", name = "Discipline", tab = 1, match = "discipline",
            note = GUIDES .. ". Sizes from a mana model (a 3 minute fight; see Defaults.lua), not a sim.",
            weights = {
                HEALING = 1, MP5 = 3, SPIRIT = 0.95, INTELLECT = 1.1, CRIT = 10, HASTE = 8, STAMINA = 0.2,
                RANGED_DPS = 0.3,
            },
        },
        {
            key = "HOLY", name = "Holy", tab = 2, match = "holy",
            note = GUIDES .. ". Sizes from a mana model (a 3 minute fight; see Defaults.lua), not a sim; spirit rises with Spiritual Guidance.",
            weights = {
                HEALING = 1, MP5 = 3, SPIRIT = 1.05, INTELLECT = 1, CRIT = 9, HASTE = 8, STAMINA = 0.2,
                RANGED_DPS = 0.3,
            },
        },
        {
            key = "SHADOW", name = "Shadow", tab = 3, match = "shadow", leveling = true,
            note = GUIDES .. ". No sim publishes priest numbers; hit and crit are sized like the other casters.",
            weights = {
                SPELL_DAMAGE = 1, SHADOW_DAMAGE = 1, HIT = 12, CRIT = 11, HASTE = 6,
                INTELLECT = 0.3, SPIRIT = 0.15, MP5 = 0.3, STAMINA = 0.15, SPELL_PEN = 0.1, SPELL_PIERCE = 1.5, RANGED_DPS = 1,
            },
        },
        {
            key = "SMITE", name = "Smite", -- a damage build with no tree of its own: picked by hand
            note = "Low confidence: one source (Warcraft Tavern) and an unproven build. Holy Precision should cover "
                .. "most of the hit.",
            weights = {
                SPELL_DAMAGE = 1, HOLY_DAMAGE = 0.85, SHADOW_DAMAGE = 0.15, HIT = 3, CRIT = 6, HASTE = 9,
                INTELLECT = 0.35, SPIRIT = 0.2, MP5 = 0.35, STAMINA = 0.15, SPELL_PIERCE = 1.5, RANGED_DPS = 1,
            },
        },
    },

    PALADIN = {
        {
            key = "HOLY", name = "Holy", tab = 1, match = "holy",
            note = GUIDES .. ". Sizes from a mana model (a 3 minute fight; see Defaults.lua), not a sim; crit counts Illumination.",
            weights = {
                HEALING = 1, INTELLECT = 1.2, MP5 = 3, CRIT = 11, HASTE = 8, SPIRIT = 0.5, STAMINA = 0.2,
            },
        },
        {
            key = "PROTECTION", name = "Protection", tab = 2, match = "protection",
            tank = true,
            note = "Survival stats come from an effective-health model sized to your own health and armor, not from a "
                .. "sim; threat stats follow the guides, which disagree. See Defaults.lua.",
            weights = {
                STAMINA = 1, STRENGTH = 0.5, AGILITY = 0.4, INTELLECT = 0.2, ATTACK_POWER = 0.2,
                SPELL_DAMAGE = 0.5, HOLY_DAMAGE = 0.5, HIT = 8, CRIT = 3, EXPERTISE = 7, MELEE_DPS = 3,
                ARMOR = 0.05, DEFENSE = 1.2, DODGE = 7.5, PARRY = 7.5, BLOCK = 5, BLOCK_VALUE = 0.4, MP5 = 0.5, HP5 = 0.3,
            },
        },
        {
            key = "RETRIBUTION", name = "Retribution", tab = 3, match = "retribution", leveling = true,
            note = GUIDES .. ". The guides disagree on spell power versus strength; both count here. Assumes a two-hander; "
                .. "intellect rises with Champion of the Light.",
            weights = {
                STRENGTH = 1, AGILITY = 0.6, INTELLECT = 0.2, STAMINA = 0.15, SPIRIT = 0.05, ATTACK_POWER = 0.45,
                SPELL_DAMAGE = 0.5, HOLY_DAMAGE = 0.45, HIT = 13, CRIT = 12, EXPERTISE = 12, WEAPON_SKILL = 3, HASTE = 8,
                MELEE_DPS = 4.7, MELEE_HIT = 0.4, MP5 = 0.3,
            },
        },
    },

    SHAMAN = {
        {
            key = "ELEMENTAL", name = "Elemental", tab = 1, match = "elemental",
            note = GUIDES .. ". The guides disagree on where crit sits. No sim publishes shaman numbers.",
            weights = {
                SPELL_DAMAGE = 1, NATURE_DAMAGE = 0.9, FIRE_DAMAGE = 0.1, HIT = 9.5, CRIT = 8, HASTE = 8,
                INTELLECT = 0.4, SPIRIT = 0.2, MP5 = 0.5, STAMINA = 0.15, SPELL_PEN = 0.1, SPELL_PIERCE = 1.8,
            },
        },
        {
            key = "ENHANCEMENT", name = "Enhancement", tab = 2, match = "enhancement", leveling = true,
            note = GUIDES .. ". Two-handed (no dual wield in Forever); intellect rises with Mental Dexterity.",
            weights = {
                STRENGTH = 1, INTELLECT = 0.25, AGILITY = 0.6, STAMINA = 0.15, SPIRIT = 0.1, ATTACK_POWER = 0.5,
                SPELL_DAMAGE = 0.35, HIT = 13, CRIT = 12, EXPERTISE = 12, WEAPON_SKILL = 3, HASTE = 8,
                MELEE_DPS = 4.6, MELEE_HIT = 0.55, MP5 = 0.3,
            },
        },
        {
            key = "RESTORATION", name = "Restoration", tab = 3, match = "restoration",
            note = GUIDES .. ". Sizes from a mana model (a 3 minute fight; see Defaults.lua), not a sim; intellect rises with Mental Quickness.",
            weights = {
                HEALING = 1, INTELLECT = 1, MP5 = 3, SPIRIT = 0.7, CRIT = 9, HASTE = 8, STAMINA = 0.2,
            },
        },
    },

    DRUID = {
        {
            key = "BALANCE", name = "Balance", tab = 1, match = "balance",
            note = GUIDES .. ". Crit versus haste is unsolved. No sim publishes druid numbers.",
            weights = {
                SPELL_DAMAGE = 1, ARCANE_DAMAGE = 0.7, NATURE_DAMAGE = 0.3, HIT = 9.5, CRIT = 8, HASTE = 7,
                INTELLECT = 0.3, SPIRIT = 0.25, MP5 = 0.5, STAMINA = 0.15, SPELL_PEN = 0.1, SPELL_PIERCE = 2,
            },
        },
        {
            key = "FERAL_CAT", name = "Feral (Cat)", tab = 2, match = "feral", leveling = true,
            swing = 1,
            note = GUIDES .. ". Weapon damage now carries into forms, so the weapon counts.",
            weights = {
                STRENGTH = 1, AGILITY = 1.1, STAMINA = 0.15, SPIRIT = 0.1, INTELLECT = 0.1,
                ATTACK_POWER = 0.42, FERAL_AP = 0.42, HIT = 11, CRIT = 12, EXPERTISE = 9, HASTE = 6.5,
                MELEE_DPS = 4,
            },
        },
        {
            key = "FERAL_BEAR", name = "Feral (Bear)", -- shares the Feral tree with Cat: picked by hand
            swing = 2.5,
            note = "Low confidence: no strong source publishes an ordered bear list. Survival first, then threat.",
            weights = {
                STAMINA = 1, AGILITY = 0.5, STRENGTH = 0.5, ATTACK_POWER = 0.25, FERAL_AP = 0.25,
                HIT = 8, CRIT = 4, EXPERTISE = 12, MELEE_DPS = 3.1,
                ARMOR = 0.15, DEFENSE = 1, DODGE = 6, HP5 = 0.3,
            },
        },
        {
            key = "RESTORATION", name = "Restoration", tab = 3, match = "restoration",
            note = GUIDES .. ". Sizes from a mana model (a 3 minute fight; see Defaults.lua), not a sim; spirit rises with Living Spirit.",
            weights = {
                HEALING = 1, SPIRIT = 1.05, INTELLECT = 0.9, MP5 = 3, CRIT = 7, HASTE = 6, STAMINA = 0.2,
            },
        },
    },
}

-- What talents add to the weights above, at full rank; fewer ranks add in
-- proportion. Talents are found by their lower-case English name (a client
-- in another language needs its names for them: see Locale.lua), and the
-- amounts are per scale key.
ns.talentWeights = {
    MAGE = {
        -- each cast gives 12% of intellect as spell damage, stacking to 48%
        -- for 18 sec (Icy Veins); held near full stacks, less the ramp up
        { talent = "arcane blast", ranks = 1, add = { ARCANE = { INTELLECT = 0.45 } } },
        -- 10% more intellect at 5/5, on top of what intellect is worth to Arcane with the above
        { talent = "arcane mind", ranks = 5, add = { ARCANE = { INTELLECT = 0.09 } } },
    },
    SHAMAN = {
        -- attack power equal to 33/66/100% of intellect (Nov 10; 50/100/150% for the week after launch):
        -- 1 AP is half a strength, and both sims put intellect near 0.85 of a strength with it
        { talent = "mental dexterity", ranks = 3, add = { ENHANCEMENT = { INTELLECT = 0.5 } } },
        -- spell damage and healing equal to 15/30% of intellect
        { talent = "mental quickness", ranks = 2, add = {
            ELEMENTAL = { INTELLECT = 0.3 }, RESTORATION = { INTELLECT = 0.3 }, ENHANCEMENT = { INTELLECT = 0.1 },
        } },
    },
    HUNTER = {
        -- attack power equal to 20-100% of intellect, at each scale's attack power weight
        { talent = "careful aim", ranks = 5, add = {
            BEAST_MASTERY = { INTELLECT = 0.38 }, MARKSMANSHIP = { INTELLECT = 0.36 }, SURVIVAL = { INTELLECT = 0.55 },
        } },
    },
    PALADIN = {
        -- spell damage equal to 12/24/36/48/60% of intellect (not healing), at each scale's spell damage weight
        { talent = "champion of the light", ranks = 5, add = {
            RETRIBUTION = { INTELLECT = 0.3 }, PROTECTION = { INTELLECT = 0.3 },
        } },
        -- the critical healing bonus of Holy spells up by 10-50%: at 5/5 a crit heals for 225% rather than 150%,
        -- which more than doubles what one percent of crit adds
        { talent = "holy power", ranks = 5, add = { HOLY = { CRIT = 12 } } },
    },
    PRIEST = {
        -- healing equal to 25% of spirit at 5/5, and a third of that as damage
        { talent = "spiritual guidance", ranks = 5, add = {
            HOLY = { SPIRIT = 0.25 }, DISCIPLINE = { SPIRIT = 0.25 }, SHADOW = { SPIRIT = 0.08 }, SMITE = { SPIRIT = 0.08 },
        } },
        -- 10% more intellect at 5/5 (second row of Discipline since Oct 15), at each scale's intellect weight
        { talent = "mental strength", ranks = 5, add = {
            DISCIPLINE = { INTELLECT = 0.11 }, HOLY = { INTELLECT = 0.1 }, SHADOW = { INTELLECT = 0.03 }, SMITE = { INTELLECT = 0.03 },
        } },
    },
    DRUID = {
        -- 15% more spirit at 3/3
        { talent = "living spirit", ranks = 3, add = { RESTORATION = { SPIRIT = 0.15 } } },
        -- an expiring Rejuvenation or Regrowth heals for 100% of spirit: a judgement of how much of that lands
        { talent = "bloom", ranks = 1, add = { RESTORATION = { SPIRIT = 0.3 } } },
        -- healing equal to 25% of intellect, at 2/2 (a Feral talent: hybrids only)
        { talent = "natural instinct", ranks = 2, add = { RESTORATION = { INTELLECT = 0.25 } } },
    },
}

-- Baselines for every scale that does not set its own value.
--
-- Gear below level 10 or so has nothing on it but armor, so a scale that
-- ignored armor outright would have no opinion on it at all. A token weight
-- (100 armor to one point of the headline stat) is enough to rank two plain
-- pieces without a bare shield outweighing real stats later. Likewise the
-- thrown or ranged weapon of a class that only pulls with it.
--
-- spell: the scale is built on spell damage or healing. Its percentage
-- stats grow faster with level than a weapon user's, and its weapon damage
-- counts by level and by whether a wand is worn (see Scales.lua).
--
-- The names and notes above are the English ones. The client's language
-- may bring its own, by class and scale key, and the name its talent tree
-- goes by there (see Locale.lua); the key and the weights stay as they are.
local translated = ns.locale and ns.locale.scales or {}

for class, list in pairs(ns.defaultScales) do
    for _, scale in ipairs(list) do
        local own = translated[class] and translated[class][scale.key]
        if own then
            scale.name, scale.note, scale.localMatch = own.name or scale.name, own.note or scale.note, own.match
        end
        local weights = scale.weights
        weights.ARMOR = weights.ARMOR or 0.01
        scale.spell = weights.SPELL_DAMAGE == 1 or weights.HEALING == 1
        if scale.spell then
            weights.MELEE_DPS = weights.MELEE_DPS or 1 -- its level 1 worth; see CASTER above
        end
        if class == "WARRIOR" or class == "ROGUE" then
            weights.RANGED_DPS = weights.RANGED_DPS or 0.2
        end
    end
end

-- Embedded from the installed PawnForever 1.7.1 defaults. Lootified owns this copy and has no PawnForever runtime dependency.
LJ.EmbeddedPawnWeights = { scales = ns.defaultScales, talentWeights = ns.talentWeights }
