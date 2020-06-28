JP_Current_Settings = {}
local Jp = _G.Jp
local Utils = Jp.Utils
local Settings = {}
Jp.Settings = Settings

local ClassesWaitingForSettings = {}
local ClassesListeningToChanges = {}
local SettingsTable = {}
local SettingsLoaded = false
local SettingTexts = { ONY_NAME, MC_NAME, BWL_NAME, AQ_NAME, NAXX_NAME, DECAY_SETTING_NAME }
local DefaultSettings = { [SettingTexts[1]] = 12, [SettingTexts[2]] = 33, [SettingTexts[3]] = 27, [SettingTexts[4]] = 0, [SettingTexts[5]] = 0, [SettingTexts[6]] = 20 }

function Settings:onSettingsClick()
    local isOfficer = Utils:isOfficer()
    local settings = getglobal("JP_SettingsFrame")
    local management = getglobal("JP_Management")

    if not settings:IsVisible() then
        settings:Show()
        management:Hide()
        --        if not isOfficer then
        --            getglobal("JP_OuterFrame"):SetSize(651, 300)
        --            getglobal("JP_OuterFrameTitleFrame"):SetSize(651, 24)
        --            getglobal("JP_BenchFrame"):SetPoint("TOPLEFT", "JP_SettingsFrame", "TOPRIGHT")
        --        end
    else
        settings:Hide()
        if isOfficer then
            management:Show()
            --        else
            --            getglobal("JP_OuterFrame"):SetSize(368, 300)
            --            getglobal("JP_OuterFrameTitleFrame"):SetSize(368, 24)
            --            getglobal("JP_BenchFrame"):SetPoint("TOPLEFT", "JP_OuterFrameList", "TOPRIGHT", 0, -4)
        end
    end
end

local function createEditBox(settingFrame, id)
    settingFrame.value = CreateFrame("EditBox", "$parentEditBox", settingFrame, "JP_SettingEditBox")
    settingFrame.value:SetID(id)
    settingFrame.value:SetNumeric()
    settingFrame.value:SetJustifyH("RIGHT")
    settingFrame.value:SetTextInsets(0, 5, 0, 0)
    settingFrame.value:SetPoint("RIGHT")
    settingFrame.value:SetAutoFocus(false)
    settingFrame.value:SetFontObject("GameFontNormal")
end

local function sendSettingChange(settingName, newValue)
    for _, classListening in pairs(ClassesListeningToChanges) do
        classListening:settingChanged(settingName, newValue)
    end
end

local function insertSetting(settingName, settingValue)
    JP_Current_Settings[settingName] = settingValue
    SettingsTable[settingName] = settingValue
    sendSettingChange(settingName, settingValue)
end

local function toggleBooleanSetting(settingName)
    if SettingsTable[settingName] then
        insertSetting(settingName, false)
    else
        insertSetting(settingName, true)
    end
end

function Settings:onLoad()
    local initialSetting = CreateFrame("Frame", "$parentSetting1", JP_SettingsFrame, "JP_SettingEntry")
    initialSetting:SetPoint("TOPLEFT", 0, -24)
    initialSetting.text = initialSetting:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    initialSetting.text:SetPoint("LEFT", 5, 0)
    initialSetting.text:SetText(SettingTexts[1])
    createEditBox(initialSetting, 1)
    for settingCount = 2, 6, 1 do
        local followingSettings = CreateFrame("Frame", "$parentSetting" .. settingCount, JP_SettingsFrame, "JP_SettingEntry")
        followingSettings:SetPoint("TOP", "$parentSetting" .. (settingCount - 1), "BOTTOM")
        followingSettings.text = followingSettings:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        followingSettings.text:SetPoint("LEFT", 5, 0)
        followingSettings.text:SetText(SettingTexts[settingCount])
        createEditBox(followingSettings, settingCount)
    end

    local settingInfo = CreateFrame("Frame", "$parentSettingInfo", JP_SettingsFrame, "JP_SettingEntry")
    settingInfo:SetPoint("BOTTOMLEFT")
    settingInfo.text = settingInfo:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    settingInfo.text:SetPoint("LEFT", 5, 0)
    settingInfo.text:SetText(SETTING_INFO)

    local biddersOnlySetting = CreateFrame("Frame", "$parentBiddersOnlySetting", JP_SettingsFrame, "JP_SettingEntry")
    biddersOnlySetting:SetPoint("BOTTOM", "$parentSettingInfo", "TOP")
    biddersOnlySetting.text = biddersOnlySetting:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    biddersOnlySetting.text:SetPoint("LEFT", 5, 0)
    biddersOnlySetting.text:SetText(BIDDERS_ONLY_SETTING)
    biddersOnlySetting.checkButton = CreateFrame("CheckButton", "$parentCheckButton", JP_SettingsFrameBiddersOnlySetting, "JP_SettingCheckButton")
    biddersOnlySetting.checkButton:SetPoint("RIGHT")
    biddersOnlySetting.checkButton.tooltip = "A bidding round is started by linking an item in a raid warning. If this checkbox is marked the only people that will be shown in the overview, after the start of a bidding round, is people linking an item in the raid chat. The bidding round lasts until a new round has been started or show none/all is clicked."
    biddersOnlySetting.checkButton:SetScript("OnClick", function()
        toggleBooleanSetting(BIDDERS_ONLY_BOOLEAN_SETTING)
        if SettingsTable[BIDDERS_ONLY_BOOLEAN_SETTING] then
            Jp.DkpBrowser:addBidToOverview()
        else
            Jp.DkpBrowser:removeBidFromOverview()
        end
    end)

    local autoInvSetting = CreateFrame("Frame", "$parentAutoInvSetting", JP_SettingsFrame, "JP_SettingEntry")
    autoInvSetting:SetPoint("BOTTOM", "$parentBiddersOnlySetting", "TOP")
    autoInvSetting.text = autoInvSetting:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    autoInvSetting.text:SetPoint("LEFT", 5, 0)
    autoInvSetting.text:SetText(AUTO_INV_SETTING)
    autoInvSetting.checkButton = CreateFrame("CheckButton", "$parentCheckButton", JP_SettingsFrameAutoInvSetting, "JP_SettingCheckButton")
    autoInvSetting.checkButton:SetPoint("RIGHT")
    autoInvSetting.checkButton.tooltip = "Toggle automatic inviting of guild members. Valid formats: 'Inv', 'inv', 'Invite', 'invite'"
    autoInvSetting.checkButton:SetScript("OnClick", function()
        toggleBooleanSetting(AUTO_INV_BOOLEAN_SETTING)
    end)
end

local function insertInEditBoxAndSettingsTable(settingValue, editBoxId)
    getglobal("JP_SettingsFrameSetting" .. editBoxId .. "EditBox"):SetNumber(settingValue)
    SettingsTable[SettingTexts[editBoxId]] = settingValue
end

local function loadCheckBoxSetting(settingName, checkBoxName)
    SettingsTable[settingName] = JP_Current_Settings[settingName]
    if JP_Current_Settings[settingName] then
        getglobal(checkBoxName):SetChecked(true)
    end
end

local function loadCheckBoxSettings()
    loadCheckBoxSetting(BIDDERS_ONLY_BOOLEAN_SETTING, "JP_SettingsFrameBiddersOnlySettingCheckButton")
    loadCheckBoxSetting(AUTO_INV_BOOLEAN_SETTING, "JP_SettingsFrameAutoInvSettingCheckButton")
end

local function loadSettings()
    for settingsCount = 1, Utils:getTableSize(DefaultSettings), 1 do
        local setting = JP_Current_Settings[SettingTexts[settingsCount]]
        if not setting then
            setting = DefaultSettings[SettingTexts[settingsCount]]
        end
        insertInEditBoxAndSettingsTable(setting, settingsCount)
    end
    loadCheckBoxSettings()
end

local function sendSettings()
    for _ , waitingClass in pairs(ClassesWaitingForSettings) do
        waitingClass:settingsLoaded()
    end
end

function Settings:settingsLoaded(event, ...)
    local addonPrefix = select(1, ...)
    if (addonPrefix == ADDON_PREFIX) and (event == "ADDON_LOADED") then
        loadSettings()
        sendSettings()
        SettingsLoaded = true
    end
end

function Settings:saveSetting(id)
    local settingValue = getglobal("JP_SettingsFrameSetting" .. id .. "EditBox"):GetNumber()
    local settingName = SettingTexts[id]
    insertSetting(settingName, settingValue)
end

function Settings:getSetting(settingName)
    return SettingsTable[settingName]
end

function Settings:subscribeToSettings(class)
    if SettingsLoaded then
        class:settingsLoaded()
    else
        table.insert(ClassesWaitingForSettings, class)
    end
end

function Settings:subscribeToSettingChanges(class)
    table.insert(ClassesListeningToChanges, class)
end