local addoName, addon = ...

local C = {}

C.thresholds = {
  mythTrackKeyVault = 10,
  maxLootDelveVault = 8,
}

C.pixelSizing = {
  baseWindowSize = 570,
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
  cofferKeys = TraditionalRowValue,
  spark = TraditionalRowValue,
  catalyst = TraditionalRowValue,
  
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
  cofferKeys = "Coffer Keys |T4622270:16:16:0:0|t",
  sparks = "Sparks |T5929751:16:16:0:0|t",
  catalyst = "Catalyst |T3566851:16:16:0:0|t",

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
  showCofferKeysEnabled = "Show Coffer Keys",
  showSparksEnabled = "Show Fractured Spark of Fortune progress",
  showCatalystEnabled = "Show Catalyst charges remaining",

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
  showUndermineEnabled = "If disabled, this will overwrite any N/H/M settings below and disable all of them.",
}

C.misc = {
  minLevelToShow = 70,
}



addon.C = C