local RHOKDELAR_ENTRY = 18713
local LOKDELAR_ENTRY  = 18715

local MAX_PROGRESS = 48
local CREATURE_EVENT_ON_DIED = 4

-- ============================================================
-- Progressionswaffen
--
-- Jede konkrete Item-GUID besitzt ihren eigenen Fortschritt.
--
-- bosses:
--     Welche Bosse für diese Waffenart zählen.
--
-- weaponDamage:
--     Ob der Waffenschaden mit dem Rang steigt.
--
-- stats:
--     Später können hier die gewünschten ItemModType-Stats
--     hinterlegt werden.
-- ============================================================

local PROGRESSION_WEAPONS = {

    [RHOKDELAR_ENTRY] = {
        maxRank = 48,
        weaponDamage = true,

        bosses = {
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
    },

    [LOKDELAR_ENTRY] = {
        maxRank = 48,
        weaponDamage = true,

        bosses = {
            [12118] = true,
            [11982] = true,
            [12259] = true,
            [12057] = true,
            [12264] = true,
            [12056] = true,
            [12098] = true,
            [11988] = true,
            [12018] = true,
            [11502] = true,

            [12435] = true,
            [13020] = true,
            [12017] = true,
            [11983] = true,
            [14601] = true,
            [11981] = true,
            [14020] = true,
            [11583] = true,

            [15263] = true,
            [15511] = true,
            [15544] = true,
            [15543] = true,
            [15516] = true,
            [15348] = true,
            [15299] = true,
            [15509] = true,
            [15277] = true,
            [15276] = true,
            [15517] = true,
            [15727] = true,

            [15956] = true,
            [15953] = true,
            [15952] = true,
            [15954] = true,
            [15936] = true,
            [16011] = true,
            [16061] = true,
            [16060] = true,
            [16064] = true,
            [16065] = true,
            [16066] = true,
            [16067] = true,
            [16028] = true,
            [15931] = true,
            [15932] = true,
            [15928] = true,
            [15989] = true,
            [15990] = true,
        }
    }
}


-- ============================================================
-- Ermittelt den aktuellen Fortschritt eines konkreten Items
-- ============================================================

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


-- ============================================================
-- Prüft, ob genau dieses Item diesen Boss bereits gezählt hat
-- ============================================================

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


-- ============================================================
-- Speichert den neuen Bosskill für das konkrete Item
-- ============================================================

local function RegisterWeaponBossKill(player, item, bossEntry, killOrder)
    if not player or not item then
        return
    end

    local guid = player:GetGUIDLow()
    local itemGuid = item:GetGUIDLow()

    CharDBExecute(string.format(
        "INSERT IGNORE INTO keeper_weapon_progression " ..
        "(guid, item_guid, boss_entry, kill_order) " ..
        "VALUES (%u, %u, %u, %u)",
        guid,
        itemGuid,
        bossEntry,
        killOrder
    ))
end


-- ============================================================
-- Aktualisiert den Waffenschaden auf den neuen Rang
-- ============================================================

local function UpgradeWeaponDamage(item, rank)
    if not item then
        return
    end

    local owner = item:GetOwner()

    if not owner then
        return
    end

    local result = owner:SetWeaponDamageUpgrade(item, rank)

    -- 0 = Success
    -- 6 = RankNotHigher
    if result ~= 0 and result ~= 6 then
        print(string.format(
            "[Keeper] Weapon Damage Upgrade fehlgeschlagen. " ..
            "Player=%u Item=%u Rank=%u Result=%u",
            owner:GetGUIDLow(),
            item:GetGUIDLow(),
            rank,
            result
        ))
    end
end


-- ============================================================
-- Verarbeitet den Bosskill für eine konkrete Waffe
-- ============================================================

local function ProcessWeaponBossKill(player, item, bossEntry)
    if not player or not item then
        return
    end

    -- Keine Playerbots
    if player:IsBot() then
        return
    end

    local itemEntry = item:GetEntry()
    local config = PROGRESSION_WEAPONS[itemEntry]

    if not config then
        return
    end

    -- Boss muss für diese Waffenart zugelassen sein
    if not config.bosses[bossEntry] then
        return
    end

    -- Dieser Boss wurde mit diesem Item bereits gezählt
    if HasWeaponKilledBoss(item, bossEntry) then
        return
    end

    local currentProgress = GetWeaponProgress(item)

    if currentProgress >= config.maxRank then
        return
    end

    local newProgress = currentProgress + 1

    -- Bosskill für dieses konkrete Item speichern
    RegisterWeaponBossKill(
        player,
        item,
        bossEntry,
        newProgress
    )

    -- Waffenschaden aktualisieren
    if config.weaponDamage then
        UpgradeWeaponDamage(item, newProgress)
    end

    player:SendBroadcastMessage(
        string.format(
            "|cffFFD100Keeper-Waffe:|r " ..
            "|cffFFFFFF%s|r  " ..
            "|cffAAAAAAProgress:|r " ..
            "|cff00FF00%u/%u|r",
            item:GetName(),
            newProgress,
            config.maxRank
        )
    )

    print(string.format(
        "[Keeper] Player=%u Item=%u Boss=%u Progress=%u/%u",
        player:GetGUIDLow(),
        item:GetGUIDLow(),
        bossEntry,
        newProgress,
        config.maxRank
    ))
end


-- ============================================================
-- Ermittelt die Progressionswaffen, die der Spieler trägt
--
-- Main Hand und Off Hand werden berücksichtigt.
-- Zusätzlich werden weitere ausgerüstete Slots geprüft.
-- ============================================================

local function ProcessEquippedProgressionWeapons(player, bossEntry)
    if not player then
        return
    end

    for slot = 0, 18 do

        local item = player:GetEquippedItemBySlot(slot)

        if item then
            local config = PROGRESSION_WEAPONS[item:GetEntry()]

            if config then
                ProcessWeaponBossKill(
                    player,
                    item,
                    bossEntry
                )
            end
        end
    end
end


-- ============================================================
-- Boss Death
-- ============================================================

local function ProcessGroupMembers(creature, group, bossEntry)
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

    -- Nur bekannte Bosse verarbeiten.
    --
    -- Die Liste wird aus den Waffen-Konfigurationen erzeugt.
    local isProgressionBoss = false

    for _, config in pairs(PROGRESSION_WEAPONS) do
        if config.bosses[bossEntry] then
            isProgressionBoss = true
            break
        end
    end

    if not isProgressionBoss then
        return
    end

    -- ========================================================
    -- Normaler Gruppenfall
    -- ========================================================

    local group = creature:GetLootRecipientGroup()

    if group then
        ProcessGroupMembers(
            creature,
            group,
            bossEntry
        )

        return
    end

    -- ========================================================
    -- Kein Loot-Recipient-Group
    -- ========================================================

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

        -- Playerbot als Killer
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


-- ============================================================
-- Boss Hooks registrieren
-- ============================================================

local REGISTERED_BOSSES = {}

for _, config in pairs(PROGRESSION_WEAPONS) do

    for bossEntry, _ in pairs(config.bosses) do

        if not REGISTERED_BOSSES[bossEntry] then

            RegisterCreatureEvent(
                bossEntry,
                CREATURE_EVENT_ON_DIED,
                OnBossDied
            )

            REGISTERED_BOSSES[bossEntry] = true
        end
    end
end


print("[Keeper] Item-basierte Weapon Progression geladen.")
print("[Keeper] Boss-Reihenfolge ist frei.")
print("[Keeper] Jeder eindeutige Bosskill zählt pro Item nur einmal.")
print("[Keeper] Rhok'delar 18713 / Lok'delar 18715.")