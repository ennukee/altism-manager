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
  local manualOrderRows = {}
  local manualOrderGuids = {}

  local function createCheckboxSection(sectionLabel, configKeys, relativeTo)
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

  local function buildManualOrderGuidList()
    local db = AltismManagerDB
    local result = {}
    if not db or not db.data then
      return result
    end

    db.manualCharacterOrder = db.manualCharacterOrder or {}

    local seen = {}
    for _, guid in ipairs(db.manualCharacterOrder) do
      if db.data[guid] and not seen[guid] then
        table.insert(result, guid)
        seen[guid] = true
      end
    end

    local remainder = {}
    for guid, charData in pairs(db.data) do
      if not seen[guid] then
        table.insert(remainder, {
          guid = guid,
          ilevel = charData.ilevel or 0,
          name = charData.name or "",
          realm = charData.realm or "",
        })
      end
    end

    table.sort(remainder, function(left, right)
      if left.ilevel ~= right.ilevel then
        return left.ilevel > right.ilevel
      end
      if left.name ~= right.name then
        return left.name < right.name
      end
      if left.realm ~= right.realm then
        return left.realm < right.realm
      end
      return left.guid < right.guid
    end)

    for _, entry in ipairs(remainder) do
      table.insert(result, entry.guid)
    end

    return result
  end

  local function saveManualOrderGuidList()
    AltismManagerDB.manualCharacterOrder = {}
    for _, guid in ipairs(manualOrderGuids) do
      table.insert(AltismManagerDB.manualCharacterOrder, guid)
    end
  end

  local function manualDisplayName(guid)
    local charData = AltismManagerDB and AltismManagerDB.data and AltismManagerDB.data[guid]
    if not charData then
      return "Unknown-Unknown"
    end
    return tostring(charData.name or "Unknown") .. "-" .. tostring(charData.realm or "Unknown")
  end

  local function refreshMainFrameIfVisible()
    if addon and addon.main_frame and addon.main_frame:IsShown() and addon.UpdateStrings then
      addon:UpdateStrings()
    end
  end

  local function refreshManualOrderRows()
    local isManualEnabled = AltismManagerDB and AltismManagerDB.manualCharacterOrderEnabled
    for i, row in ipairs(manualOrderRows) do
      local guid = manualOrderGuids[i]
      row.guid = guid
      row.index = i
      if guid then
        row.text:SetText(i .. ". " .. manualDisplayName(guid))
        row.text:SetTextColor(1, 1, 1, 1)
        row.upButton:Show()
        row.downButton:Show()
        row.upButton:SetEnabled(isManualEnabled and i > 1)
        row.downButton:SetEnabled(isManualEnabled and i < #manualOrderGuids)
      else
        row.text:SetText("")
        row.upButton:Hide()
        row.downButton:Hide()
      end
    end
  end

  local function moveManualCharacter(oldIndex, newIndex)
    if newIndex < 1 or newIndex > #manualOrderGuids then
      return
    end
    manualOrderGuids[oldIndex], manualOrderGuids[newIndex] = manualOrderGuids[newIndex], manualOrderGuids[oldIndex]
    saveManualOrderGuidList()
    refreshManualOrderRows()
    refreshMainFrameIfVisible()
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
  local bossSection = createCheckboxSection(
    "Boss Section", C.sections[C.sectionNames["Raids"]], pvpSection)

  local manualOrderSection = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
  manualOrderSection:SetPoint("BOTTOMLEFT", bossSection, 0, -(rowHeight * (lastSectionRowCount or 2)))
  manualOrderSection:SetText("Character Ordering")

  local manualOrderToggle = createCheckbox("manualCharacterOrderEnabled")
  if manualOrderToggle then
    manualOrderToggle:SetPoint("TOPLEFT", manualOrderSection, "BOTTOMLEFT", 0, -8)
  end

  manualOrderGuids = buildManualOrderGuidList()
  saveManualOrderGuidList()

  local previousRow = nil
  for i, guid in ipairs(manualOrderGuids) do
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(560, 22)
    if not previousRow then
      if manualOrderToggle then
        row:SetPoint("TOPLEFT", manualOrderToggle, "BOTTOMLEFT", 0, -6)
      else
        row:SetPoint("TOPLEFT", manualOrderSection, "BOTTOMLEFT", 0, -12)
      end
    else
      row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -4)
    end

    row.text = row:CreateFontString("ARTWORK", nil, "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 46, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWidth(500)
    row.text:SetText(i .. ". " .. manualDisplayName(guid))

    row.upButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.upButton:SetSize(20, 20)
    row.upButton:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.upButton:SetText("^")

    row.downButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.downButton:SetSize(20, 20)
    row.downButton:SetPoint("LEFT", row.upButton, "RIGHT", 4, 0)
    row.downButton:SetText("v")

    row.index = i
    row.guid = guid
    row.upButton:SetScript("OnClick", function(self)
      local index = self:GetParent().index
      moveManualCharacter(index, index - 1)
    end)
    row.downButton:SetScript("OnClick", function(self)
      local index = self:GetParent().index
      moveManualCharacter(index, index + 1)
    end)

    table.insert(manualOrderRows, row)
    previousRow = row
  end

  if #manualOrderRows == 0 then
    local emptyText = frame:CreateFontString("ARTWORK", nil, "GameFontHighlightSmall")
    if manualOrderToggle then
      emptyText:SetPoint("TOPLEFT", manualOrderToggle, "BOTTOMLEFT", 0, -6)
    else
      emptyText:SetPoint("TOPLEFT", manualOrderSection, "BOTTOMLEFT", 0, -12)
    end
    emptyText:SetText("No known characters yet. Log onto characters first to populate this list.")
  end

  if manualOrderToggle then
    manualOrderToggle:HookScript("OnClick", function()
      refreshManualOrderRows()
      refreshMainFrameIfVisible()
    end)
  end

  refreshManualOrderRows()

  frame:SetScript("OnShow", nil)
end)

if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
  local category = Settings.RegisterCanvasLayoutCategory(mainFrame, mainFrame.name);
  Settings.RegisterAddOnCategory(category);
  addon.settingsCategory = category;
end