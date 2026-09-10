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
-- Der Rang von Waffenschaden und allen konfigurierten Stats
-- ist immer identisch.
-- ============================================================


local RHOKDELAR_ENTRY = 18713
local LOKDELAR_ENTRY  = 18715

local MAX_PROGRESS = 48


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


-- ============================================================
-- ItemModType / item_template stat IDs
-- ============================================================
--
-- AzerothCore WotLK 3.3.5a
--
-- Diese Werte entsprechen direkt der ItemModType-Enum aus
-- ItemTemplate.h und damit auch mod-item-upgrade.stat_type.
--
-- 0 und 1 sind ebenfalls gültige ItemModType-Werte
-- (Mana / Health), auch wenn sie für unsere Keeper-Waffen
-- normalerweise nicht verwendet werden.
--
-- Nicht aufgeführte numerische Werte sind in 3.3.5a
-- keine gültigen ItemModType-Einträge.
-- ============================================================

local STAT_MANA                       = 0
local STAT_HEALTH                     = 1

local STAT_AGILITY                    = 3
local STAT_STRENGTH                   = 4
local STAT_INTELLECT                  = 5
local STAT_SPIRIT                     = 6
local STAT_STAMINA                    = 7

local STAT_DEFENSE_SKILL_RATING       = 12
local STAT_DODGE_RATING               = 13
local STAT_PARRY_RATING               = 14
local STAT_BLOCK_RATING               = 15

local STAT_HIT_MELEE_RATING           = 16
local STAT_HIT_RANGED_RATING          = 17
local STAT_HIT_SPELL_RATING           = 18

local STAT_CRIT_MELEE_RATING          = 19
local STAT_CRIT_RANGED_RATING         = 20
local STAT_CRIT_SPELL_RATING          = 21

local STAT_HIT_TAKEN_MELEE_RATING     = 22
local STAT_HIT_TAKEN_RANGED_RATING    = 23
local STAT_HIT_TAKEN_SPELL_RATING     = 24

local STAT_CRIT_TAKEN_MELEE_RATING    = 25
local STAT_CRIT_TAKEN_RANGED_RATING   = 26
local STAT_CRIT_TAKEN_SPELL_RATING    = 27

local STAT_HASTE_MELEE_RATING         = 28
local STAT_HASTE_RANGED_RATING        = 29
local STAT_HASTE_SPELL_RATING         = 30

local STAT_HIT_RATING                 = 31
local STAT_CRIT_RATING                = 32

local STAT_HIT_TAKEN_RATING           = 33
local STAT_CRIT_TAKEN_RATING          = 34

local STAT_RESILIENCE_RATING          = 35
local STAT_HASTE_RATING               = 36
local STAT_EXPERTISE_RATING           = 37

local STAT_ATTACK_POWER               = 38
local STAT_RANGED_ATTACK_POWER        = 39

local STAT_SPELL_HEALING_DONE         = 41
local STAT_SPELL_DAMAGE_DONE          = 42
local STAT_MANA_REGENERATION          = 43
local STAT_ARMOR_PENETRATION_RATING   = 44
local STAT_SPELL_POWER                = 45
local STAT_HEALTH_REGEN               = 46
local STAT_SPELL_PENETRATION          = 47
local STAT_BLOCK_VALUE                = 48


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
            STAT_STAMINA,    -- 7
            STAT_INTELLECT,  -- 5
        },

        bosses = KEEPER_BOSSES,
    },
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

    -- Sicherheitsprüfung:
    -- Nur tatsächlich ausgerüstete Items dürfen Progress erhalten.
    if not item:IsEquipped() then
        return
    end

    local itemEntry = item:GetEntry()
    local config = PROGRESSION_WEAPONS[itemEntry]

    if not config then
        return
    end

    -- Boss muss für diese Waffe konfiguriert sein.
    if not config.bosses[bossEntry] then
        return
    end

    -- Bereits für dieses Item erledigt?
    if HasWeaponKilledBoss(item, bossEntry) then
        return
    end

    -- Aktuellen Rang anhand der konkreten Item-GUID bestimmen.
    local currentProgress = GetWeaponProgress(item)

    if currentProgress >= config.maxRank then
        return
    end

    local newProgress = currentProgress + 1

    -- ========================================================
    -- NEUER ATOMARER C++-Aufruf
    --
    -- Weapon Damage + alle Stats + Bosskill werden
    -- innerhalb EINER DB-Transaktion verarbeitet.
    -- ========================================================

    local result = player:SetKeeperWeaponProgression(
        item,
        bossEntry,
        newProgress,
        config.stats,
        config.weaponDamage
    )

    -- 0 = Success
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

    -- ========================================================
    -- Erfolg
    -- ========================================================

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

local function OnPlayerKillCreature(event, killer, killed)

    if not killer or not killed then
        return
    end

    local bossEntry = killed:GetEntry()

    if not KEEPER_BOSSES[bossEntry] then
        return
    end

    -- Gruppenfall:
    -- Alle berechtigten menschlichen Spieler der Gruppe verarbeiten.
    local group = killed:GetLootRecipientGroup()

    if group then
        ProcessGroupMembers(
            killed,
            group,
            bossEntry
        )
        return
    end

    -- Kein Loot-Recipient-Group.
    if not killer.IsPlayer or not killer:IsPlayer() then
        return
    end

    -- Normaler menschlicher Spieler als Killer.
    if not killer:IsBot() then
        ProcessEquippedProgressionWeapons(
            killer,
            bossEntry
        )
        return
    end

    -- Playerbot als Killer:
    -- nur menschliche Gruppenmitglieder verarbeiten.
    local botGroup = killer:GetGroup()

    if botGroup then
        ProcessGroupMembers(
            killed,
            botGroup,
            bossEntry
        )
    end
end

RegisterPlayerEvent(
    PLAYER_EVENT_ON_KILL_CREATURE,
    OnPlayerKillCreature
)


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