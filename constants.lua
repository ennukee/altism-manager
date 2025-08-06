local addoName, addon = ...

local C = {}

C.ids = {
  -- Lowest to highest tier crests, may not be called these names in the future
  weathered_crest = 3284,
  carved_crest = 3286,
  runed_crest = 3288,
  gilded_crest = 3290,
  -- Important PvM currencies
  ethereal_strands = 3278, -- ADD TO UI
  spark = 3141,
  catalyst = 3269,
  vault_reroll_token = 248242,
  -- Delve
  coffer1 = 84736,
  coffer2 = 84737,
  coffer3 = 84738,
  coffer4 = 84739,
  currentCofferKeys = 3028,
  delversBounty = 86371,
  -- Raid
  raid = 2406, -- NEED 11.2 UPDATE
  worldBoss = 87345
}

C.thresholds = {
  mythTrackKeyVault = 10,
  maxLootDelveVault = 8,
}

C.pixelSizing = {
  baseWindowSize = 670,
  offsetX = 0,
  offsetY = 40,
  perAltX = 150,
  ilvlTextSize = 8,
  removeButtonSize = 12,
  minSizeX = 300,
}

local TraditionalRowValue = 20;
C.toggles = {
  gap = TraditionalRowValue,
  gold = 20,

  raidVault = TraditionalRowValue,
  mythicPlusVault = TraditionalRowValue,
  delveVault = TraditionalRowValue,
  mythicPlus = TraditionalRowValue * 2,

  valorstones = TraditionalRowValue,
  spark = TraditionalRowValue,
  catalyst = TraditionalRowValue,
  algariTokensOfMerit = TraditionalRowValue,
  etherealStrands = TraditionalRowValue,

  cofferKeys = TraditionalRowValue,
  currentCofferKeys = TraditionalRowValue,
  delverBounty = TraditionalRowValue,
  
  whelpling = TraditionalRowValue,
  drake = TraditionalRowValue,
  wyrm = TraditionalRowValue,
  aspect = TraditionalRowValue,

  pvp = TraditionalRowValue * 3,
  
  worldBoss = TraditionalRowValue,
  mythic = TraditionalRowValue,
  heroic = TraditionalRowValue,
  normal = TraditionalRowValue,
};

C.labels = {
  -- [[ Left-column row labels ]] --
  name = "",
  
  raidVault = "Raid Vault",
  mythicPlusVault = "M+ Vault",
  delveVault = "Delve Vault",
  mythicKeystone = "Keystone |T525134:16:16:0:0|t",
  mythicPlusRating = "Mythic+ Rating",
  
  flightstones = "Valorstones |T5868902:16:16:0:0|t",
  sparks = "Sparks |T5929747:16:16:0:0|t",
  catalyst = "Catalyst |T610613:16:16:0:0|t",
  algariTokensOfMerit = "Vault Tokens |T2744751:16:16:0:0|t",
  etherealStrands = "Eth. Strands |T5931153:16:16:0:0|t",

  cofferKeys = "Weekly Coffer Keys",
  currentCofferKeys = "Coffer Keys |T4622270:16:16:0:0|t",
  delversBounty = "Delver Bounty |T1064187:16:16:0:0|t",

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

C.configLabels = {
  showGoldEnabled = "Show Gold",

  showRaidVaultEnabled = "Show Raid Vault",
  showMythicPlusVaultEnabled = "Show Mythic+ Vault",
  showDelveVaultEnabled = "Show Delve Vault",
  showMythicPlusDataEnabled = "Show M+ Keystone/Rating",
  
  showValorstonesEnabled = "Show Valorstones",
  showSparksEnabled = "Show Fractured Spark of Fortune progress",
  showCatalystEnabled = "Show Catalyst charges remaining",
  showAlgariTokensOfMeritEnabled = "Show Algari Tokens of Merit",
  showEtherealStrandsEnabled = "Show Ethereal Strands",

  showCofferKeysEnabled = "Show Weekly Coffer Keys earned",
  showCurrentCofferKeysEnabled = "Show Owned Coffer Keys",
  showDelversBountyEnabled = "Show Delver's Bounty completion",

  showRemainingCrestsEnabled = "Show remaining crests to be earned up to cap",
  showWhelplingCrestEnabled = "Show Weathered Crests",
  showDrakeCrestEnabled = "Show Carved Crests",
  showWyrmCrestEnabled = "Show Runed Crests",
  showAspectCrestEnabled = "Show Gilded Crests",

  showPVPCurrenciesEnabled = "Show PVP Currency",

  showWorldBossEnabled = "Show World Boss",
  showUndermineEnabled = "Show Manaforge Omega",
  showUndermineMythicEnabled = "Show Manaforge Omega Mythic",
  showUndermineHeroicEnabled = "Show Manaforge Omega Heroic",
  showUndermineNormalEnabled = "Show Manaforge Omega Normal",
}

C.configTooltips = {
  showAlgariTokensOfMeritEnabled = "Show the number of Algari Tokens of Merit in bags (vault socket tokens)",
  showUndermineEnabled = "If disabled, this will overwrite any N/H/M settings below and disable all of them.",
  showRemainingCrestsEnabled = "Whether or not to show additional earnable crests via a (+#) visual in the row",
}

C.misc = {
  minLevelToShow = 70,
}

addon.C = C

C.classSpells = {
  WARRIOR = 355, -- Taunt
  PALADIN = 62124, -- Hand of Reckoning
  MAGE = 108853, -- Fire Blast
  EVOKER = 361469, -- Living Flame
  DEMONHUNTER = 185123, -- Throw Glaive
  DRUID = 5176, -- Wrath
  MONK = 115546, -- Provoke
  PRIEST = 589, -- SW:P
  ROGUE = 36554, -- Poisoned Knife
  SHAMAN = 188389, -- Lightning Bolt
  DEATHKNIGHT = 49576, -- Death Grip

  HUNTER = 193455, -- Cobra Shot
  WARLOCK = 686, -- Shadow Bolt
}