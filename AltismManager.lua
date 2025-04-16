local addonName, AltismManager = ...;
_G["AltismManager"] = AltismManager;
local Dialog = LibStub("LibDialog-1.0")

-- CONSTANTS
local sizeY = 560;
local pvpToggleSize = 90;
local undermineToggleSize = 30;
local worldBossToggleSize = 30;
local goldToggleSize = 20;
local valorstonesToggleSize = 60;
local raidVaultToggleSize = 30;
local mythicPlusVaultToggleSize = 30;
local delveVaultToggleSize = 30;
local cofferKeysToggleSize = 30;
local mythicPlusToggleSize = 90;

local offsetX = 0;
local offsetY = 40;
local addonName = "AltismManager";
local perAltX = 150;
local ilvlTextSize = 8;
local removeButtonSize = 12;
local minSizeX = 300;
local minLevel = 70;

local mythTrackKeyVaultThreshold = 10
local maxLootDelveVaultThreshold = 8

local nameLabel = "" -- Name
-- /dump C_CurrencyInfo.GetCurrencyInfo(#)
local mythicKeystoneLabel = "Keystone |T525134:16:16:0:0|t"
local mythicPlusLabel = "Mythic+ Rating"
local worldBossLabel = "World Boss"
local conquestLabel = "Conquest |T1523630:16:16:0:0|t"
local conquestEarnedLabel = "Conquest Earned"
local whelplingCrestLabel = "Weathered |T5872053:16:16:0:0|t"
local drakeCrestLabel = "Carved |T5872047:16:16:0:0|t"
local wyrmCrestLabel = "Runed |T5872051:16:16:0:0|t"
local aspectCrestLabel = "Gilded |T5872049:16:16:0:0|t"
local honorLabel = "Honor |T1455894:16:16:0:0|t"
local flightstoneLabel = "Valorstones |T5868902:16:16:0:0|t"
-- local undercoinLabel = "Undercoin"
-- local resonanceCrystalLabel = "Resonance Crystal"
local isTimerunner = nil

SLASH_ALTMANAGER1 = "/am";
SLASH_ALTMANAGER2 = "/alts";

local function GetCurrencyAmount(id)
	local info = C_CurrencyInfo.GetCurrencyInfo(id)
	return info.quantity;
end

local function GetCurrencyEarned(id)
	local info = C_CurrencyInfo.GetCurrencyInfo(id)
	return info.totalEarned;
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

do
	local main_frame = CreateFrame("frame", nil, UIParent)
	AltismManager.main_frame = main_frame
	main_frame:SetFrameStrata("MEDIUM")
	main_frame.background = main_frame:CreateTexture(nil, "BACKGROUND")
	main_frame.background:SetAllPoints()
	main_frame.background:SetDrawLayer("ARTWORK", 1)
	main_frame.background:SetColorTexture(0, 0, 0, 0.75)

	-- Set frame position
	main_frame:ClearAllPoints()
	main_frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
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
	t.showGoldEnabled = true;
	t.showMythicPlusDataEnabled = true;
	t.showValorstonesEnabled = true;
	t.showPVPCurrenciesEnabled = false;
	t.showUndermineEnabled = true;
	t.showWorldBossEnabled = false;
	t.showRemainingCrestsEnabled = true;
	t.showMythicPlusVaultEnabled = true;
	t.showDelveVaultEnabled = true;
	t.showCofferKeysEnabled = true;
	return t;
end

function AltismManager:CalculateXSizeNoGuidCheck()
	local alts = AltismManagerDB.alts;
	return max((alts + 1) * perAltX, minSizeX)
end

function AltismManager:CalculateXSize()
	return self:CalculateXSizeNoGuidCheck()
end

function AltismManager:CalculateYSize()
	local modifiedSize = sizeY;
	if AltismManagerDB then
		if not AltismManagerDB.showPVPCurrenciesEnabled then
			modifiedSize = modifiedSize - pvpToggleSize;
		end
		if not AltismManagerDB.showMythicPlusDataEnabled then
			modifiedSize = modifiedSize - mythicPlusToggleSize;
		end
		if not AltismManagerDB.showValorstonesEnabled then
			modifiedSize = modifiedSize - valorstonesToggleSize;
		end
		if not AltismManagerDB.showWorldBossEnabled then
			modifiedSize = modifiedSize - worldBossToggleSize;
		end
		if not AltismManagerDB.showUndermineEnabled then
			modifiedSize = modifiedSize - undermineToggleSize;
		end
		if not AltismManagerDB.showGoldEnabled then
			modifiedSize = modifiedSize - goldToggleSize;
		end
		if not AltismManagerDB.showRaidVaultEnabled then
			modifiedSize = modifiedSize - raidVaultToggleSize;
		end
		if not AltismManagerDB.showMythicPlusVaultEnabled then
			modifiedSize = modifiedSize - mythicPlusVaultToggleSize;
		end
		if not AltismManagerDB.showDelveVaultEnabled then
			modifiedSize = modifiedSize - delveVaultToggleSize;
		end
		if not AltismManagerDB.showCofferKeysEnabled then
			modifiedSize = modifiedSize - cofferKeysToggleSize;
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
		if alt_data.charlevel == nil or alt_data.charlevel < minLevel or isTimerunner ~= nil then -- poor heuristic to remove old max level chars
			table.insert(remove, alt_guid)
		end
	end
	for k, v in pairs(remove) do
		-- don't need to redraw, this is don on load
		AltismManagerDB.alts = AltismManagerDB.alts - 1;
		AltismManagerDB.data[v] = nil
	end
end

function AltismManager:AddMissingPostReleaseFields()
	AltismManagerDB.showGoldEnabled = AltismManagerDB.showGoldEnabled or true;
	AltismManagerDB.showMythicPlusDataEnabled = AltismManagerDB.showMythicPlusDataEnabled or true;
	AltismManagerDB.showValorstonesEnabled = AltismManagerDB.showValorstonesEnabled or true;
	AltismManagerDB.showPVPCurrenciesEnabled = AltismManagerDB.showPVPCurrenciesEnabled or true;
	AltismManagerDB.showWorldBossEnabled = AltismManagerDB.showWorldBossEnabled or true;
	AltismManagerDB.showUndermineEnabled = AltismManagerDB.showUndermineEnabled or true;
end

function AltismManager:OnLoad()
	self.main_frame:UnregisterEvent("ADDON_LOADED");

	AltismManagerDB = AltismManagerDB or self:InitDB();

	self:PurgeDbShadowlands();
	-- self:AddMissingPostReleaseFields();

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
iconTexture:SetTexture("Interface\\ICONS\\inv_misc_grouplooking")
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
minimapButton:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        dragging = true
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        startX, startY = (px / scale) - mx, (py / scale) - my
        startAngle = math.atan2(startY, startX)
    elseif button == "RightButton" then
        --print("Right-click detected")  -- Debug message
        ToggleMinimapButtonVisibility()
    end
end)

minimapButton:SetScript("OnMouseUp", function(self, button)
    if dragging and button == "LeftButton" then
        dragging = false
        -- Save the new position
        SaveMinimapButtonPosition()
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
    GameTooltip:AddLine("Right-click |cffffff00to hide button|r")
    GameTooltip:AddLine("|cffffff00/alts mm|r to restore button")
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

--[[
function AltismManager:CreateFontFrame(parent, x_size, height, relative_to, y_offset, label, justify)
	local f = CreateFrame("Button", nil, parent);
	f:SetSize(x_size, height);
	f:SetNormalFontObject("GameFontHighlightSmall")
	f:SetText(label)
	f:SetPoint("TOPLEFT", relative_to, "TOPLEFT", 0, y_offset);
	f:GetFontString():SetJustifyH(justify);
	f:GetFontString():SetJustifyV("MIDDLE");
	f:SetPushedTextOffset(0, 0);
	f:GetFontString():SetWidth(120)
	f:GetFontString():SetHeight(20)

	return f;
end
]]

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
	if not self.addon_loaded or not data or not data.guid or UnitLevel('player') < minLevel or isTimerunner ~= nil then
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
	[247] = "ML",
	-- [248] = "WCM",
	-- [249] = "KR",
	-- [250] = "Seth",
	-- [251] = "UR",
	-- [252] = "SotS",
	--[353] = "SoB",
	--[369] = "YARD",
	[370] = "WORK",
	-- Shadowlands
	--[375] = "MoTS",
	--[376] = "NW",
	-- [377] = "DOS",
	-- [378] = "HoA",
	-- [379] = "PF",
	-- [380] = "SD",
	-- [381] = "SoA",
	[382] = "ToP",
	-- [391] = "STRT",
	-- [392] = "GMBT",
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
	[499] = "PSF", -- Priory of the Sacred Flame
	[500] = "ROOK", -- The Rookery
	--[501] = "SV", -- The Stonevault
	--[502] = "COT", -- City of Threads
	--[503] = "ARAK", -- Ara-Kara, City of Echoes
	[504] = "DFC", -- Darkflame Cleft
	--[505] = "DAWN", -- The Dawnbreaker
	[506] = "BREW", -- Cinderbrew Meadery
	[525] = "FLOOD", -- Operation: Floodgate
};

function AltismManager:CollectData()
	if UnitLevel('player') < minLevel or isTimerunner ~= nil then return end;
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

	-- C_MythicPlus.RequestRewards();
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
	for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		for slot=1, C_Container.GetContainerNumSlots(bag) do
			local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
			if containerInfo ~= nil then
				local slotItemID = containerInfo.itemID
				local slotLink = containerInfo.hyperlink
				if slotItemID == 180653 then
					local itemString = slotLink:match("|Hkeystone:([0-9:]+)|h(%b[])|h")
					local info = { strsplit(":", itemString) }
					dungeon = tonumber(info[2])
					if not dungeon then dungeon = nil end
					level = tonumber(info[3])
					if not level then level = nil end
					keystone_found = true;
					break -- Exit the loop after finding the keystone
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
	local undermineMapName = C_Map.GetMapInfo(2406).name
	if (self:GetRegion() == "US") then
		-- Undermine !== Liberation of Undermine VeryMad
		undermineMapName = "Liberation of Undermine"
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

		if raid_name == undermineMapName and reset > 0 then
			-- Save names like this instead of hardcoding for localization support
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

	local weeklyRaid = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Raid);
	if (#weeklyRaid < 3) then
		print("[AltismManager]: Issue retrieving raid vault data, values may be inaccurate.")
	else
		local raidVaultOutput = {}
		table.insert(raidVaultOutput, difficultyMap[weeklyRaid[1].level] or "X")
		table.insert(raidVaultOutput, difficultyMap[weeklyRaid[2].level] or "X")
		table.insert(raidVaultOutput, difficultyMap[weeklyRaid[3].level] or "X")
		char_table.raidvault = raidVaultOutput
	end

	local weeklyDelve = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.World);
	if (#weeklyDelve < 3) then
		print("[AltismManager]: Issue retrieving delve vault data, values may be inaccurate.")
	else
		local delveVaultOutput = {}
		table.insert(delveVaultOutput, weeklyDelve[1].level or "X")
		table.insert(delveVaultOutput, weeklyDelve[2].level or "X")
		table.insert(delveVaultOutput, weeklyDelve[3].level or "X")
		char_table.delvevault = delveVaultOutput
	end

	local weeklyKeys = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.MythicPlus);
	if (#weeklyKeys < 3) then
		print("[AltismManager]: Issue retrieving M+ vault data, values may be inaccurate.")
	else
		local mythicPlusVaultOutput = {}
		table.insert(mythicPlusVaultOutput, weeklyKeys[1].level or "X")
		table.insert(mythicPlusVaultOutput, weeklyKeys[2].level or "X")
		table.insert(mythicPlusVaultOutput, weeklyKeys[3].level or "X")
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
	local relevantWorldBossID = 85088 -- Gobfather
	local worldBossKilled = C_QuestLog.IsQuestFlaggedCompleted(relevantWorldBossID)

	local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CONQUEST_CURRENCY_ID);
	local maxProgress = currencyInfo.maxQuantity;
	local conquest_earned = math.min(currencyInfo.totalEarned, maxProgress);
	local conquest_total = currencyInfo.quantity

	local _, ilevel = GetAverageItemLevel();
	local gold = GetMoneyString(GetMoney(), true)
	local whelplings_crest = GetCurrencyAmount(3107);
	local whelplings_info = C_CurrencyInfo.GetCurrencyInfo(3107);
	local whelplings_max = whelplings_info.maxQuantity;
	local whelplings_earned = whelplings_info.totalEarned;
	local drakes_crest = GetCurrencyAmount(3108);
	local drakes_info = C_CurrencyInfo.GetCurrencyInfo(3108);
	local drakes_max = drakes_info.maxQuantity;
	local drakes_earned = drakes_info.totalEarned;
	local wyrms_crest = GetCurrencyAmount(3109);
	local wyrms_info = C_CurrencyInfo.GetCurrencyInfo(3109);
	local wyrms_max = wyrms_info.maxQuantity;
	local wyrms_earned = wyrms_info.totalEarned;
	local aspects_crest = GetCurrencyAmount(3110);
	local aspects_info = C_CurrencyInfo.GetCurrencyInfo(3110);
	local aspects_max = aspects_info.maxQuantity;
	local aspects_earned = aspects_info.totalEarned;
	local honor_points = GetCurrencyAmount(1792);
	local flightstones = GetCurrencyAmount(3008);
	local undercoin = GetCurrencyAmount(2803);
	local resonance_crystal = GetCurrencyAmount(2815);
	local mplus_data = C_PlayerInfo.GetPlayerMythicPlusRatingSummary('player')
	local mplus_score = mplus_data.currentSeasonScore

	local cofferKey1 = C_QuestLog.IsQuestFlaggedCompleted(84736)
	local cofferKey2 = C_QuestLog.IsQuestFlaggedCompleted(84737)
	local cofferKey3 = C_QuestLog.IsQuestFlaggedCompleted(84738)
	local cofferKey4 = C_QuestLog.IsQuestFlaggedCompleted(84739)
	
	local function b2n(bool)
		if bool then
			return 1
		else
			return 0
		end
	end
	
	char_table.guid = UnitGUID('player');
	char_table.name = name;
	char_table.class = class;
	char_table.ilevel = ilevel;
	char_table.charlevel = UnitLevel('player')
	char_table.dungeon = dungeon;
	char_table.level = level;
	char_table.run_history = run_history;
	char_table.worldboss = worldBossKilled;
	char_table.conquest_earned = conquest_earned;
	char_table.conquest_total = conquest_total;

	char_table.mplus_score = mplus_score
	char_table.gold = gold;
	char_table.whelplings_crest = whelplings_crest;
	char_table.whelplings_max = whelplings_max;
	char_table.whelplings_earned = whelplings_earned;
	char_table.drakes_crest = drakes_crest;
	char_table.drakes_max = drakes_max;
	char_table.drakes_earned = drakes_earned;
	char_table.wyrms_crest = wyrms_crest;
	char_table.wyrms_max = wyrms_max;
	char_table.wyrms_earned = wyrms_earned;
	char_table.aspects_crest = aspects_crest;
	char_table.aspects_max = aspects_max;
	char_table.aspects_earned = aspects_earned;
	char_table.flightstones = flightstones;
	char_table.undercoin = undercoin;
	char_table.resonance_crystal = resonance_crystal;
	char_table.honor_points = honor_points;
	char_table.cofferKeysObtained = b2n(cofferKey1) + b2n(cofferKey2) + b2n(cofferKey3) + b2n(cofferKey4)

	char_table.undermine_normal = Undermine_Normal;
	char_table.undermine_heroic = Undermine_Heroic;
	char_table.undermine_mythic = Undermine_Mythic;

	char_table.expires = self:GetNextWeeklyResetTime();
	char_table.data_obtained = time();
	char_table.time_until_reset = C_DateAndTime.GetSecondsUntilDailyReset();

	-- if char_table.raidsaves then
	-- 	print(#char_table.raidsaves)
	-- 	for raid, data in pairs(char_table.raidsaves) do
	-- 		print("Raid:", raid)
	-- 		for boss, isKilled in pairs(data) do
	-- 			print("  Boss:", boss, "Killed:", tostring(isKilled))
	-- 		end
	-- 	end
	-- else
	-- 	print("No raid saves found.")
	-- end

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

	local alt = 0
	for alt_guid, alt_data in spairs(db.data, function(t, a, b) return t[a].ilevel > t[b].ilevel end) do
		alt = alt + 1
		-- create the frame to which all the fontstrings anchor
		local anchor_frame = self.main_frame.alt_columns[alt] or CreateFrame("Button", nil, self.main_frame);
		if not self.main_frame.alt_columns[alt] then
			self.main_frame.alt_columns[alt] = anchor_frame;
			self.main_frame.alt_columns[alt].guid = alt_guid
			anchor_frame:SetPoint("TOPLEFT", self.main_frame, "TOPLEFT", perAltX * alt, -1);
		end
		anchor_frame:SetSize(perAltX, self:CalculateYSize());
		-- init table for fontstring storage
		self.main_frame.alt_columns[alt].label_columns = self.main_frame.alt_columns[alt].label_columns or {};
		local label_columns = self.main_frame.alt_columns[alt].label_columns;
		-- create / fill fontstrings
		local i = 1;
		for column_iden, column in spairs(self.columns_table, function(t, a, b) return t[a].order < t[b].order end) do
			-- only display data with values
			if column.type == "raidprogress" then
				for raidIndex = 1,8 do
					local raidIcon = anchor_frame:CreateTexture(nil);
					if column.data(alt_data) and column.data(alt_data)[raidIndex] then
						if column.label == "Mythic" then
							raidIcon:SetColorTexture(0.64, 0.21, 0.93, 1);
						elseif column.label == "Heroic" then
							raidIcon:SetColorTexture(0, 0.44, 0.87, 1);
						else
							raidIcon:SetColorTexture(0.12, 1, 0, 1);
						end
					else
						raidIcon:SetColorTexture(0.2, 0.2, 0.2, 1);
					end
					raidIcon:ClearAllPoints();
					raidIcon:SetPoint(
						"TOPLEFT",
						anchor_frame,
						"TOPLEFT",
						(raidIndex - 1) * ((perAltX - 10) / 8) + 10,
						-(i - 1) * font_height - 3
					);
					raidIcon:SetSize(((perAltX - 10) / 8) - 6, font_height - 6);
					raidIcon:SetDrawLayer("ARTWORK", 7);
					raidIcon:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:AddLine(alt_data.undermine_boss_names[raidIndex])
						GameTooltip:Show()
					end)
					raidIcon:SetScript("OnLeave", function(self)
						GameTooltip:Hide()
					end)
				end
			end
			if type(column.data) == "function" and column.enabled and column.type ~= "raidprogress" then
				local fontPath = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf"
				local current_row = label_columns[i] or self:CreateFontFrame(anchor_frame, perAltX, column.font_height or font_height, anchor_frame, -(i - 1) * font_height, column.data(alt_data), "CENTER", fontPath);
				-- insert it into storage if just created
				if not self.main_frame.alt_columns[alt].label_columns[i] then
					self.main_frame.alt_columns[alt].label_columns[i] = current_row;
				end
				if column.color then
					local color = column.color(alt_data)
					current_row:GetFontString():SetTextColor(color.r, color.g, color.b, 1);
				end
				current_row:SetText(column.data(alt_data))
				if column.font then
					current_row:GetFontString():SetFont(column.font, ilvlTextSize)
				else
					current_row:GetFontString():SetFont("Interface\\AddOns\\AltismManager\\fonts\\expressway.otf", 14)
				end
				if column.justify then
					current_row:GetFontString():SetJustifyV(column.justify);
				end

				local function tooltipSetup(label, bossesKilled, totalBossData)
					if (bossesKilled and bossesKilled > 0) then
						GameTooltip:AddLine(label)

						for bossIndex, bossKilled in spairs(totalBossData) do
							if bossKilled then
								GameTooltip:AddDoubleLine(alt_data.undermine_boss_names[bossIndex], "Defeated", 1, 1, 1, 1, 0, 0)
							else
								GameTooltip:AddDoubleLine(alt_data.undermine_boss_names[bossIndex], "Available", 1, 1, 1, 0, 1, 0)
							end
						end

						GameTooltip:AddLine(" ")
					end
				end
				
				if column.label == "Undermine" and alt_data.raidsaves then
					current_row:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:AddLine("Undermine Palace Raid Lockouts")
						GameTooltip:AddLine(" ")
						tooltipSetup("Normal", alt_data.undermine_normal, alt_data.raidsaves.undermine_normal_savedata)
						tooltipSetup("Heroic", alt_data.undermine_heroic, alt_data.raidsaves.undermine_heroic_savedata)
						tooltipSetup("Mythic", alt_data.undermine_mythic, alt_data.raidsaves.undermine_mythic_savedata)
						GameTooltip:Show()
					end)
					current_row:SetScript("OnLeave", function(self)
						GameTooltip:Hide()
					end)
				end

				if column.tooltip then
					current_row:SetScript("OnEnter", function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						column.tooltip(alt_data)
						GameTooltip:Show()
					end)
					current_row:SetScript("OnLeave", function(self)
						GameTooltip:Hide()
					end)
				end

				if column.remove_button ~= nil then
					self.main_frame.remove_buttons = self.main_frame.remove_buttons or {}
					local extra = self.main_frame.remove_buttons[alt_data.guid] or column.remove_button(alt_data)
					if self.main_frame.remove_buttons[alt_data.guid] == nil then
						self.main_frame.remove_buttons[alt_data.guid] = extra
					end
					extra:SetParent(current_row)
					extra:SetPoint("TOPRIGHT", current_row, "TOPRIGHT", -18, 2 );
					extra:SetPoint("BOTTOMRIGHT", current_row, "TOPRIGHT", -18, -removeButtonSize + 2);
					extra:SetFrameLevel(current_row:GetFrameLevel() + 1)
					extra:Show();
				end
			end
			if column.enabled then
				i = i + 1
			end
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

	if alt_data.mythicplusvault[1] >= mythTrackKeyVaultThreshold then
			result = "|cFF00FF00" .. tostring(alt_data.mythicplusvault[1]) .. "|r"
	elseif alt_data.mythicplusvault[1] > 0 then
			result = tostring(alt_data.mythicplusvault[1])
	else
		result = result .. "|cFF999999X|r"
	end
	if alt_data.mythicplusvault[2] >= mythTrackKeyVaultThreshold then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.mythicplusvault[2]) .. "|r"
	elseif alt_data.mythicplusvault[2] > 0 then
		result = result .. " / " .. tostring(alt_data.mythicplusvault[2])
	else
		result = result .. " / |cFF999999X|r"
	end
	if alt_data.mythicplusvault[3] >= mythTrackKeyVaultThreshold then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.mythicplusvault[3]) .. "|r"
	elseif alt_data.mythicplusvault[3] > 0 then
		result = result .. " / " .. tostring(alt_data.mythicplusvault[2])
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

	if alt_data.delvevault[1] >= maxLootDelveVaultThreshold then
			result = "|cFF00FF00" .. tostring(alt_data.delvevault[1]) .. "|r"
	elseif alt_data.delvevault[1] > 0 then
			result = tostring(alt_data.delvevault[1])
	else
		result = result .. "|cFF999999X|r"
	end
	if alt_data.delvevault[2] >= maxLootDelveVaultThreshold then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.delvevault[2]) .. "|r"
	elseif alt_data.delvevault[2] > 0 then
		result = result .. " / " .. tostring(alt_data.delvevault[2])
	else
		result = result .. " / |cFF999999X|r"
	end
	if alt_data.delvevault[3] >= maxLootDelveVaultThreshold then
		result = result .. " / |cFF00FF00" .. tostring(alt_data.delvevault[3]) .. "|r"
	elseif alt_data.delvevault[3] > 0 then
		result = result .. " / " .. tostring(alt_data.delvevault[2])
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

	local column_table = {
		name = {
			order = 1,
			label = nameLabel,
			enabled = true,
			data = function(alt_data) return alt_data.name end,
			color = function(alt_data) return RAID_CLASS_COLORS[alt_data.class] end,
		},
		ilevel = {
			order = 2,
			data = function(alt_data) return string.format("%.2f", alt_data.ilevel or 0) end, -- , alt_data.neck_level or 0
			justify = "TOP",
			enabled = true,
			-- font = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf",
			remove_button = function(alt_data) return self:CreateRemoveButton(function() AltismManager:RemoveCharacterByGuid(alt_data.guid) end) end
		},
		gold = {
			order = 3,
			justify = "TOP",
			enabled = AltismManagerDB.showGoldEnabled,
			font = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf",
			data = function(alt_data) return tostring(alt_data.gold or "0") end,
		},
		-- DelveVaultSummaryString
		raidvault = {
			order = 3.5,
			label = "Raid Vault",
			enabled = AltismManagerDB.showRaidVaultEnabled,
			data = function(alt_data) return self:RaidVaultSummaryString(alt_data) end,
		},
		mplusvault = {
			order = 4,
			label = "M+ Vault",
			enabled = AltismManagerDB.showMythicPlusVaultEnabled,
			tooltip = function(alt_data)
				local sorted_history = AltismManager:ProduceRelevantMythics(alt_data.run_history)
				GameTooltip:AddLine("Mythic+ Vault Progress")
				for i, run in ipairs(sorted_history) do
					GameTooltip:AddDoubleLine((dungeons[run.mapChallengeModeID] or "Unknown"), "+"..run.level, 1, 1, 1, 0, 1, 0)
				end
				GameTooltip:Show()
			end,
			data = function(alt_data) return self:MythicVaultSummaryString(alt_data) end,
		},
		delvevault = {
			order = 4.1,
			label = "Delve Vault",
			enabled = AltismManagerDB.showDelveVaultEnabled,
			data = function(alt_data) return self:DelveVaultSummaryString(alt_data) end,
		},
		keystone = {
			order = 4.3,
			label = mythicKeystoneLabel,
			enabled = AltismManagerDB.showMythicPlusDataEnabled,
			data = function(alt_data) return (dungeons[alt_data.dungeon] or alt_data.dungeon) .. " +" .. tostring(alt_data.level); end,
		},
		mplus_score = {
			order = 4.4,
			label = mythicPlusLabel,
			enabled = AltismManagerDB.showMythicPlusDataEnabled,
			data = function(alt_data) return tostring(alt_data.mplus_score or "0") end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET = {
			order = 5,
			label = "",
			enabled = AltismManagerDB.showMythicPlusDataEnabled,
			data = function(alt_data) return " " end,
		},
		flightstones = {
			order = 6,
			label = flightstoneLabel,
			enabled = AltismManagerDB.showValorstonesEnabled,
			data = function(alt_data)
				if alt_data.flightstones == 2000 then
					return "|cFFec393c" .. tostring(alt_data.flightstones or "?") .. "|r"
				else
					return tostring(alt_data.flightstones or "?")
				end
			end,
		},
		cofferKeys = {
			order = 6.01,
			label = "Coffer Keys |T4622270:16:16:0:0|t",
			enabled = AltismManagerDB.showCofferKeysEnabled,
			data = function(alt_data)
				return tostring(alt_data.cofferKeysObtained or "?") .. " / 4"
			end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET_3 = {
			order = 6.04,
			label = "",
			enabled = AltismManagerDB.showValorstonesEnabled,
			data = function(alt_data) return " " end,
		},
		UPGRADE_CREST_LABEL = {
			order = 6.05,
			label = "Upgrade Crests",
			enabled = true,
			data = function(alt_data) return " " end,
		},
		whelplings_crest = {
			order = 6.1,
			label = whelplingCrestLabel,
			enabled = true,
			data = function(alt_data)
				if (AltismManagerDB.showRemainingCrestsEnabled) then
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
			order = 6.2,
			label = drakeCrestLabel,
			enabled = true,
			data = function(alt_data)
				if (AltismManagerDB.showRemainingCrestsEnabled) then
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
			order = 6.3,
			label = wyrmCrestLabel,
			enabled = true,
			data = function(alt_data)
				if (AltismManagerDB.showRemainingCrestsEnabled) then
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
			order = 6.4,
			label = aspectCrestLabel,
			enabled = true,
			data = function(alt_data)
				if (AltismManagerDB.showRemainingCrestsEnabled) then
					if (alt_data.aspects_max == alt_data.aspects_earned) then
						return "|cFF39ec3c" .. tostring(alt_data.aspects_crest or "?") .. "|r"
					else 
						return tostring(alt_data.aspects_crest or "?").." |cffcccccc(+"..(alt_data.aspects_max - alt_data.aspects_earned)..")|r"
					end
				end
				return tostring(alt_data.aspects_crest or "?")
			end,
		},
		-- ! Offset
		FAKE_FOR_OFFSET_2 = {
			order = 7,
			label = "",
			enabled = AltismManagerDB.showPVPCurrenciesEnabled,
			data = function(alt_data) return " " end,
		},
		PVP_LABEL = {
			order = 8,
			label = "PvP Currency",
			enabled = AltismManagerDB.showPVPCurrenciesEnabled,
			data = function(alt_data) return " " end,
		},
		honor_points = {
			order = 10,
			label = honorLabel,
			enabled = AltismManagerDB.showPVPCurrenciesEnabled,
			data = function(alt_data) return tostring(alt_data.honor_points or "?") end,
		},
		conquest_pts = {
			order = 11,
			label = conquestLabel,
			enabled = AltismManagerDB.showPVPCurrenciesEnabled,
			data = function(alt_data) return (alt_data.conquest_total and tostring(alt_data.conquest_total) or "0")  end,
		},
		conquest_cap = {
			order = 12,
			label = conquestEarnedLabel,
			enabled = AltismManagerDB.showPVPCurrenciesEnabled,
			data = function(alt_data) return (alt_data.conquest_earned and (tostring(alt_data.conquest_earned) .. " / " .. C_CurrencyInfo.GetCurrencyInfo(Constants.CurrencyConsts.CONQUEST_CURRENCY_ID).maxQuantity) or "?")  end, --   .. "/" .. "500"
		},
		-- ! Offset
		BLANK_LINE = {
			order = 13,
			label = " ",
			enabled = true,
			data = function(alt_data) return " " end,
		},
		worldbosses = {
			order = 13.2,
			label = worldBossLabel,
			enabled = AltismManagerDB.showWorldBossEnabled,
			data = function(alt_data)
				if alt_data.worldboss == nil then return "|cffff0000Available|r" else return "|cff00ff00Defeated|r" end 
			end,
		},
		-- Undermine = {
		-- 	order = 13.4,
		-- 	label = "Undermine",
		-- 	enabled = AltismManagerDB.showUndermineEnabled,
		-- 	data = function(alt_data)return self:MakeRaidString(alt_data.undermine_normal, alt_data.undermine_heroic, alt_data.undermine_mythic) end
		-- },
		mythic = {
			order = 14,
			label = "Mythic",
			type = "raidprogress",
			enabled = AltismManagerDB.showUndermineEnabled,
			data = function(alt_data)
				if (alt_data.raidsaves and alt_data.raidsaves.undermine_mythic_savedata) then
					return alt_data.raidsaves.undermine_mythic_savedata
				end
				return nil
			end
		},
		heroic = {
			order = 14.1,
			label = "Heroic",
			type = "raidprogress",
			enabled = AltismManagerDB.showUndermineEnabled,
			data = function(alt_data)
				if (alt_data.raidsaves and alt_data.raidsaves.undermine_heroic_savedata) then
					return alt_data.raidsaves.undermine_heroic_savedata
				end
				return nil
			end
		},
		normal = {
			order = 14.2,
			label = "Normal",
			type = "raidprogress",
			enabled = AltismManagerDB.showUndermineEnabled,
			data = function(alt_data)
				if (alt_data.raidsaves and alt_data.raidsaves.undermine_normal_savedata) then
					return alt_data.raidsaves.undermine_normal_savedata
				end
				return nil
			end
		},
	}
	self.columns_table = column_table;

	-- create labels and unrolls
	local font_height = 20;
	local label_column = self.main_frame.label_column or CreateFrame("Button", nil, self.main_frame);
	if not self.main_frame.label_column then self.main_frame.label_column = label_column; end
	label_column:SetSize(perAltX, self:CalculateYSize());
	label_column:SetPoint("TOPLEFT", self.main_frame, "TOPLEFT", 4, -1);

	local i = 1;
	for row_iden, row in spairs(self.columns_table, function(t, a, b) return t[a].order < t[b].order end) do
		if row.label and row.enabled then
			local fontPath = "Interface\\AddOns\\AltismManager\\fonts\\expressway.otf"
			local label_row = self:CreateFontFrame(self.main_frame, perAltX, font_height, label_column, -(i-1)*font_height, row.label~="" and row.label or " ", "RIGHT", fontPath);
			self.main_frame.lowest_point = -(i-1)*font_height;
		end
		-- if row.data == "unroll" then
		-- 	-- create a button that will unroll it
		-- 	local unroll_button = CreateFrame("Button", "UnrollButton", self.main_frame, "UIPanelButtonTemplate");
		-- 	unroll_button:SetText(row.name);
		-- 	--unroll_button:SetFrameStrata("HIGH");
		-- 	unroll_button:SetFrameLevel(self.main_frame:GetFrameLevel() + 2)
		-- 	unroll_button:SetSize(unroll_button:GetTextWidth() + 20, 25);
		-- 	unroll_button:SetPoint("BOTTOMRIGHT", self.main_frame, "TOPLEFT", 4 + perAltX, -(i-1)*font_height-10);
		-- 	unroll_button:SetScript("OnClick", function() row.unroll_function(unroll_button, row.rows) end);
		-- 	self.main_frame.lowest_point = -(i-1)*font_height-10;
		-- end
		if row.enabled then
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
	self:StoreData(self:CollectData())
	self:UpdateStrings();
end

function AltismManager:CreateRemoveButton(func)
	local frame = CreateFrame("Button", nil, nil)
	frame:ClearAllPoints()
	frame:SetScript("OnClick", function() func() end);
	self:MakeRemoveTexture(frame)
	frame:SetWidth(removeButtonSize)
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



--------------------------------------------------
-- Options panel (shamelessly yoinked from idTip)
--------------------------------------------------
local panel = CreateFrame("Frame")
panel.name = addonName
panel:Hide()

panel:SetScript("OnShow", function()
  local function createCheckbox(label, key)
    local checkBox = CreateFrame("CheckButton", addonName .. "Check" .. label, panel, "InterfaceOptionsCheckButtonTemplate")
    checkBox:SetChecked(AltismManagerDB[key])
    checkBox:HookScript("OnClick", function(self)
      local checked = self:GetChecked()
      AltismManagerDB[key] = checked
    end)
    checkBox.Text:SetText(label)
    return checkBox
  end

  local title = panel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(addonName)

	local subtitle = panel:CreateFontString("ARTWORK", nil, "GameFontNormalSmall")
  subtitle:SetPoint("TOPRIGHT", -16, -16)
  subtitle:SetText("Any changes will require a UI reload (/reload) to take effect.")

  local index = 0
  local rowHeight = 24
  local columnWidth = 150
  local rowNum = 10

	local kinds = {
		showGold = "Show Gold",
		showMythicPlusData = "Show Mythic+ Data",
		showValorstones = "Show Valorstones",
		showPVPCurrencies = "Show PvP Currencies",
		showWorldBoss = "Show World Bosses",
		showUndermine = "Show Liberation of Undermine",
		showRaidVault = "Show Raid Vault",
		showMythicPlusVault = "Show Mythic+ Vault",
		showDelveVault = "Show Delve Vault",
		showRemainingCrests = "Show remaining crests to be earned up to cap",
		showCofferKeys = "Show Coffer Keys",
	}
  local keys = {
		"showGold",
		"showRaidVault",
		"showMythicPlusVault",
		"showDelveVault",
		"showMythicPlusData",
		"showValorstones",
		"showCofferKeys",
		"showRemainingCrests",
		"showPVPCurrencies",
		"showWorldBoss",
		"showUndermine",
	}
	if #keys ~= #kinds then
		print("[Alt Manager]: Config key lengths do not match. There might be a missing config value in settings.")
	end
  -- for key in pairs(kinds) do table.insert(keys, key) end
  -- table.sort(keys)

  for _, key in pairs(keys) do
    local checkBox = createCheckbox(kinds[key], key.."Enabled")
    local columnIndex = math.floor(index / rowNum)
    local offsetRight = columnIndex * columnWidth
    local offsetUp = -(index * rowHeight) + (rowHeight * rowNum  * columnIndex) - 16
    checkBox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", offsetRight, offsetUp)
    index = index + 1
  end

  panel:SetScript("OnShow", nil)
end)

local categoryId = nil
if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
  local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  categoryId = category.ID
  Settings.RegisterAddOnCategory(category);
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
		Settings.OpenToCategory(categoryId)
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
