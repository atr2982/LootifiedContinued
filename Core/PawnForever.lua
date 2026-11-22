-- Lootified delegates live item upgrade verdicts to PawnForever when it is loaded.
local _, LJ = ...

local Integration = {}
LJ.PawnForever = Integration
local scaleProxies = {}

-- Lootified's supported specs mapped to PawnForever's scale keys.
local SCALE_KEYS = {
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
    MELEE_DPS = "WeaponDPS", OFFHAND_DPS = "OffHandWeaponDPS", RANGED_DPS = "RangedWeaponDPS",
    SPELL_DAMAGE = "SpellPower", HEALING = "Healing", ARCANE_DAMAGE = "ArcanePower", FIRE_DAMAGE = "FirePower",
    FROST_DAMAGE = "FrostPower", NATURE_DAMAGE = "NaturePower", SHADOW_DAMAGE = "ShadowPower",
    HOLY_DAMAGE = "HolyPower", MP5 = "MP5", ARMOR = "Armor", DEFENSE = "Defense", DODGE = "Dodge",
    PARRY = "Parry", BLOCK = "Block", BLOCK_VALUE = "BlockValue", HP5 = "HP5",
}

function Integration.Scale(spec)
    local pawn = _G.PawnForever
    if type(pawn) ~= "table" or not pawn.Scales or type(pawn.Scales.List) ~= "function" then return nil end
    if not spec or pawn.class ~= spec.class then return nil end
    local keys = SCALE_KEYS[spec.class]
    local wanted = keys and keys[spec.key]
    if not wanted then return nil end
    for _, scale in ipairs(pawn.Scales:List()) do
        if scale.key == wanted then return scale end
    end
end

-- Returns PawnForever's own verdict for this exact spec and item link.
function Integration.Check(link, spec)
    local pawn = _G.PawnForever
    local scale = Integration.Scale(spec)
    if not scale or not pawn.Upgrades or type(pawn.Upgrades.Check) ~= "function" then return nil end
    -- A separate scale identity gives Lootified a private PawnForever verdict cache.
    -- The real PawnForever scale and its bag verdicts remain unchanged.
    local scoringScale = scaleProxies[scale]
    if not scoringScale then
        scoringScale = setmetatable({}, { __index = scale })
        scaleProxies[scale] = scoringScale
    end
    -- Preserve PawnForever's class and armor checks while allowing Lootified to compare
    -- future-level items. Only the minimum-level field passed to its usability check changes.
    local upgrades = pawn.Upgrades
    local originalUsable = upgrades.Usable
    if type(originalUsable) == "function" then
        upgrades.Usable = function(self, info)
            local futureItem = setmetatable({ minLevel = 0 }, { __index = info })
            return originalUsable(self, futureItem)
        end
    end
    local ok, verdict = pcall(pawn.Upgrades.Check, pawn.Upgrades, link, scoringScale)
    upgrades.Usable = originalUsable
    if not ok then return nil end
    return verdict
end

-- Lootified's catalog ranking uses the same effective PawnForever weights (including its
-- talent and level adjustments) for its known stat fields. Direct item checks still use
-- PawnForever's full verdict path above, including hit caps, weapons, and slot pairing.
function Integration.Weights(spec)
    local pawn = _G.PawnForever
    local scale = Integration.Scale(spec)
    if not scale or not pawn.Scales or type(pawn.Scales.Using) ~= "function"
        or type(pawn.Scales.Weights) ~= "function" then return nil end
    local ok, source = pcall(pawn.Scales.Using, pawn.Scales, scale, function()
        return pawn.Scales:Weights()
    end)
    if not ok or type(source) ~= "table" then return nil end
    local weights = {}
    for key, value in pairs(source) do
        local mapped = WEIGHT_KEYS[key]
        if mapped then weights[mapped] = value end
    end
    return weights
end

function Integration.CacheKey(spec)
    local pawn = _G.PawnForever
    local scale = Integration.Scale(spec)
    if not scale then return "no-pawn-scale" end
    return table.concat({ scale.key, tostring(pawn.generation or 0) }, ":")
end

function Integration.GainText(verdict)
    local pawn = _G.PawnForever
    if pawn and pawn.Upgrades and type(pawn.Upgrades.GainText) == "function" then
        local ok, text = pcall(pawn.Upgrades.GainText, verdict, true)
        if ok then return text end
    end
    if verdict and verdict.gain then
        return ("+%d%%"):format(math.max(1, math.floor(verdict.gain + 0.5)))
    end
    return nil
end

function Integration.Active()
    return Integration.Scale(LJ.Player and LJ.Player:GetActiveSpec()) ~= nil
end

