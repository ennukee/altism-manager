local addoName, addon = ...

local C = {}

-- ! ALL IDs NEED AN UPDATE FOR 12.0 WHEN AVAILABLE
C.ids = {
  -- Lowest to highest tier crests, may not be called these names in the future
  weathered_crest = 3284,
  carved_crest = 3286,
  runed_crest = 3288,
  gilded_crest = 3290,
  -- Important PvM currencies
  spark = 3141,
  catalyst = 3269,
  vault_tokens = 248242,
  -- Delve
  coffer1 = 84736,
  coffer2 = 84737,
  coffer3 = 84738,
  coffer4 = 84739,
  currentCofferKeys = 3028,
  delversBounty = 86371,
  crackedKeystoneQuest = 90779,
  -- Raid
  raid = 2406,
  worldBoss = 87345
}

C.thresholds = {
  mythTrackKeyVault = 10,
  maxLootDelveVault = 8,
}

C.TraditionalRowValue = 20;
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
    "showTier1Crest",
    "showTier2Crest",
    "showTier3Crest",
    "showTier4Crest",
  },
  [4] = {"showPVPCurrenciesEnabled"},
  [5] = {
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
  showRemainingCrestsEnabled = {
    label = "Show remaining crests to be earned up to cap",
    default = true,
    height = 0,
    tooltip = "Whether or not to show additional earnable crests via a (+#) visual in the row (does nothing if crest cap is removed in Turbo Boost)",
  },
  showTier1Crest = {
    label = "Show Weathered Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showTier2Crest = {
    label = "Show Carved Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showTier3Crest = {
    label = "Show Runed Crests",
    default = true,
    height = C.TraditionalRowValue,
  },
  showTier4Crest = {
    label = "Show Gilded Crests",
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
  
  sparks = "Sparks |T5929747:16:16:0:0|t",
  catalyst = "Catalyst |T610613:16:16:0:0|t",
  vaultTokens = "Vault Tokens |T2744751:16:16:0:0|t",

  cofferKeys = "Weekly Keys",
  currentCofferKeys = "Current Keys |T4622270:16:16:0:0|t",
  delversBounty = "Delver Bounty |T1064187:16:16:0:0|t",
  -- crackedKeystoneDone = "Cracked Keyst. |T4352494:16:16:0:0|t",

  upgradeCrests = "Upgrade Crests",
  whelplingCrest = "Weathered |T5872061:16:16:0:0|t",
  drakeCrest = "Carved |T5872055:16:16:0:0|t",
  wyrmCrest = "Runed |T5872059:16:16:0:0|t",
  aspectCrest = "Gilded |T5872057:16:16:0:0|t",
  
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
  minLevelToShow = 70,
}

addon.C = C