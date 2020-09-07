JP_Current_Settings = {}

local Jp = _G.Jp
local Localization = Jp.Localization
local Utils = Jp.Utils
local Settings = {}
Jp.Settings = Settings

local ClassesWaitingForSettings = {}
local ClassesListeningToChanges = {}
local SettingsTable = {}
local SettingsLoaded = false
local SettingTexts = { Localization.ONY_NAME, Localization.MC_NAME, Localization.BWL_NAME, Localization.AQ_NAME, Localization.NAXX_NAME, Localization.DECAY_SETTING_NAME }
local DefaultSettings = { [SettingTexts[1]] = 12, [SettingTexts[2]] = 33, [SettingTexts[3]] = 27, [SettingTexts[4]] = 0, [SettingTexts[5]] = 0, [SettingTexts[6]] = 20}

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

function Settings:toggleBooleanSetting(settingName)
    if SettingsTable[settingName] then
        insertSetting(settingName, false)
    else
        insertSetting(settingName, true)
    end
end

function Settings:onLoad()
    getglobal("JP_SettingsFrameTitleFrameText"):SetText(Localization.SETTINGS_FRAME_TITLE)

    local settingInfo = CreateFrame("Frame", "$parentSettingInfo", JP_SettingsFrame, "JP_SettingEntry")
    settingInfo:SetPoint("TOPLEFT", 0, -24)
    settingInfo.text = settingInfo:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    settingInfo.text:SetPoint("LEFT", 5, 0)
    settingInfo.text:SetText(Localization.SETTING_INFO)

    local initialSetting = CreateFrame("Frame", "$parentSetting1", JP_SettingsFrame, "JP_SettingEntry")
    initialSetting:SetPoint("TOP", "$parentSettingInfo", "BOTTOM")
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

    local biddersOnlySetting = CreateFrame("Frame", "$parentBiddersOnlySetting", JP_SettingsFrame, "JP_SettingEntry")
    biddersOnlySetting:SetPoint("BOTTOMLEFT")
    biddersOnlySetting.text = biddersOnlySetting:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    biddersOnlySetting.text:SetPoint("LEFT", 5, 0)
    biddersOnlySetting.text:SetText(Localization.BIDDERS_ONLY_SETTING)
    biddersOnlySetting.checkButton = CreateFrame("CheckButton", "$parentCheckButton", JP_SettingsFrameBiddersOnlySetting, "JP_SettingCheckButton")
    biddersOnlySetting.checkButton:SetPoint("RIGHT")
    biddersOnlySetting.checkButton.tooltip = "A bidding round is started by linking an item in a raid warning. If this checkbox is marked the only people that will be shown in the overview, after the start of a bidding round, is people linking an item in the raid chat and people whispering a bid. The bidding round lasts until a new round has been started or show none/all is clicked."
    biddersOnlySetting.checkButton:SetScript("OnClick", function()
        Settings:toggleBooleanSetting(Localization.BIDDERS_ONLY_BOOLEAN_SETTING)
        if SettingsTable[Localization.BIDDERS_ONLY_BOOLEAN_SETTING] then
            Jp.DkpBrowser:addBidToOverview()
        else
            Jp.DkpBrowser:removeBidFromOverview()
        end
    end)

    local linkPrioSetting = CreateFrame("Frame", "$parentLinkPrioSetting", JP_SettingsFrame, "JP_SettingEntry")
    linkPrioSetting:SetPoint("BOTTOM", "$parentBiddersOnlySetting", "TOP")
    linkPrioSetting.text = linkPrioSetting:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    linkPrioSetting.text:SetPoint("LEFT", 5, 0)
    linkPrioSetting.text:SetText(Localization.LINK_PRIO_SETTING_TEXT)
    linkPrioSetting.checkButton = CreateFrame("CheckButton", "$parentCheckButton", JP_SettingsFrameLinkPrioSetting, "JP_SettingCheckButton")
    linkPrioSetting.checkButton:SetPoint("RIGHT")
    linkPrioSetting.checkButton.tooltip = "Toggle to link priorities in the raid chat when an item is linked in a raid warning, if such a priority exist"
    linkPrioSetting.checkButton:SetScript("OnClick", function()
        Settings:toggleBooleanSetting(Localization.LINK_PRIO_BOOLEAN_SETTING)
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
    loadCheckBoxSetting(Localization.BIDDERS_ONLY_BOOLEAN_SETTING, "JP_SettingsFrameBiddersOnlySettingCheckButton")
    loadCheckBoxSetting(Localization.AUTO_INV_BOOLEAN_SETTING, "JP_InviteFrameInviteTabAutoInvSettingCheckButton")
    loadCheckBoxSetting(Localization.LINK_PRIO_BOOLEAN_SETTING, "JP_SettingsFrameLinkPrioSettingCheckButton")
    loadCheckBoxSetting(Localization.OFFICER_ASSIST_BOOLEAN_SETTING, "JP_InviteFrameAssistTabOfficerAssistSettingCheckButton")
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
    if (addonPrefix == Localization.ADDON_PREFIX) and (event == "ADDON_LOADED") then
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