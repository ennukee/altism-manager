local addoName, addon = ...

local C = {}

-- ! ALL IDs NEED AN UPDATE FOR 12.0 WHEN AVAILABLE
C.ids = {
  -- Lowest to highest tier crests, may not be called these names in the future
  weathered_crest = 3383,
  carved_crest = 3341,
  runed_crest = 3343,
  gilded_crest = 3345,
  myth_crest = 3347,
  -- Important PvM currencies
  spark = 3212,
  catalyst = 3378,
  vault_tokens = 248242,
  -- Delve
  coffer1 = 84736,
  coffer2 = 84737,
  coffer3 = 84738,
  coffer4 = 84739,
  -- World Content
  soireeRunestone1 = 90574,
  soireeRunestone2 = 90575,
  soireeRunestone3 = 90573,
  soireeRunestone4 = 90576,
  abundance = 89507,
  memoryOfHarandar1 = 89268,
  memoryOfHarandar2 = 0,--88994,
  memoryOfHarandar3 = 0,--88995,
  memoryOfHarandar4 = 0,--88996,
  memoryOfHarandar5 = 0,--88997,
  stormarionAssault = 90962,
  -- currentCompleteCofferKeys = 3028, // TODO
  currentCofferKeys = 3310,
  delversBounty = 86371,
  crackedKeystoneQuest = 90779,
  -- Raid
  raid = 2406,
  worldBoss = 87345,
  -- Expansion-zones
  specialAssignments = {
    {
      94391, -- Harandar "Push Back the Light"
      93013, -- Harandar "Push Back the Light" (unlocked)
    },
    {
      94390, -- Harandar "A Hunter's Regret"
      92063, -- Harandar "A Hunter's Regret" (unlocked)
    },
    {
      94743, -- Voidstorm "Precision Excision"
      93438, -- Voidstorm "Precision Excision" (unlocked)
    },
    {
      94795, -- Voidstorm "Agents of the Shield"
      93244, -- Voidstorm "Agents of the Shield" (unlocked)
    },
    {
      94865, -- Zul'Aman "What Remains of a Temple Broken"
      91390, -- Zul'Aman "What Remains of a Temple Broken" (unlocked)
    },
    {
      94866, -- Zul'Aman "Once Ours More!"
      91796, -- Zul'Aman "Once Ours More!" (unlocked)
    },
    {
      92848, -- Eversong "The Grand Magister's Drink"
      92145, -- Eversong "The Grand Magister's Drink" (unlocked)
    }
  },
}

C.thresholds = {
  mythTrackKeyVault = 10,
  maxLootDelveVault = 8,
}

C.TraditionalRowValue = 20
C.sectionNames = {
  ["Vault"] = 0,
  ["Misc"] = 1,
  ["Delve"] = 2,
  ["World Content"] = 3,
  ["Crests"] = 4,
  ["PVP"] = 5,
  ["Raids"] = 6,
}
C.sections = {
  [0] = {
    "showRaidVaultEnabled",
    "showMythicPlusVaultEnabled",
    "showDelveVaultEnabled",
    "showMythicPlusDataEnabled",
  },
  [1] = {
    "showSparksEnabled",
    "showCatalystEnabled",
    "showVaultTokensEnabled",
  },
  [2] = {
    "showCurrentCofferKeysEnabled",
    "showCofferKeysEnabled",
    "showDelversBountyEnabled",
    "showCrackedKeystoneEnabled",
  },
  [3] = {
    "showSoireeRunestoneEnabled",
    "showAbundanceEnabled",
    "showMemoryOfHarandarEnabled",
    "showStormarionAssaultEnabled",
    "showSpecialAssignmentsEnabled",
  },
  [4] = {
    "showTier1Crest",
    "showTier2Crest",
    "showTier3Crest",
    "showTier4Crest",
    "showTier5Crest",
  },
  [5] = {"showPVPCurrenciesEnabled"},
  [6] = {
    "showWorldBossEnabled",
    "showMythicRaidEnabled",
    "showHeroicRaidEnabled",
    "showNormalRaidEnabled",
  },
}
C.configData = {
  showGoldEnabled = {
    label = "Show Gold",
    default = true,
    height = C.TraditionalRowValue,
  },
  showRaidVaultEnabled = {
    label = "Show Raid Vault",
    default = true,
    height = C.TraditionalRowValue,
  },
  showMythicPlusVaultEnabled = {
    label = "Show Mythic+ Vault",
    default = true,
    height = C.TraditionalRowValue,
  },
  showDelveVaultEnabled = {
    label = "Show Delve Vault",
    default = true,
    height = C.TraditionalRowValue,
  },
  showMythicPlusDataEnabled = {
    label = "Show M+ Keystone/Rating",
    default = true,
    height = C.TraditionalRowValue * 2,
  },
  showSparksEnabled = {
    label = "Show Fractured Spark of Fortune progress",
    default = true,
    height = C.TraditionalRowValue,
  },
  showCatalystEnabled = {
    label = "Show Catalyst charges remaining",
    default = true,
    height = C.TraditionalRowValue,
  },
  showVaultTokensEnabled = {
    label = "Show Vault Tokens",
    default = true,
    height = C.TraditionalRowValue,
    tooltip = "Show the number of Vault Tokens in bags",
  },
  showCurrentCofferKeysEnabled = {
    label = "Show Owned Coffer Keys",
    default = true,
    height = C.TraditionalRowValue,
  },
  showCofferKeysEnabled = {
    label = "Show Weekly Coffer Keys earned",
    default = false,
    height = C.TraditionalRowValue,
  },
  showDelversBountyEnabled = {
    label = "Show Delver's Bounty completion",
    default = true,
    height = C.TraditionalRowValue,
  },
  -- showCrackedKeystoneEnabled = {
  --   label = "Show Cracked Keystone one-time quest",
  --   default = true,
  --   height = C.TraditionalRowValue,
  --   tooltip = "Cracked Keystone is a one-time quest per character per season that rewards 15 uncapped gilded crests",
  -- },
  showSoireeRunestoneEnabled = {
    label = "Show Eversong Runestone completion",
    default = true,
    height = C.TraditionalRowValue,
  },
  showAbundanceEnabled = {
    label = "Show Abundance completion",
    default = true,
    height = C.TraditionalRowValue,
  },
  showMemoryOfHarandarEnabled = {
    label = "Show Memory of Harandar completion",
    default = true,
    height = C.TraditionalRowValue,
  },
  showStormarionAssaultEnabled = {
    label = "Show Stormarion Assault completion",
    default = true,
    height = C.TraditionalRowValue,
  },
  showSpecialAssignmentsEnabled = {
    label = "Show Special Assignments remaining on map",
    default = true,
    height = C.TraditionalRowValue,
  },
  showRemainingCrestsEnabled = {
    label = "Show remaining crests to be earned up to cap",
    default = true,
    height = 0,
    tooltip = "Whether or not to show additional earnable crests via a (+#) visual in the row (does nothing if crest cap is removed in Turbo Boost)",
  },
  showTier1Crest = {
    label = "Show Adventurer Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showTier2Crest = {
    label = "Show Veteran Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showTier3Crest = {
    label = "Show Champion Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showTier4Crest = {
    label = "Show Hero Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showTier5Crest = {
    label = "Show Myth Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showPVPCurrenciesEnabled = {
    label = "Show PVP Currency",
    default = false,
    height = C.TraditionalRowValue * 3,
  },
  showWorldBossEnabled = {
    label = "Show World Boss",
    default = true,
    height = C.TraditionalRowValue,
  },
  showMythicRaidEnabled = {
    label = "Show Manaforge Omega Mythic",
    default = true,
    height = C.TraditionalRowValue,
  },
  showHeroicRaidEnabled = {
    label = "Show Manaforge Omega Heroic",
    default = true,
    height = C.TraditionalRowValue,
  },
  showNormalRaidEnabled = {
    label = "Show Manaforge Omega Normal",
    default = true,
    height = C.TraditionalRowValue,
  },
}

C.pixelSizing = {
  baseWindowSize = (function()
    local total = 0
    for _, cfg in pairs(C.configData) do
      total = total + (cfg.height or 0)
    end
    total = total + (#C.sections * C.TraditionalRowValue)
    total = total + 50 -- Generic padding for the dialog
    return total
  end)(),
  offsetX = 0,
  offsetY = 40,
  perAltX = 150,
  ilvlTextSize = 9,
  removeButtonSize = 12,
  minSizeX = 300,
}

C.labels = {
  -- [[ Left-column row labels ]] --
  name = "",
  
  raidVault = "Raid Vault",
  mythicPlusVault = "M+ Vault",
  delveVault = "Delve Vault",
  mythicKeystone = "Keystone |T525134:16:16:0:0|t",
  mythicPlusRating = "Mythic+ Rating",
  
  sparks = "Sparks |T7551418:16:16:0:0|t",
  catalyst = "Catalyst |T4622294:16:16:0:0|t",
  vaultTokens = "Vault Tokens |T2744751:16:16:0:0|t",

  cofferKeys = "Weekly Keys",
  currentCofferKeys = "Current Shards |T133016:16:16:0:0|t",
  delversBounty = "Delver Bounty |T1064187:16:16:0:0|t",
  -- crackedKeystoneDone = "Cracked Keyst. |T4352494:16:16:0:0|t",

  soireeRunestone = "Eversong Runestone",
  abundance = "Abundance",
  memoryOfHarandar = "Harandar Memory",
  stormarionAssault = "Stormarion Assault",
  specialAssignments = "Special Asgmt",

  upgradeCrests = "Upgrade Crests",
  whelplingCrest = "Adventurer |T7639517:16:16:0:0|t",
  drakeCrest = "Veteran |T7639525:16:16:0:0|t",
  wyrmCrest = "Champion |T7639519:16:16:0:0|t",
  aspectCrest = "Hero |T7639521:16:16:0:0|t",
  mythCrest = "Myth |T7639523:16:16:0:0|t",
  
  pvpCurrency = "PVP Currency",
  honor = "Honor |T1455894:16:16:0:0|t",
  conquest = "Conquest |T1523630:16:16:0:0|t",
  conquestEarned = "Conquest Earned",
  
  worldBoss = "World Boss",
  mythic = "Mythic",
  heroic = "Heroic",
  normal = "Normal",
}

C.misc = {
  minLevelToShow = 80,
}

addon.C = C