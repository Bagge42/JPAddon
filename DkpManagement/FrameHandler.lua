local Jp = _G.Jp
local FrameHandler = {}
local Utils = Jp.Utils
Jp.FrameHandler = FrameHandler

local function hideAll()
    getglobal("JP_SettingsFrame"):Hide()
    getglobal("JP_Management"):Hide()
    getglobal("JP_InviteFrame"):Hide()
end

local function showDefaultFrame()
    if Utils:isOfficer() then
        getglobal("JP_Management"):Show()
    end
end

local function toggleCenterFrame(frameName)
    local settings = getglobal(frameName)
    local settingsWasVisible = settings:IsVisible()
    hideAll()

    if not settingsWasVisible then
        settings:Show()
    else
        showDefaultFrame()
    end
end

local function settingsClicked()
    toggleCenterFrame("JP_SettingsFrame")
end

local function inviteClicked()
    toggleCenterFrame("JP_InviteFrame")
end

function FrameHandler:onClose(frameName)
    if (frameName == "JP_SettingsFrameTitleFrameClose") then
        settingsClicked()
    elseif (frameName == "JP_InviteFrameTitleFrameClose") then
        inviteClicked()
    end
end

function FrameHandler:settingButtonClicked()
    settingsClicked()
end

function FrameHandler:inviteButtonClicked()
    inviteClicked()
end