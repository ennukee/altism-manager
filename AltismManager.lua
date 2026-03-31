local addonName, AltismManager = ...;
_G["AltismManager"] = AltismManager;

local Dialog = LibStub("LibDialog-1.0")
local C = AltismManager.C;
AltismManager.healthCheck = true;

local isTimerunner = nil

SLASH_ALTMANAGER1 = "/am";
SLASH_ALTMANAGER2 = "/alts";

local function GetCurrencyAmount(id)
	local info = C_CurrencyInfo.GetCurrencyInfo(id)
	return info.quantity;
end

local function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function true_numel(t)
	local c = 0
	for k, v in pairs(t) do c = c + 1 end
	return c
end

local GEAR_SLOT_DEFINITIONS = {
	{ id = INVSLOT_HEAD, label = "Head" },
	{ id = INVSLOT_NECK, label = "Neck" },
	{ id = INVSLOT_SHOULDER, label = "Shoulder" },
	{ id = INVSLOT_BACK, label = "Back" },
	{ id = INVSLOT_CHEST, label = "Chest" },
	{ id = INVSLOT_WRIST, label = "Wrist" },
	{ id = INVSLOT_HAND, label = "Hands" },
	{ id = INVSLOT_WAIST, label = "Waist" },
	{ id = INVSLOT_LEGS, label = "Legs" },
	{ id = INVSLOT_FEET, label = "Feet" },
	{ id = INVSLOT_FINGER1, label = "Ring 1" },
	{ id = INVSLOT_FINGER2, label = "Ring 2" },
	{ id = INVSLOT_TRINKET1, label = "Trinket 1" },
	{ id = INVSLOT_TRINKET2, label = "Trinket 2" },
	{ id = INVSLOT_MAINHAND, label = "Main Hand" },
	{ id = 17, label = "Off Hand" },
}

do
	local main_frame = CreateFrame("frame", nil, UIParent)
	AltismManager.main_frame = main_frame
	main_frame:SetFrameStrata("DIALOG")
	main_frame.background = main_frame:CreateTexture(nil, "BACKGROUND")
	main_frame.background:SetAllPoints()
	main_frame.background:SetDrawLayer("ARTWORK", 1)
	main_frame.background:SetColorTexture(0, 0, 0, 0.75)

	-- Set frame position
	main_frame:ClearAllPoints()
	main_frame:SetPoint("CENTER", UIParent, "CENTER", C.pixelSizing.offsetX, C.pixelSizing.offsetY)
	main_frame:RegisterEvent("ADDON_LOADED")
	main_frame:RegisterEvent("PLAYER_LOGIN")
	main_frame:RegisterEvent("PLAYER_LOGOUT")
	main_frame:RegisterEvent("QUEST_TURNED_IN")
	main_frame:RegisterEvent("BAG_UPDATE_DELAYED")
	main_frame:RegisterEvent("ARTIFACT_XP_UPDATE")
	main_frame:RegisterEvent("CHAT_MSG_CURRENCY")
	main_frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
	main_frame:RegisterEvent("PLAYER_LEAVING_WORLD")

	main_frame:SetScript("OnEvent", function(self, event, ...)
		if event == "ADDON_LOADED" then
			local loadedAddon = ...
			if loadedAddon == addonName then
				isTimerunner = PlayerGetTimerunningSeasonID()
				AltismManager:OnLoad()
			end
		elseif event == "PLAYER_LOGIN" then
			isTimerunner = PlayerGetTimerunningSeasonID()
			AltismManager:OnLogin()
		elseif event == "PLAYER_LEAVING_WORLD" or event == "ARTIFACT_XP_UPDATE" then
			isTimerunner = PlayerGetTimerunningSeasonID()
			local data = AltismManager:CollectData()
			AltismManager:StoreData(data)
		elseif event == "BAG_UPDATE_DELAYED" or event == "QUEST_TURNED_IN" or event == "CHAT_MSG_CURRENCY" or event == "CURRENCY_DISPLAY_UPDATE" then
			if AltismManager.addon_loaded then
				isTimerunner = PlayerGetTimerunningSeasonID()
				local data = AltismManager:CollectData()
				AltismManager:StoreData(data)
			end
		end
	end)

	main_frame:EnableKeyboard(true)
	main_frame:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			main_frame:SetPropagateKeyboardInput(false)
		else
			main_frame:SetPropagateKeyboardInput(true)
		end
	end)
	main_frame:SetScript("OnKeyUp", function(self, key)
		if key == "ESCAPE" then
			AltismManager:HideInterface()
		end
	end)

	-- Show Frame
	main_frame:Hide()
end

function AltismManager:InitDB()
	local t = {};
	t.alts = 0;
	t.data = {};
	t.configDefaults = {};
	t.characterConfig = {};
	t.selectedConfigTarget = "DEFAULT";
	t.manualCharacterOrderEnabled = false;
	t.manualCharacterOrder = {};
	t.showGoldEnabled = true;
	t.showMythicPlusDataEnabled = true;
	t.showPVPCurrenciesEnabled = false;
	t.showWorldBossEnabled = false;
	t.showRemainingCrestsEnabled = true;
	t.showMythicPlusVaultEnabled = true;
	t.showDelveVaultEnabled = true;
	t.showSparksEnabled = true;
	t.showCatalystEnabled = true;
	t.showRaidVaultEnabled = true;
	return t;
end

function AltismManager:CalculateXSizeNoGuidCheck()
	local alts = #self:GetSortedCharacterGuids(false)
	return max((alts + 1) * C.pixelSizing.perAltX, C.pixelSizing.minSizeX)
end

function AltismManager:CalculateXSize()
	return self:CalculateXSizeNoGuidCheck()
end

function AltismManager:CalculateYSize()
	local modifiedSize = C.pixelSizing.baseWindowSize;
	if AltismManagerDB then
		for _, section in ipairs(C.sections or {}) do
			local anyActive = false
			for _, flagName in ipairs(section) do
				if self:IsConfigFlagEnabledAnywhere(flagName) then
					anyActive = true
					break
				end
			end
			if not anyActive then
				modifiedSize = modifiedSize - C.TraditionalRowValue
			end
		end
		for flagName, config in pairs(C.configData or {}) do
			if not self:IsConfigFlagEnabledAnywhere(flagName) then
					modifiedSize = modifiedSize - (config.height or 0)
			end
		end
	end
	return modifiedSize
end

-- because of guid...
function AltismManager:OnLogin()
	self:ValidateReset();
	self:StoreData(self:CollectData());

	self.main_frame:SetSize(self:CalculateXSize(), self:CalculateYSize());
	self.main_frame.background:SetAllPoints();

	-- Create menus
	AltismManager:CreateContent();
	AltismManager:MakeTopBottomTextures(self.main_frame);
	AltismManager:MakeBorder(self.main_frame, 5);
end

function AltismManager:PurgeDbShadowlands()
	if AltismManagerDB == nil or AltismManagerDB.data == nil then return end
	local remove = {}
	for alt_guid, alt_data in spairs(AltismManagerDB.data, function(t, a, b) return t[a].ilevel > t[b].ilevel end) do
		if alt_data.charlevel == nil or alt_data.charlevel < C.misc.minLevelToShow or isTimerunner ~= nil then -- poor heuristic to remove old max level chars
			table.insert(remove, alt_guid)
		end
	end
	for k, v in pairs(remove) do
		-- don't need to redraw, this is don on load
		AltismManagerDB.alts = AltismManagerDB.alts - 1;
		AltismManagerDB.data[v] = nil
	end
end

function AltismManager:AddMissingField(name, value)
	if AltismManagerDB == nil then return end
	if AltismManagerDB[name] == nil then
		AltismManagerDB[name] = value
	end
end

function AltismManager:AddMissingPostReleaseFields()
	if AltismManagerDB == nil then return end

	-- Iterate over C.configData and add missing fields with their defaults
	for key, config in pairs(C.configData) do
		AltismManager:AddMissingField(key, config.default)
	end

	AltismManagerDB.configDefaults = AltismManagerDB.configDefaults or {}
	AltismManagerDB.characterConfig = AltismManagerDB.characterConfig or {}
	if AltismManagerDB.selectedConfigTarget == nil then
		AltismManagerDB.selectedConfigTarget = "DEFAULT"
	end

	for key, config in pairs(C.configData) do
		if AltismManagerDB.configDefaults[key] == nil then
			if AltismManagerDB[key] ~= nil then
				AltismManagerDB.configDefaults[key] = AltismManagerDB[key]
			else
				AltismManagerDB.configDefaults[key] = config.default
			end
		end
	end
end

function AltismManager:GetCharacterConfigEntry(guid, createIfMissing)
	if not AltismManagerDB or not guid then
		return nil
	end

	AltismManagerDB.characterConfig = AltismManagerDB.characterConfig or {}
	local entry = AltismManagerDB.characterConfig[guid]
	if not entry and createIfMissing then
		entry = {
			overrides = {},
			hidden = false,
		}
		AltismManagerDB.characterConfig[guid] = entry
	end

	if entry then
		entry.overrides = entry.overrides or {}
		if entry.hidden == nil then
			entry.hidden = false
		end
	end

	return entry
end

function AltismManager:IsCharacterHidden(guid)
	local entry = self:GetCharacterConfigEntry(guid, false)
	return entry and entry.hidden == true or false
end

function AltismManager:SetCharacterHidden(guid, hidden)
	if not guid then return end
	local entry = self:GetCharacterConfigEntry(guid, true)
	entry.hidden = hidden and true or false
end

function AltismManager:GetDefaultConfigValue(flagName)
	if not AltismManagerDB then return false end

	AltismManagerDB.configDefaults = AltismManagerDB.configDefaults or {}
	if AltismManagerDB.configDefaults[flagName] == nil then
		if AltismManagerDB[flagName] ~= nil then
			AltismManagerDB.configDefaults[flagName] = AltismManagerDB[flagName]
		elseif C.configData[flagName] then
			AltismManagerDB.configDefaults[flagName] = C.configData[flagName].default
		else
			AltismManagerDB.configDefaults[flagName] = false
		end
	end

	return AltismManagerDB.configDefaults[flagName]
end

function AltismManager:SetDefaultConfigValue(flagName, value)
	if not AltismManagerDB then return end

	AltismManagerDB.configDefaults = AltismManagerDB.configDefaults or {}
	AltismManagerDB.configDefaults[flagName] = value and true or false
	AltismManagerDB[flagName] = AltismManagerDB.configDefaults[flagName]
end

function AltismManager:GetConfigValue(flagName, guid)
	local defaultValue = self:GetDefaultConfigValue(flagName)
	if not guid then
		return defaultValue
	end

	local entry = self:GetCharacterConfigEntry(guid, false)
	if not entry then
		return defaultValue
	end

	if entry.overrides[flagName] == nil then
		return defaultValue
	end

	return entry.overrides[flagName]
end

function AltismManager:SetCharacterConfigValue(guid, flagName, value)
	if not guid then return end
	local entry = self:GetCharacterConfigEntry(guid, true)
	if not entry then return end
	entry.overrides = entry.overrides or {}
	entry.overrides[flagName] = value and true or false
end

function AltismManager:ApplyConfigValueToAllCharacters(flagName, value)
	if not AltismManagerDB or not AltismManagerDB.data then return end
	for guid in pairs(AltismManagerDB.data) do
		local entry = self:GetCharacterConfigEntry(guid, true)
		if entry then
			entry.overrides = entry.overrides or {}
			entry.overrides[flagName] = value and true or false
		end
	end
end

function AltismManager:IsConfigFlagEnabledAnywhere(flagName)
	if not AltismManagerDB or not AltismManagerDB.data then
		return false
	end

	for guid in pairs(AltismManagerDB.data) do
		if not self:IsCharacterHidden(guid) and self:GetConfigValue(flagName, guid) then
			return true
		end
	end

	return false
end

function AltismManager:IsSectionVisibleAnywhere(sectionId)
	local section = C.sections and C.sections[sectionId]
	if not section then
		return false
	end

	for _, flagName in ipairs(section) do
		if self:IsConfigFlagEnabledAnywhere(flagName) then
			return true
		end
	end

	return false
end

function AltismManager:IsColumnVisibleAnywhere(column)
	if not column then
		return false
	end

	if column.enabled == false then
		return false
	end

	if column.sectionId ~= nil then
		return self:IsSectionVisibleAnywhere(column.sectionId)
	end

	if column.configKey then
		return self:IsConfigFlagEnabledAnywhere(column.configKey)
	end

	return true
end

function AltismManager:SyncCharacterConfigStorage()
	local db = AltismManagerDB
	if not db then return end

	db.characterConfig = db.characterConfig or {}
	db.data = db.data or {}

	for guid, _ in pairs(db.characterConfig) do
		if not db.data[guid] then
			db.characterConfig[guid] = nil
		end
	end

	for guid in pairs(db.data) do
		local entry = self:GetCharacterConfigEntry(guid, true)
		if entry then
			entry.overrides = entry.overrides or {}
			if entry.hidden == nil then
				entry.hidden = false
			end
		end
	end
end

function AltismManager:OnLoad()
	self.main_frame:UnregisterEvent("ADDON_LOADED");

	AltismManagerDB = AltismManagerDB or self:InitDB();
	AltismManagerDB.manualCharacterOrder = AltismManagerDB.manualCharacterOrder or {}

	self:PurgeDbShadowlands();
	self:AddMissingPostReleaseFields();
	self:SyncCharacterConfigStorage();
	self:SyncManualCharacterOrder()

	if AltismManagerDB.alts ~= true_numel(AltismManagerDB.data) then
		print("Altcount inconsistent, using", true_numel(AltismManagerDB.data))
		AltismManagerDB.alts = true_numel(AltismManagerDB.data)
	end

	self.addon_loaded = true
	C_MythicPlus.RequestRewards();
	C_MythicPlus.RequestCurrentAffixes();
	C_MythicPlus.RequestMapInfo();
end

-- Create a minimap button
local minimapButton = CreateFrame("Button", "AltismManagerMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)

-- Set the minimap button texture
local iconTexture = minimapButton:CreateTexture(nil, "BACKGROUND")
iconTexture:SetTexture("Interface\\ICONS\\achievement_guildperk_everybodysfriend")
iconTexture:SetSize(20, 20)
iconTexture:SetPoint("CENTER", 0, 0)

-- Set the minimap button border (optional)
local borderTexture = minimapButton:CreateTexture(nil, "OVERLAY")
borderTexture:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
borderTexture:SetSize(54, 54)
borderTexture:SetPoint("TOPLEFT")

-- Helper function to update the button's position
local function UpdateMinimapButtonPosition()
    local angle = minimapButton.angle or math.rad(45) -- Default to 45 degrees if not set
    local radius = 80 -- Adjust radius if needed
    local x, y

    -- Check if GetMinimapShape is available
    local shape
    if type(GetMinimapShape) == "function" then
        shape = GetMinimapShape() or "ROUND"
    else
        shape = "ROUND"
    end

    -- Minimap dimensions and center
    local minimapWidth, minimapHeight = Minimap:GetWidth(), Minimap:GetHeight()
    local minimapCenterX, minimapCenterY = Minimap:GetCenter()

    if shape == "ROUND" then
        -- Calculate position for round minimap, making sure it's on the edge
        local minimapRadius = minimapWidth / 2
        x = minimapRadius * math.cos(angle)
        y = minimapRadius * math.sin(angle)
    elseif shape == "SQUARE" then
        -- Snap to edges of a square minimap
        local xEdge = radius * math.cos(angle)
        local yEdge = radius * math.sin(angle)
        local absX = math.abs(xEdge)
        local absY = math.abs(yEdge)

        if absX > absY then
            -- Snap to horizontal edge
            x = (xEdge > 0) and minimapWidth / 2 or -minimapWidth / 2
            y = (yEdge / xEdge) * x
        else
            -- Snap to vertical edge
            y = (yEdge > 0) and minimapHeight / 2 or -minimapHeight / 2
            x = (xEdge / yEdge) * y
        end
    else
        -- Default behavior for unknown shapes (fallback)
        x = radius * math.cos(angle)
        y = radius * math.sin(angle)
    end

    -- Update the position
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Save minimap button position and visibility to the saved variables
local function SaveMinimapButtonPosition()
    if not AltismManagerDB then
        AltismManagerDB = {}
    end
    if not AltismManagerDB.minimapButton then
        AltismManagerDB.minimapButton = {}
    end
    AltismManagerDB.minimapButton.angle = minimapButton.angle
    AltismManagerDB.minimapButton.hidden = not minimapButton:IsShown() -- Save visibility state
end

-- Load minimap button position and visibility from the saved variables
local function LoadMinimapButtonPosition()
    if AltismManagerDB and AltismManagerDB.minimapButton then
        minimapButton.angle = AltismManagerDB.minimapButton.angle or math.rad(45)  -- Default angle if no saved position
        local hidden = AltismManagerDB.minimapButton.hidden
        if hidden == nil then
            hidden = false -- Default to showing if not saved
        end
        if hidden then
            minimapButton:Hide()
        else
            minimapButton:Show()
        end
    else
        minimapButton.angle = math.rad(45)  -- Default angle if no saved position
        minimapButton:Show() -- Default to showing if no saved visibility
    end
    UpdateMinimapButtonPosition()
end

-- Variables to track dragging state
local dragging = false
local startX, startY
local startAngle

-- Function to toggle button visibility
local function ToggleMinimapButtonVisibility()
    if minimapButton:IsShown() then
        minimapButton:Hide()
        print("[Alt Manager]: Minimap button hidden")
    else
        minimapButton:Show()
        print("[Alt Manager]: Minimap button shown")
    end
    -- Save visibility state after toggling
    SaveMinimapButtonPosition()
end

-- Set up the minimap button dragging functionality
local mouseDownTime = nil;
minimapButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        dragging = true
				mouseDownTime = GetTime()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        startX, startY = (px / scale) - mx, (py / scale) - my
        startAngle = math.atan2(startY, startX)
    elseif button == "RightButton" then
			if not AltismManager.settingsCategory then
				print("[Alt Manager] Config panel was not initialized. Try /reload-ing and report the issue if it persists.")
			end
			Settings.OpenToCategory(AltismManager.settingsCategory.ID)
    end
end)

minimapButton:SetScript("OnMouseUp", function(self, button)
    if dragging and button == "LeftButton" then
				dragging = false
				if GetTime() - mouseDownTime < 0.25 then
					AltismManager:ShowInterface()
				else
					-- Save the new position only if dragging is qualified as a proper drag
					SaveMinimapButtonPosition()
				end
    end
end)

minimapButton:SetScript("OnUpdate", function(self)
    if dragging then
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        px = px / scale
        py = py / scale

        local mx, my = Minimap:GetCenter()
        local dx = px - mx
        local dy = py - my
        minimapButton.angle = math.atan2(dy, dx)

        -- Update button position safely
        if not self.isUpdating then
            self.isUpdating = true
            UpdateMinimapButtonPosition()
            self.isUpdating = false
        end
    end
end)

-- Handle button clicks
local isShown = false
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if not isShown then
            AltismManager:ShowInterface()
            isShown = true
        else
            AltismManager:HideInterface()
            isShown = false
        end
    elseif button == "RightButton" then
        -- Do nothing here to avoid conflict with OnMouseDown
    end
end)

-- Tooltip for the minimap button
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cffffff00AltismManager|r")
    GameTooltip:AddLine("Left-click |cffffff00to toggle window|r")
    GameTooltip:AddLine("Right-click |cffffff00to open settings|r")
    GameTooltip:AddLine("|cffffff00/alts mm|r to hide/show this button")
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Register event to load and save the minimap position
minimapButton:RegisterEvent("PLAYER_LOGIN")
minimapButton:RegisterEvent("PLAYER_LOGOUT")
minimapButton:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        LoadMinimapButtonPosition()
    elseif event == "PLAYER_LOGOUT" then
        SaveMinimapButtonPosition()
    end
end)

function AltismManager:CreateFontFrame(parent, x_size, height, relative_to, y_offset, label, justify, fontPath)
    local f = CreateFrame("Button", nil, parent)
    f:SetSize(x_size, height)
    f:SetText(label)
    f:SetPoint("TOPLEFT", relative_to, "TOPLEFT", 0, y_offset)
    f:GetFontString():SetJustifyH(justify)
    f:GetFontString():SetJustifyV("MIDDLE")
    f:SetPushedTextOffset(0, 0)
    f:GetFontString():SetWidth(120)
    f:GetFontString():SetHeight(20)

    -- Load and set the custom font
    local customFont = CreateFont("MyCustomFont")
    customFont:SetFont(fontPath, 12, "") -- Set the font path and size
    f:GetFontString():SetFontObject("MyCustomFont") -- Set the font object for the frame

    return f
end


function AltismManager:Keyset()
	local keyset = {}
	if AltismManagerDB and AltismManagerDB.data then
		for k in pairs(AltismManagerDB.data) do
			table.insert(keyset, k)
		end
	end
	return keyset
end

function AltismManager:SyncManualCharacterOrder()
	local db = AltismManagerDB
	if not db or not db.data then return end

	db.manualCharacterOrder = db.manualCharacterOrder or {}

	local seen = {}
	local synchronized = {}
	for _, guid in ipairs(db.manualCharacterOrder) do
		if db.data[guid] and not seen[guid] then
			table.insert(synchronized, guid)
			seen[guid] = true
		end
	end

	local untracked = {}
	for guid, charData in pairs(db.data) do
		if not seen[guid] then
			table.insert(untracked, {
				guid = guid,
				ilevel = charData.ilevel or 0,
				name = charData.name or "",
				realm = charData.realm or "",
			})
		end
	end

	table.sort(untracked, function(left, right)
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

	for _, entry in ipairs(untracked) do
		table.insert(synchronized, entry.guid)
	end

	db.manualCharacterOrder = synchronized
end

function AltismManager:GetSortedCharacterGuids(includeHidden)
	local db = AltismManagerDB
	local sorted = {}
	if not db or not db.data then return sorted end

	if db.manualCharacterOrderEnabled then
		self:SyncManualCharacterOrder()
		for _, guid in ipairs(db.manualCharacterOrder or {}) do
			if db.data[guid] and (includeHidden or not self:IsCharacterHidden(guid)) then
				table.insert(sorted, guid)
			end
		end
		return sorted
	end

	for guid in pairs(db.data) do
		if includeHidden or not self:IsCharacterHidden(guid) then
			table.insert(sorted, guid)
		end
	end

	table.sort(sorted, function(a, b)
		local left = db.data[a]
		local right = db.data[b]
		local leftIlvl = (left and left.ilevel) or 0
		local rightIlvl = (right and right.ilevel) or 0
		if leftIlvl ~= rightIlvl then
			return leftIlvl > rightIlvl
		end
		local leftName = (left and left.name) or ""
		local rightName = (right and right.name) or ""
		if leftName ~= rightName then
			return leftName < rightName
		end
		local leftRealm = (left and left.realm) or ""
		local rightRealm = (right and right.realm) or ""
		if leftRealm ~= rightRealm then
			return leftRealm < rightRealm
		end
		return a < b
	end)

	return sorted
end

function AltismManager:GetMidnightRaidProgressData(alt_data, saveKey)
	local result = {}
	local bossCounts = { 6, 1, 2 }

	for groupIndex, bossCount in ipairs(bossCounts) do
		local raidId = (C.ids.midnightRaids and (C.ids.midnightRaids[groupIndex - 1] or C.ids.midnightRaids[groupIndex])) or nil
		local raidSave = raidId and alt_data.raidsaves_midnight and alt_data.raidsaves_midnight[raidId] or nil
		local saveData = raidSave and raidSave[saveKey] or nil
		local bossNames = raidSave and raidSave.boss_names or nil

		for bossIndex = 1, bossCount do
			table.insert(result, {
				type = "boss",
				killed = saveData and saveData[bossIndex] or false,
				bossName = bossNames and bossNames[bossIndex] or nil,
			})
		end

		if groupIndex < #bossCounts then
			table.insert(result, { type = "separator" })
		end
	end

	return result
end

function AltismManager:GetGearSlotDefinitions()
	return GEAR_SLOT_DEFINITIONS
end

function AltismManager:GetGearTrackColorCode(trackName, isCrafted)
	if isCrafted then
		return "ffc0c0c0"
	end

	local normalized = (trackName or ""):lower()
	if normalized:find("veteran") then
		return "ffc0c0c0"
	end
	if normalized:find("champion") then
		return "ff1eff00"
	end
	if normalized:find("hero") then
		return "ff0070dd"
	end
	if normalized:find("myth") then
		return "ffa335ee"
	end
	return "ffc0c0c0"
end

function AltismManager:FormatGearTrackText(item)
	local ilvlValue = tonumber(item.ilvl or 0) or 0
	local ilvlText = tostring(math.floor(ilvlValue + 0.5))

	if item.track and item.track ~= "-" and item.track ~= "" then
		local colorCode = self:GetGearTrackColorCode(item.track, false)
		local ilvlColored = "|c" .. colorCode .. ilvlText .. "|r"

		local trackLabel = item.track or ""
		local progressText = ""
		if item.trackProgress and item.trackProgress ~= "-" then
			local current, maximum = item.trackProgress:match("^(%d+)%s*/%s*(%d+)$")
			if current and maximum then
				if tonumber(current) and tonumber(maximum) and tonumber(current) < tonumber(maximum) then
					progressText = " |cffffffff" .. current .. "|r|c" .. colorCode .. "/" .. maximum .. "|r"
				else
					progressText = " " .. item.trackProgress
				end
			else
				progressText = " " .. item.trackProgress
			end
		end

		local trackSegment = "|c" .. colorCode .. trackLabel .. progressText .. "|r"
		return ilvlColored .. " (" .. trackSegment .. ")"
	end

	if item.isCrafted then
		local craftedColor = "ffc0c0c0"
		return "|c" .. craftedColor .. ilvlText .. "|r (|c" .. craftedColor .. "Crafted|r)"
	end

	return "|cffc0c0c0" .. ilvlText .. "|r (|cffc0c0c0-|r)"
end

function AltismManager:IsDualWieldClass(classToken)
	return classToken == "DEATHKNIGHT"
		or classToken == "DEMONHUNTER"
		or classToken == "MONK"
		or classToken == "ROGUE"
		or classToken == "SHAMAN"
		or classToken == "WARRIOR"
end

function AltismManager:IsWeaponItemLink(itemLink)
	if not itemLink then
		return false
	end
	if not (C_Item and C_Item.GetItemInfoInstant) then
		return false
	end

	local _, _, _, _, _, _, _, _, equipLoc = C_Item.GetItemInfoInstant(itemLink)
	if not equipLoc then
		return false
	end

	return equipLoc == "INVTYPE_WEAPON"
		or equipLoc == "INVTYPE_WEAPONMAINHAND"
		or equipLoc == "INVTYPE_WEAPONOFFHAND"
		or equipLoc == "INVTYPE_2HWEAPON"
		or equipLoc == "INVTYPE_RANGED"
		or equipLoc == "INVTYPE_RANGEDRIGHT"
		or equipLoc == "INVTYPE_THROWN"
		or equipLoc == "INVTYPE_GUN"
		or equipLoc == "INVTYPE_BOW"
		or equipLoc == "INVTYPE_CROSSBOW"
		or equipLoc == "INVTYPE_WAND"
end

function AltismManager:SlotRequiresEnchant(alt_data, item)
	local slotId = item and item.slotId
	if not slotId then
		return false
	end

	if slotId == INVSLOT_HEAD
		or slotId == INVSLOT_SHOULDER
		or slotId == INVSLOT_CHEST
		or slotId == INVSLOT_LEGS
		or slotId == INVSLOT_FEET
		or slotId == INVSLOT_FINGER1
		or slotId == INVSLOT_FINGER2
		or slotId == INVSLOT_MAINHAND then
		return item.itemLink ~= nil
	end

	if slotId == INVSLOT_OFFHAND then
		if not (item.itemLink and self:IsDualWieldClass(alt_data and alt_data.class)) then
			return false
		end
		return self:IsWeaponItemLink(item.itemLink)
	end

	return false
end

function AltismManager:CollectGearData(unitToken)
	local gearData = {}
	local function looksLikeTrackName(name)
		local normalized = strtrim((name or ""):lower())
		if normalized == "" then return false end
		if normalized:find("durability", 1, true) then return false end
		if normalized:find("upgrade level", 1, true) then return false end
		return normalized:find("veteran", 1, true)
			or normalized:find("champion", 1, true)
			or normalized:find("hero", 1, true)
			or normalized:find("myth", 1, true)
	end
	for _, slotDef in ipairs(self:GetGearSlotDefinitions()) do
		local slotId = slotDef.id
		local slotLabel = slotDef.label
		local itemLink = GetInventoryItemLink(unitToken, slotId)
		if itemLink then
			local itemName, _, itemRarity, itemLevel, _, _, _, _, _, icon = C_Item.GetItemInfo(itemLink)
			local detailedIlvl = C_Item.GetDetailedItemLevelInfo(itemLink)

			local track = "-"
			local trackProgress = "-"
			local enchant = "-"
			local isCrafted = false

			local tooltipData = C_TooltipInfo and C_TooltipInfo.GetInventoryItem and C_TooltipInfo.GetInventoryItem(unitToken, slotId)
			if tooltipData and tooltipData.lines then
				for _, line in ipairs(tooltipData.lines) do
					local leftText = line.leftText
					local rightText = line.rightText
					local craftedLeft = leftText and leftText:lower():find("crafted", 1, true)
					local craftedRight = rightText and rightText:lower():find("crafted", 1, true)
					if (craftedLeft or craftedRight) and not isCrafted then
							isCrafted = true
					end

					local text = leftText
					if text and text ~= "" then
						if enchant == "-" then
							local enchantText = text:match("^Enchanted:%s*(.+)$")
							if enchantText and enchantText ~= "" then
								enchant = enchantText
							end
						end

						-- Prefer Upgrade Level as source of truth, but strip the label.
						local upTrackName, upCurrent, upMaximum = text:match("^[Uu]pgrade%s+[Ll]evel:?%s*(.+)%s+(%d+)%s*/%s*(%d+)$")
						if upTrackName and upCurrent and upMaximum and looksLikeTrackName(upTrackName) then
							track = strtrim(upTrackName)
							trackProgress = upCurrent .. "/" .. upMaximum
						end

						-- Format: "Champion 6/6"
						local inlineTrackName, current, maximum = text:match("^(.+)%s+(%d+)%s*/%s*(%d+)$")
						if track == "-" and inlineTrackName and current and maximum and looksLikeTrackName(inlineTrackName) then
							track = strtrim(inlineTrackName)
							trackProgress = current .. "/" .. maximum
						end

						-- Format: left is track name, right is progress (e.g. Champion | 6/6)
						if track == "-" and looksLikeTrackName(text) then
							track = strtrim(text)
						end

						if track ~= "-" and trackProgress == "-" then
							local leftCurrent, leftMaximum = text:match("(%d+)%s*/%s*(%d+)")
							if leftCurrent and leftMaximum and not text:lower():find("durability", 1, true) then
								trackProgress = leftCurrent .. "/" .. leftMaximum
							end
						end

						-- Keep upgrade progress fallback if track was identified elsewhere.
						if track ~= "-" and trackProgress == "-" and text:lower():find("upgrade", 1, true) then
							local upCurrent, upMaximum = text:match("(%d+)%s*/%s*(%d+)")
							if upCurrent and upMaximum then
								trackProgress = upCurrent .. "/" .. upMaximum
							end
						end
					end

					if track ~= "-" and trackProgress == "-" and rightText and rightText ~= "" then
						local rightCurrent, rightMaximum = rightText:match("(%d+)%s*/%s*(%d+)")
						if rightCurrent and rightMaximum then
							trackProgress = rightCurrent .. "/" .. rightMaximum
						end
					end
				end
			end

			local itemString = itemLink:match("item:([%-%d:]+)")
			if enchant == "-" and itemString then
				local _, enchantId = strsplit(":", itemString)
				local enchantIdNum = tonumber(enchantId or "0") or 0
				if enchantIdNum > 0 then
					enchant = "Enchant #" .. tostring(enchantIdNum)
				end
			end

			gearData[slotId] = {
				slotId = slotId,
				slotLabel = slotLabel,
				itemLink = itemLink,
				name = itemName or "Unknown Item",
				ilvl = detailedIlvl or itemLevel or 0,
				rarity = itemRarity or 1,
				track = track,
				trackProgress = trackProgress,
				isCrafted = isCrafted,
				enchant = enchant,
				icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
			}
		else
			gearData[slotId] = {
				slotId = slotId,
				slotLabel = slotLabel,
				itemLink = nil,
				name = "Empty",
				ilvl = 0,
				rarity = 1,
				track = "-",
				trackProgress = "-",
				isCrafted = false,
				enchant = "-",
				icon = "Interface\\Icons\\INV_Misc_QuestionMark",
			}
		end
	end

	return gearData
end

function AltismManager:ValidateReset()
	local db = AltismManagerDB
	if not db then return end;
	if not db.data then return end;

	local keyset = {}
	for k in pairs(db.data) do
		table.insert(keyset, k)
	end

	for alt = 1, db.alts do
		local expiry = db.data[keyset[alt]].expires or 0;
		local char_table = db.data[keyset[alt]];
		if time() > expiry then
			self:ResetCharTable(char_table);
		end
	end
end

function AltismManager:ResetCharTable(char_table)
	if not char_table then return end

	char_table.dungeon = "Unknown";
	char_table.level = "?";
	char_table.run_history = nil;
	char_table.expires = self:GetNextWeeklyResetTime();
	char_table.worldboss = false;
	char_table.aspects_max = 0;
	char_table.wyrms_max = 0;
	char_table.drakes_max = 0;
	char_table.whelplings_max = 0;
	char_table.undermine_normal = 0;
	char_table.undermine_heroic = 0;
	char_table.undermine_mythic = 0;
	char_table.undermine_normal_savedata = nil;
	char_table.undermine_heroic_savedata = nil;
	char_table.undermine_mythic_savedata = nil;
	char_table.raidvault = nil;
	char_table.mythicplusvault = nil;
	char_table.delvevault = nil;
	char_table.cofferKeysObtained = 0;
	char_table.delversBountyClaimed = false;
end

function AltismManager:Purge()
	AltismManagerDB = self:InitDB();
end

function AltismManager:RemoveCharactersByName(name)
	local db = AltismManagerDB;

	local indices = {};
	for guid, data in pairs(db.data) do
		if db.data[guid].name == name then
			indices[#indices+1] = guid
		end
	end

	db.alts = db.alts - #indices;
	for i = 1,#indices do
		db.data[indices[i]] = nil
	end

	print("Found " .. (#indices) .. " characters by the name of " .. name)
	print("Please reload ui to update the displayed info.")

	-- things wont be redrawn
end

function AltismManager:RemoveCharacterByGuid(index, skip_confirmation)
	local db = AltismManagerDB;

	if db.data[index] == nil then return end

	local delete = function()
		if db.data[index] == nil then return end
		db.alts = db.alts - 1;
		db.data[index] = nil
		if db.characterConfig then
			db.characterConfig[index] = nil
		end
		if db.selectedConfigTarget == index then
			db.selectedConfigTarget = "DEFAULT"
		end
		if db.manualCharacterOrder then
			for i = #db.manualCharacterOrder, 1, -1 do
				if db.manualCharacterOrder[i] == index then
					table.remove(db.manualCharacterOrder, i)
				end
			end
		end
		self.main_frame:SetSize(self:CalculateXSizeNoGuidCheck(), self:CalculateYSize());
		if self.main_frame.alt_columns ~= nil then
			-- Hide the last col
			-- find the correct frame to hide
			local count = #self.main_frame.alt_columns
			for j = 0,count-1 do
				if self.main_frame.alt_columns[count-j]:IsShown() then
					self.main_frame.alt_columns[count-j]:Hide()
					-- also for instances
					if self.instances_unroll ~= nil and self.instances_unroll.alt_columns ~= nil and self.instances_unroll.alt_columns[count-j] ~= nil then
						self.instances_unroll.alt_columns[count-j]:Hide()
					end
					break
				end
			end

			-- and hide the remove button
			if self.main_frame.remove_buttons ~= nil and self.main_frame.remove_buttons[index] ~= nil then
				self.main_frame.remove_buttons[index]:Hide()
			end
		end
		self:UpdateStrings()
		-- it's not simple to update the instances text with current design, so hide it and let the click do update
		if self.instances_unroll ~= nil and self.instances_unroll.state == "open" then
			self:CloseInstancesUnroll()
			self.instances_unroll.state = "closed";
		end
	end

	if skip_confirmation == nil then
		local name = db.data[index].name
		Dialog:Register("AltismManagerRemoveCharacterDialog", {
			text = "Are you sure you want to remove " .. name .. " from the list?",
			width = 500,
			on_show = function(self, data)
			end,
			buttons = {
				{ text = "Delete",
				on_click = delete},
				{ text = "Cancel", }
			},
			show_while_dead = true,
			hide_on_escape = true,
		})
		if Dialog:ActiveDialog("AltismManagerRemoveCharacterDialog") then
			Dialog:Dismiss("AltismManagerRemoveCharacterDialog")
		end
		Dialog:Spawn("AltismManagerRemoveCharacterDialog", {string = string})
	else
		delete();
	end

end

function AltismManager:StoreData(data)
	if not self.addon_loaded or not data or not data.guid or UnitLevel('player') < C.misc.minLevelToShow or isTimerunner ~= nil then
		return
	end

	local db = AltismManagerDB
	local guid = data.guid

	db.data = db.data or {}

	if not db.data[guid] then
		db.data[guid] = data
		db.alts = db.alts + 1
	else
		local lvl = db.data[guid].artifact_level
		data.artifact_level = data.artifact_level or lvl
		db.data[guid] = data
	end

	self:SyncCharacterConfigStorage()
	self:SyncManualCharacterOrder()
end

local dungeons = {
	-- CATA
	-- [438] = "VP",
	-- [456] = "TOTT",
	-- [507] = "GB",
	-- MoP
	-- [2] =   "TJS",
	-- WoD
	-- [165] = "SBG",
	-- [166] = "GD",
	-- [168] = "EB",
	-- [169] = "ID",
	-- Legion
	-- [198] = "DHT",
	-- [199] = "BRH",
	-- [200] = "HOV",
	-- [206] = "NL",
	-- [210] = "COS",
	-- [227] = "LOWR",
	-- [234] = "UPPR",
	-- BFA
	-- [244] = "AD",
	-- [245] = "FH",
	-- [246] = "TD",
	-- [247] = "ML",
	-- [248] = "WCM",
	-- [249] = "KR",
	-- [250] = "Seth",
	-- [251] = "UR",
	-- [252] = "SotS",
	--[353] = "SoB",
	--[369] = "YARD",
	-- [370] = "WORK",
	-- Shadowlands
	--[375] = "MoTS",
	--[376] = "NW",
	-- [377] = "DOS",
	-- [378] = "HoA", -- Halls of Atonement
	-- [379] = "PF",
	-- [380] = "SD",
	-- [381] = "SoA",
	-- [382] = "ToP",
	-- [391] = "STRT", -- Tazavesh: Streets
	-- [392] = "GMBT", -- Tazavesh: Gambit
	-- Dragonflight
	-- [399] = "RLP",
	-- [400] = "NO",
	-- [401] = "AV",
	-- [402] = "AA",
	-- [403] = "ULD",
	-- [404] = "NELT",
	-- [405] = "BH",
	-- [406] = "HOI"
	-- [463] = "FALL",
	-- [464] = "RISE",
	-- The War Within
	-- [499] = "PSF", -- Priory of the Sacred Flame
	-- [500] = "ROOK", -- The Rookery
	--[501] = "SV", -- The Stonevault
	--[502] = "COT", -- City of Threads
	-- [503] = "ARAK", -- Ara-Kara, City of Echoes
	-- [504] = "DFC", -- Darkflame Cleft
	-- [505] = "DAWN", -- The Dawnbreaker
	-- [506] = "BREW", -- Cinderbrew Meadery
	-- [525] = "FLOOD", -- Operation: Floodgate
	-- [542] = "ECO" -- Eco-Dome Al'dani
	-- Midnight S1
	[239] = "SEAT", -- Seat of the Triumverate
	[161] = "SKY", -- Skyreach
	[560] = "CAVERN", -- Maisara Caverns
	[557] = "SPIRE", -- Windrunner spire
	[556] = "PIT", -- Pit of Saron
	[402] = "AA", -- Algeth'ar Academy
	[558] = "MT", -- Magister's Terrace
	[559] = "XENAS", -- Nexus-Point Xenas
};

function AltismManager:CollectData()
	if UnitLevel('player') < C.misc.minLevelToShow or isTimerunner ~= nil then return end;
	-- this is an awful hack that will probably have some unforeseen consequences,
	-- but Blizzard fucked something up with systems on logout, so let's see how it
	-- goes.
	_, i = GetAverageItemLevel()
	if i == 0 then return end;

	local name = UnitName('player')
	local _, class = UnitClass('player')
	local dungeon = nil;
	local expire = nil;
	local level = nil;
	local highest_mplus = 0;
	local guid = UnitGUID('player');

	local mine_old = nil
	if AltismManagerDB and AltismManagerDB.data then
		mine_old = AltismManagerDB.data[guid];
	end

	-- C_MythicPlus.RequestRewards()
	C_MythicPlus.RequestCurrentAffixes();
	C_MythicPlus.RequestMapInfo();
	for k,v in pairs(dungeons) do
		-- request info in advance
		C_MythicPlus.RequestMapInfo(k);
	end
	local maps = C_ChallengeMode.GetMapTable();
	for i = 1, #maps do
		C_ChallengeMode.RequestLeaders(maps[i]);
	end

	local run_history = C_MythicPlus.GetRunHistory(false, true);

	-- find keystone
	local keystone_found = false;
	local vault_tokens = 0;
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		if (keystone_found and vault_tokens > 0) then break end

		for slot=1, C_Container.GetContainerNumSlots(bag) do
			if (keystone_found and vault_tokens > 0) then break end

			local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
			if containerInfo ~= nil then
				local slotItemID = containerInfo.itemID
				local slotLink = containerInfo.hyperlink
				if slotItemID == C.ids.vault_tokens then
					vault_tokens = containerInfo.stackCount or 0
				end
				if slotItemID == 180653 then
					local itemString = slotLink:match("|Hkeystone:([0-9:]+)|h(%b[])|h")
					if (not itemString) then
						-- print("Failed to parse keystone item link:", slotLink)
						break
					end
					local info = { strsplit(":", itemString) }
					dungeon = tonumber(info[2])
					if not dungeon then dungeon = nil end
					level = tonumber(info[3])
					if not level then level = nil end
					keystone_found = true;
				end
			end
		end
	end

	if not keystone_found then
		dungeon = "Unknown";
		level = "?"
	end

	-- Define the savedata file
	local char_table = {}
	char_table.vaultTokens = vault_tokens
	char_table.gear = self:CollectGearData('player')

	char_table.raidsaves = {}

	local saves = GetNumSavedInstances();
	local normal_difficulty = 14
	local heroic_difficulty = 15
	local mythic_difficulty = 16
	local difficultyMap = {
		[normal_difficulty] = 'N',
		[heroic_difficulty] = 'H',
		[mythic_difficulty] = 'M',
		[13] = 'X',
		[0] = 'X'
	}
	char_table.raidsaves_midnight = {}
	local midnightRaidNameToId = {}
	for _, raidMapID in pairs(C.ids.midnightRaids or {}) do
		local mapInfo = C_Map.GetMapInfo(raidMapID)
		if mapInfo and mapInfo.name then
			midnightRaidNameToId[mapInfo.name] = raidMapID
			char_table.raidsaves_midnight[raidMapID] = {
				boss_names = {},
				normal_savedata = nil,
				heroic_savedata = nil,
				mythic_savedata = nil,
				normal_kills = nil,
				heroic_kills = nil,
				mythic_kills = nil,
			}
		end
	end

	-- /run local mapID = C_Map.GetBestMapForUnit("player"); print(format("You are in %s (%d)", C_Map.GetMapInfo(mapID).name, mapID))
	for i = 1, saves do
		local raid_name, _, reset, difficulty, _, _, _, _, _, _, numEncounters, killed_bosses = GetSavedInstanceInfo(i);
		local bossKillData = {}
		local bossNameData = {}
		for q = 1, numEncounters do
			local bossName, _, isKilled = GetSavedInstanceEncounterInfo(i, q)
			if bossName then
				-- print("Boss Name: " .. bossName .. ", Killed: " .. tostring(isKilled))
				bossKillData[q] = isKilled
				bossNameData[q] = bossName
			end
		end

		local matchedRaidId = midnightRaidNameToId[raid_name]
		if matchedRaidId and reset > 0 then
			local raidSave = char_table.raidsaves_midnight[matchedRaidId]
			if raidSave then
				raidSave.boss_names = bossNameData
				if difficulty == normal_difficulty then
					raidSave.normal_savedata = bossKillData
					raidSave.normal_kills = killed_bosses
				elseif difficulty == heroic_difficulty then
					raidSave.heroic_savedata = bossKillData
					raidSave.heroic_kills = killed_bosses
				elseif difficulty == mythic_difficulty then
					raidSave.mythic_savedata = bossKillData
					raidSave.mythic_kills = killed_bosses
				end
			end

			-- Backward compatibility for existing Undermine consumers.
			if matchedRaidId == C.ids.raid then
				char_table.undermine_boss_names = bossNameData
				if difficulty == normal_difficulty then
					Undermine_Normal = killed_bosses
					char_table.raidsaves.undermine_normal_savedata = bossKillData
				end
				if difficulty == heroic_difficulty then
					Undermine_Heroic = killed_bosses
					char_table.raidsaves.undermine_heroic_savedata = bossKillData
				end
				if difficulty == mythic_difficulty then
					Undermine_Mythic = killed_bosses
					char_table.raidsaves.undermine_mythic_savedata = bossKillData
				end
			end
		end
	end
	


	local weeklyRaid = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Raid);
	if (#weeklyRaid < 3) then
		-- print("[AltismManager]: Issue retrieving raid vault data, values may be inaccurate.")
		char_table.raidvault = {"X", "X", "X"}
	else
		local raidVaultOutput = {}
		table.insert(raidVaultOutput, difficultyMap[weeklyRaid[1].level] or "X")
		table.insert(raidVaultOutput, difficultyMap[weeklyRaid[2].level] or "X")
		table.insert(raidVaultOutput, difficultyMap[weeklyRaid[3].level] or "X")
		char_table.raidvault = raidVaultOutput
	end

	local weeklyDelve = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.World);
	if (#weeklyDelve < 3) then
		-- print("[AltismManager]: Issue retrieving delve vault data, values may be inaccurate.")
		char_table.delvevault = {-1, -1, -1}
	else
		local delveVaultOutput = {}
		table.insert(delveVaultOutput, weeklyDelve[1].level or "X")
		table.insert(delveVaultOutput, weeklyDelve[2].level or "X")
		table.insert(delveVaultOutput, weeklyDelve[3].level or "X")
		char_table.delvevault = delveVaultOutput
	end

	-- local weeklyKeys = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.MythicPlus);
	local weeklyKeys = C_WeeklyRewards.GetActivities(1);
	char_table.hardmode_tazavesh_completed = false
	if (#weeklyKeys < 3) then
		-- print("[AltismManager]: Issue retrieving M+ vault data, values may be inaccurate.")
		char_table.mythicplusvault = {-1, -1, -1}
	else
		local mythicPlusVaultOutput = {}
		if (weeklyKeys[1].progress >= weeklyKeys[1].threshold) then
			if weeklyKeys[1].level == 0 then
				table.insert(mythicPlusVaultOutput, "M0")
			else
				table.insert(mythicPlusVaultOutput, weeklyKeys[1].level or -1)
			end
		else
			table.insert(mythicPlusVaultOutput, -1)
		end

		if (weeklyKeys[2].progress >= weeklyKeys[2].threshold) then
			if weeklyKeys[2].level == 0 then
				table.insert(mythicPlusVaultOutput, "M0")
			else
				table.insert(mythicPlusVaultOutput, weeklyKeys[2].level or -1)
			end
		else
			table.insert(mythicPlusVaultOutput, -1)
		end

		if (weeklyKeys[3].progress >= weeklyKeys[3].threshold) then
			if weeklyKeys[3].level == 0 then
				table.insert(mythicPlusVaultOutput, "M0")
			else
				table.insert(mythicPlusVaultOutput, weeklyKeys[3].level or -1)
			end
		else
			table.insert(mythicPlusVaultOutput, -1)
		end
		char_table.mythicplusvault = mythicPlusVaultOutput
	end


	-- local worldBossQuests = {
	-- 	[81624] = "Orta",
	-- 	[82653] = "Aggregation",
	-- 	[81653] = "Shurrai",
	-- 	[81630] = "Kordac",
	-- 	[85088] = "Gobfather"
	-- }
	-- local worldboss = nil
	-- for questID, bossName in pairs(worldBossQuests) do
	-- 	if C_QuestLog.IsQuestFlaggedCompleted(questID) then
	-- 		worldboss = bossName
	-- 		break -- Exit the loop if a completed quest is found
	-- 	end
	-- end

	-- this is how the official pvp ui does it, so if its wrong.. sue me
	-- based
	local relevantWorldBossID = C.ids.worldBoss -- Reshanor
	local worldBossKilled = C_QuestLog.IsQuestFlaggedCompleted(relevantWorldBossID)

	local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CONQUEST_CURRENCY_ID);
	local conquest_earned = math.min(currencyInfo.totalEarned, currencyInfo.maxQuantity);
	local conquest_total = currencyInfo.quantity

	local _, ilevel = GetAverageItemLevel();
	local gold = GetMoneyString(GetMoney(), true)
	local whelplings_crest = GetCurrencyAmount(C.ids.weathered_crest);
	local whelplings_info = C_CurrencyInfo.GetCurrencyInfo(C.ids.weathered_crest);
	local drakes_crest = GetCurrencyAmount(C.ids.carved_crest);
	local drakes_info = C_CurrencyInfo.GetCurrencyInfo(C.ids.carved_crest);
	local wyrms_crest = GetCurrencyAmount(C.ids.runed_crest);
	local wyrms_info = C_CurrencyInfo.GetCurrencyInfo(C.ids.runed_crest);
	local aspects_crest = GetCurrencyAmount(C.ids.gilded_crest);
	local aspects_info = C_CurrencyInfo.GetCurrencyInfo(C.ids.gilded_crest);
	local tier5_crest = GetCurrencyAmount(C.ids.myth_crest);
	local tier5_info = C_CurrencyInfo.GetCurrencyInfo(C.ids.myth_crest);
	local mplus_data = C_PlayerInfo.GetPlayerMythicPlusRatingSummary('player')

	local sparkData = C_CurrencyInfo.GetCurrencyInfo(C.ids.spark);
	char_table.currentSparks = sparkData.quantity;
	AltismManagerDB.currentMaxSparks = sparkData.maxQuantity;

	local catalystData = C_CurrencyInfo.GetCurrencyInfo(C.ids.catalyst)
	char_table.currentCatalyst = catalystData.quantity;

	local cofferKeyShards = C_CurrencyInfo.GetCurrencyInfo(C.ids.currentCofferKeyShards);
	local shardsThisWeek = cofferKeyShards.quantityEarnedThisWeek;
	local shardsThisWeekCap = cofferKeyShards.maxWeeklyQuantity;
	char_table.currentCofferKeyShards = shardsThisWeek;
	char_table.currentCofferKeyShardsCap = shardsThisWeekCap;

	local function b2n(bool)
		if bool then
			return 1
		else
			return 0
		end
	end

	local incompleteSpecialAssignments = 0
	for _, questPair in ipairs(C.ids.specialAssignments) do
		for _, questID in ipairs(questPair) do
			local questInfo = C_QuestLog.GetQuestObjectives(questID)
			local isActive = C_TaskQuest.IsActive and C_TaskQuest.IsActive(questID)
			if questInfo and questInfo[1] and questInfo[1].text ~= "" and questInfo[1].text ~= nil
				and (questInfo[1].objectiveType == 14 or isActive)
				and not C_QuestLog.IsQuestFlaggedCompleted(questID) then
					-- print("Special assignment incomplete: " .. questID)
					incompleteSpecialAssignments = incompleteSpecialAssignments + 1
					break
			end
		end
	end

	local soireeCompleted = C_QuestLog.IsQuestFlaggedCompleted(C.ids.soireeRunestone1)
		or C_QuestLog.IsQuestFlaggedCompleted(C.ids.soireeRunestone2)
		or C_QuestLog.IsQuestFlaggedCompleted(C.ids.soireeRunestone3)
		or C_QuestLog.IsQuestFlaggedCompleted(C.ids.soireeRunestone4);
	local memoryCompleted = C_QuestLog.IsQuestFlaggedCompleted(C.ids.memoryOfHarandar1)
		or C_QuestLog.IsQuestFlaggedCompleted(C.ids.memoryOfHarandar2)
		or C_QuestLog.IsQuestFlaggedCompleted(C.ids.memoryOfHarandar3)
		or C_QuestLog.IsQuestFlaggedCompleted(C.ids.memoryOfHarandar4)
		or C_QuestLog.IsQuestFlaggedCompleted(C.ids.memoryOfHarandar5);

	

	char_table.weeklies = {
		stormarionAssault = C_QuestLog.IsQuestFlaggedCompleted(C.ids.stormarionAssault),
		nightmarishTask = false,
		soireeRunestone = soireeCompleted,
		abundance = C_QuestLog.IsQuestFlaggedCompleted(C.ids.abundance),
		memoryOfHarandar = memoryCompleted,
		specialAssignments = incompleteSpecialAssignments,
	}

	char_table.currentCofferKeys = C_CurrencyInfo.GetCurrencyInfo(C.ids.currentCofferKeys).quantity;
	char_table.delversBountyClaimed = C_QuestLog.IsQuestFlaggedCompleted(C.ids.delversBounty);

	char_table.guid = UnitGUID('player');
	char_table.name = name;
	char_table.realm = GetRealmName();
	char_table.class = class;
	char_table.ilevel = ilevel;
	char_table.charlevel = UnitLevel('player')
	char_table.dungeon = dungeon;
	char_table.level = level;
	char_table.run_history = run_history;
	char_table.worldboss = worldBossKilled;
	char_table.conquest_earned = conquest_earned;
	char_table.conquest_total = conquest_total;

	char_table.mplus_score = mplus_data.currentSeasonScore
	char_table.gold = gold;
	char_table.whelplings_crest = whelplings_crest;
	char_table.whelplings_max = whelplings_info.maxQuantity;
	char_table.whelplings_earned = whelplings_info.totalEarned;
	char_table.drakes_crest = drakes_crest;
	char_table.drakes_max = drakes_info.maxQuantity;
	char_table.drakes_earned = drakes_info.totalEarned;
	char_table.wyrms_crest = wyrms_crest;
	char_table.wyrms_max = wyrms_info.maxQuantity;
	char_table.wyrms_earned = wyrms_info.totalEarned;
	char_table.aspects_crest = aspects_crest;
	char_table.aspects_max = aspects_info.maxQuantity;
	char_table.aspects_earned = aspects_info.totalEarned;
	char_table.tier5_crest = tier5_crest;
	char_table.tier5_max = tier5_info.maxQuantity;
	char_table.tier5_earned = tier5_info.totalEarned;
	char_table.flightstones = GetCurrencyAmount(3008);
	char_table.honor_points = GetCurrencyAmount(1792);

	char_table.undermine_normal = Undermine_Normal;
	char_table.undermine_heroic = Undermine_Heroic;
	char_table.undermine_mythic = Undermine_Mythic;

	char_table.expires = self:GetNextWeeklyResetTime();
	char_table.data_obtained = time();
	char_table.time_until_reset = C_DateAndTime.GetSecondsUntilDailyReset();

	local crackedKeystoneDone = C_QuestLog.IsQuestFlaggedCompleted(C.ids.crackedKeystoneQuest);
	char_table.cracked_keystone_done = crackedKeystoneDone;

	return char_table;
end

function AltismManager:UpdateStrings()
	local font_height = 20;
	local db = AltismManagerDB;

	local keyset = {}
	for k in pairs(db.data) do
		table.insert(keyset, k)
	end

	self.main_frame.alt_columns = self.main_frame.alt_columns or {};
	self.main_frame.remove_buttons = self.main_frame.remove_buttons or {}
	self.main_frame.gear_buttons = self.main_frame.gear_buttons or {}

	local shownGuids = {}
	local sortedGuids = self:GetSortedCharacterGuids(false)
	local alt = 0
	for _, alt_guid in ipairs(sortedGuids) do
		local alt_data = db.data[alt_guid]
		if alt_data then
		alt = alt + 1
		shownGuids[alt_guid] = true
		-- create the frame to which all the fontstrings anchor
		local anchor_frame = self.main_frame.alt_columns[alt] or CreateFrame("Button", nil, self.main_frame);
		if not self.main_frame.alt_columns[alt] then
			self.main_frame.alt_columns[alt] = anchor_frame;
		end
		self.main_frame.alt_columns[alt].guid = alt_guid
		anchor_frame:ClearAllPoints()
		anchor_frame:SetPoint("TOPLEFT", self.main_frame, "TOPLEFT", C.pixelSizing.perAltX * alt, -1);
		anchor_frame:SetSize(C.pixelSizing.perAltX, self:CalculateYSize());
		-- init table for fontstring storage
		self.main_frame.alt_columns[alt].label_columns = self.main_frame.alt_columns[alt].label_columns or {};
		local label_columns = self.main_frame.alt_columns[alt].label_columns;
		-- create / fill fontstrings
		local i = 1;
		for column_iden, column in spairs(self.columns_table, function(t, a, b) return t[a].order < t[b].order end) do
			local rowEnabledAnywhere = self:IsColumnVisibleAnywhere(column)
			local enabledForCharacter = rowEnabledAnywhere and (not column.configKey or self:GetConfigValue(column.configKey, alt_guid))
			-- only display data with values
			if rowEnabledAnywhere and enabledForCharacter and column.type == "raidprogress" then
				local raidProgress = column.data(alt_data) or {}
				local totalBosses = 0
				local totalSeparators = 0
				for _, entry in ipairs(raidProgress) do
					if entry.type == "boss" then
						totalBosses = totalBosses + 1
					elseif entry.type == "separator" then
						totalSeparators = totalSeparators + 1
					end
				end
				if totalBosses == 0 then
					totalBosses = 9
					totalSeparators = 2
				end

				local separatorUnitSize = 0.4
				local totalUnits = totalBosses + (totalSeparators * separatorUnitSize)
				local layoutWidth = C.pixelSizing.perAltX - 15
				local unitWidth = layoutWidth / totalUnits

				local slotLayout = {}
				local baseTotal = 0
				for idx, entry in ipairs(raidProgress) do
					local units = entry.type == "separator" and separatorUnitSize or 1
					local desired = unitWidth * units
					local width = math.max(1, math.floor(desired))
					slotLayout[idx] = {
						index = idx,
						entry = entry,
						width = width,
						fraction = desired - width,
					}
					baseTotal = baseTotal + width
				end

				local remainder = layoutWidth - baseTotal
				if remainder ~= 0 then
					table.sort(slotLayout, function(a, b)
						if a.fraction == b.fraction then
							return a.width > b.width
						end
						return a.fraction > b.fraction
					end)

					if remainder > 0 then
						for r = 1, remainder do
							local target = slotLayout[((r - 1) % #slotLayout) + 1]
							target.width = target.width + 1
						end
					elseif remainder < 0 then
						for r = 1, math.abs(remainder) do
							for _, target in ipairs(slotLayout) do
								if target.width > 1 then
									target.width = target.width - 1
									break
								end
							end
						end
					end

					table.sort(slotLayout, function(a, b)
						return a.index < b.index
					end)
				end

				local byEntry = {}
				for _, slot in ipairs(slotLayout) do
					byEntry[slot.entry] = slot.width
				end
				local currentX = 10
				for _, entry in ipairs(raidProgress) do
					local slotWidth = byEntry[entry] or 1
					if entry.type == "separator" then
						-- Keep separator slots as visual spacing between raid groups.
						currentX = currentX + slotWidth
					else
						local raidIcon = anchor_frame:CreateTexture(nil)
						if entry.killed then
							if column.label == "Mythic" then
								raidIcon:SetColorTexture(0.64, 0.21, 0.93, 1)
							elseif column.label == "Heroic" then
								raidIcon:SetColorTexture(0, 0.44, 0.87, 1)
							else
								raidIcon:SetColorTexture(0.12, 1, 0, 1)
							end
						else
							raidIcon:SetColorTexture(0.2, 0.2, 0.2, 1)
						end
						raidIcon:ClearAllPoints()
						local iconWidth = math.max(2, slotWidth - 4)
						local iconX = currentX + math.floor((slotWidth - iconWidth) / 2)
						raidIcon:SetPoint(
							"TOPLEFT",
							anchor_frame,
							"TOPLEFT",
							iconX,
							-(i - 1) * font_height - 3
						)
						raidIcon:SetSize(iconWidth, font_height - 6)
						raidIcon:SetDrawLayer("ARTWORK", 7)
						currentX = currentX + slotWidth
						if entry.bossName then
							raidIcon:SetScript("OnEnter", function(self)
								GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
								GameTooltip:AddLine(entry.bossName)
								GameTooltip:Show()
							end)
							raidIcon:SetScript("OnLeave", function(self)
								GameTooltip:Hide()
							end)
						end
					end
				end
			end
			if type(column.data) == "function" and rowEnabledAnywhere and column.type ~= "raidprogress" then
				local fontPath = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf"
				local current_row = label_columns[i] or self:CreateFontFrame(anchor_frame, C.pixelSizing.perAltX, column.font_height or font_height, anchor_frame, -(i - 1) * font_height, column.data(alt_data), "CENTER", fontPath);
				-- insert it into storage if just created
				if not self.main_frame.alt_columns[alt].label_columns[i] then
					self.main_frame.alt_columns[alt].label_columns[i] = current_row;
				end
				if enabledForCharacter and column.color then
					local color = column.color(alt_data)
					current_row:GetFontString():SetTextColor(color.r, color.g, color.b, 1);
				end
				if enabledForCharacter then
					current_row:SetText(column.data(alt_data))
				else
					current_row:SetText(" ")
				end
				if column.font then
					current_row:GetFontString():SetFont(column.font, C.pixelSizing.ilvlTextSize)
				else
					current_row:GetFontString():SetFont("Interface\\AddOns\\AltismManager\\fonts\\expressway.otf", 14)
				end
				if column.justify then
					current_row:GetFontString():SetJustifyV(column.justify);
				end

				if enabledForCharacter and column.tooltip then
					current_row:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						column.tooltip(alt_data)
						GameTooltip:Show()
					end)
					current_row:SetScript("OnLeave", function(self)
						GameTooltip:Hide()
					end)
				else
					current_row:SetScript("OnEnter", nil)
					current_row:SetScript("OnLeave", nil)
				end

				if enabledForCharacter and column.remove_button ~= nil then
					self.main_frame.remove_buttons = self.main_frame.remove_buttons or {}
					local extra = self.main_frame.remove_buttons[alt_data.guid] or column.remove_button(alt_data)
					if self.main_frame.remove_buttons[alt_data.guid] == nil then
						self.main_frame.remove_buttons[alt_data.guid] = extra
					end
					extra:SetParent(current_row)
					extra:SetPoint("TOPRIGHT", current_row, "TOPRIGHT", -18, 2 );
					extra:SetPoint("BOTTOMRIGHT", current_row, "TOPRIGHT", -18, -C.pixelSizing.removeButtonSize + 2);
					extra:SetFrameLevel(current_row:GetFrameLevel() + 1)
					extra:Show();
				end

				if enabledForCharacter and column.gear_button ~= nil then
					self.main_frame.gear_buttons = self.main_frame.gear_buttons or {}
					local gearButton = self.main_frame.gear_buttons[alt_data.guid] or column.gear_button(alt_data)
					if self.main_frame.gear_buttons[alt_data.guid] == nil then
						self.main_frame.gear_buttons[alt_data.guid] = gearButton
					end
					gearButton:SetParent(current_row)
					gearButton:SetPoint("TOPRIGHT", current_row, "TOPRIGHT", -34, 2)
					gearButton:SetPoint("BOTTOMRIGHT", current_row, "TOPRIGHT", -34, -C.pixelSizing.removeButtonSize + 2)
					gearButton:SetFrameLevel(current_row:GetFrameLevel() + 1)
					gearButton:Show()
				end
			end
			if rowEnabledAnywhere then
				i = i + 1
			end
		end
		end
	end

	for i = alt + 1, #self.main_frame.alt_columns do
		if self.main_frame.alt_columns[i] then
			self.main_frame.alt_columns[i]:Hide()
		end
	end

	for guid, button in pairs(self.main_frame.remove_buttons) do
		if button and not shownGuids[guid] then
			button:Hide()
		end
	end

	for guid, button in pairs(self.main_frame.gear_buttons) do
		if button and not shownGuids[guid] then
			button:Hide()
		end
	end
end

function AltismManager:ProduceRelevantMythics(run_history)
	-- find thresholds
	local weekly_info = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.MythicPlus);
	table.sort(run_history, function(left, right) return left.level > right.level; end);
	local thresholds = {}

	local max_threshold = 0
	for i = 1 , #weekly_info do
		thresholds[weekly_info[i].threshold] = true;
		if weekly_info[i].threshold > max_threshold then
			max_threshold = weekly_info[i].threshold;
		end
	end
	return run_history, thresholds, max_threshold
end

function AltismManager:ProduceRelevantRaidKillData()
	local weekly_info = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Raid);
	-- progress = number of bosses killed
	-- level = raid difficulty id? so 16 = mythic, 15 = heroic, 14 = normal?
	table.sort(run_history, function(left, right) return left.level > right.level; end);
	local thresholds = {}

	local max_threshold = 0
	for i = 1 , #weekly_info do
		thresholds[weekly_info[i].threshold] = true;
		if weekly_info[i].threshold > max_threshold then
			max_threshold = weekly_info[i].threshold;
		end
	end
	return run_history, thresholds, max_threshold
end

function AltismManager:RaidVaultSummaryString(alt_data)
	if alt_data.raidvault == nil then
		return "|cFF999999X|r / |cFF999999X|r / |cFF999999X|r"
	end

	local result = ""

	if alt_data.raidvault[1] == "X" then
		result = result .. "|cFF999999X|r"
	elseif alt_data.raidvault[1] == "N" then
		result = result .. "|cFF1eff00" .. alt_data.raidvault[1] .. "|r"
	elseif alt_data.raidvault[1] == "H" then
		result = result .. "|cFF0070dd" .. alt_data.raidvault[1] .. "|r"
	elseif alt_data.raidvault[1] == "M" then
		result = result .. "|cFFa335ee" .. alt_data.raidvault[1] .. "|r"
	else
		result = result .. "|cFF999999" .. alt_data.raidvault[1] .. "|r"
	end

	if alt_data.raidvault[2] == "X" then
		result = result .. " / |cFF999999X|r"
	elseif alt_data.raidvault[2] == "N" then
		result = result .. " / |cFF1eff00" .. alt_data.raidvault[2] .. "|r"
	elseif alt_data.raidvault[2] == "H" then
		result = result .. " / |cFF0070dd" .. alt_data.raidvault[2] .. "|r"
	elseif alt_data.raidvault[2] == "M" then
		result = result .. " / |cFFa335ee" .. alt_data.raidvault[2] .. "|r"
	else
		result = result .. " / |cFF999999" .. alt_data.raidvault[2] .. "|r"
	end
	
	if alt_data.raidvault[3] == "X" then
		result = result .. " / |cFF999999X|r"
	elseif alt_data.raidvault[3] == "N" then
		result = result .. " / |cFF1eff00" .. alt_data.raidvault[3] .. "|r"
	elseif alt_data.raidvault[3] == "H" then
		result = result .. " / |cFF0070dd" .. alt_data.raidvault[3] .. "|r"
	elseif alt_data.raidvault[3] == "M" then
		result = result .. " / |cFFa335ee" .. alt_data.raidvault[3] .. "|r"
	else
		result = result .. " / |cFF999999" .. alt_data.raidvault[3] .. "|r"
	end

	return result ~= "" and result or "-"
end

function AltismManager:MythicVaultSummaryString(alt_data)
	if alt_data.mythicplusvault == nil then
		return "|cFF999999X|r / |cFF999999X|r / |cFF999999X|r"
	end

	-- local sorted_history = AltismManager:ProduceRelevantMythics(alt_data.run_history)
	-- local total_runs = #sorted_history
	local result = ""

	if type(alt_data.mythicplusvault[1]) == "string" and alt_data.mythicplusvault[1] == "M0" then
		result = result .. "0"
	elseif alt_data.mythicplusvault[1] >= C.thresholds.mythTrackKeyVault then
		result = "|cFF00FF00" .. tostring(alt_data.mythicplusvault[1]) .. "|r"
	elseif alt_data.mythicplusvault[1] > 0 then
		result = tostring(alt_data.mythicplusvault[1])
	else
		result = result .. "|cFF999999X|r"
	end
	if type(alt_data.mythicplusvault[2]) == "string" and alt_data.mythicplusvault[2] == "M0" then
		result = result .. " / 0"
	elseif alt_data.mythicplusvault[2] >= C.thresholds.mythTrackKeyVault then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.mythicplusvault[2]) .. "|r"
	elseif alt_data.mythicplusvault[2] > 0 then
		result = result .. " / " .. tostring(alt_data.mythicplusvault[2])
	else
		result = result .. " / |cFF999999X|r"
	end
	if type(alt_data.mythicplusvault[3]) == "string" and alt_data.mythicplusvault[3] == "M0" then
		result = result .. " / 0"
	elseif alt_data.mythicplusvault[3] >= C.thresholds.mythTrackKeyVault then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.mythicplusvault[3]) .. "|r"
	elseif alt_data.mythicplusvault[3] > 0 then
		result = result .. " / " .. tostring(alt_data.mythicplusvault[3])
	else
		result = result .. " / |cFF999999X|r"
	end

	return result ~= "" and result or "-"
end

function AltismManager:DelveVaultSummaryString(alt_data)
	if alt_data.mythicplusvault == nil then
		return "|cFF999999X|r / |cFF999999X|r / |cFF999999X|r"
	end

	local result = ""

	if alt_data.delvevault[1] >= C.thresholds.maxLootDelveVault then
			result = "|cFF00FF00" .. tostring(alt_data.delvevault[1]) .. "|r"
	elseif alt_data.delvevault[1] > 0 then
			result = tostring(alt_data.delvevault[1])
	else
		result = result .. "|cFF999999X|r"
	end
	if alt_data.delvevault[2] >= C.thresholds.maxLootDelveVault then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.delvevault[2]) .. "|r"
	elseif alt_data.delvevault[2] > 0 then
		result = result .. " / " .. tostring(alt_data.delvevault[2])
	else
		result = result .. " / |cFF999999X|r"
	end
	if alt_data.delvevault[3] >= C.thresholds.maxLootDelveVault then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.delvevault[3]) .. "|r"
	elseif alt_data.delvevault[3] > 0 then
		result = result .. " / " .. tostring(alt_data.delvevault[3])
	else
		result = result .. " / |cFF999999X|r"
	end

	return result ~= "" and result or "-"
end

function AltismManager:CreateContent()
	-- Close button
	self.main_frame.closeButton = CreateFrame("Button", "CloseButton", self.main_frame, "UIPanelCloseButton");
	self.main_frame.closeButton:ClearAllPoints()
	self.main_frame.closeButton:SetPoint("BOTTOMRIGHT", self.main_frame, "TOPRIGHT", -5, 4);
	self.main_frame.closeButton:SetScript("OnClick", function() AltismManager:HideInterface(); end);
	--self.main_frame.closeButton:SetSize(32, h);

	local function checkSectionFlags(section_id) 
		return self:IsSectionVisibleAnywhere(section_id)
	end

	local column_table = {
		name = {
			order = 1001,
			label = C.labels.name,
			enabled = true,
			data = function(alt_data) return alt_data.name end,
			color = function(alt_data) return RAID_CLASS_COLORS[alt_data.class] end,
		},
		ilevel = {
			order = 1002,
			data = function(alt_data) return string.format("%.2f", alt_data.ilevel or 0) end, -- , alt_data.neck_level or 0
			justify = "TOP",
			enabled = true,
			-- font = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf",
			gear_button = function(alt_data) return self:CreateGearButton(function() AltismManager:ShowGearDialog(alt_data) end) end,
			remove_button = function(alt_data) return self:CreateRemoveButton(function() AltismManager:RemoveCharacterByGuid(alt_data.guid) end) end
		},
		gold = {
			order = 1003,
			justify = "TOP",
			enabled = true,
			configKey = "showGoldEnabled",
			font = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf",
			data = function(alt_data) return tostring(alt_data.gold or "0") end,
		},
		raidvault = {
			order = 2010,
			label = C.labels.raidVault,
			enabled = true,
			configKey = "showRaidVaultEnabled",
			data = function(alt_data) return self:RaidVaultSummaryString(alt_data) end,
		},
		mplusvault = {
			order = 2020,
			label = C.labels.mythicPlusVault,
			enabled = true,
			configKey = "showMythicPlusVaultEnabled",
			tooltip = function(alt_data)
				local sorted_history = AltismManager:ProduceRelevantMythics(alt_data.run_history)
				GameTooltip:AddLine("Mythic+ Vault Progress")
				for i, run in ipairs(sorted_history) do
					GameTooltip:AddDoubleLine((dungeons[run.mapChallengeModeID] or "Unknown"), "+"..run.level, 1, 1, 1, 0, 1, 0)
				end
				if (alt_data.hardmode_tazavesh_completed) then
					GameTooltip:AddDoubleLine("Hardmode Tazavesh", "+10", 1, 1, 1, 0, 1, 0)
				end
				GameTooltip:Show()
			end,
			data = function(alt_data) return self:MythicVaultSummaryString(alt_data) end,
		},
		delvevault = {
			order = 2030,
			label = C.labels.delveVault,
			enabled = true,
			configKey = "showDelveVaultEnabled",
			data = function(alt_data) return self:DelveVaultSummaryString(alt_data) end,
		},
		keystone = {
			order = 2040,
			label = C.labels.mythicKeystone,
			enabled = true,
			configKey = "showMythicPlusDataEnabled",
			data = function(alt_data) return (dungeons[alt_data.dungeon] or alt_data.dungeon) .. " +" .. tostring(alt_data.level); end,
		},
		mplus_score = {
			order = 2050,
			label = C.labels.mythicPlusRating,
			enabled = true,
			configKey = "showMythicPlusDataEnabled",
			data = function(alt_data) return tostring(alt_data.mplus_score or "0") end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET = {
			order = 3000,
			label = "",
			enabled = true,
			sectionId = C.sectionNames["Misc"],
			data = function(alt_data) return " " end,
		},
		sparks = {
			order = 3020,
			label = C.labels.sparks,
			enabled = true,
			configKey = "showSparksEnabled",
			data = function(alt_data)
				if (alt_data.currentSparks == AltismManagerDB.currentMaxSparks) then
					return "|cFF39ec3c" .. tostring(alt_data.currentSparks or "?") .. " / " .. (AltismManagerDB.currentMaxSparks or "?") .. "|r"
				else 
					return tostring(alt_data.currentSparks or "?") .. " / " .. (AltismManagerDB.currentMaxSparks or "?")
				end
			end,
		},
		catalyst = {
			order = 3030,
			label = C.labels.catalyst,
			enabled = true,
			configKey = "showCatalystEnabled",
			data = function(alt_data)
				if (alt_data.currentCatalyst == 0) then
					return "|cFFec393c" .. tostring(alt_data.currentCatalyst or "?") .. "|r"
				else 
					return tostring(alt_data.currentCatalyst or "?")
				end
			end,
		},
		vaultTokens = {
			order = 3040,
			label = C.labels.vaultTokens,
			enabled = true,
			configKey = "showVaultTokensEnabled",
			data = function(alt_data)
				return tostring(alt_data.vaultTokens or "?")
			end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET_delve = {
			order = 4000,
			label = "",
			enabled = true,
			sectionId = C.sectionNames["Delve"],
			data = function(alt_data) return " " end,
		},
		currentCofferKeys = {
			order = 4030,
			label = C.labels.currentCofferKeys,
			enabled = true,
			configKey = "showCurrentCofferKeysEnabled",
			data = function(alt_data)
				return tostring(alt_data.currentCofferKeys or "?")
			end,
		},
		weeklyCofferShards = {
			order = 4035,
			label = C.labels.currentCofferKeyShards,
			enabled = true,
			configKey = "showCurrentCofferKeysEnabled",
			data = function(alt_data)
				if (alt_data.currentCofferKeyShards == nil or alt_data.currentCofferKeyShardsCap == nil) then
					return "|cFFbbbbbbUnknown|r"
				end
				return tostring(alt_data.currentCofferKeyShards or "?") .. " / " .. tostring(alt_data.currentCofferKeyShardsCap or "?")
			end,
		},
		delversBounty = {
			order = 4040,
			label = C.labels.delversBounty,
			enabled = true,
			configKey = "showDelversBountyEnabled",
			data = function(alt_data)
				if (alt_data.delversBountyClaimed == nil) then
					return "|cFFbbbbbbUnknown|r"
				end
				return tostring(alt_data.delversBountyClaimed and "|cFF39ec3cDone|r" or "|cFFec393cAvailable|r")
			end,
		},
		crackedKeystone = {
			order = 4050,
			label = C.labels.crackedKeystoneDone,
			enabled = true,
			configKey = "showCrackedKeystoneEnabled",
			data = function(alt_data)
				if (alt_data.cracked_keystone_done == nil) then
					return "|cFFbbbbbbUnknown|r"
				end
				return tostring(alt_data.cracked_keystone_done and "|cFF39ec3cDone|r" or "|cFFec393cAvailable|r")
			end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET_WORLD_CONTENT = {
			order = 4500,
			label = "",
			enabled = true,
			sectionId = C.sectionNames["World Content"],
			data = function(alt_data) return " " end,
		},
		soiree_runestone = {
			order = 4501,
			label = C.labels.soireeRunestone,
			enabled = true,
			configKey = "showSoireeRunestoneEnabled",
			data = function(alt_data)
				if (alt_data.weeklies == nil or alt_data.weeklies.soireeRunestone == nil) then
					return "|cFFbbbbbbUnknown|r"
				end
				return tostring(alt_data.weeklies.soireeRunestone and "|cFF39ec3cDone|r" or "|cFFec393cAvailable|r")
			end,
		},
		abundance = {
			order = 4502,
			label = C.labels.abundance,
			enabled = true,
			configKey = "showAbundanceEnabled",
			data = function(alt_data)
				if (alt_data.weeklies == nil or alt_data.weeklies.abundance == nil) then
					return "|cFFbbbbbbUnknown|r"
				end
				return tostring(alt_data.weeklies.abundance and "|cFF39ec3cDone|r" or "|cFFec393cAvailable|r")
			end,
		},
		-- memory_of_harandar = {
		-- 	order = 4503,
		-- 	label = C.labels.memoryOfHarandar,
		-- 	enabled = AltismManagerDB.showMemoryOfHarandarEnabled,
		-- 	data = function(alt_data)
		-- 		if (alt_data.weeklies == nil or alt_data.weeklies.memoryOfHarandar == nil) then
		-- 			return "|cFFbbbbbbUnknown|r"
		-- 		end
		-- 		return tostring(alt_data.weeklies.memoryOfHarandar and "|cFF39ec3cDone|r" or "|cFFec393cAvailable|r")
		-- 	end,
		-- },
		stormarion_assault = {
			order = 4504,
			label = C.labels.stormarionAssault,
			enabled = true,
			configKey = "showStormarionAssaultEnabled",
			data = function(alt_data)
				if (alt_data.weeklies == nil or alt_data.weeklies.stormarionAssault == nil) then
					return "|cFFbbbbbbUnknown|r"
				end
				return tostring(alt_data.weeklies.stormarionAssault and "|cFF39ec3cDone|r" or "|cFFec393cAvailable|r")
			end,
		},
		special_assignments = {
			order = 4505,
			label = C.labels.specialAssignments,
			enabled = true,
			configKey = "showSpecialAssignmentsEnabled",
			data = function(alt_data)
				if (alt_data.weeklies == nil or alt_data.weeklies.specialAssignments == nil) then
					return "|cFFbbbbbbUnknown|r"
				end
				local remainingAssignments = alt_data.weeklies.specialAssignments
				if remainingAssignments > 0 then
					return tostring(2 - remainingAssignments) .. " / 2"
				end
				return "|cFF39ec3cDone|r"
			end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET_3 = {
			order = 5000,
			label = "",
			enabled = true,
			sectionId = C.sectionNames["Crests"],
			data = function(alt_data) return " " end,
		},
		whelplings_crest = {
			order = 5010,
			label = C.labels.whelplingCrest,
			enabled = true,
			configKey = "showTier1Crest",
			data = function(alt_data)
				-- REMOVE `false and` WHEN TURBO BOOST IS OVER
				if (self:GetConfigValue("showRemainingCrestsEnabled", alt_data.guid)) then
					if (alt_data.whelplings_max == alt_data.whelplings_earned) then
						return "|cFF39ec3c" .. tostring(alt_data.whelplings_crest or "?") .. "|r"
					else 
						return tostring(alt_data.whelplings_crest or "?").." |cffcccccc(+"..(alt_data.whelplings_max - alt_data.whelplings_earned)..")|r"
					end
				end
				return tostring(alt_data.whelplings_crest or "?")
			end,
		},
		drakes_crest = {
			order = 5020,
			label = C.labels.drakeCrest,
			enabled = true,
			configKey = "showTier2Crest",
			data = function(alt_data)
				-- REMOVE `false and` WHEN TURBO BOOST IS OVER
				if (self:GetConfigValue("showRemainingCrestsEnabled", alt_data.guid)) then
					if (alt_data.drakes_max == alt_data.drakes_earned) then
						return "|cFF39ec3c" .. tostring(alt_data.drakes_crest or "?") .. "|r"
					else 
						return tostring(alt_data.drakes_crest or "?").." |cffcccccc(+"..(alt_data.drakes_max - alt_data.drakes_earned)..")|r"
					end
				end
				return tostring(alt_data.drakes_crest or "?")
			end,
		},
		wyrms_crest = {
			order = 5030,
			label = C.labels.wyrmCrest,
			enabled = true,
			configKey = "showTier3Crest",
			data = function(alt_data)
				-- REMOVE `false and` WHEN TURBO BOOST IS OVER
				if (self:GetConfigValue("showRemainingCrestsEnabled", alt_data.guid)) then
					if (alt_data.wyrms_max == alt_data.wyrms_earned) then
						return "|cFF39ec3c" .. tostring(alt_data.wyrms_crest or "?") .. "|r"
					else 
						return tostring(alt_data.wyrms_crest or "?").." |cffcccccc(+"..(alt_data.wyrms_max - alt_data.wyrms_earned)..")|r"
					end
				end
				return tostring(alt_data.wyrms_crest or "?")
			end,
		},
		aspects_crest = {
			order = 5040,
			label = C.labels.aspectCrest,
			enabled = true,
			configKey = "showTier4Crest",
			data = function(alt_data)
				-- REMOVE `false and` WHEN TURBO BOOST IS OVER
				if (self:GetConfigValue("showRemainingCrestsEnabled", alt_data.guid)) then
					if (alt_data.aspects_max == alt_data.aspects_earned) then
						return "|cFF39ec3c" .. tostring(alt_data.aspects_crest or "?") .. "|r"
					else 
						return tostring(alt_data.aspects_crest or "?").." |cffcccccc(+"..(alt_data.aspects_max - alt_data.aspects_earned)..")|r"
					end
				end
				return tostring(alt_data.aspects_crest or "?")
			end,
		},
		myth_crest = {
			order = 5050,
			label = C.labels.mythCrest,
			enabled = true,
			configKey = "showTier5Crest",
			data = function(alt_data)
				-- REMOVE `false and` WHEN TURBO BOOST IS OVER
				if (self:GetConfigValue("showRemainingCrestsEnabled", alt_data.guid)) then
					if (alt_data.tier5_max == alt_data.tier5_earned) then
						return "|cFF39ec3c" .. tostring(alt_data.tier5_crest or "?") .. "|r"
					else 
						return tostring(alt_data.tier5_crest or "?").." |cffcccccc(+"..(alt_data.tier5_max - alt_data.tier5_earned)..")|r"
					end
				end
				return tostring(alt_data.tier5_crest or "?")
			end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET_2 = {
			order = 6000,
			label = "",
			enabled = true,
			sectionId = C.sectionNames["PVP"],
			data = function(alt_data) return " " end,
		},
		honor_points = {
			order = 6010,
			label = C.labels.honor,
			enabled = true,
			configKey = "showPVPCurrenciesEnabled",
			data = function(alt_data) return tostring(alt_data.honor_points or "?") end,
		},
		conquest_pts = {
			order = 6020,
			label = C.labels.conquest,
			enabled = true,
			configKey = "showPVPCurrenciesEnabled",
			data = function(alt_data) return (alt_data.conquest_total and tostring(alt_data.conquest_total) or "0")  end,
		},
		conquest_cap = {
			order = 6030,
			label = C.labels.conquestEarned,
			enabled = true,
			configKey = "showPVPCurrenciesEnabled",
			data = function(alt_data) return (alt_data.conquest_earned and (tostring(alt_data.conquest_earned) .. " / " .. C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CONQUEST_CURRENCY_ID).maxQuantity) or "?")  end, --   .. "/" .. "500"
		},
		-- ! Offset
		BLANK_LINE = {
			order = 7000,
			label = " ",
			enabled = true,
			sectionId = C.sectionNames["Raids"],
			data = function(alt_data) return " " end,
		},
		-- worldboss = {
		-- 	order = 7010,
		-- 	label = C.labels.worldBoss,
		-- 	enabled = AltismManagerDB.showWorldBossEnabled,
		-- 	data = function(alt_data)
		-- 		if alt_data.worldboss == nil then return "|cffff0000Available|r" else return "|cff00ff00Defeated|r" end 
		-- 	end,
		-- },
		mythic = {
			order = 7020,
			label = C.labels.mythic,
			type = "raidprogress",
			enabled = true,
			configKey = "showMythicRaidEnabled",
			data = function(alt_data)
				return self:GetMidnightRaidProgressData(alt_data, "mythic_savedata")
			end
		},
		heroic = {
			order = 7030,
			label = C.labels.heroic,
			type = "raidprogress",
			enabled = true,
			configKey = "showHeroicRaidEnabled",
			data = function(alt_data)
				return self:GetMidnightRaidProgressData(alt_data, "heroic_savedata")
			end
		},
		normal = {
			order = 7040,
			label = C.labels.normal,
			type = "raidprogress",
			enabled = true,
			configKey = "showNormalRaidEnabled",
			data = function(alt_data)
				return self:GetMidnightRaidProgressData(alt_data, "normal_savedata")
			end
		},
	}
	self.columns_table = column_table;

	-- create labels and unrolls
	local font_height = 20;
	local label_column = self.main_frame.label_column or CreateFrame("Button", nil, self.main_frame);
	if not self.main_frame.label_column then self.main_frame.label_column = label_column; end
	label_column:SetSize(C.pixelSizing.perAltX, self:CalculateYSize());
	label_column:SetPoint("TOPLEFT", self.main_frame, "TOPLEFT", 4, -1);

	local i = 1;
	for row_iden, row in spairs(self.columns_table, function(t, a, b) return t[a].order < t[b].order end) do
		local rowEnabledAnywhere = self:IsColumnVisibleAnywhere(row)
		if row.label and rowEnabledAnywhere then
			local fontPath = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf"
			local label_row = self:CreateFontFrame(self.main_frame, C.pixelSizing.perAltX, font_height, label_column, -(i-1)*font_height, row.label~="" and row.label or " ", "RIGHT", fontPath);
			self.main_frame.lowest_point = -(i-1)*font_height;
		end
		if rowEnabledAnywhere then
			i = i + 1
		end
	end

end

function AltismManager:MakeRaidString(normal, heroic, mythic)
	if not normal then normal = 0 end
	if not heroic then heroic = 0 end
	if not mythic then mythic = 0 end

	local string = ""
	if mythic > 0 then string = string .. tostring(mythic) .. "M" end
	if heroic > 0 and mythic > 0 then string = string .. "/" end
	if heroic > 0 then string = string .. tostring(heroic) .. "H" end
	if normal > 0 and (mythic > 0 or heroic > 0) then string = string .. "/" end
	if normal > 0 then string = string .. tostring(normal) .. "N" end
	return string == "" and "-" or string
end

function AltismManager:HideInterface()
	self.main_frame:Hide();
end

function AltismManager:ShowInterface()
	self.main_frame:Show();
	self.main_frame:SetSize(self:CalculateXSize(), self:CalculateYSize());
	self:StoreData(self:CollectData())
	self.main_frame:SetSize(self:CalculateXSize(), self:CalculateYSize());
	self:UpdateStrings();
end

function AltismManager:EnsureGearDialog()
	if self.gearDialog then
		return self.gearDialog
	end

	local dialog = CreateFrame("Frame", "AltismManagerGearDialog", UIParent, "BasicFrameTemplateWithInset")
	local dialogWidth = 980
	local rowHeight = 32
	local rowSpacing = 2
	local totalRows = #self:GetGearSlotDefinitions()
	local contentHeight = (totalRows * rowHeight) + ((totalRows - 1) * rowSpacing)
	local dialogHeight = contentHeight + 70
	dialog:SetSize(dialogWidth, dialogHeight)
	dialog:SetPoint("CENTER")
	dialog:SetFrameStrata("FULLSCREEN_DIALOG")
	dialog:SetFrameLevel(50)
	dialog:EnableKeyboard(true)
	dialog:SetScript("OnKeyDown", function(self, key)
		if key == "ESCAPE" then
			self:SetPropagateKeyboardInput(false)
			self:Hide()
		else
			self:SetPropagateKeyboardInput(true)
		end
	end)
	dialog:SetScript("OnShow", function(self)
		self:SetPropagateKeyboardInput(true)
	end)
	dialog:Hide()

	dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	dialog.title:SetPoint("TOP", dialog, "TOP", 0, -8)
	dialog.title:SetText("Character Gear")

	dialog.content = CreateFrame("Frame", nil, dialog)
	dialog.content:SetPoint("TOPLEFT", dialog, "TOPLEFT", 12, -28)
	dialog.content:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -12, -28)
	dialog.content:SetSize(956, 1)
	dialog.rows = {}

	for idx, slotDef in ipairs(self:GetGearSlotDefinitions()) do
		local row = CreateFrame("Button", nil, dialog.content)
		row:SetSize(948, 32)
		if idx == 1 then
			row:SetPoint("TOPLEFT", dialog.content, "TOPLEFT", 0, 0)
		else
			row:SetPoint("TOPLEFT", dialog.rows[idx - 1], "BOTTOMLEFT", 0, -2)
		end

		row.bg = row:CreateTexture(nil, "BACKGROUND")
		row.bg:SetAllPoints()
		row.bg:SetColorTexture(0.05, 0.05, 0.08, idx % 2 == 0 and 0.3 or 0.15)

		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(28, 28)
		row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)

		row.slot = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		row.slot:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
		row.slot:SetWidth(92)
		row.slot:SetJustifyH("LEFT")

		row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		row.name:SetPoint("LEFT", row.slot, "RIGHT", 6, 0)
		row.name:SetWidth(220)
		row.name:SetJustifyH("LEFT")

		row.trackLine = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.trackLine:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
		row.trackLine:SetWidth(220)
		row.trackLine:SetJustifyH("LEFT")

		row.enchant = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.enchant:SetPoint("LEFT", row.trackLine, "RIGHT", 6, 0)
		row.enchant:SetWidth(340)
		row.enchant:SetJustifyH("LEFT")

		row:SetScript("OnEnter", function(self)
			if self.itemLink then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(self.itemLink)
				GameTooltip:Show()
			end
		end)
		row:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		dialog.rows[idx] = row
	end

	if #dialog.rows > 0 then
		dialog.content:SetHeight(contentHeight)
	end

	self.gearDialog = dialog
	return dialog
end

function AltismManager:ShowGearDialog(alt_data)
	if not alt_data then return end
	local dialog = self:EnsureGearDialog()
	dialog.title:SetText((alt_data.name or "Unknown") .. " - " .. (alt_data.realm or "Unknown") .. " Gear")

	local gear = alt_data.gear or {}
	for idx, slotDef in ipairs(self:GetGearSlotDefinitions()) do
		local row = dialog.rows[idx]
		if row then
			local item = gear[slotDef.id] or {
				slotId = slotDef.id,
				slotLabel = slotDef.label,
				itemLink = nil,
				name = "Empty",
				ilvl = 0,
				rarity = 1,
				track = "-",
				trackProgress = "-",
				isCrafted = false,
				enchant = "-",
				icon = "Interface\\Icons\\INV_Misc_QuestionMark",
			}

			row.itemLink = item.itemLink
			row.icon:SetTexture(item.icon)
			row.slot:SetText(item.slotLabel or slotDef.label)
			row.name:SetText(item.name or "Unknown Item")
			row.trackLine:SetText(self:FormatGearTrackText(item))

			local enchantText = item.enchant or "-"
			local hasEnchant = enchantText ~= "" and enchantText ~= "-"
			local requiresEnchant = self:SlotRequiresEnchant(alt_data, item)
			if requiresEnchant and not hasEnchant then
				row.enchant:SetText("|cffff4040Missing|r")
			else
				row.enchant:SetText(enchantText)
			end

			local qualityColor = ITEM_QUALITY_COLORS[item.rarity or 1] or ITEM_QUALITY_COLORS[1]
			row.name:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b, 1)
		end
	end

	dialog:Show()
end

function AltismManager:CreateRemoveButton(func)
	local frame = CreateFrame("Button", nil, nil)
	frame:ClearAllPoints()
	frame:SetScript("OnClick", function() func() end);
	self:MakeRemoveTexture(frame)
	frame:SetWidth(C.pixelSizing.removeButtonSize)
	return frame
end

function AltismManager:CreateGearButton(func)
	local frame = CreateFrame("Button", nil, nil)
	frame:ClearAllPoints()
	frame:SetScript("OnClick", function() func() end)
	frame:SetSize(C.pixelSizing.removeButtonSize, C.pixelSizing.removeButtonSize)
	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetTexture("Interface\\Icons\\INV_Chest_Plate06")
	frame.icon:SetAllPoints()
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Show Character Gear")
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return frame
end

function AltismManager:MakeRemoveTexture(frame)
	if frame.remove_tex == nil then
		frame.remove_tex = frame:CreateTexture(nil, "BACKGROUND")
		frame.remove_tex:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
		frame.remove_tex:SetAllPoints()
		frame.remove_tex:Show();
	end
	return frame
end

function AltismManager:MakeTopBottomTextures(frame)
	if frame.bottomPanel == nil then
		frame.bottomPanel = frame:CreateTexture(nil);
	end
	if frame.topPanel == nil then
		frame.topPanel = CreateFrame("Frame", "AltismManagerTopPanel", frame);
		frame.topPanelTex = frame.topPanel:CreateTexture(nil, "BACKGROUND");
		frame.topPanelTex:SetAllPoints();
		frame.topPanelTex:SetDrawLayer("ARTWORK", -5);
		frame.topPanelTex:SetColorTexture(0, 0, 0.05, 1);

		frame.topPanelString = frame.topPanel:CreateFontString("OVERLAY");
		frame.topPanelString:SetFont("Interface\\AddOns\\AltismManager\\fonts\\expressway.otf", 22)
		frame.topPanelString:SetTextColor(0.95, 0.95, 0.95, 1);
		frame.topPanelString:SetJustifyH("CENTER")
		frame.topPanelString:SetJustifyV("MIDDLE")
		frame.topPanelString:SetWidth(260)
		frame.topPanelString:SetHeight(20)
		frame.topPanelString:SetText("Altism Manager");
		frame.topPanelString:ClearAllPoints();
		frame.topPanelString:SetPoint("CENTER", frame.topPanel, "CENTER", 0, 0);
		frame.topPanelString:Show();
	end

	frame.bottomPanel:SetColorTexture(0, 0, 0.05, 1);
	frame.bottomPanel:ClearAllPoints();
	frame.bottomPanel:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0);
	frame.bottomPanel:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0);
	frame.bottomPanel:SetSize(frame:GetWidth(), 10);
	frame.bottomPanel:SetDrawLayer("ARTWORK", 7);

	frame.topPanel:ClearAllPoints();
	frame.topPanel:SetSize(frame:GetWidth(), 35);
	frame.topPanel:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0);
	frame.topPanel:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0);

	frame:SetMovable(true);
	frame.topPanel:EnableMouse(true);
	frame.topPanel:RegisterForDrag("LeftButton");
	frame.topPanel:SetScript("OnDragStart", function(self,button)
		frame:SetMovable(true);
        frame:StartMoving();
    end);
	frame.topPanel:SetScript("OnDragStop", function(self,button)
        frame:StopMovingOrSizing();
		frame:SetMovable(false);
    end);
end

function AltismManager:MakeBorderPart(frame, x, y, xoff, yoff, part)
	if part == nil then
		part = frame:CreateTexture(nil);
	end
	part:SetTexture(0, 0, 0, 1);
	part:ClearAllPoints();
	part:SetPoint("TOPLEFT", frame, "TOPLEFT", xoff, yoff);
	part:SetSize(x, y);
	part:SetDrawLayer("ARTWORK", 7);
	return part;
end

function AltismManager:MakeBorder(frame, size)
	if size == 0 then
		return;
	end
	frame.borderTop = self:MakeBorderPart(frame, frame:GetWidth(), size, 0, 0, frame.borderTop); -- top
	frame.borderLeft = self:MakeBorderPart(frame, size, frame:GetHeight(), 0, 0, frame.borderLeft); -- left
	frame.borderBottom = self:MakeBorderPart(frame, frame:GetWidth(), size, 0, -frame:GetHeight() + size, frame.borderBottom); -- bottom
	frame.borderRight = self:MakeBorderPart(frame, size, frame:GetHeight(), frame:GetWidth() - size, 0, frame.borderRight); -- right
end


-- ! DATETIME RELATED FUNCTIONS
-- ! SHAMELESSLY STOLEN FROM SAVEDINSTANCES (you are the goats)

function AltismManager:GetNextWeeklyResetTime()
	if not self.resetDays then
		local region = self:GetRegion()
		if not region then return nil end
		self.resetDays = {}
		self.resetDays.DLHoffset = 0
		if region == "US" then
			self.resetDays["2"] = true -- tuesday
			-- ensure oceanic servers over the dateline still reset on tues UTC (wed 1/2 AM server)
			self.resetDays.DLHoffset = -3
		elseif region == "EU" then
			self.resetDays["3"] = true -- wednesday
		elseif region == "CN" or region == "KR" or region == "TW" then -- XXX: codes unconfirmed
			self.resetDays["4"] = true -- thursday
		else
			self.resetDays["2"] = true -- tuesday?
		end
	end
	local offset = (self:GetServerOffset() + self.resetDays.DLHoffset) * 3600
	local nightlyReset = self:GetNextDailyResetTime()
	if not nightlyReset then return nil end
	while not self.resetDays[date("%w",nightlyReset+offset)] do
		nightlyReset = nightlyReset + 24 * 3600
	end
	return nightlyReset
end

function AltismManager:GetNextDailyResetTime()
	local resettime = GetQuestResetTime()
	if not resettime or resettime <= 0 or -- ticket 43: can fail during startup
		-- also right after a daylight savings rollover, when it returns negative values >.<
		resettime > 24*3600+30 then -- can also be wrong near reset in an instance
		return nil
	end
	if false then -- this should no longer be a problem after the 7.0 reset time changes
		-- ticket 177/191: GetQuestResetTime() is wrong for Oceanic+Brazilian characters in PST instances
		local serverHour, serverMinute = GetGameTime()
		local serverResetTime = (serverHour*3600 + serverMinute*60 + resettime) % 86400 -- GetGameTime of the reported reset
		local diff = serverResetTime - 10800 -- how far from 3AM server
		if math.abs(diff) > 3.5*3600  -- more than 3.5 hours - ignore TZ differences of US continental servers
			and self:GetRegion() == "US" then
			local diffhours = math.floor((diff + 1800)/3600)
			resettime = resettime - diffhours*3600
			if resettime < -900 then -- reset already passed, next reset
				resettime = resettime + 86400
				elseif resettime > 86400+900 then
				resettime = resettime - 86400
			end
		end
	end
	return time() + resettime
end

function AltismManager:GetServerOffset()
	local serverDay = C_DateAndTime.GetCurrentCalendarTime().weekday - 1 -- 1-based starts on Sun
	local localDay = tonumber(date("%w")) -- 0-based starts on Sun
	local serverHour, serverMinute = GetGameTime()
	local localHour, localMinute = tonumber(date("%H")), tonumber(date("%M"))
	if serverDay == (localDay + 1)%7 then -- server is a day ahead
		serverHour = serverHour + 24
	elseif localDay == (serverDay + 1)%7 then -- local is a day ahead
		localHour = localHour + 24
	end
	local server = serverHour + serverMinute / 60
	local localT = localHour + localMinute / 60
	local offset = floor((server - localT) * 2 + 0.5) / 2
	return offset
end

function AltismManager:GetRegion()
	if not self.region then
		local reg
		reg = GetCVar("portal")
		if reg == "public-test" then -- PTR uses US region resets, despite the misleading realm name suffix
			reg = "US"
		end
		if not reg or #reg ~= 2 then
			local gcr = GetCurrentRegion()
			reg = gcr and ({ "US", "KR", "EU", "TW", "CN" })[gcr]
		end
		if not reg or #reg ~= 2 then
			reg = (GetCVar("realmList") or ""):match("^(%a+)%.")
		end
		if not reg or #reg ~= 2 then -- other test realms?
			reg = (GetRealmName() or ""):match("%((%a%a)%)")
		end
		reg = reg and reg:upper()
		if reg and #reg == 2 then
			self.region = reg
		end
	end
	return self.region
end

function AltismManager:GetWoWDate()
	local hour = tonumber(date("%H"));
	local day = C_DateAndTime.GetCurrentCalendarTime().weekday;
	return day, hour;
end

function AltismManager:TimeString(length)
	if length == 0 then
		return "Now";
	end
	if length < 3600 then
		return string.format("%d mins", length / 60);
	end
	if length < 86400 then
		return string.format("%d hrs %d mins", length / 3600, (length % 3600) / 60);
	end
	return string.format("%d days %d hrs", length / 86400, (length % 86400) / 3600);
end

function SlashCmdList.ALTMANAGER(cmd, editbox)
	local rqst, arg = strsplit(' ', cmd)
	
	if rqst == "help" then
			print("Alt Manager help:")
			print("   \"/am or /alts\" to open main addon window.")
			print("   \"/alts purge\" to remove all stored data.")
			print("   \"/alts remove name\" to remove characters by name.")
			print("   \"/alts mm\" to toggle the minimap button visibility.")
	elseif rqst == "config" then
		if not AltismManager.settingsCategory then
			print("[Alt Manager] Config panel was not initialized. Try /reload-ing and report the issue if it persists.")
		end
		Settings.OpenToCategory(AltismManager.settingsCategory.ID)
	elseif rqst == "purge" then
			AltismManager:Purge()
	elseif rqst == "remove" then
			AltismManager:RemoveCharactersByName(arg)
	elseif rqst == "mm" then
			if minimapButton then
					if minimapButton:IsShown() then
							minimapButton:Hide()
							print("[Alt Manager]: Minimap button hidden.")
					else
							minimapButton:Show()
							-- Save the state to the saved variables
							SaveMinimapButtonPosition()
							print("[Alt Manager]: Minimap button is now visible.")
					end
			else
					print("[Alt Manager]: Minimap button is not initialized.")
			end
	else
			AltismManager:ShowInterface()
	end
end
