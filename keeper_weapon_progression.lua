local RHOKDELAR_ENTRY = 18713
local LOKDELAR_ENTRY  = 18715
local MAX_PROGRESS = 48
local STAT_STRENGTH       = 3
local STAT_AGILITY        = 4
local STAT_STAMINA        = 5
local STAT_INTELLECT      = 7
local STAT_SPIRIT         = 8
local STAT_CRIT           = 32
local STAT_ATTACK_POWER   = 38
local STAT_RANGED_AP      = 39

local KEEPER_BOSSES = {
    [12118] = true, -- Lucifron
    [11982] = true, -- Magmadar
    [12259] = true, -- Gehennas
    [12057] = true, -- Garr
    [12264] = true, -- Shazzrah
    [12056] = true, -- Baron Geddon
    [12098] = true, -- Sulfuron Harbinger
    [11988] = true, -- Golemagg
    [12018] = true, -- Majordomo Executus
    [11502] = true, -- Ragnaros
    [12435] = true, -- Razorgore
    [13020] = true, -- Vaelastrasz
    [12017] = true, -- Broodlord Lashlayer
    [11983] = true, -- Firemaw
    [14601] = true, -- Ebonroc
    [11981] = true, -- Flamegor
    [14020] = true, -- Chromaggus
    [11583] = true, -- Nefarian
    [15263] = true, -- The Prophet Skeram
    [15511] = true, -- Lord Kri
    [15544] = true, -- Vem
    [15543] = true, -- Princess Yauj
    [15516] = true, -- Battleguard Sartura
    [15348] = true, -- Fankriss
    [15299] = true, -- Viscidus
    [15509] = true, -- Princess Huhuran
    [15277] = true, -- Emperor Vek'nilash
    [15276] = true, -- Emperor Vek'lor
    [15517] = true, -- Ouro
    [15727] = true, -- C'Thun
    [15956] = true, -- Anub'Rekhan
    [15953] = true, -- Grand Widow Faerlina
    [15952] = true, -- Maexxna
    [15954] = true, -- Noth
    [15936] = true, -- Heigan
    [16011] = true, -- Loatheb
    [16061] = true, -- Instructor Razuvious
    [16060] = true, -- Gothik
    [16064] = true, -- Thane Korth'azz
    [16065] = true, -- Baron Rivendare
    [16066] = true, -- Lady Blaumeux
    [16067] = true, -- Sir Zeliek
    [16028] = true, -- Patchwerk
    [15931] = true, -- Grobbulus
    [15932] = true, -- Gluth
    [15928] = true, -- Thaddius
    [15989] = true, -- Sapphiron
    [15990] = true, -- Kel'Thuzad
}

local PROGRESSION_WEAPONS = {
    [RHOKDELAR_ENTRY] = {
        maxRank = MAX_PROGRESS,
        weaponDamage = true,
        stats = {
        },
        bosses = KEEPER_BOSSES,
    },
    [LOKDELAR_ENTRY] = {
        maxRank = MAX_PROGRESS,
        weaponDamage = true,
        stats = {
            STAT_STAMINA,    -- 5
            STAT_INTELLECT,  -- 7
        },
        bosses = KEEPER_BOSSES,
    },
}

local function GetWeaponUpgradeResultName(result)
    local names = {
        [0] = "Success",
        [1] = "InvalidPlayer",
        [2] = "InvalidItem",
        [3] = "InvalidWeapon",
        [4] = "ItemNotOwned",
        [5] = "InvalidRank",
        [6] = "RankNotHigher",
        [7] = "DatabaseError",
    }
    return names[result] or "Unknown"
end

local function GetStatUpgradeResultName(result)
    local names = {
        [0] = "Success",
        [1] = "InvalidPlayer",
        [2] = "InvalidItem",
        [3] = "ItemNotOwned",
        [4] = "InvalidStat",
        [5] = "InvalidRank",
        [6] = "RankNotHigher",
        [7] = "StatNotPresent",
        [8] = "StatNotAllowed",
        [9] = "DatabaseError",
    }
    return names[result] or "Unknown"
end

local function GetStatName(statType)
    local names = {
        [STAT_STRENGTH]     = "Strength",
        [STAT_AGILITY]      = "Agility",
        [STAT_STAMINA]      = "Stamina",
        [STAT_INTELLECT]    = "Intellect",
        [STAT_SPIRIT]       = "Spirit",
        [STAT_CRIT]         = "Critical Strike Rating",
        [STAT_ATTACK_POWER] = "Attack Power",
        [STAT_RANGED_AP]    = "Ranged Attack Power",
    }
    return names[statType] or ("Stat " .. tostring(statType))
end

local function GetWeaponProgress(item)
    if not item then
        return 0
    end
    local itemGuid = item:GetGUIDLow()
    local result = CharDBQuery(string.format(
        "SELECT COUNT(*) " ..
        "FROM keeper_weapon_progression " ..
        "WHERE item_guid = %u",
        itemGuid
    ))
    if not result then
        return 0
    end
    return result:GetUInt32(0)
end

local function HasWeaponKilledBoss(item, bossEntry)
    if not item then
        return false
    end
    local itemGuid = item:GetGUIDLow()
    local result = CharDBQuery(string.format(
        "SELECT 1 " ..
        "FROM keeper_weapon_progression " ..
        "WHERE item_guid = %u " ..
        "AND boss_entry = %u " ..
        "LIMIT 1",
        itemGuid,
        bossEntry
    ))
    return result ~= nil
end

local function ProcessWeaponBossKill(player, item, bossEntry)
    if not player or not item then
        return
    end
    if player:IsBot() then
        return
    end
    if not item:IsEquipped() then
        return
    end
    local itemEntry = item:GetEntry()
    local config = PROGRESSION_WEAPONS[itemEntry]

    if not config then
        return
    end
    if not config.bosses[bossEntry] then
        return
    end
    if HasWeaponKilledBoss(item, bossEntry) then
        return
    end
    local currentProgress = GetWeaponProgress(item)
    if currentProgress >= config.maxRank then
        return
    end
    local newProgress = currentProgress + 1
    local result = player:SetKeeperWeaponProgression(
        item,
        bossEntry,
        newProgress,
        config.stats,
        config.weaponDamage
    )
    if result ~= 0 then
        print(string.format(
            "[Keeper][ERROR] Progression fehlgeschlagen. " ..
            "Player=%u ItemGUID=%u ItemEntry=%u Boss=%u " ..
            "Rank=%u Result=%u",
            player:GetGUIDLow(),
            item:GetGUIDLow(),
            itemEntry,
            bossEntry,
            newProgress,
            result
        ))
        player:SendBroadcastMessage(
            string.format(
                "|cffFF0000Keeper-Waffe:|r " ..
                "|cffFFFFFF%s|r konnte für diesen Boss nicht " ..
                "auf Rang |cffFFFF00%u|r aktualisiert werden. " ..
                "Result=%u. Siehe Worldserver-Konsole.",
                item:GetName(),
                newProgress,
                result
            )
        )

        return
    end
    player:SendBroadcastMessage(
        string.format(
            "|cffFFD100Keeper-Waffe:|r " ..
            "|cffFFFFFF%s|r " ..
            "|cffAAAAAAProgress:|r " ..
            "|cff00FF00%u/%u|r",
            item:GetName(),
            newProgress,
            config.maxRank
        )
    )
    print(string.format(
        "[Keeper][SUCCESS] Player=%u ItemGUID=%u ItemEntry=%u " ..
        "Boss=%u Progress=%u/%u",
        player:GetGUIDLow(),
        item:GetGUIDLow(),
        itemEntry,
        bossEntry,
        newProgress,
        config.maxRank
    ))
end

local function ProcessEquippedProgressionWeapons(player, bossEntry)
    if not player then
        return
    end
    if player:IsBot() then
        return
    end
    for slot = 0, 18 do
        local item = player:GetEquippedItemBySlot(slot)
        if item then
            local config = PROGRESSION_WEAPONS[
                item:GetEntry()
            ]
            if config then
                if item:IsEquipped() then
                    ProcessWeaponBossKill(
                        player,
                        item,
                        bossEntry
                    )
                end
            end
        end
    end
end

local function ProcessGroupMembers(
    creature,
    group,
    bossEntry
)
    if not group then
        return
    end
    local members = group:GetMembers()

    if not members then
        return
    end
    for _, member in ipairs(members) do

        if member
            and not member:IsBot()
            and member:IsAtGroupRewardDistance(creature)
        then

            ProcessEquippedProgressionWeapons(
                member,
                bossEntry
            )
        end
    end
end

local function OnBossDied(event, creature, killer)
    if not creature then
        return
    end
    local bossEntry = creature:GetEntry()
    if not KEEPER_BOSSES[bossEntry] then
        return
    end
    local group = creature:GetLootRecipientGroup()
    if group then

        ProcessGroupMembers(
            creature,
            group,
            bossEntry
        )

        return
    end
    if not killer then
        return
    end	
    if killer.IsPlayer and killer:IsPlayer() then
        if not killer:IsBot() then
            ProcessEquippedProgressionWeapons(
                killer,
                bossEntry
            )
            return
        end		
        local botGroup = killer:GetGroup()
        if botGroup then
            ProcessGroupMembers(
                creature,
                botGroup,
                bossEntry
            )
        end
    end
end

print("[Keeper] ==================================================")
print("[Keeper] Item-basierte Weapon Progression geladen.")
print("[Keeper] Boss-Reihenfolge ist frei.")
print("[Keeper] Jeder eindeutige Bosskill zählt pro Item-GUID nur einmal.")
print("[Keeper] Nur ausgerüstete Progressionswaffen erhalten Fortschritt.")
print("[Keeper] Playerbots werden ignoriert.")
print("[Keeper] Weapon Damage und Stats werden auf denselben Rang gesetzt.")
print("[Keeper] Fortschritt wird erst nach erfolgreichem Upgrade gespeichert.")
print("[Keeper] Rhok'delar 18713 / Lok'delar 18715.")
print("[Keeper] ==================================================")