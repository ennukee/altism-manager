local addonName, addon = ...
if not addon.healthCheck then return end

local C = addon.C;

local mainFrame = CreateFrame("Frame")
mainFrame.name = addonName
mainFrame:Hide()

local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, 0)
scrollFrame:SetPoint("BOTTOMRIGHT", -20, 0)

local frame = CreateFrame("Frame")
scrollFrame:SetScrollChild(frame)
frame:SetWidth(SettingsPanel.Container:GetWidth() - 18)
frame:SetHeight(SettingsPanel.Container:GetHeight() - 32)

frame:SetScript("OnShow", function()
  local function createCheckbox(key)
    local checkBox = CreateFrame("CheckButton", addonName .. "Check" .. key, frame, "InterfaceOptionsCheckButtonTemplate")
    checkBox:SetChecked(AltismManagerDB[key])
    checkBox:HookScript("OnClick", function(self)
      local checked = self:GetChecked()
      AltismManagerDB[key] = checked
      if checked then
				PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
			else
				PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
			end
    end)
    if C.configTooltips[key] then
      checkBox:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(C.configTooltips[key])
        GameTooltip:Show()
      end)
      checkBox:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
    end
    checkBox.Text:SetText(C.configLabels[key])
    return checkBox
  end

  local title = frame:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(addonName)

	local subtitle = frame:CreateFontString("ARTWORK", nil, "GameFontNormalSmall")
  subtitle:SetPoint("TOPRIGHT", -16, -16)
  subtitle:SetText("Any changes will require a UI reload (/reload) to take effect.")

  -- ! Reload button next to the title
  local reloadButton = CreateFrame("Button", "AMReloadButton", frame)
  reloadButton:SetSize(16, 16)
  reloadButton:SetPoint("TOPRIGHT", title, 22, 0)

  local texture = reloadButton:CreateTexture(nil, "ARTWORK")
  texture:SetAllPoints()
  texture:SetTexture("Interface\\Buttons\\UI-RefreshButton")
  reloadButton.texture = texture

  reloadButton:SetScript("OnClick", function()
      ReloadUI()
  end)

  reloadButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Reload UI")
    GameTooltip:Show()
  end)

  reloadButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  -- ! End reload button creation

  local columnWidth = 250;
  local rowHeight = 30;
  ---------------------
  -- Generic Section --
  ---------------------
  local generalSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  generalSection:SetPoint("BOTTOMLEFT", title, 0, -24)
  generalSection:SetText("General Options")

  local goldToggle = createCheckbox("showGoldEnabled")
  goldToggle:SetPoint("TOPLEFT", generalSection, "BOTTOMLEFT", 0, -8)

  -------------------
  -- Vault Section --
  -------------------
  local vaultSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  vaultSection:SetPoint("BOTTOMLEFT", generalSection, 0, -(rowHeight * 2))
  vaultSection:SetText("Vault Section")

  local showRaidVault = createCheckbox("showRaidVaultEnabled")
  showRaidVault:SetPoint("TOPLEFT", vaultSection, "BOTTOMLEFT", 0, -8)

  local showMythicPlusVault = createCheckbox("showMythicPlusVaultEnabled")
  showMythicPlusVault:SetPoint("TOPLEFT", vaultSection, "BOTTOMLEFT", columnWidth, -8)

  local showDelveVault = createCheckbox("showDelveVaultEnabled")
  showDelveVault:SetPoint("TOPLEFT", showRaidVault, "BOTTOMLEFT", 0, -2)

  local showMythicPlusData = createCheckbox("showMythicPlusDataEnabled")
  showMythicPlusData:SetPoint("TOPLEFT", showMythicPlusVault, "BOTTOMLEFT", 0, -2)

  ------------------------
  -- Valorstone Section --
  ------------------------
  local valorstoneSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  valorstoneSection:SetPoint("BOTTOMLEFT", vaultSection, 0, -(rowHeight * 3))
  valorstoneSection:SetText("Valorstone Section")

  local showValorstones = createCheckbox("showValorstonesEnabled")
  showValorstones:SetPoint("TOPLEFT", valorstoneSection, "BOTTOMLEFT", 0, -8)

  local showSparks = createCheckbox("showSparksEnabled")
  showSparks:SetPoint("TOPLEFT", showValorstones, "BOTTOMLEFT", 0, -2)

  local showCatalyst = createCheckbox("showCatalystEnabled")
  showCatalyst:SetPoint("TOPLEFT", valorstoneSection, "BOTTOMLEFT", columnWidth, -8)

  local showAlgariTokensOfMerit = createCheckbox("showAlgariTokensOfMeritEnabled")
  showAlgariTokensOfMerit:SetPoint("TOPLEFT", showCatalyst, "BOTTOMLEFT", 0, -2)

  local showEtherealStrands = createCheckbox("showEtherealStrandsEnabled")
  showEtherealStrands:SetPoint("TOPLEFT", showSparks, "BOTTOMLEFT", 0, -2)

  -------------------
  -- Delve Section --
  -------------------
  local delveSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  delveSection:SetPoint("BOTTOMLEFT", valorstoneSection, 0, -(rowHeight * 4))
  delveSection:SetText("Delve Section")

  local showCofferKeys = createCheckbox("showCofferKeysEnabled")
  showCofferKeys:SetPoint("TOPLEFT", delveSection, "BOTTOMLEFT", 0, -8)

  local showCurrentCofferKeys = createCheckbox("showCurrentCofferKeysEnabled")
  showCurrentCofferKeys:SetPoint("TOPLEFT", delveSection, "BOTTOMLEFT", columnWidth, -8);

  local showDelversBounty = createCheckbox("showDelversBountyEnabled")
  showDelversBounty:SetPoint("TOPLEFT", showCofferKeys, "BOTTOMLEFT", 0, -2)

  local showCrackedKeystoneEnabled = createCheckbox("showCrackedKeystoneEnabled")
  showCrackedKeystoneEnabled:SetPoint("TOPLEFT", showCurrentCofferKeys, "BOTTOMLEFT", 0, -2)

  ---------------------------
  -- Upgrade Crest Section --
  ---------------------------
  local upgradeCrestSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  upgradeCrestSection:SetPoint("BOTTOMLEFT", delveSection, 0, -(rowHeight * 3))
  upgradeCrestSection:SetText("Upgrade Crest Section")

  local showRemainingCrests = createCheckbox("showRemainingCrestsEnabled")
  showRemainingCrests:SetPoint("TOPLEFT", upgradeCrestSection, "BOTTOMLEFT", 0, -8)

  local showWhelplingCrest = createCheckbox("showWhelplingCrestEnabled")
  showWhelplingCrest:SetPoint("TOPLEFT", showRemainingCrests, "BOTTOMLEFT", 0, -2)

  local showDrakeCrest = createCheckbox("showDrakeCrestEnabled")
  showDrakeCrest:SetPoint("TOPLEFT", showRemainingCrests, "BOTTOMLEFT", columnWidth, -2)

  local showWyrmCrest = createCheckbox("showWyrmCrestEnabled")
  showWyrmCrest:SetPoint("TOPLEFT", showWhelplingCrest, "BOTTOMLEFT", 0, -2)

  local showAspectCrest = createCheckbox("showAspectCrestEnabled")
  showAspectCrest:SetPoint("TOPLEFT", showDrakeCrest, "BOTTOMLEFT", 0, -2)

  -----------------
  -- PVP Section --
  -----------------
  local pvpSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  pvpSection:SetPoint("BOTTOMLEFT", upgradeCrestSection, 0, -(rowHeight * 4))
  pvpSection:SetText("PVP Currency Section")

  local showPVPCurrencies = createCheckbox("showPVPCurrenciesEnabled")
  showPVPCurrencies:SetPoint("TOPLEFT", pvpSection, "BOTTOMLEFT", 0, -8)

  ------------------
  -- Boss Section --
  ------------------
  local bossSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  bossSection:SetPoint("BOTTOMLEFT", pvpSection, 0, -(rowHeight * 2))
  bossSection:SetText("Boss Section")

  local showWorldBoss = createCheckbox("showWorldBossEnabled")
  showWorldBoss:SetPoint("TOPLEFT", bossSection, "BOTTOMLEFT", 0, -8)

  local showUndermine = createCheckbox("showUndermineEnabled")
  showUndermine:SetPoint("TOPLEFT", showWorldBoss, "BOTTOMLEFT", 0, -2)

  local showUndermineNormal = createCheckbox("showUndermineNormalEnabled")
  showUndermineNormal:SetPoint("TOPLEFT", showUndermine, "BOTTOMLEFT", 16, -1)

  local showUndermineHeroic = createCheckbox("showUndermineHeroicEnabled")
  showUndermineHeroic:SetPoint("TOPLEFT", showUndermineNormal, "BOTTOMLEFT", 0, -1)

  local showUndermineMythic = createCheckbox("showUndermineMythicEnabled")
  showUndermineMythic:SetPoint("TOPLEFT", showUndermineHeroic, "BOTTOMLEFT", 0, -1)

  frame:SetScript("OnShow", nil)
end)

if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
  local category = Settings.RegisterCanvasLayoutCategory(mainFrame, mainFrame.name);
  Settings.RegisterAddOnCategory(category);
  addon.settingsCategory = category;
end