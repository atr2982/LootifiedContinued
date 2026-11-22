-- Standalone Lootified scoring based on the PawnForever 1.5.0 scales and
-- upgrade rules. This module deliberately reads no PawnForever globals.
local _, LJ = ...

local Integration = {}
LJ.UpgradeScoring = Integration

local DATA = LJ.EmbeddedPawnWeights
local SPEC_KEYS = {
    WARRIOR = { ARMS = "ARMS", FURY = "FURY", PROT = "PROTECTION" },
    PALADIN = { HOLY = "HOLY", PROT = "PROTECTION", RET = "RETRIBUTION" },
    HUNTER = { BM = "BEAST_MASTERY", MM = "MARKSMANSHIP", SV = "SURVIVAL" },
    ROGUE = { ASSA = "ASSASSINATION", COMBAT = "COMBAT", SUB = "SUBTLETY" },
    PRIEST = { DISC = "DISCIPLINE", HOLY = "HOLY", SHADOW = "SHADOW" },
    SHAMAN = { ELE = "ELEMENTAL", ENH = "ENHANCEMENT", RESTO = "RESTORATION" },
    MAGE = { ARCANE = "ARCANE", FIRE = "FIRE", FROST = "FROST" },
    WARLOCK = { AFFLI = "AFFLICTION", DEMO = "DEMONOLOGY", DESTRO = "DESTRUCTION" },
    DRUID = { BALANCE = "BALANCE", CAT = "FERAL_CAT", BEAR = "FERAL_BEAR", RESTO = "RESTORATION" },
}
local WEIGHT_KEYS = {
    STRENGTH = "Strength", AGILITY = "Agility", STAMINA = "Stamina", INTELLECT = "Intellect", SPIRIT = "Spirit",
    ATTACK_POWER = "AttackPower", RANGED_AP = "RangedAttackPower", FERAL_AP = "FeralAttackPower",
    HIT = "Hit", CRIT = "Crit", EXPERTISE = "Expertise", WEAPON_SKILL = "WeaponSkill", HASTE = "Haste",
    MELEE_DPS = "WeaponDPS", MELEE_HIT = "WeaponHitDamage", OFFHAND_DPS = "OffHandWeaponDPS",
    RANGED_DPS = "RangedWeaponDPS", RANGED_HIT = "RangedHitDamage", SPELL_DAMAGE = "SpellPower",
    HEALING = "Healing", ARCANE_DAMAGE = "ArcanePower", FIRE_DAMAGE = "FirePower", FROST_DAMAGE = "FrostPower",
    NATURE_DAMAGE = "NaturePower", SHADOW_DAMAGE = "ShadowPower", HOLY_DAMAGE = "HolyPower", MP5 = "MP5",
    SPELL_PEN = "SpellPenetration", ARMOR = "Armor", DEFENSE = "Defense", DODGE = "Dodge", PARRY = "Parry",
    BLOCK = "Block", BLOCK_VALUE = "BlockValue", HP5 = "HP5",
}

local function FindScale(spec)
    local wanted = spec and SPEC_KEYS[spec.class] and SPEC_KEYS[spec.class][spec.key]
    local list = wanted and DATA and DATA.scales and DATA.scales[spec.class]
    if list then
        for _, scale in ipairs(list) do
            if scale.key == wanted then return scale end
        end
    end
end

function Integration.Scale(spec)
    return FindScale(spec)
end

local talentCache
local function ReadTalents()
    local traits, class = C_Traits, C_ClassTalents
    if not (traits and class and class.GetActiveConfigID and traits.GetConfigInfo) then return nil end
    local configID = class.GetActiveConfigID()
    local config = configID and traits.GetConfigInfo(configID)
    local treeID = type(config) == "table" and type(config.treeIDs) == "table" and config.treeIDs[1]
    if not treeID then return nil end

    local result = {}
    local displays = traits.GetGroupDisplayInfoByTreeID and traits.GetGroupDisplayInfoByTreeID(treeID) or {}
    local nodeIDs = traits.GetTreeNodes and traits.GetTreeNodes(treeID) or {}
    for _, nodeID in ipairs(nodeIDs) do
        local node = traits.GetNodeInfo(configID, nodeID)
        local rank = type(node) == "table" and tonumber(node.ranksPurchased) or 0
        if rank and rank > 0 then
            local entryID = type(node.activeEntry) == "table" and node.activeEntry.entryID
                or (type(node.entryIDs) == "table" and node.entryIDs[1])
            local entry = entryID and traits.GetEntryInfo(configID, entryID)
            local def = type(entry) == "table" and entry.definitionID and traits.GetDefinitionInfo(entry.definitionID)
            local name = type(def) == "table" and def.overrideName
            if not name and type(def) == "table" and def.spellID and C_Spell and C_Spell.GetSpellName then
                name = C_Spell.GetSpellName(def.spellID)
            end
            if type(name) == "string" then result[name:lower()] = rank end
        end
    end
    return result
end
local function ReadTalentsSafely()
    local ok, ranks = pcall(ReadTalents)
    return ok and type(ranks) == "table" and ranks or nil
end

local LEVEL_SCALED = { HIT = true, CRIT = true, EXPERTISE = true, HASTE = true, WEAPON_SKILL = true,
    DEFENSE = true, DODGE = true, PARRY = true, BLOCK = true }
local function PlainNumber(value)
    if LJ.Util and LJ.Util.IsSecret and LJ.Util.IsSecret(value) then return nil end
    return type(value) == "number" and value or tonumber(value)
end
local function ArmorConstant(level)
    return level < 60 and (400 + 85 * level) or 5882.5
end
local function ArmorWorth(health, armor, level)
    return health / (10 * (armor + ArmorConstant(level)))
end

local function RawWeights(scale, spec)
    local weights = {}
    for key, value in pairs(scale.weights or {}) do weights[key] = value end
    local rules = DATA and DATA.talentWeights and DATA.talentWeights[spec.class] or {}
    for _, rule in ipairs(rules) do
        local add = rule.add and rule.add[scale.key]
        local rank = talentCache and talentCache[rule.talent] or 0
        if add and rank > 0 then
            local share = math.min(rank / rule.ranks, 1)
            for key, amount in pairs(add) do weights[key] = (weights[key] or 0) + amount * share end
        end
    end
    weights.ARMOR = weights.ARMOR or 0.01
    return weights
end

function Integration.Weights(spec)
    local scale = FindScale(spec)
    if not scale then return nil end
    talentCache = talentCache or ReadTalentsSafely() or {}
    local raw = RawWeights(scale, spec)
    local level = math.min(math.max(PlainNumber(UnitLevel("player")) or 1, 1), 60)
    local share = level / 60
    if scale.spell then share = share * share end
    for key in pairs(LEVEL_SCALED) do
        if raw[key] ~= nil then raw[key] = raw[key] * share end
    end

    if scale.spell then
        local melee = math.max(0, (20 - level) / 19)
        local rangedShare = math.min(math.max((60 - level) / 40, 0), 1)
        local hasWand = false
        for slot = 16, 18 do
            local id = GetInventoryItemID("player", slot)
            if id then
                local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(id)
                if classID == 2 and subClassID == 19 then hasWand = true; break end
            end
        end
        if hasWand then melee = 0 end
        raw.MELEE_DPS = (raw.MELEE_DPS or 1) * melee
        raw.RANGED_DPS = (raw.RANGED_DPS or 0) * (1 + 1.5 * rangedShare)
    end

    if scale.tank then
        local health = PlainNumber(UnitHealthMax("player"))
        local armor = PlainNumber(select(2, UnitArmor("player")))
        if health and health > 0 then
            local survival = math.min(health / 6000, 1.5)
            for _, key in ipairs({ "DODGE", "PARRY", "BLOCK", "DEFENSE" }) do
                if raw[key] ~= nil then raw[key] = raw[key] * survival end
            end
            if armor then
                raw.ARMOR = (raw.ARMOR or 0) * ArmorWorth(health, armor, level) / ArmorWorth(6000, 6000, 60)
            end
        end
    end

    local mapped = {}
    for key, value in pairs(raw) do
        local target = WEIGHT_KEYS[key]
        if target then mapped[target] = value end
    end
    return mapped
end

local function ItemValue(stats, key, spec, scale)
    local direct = {
        STRENGTH = "Strength", AGILITY = "Agility", STAMINA = "Stamina", INTELLECT = "Intellect",
        SPIRIT = "Spirit", ATTACK_POWER = "AttackPower", RANGED_AP = "RangedAttackPower",
        FERAL_AP = "FeralAttackPower", ARMOR = "Armor", DEFENSE = "Defense", BLOCK_VALUE = "BlockValue",
        HP5 = "HP5", MP5 = "MP5", SPELL_PEN = "SpellPenetration", HEALING = "Healing",
        ARCANE_DAMAGE = "ArcanePower", FIRE_DAMAGE = "FirePower", FROST_DAMAGE = "FrostPower",
        NATURE_DAMAGE = "NaturePower", SHADOW_DAMAGE = "ShadowPower", HOLY_DAMAGE = "HolyPower",
    }
    if direct[key] then return stats[direct[key]] or 0 end
    if key == "SPELL_DAMAGE" then return (stats.SpellPowerAll or 0) + (stats.SpellDamage or 0) end
    if key == "HIT" then
        local kind = scale.spell and "HIT_SPELL" or scale.weights.RANGED_HIT ~= nil and "HIT_RANGED" or "HIT_MELEE"
        local rating = (stats.HitRating or 0) + (scale.spell and (stats.SpellHitRating or 0)
            or scale.weights.RANGED_HIT ~= nil and (stats.RangedHitRating or 0) or (stats.MeleeHitRating or 0))
        return LJ.Scoring.RatingToPct(kind, rating, true) + (stats.HitPct or 0)
            + (scale.spell and (stats.SpellHitPct or 0) or 0)
    end
    if key == "CRIT" then
        local kind = scale.spell and "CRIT_SPELL" or scale.weights.RANGED_HIT ~= nil and "CRIT_RANGED" or "CRIT_MELEE"
        local rating = (stats.CritRating or 0) + (scale.spell and (stats.SpellCritRating or 0)
            or scale.weights.RANGED_HIT ~= nil and (stats.RangedCritRating or 0) or (stats.MeleeCritRating or 0))
        return LJ.Scoring.RatingToPct(kind, rating, true) + (stats.CritPct or 0)
            + (scale.spell and (stats.SpellCritPct or 0) or 0)
    end
    if key == "EXPERTISE" then return LJ.Scoring.RatingToPct("EXPERTISE", stats.ExpertiseRating or 0, true) end
    if key == "HASTE" then return LJ.Scoring.RatingToPct("HASTE", stats.HasteRating or 0, true) end
    if key == "DODGE" then return LJ.Scoring.RatingToPct("DODGE", stats.DodgeRating or 0, true) + (stats.DodgePct or 0) end
    if key == "PARRY" then return LJ.Scoring.RatingToPct("PARRY", stats.ParryRating or 0, true) + (stats.ParryPct or 0) end
    if key == "BLOCK" then return LJ.Scoring.RatingToPct("BLOCK", stats.BlockRating or 0, true) + (stats.BlockPct or 0) end
    if key == "WEAPON_SKILL" then return stats.WeaponSkill or 0 end
    if key == "MELEE_DPS" or key == "OFFHAND_DPS" or key == "RANGED_DPS" then return stats.DPS or 0 end
    if key == "MELEE_HIT" or key == "RANGED_HIT" then return stats.WeaponHitDamage or 0 end
    if key == "MELEE_SPEED" or key == "OFFHAND_SPEED" or key == "RANGED_SPEED" then return stats.WeaponSpeed or 0 end
    return 0
end

local function Dominates(link, oldID, oldLink, spec, scale)
    if not oldID then return false end
    local newer = LJ.Scoring.GetStatsForLink(link)
    local older = oldLink and LJ.Scoring.GetStatsForLink(oldLink) or LJ.Scoring.GetStats(oldID)
    if not (newer and older) or newer.HasUnparsedEquip or older.HasUnparsedEquip then return false end
    local changed = false
    for key, weight in pairs(scale.weights or {}) do
        if weight ~= 0 then
            local a = ItemValue(newer, key, spec, scale)
            local b = ItemValue(older, key, spec, scale)
            if weight < 0 then a, b = b, a end
            if a < b then return false end
            changed = changed or a > b
        end
    end
    return changed
end

function Integration.CacheKey(spec)
    talentCache = ReadTalentsSafely() or talentCache or {}
    local keys = {}
    for key, value in pairs(talentCache) do keys[#keys + 1] = key .. "=" .. value end
    table.sort(keys)
    return table.concat({ spec and spec.class or "", spec and spec.key or "", UnitLevel("player") or 1,
        table.concat(keys, ",") }, ":")
end

-- This returns Lootified's own stat-weight verdict. Its item and character data
-- come from Lootified's Forever-aware stat reader, never PawnForever's runtime API.
function Integration.Check(link, spec)
    if not (LJ.ItemCheck and LJ.ItemCheck.Share) then return nil end
    local share = LJ.ItemCheck.Share(spec, link)
    if not share then return nil end
    local points = share.points
    local empty = share.empty == true
    local scale = FindScale(spec)
    local dominant = scale and Dominates(link, share.replaces, share.replacesLink, spec, scale) or false
    -- Pawn's headline gain is relative to the item or pair being replaced, not
    -- to the score of every equipped slot combined.
    local gain = share.current and share.current > 0 and points and points / share.current * 100 or share.pct
    local upgrade = share.better and gain ~= nil
        and (empty or dominant or ((gain or 0) >= 2 and (points or 0) >= 0.1)) or false
    return { upgrade = upgrade, gain = upgrade and gain or nil, points = points,
        empty = empty, slot = share.slot, score = share.score }
end

function Integration.GainText(verdict)
    if verdict and verdict.gain then return ("+%.1f%%"):format(verdict.gain) end
    return nil
end

function Integration.Active()
    return FindScale(LJ.Player and LJ.Player:GetActiveSpec()) ~= nil
end

LJ:Listen("PLAYER_TALENT_UPDATE", function() talentCache = nil end)
LJ:Listen("TRAIT_CONFIG_UPDATED", function() talentCache = nil end)
LJ:Listen("TRAIT_CONFIG_LIST_UPDATED", function() talentCache = nil end)
LJ:Listen("PLAYER_ENTERING_WORLD", function() talentCache = nil end)
