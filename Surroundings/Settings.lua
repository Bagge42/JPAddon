JP_Current_Settings = {}
_G.JP_Settings = {}
local Settings = _G.JP_Settings
local Utils = _G.JP_Utils

local ClassesWaitingForSettings = {}
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
    for waitingClass, _ in pairs(ClassesWaitingForSettings) do
        getglobal(waitingClass):settingsLoaded()
    end
end

function Settings:settingsLoaded(event, ...)
    local addonPrefix = select(1, ...)
    if (addonPrefix == ADDON_PREFIX) and (event == "ADDON_LOADED") then
        insertSettings()
    end
    sendSettings()
    SettingsLoaded = true
end

function Settings:saveSetting(id)
    local settingValue = getglobal("JP_SettingsFrameSetting" .. id .. "EditBox"):GetNumber()
    JP_Current_Settings[SettingTexts[id]] = settingValue
    EditBoxTable[SettingTexts[id]] = settingValue
end

function Settings:getSetting(settingName)
    return EditBoxTable[settingName]
end

function Settings:subscribeToSettings(nameOfClass)
    if SettingsLoaded then
        getglobal(nameOfClass):settingsLoaded()
    else
        ClassesWaitingForSettings[nameOfClass] = true
    end
end