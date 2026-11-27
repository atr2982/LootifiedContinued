-- Lootified - item stats and the hidden ranking: reads the Forever item stats (shipped, or the client's for items
-- outside the shipped data) and scores items per spec with stat weights. The ranking is never shown as such: it fills
-- the Best in Slot list where the simulator does not decide it (Core/BiS.lua).
local _, LJ = ...

local Scoring = {}
LJ.Scoring = Scoring

local Items = LJ.Items
local Player = LJ.Player

---------------------------------------------------------------------------
-- Stat extraction
---------------------------------------------------------------------------
local STAT_KEYS = {
    ITEM_MOD_STRENGTH_SHORT = "Strength",
    ITEM_MOD_AGILITY_SHORT = "Agility",
    ITEM_MOD_STAMINA_SHORT = "Stamina",
    ITEM_MOD_INTELLECT_SHORT = "Intellect",
    ITEM_MOD_SPIRIT_SHORT = "Spirit",
    ITEM_MOD_ATTACK_POWER_SHORT = "AttackPower",
    ITEM_MOD_MELEE_ATTACK_POWER_SHORT = "AttackPower",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "RangedAttackPower",
    ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "FeralAttackPower",
    ITEM_MOD_HIT_RATING_SHORT = "HitRating",
    ITEM_MOD_HIT_MELEE_RATING_SHORT = "MeleeHitRating",
    ITEM_MOD_HIT_RANGED_RATING_SHORT = "RangedHitRating",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "SpellHitRating",
    ITEM_MOD_CRIT_RATING_SHORT = "CritRating",
    ITEM_MOD_CRIT_MELEE_RATING_SHORT = "MeleeCritRating",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT = "RangedCritRating",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT = "SpellCritRating",
    ITEM_MOD_HASTE_RATING_SHORT = "HasteRating",
    ITEM_MOD_EXPERTISE_RATING_SHORT = "ExpertiseRating",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense",
    ITEM_MOD_DODGE_RATING_SHORT = "DodgeRating",
    ITEM_MOD_PARRY_RATING_SHORT = "ParryRating",
    ITEM_MOD_BLOCK_RATING_SHORT = "BlockRating",
    ITEM_MOD_BLOCK_VALUE_SHORT = "BlockValue",
    ITEM_MOD_SPELL_POWER_SHORT = "SpellPowerAll",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "SpellDamage",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "Healing",
    ITEM_MOD_SPELL_PENETRATION_SHORT = "SpellPenetration",
    ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT = "ShadowPower",
    ITEM_MOD_FIRE_DAMAGE_DONE_SHORT = "FirePower",
    ITEM_MOD_FROST_DAMAGE_DONE_SHORT = "FrostPower",
    ITEM_MOD_NATURE_DAMAGE_DONE_SHORT = "NaturePower",
    ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT = "ArcanePower",
    ITEM_MOD_HOLY_DAMAGE_DONE_SHORT = "HolyPower",
    ITEM_MOD_MANA_REGENERATION_SHORT = "MP5",
    ITEM_MOD_POWER_REGEN0_SHORT = "MP5",
    ITEM_MOD_EXTRA_ARMOR_SHORT = "Armor",
    RESISTANCE0_NAME = "Armor",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "DPS",
    ITEM_MOD_AXES_SHORT = "WeaponSkillAxes", ITEM_MOD_BOWS_SHORT = "WeaponSkillBows",
    ITEM_MOD_CROSSBOWS_SHORT = "WeaponSkillCrossbows", ITEM_MOD_DAGGERS_SHORT = "WeaponSkillDaggers",
    ITEM_MOD_FIST_WEAPONS_SHORT = "WeaponSkillFistWeapons", ITEM_MOD_GUNS_SHORT = "WeaponSkillGuns",
    ITEM_MOD_MACES_SHORT = "WeaponSkillMaces", ITEM_MOD_POLEARMS_SHORT = "WeaponSkillPolearms",
    ITEM_MOD_SWORDS_SHORT = "WeaponSkillSwords", ITEM_MOD_STAVES_SHORT = "WeaponSkillStaves",
    ITEM_MOD_HEALTH_REGENERATION_SHORT = "HP5",
    ITEM_MOD_HEALTH_REGENERATION = "HP5",
}

Scoring.STAT_KEYS = STAT_KEYS

-- English "Equip:" lines that GetItemStats does not always expose (percentage
-- based Classic effects). Only used when the stat is missing from GetItemStats.
-- Attack power that only counts in Cat and Bear form is feral attack power (e.g. Mace of Unending Life: "+140 Attack
-- Power in Cat, Bear, and Dire Bear forms only.").
local EQUIP_PATTERNS = {
    { "%+(%d+) Attack Power in Cat", "FeralAttackPower" },
    { "attack power by (%d+) in Cat", "FeralAttackPower" },
    { "chance to hit with spells by (%d+)%%", "SpellHitPct" },
    { "chance to get a critical strike with spells by (%d+)%%", "SpellCritPct" },
    { "chance to hit by (%d+)%%", "HitPct" },
    { "chance to get a critical strike by (%d+)%%", "CritPct" },
    { "chance to dodge an attack by (%d+)%%", "DodgePct" },
    { "chance to parry an attack by (%d+)%%", "ParryPct" },
    { "chance to block attacks with a shield by (%d+)%%", "BlockPct" },
    { "damage and healing done by magical spells and effects by up to (%d+)", "SpellPowerAll" },
    { "healing done by spells and effects by up to (%d+)", "Healing" },
    { "healing done by magical spells and effects by up to (%d+)", "Healing" },
    { "damage done by Shadow spells and effects by up to (%d+)", "ShadowPower" },
    { "damage done by Fire spells and effects by up to (%d+)", "FirePower" },
    { "damage done by Frost spells and effects by up to (%d+)", "FrostPower" },
    { "damage done by Nature spells and effects by up to (%d+)", "NaturePower" },
    { "damage done by Arcane spells and effects by up to (%d+)", "ArcanePower" },
    { "damage done by Holy spells and effects by up to (%d+)", "HolyPower" },
    { "Restores (%d+) mana per 5 sec", "MP5" },
    { "%+(%d+) Attack Power", "AttackPower" },
    { "attack power by (%d+)", "AttackPower" },
    { "block value of your shield by (%d+)", "BlockValue" },
    { "defense skill by (%d+)", "Defense" },
    { "Increased Defense %+(%d+)", "Defense" },
    { "your hit by (%d+)", "HitRating" },
    { "your critical strike by (%d+)", "CritRating" },
    { "spell penetration by (%d+)", "SpellPenetration" },
    { "spells pierce (%d+) magical resistance", "SpellPiercing" },
}

local statCache = {}
local liveStats = {}   -- [itemID] = true when statCache holds stats read from the client this session

-- The "Equip:" lines are read with English patterns (EQUIP_PATTERNS). On a client in another language they do
-- not match, so stats read there can miss spell power, hit, crit, MP5 and the like. Such clients use the stats
-- shipped with the addon (read from an English client) for every item that has them (LJ.ENGLISH_CLIENT).
local ENGLISH_CLIENT = LJ.ENGLISH_CLIENT

-- Effects that only count against some enemies are not stats of the item (Mark of the Champion: "+150 Attack Power
-- when fighting Undead and Demons.").
local function ParseTooltipData(data, stats)
    if not data or not data.lines then return end
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if type(text) == "string" and not LJ.Util.IsSecret(text) then
            local lower = text:lower()
            local allDamage = lower:match("%+?(%d+) weapon damage")
            local meleeDamage = lower:match("adds? (%d+) %a* damage to your melee attacks")
            if allDamage then
                stats.MeleeDamage = (stats.MeleeDamage or 0) + tonumber(allDamage)
                stats.RangedDamage = (stats.RangedDamage or 0) + tonumber(allDamage)
            elseif meleeDamage then
                stats.MeleeDamage = (stats.MeleeDamage or 0) + tonumber(meleeDamage)
            end
        end
        if type(text) == "string" and not LJ.Util.IsSecret(text) and text:find("Equip:", 1, true)
            and not text:find(" when fighting ", 1, true) then
            local recognized = false
            for _, p in ipairs(EQUIP_PATTERNS) do
                local value = text:match(p[1])
                if value then
                    recognized = true
                    if not stats[p[2]] then stats[p[2]] = tonumber(value) end
                    break
                end
            end
            if not recognized then stats.HasUnparsedEquip = true end
        end
    end
end

local function ParseTooltip(itemID, stats)
    ParseTooltipData(C_TooltipInfo.GetItemByID(itemID), stats)
end

local function ParseWeaponTooltip(data, stats)
    if not (data and data.lines) then return end
    for _, line in ipairs(data.lines) do
        local left, right = line.leftText, line.rightText
        if type(left) == "string" and not LJ.Util.IsSecret(left) then
            local lo, hi = left:match("(%d+)%s*%-%s*(%d+)%s+[Dd]amage")
            if lo and hi then stats.WeaponHitDamage = (tonumber(lo) + tonumber(hi)) / 2 end
        end
        if type(right) == "string" and not LJ.Util.IsSecret(right) then
            local speed = right:match("[Ss]peed%s+(%d+%.?%d*)")
            if speed then stats.WeaponSpeed = tonumber(speed) end
        end
    end
    if not stats.WeaponHitDamage and stats.DPS and stats.WeaponSpeed then
        stats.WeaponHitDamage = stats.DPS * stats.WeaponSpeed
    end
end

-- Stats of one concrete item link (random suffixes like "of the Bear" included), for tooltips of any item in
-- the game (bags, bank, vendors, auction house, other players). Not written to the item cache.
-- nil while the client has no data for the item yet.
local linkStats, linkStatsCount = {}, 0
function Scoring.GetStatsForLink(link)
    if type(link) ~= "string" or LJ.Util.IsSecret(link) then return nil end
    local cached = linkStats[link]
    if cached then return cached end
    if not ENGLISH_CLIENT then
        -- items without a random suffix: the shipped stats (see ENGLISH_CLIENT)
        local id = tonumber(link:match("item:(%d+)"))
        local suffix = link:match("item:%d+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:(%-?%d*)")
        local shipped = id and (not suffix or suffix == "" or suffix == "0") and Items.GetShippedStats(id)
        if shipped then
            if linkStatsCount > 400 then linkStats, linkStatsCount = {}, 0 end
            linkStats[link] = shipped
            linkStatsCount = linkStatsCount + 1
            return shipped
        end
    end
    if not C_Item.GetItemInfo(link) then return nil end
    local raw = C_Item.GetItemStats(link)
    if not raw then return nil end
    local stats = {}
    for key, value in pairs(raw) do
        local stat = STAT_KEYS[key]
        if stat and type(value) == "number" and not LJ.Util.IsSecret(value) then
            stats[stat] = (stats[stat] or 0) + value
        end
    end
    ParseTooltipData(C_TooltipInfo.GetHyperlink(link), stats)
    ParseWeaponTooltip(C_TooltipInfo.GetHyperlink(link), stats)
    if linkStatsCount > 400 then linkStats, linkStatsCount = {}, 0 end
    linkStats[link] = stats
    linkStatsCount = linkStatsCount + 1
    return stats
end

-- Stats read or looked up earlier in this session (nil when there are none yet).
function Scoring.GetCachedStats(itemID)
    return statCache[itemID]
end

-- The stats the client itself gives for an item it has the data of: its stat table and the "Equip:" lines of its
-- tooltip; empty while the client has not all of the item's data. (/lf collect reads them; at run time they count only
-- for items outside the shipped data.)
function Scoring.ClientStats(itemID)
    local stats = {}
    local link = select(2, C_Item.GetItemInfo(itemID)) or ("item:" .. itemID)
    local raw = C_Item.GetItemStats(link)
    if raw then
        for key, value in pairs(raw) do
            local stat = STAT_KEYS[key]
            if stat and type(value) == "number" and not LJ.Util.IsSecret(value) then
                stats[stat] = (stats[stat] or 0) + value
            end
        end
    end
    ParseTooltip(itemID, stats)
    ParseWeaponTooltip(C_TooltipInfo.GetItemByID(itemID), stats)
    return stats
end

-- The stats of an item. An item of the shipped data (Data/ItemStats.lua): its shipped stats, nil when none are known
-- (never asked for). Other items: stats saved in an earlier session until the client has the item, then the client's;
-- nil while its data is not loaded (asked from the server).
function Scoring.GetStats(itemID)
    local cached = statCache[itemID]
    if Items.IsShipped(itemID) then
        -- The shipped snapshot is a fallback, not a live override. Forever can change an existing item's stats
        -- without changing its ID; once the client has that item cached, prefer its current stats and Equip lines.
        if not liveStats[itemID] then
            local rec = Items.GetLive(itemID)
            if rec and rec.live then
                local current = Scoring.ClientStats(itemID)
                if next(current) ~= nil then
                    statCache[itemID] = current
                    liveStats[itemID] = true
                    Items.SaveStats(itemID, current)
                    return current
                end
            end
        end
        if not cached then
            cached = Items.GetShippedStats(itemID)
            statCache[itemID] = cached
        end
        return cached
    end
    local rec = Items.Get(itemID)
    if not rec.loaded then return nil end
    if cached and (liveStats[itemID] or not rec.live) then return cached end
    if not rec.live then
        local saved = Items.GetSavedStats(itemID)
        if saved then
            statCache[itemID] = saved
            return saved
        end
        Items.Request(itemID)
        return nil
    end
    local stats = Scoring.ClientStats(itemID)
    -- no stats at all: the client does not have the item's full data yet (gear without any stat is ranked out
    -- anyway), so nothing is kept and the next call reads again
    if next(stats) == nil then return stats end
    statCache[itemID] = stats
    liveStats[itemID] = true
    Items.SaveStats(itemID, stats)
    return stats
end

---------------------------------------------------------------------------
-- Rating conversion
---------------------------------------------------------------------------
-- Combat rating indices (Forever uses the rating system: GetCombatRatingBonus).
local CR = { HIT_MELEE = 6, HIT_RANGED = 7, HIT_SPELL = 8, CRIT_MELEE = 9, CRIT_RANGED = 10, CRIT_SPELL = 11,
    DODGE = 3, PARRY = 4, BLOCK = 5, HASTE = 18, EXPERTISE = 24 }
Scoring.CR = CR

-- PawnForever 1.7.1 parses item rating lines at these level-60 conversions,
-- then scales the corresponding weights by character level.
local RATING_PER_PCT_60 = { HIT_MELEE = 10, HIT_RANGED = 10, HIT_SPELL = 10, CRIT_MELEE = 14, CRIT_RANGED = 14,
    CRIT_SPELL = 14, DODGE = 12, PARRY = 15, BLOCK = 5, HASTE = 10, EXPERTISE = 10 }
Scoring.RATING_PER_PCT_60 = RATING_PER_PCT_60

local function RatingToPct(which, rating, atCurrentLevel)
    if not rating or rating == 0 then return 0 end
    return rating / RATING_PER_PCT_60[which]
end
Scoring.RatingToPct = RatingToPct

-- PawnForever's upgrade scorer applies the character's current hit cap to
-- the replacement comparison. Keep the cap math here so every Lootified
-- surface that compares gear uses the same scorer.
local HIT_KIND = { MELEE = { key = "HIT_MELEE", rating = CR.HIT_MELEE, modifier = "GetHitModifier" },
    RANGED = { key = "HIT_RANGED", rating = CR.HIT_RANGED, modifier = "GetRangedHitModifier" },
    SPELL = { key = "HIT_SPELL", rating = CR.HIT_SPELL, modifier = "GetSpellHitModifier" } }

local function HitKind(spec)
    local scale = LJ.UpgradeScoring.Scale(spec)
    if scale and scale.spell then return HIT_KIND.SPELL end
    if scale and scale.weights and scale.weights.RANGED_HIT ~= nil then return HIT_KIND.RANGED end
    return HIT_KIND.MELEE
end

local function PlainNumber(value)
    if LJ.Util and LJ.Util.IsSecret and LJ.Util.IsSecret(value) then return nil end
    return tonumber(value)
end

local function ItemHitPct(stats, kind)
    if not stats then return 0 end
    local rating = (stats.HitRating or 0) + (kind == HIT_KIND.SPELL and (stats.SpellHitRating or 0)
        or kind == HIT_KIND.RANGED and (stats.RangedHitRating or 0) or (stats.MeleeHitRating or 0))
    return RatingToPct(kind.key, rating) + (stats.HitPct or 0)
        + (kind == HIT_KIND.SPELL and (stats.SpellHitPct or 0) or 0)
end
function Scoring.HitStatPercent(stats, spec)
    return ItemHitPct(stats, HitKind(spec))
end

function Scoring.HitCap(spec)
    if HitKind(spec) == HIT_KIND.SPELL then return Player.level >= 60 and 17 or 4 end
    return Player.level >= 60 and 8 or 6
end

local function EquippedStats(slotID)
    local itemID = Player:GetEquippedItemID(slotID)
    if not itemID then return nil end
    local link = Player:GetEquippedLink(slotID)
    local stats = link and Scoring.GetStatsForLink(link)
    return stats and next(stats) and stats or Scoring.GetStats(itemID)
end

local function PlayerHitTotal(kind)
    local rating, modifier
    if type(GetCombatRatingBonus) == "function" then
        local ok, value = pcall(GetCombatRatingBonus, kind.rating)
        if ok then rating = PlainNumber(value) end
    end
    if type(_G[kind.modifier]) == "function" then
        local ok, value = pcall(_G[kind.modifier])
        if ok then modifier = PlainNumber(value) end
    end
    if rating ~= nil or modifier ~= nil then return (rating or 0) + (modifier or 0) end

    -- Same fallback as PawnForever: sum the parsed hit from the currently
    -- equipped items when the client does not expose readable hit APIs.
    local total = 0
    for slotID = 1, 18 do
        local id = Player:GetEquippedItemID(slotID)
        if id then total = total + ItemHitPct(EquippedStats(slotID), kind) end
    end
    return total
end

function Scoring.HitContext(spec, excludedSlots, dualWielding)
    local kind = HitKind(spec)
    local total = PlayerHitTotal(kind)
    for _, slotID in ipairs(excludedSlots or {}) do
        local id = Player:GetEquippedItemID(slotID)
        if id then
            local stats = EquippedStats(slotID)
            if not stats then return nil end
            total = total - ItemHitPct(stats, kind)
        end
    end
    return total, dualWielding
end

local function HitWorth(hit, cap, beyond)
    return math.min(hit, cap) + beyond * math.max(hit - cap, 0)
end
Scoring.HitWorth = HitWorth

---------------------------------------------------------------------------
-- Scoring
---------------------------------------------------------------------------
local function W(w, key) return w[key] or 0 end

local SCHOOLS = { "ShadowPower", "FirePower", "FrostPower", "NaturePower", "ArcanePower", "HolyPower" }
local WEAPON_SKILL_SUBCLASSES = {
    WeaponSkillAxes = { 0, 1 }, WeaponSkillBows = { 2 }, WeaponSkillGuns = { 3 },
    WeaponSkillMaces = { 4, 5 }, WeaponSkillPolearms = { 6 }, WeaponSkillSwords = { 7, 8 },
    WeaponSkillStaves = { 10 }, WeaponSkillFistWeapons = { 13 }, WeaponSkillDaggers = { 15 },
    WeaponSkillCrossbows = { 18 },
}

-- Feral form gear must not be selected for spell damage it cannot use. Weapon DPS still counts in form,
-- but caster spell bonuses and weapon off-hands are not Feral upgrades.
local FERAL_SPECS = { CAT = true, BEAR = true }
local FERAL_RELIC_SPECS = {
    [249441] = {},             -- Talons of Wrath restores mana to Wrath; not useful in either Feral form.
    [213594] = { BEAR = true }, -- Idol of the Heckler's Forever effect is unlocked through Challenging Roar.
}
local function IsFeral(spec)
    return spec and spec.class == "DRUID" and FERAL_SPECS[spec.key]
end

function Scoring.IsSpecEligible(itemID, spec, slotKey, stats)
    if not IsFeral(spec) then return true end
    if slotKey == "OFFHAND" then return false end
    local relicSpecs = FERAL_RELIC_SPECS[itemID]
    if relicSpecs and not relicSpecs[spec.key] then return false end
    stats = stats or Scoring.GetStats(itemID)
    if stats then
        for _, key in ipairs({ "SpellPowerAll", "SpellDamage", "ShadowPower", "FirePower", "FrostPower",
            "NaturePower", "ArcanePower", "HolyPower" }) do
            if (stats[key] or 0) > 0 then return false end
        end
    end
    return true
end

-- slotKey decides how weapon DPS counts (MAINHAND/TWOHAND/OFFHAND/RANGED).
-- stats: optional stat table (Scoring.GetStatsForLink), otherwise the item's stats are used.
-- hitBase: hit chance without the item being compared (PawnForever's capped-hit comparison context).
-- dualWielding: whether the character currently has a weapon in the off hand (PawnForever's over-cap value).
function Scoring.Score(itemID, spec, slotKey, atCurrentLevel, stats, hitBase, dualWielding)
    local s = stats or Scoring.GetStats(itemID)
    if not s then return nil end
    if not Scoring.IsSpecEligible(itemID, spec, slotKey, s) then return nil end
    local w = LJ.UpgradeScoring.Weights(spec)
    local pawnScale = LJ.UpgradeScoring.Scale(spec)
    if not w then return nil end
    local score = 0

    score = score + (s.Strength or 0) * W(w, "Strength")
    score = score + (s.Agility or 0) * W(w, "Agility")
    score = score + (s.Stamina or 0) * W(w, "Stamina")
    score = score + (s.Intellect or 0) * W(w, "Intellect")
    score = score + (s.Spirit or 0) * W(w, "Spirit")
    score = score + (s.MP5 or 0) * W(w, "MP5")
    score = score + (s.HP5 or 0) * W(w, "HP5")
    score = score + (s.Armor or 0) * W(w, "Armor")
    score = score + (s.Defense or 0) * W(w, "Defense")
    score = score + (s.BlockValue or 0) * W(w, "BlockValue")
    score = score + (s.ArcaneResistance or 0) * W(w, "ArcaneResistance")
    score = score + (s.FireResistance or 0) * W(w, "FireResistance")
    score = score + (s.FrostResistance or 0) * W(w, "FrostResistance")
    score = score + (s.NatureResistance or 0) * W(w, "NatureResistance")
    score = score + (s.ShadowResistance or 0) * W(w, "ShadowResistance")

    -- PawnForever scores the parsed ATTACK_POWER and RANGED_AP stats separately.
    -- Generic attack power stays on its own weight; the item stat parser does not
    -- duplicate it as ranged AP.
    local apWeight = W(w, "AttackPower")
    local rapWeight = W(w, "RangedAttackPower")
    score = score + (s.AttackPower or 0) * apWeight
    score = score + (s.RangedAttackPower or 0) * rapWeight
    if spec.key == "CAT" or spec.key == "BEAR" then
        score = score + (s.FeralAttackPower or 0) * W(w, "FeralAttackPower")
    end

    -- Match PawnForever's parser: a combined spell damage/healing bonus contributes
    -- to both weights, and healing-only bonuses contribute one third as spell damage
    -- when the item has no explicit spell damage bonus.
    local spWeight = W(w, "SpellPower")
    local healWeight = W(w, "Healing")
    local spellPower, healing = s.SpellPowerAll or 0, s.Healing or 0
    score = score + spellPower * (spWeight + healWeight)
    score = score + (s.SpellDamage or 0) * spWeight
    score = score + healing * healWeight
    if spellPower == 0 and (s.SpellDamage or 0) == 0 then
        score = score + healing / 3 * spWeight
    end
    for _, school in ipairs(SCHOOLS) do
        score = score + (s[school] or 0) * W(w, school)
    end

    -- PawnForever gives each scale one hit and crit weight. Apply those weights to
    -- the scale's attack school (spell, ranged for hunters, otherwise melee).
    local spellScale = pawnScale and pawnScale.spell
    local rangedScale = pawnScale and pawnScale.weights and pawnScale.weights.RANGED_HIT ~= nil
    local hitKey = spellScale and "HIT_SPELL" or rangedScale and "HIT_RANGED" or "HIT_MELEE"
    local critKey = spellScale and "CRIT_SPELL" or rangedScale and "CRIT_RANGED" or "CRIT_MELEE"
    local hitRating = (s.HitRating or 0) + (spellScale and (s.SpellHitRating or 0)
        or rangedScale and (s.RangedHitRating or 0) or (s.MeleeHitRating or 0))
    local critRating = (s.CritRating or 0) + (spellScale and (s.SpellCritRating or 0)
        or rangedScale and (s.RangedCritRating or 0) or (s.MeleeCritRating or 0))
    local hitPct = RatingToPct(hitKey, hitRating, atCurrentLevel) + (s.HitPct or 0)
        + (spellScale and (s.SpellHitPct or 0) or 0)
    local critPct = RatingToPct(critKey, critRating, atCurrentLevel) + (s.CritPct or 0)
        + (spellScale and (s.SpellCritPct or 0) or 0)
    if hitBase ~= nil then
        local cap = Scoring.HitCap(spec)
        local beyond = dualWielding and 0.4 or 0
        hitPct = HitWorth(hitBase + hitPct, cap, beyond) - HitWorth(hitBase, cap, beyond)
    end
    score = score + hitPct * W(w, "Hit") + critPct * W(w, "Crit")
    score = score + (RatingToPct("DODGE", s.DodgeRating, atCurrentLevel) + (s.DodgePct or 0)) * W(w, "Dodge")
    score = score + (RatingToPct("PARRY", s.ParryRating, atCurrentLevel) + (s.ParryPct or 0)) * W(w, "Parry")
    score = score + (RatingToPct("BLOCK", s.BlockRating, atCurrentLevel) + (s.BlockPct or 0)) * W(w, "Block")

    -- Only score stats that have a visible, spec-specific row. Hidden fallback weights made items
    -- gain value from stats the player could not see in the priority panel.
    score = score + RatingToPct("HASTE", s.HasteRating, atCurrentLevel) * W(w, "Haste")
    score = score + RatingToPct("EXPERTISE", s.ExpertiseRating, atCurrentLevel) * W(w, "Expertise")
    -- PawnForever scores a generic weapon-skill bonus as a regular stat, but
    -- weapon-type-specific bonuses only apply to currently wielded weapons of
    -- that type (or the candidate weapon itself). Preserve the type from the
    -- client's stat keys instead of flattening every weapon skill together.
    score = score + (s.WeaponSkill or 0) * W(w, "WeaponSkill")
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    if W(w, "WeaponSkill") ~= 0 and classID == 2 then
        local wielded = {}
        for _, equipSlot in ipairs({ 16, 17, 18 }) do
            local equippedID = GetInventoryItemID("player", equipSlot)
            if equippedID then
                local equippedClass, equippedSubclass = select(6, C_Item.GetItemInfoInstant(equippedID))
                if equippedClass == 2 and equippedSubclass ~= nil then wielded[equippedSubclass] = true end
            end
        end
        if subclassID ~= nil then wielded[subclassID] = true end
        for key, subclasses in pairs(WEAPON_SKILL_SUBCLASSES) do
            local value = s[key] or 0
            if value ~= 0 then
                for _, weaponSubclass in ipairs(subclasses) do
                    if wielded[weaponSubclass] then
                        score = score + value * W(w, "WeaponSkill")
                        break
                    end
                end
            end
        end
    end
    score = score + (s.SpellPenetration or 0) * W(w, "SpellPenetration")
    score = score + (s.SpellPiercing or 0) * W(w, "SpellPiercing")

    -- Weapon damage.
    local dps = s.DPS or 0
    if dps > 0 then
        if slotKey == "RANGED" then
            score = score + dps * W(w, "RangedWeaponDPS")
        elseif slotKey == "OFFHAND" then
            score = score + dps * (w.OffHandWeaponDPS or 0.5 * W(w, "WeaponDPS"))
        else
            score = score + dps * W(w, "WeaponDPS")
        end
        local speed = s.WeaponSpeed or s.Speed or 0
        local hitDamage = s.WeaponHitDamage or (speed > 0 and dps * speed) or 0
        if slotKey == "RANGED" then
            score = score + hitDamage * W(w, "RangedHitDamage")
            score = score + speed * W(w, "RangedSpeedWeight")
        elseif slotKey == "OFFHAND" then
            score = score + speed * W(w, "OffHandSpeedWeight")
        else
            score = score + hitDamage * W(w, "WeaponHitDamage")
            score = score + speed * W(w, "WeaponSpeedWeight")
        end
    end

    -- PawnForever values flat weapon damage from the currently equipped weapon
    -- speeds (or the selected weapon's own speed when evaluating a weapon).
    local flatMelee, flatRanged = s.MeleeDamage or 0, s.RangedDamage or 0
    if flatMelee ~= 0 or flatRanged ~= 0 then
        local scale = pawnScale or {}
        local function EquippedSpeed(invSlot)
            local link = GetInventoryItemLink("player", invSlot)
            if not link then return nil end
            local itemStats = Scoring.GetStatsForLink(link)
            return itemStats and (itemStats.WeaponSpeed or itemStats.Speed)
        end
        local mainSpeed = EquippedSpeed(16)
        local offSpeed = EquippedSpeed(17)
        local rangedSpeed = EquippedSpeed(18)
        local mainID = GetInventoryItemID("player", 16)
        local mainLoc = mainID and select(4, C_Item.GetItemInfoInstant(mainID))
        if slotKey == "MAINHAND" or slotKey == "TWOHAND" then
            mainSpeed = s.WeaponSpeed or s.Speed or mainSpeed
            if slotKey == "TWOHAND" then offSpeed = nil end
        elseif slotKey == "OFFHAND" then
            offSpeed = s.WeaponSpeed or s.Speed or offSpeed
        elseif slotKey == "RANGED" then
            rangedSpeed = s.WeaponSpeed or s.Speed or rangedSpeed
        end
        if mainLoc == "INVTYPE_2HWEAPON" and slotKey ~= "OFFHAND" then offSpeed = nil end
        local formSwing = scale.swing
        local meleeWorth = W(w, "WeaponDPS") / (formSwing or mainSpeed or 2) + W(w, "WeaponHitDamage")
        if offSpeed and offSpeed > 0 then
            meleeWorth = meleeWorth + (w.OffHandWeaponDPS or 0) / offSpeed
        end
        local rangedWorth = rangedSpeed and rangedSpeed > 0
            and (W(w, "RangedWeaponDPS") / rangedSpeed + W(w, "RangedHitDamage")) or 0
        score = score + flatMelee * meleeWorth + flatRanged * rangedWorth
    end
    return score
end

---------------------------------------------------------------------------
-- Candidate pools and ranking
---------------------------------------------------------------------------
Scoring.SLOTS = { "HEAD", "NECK", "SHOULDER", "BACK", "CHEST", "WRIST", "HANDS", "WAIST", "LEGS", "FEET",
    "FINGER", "TRINKET", "MAINHAND", "OFFHAND", "TWOHAND", "RANGED", "RELIC" }

local EQUIPLOC_SLOTS = {
    INVTYPE_HEAD = "HEAD", INVTYPE_NECK = "NECK", INVTYPE_SHOULDER = "SHOULDER", INVTYPE_CLOAK = "BACK",
    INVTYPE_CHEST = "CHEST", INVTYPE_ROBE = "CHEST", INVTYPE_WRIST = "WRIST", INVTYPE_HAND = "HANDS",
    INVTYPE_WAIST = "WAIST", INVTYPE_LEGS = "LEGS", INVTYPE_FEET = "FEET", INVTYPE_FINGER = "FINGER",
    INVTYPE_TRINKET = "TRINKET", INVTYPE_WEAPONMAINHAND = "MAINHAND", INVTYPE_WEAPONOFFHAND = "OFFHAND",
    INVTYPE_SHIELD = "OFFHAND", INVTYPE_HOLDABLE = "OFFHAND", INVTYPE_2HWEAPON = "TWOHAND",
    INVTYPE_RANGED = "RANGED", INVTYPE_RANGEDRIGHT = "RANGED", INVTYPE_THROWN = "RANGED", INVTYPE_RELIC = "RELIC",
}
Scoring.EQUIPLOC_SLOTS = EQUIPLOC_SLOTS

-- Returns the list of slot keys an item can fill for a class (shared lists: callers only read them); level: the level
-- of the character (another class: Dual Wield is learned at a level, Player:CanDualWield).
local SLOT_LIST, DUAL_WIELD, MAIN_HAND, NO_SLOTS = {}, { "MAINHAND", "OFFHAND" }, { "MAINHAND" }, {}
for _, slot in pairs(EQUIPLOC_SLOTS) do SLOT_LIST[slot] = SLOT_LIST[slot] or { slot } end
function Scoring.GetItemSlots(rec, class, level)
    local loc = rec.equipLoc
    if loc == "INVTYPE_WEAPON" then
        if Player:CanDualWield(class, level) then return DUAL_WIELD end
        return MAIN_HAND
    end
    -- off-hand weapons need dual wield
    if loc == "INVTYPE_WEAPONOFFHAND" and not Player:CanDualWield(class, level) then return NO_SLOTS end
    local slot = EQUIPLOC_SLOTS[loc]
    if slot then return SLOT_LIST[slot] end
    return NO_SLOTS
end

-- Every item the journal knows (dungeon + raid loot, trash, the shipped Best in Slot items of Data/BiS.lua).
-- Their data ships with the addon (Data/ItemStats.lua).
function Scoring.GetBaseCandidateIDs()
    if Scoring.baseIDs then return Scoring.baseIDs end
    local seen, list = {}, {}
    local function add(id)
        if id and not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    for _, inst in ipairs(LJ.Data.Instances) do
        for _, boss in ipairs(inst.bosses) do
            for _, id in ipairs(boss.loot) do add(id) end
        end
        for _, id in ipairs(inst.trash or {}) do add(id) end
    end
    for _, specs in pairs(LJ.Data.BiS) do
        for _, spec in ipairs(specs) do
            for _, entries in pairs(spec.slots) do
                for _, e in ipairs(entries) do add(e.id) end
            end
        end
    end
    Scoring.baseIDs, Scoring.baseSet = list, seen
    return list
end

-- The open world's items (the drops of rares and other mobs, random world drops), open world quest rewards, the rewards
-- of the dungeon quests and what the professions make. Which of them a character's list takes, its filter decides
-- (Items.InList).
function Scoring.GetWorldCandidateIDs()
    if Scoring.worldIDs then return Scoring.worldIDs end
    Scoring.GetBaseCandidateIDs()
    local seen, list = {}, {}
    local function add(id)
        if not seen[id] and not Scoring.baseSet[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    for id in pairs(LJ.Data.WorldDrops or {}) do add(id) end
    for _, id in ipairs(Items.GetWorldQuestItemIDs()) do add(id) end
    for id in pairs(LJ.Quests and LJ.Quests.rewardOf or {}) do add(id) end
    for id in pairs(LJ.Data.Crafted) do add(id) end
    table.sort(list)
    Scoring.worldIDs = list
    return list
end

-- ForeverDB includes speculative records that are present in client data but have no confirmed acquisition
-- path. Keep those in the raw catalog for /lf collect, but don't present them as obtainable gear unless one of
-- Lootified's verified source tables identifies where they come from.
local function HasVerifiedItemSource(id)
    local dungeonSources = Items.GetSources(id)
    if (dungeonSources and #dungeonSources > 0) or Items.HasWorldDrop(id) then return true end
    if LJ.Data.Crafted and LJ.Data.Crafted[id] then return true end
    if LJ.Data.WorldQuestRewards and LJ.Data.WorldQuestRewards[id] then return true end
    if LJ.Quests and LJ.Quests.rewardOf and LJ.Quests.rewardOf[id] then return true end
    return false
end

local function IsUnconfirmedForeverItem(id)
    local record = LJ.Data.ForeverDB and LJ.Data.ForeverDB.items and LJ.Data.ForeverDB.items[id]
    return record and record.speculation == true and not HasVerifiedItemSource(id)
end

function Scoring.GetAllCandidateIDs()
    if Scoring.allIDs then return Scoring.allIDs end
    -- The Database is a catalog, not just an index of items with already-known acquisition sources. Include the
    -- shipped item records, except ForeverDB entries explicitly marked speculative with no verified source.
    local list = {}
    for _, id in ipairs(Scoring.GetAllItemIDs()) do
        if not IsUnconfirmedForeverItem(id) then list[#list + 1] = id end
    end
    Scoring.allIDs = list
    return list
end

-- Developer tool (/lf collect): asks the server once for every open world candidate, so the saved item cache
-- holds their Forever stats. That SavedVariables file is then baked into Data/ItemStats.lua (gen_itemstats.lua)
-- and the items rank from the start without any server request. Only runs when the command is typed.
-- Items new in WoW: Forever have IDs far above the Classic ones (Classic item IDs end below 26000).
local FOREVER_ITEM_MIN = 100000

-- Every new Forever item the addon knows: loot, open world drops, quest items and rewards, BiS entries.
function Scoring.GetForeverItemIDs()
    local seen, list = {}, {}
    local function add(id)
        if type(id) == "number" and id >= FOREVER_ITEM_MIN and not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    local D = LJ.Data
    for id in pairs(D.Items or {}) do add(id) end
    for id in pairs(D.ForeverDB and D.ForeverDB.items or {}) do add(id) end
    for id in pairs(D.WorldDrops or {}) do add(id) end
    for id in pairs(D.WorldQuestItems or {}) do add(id) end
    for id in pairs(D.ItemStats and D.ItemStats.items or {}) do add(id) end
    for _, q in pairs(D.Quests or {}) do
        for _, id in ipairs(q.choice or {}) do add(id) end
        for _, id in ipairs(q.reward or {}) do add(id) end
        for _, it in ipairs(q.items or {}) do add(it.id) end
        if type(q.start) == "table" and q.start.kind == "item" then add(q.start.id) end
    end
    for _, specs in pairs(D.BiS or {}) do
        for _, spec in ipairs(specs) do
            for _, entries in pairs(spec.slots or {}) do
                for _, e in ipairs(entries) do add(e.id) end
            end
        end
    end
    table.sort(list)
    return list
end

-- Every item the addon knows (dungeon loot, Best in Slot lists, open world drops, quest items and rewards, the
-- shipped item data), for /lf collect (Core/Locale.lua).
function Scoring.GetAllItemIDs()
    local seen, list = {}, {}
    local function add(id)
        if type(id) == "number" and not seen[id] then
            seen[id] = true
            list[#list + 1] = id
        end
    end
    for _, id in ipairs(Scoring.GetBaseCandidateIDs()) do add(id) end
    for _, id in ipairs(Scoring.GetWorldCandidateIDs()) do add(id) end
    for _, id in ipairs(Scoring.GetForeverItemIDs()) do add(id) end
    local D = LJ.Data
    for id in pairs(D.Items or {}) do add(id) end
    for id in pairs(D.ForeverDB and D.ForeverDB.items or {}) do add(id) end
    for id in pairs(D.WorldDrops or {}) do add(id) end
    for id in pairs(D.WorldQuestItems or {}) do add(id) end
    for id in pairs(D.ItemStats and D.ItemStats.items or {}) do add(id) end
    for _, q in pairs(D.Quests or {}) do
        for _, it in ipairs(q.items or {}) do add(it.id) end
        if type(q.start) == "table" and q.start.kind == "item" then add(q.start.id) end
    end
    table.sort(list)
    return list
end

-- The all-item catalog also contains consumables and quest objects. Cache just records the current Forever client
-- identifies as equippable for the Best in Slot fallback scan.
local catalogGearIDs
function Scoring.GetCatalogGearIDs()
    if catalogGearIDs then return catalogGearIDs end
    local list = {}
    for _, id in ipairs(Scoring.GetAllItemIDs()) do
        if not IsUnconfirmedForeverItem(id) then
            local itemID, _, _, equipLoc = C_Item.GetItemInfoInstant(id)
            if itemID and equipLoc and equipLoc ~= "" then list[#list + 1] = id end
        end
    end
    catalogGearIDs = list
    return list
end

-- Rankings are kept until something they come from changes: the spec or the character (Scoring.InvalidateCache), an
-- item's levels; one that waited for items without data yet (pending) until item data arrives (ITEMS_UPDATED).
local rankingCache, rankingCount = {}, 0
local RANKINGS_KEPT = 6     -- specs and level options switched between; older rankings are made again

local function RankingCacheKey(spec, opts)
    return table.concat({ spec.class, spec.key, tostring(opts.maxLevel or 0), tostring(opts.current and 1 or 0),
        Items.ListKey(), Items.AvailabilityKey(), LJ.UpgradeScoring.CacheKey(spec) }, ":")
end

function Scoring.InvalidateCache()
    rankingCache, rankingCount = {}, 0
end

-- A newly loaded item can replace its shipped fallback stats with the live
-- Forever record. Invalidate only rankings that considered that item.
function Scoring.InvalidateItem(itemID)
    if not itemID then return end
    statCache[itemID], liveStats[itemID] = nil, nil
    local linkPrefix = "item:" .. itemID .. ":"
    for link in pairs(linkStats) do
        if link:find(linkPrefix, 1, true) then linkStats[link] = nil end
    end
    for key, ranking in pairs(rankingCache) do
        if ranking.itemIDs and ranking.itemIDs[itemID] then
            rankingCache[key] = nil
            rankingCount = math.max(0, rankingCount - 1)
        end
    end
end

-- Ranks every known item for a spec, grouped by slot: the items its list takes (Items.InList: the sources the player
-- picked) that the character can wear (not the other faction's, on the own class's list none with a profession the
-- character lacks). Kept per list (Items.ListKey) and PawnForever scale generation: another one is ranked anew.
-- opts.maxLevel limits the items to those usable at that level (Items.GetUseLevel), opts.current uses the
-- rating conversions of the current level.
-- Thousands of candidates are looked at without an item record each: slot and type come from the client
-- (C_Item.GetItemInfoInstant), levels and stats from the shipped or saved data. Only items neither knows (outside the
-- shipped data and not known as without server data) get a record, which asks the server for them.
function Scoring.RankAll(spec, opts)
    opts = opts or {}
    local cacheKey = RankingCacheKey(spec, opts)
    if rankingCache[cacheKey] then return rankingCache[cacheKey] end
    local started = debugprofilestop()
    local bySlot = {}
    for _, slot in ipairs(Scoring.SLOTS) do bySlot[slot] = {} end
    local facts = {}        -- reused for item eligibility checks within this ranking
    local scratchStats = {} -- shipped stats parsed for this ranking only
    -- the candidates whose data the game has not sent yet (asked for once: Items.Request)
    local waiting = {}
    local rankedItems = {}
    local class, maxLevel = spec.class, opts.maxLevel
    local level, own = maxLevel or 60, class == Player.class
    local function Rank(id, world, sourceFallback, fallbackSlots)
        -- an item without server data (the shipped list, or this game version's answers) is not in the game
        if Items.IsKnownMissing(id) then return end
        local itemID, _, _, equipLoc, _, classID, subclassID = C_Item.GetItemInfoInstant(id)
        if not itemID or not equipLoc or equipLoc == "" then return end   -- not in this client, or not gear
        facts.id, facts.equipLoc, facts.classID, facts.subclassID = id, equipLoc, classID, subclassID
        if not Player:CanClassUse(facts, class, level) then return end
        if Items.IsOtherFaction(id) then return end
        -- the character's own list: not with a profession it lacks (Scoring.MissingSkill)
        if own and Scoring.MissingSkill(id) then return end
        -- only what the list takes (a quest of the other faction or another class gives none)
        if not Items.InList(id, class, level, sourceFallback) then return end
        rankedItems[id] = true
        -- Fallback is explicitly the best available catalog candidate when enabled sources have no item for a slot.
        -- The Forever item catalog proves the item exists; missing source/stat coverage must not make the slot blank.
        local minLevel, itemLevel = Items.GetKnownLevels(id)
        if not minLevel then
            -- open world items never ask the server: they rank when their data ships with the addon
            -- (Data/ItemStats.lua) or the client already has it; otherwise they are skipped, not pending
            local rec = world and Items.Peek(id) or Items.Get(id)
            if not rec.loaded then
                if not world then waiting[#waiting + 1] = id end
                return
            end
            minLevel, itemLevel = rec.minLevel or 0, rec.itemLevel or 0
        end
        -- ... and only with stats that are known without asking the server
        if world and not Items.HasKnownStats(id) and not sourceFallback then return end
        if maxLevel and Items.UseLevelFrom(id, minLevel, itemLevel) > maxLevel then return end
        -- stats read this session, then saved or shipped ones; unknown stats come from the client or the server
        -- The ID cache can contain an older shipped snapshot. The scorer used
        -- by links and tooltips prefers the current Forever client record, so
        -- ranking must ask the same source first as soon as it is available.
        local stats
        if not stats and sourceFallback then
            -- For fallback catalog scans, use client stats only when already
            -- known; never trigger item requests for thousands of unrelated gear.
            if Items.HasKnownStats(id) then stats = Scoring.GetStats(id) end
            stats = stats or Items.GetKnownStats(id, scratchStats)
        else
            -- Match tooltip scoring: prefer the scorer's live Forever item data,
            -- then use the shipped snapshot only when the client has none.
            stats = Scoring.GetStats(id) or Scoring.GetCachedStats(id) or Items.GetKnownStats(id, scratchStats)
        end
        if not stats and sourceFallback then
            -- An item with no parsed numeric stats remains a valid zero-score last resort. Do not request thousands of
            -- tooltips during this scan; item details can still arrive through ordinary client use or /lf collect.
            stats = {}
        end
        if not stats then
            -- (a shipped item without stats has none: it does not rank)
            if not Items.IsShipped(id) then waiting[#waiting + 1] = id end
            return
        end
        for _, slot in ipairs(Scoring.GetItemSlots(facts, class, level)) do
            if not fallbackSlots or fallbackSlots[slot] then
                local hitBase, dualWielding = Scoring.GetRankHitContext(spec, slot)
                local score = hitBase ~= nil and Scoring.Score(id, spec, slot, opts.current, stats, hitBase, dualWielding) or nil
                if score and (score > 0 or (sourceFallback and score == 0)) then
                    local list = bySlot[slot]
                    list[#list + 1] = { id = id, score = score, fallback = sourceFallback, itemLevel = itemLevel or 0 }
                end
            end
        end
    end
    for _, id in ipairs(Scoring.GetBaseCandidateIDs()) do
        Rank(id, false)
    end
    for _, id in ipairs(Scoring.GetWorldCandidateIDs()) do
        Rank(id, true)
    end
    -- If selected sources have no scored option for a slot, search the full known item catalog while preserving class,
    -- level, faction, profession, and armor-filter rules. This is deliberately a fallback: normal source-filtered picks
    -- always win, but a slot does not stay empty just because its source table or stat cache is incomplete.
    local fallbackSlots = {}
    for slot, list in pairs(bySlot) do
        if #list == 0 then fallbackSlots[slot] = true end
    end
    if next(fallbackSlots) then
        for _, id in ipairs(Scoring.GetCatalogGearIDs()) do
            Rank(id, true, true, fallbackSlots)
        end
    end
    for _, list in pairs(bySlot) do
        table.sort(list, function(a, b)
            if a.score ~= b.score then return a.score > b.score end
            if a.fallback and b.fallback then
                if a.itemLevel ~= b.itemLevel then return a.itemLevel > b.itemLevel end
                return a.id < b.id
            end
            return false
        end)
    end
    local result = { bySlot = bySlot, pending = #waiting, itemIDs = rankedItems }
    if rankingCount >= RANKINGS_KEPT then rankingCache, rankingCount = {}, 0 end
    rankingCache[cacheKey] = result
    rankingCount = rankingCount + 1
    -- (/lf debug: a ranking made, and the items it waits for)
    LJ:Debug("ranking %s: %.1f ms, %d items wait for data %s", cacheKey, debugprofilestop() - started, #waiting,
        table.concat(waiting, ", ", 1, math.min(#waiting, 8)))
    return result
end

-- New item data: the rankings that waited for items are made again with them.
LJ:Listen("ITEMS_UPDATED", function()
    -- A client item-data load can replace the shipped fallback stats. Drop
    -- stats parsed before that load so Journal comparisons use the same data
    -- the item tooltip now sees.
    statCache, liveStats, linkStats, linkStatsCount = {}, {}, {}, 0
    for key, r in pairs(rankingCache) do
        if r.pending > 0 then
            rankingCache[key] = nil
            rankingCount = rankingCount - 1
        end
    end
end)

LJ:Listen("ITEM_DATA_UPDATED", function(_, itemID)
    Scoring.InvalidateItem(itemID)
end)

-- The score of the item worn in an equipment slot, from its link (random suffixes count): score, item ID, link; 0
-- for an empty slot. The score is nil while the game has no data for the worn item yet (no link, no stats of it): the
-- game is asked for it (ITEMS_UPDATED follows).
local function EquippedScore(slotID, spec, slotKey, current, hitBase, dualWielding)
    local itemID = Player:GetEquippedItemID(slotID)
    if not itemID then return 0, nil end
    local link = Player:GetEquippedLink(slotID)
    local stats = link and Scoring.GetStatsForLink(link)
    -- Forever can provide an equipped link before its live stat table is available.  The
    -- collected/shipped item record is still authoritative in that case; without this
    -- fallback every worn slot looks unknown and the shared BiS upgrade list is empty.
    if not stats or next(stats) == nil then
        stats = Scoring.GetStats(itemID)
    end
    if not stats then
        Items.Request(itemID)
        return nil, itemID, link
    end
    return Scoring.Score(itemID, spec, slotKey, current, stats, hitBase, dualWielding), itemID, link
end
Scoring.EquippedScore = EquippedScore

-- The score of what is worn where an item of a slot goes (the lower one of two ring or trinket slots): score, item ID,
-- link; the score is nil while the game has no data for an item worn there yet (EquippedScore).
function Scoring.GetEquippedScore(spec, slot, current, hitBase, dualWielding)
    if slot == "TWOHAND" then
        local mhScore, mh, mhLink = EquippedScore(16, spec, "TWOHAND", current, hitBase, dualWielding)
        local ohScore, oh, ohLink = EquippedScore(17, spec, "OFFHAND", current, hitBase, dualWielding)
        if not (mhScore and ohScore) then return nil, mh or oh, mhLink or ohLink end
        return mhScore + ohScore, mh or oh, mhLink or ohLink
    end
    local ids = Player.SLOT_IDS[slot]
    if not ids then return 0, nil end
    -- an off hand next to a worn two-hander replaces the two-hander (its own slot is empty, not free)
    if slot == "OFFHAND" and not Player:GetEquippedItemID(17) then
        local mainHand = Player:GetEquippedItemID(16)
        local mainLoc = mainHand and select(4, C_Item.GetItemInfoInstant(mainHand))
        if mainLoc == "INVTYPE_2HWEAPON" then return EquippedScore(16, spec, "TWOHAND", current, hitBase, dualWielding) end
    end
    local lowest, lowestID, lowestLink
    for _, slotID in ipairs(ids) do
        local score, itemID, link = EquippedScore(slotID, spec, slot, current, hitBase, dualWielding)
        if not score then return nil, itemID, link end
        if not lowest or score < lowest then
            lowest, lowestID, lowestLink = score, itemID, link
        end
    end
    return lowest or 0, lowestID, lowestLink
end

-- Score the exact equipped slot PawnForever would replace, including each
-- ring/trinket independently and the two hands together for a two-hand slot.
function Scoring.GetReplacementScore(spec, slot)
    local dualID = Player:GetEquippedItemID(17)
    local dualClass = dualID and select(6, C_Item.GetItemInfoInstant(dualID))
    local dualWielding = dualClass == 2
    if slot == "TWOHAND" then
        local hitBase = Scoring.HitContext(spec, { 16, 17 }, dualWielding)
        if hitBase == nil then return nil end
        local score, id, link = Scoring.GetEquippedScore(spec, slot, true, hitBase, dualWielding)
        return score, id, link, hitBase, dualWielding
    end
    local slotIDs = Player.SLOT_IDS[slot]
    if not slotIDs then return 0, nil, nil, Scoring.HitContext(spec, {}, dualWielding), dualWielding end
    local best, bestID, bestLink, bestHit
    for _, slotID in ipairs(slotIDs) do
        local id = Player:GetEquippedItemID(slotID)
        local hitBase = Scoring.HitContext(spec, id and { slotID } or {}, dualWielding)
        if hitBase == nil then return nil end
        local score, wornID, link = EquippedScore(slotID, spec, slot, true, hitBase, dualWielding)
        if score == nil then return nil, wornID, link end
        if best == nil or score < best or (score == best and not wornID) then
            best, bestID, bestLink, bestHit = score, wornID, link, hitBase
        end
    end
    return best or 0, bestID, bestLink, bestHit, dualWielding
end

function Scoring.GetRankHitContext(spec, slot)
    local dualID = Player:GetEquippedItemID(17)
    local dualClass = dualID and select(6, C_Item.GetItemInfoInstant(dualID))
    local dualWielding = dualClass == 2
    if slot == "MAINHAND" or slot == "OFFHAND" or slot == "TWOHAND" then
        return Scoring.HitContext(spec, { 16, 17 }, dualWielding), dualWielding
    end
    local _, _, _, hitBase, dual = Scoring.GetReplacementScore(spec, slot)
    return hitBase, dual
end

-- PawnForever compares weapon replacements as a two-hand loadout, including
-- the different off-hand weights and a usable bag partner when replacing a
-- two-hander. The result is still built only from Scoring.Score.
function Scoring.CompareWeapon(itemID, spec, candidateStats, equipLoc, allowBagPartner)
    local mainID, offID = Player:GetEquippedItemID(16), Player:GetEquippedItemID(17)
    local mainLoc = mainID and select(4, C_Item.GetItemInfoInstant(mainID))
    local mainStats = mainID and EquippedStats(16)
    local offStats = offID and EquippedStats(17)
    if (mainID and not mainStats) or (offID and not offStats) then return nil end

    local offClass = offID and select(6, C_Item.GetItemInfoInstant(offID))
    local offIsWeapon = offClass == 2
    local canDual = Player:CanDualWield(spec.class)
    local hitBase = Scoring.HitContext(spec, { 16, 17 }, offIsWeapon)
    if hitBase == nil then return nil end
    local currentMain = mainID and Scoring.Score(mainID, spec, mainLoc == "INVTYPE_2HWEAPON" and "TWOHAND" or "MAINHAND",
        true, mainStats, hitBase, offIsWeapon) or 0
    local currentOff = offID and offIsWeapon and Scoring.Score(offID, spec, "OFFHAND", true, offStats, hitBase, offIsWeapon) or 0
    local current = currentMain + currentOff
    local mainTwoHand = mainLoc == "INVTYPE_2HWEAPON"

    local function CandidateScore(hand)
        return Scoring.Score(itemID, spec, hand, true, candidateStats, hitBase, offIsWeapon)
    end
    local function BestBagPartner(hand)
        if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then return nil end
        local best
        for bag = 0, NUM_BAG_SLOTS or 4 do
            for bagSlot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
                local containerItem = C_Container.GetContainerItemInfo(bag, bagSlot)
                local link = containerItem and containerItem.hyperlink
                local partnerID = link and tonumber(link:match("item:(%d+)"))
                if partnerID and partnerID ~= itemID and partnerID ~= mainID and partnerID ~= offID then
                    local _, _, _, loc, _, classID, subclassID = C_Item.GetItemInfoInstant(link)
                    local facts = { id = partnerID, equipLoc = loc, classID = classID, subclassID = subclassID }
                    local isMainPartner = classID == 2 and (loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONMAINHAND")
                    local isOffWeapon = classID == 2 and (loc == "INVTYPE_WEAPON" or loc == "INVTYPE_WEAPONOFFHAND") and canDual
                    local isOffArmor = loc == "INVTYPE_SHIELD" or loc == "INVTYPE_HOLDABLE"
                    if (isMainPartner or isOffWeapon or isOffArmor) and Player:CanClassUse(facts, spec.class) then
                        local partnerStats = Scoring.GetStatsForLink(link)
                        local partnerHand = hand == "MAINHAND" and "MAINHAND" or "OFFHAND"
                        local allowed = hand == "MAINHAND" and isMainPartner
                            or hand == "OFFHAND" and (isOffWeapon or isOffArmor)
                        if allowed and partnerStats then
                            local score = Scoring.Score(partnerID, spec, partnerHand, true, partnerStats, hitBase, offIsWeapon)
                            if score and score > 0 and (not best or score > best.score) then
                                best = { id = partnerID, score = score }
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local candidate, shown, chosenSlot
    if equipLoc == "INVTYPE_2HWEAPON" then
        shown = CandidateScore("TWOHAND")
        candidate, chosenSlot = shown, "MAINHAND"
    elseif equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" then
        local asMain = CandidateScore("MAINHAND")
        local asOff = canDual and Scoring.IsSpecEligible(itemID, spec, "OFFHAND", candidateStats)
            and CandidateScore("OFFHAND") or nil
        shown, candidate, chosenSlot = asMain, (asMain or 0) + currentOff, "MAINHAND"
        if mainTwoHand and allowBagPartner ~= false then
            local partner = BestBagPartner("OFFHAND")
            if partner then candidate = (asMain or 0) + partner.score end
        elseif mainID and canDual and mainLoc == "INVTYPE_WEAPON" then
            local mainAsOff = Scoring.Score(mainID, spec, "OFFHAND", true, mainStats, hitBase, offIsWeapon)
            if mainAsOff and asMain and asMain + mainAsOff > candidate then candidate = asMain + mainAsOff end
        end
        if asOff and not mainTwoHand and currentMain + asOff > candidate then
            candidate, shown, chosenSlot = currentMain + asOff, asOff, "OFFHAND"
        end
    else
        shown = CandidateScore("OFFHAND")
        chosenSlot = "OFFHAND"
        if mainTwoHand then
            if allowBagPartner ~= false then
                local partner = BestBagPartner("MAINHAND")
                candidate = (partner and partner.score or 0) + (shown or 0)
            else
                candidate = shown or 0
            end
        else
            candidate = currentMain + (shown or 0)
        end
    end
    if not candidate or not shown then return nil end
    return { current = current, candidate = candidate, delta = candidate - current, itemScore = shown,
        slot = chosenSlot, hitBase = hitBase }
end

-- The profession an item asks for (Data/ItemStats.lua) when the character does not have it at that rank:
-- "Requires Engineering (245)" with the profession's name (Data.Professions, translated by the language data); nil
-- when it asks for none or the character has it.
function Scoring.MissingSkill(itemID)
    local line, rank = Items.GetSkill(itemID)
    if not line or (Player:ProfessionRank(line) or 0) >= rank then return nil end
    return LJ.F("Requires %s (%d)", assert(LJ.Data.Professions[line], "no name for profession " .. line), rank)
end

-- stats looked up for the items the window showed (the item records go at the same time, Items.lua)
LJ:Listen("WINDOW_CLOSED", function() statCache, liveStats = {}, {} end)

LJ:Listen("SPEC_CHANGED", Scoring.InvalidateCache)
LJ:Listen("PLAYER_CHANGED", Scoring.InvalidateCache)
LJ:Listen("EQUIPMENT_CHANGED", Scoring.InvalidateCache)
LJ:Listen("CONTENT_AVAILABILITY_CHANGED", Scoring.InvalidateCache)
