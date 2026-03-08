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
    local config = C.configData[key]
    if not config then return nil end
    
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
    if config.tooltip then
      checkBox:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(config.tooltip)
        GameTooltip:Show()
      end)
      checkBox:HookScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)
    end
    checkBox.Text:SetText(config.label)
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

  local columnWidth = 300;
  local rowHeight = 30;
  local lastSectionRowCount = nil;

  local function createCheckboxSection(sectionLabel, configKeys, relativeTo)
    print("Creating section: " .. sectionLabel .. " with " .. #configKeys .. " checkboxes. Previous section had " .. (lastSectionRowCount or "nil") .. " rows.")
    local sectionTitle = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    sectionTitle:SetPoint("BOTTOMLEFT", relativeTo, 0, -(rowHeight * (lastSectionRowCount or 2)))
    sectionTitle:SetText(sectionLabel)

    local lastAnchor = nil
    for i, key in ipairs(configKeys) do
      local checkbox = createCheckbox(key)
      if checkbox then
        if i % 2 == 1 then
          local anchor = lastAnchor or sectionTitle
          local offset = lastAnchor and -rowHeight or (math.floor(-rowHeight / 2) - 4)
          checkbox:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, offset)
          lastAnchor = checkbox
        else
          local anchor = lastAnchor or sectionTitle
          checkbox:SetPoint("TOPLEFT", anchor, "TOPLEFT", columnWidth, 0)
        end
      else
        print("|cffff0000AltismManager [error]|r: Config data for key '" .. key .. "' not found.")
      end
    end

    lastSectionRowCount = math.ceil(#configKeys / 2) + 1
    return sectionTitle
  end

  ---------------------
  -- Generic Section --
  ---------------------
  local generalSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  generalSection:SetPoint("BOTTOMLEFT", title, 0, -24)
  generalSection:SetText("General Options")

  local goldToggle = createCheckbox("showGoldEnabled")
  if goldToggle then
    goldToggle:SetPoint("TOPLEFT", generalSection, "BOTTOMLEFT", 0, -8)
  else
    print("|cffff0000[AltismManager][error]|r: Config toggle for gold missing")
  end

  local vaultSection = createCheckboxSection(
    "Vault Section", C.sections[C.sectionNames["Vault"]], generalSection)
  local assortedPvMSection = createCheckboxSection(
    "Assorted PvM Section", C.sections[C.sectionNames["Misc"]], vaultSection)
  local delveSection = createCheckboxSection(
    "Delve Section", C.sections[C.sectionNames["Delve"]], assortedPvMSection)
  local worldContentSection = createCheckboxSection(
    "World Content Section", C.sections[C.sectionNames["World Content"]], delveSection)
  local upgradeCrestSection = createCheckboxSection(
    "Upgrade Crest Section", C.sections[C.sectionNames["Crests"]], worldContentSection)
  local pvpSection = createCheckboxSection(
    "PVP Section", C.sections[C.sectionNames["PVP"]], upgradeCrestSection)
  createCheckboxSection(
    "Boss Section", C.sections[C.sectionNames["Raids"]], pvpSection)

  frame:SetScript("OnShow", nil)
end)

if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
  local category = Settings.RegisterCanvasLayoutCategory(mainFrame, mainFrame.name);
  Settings.RegisterAddOnCategory(category);
  addon.settingsCategory = category;
end