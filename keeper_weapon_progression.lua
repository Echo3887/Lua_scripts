-- ============================================================
-- Keeper Weapon Progression
-- ============================================================
--
-- Item-basierte Progression:
--
-- Jede konkrete Item-GUID besitzt ihren eigenen Fortschritt.
--
-- Beispiel:
--   Item GUID 10001 -> Boss A, B, C -> Rang 3
--   Item GUID 10002 -> Boss A, D     -> Rang 2
--
-- Es gibt KEINE feste Boss-Reihenfolge.
-- Jeder konfigurierte Boss kann als nächster Progressionspunkt
-- verwendet werden.
--
-- Ein Boss wird pro konkreter Item-GUID nur einmal gezählt.
--
-- Nur tatsächlich ausgerüstete Progressionswaffen erhalten
-- beim Boss-Tod Fortschritt.
--
-- Playerbots werden vollständig ignoriert.
--
-- Die eigentlichen Item-Upgrades werden durch mod-item-upgrade
-- durchgeführt:
--
--   Player:SetWeaponDamageUpgrade(item, rank)
--   Player:SetItemStatUpgrade(item, statType, rank)
--
-- Der Rang von Waffenschaden und allen konfigurierten Stats
-- ist immer identisch.
-- ============================================================


local RHOKDELAR_ENTRY = 18713
local LOKDELAR_ENTRY  = 18715

local MAX_PROGRESS = 48
local CREATURE_EVENT_ON_DIED = 4


-- ============================================================
-- Stat-IDs
-- ============================================================
--
-- WoW 3.3.5 / ItemModType:
--
-- 3  = Strength
-- 4  = Agility
-- 5  = Stamina
-- 6  = Intellect
-- 7  = Spirit
-- 32 = Critical Strike Rating
-- 38 = Attack Power
-- 39 = Ranged Attack Power
--
-- WICHTIG:
-- mod-item-upgrade kann nur Stats verbessern, die tatsächlich
-- auf dem Item vorhanden sind.
--
-- Daher:
--
-- Rhok'delar:
--   Crit + Ranged AP
--
-- Lok'delar:
--   Stamina + Intellect + Crit
--
-- Falls deine eigene item_template andere Stats besitzt, kann
-- diese Liste hier angepasst werden.
-- ============================================================


local STAT_STRENGTH       = 3
local STAT_AGILITY        = 4
local STAT_STAMINA        = 5
local STAT_INTELLECT      = 6
local STAT_SPIRIT         = 7
local STAT_CRIT           = 32
local STAT_ATTACK_POWER   = 38
local STAT_RANGED_AP      = 39


-- ============================================================
-- Gemeinsame Bossliste
-- ============================================================
--
-- Insgesamt 48 mögliche Bosse.
--
-- Es gibt keine Reihenfolge.
-- Jeder Boss kann unabhängig voneinander als nächster
-- Progressionspunkt zählen.
-- ============================================================

local KEEPER_BOSSES = {

    -- ========================================================
    -- Molten Core
    -- ========================================================

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

    -- ========================================================
    -- Blackwing Lair
    -- ========================================================

    [12435] = true, -- Razorgore
    [13020] = true, -- Vaelastrasz
    [12017] = true, -- Broodlord Lashlayer
    [11983] = true, -- Firemaw
    [14601] = true, -- Ebonroc
    [11981] = true, -- Flamegor
    [14020] = true, -- Chromaggus
    [11583] = true, -- Nefarian

    -- ========================================================
    -- Ahn'Qiraj
    -- ========================================================

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

    -- ========================================================
    -- Naxxramas
    -- ========================================================

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


-- ============================================================
-- Waffen-Konfiguration
-- ============================================================
--
-- Jede Waffe kann vollkommen unabhängig konfiguriert werden.
--
-- maxRank:
--     Maximale Progression.
--
-- weaponDamage:
--     true  = Waffenschaden wird mit dem Rang erhöht.
--     false = kein Waffenschaden-Upgrade.
--
-- stats:
--     ItemModType-IDs, die mit demselben Rang verbessert
--     werden sollen.
--
-- bosses:
--     Bosses, die für DIESE Waffenart zählen.
--
-- Die Bossliste kann später pro Waffe unabhängig geändert
-- werden.
-- ============================================================

local PROGRESSION_WEAPONS = {

    -- ========================================================
    -- Rhok'delar, Longbow of the Ancient Keepers
    -- Entry: 18713
    -- ========================================================

    [RHOKDELAR_ENTRY] = {

        maxRank = MAX_PROGRESS,

        weaponDamage = true,

        stats = {
            STAT_CRIT,       -- 32
            STAT_RANGED_AP,  -- 39
        },

        bosses = KEEPER_BOSSES,
    },


    -- ========================================================
    -- Lok'delar, Stave of the Ancient Keepers
    -- Entry: 18715
    -- ========================================================

    [LOKDELAR_ENTRY] = {

        maxRank = MAX_PROGRESS,

        weaponDamage = true,

        stats = {
            STAT_STAMINA,    -- 5
            STAT_INTELLECT,  -- 6
            STAT_CRIT,       -- 32
        },

        bosses = KEEPER_BOSSES,
    },
}


-- ============================================================
-- Hilfsfunktion: Fehlertext für WeaponUpgradeResult
-- ============================================================

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


-- ============================================================
-- Hilfsfunktion: Fehlertext für StatUpgradeResult
-- ============================================================

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


-- ============================================================
-- Hilfsfunktion: Name eines Stats
-- ============================================================

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
--
-- Diese Funktion wird ERST aufgerufen, wenn alle Upgrades
-- erfolgreich verarbeitet wurden.
-- ============================================================

local function RegisterWeaponBossKill(player, item, bossEntry, killOrder)

    if not player or not item then
        return false
    end

    local guid = player:GetGUIDLow()
    local itemGuid = item:GetGUIDLow()

    local query = string.format(
        "INSERT IGNORE INTO keeper_weapon_progression " ..
        "(guid, item_guid, boss_entry, kill_order) " ..
        "VALUES (%u, %u, %u, %u)",
        guid,
        itemGuid,
        bossEntry,
        killOrder
    )

    CharDBExecute(query)

    -- Nach dem INSERT kontrollieren, ob der Datensatz wirklich
    -- vorhanden ist.
    local result = CharDBQuery(string.format(
        "SELECT 1 " ..
        "FROM keeper_weapon_progression " ..
        "WHERE item_guid = %u " ..
        "AND boss_entry = %u " ..
        "AND kill_order = %u " ..
        "LIMIT 1",
        itemGuid,
        bossEntry,
        killOrder
    ))

    if not result then

        print(string.format(
            "[Keeper][ERROR] Bosskill konnte nicht gespeichert werden. " ..
            "Player=%u ItemGUID=%u Boss=%u Rank=%u",
            guid,
            itemGuid,
            bossEntry,
            killOrder
        ))

        return false
    end

    return true
end


-- ============================================================
-- Upgrade: Waffenschaden
-- ============================================================

local function UpgradeWeaponDamage(player, item, rank)

    if not player or not item then
        return false
    end

    local result = player:SetWeaponDamageUpgrade(
        item,
        rank
    )

    -- Success
    if result == 0 then
        return true
    end

    -- RankNotHigher bedeutet:
    -- Der Waffenschaden ist bereits mindestens auf diesem Rang.
    --
    -- Das behandeln wir als erfolgreich, damit bei einem
    -- vorherigen Teilfehler die fehlenden Stats später noch
    -- nachgezogen werden können.
    if result == 6 then
        print(string.format(
            "[Keeper][INFO] Weapon Damage bereits auf Rang >= %u. " ..
            "Player=%u ItemGUID=%u",
            rank,
            player:GetGUIDLow(),
            item:GetGUIDLow()
        ))

        return true
    end

    print(string.format(
        "[Keeper][ERROR] Weapon Damage Upgrade fehlgeschlagen. " ..
        "Player=%u ItemGUID=%u ItemEntry=%u Rank=%u Result=%u (%s)",
        player:GetGUIDLow(),
        item:GetGUIDLow(),
        item:GetEntry(),
        rank,
        result,
        GetWeaponUpgradeResultName(result)
    ))

    return false
end


-- ============================================================
-- Upgrade: einzelne Item-Stat
-- ============================================================

local function UpgradeWeaponStat(player, item, statType, rank)

    if not player or not item then
        return false
    end

    local result = player:SetItemStatUpgrade(
        item,
        statType,
        rank
    )

    -- Success
    if result == 0 then
        return true
    end

    -- Der Stat befindet sich bereits auf dem gewünschten oder
    -- einem höheren Rang.
    --
    -- Das gilt für die Progression als erfolgreich.
    if result == 6 then
        print(string.format(
            "[Keeper][INFO] Stat bereits auf Rang >= %u. " ..
            "Player=%u ItemGUID=%u Stat=%u (%s)",
            rank,
            player:GetGUIDLow(),
            item:GetGUIDLow(),
            statType,
            GetStatName(statType)
        ))

        return true
    end

    print(string.format(
        "[Keeper][ERROR] Stat Upgrade fehlgeschlagen. " ..
        "Player=%u ItemGUID=%u ItemEntry=%u " ..
        "Stat=%u (%s) Rank=%u Result=%u (%s)",
        player:GetGUIDLow(),
        item:GetGUIDLow(),
        item:GetEntry(),
        statType,
        GetStatName(statType),
        rank,
        result,
        GetStatUpgradeResultName(result)
    ))

    return false
end


-- ============================================================
-- Führt ALLE Upgrades für den neuen Rang aus
-- ============================================================
--
-- Wichtig:
--
-- 1. Weapon Damage
-- 2. alle konfigurierten Stats
-- 3. erst danach wird der Bosskill gespeichert.
--
-- Dadurch wird ein Boss nicht als erledigt gespeichert,
-- solange mindestens ein benötigtes Upgrade fehlgeschlagen ist.
-- ============================================================

local function ApplyWeaponProgression(player, item, config, rank)

    if not player or not item or not config then
        return false
    end


    -- ========================================================
    -- Waffenschaden
    -- ========================================================

    if config.weaponDamage then

        if not UpgradeWeaponDamage(
            player,
            item,
            rank
        ) then

            print(string.format(
                "[Keeper][ERROR] Progression abgebrochen: " ..
                "Weapon Damage fehlgeschlagen. " ..
                "Player=%u ItemGUID=%u Rank=%u",
                player:GetGUIDLow(),
                item:GetGUIDLow(),
                rank
            ))

            return false
        end
    end


    -- ========================================================
    -- Stats
    -- ========================================================

    if config.stats then

        for _, statType in ipairs(config.stats) do

            if not UpgradeWeaponStat(
                player,
                item,
                statType,
                rank
            ) then

                print(string.format(
                    "[Keeper][ERROR] Progression abgebrochen: " ..
                    "Stat %u (%s) fehlgeschlagen. " ..
                    "Player=%u ItemGUID=%u Rank=%u",
                    statType,
                    GetStatName(statType),
                    player:GetGUIDLow(),
                    item:GetGUIDLow(),
                    rank
                ))

                return false
            end
        end
    end


    return true
end


-- ============================================================
-- Verarbeitet den Bosskill für eine konkrete Waffe
-- ============================================================

local function ProcessWeaponBossKill(player, item, bossEntry)

    if not player or not item then
        return
    end


    -- ========================================================
    -- Playerbot-Schutz
    -- ========================================================

    if player:IsBot() then
        return
    end


    -- ========================================================
    -- Sicherheitsprüfung:
    -- Das Item muss tatsächlich ausgerüstet sein.
    -- ========================================================

    if not item:IsEquipped() then

        print(string.format(
            "[Keeper][DEBUG] Item nicht ausgerüstet. " ..
            "Player=%u ItemGUID=%u Entry=%u Boss=%u",
            player:GetGUIDLow(),
            item:GetGUIDLow(),
            item:GetEntry(),
            bossEntry
        ))

        return
    end


    -- ========================================================
    -- Konfiguration bestimmen
    -- ========================================================

    local itemEntry = item:GetEntry()

    local config = PROGRESSION_WEAPONS[itemEntry]

    if not config then
        return
    end


    -- ========================================================
    -- Boss muss für diese Waffe konfiguriert sein
    -- ========================================================

    if not config.bosses[bossEntry] then
        return
    end


    -- ========================================================
    -- Dieser Boss wurde mit genau diesem Item bereits gezählt
    -- ========================================================

    if HasWeaponKilledBoss(
        item,
        bossEntry
    ) then

        print(string.format(
            "[Keeper][DEBUG] Boss bereits für Item gezählt. " ..
            "Player=%u ItemGUID=%u Boss=%u",
            player:GetGUIDLow(),
            item:GetGUIDLow(),
            bossEntry
        ))

        return
    end


    -- ========================================================
    -- Aktuellen Rang ermitteln
    -- ========================================================

    local currentProgress = GetWeaponProgress(item)


    if currentProgress >= config.maxRank then

        print(string.format(
            "[Keeper][INFO] Maximale Progression erreicht. " ..
            "Player=%u ItemGUID=%u Progress=%u/%u",
            player:GetGUIDLow(),
            item:GetGUIDLow(),
            currentProgress,
            config.maxRank
        ))

        return
    end


    local newProgress = currentProgress + 1


    -- ========================================================
    -- Upgrades anwenden
    --
    -- Der Bosskill wird absichtlich NOCH NICHT gespeichert.
    -- ========================================================

    local upgradeSuccess = ApplyWeaponProgression(
        player,
        item,
        config,
        newProgress
    )


    if not upgradeSuccess then

        player:SendBroadcastMessage(
            string.format(
                "|cffFF0000Keeper-Waffe:|r " ..
                "|cffFFFFFF%s|r konnte für diesen Boss nicht " ..
                "auf Rang |cffFFFF00%u|r aktualisiert werden. " ..
                "Siehe Worldserver-Konsole.",
                item:GetName(),
                newProgress
            )
        )

        print(string.format(
            "[Keeper][ERROR] Bosskill NICHT gespeichert. " ..
            "Mindestens ein Upgrade fehlgeschlagen. " ..
            "Player=%u ItemGUID=%u ItemEntry=%u Boss=%u " ..
            "Rank=%u/%u",
            player:GetGUIDLow(),
            item:GetGUIDLow(),
            itemEntry,
            bossEntry,
            newProgress,
            config.maxRank
        ))

        return
    end


    -- ========================================================
    -- Jetzt erst Bosskill speichern
    -- ========================================================

    local registered = RegisterWeaponBossKill(
        player,
        item,
        bossEntry,
        newProgress
    )


    if not registered then

        player:SendBroadcastMessage(
            "|cffFF0000Keeper-Waffe:|r " ..
            "|cffFFFFFFProgression konnte nicht gespeichert werden.|r " ..
            "Siehe Worldserver-Konsole."
        )

        return
    end


    -- ========================================================
    -- Erfolgsmeldung
    -- ========================================================

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


-- ============================================================
-- Ermittelt und verarbeitet alle ausgerüsteten
-- Progressionswaffen eines Spielers
-- ============================================================
--
-- Equipment Slots 0-18 werden geprüft.
--
-- Wichtig:
-- Nur ein tatsächlich ausgerüstetes Item mit einer bekannten
-- Progressionskonfiguration wird verarbeitet.
-- ============================================================

local function ProcessEquippedProgressionWeapons(player, bossEntry)

    if not player then
        return
    end


    -- Playerbot-Schutz
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

                -- Zusätzliche Sicherheitsprüfung
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


-- ============================================================
-- Gruppenmitglieder verarbeiten
-- ============================================================

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


-- ============================================================
-- Boss Death
-- ============================================================

local function OnBossDied(event, creature, killer)

    if not creature then
        return
    end


    local bossEntry = creature:GetEntry()


    -- ========================================================
    -- Nur bekannte Progressionsbosse verarbeiten
    -- ========================================================

    if not KEEPER_BOSSES[bossEntry] then
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


    -- ========================================================
    -- Direkter Spieler als Killer
    -- ========================================================

    if killer.IsPlayer and killer:IsPlayer() then

        -- Normaler Spieler
        if not killer:IsBot() then

            ProcessEquippedProgressionWeapons(
                killer,
                bossEntry
            )

            return
        end


        -- ====================================================
        -- Playerbot als Killer:
        -- Nur menschliche Gruppenmitglieder verarbeiten.
        -- ====================================================

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
--
-- Jeder Boss wird nur EINMAL registriert.
-- ============================================================

local REGISTERED_BOSSES = {}


for bossEntry, _ in pairs(KEEPER_BOSSES) do

    if not REGISTERED_BOSSES[bossEntry] then

        RegisterCreatureEvent(
            bossEntry,
            CREATURE_EVENT_ON_DIED,
            OnBossDied
        )

        REGISTERED_BOSSES[bossEntry] = true
    end
end


-- ============================================================
-- Startmeldungen
-- ============================================================

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