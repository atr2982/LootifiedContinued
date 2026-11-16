-- Lootified - one researched, spec-specific stat order drives both the Stat priority panel and Percent scoring.
-- The displayed bars are the relative values used by the scorer, so a lower row can never silently count more.
local _, LJ = ...

local StatPrio = {}
LJ.StatPrio = StatPrio

local Player = LJ.Player
local Scoring = LJ.Scoring

-- Typical item amounts are used only to put different units on the same visual/score scale. Each spec's existing
-- weight curve is retained; the researched order assigns that curve from highest to lowest priority per spec.
StatPrio.STATS = {
    { key = "Strength", text = "Strength", typical = 13 },
    { key = "Agility", text = "Agility", typical = 13 },
    { key = "Stamina", text = "Stamina", typical = 13 },
    { key = "Intellect", text = "Intellect", typical = 13 },
    { key = "Spirit", text = "Spirit", typical = 13 },
    { key = "AttackPower", text = "Attack Power", typical = 26 },
    { key = "RangedAttackPower", text = "Ranged Attack Power", typical = 32.5 },
    { key = "WeaponDPS", text = "Weapon DPS", typical = 1 },
    { key = "OffHandWeaponDPS", text = "Off-hand Weapon DPS", typical = 1 },
    { key = "RangedWeaponDPS", text = "Ranged Weapon DPS", typical = 1 },
    { key = "SpellPower", text = "Spell Power", typical = 15 },
    { key = "Healing", text = "Healing", typical = 29 },
    { key = "ShadowPower", text = "Shadow Spell Power", typical = 26 },
    { key = "FirePower", text = "Fire Spell Power", typical = 26 },
    { key = "FrostPower", text = "Frost Spell Power", typical = 26 },
    { key = "NaturePower", text = "Nature Spell Power", typical = 26 },
    { key = "ArcanePower", text = "Arcane Spell Power", typical = 26 },
    { key = "HolyPower", text = "Holy Spell Power", typical = 26 },
    { key = "Hit", text = "Hit Rating", typical = 13, weights = { Hit = "HIT_MELEE", SpellHit = "HIT_SPELL" } },
    { key = "Crit", text = "Critical Strike Rating", typical = 13, weights = { Crit = "CRIT_MELEE", SpellCrit = "CRIT_SPELL" } },
    { key = "Haste", text = "Haste Rating", typical = 13, weights = { Haste = "HASTE" } },
    { key = "Expertise", text = "Expertise Rating", typical = 13, weights = { Expertise = "EXPERTISE" } },
    { key = "WeaponSkill", text = "Weapon Skill", typical = 1, weights = { WeaponSkill = "WEAPON_SKILL" } },
    { key = "MP5", text = "Mana per 5 sec.", typical = 5.2 },
    { key = "Defense", text = "Defense", typical = 10 },
    { key = "Dodge", text = "Dodge Rating", typical = 13, weights = { Dodge = "DODGE" } },
    { key = "Parry", text = "Parry Rating", typical = 13, weights = { Parry = "PARRY" } },
    { key = "Block", text = "Block Rating", typical = 13, weights = { Block = "BLOCK" } },
    { key = "BlockValue", text = "Block Value", typical = 17 },
    { key = "Armor", text = "Armor", typical = 183 },
}

local WEAPON = { WeaponDPS = true, OffHandWeaponDPS = true, RangedWeaponDPS = true }

-- Forever-focused PvE guide priorities. Weapon DPS remains a separate weapon score; hit/expertise caps, role, and
-- healing/threat/mitigation goals are reflected in the order where the spec's item model supports those stats.
-- Sources are noted in the repository documentation; when a guide gives separate tank threat and mitigation lists,
-- Bear and Protection use a practical combined leveling/gearing order with survivability first.
local PRIORITY = {
    WARRIOR = {
        ARMS = { "WeaponDPS", "Hit", "Expertise", "Crit", "Strength", "AttackPower", "Agility", "Haste", "Stamina" },
        FURY = { "WeaponDPS", "OffHandWeaponDPS", "Hit", "Expertise", "Crit", "Strength", "AttackPower", "Agility", "Haste", "Stamina" },
        PROT = { "Stamina", "Armor", "Agility", "Dodge", "Parry", "Defense", "Expertise", "Hit", "Strength", "WeaponDPS", "AttackPower", "BlockValue", "Block", "Crit", "Haste" },
    },
    PALADIN = {
        HOLY = { "Healing", "Intellect", "Spirit", "MP5", "Crit", "Haste", "SpellPower", "HolyPower", "Stamina", "Armor", "Agility" },
        PROT = { "Stamina", "Defense", "SpellPower", "Intellect", "Strength", "Armor", "Block", "BlockValue", "Dodge", "Parry", "WeaponDPS", "Hit", "HolyPower", "Expertise", "Crit", "Haste" },
        RET = { "WeaponDPS", "Hit", "Expertise", "Strength", "SpellPower", "HolyPower", "AttackPower", "Crit", "Agility", "Intellect", "Stamina", "Haste", "Spirit", "MP5" },
        HOLY_DMG = { "WeaponDPS", "Hit", "SpellPower", "HolyPower", "Crit", "Intellect", "Strength", "AttackPower", "Expertise", "Agility", "Stamina", "Spirit", "MP5" },
    },
    HUNTER = {
        BM = { "RangedWeaponDPS", "Hit", "Crit", "Agility", "RangedAttackPower", "AttackPower", "Intellect", "Stamina", "Spirit", "MP5" },
        MM = { "RangedWeaponDPS", "Hit", "Crit", "Agility", "RangedAttackPower", "AttackPower", "Intellect", "Stamina", "Spirit", "MP5" },
        SV = { "WeaponDPS", "OffHandWeaponDPS", "RangedWeaponDPS", "Hit", "Crit", "Agility", "RangedAttackPower", "AttackPower", "Strength", "Intellect", "Stamina", "Spirit", "MP5" },
    },
    ROGUE = {
        ASSA = { "Expertise", "Hit", "Agility", "WeaponDPS", "OffHandWeaponDPS", "Crit", "AttackPower", "Strength", "Haste", "Stamina" },
        COMBAT = { "Expertise", "Hit", "Agility", "WeaponDPS", "OffHandWeaponDPS", "Crit", "AttackPower", "Strength", "Haste", "Stamina" },
        SUB = { "WeaponDPS", "OffHandWeaponDPS", "Expertise", "Hit", "WeaponSkill", "Agility", "Crit", "AttackPower", "Strength", "Haste", "Stamina" },
    },
    PRIEST = {
        DISC = { "Healing", "MP5", "Spirit", "Intellect", "Crit", "SpellPower", "ShadowPower", "Stamina" },
        HOLY = { "Healing", "Intellect", "Spirit", "MP5", "Crit", "SpellPower", "Stamina" },
        SHADOW = { "Hit", "SpellPower", "ShadowPower", "Crit", "Haste", "Intellect", "Spirit", "MP5", "Stamina" },
        DISC_DMG = { "Hit", "SpellPower", "ShadowPower", "Crit", "Haste", "Intellect", "Spirit", "MP5", "Stamina" },
        HOLY_DMG = { "Hit", "SpellPower", "HolyPower", "Crit", "Haste", "Intellect", "Spirit", "MP5", "Stamina" },
    },
    SHAMAN = {
        ELE = { "SpellPower", "NaturePower", "FirePower", "FrostPower", "Hit", "Crit", "Haste", "Intellect", "MP5", "Spirit", "Stamina" },
        ENH = { "WeaponDPS", "Hit", "Expertise", "Strength", "Intellect", "SpellPower", "AttackPower", "Crit", "Agility", "Stamina", "Spirit", "MP5" },
        RESTO = { "Healing", "Intellect", "MP5", "Spirit", "Crit", "Haste", "SpellPower", "Stamina" },
    },
    MAGE = {
        ARCANE = { "Hit", "SpellPower", "ArcanePower", "Crit", "Haste", "Intellect", "MP5", "Spirit", "Stamina" },
        FIRE = { "Hit", "SpellPower", "FirePower", "Crit", "Haste", "Intellect", "Spirit", "MP5", "Stamina" },
        FROST = { "Hit", "SpellPower", "FrostPower", "ArcanePower", "Crit", "Intellect", "Haste", "MP5", "Spirit", "Stamina" },
    },
    WARLOCK = {
        AFFLI = { "Hit", "SpellPower", "ShadowPower", "Crit", "Haste", "Intellect", "Spirit", "Stamina", "FirePower" },
        DEMO = { "Hit", "SpellPower", "ShadowPower", "Crit", "Haste", "Intellect", "Spirit", "Stamina", "FirePower" },
        DESTRO = { "Hit", "SpellPower", "FirePower", "Haste", "Crit", "Intellect", "Spirit", "Stamina", "ShadowPower" },
    },
    DRUID = {
        CAT = { "WeaponDPS", "Expertise", "Hit", "Agility", "Strength", "Crit", "AttackPower", "Stamina", "Armor", "Intellect", "Spirit", "MP5" },
        BEAR = { "Armor", "Defense", "Stamina", "WeaponDPS", "Expertise", "Hit", "Agility", "Dodge", "Crit", "Strength", "AttackPower", "Spirit", "Intellect", "MP5" },
        BALANCE = { "Hit", "SpellPower", "NaturePower", "ArcanePower", "Crit", "Haste", "Intellect", "MP5", "Spirit", "Stamina", "Armor", "Agility" },
        RESTO = { "Healing", "Intellect", "MP5", "Spirit", "Crit", "Haste", "SpellPower", "Stamina", "Armor", "Agility" },
    },
}

local BY_KEY, OF_WEIGHT = {}, {}
for i, stat in ipairs(StatPrio.STATS) do
    stat.index = i
    stat.weights = stat.weights or { [stat.key] = false }
    BY_KEY[stat.key] = stat
    for weight in pairs(stat.weights) do OF_WEIGHT[weight] = stat end
end

-- A spec cannot gain useful damage from every stat present on an item. Feral Cat's Forever DPS guide has no value
-- for generic spell power; counting that line was enough to make Staff of Jordan outrank a higher-DPS feral weapon.
-- Remove inputs that the Forever spec does not use. This prevents old generic weight tables from letting caster
-- stats dominate a physical item comparison. Hybrid specs (Enhancement and Retribution) keep their documented
-- cross-school stats.
local IGNORE = {
    DRUID = {
        CAT = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
        BEAR = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
    },
    WARRIOR = {
        ARMS = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
        FURY = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
        PROT = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
    },
    ROGUE = {
        ASSA = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
        COMBAT = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
        SUB = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true,
            Intellect = true, Spirit = true, MP5 = true },
    },
    HUNTER = {
        BM = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true },
        MM = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true },
        SV = { SpellPower = true, Healing = true, ShadowPower = true, FirePower = true, FrostPower = true,
            NaturePower = true, ArcanePower = true, HolyPower = true, SpellHit = true, SpellCrit = true },
    },
}

local function InputWeights(spec)
    local weights = {}
    for key, value in pairs(spec.weights) do weights[key] = value end
    -- Subtlety's current Forever guide explicitly values weapon skill. The lightweight scorer
    -- retains the established equivalence used by its legacy item model, now exposed as its own row.
    if spec.class == "ROGUE" and spec.key == "SUB" and weights.WeaponSkill == nil then
        weights.WeaponSkill = 0.2 * (weights.Hit or 0)
    end
    local ignored = IGNORE[spec.class] and IGNORE[spec.class][spec.key]
    for key in pairs(ignored or {}) do
        local stat = BY_KEY[key]
        if stat then
            for weight in pairs(stat.weights) do weights[weight] = 0 end
        else
            weights[key] = 0
        end
    end
    return weights
end

local function Per(stat, weight)
    local cr = stat.weights[weight]
    return cr and Scoring.RATING_PER_PCT_60[cr] or 1
end

local function Value(weights, stat)
    local value = 0
    for weight in pairs(stat.weights) do
        value = value + (weights[weight] or 0) * stat.typical / Per(stat, weight)
    end
    return value
end

local function BaseRows(spec, weights)
    local rows, seen = {}, {}
    for weight, w in pairs(weights) do
        assert(OF_WEIGHT[weight] or WEAPON[weight], "stat priority: no stat for the weight " .. weight)
        -- Weapon DPS has no regular item-stat weight mapping, but it still needs a visible priority row and must
        -- participate in the same per-spec order as the other scoring inputs.
        local stat = OF_WEIGHT[weight] or (WEAPON[weight] and BY_KEY[weight])
        if stat and w > 0 and not seen[stat.key] then
            seen[stat.key] = true
            rows[#rows + 1] = { key = stat.key, value = Value(weights, stat), stat = stat }
        end
    end
    table.sort(rows, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return a.stat.index < b.stat.index
    end)
    return rows
end

-- Return a full spec-specific order: researched ranks first, then any supported leftovers by their original baseline.
local function MakeOrder(spec)
    local weights = InputWeights(spec)
    local base, byKey, order, seen = BaseRows(spec, weights), {}, {}, {}
    for _, row in ipairs(base) do byKey[row.key] = row end
    local preferred = PRIORITY[spec.class] and PRIORITY[spec.class][spec.key]
    for _, key in ipairs(preferred or {}) do
        if byKey[key] and not seen[key] then order[#order + 1], seen[key] = key, true end
    end
    for _, row in ipairs(base) do
        if not seen[row.key] then order[#order + 1], seen[row.key] = row.key, true end
    end
    return order, base, byKey, weights
end

local computed = {}

-- The source priority controls scoring, not just the labels: existing per-spec weight magnitudes are sorted and
-- assigned in the researched order, keeping their spread while making the displayed order and scorer agree.
local function Computed(spec)
    local c = computed[spec.class .. ":" .. spec.key]
    if c then return c end
    local order, base, byKey, inputWeights = MakeOrder(spec)
    c = { weights = {}, value = {}, order = order }
    for weight, value in pairs(inputWeights) do c.weights[weight] = value end
    for index, key in ipairs(order) do
        local stat, original = BY_KEY[key], byKey[key]
        local target = base[index] and base[index].value or 0
        local factor = original and original.value > 0 and target / original.value or 1
        c.value[key] = target
        if factor ~= 1 then
            for weight in pairs(stat.weights) do
                if inputWeights[weight] then c.weights[weight] = inputWeights[weight] * factor end
            end
        end
    end
    c.key = table.concat(order, ",")
    computed[spec.class .. ":" .. spec.key] = c
    return c
end

function StatPrio.DefaultOrder(spec)
    local order = Computed(spec).order
    local copy = {}
    for i, key in ipairs(order) do copy[i] = key end
    return copy
end

function StatPrio.Counts(spec)
    -- Keep the read-only priority explanation visible for the active scorer on every spec.
    return spec.class == Player.class
end

function StatPrio.Weights(spec)
    if not StatPrio.Counts(spec) then return spec.weights end
    return Computed(spec).weights
end

function StatPrio.Key(spec)
    return Computed(spec).key
end

function StatPrio.IsCustom() return false end
function StatPrio.Order(spec) return StatPrio.DefaultOrder(spec) end

function StatPrio.Rows(spec)
    local c, rows = Computed(spec), {}
    for i, key in ipairs(c.order) do
        local stat = BY_KEY[key]
        rows[i] = { key = key, text = stat.text, value = c.value[key] or 0 }
    end
    return rows
end

-- Kept as harmless compatibility shims for older UI and saved-variable migrations.
function StatPrio.Move() return false end
function StatPrio.Reset() return false end

function StatPrio.DropStale()
    computed = {}
    -- Discard legacy user multipliers: those came from the broken drag model and can invert the guide order/scoring.
    LJ.cdb.statPrio = {}
end
LJ:Listen("DB_READY", StatPrio.DropStale)
