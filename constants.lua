local addoName, addon = ...

local C = {}

C.thresholds = {
  mythTrackKeyVault = 10,
  maxLootDelveVault = 8,
}

C.pixelSizing = {
  baseWindowSize = 650,
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
  sparks = "Sparks |T5929751:16:16:0:0|t",
  catalyst = "Catalyst |T3566851:16:16:0:0|t",
  algariTokensOfMerit = "Vault Tokens |T2744751:16:16:0:0|t",

  cofferKeys = "Weekly Coffer Keys",
  currentCofferKeys = "Coffer Keys |T4622270:16:16:0:0|t",
  delversBounty = "Delver Bounty |T1064187:16:16:0:0|t",

  upgradeCrests = "Upgrade Crests",
  whelplingCrest = "Weathered |T5872053:16:16:0:0|t",
  drakeCrest = "Carved |T5872047:16:16:0:0|t",
  wyrmCrest = "Runed |T5872051:16:16:0:0|t",
  aspectCrest = "Gilded |T5872049:16:16:0:0|t",
  
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
  showUndermineEnabled = "Show Liberation of Undermine",
  showUndermineMythicEnabled = "Show Undermine Mythic",
  showUndermineHeroicEnabled = "Show Undermine Heroic",
  showUndermineNormalEnabled = "Show Undermine Normal",
}

C.configTooltips = {
  showAlgariTokensOfMeritEnabled = "Show the number of Algari Tokens of Merit in bags (vault socket tokens)",
  showUndermineEnabled = "If disabled, this will overwrite any N/H/M settings below and disable all of them.",
  showRemainingCrestsEnabled = "This does NOTHING if crests are uncapped (e.g. after May 13th)",
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