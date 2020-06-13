JP_Current_Settings = {}
local Jp = _G.Jp
local Utils = Jp.Utils
local Settings = {}
Jp.Settings = Settings

local ClassesWaitingForSettings = {}
local ClassesListeningToChanges = {}
local EditBoxTable = {}
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
end

local function insertInEditBoxAndEditBoxTable(settingValue, editBoxId)
    getglobal("JP_SettingsFrameSetting" .. editBoxId .. "EditBox"):SetNumber(settingValue)
    EditBoxTable[SettingTexts[editBoxId]] = settingValue
end

local function insertSettings()
    for settingsCount = 1, Utils:getTableSize(DefaultSettings), 1 do
        local setting = JP_Current_Settings[SettingTexts[settingsCount]]
        if not setting then
            setting = DefaultSettings[SettingTexts[settingsCount]]
        end
        insertInEditBoxAndEditBoxTable(setting, settingsCount)
    end
end

local function sendSettings()
    for _ , waitingClass in pairs(ClassesWaitingForSettings) do
        waitingClass:settingsLoaded()
    end
end

function Settings:settingsLoaded(event, ...)
    local addonPrefix = select(1, ...)
    if (addonPrefix == ADDON_PREFIX) and (event == "ADDON_LOADED") then
        insertSettings()
        sendSettings()
        SettingsLoaded = true
    end
end

local function sendSettingChange(settingName, newValue)
    for classListening, _ in pairs(ClassesListeningToChanges) do
        classListening:settingChanged(settingName, newValue)
    end
end

function Settings:saveSetting(id)
    local settingValue = getglobal("JP_SettingsFrameSetting" .. id .. "EditBox"):GetNumber()
    local settingName = SettingTexts[id]
    JP_Current_Settings[settingName] = settingValue
    EditBoxTable[settingName] = settingValue
    sendSettingChange(settingName, settingValue)
end

function Settings:getSetting(settingName)
    return EditBoxTable[settingName]
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