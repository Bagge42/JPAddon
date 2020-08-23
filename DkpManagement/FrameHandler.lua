local Jp = _G.Jp
local FrameHandler = {}
local Utils = Jp.Utils
Jp.FrameHandler = FrameHandler

local function hideAll()
    getglobal("JP_SettingsFrame"):Hide()
    getglobal("JP_Management"):Hide()
    getglobal("JP_InviteFrame"):Hide()
    getglobal("JP_ConsFrame"):Hide()
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

local function consClicked()
    toggleCenterFrame("JP_ConsFrame")
end

function FrameHandler:onClose(frameName)
    if (frameName == "JP_SettingsFrameTitleFrameClose") then
        settingsClicked()
    elseif (frameName == "JP_InviteFrameTitleFrameClose") then
        inviteClicked()
    elseif (frameName == "JP_ConsFrameTitleFrameClose") then
        consClicked()
    end
end

function FrameHandler:settingButtonClicked()
    settingsClicked()
end

function FrameHandler:inviteButtonClicked()
    inviteClicked()
end

function FrameHandler:consButtonClicked()
    consClicked()
end

function FrameHandler:setOnClick(tab, method)
    getglobal("JP_InviteFrameTitleFrame" .. tab .. "TabButton"):HookScript("OnClick", method)
    getglobal("JP_OuterFrameTitleFrameInvite"):HookScript("OnClick", method)
end

local function hideAllInviteTabs()
    getglobal("JP_InviteFrameInviteTab"):Hide()
    getglobal("JP_InviteFrameTanksTab"):Hide()
    getglobal("JP_InviteFrameAssistTab"):Hide()
    getglobal("JP_InviteFrameImportTab"):Hide()
end

local function showTab(tab)
    hideAllInviteTabs()
    getglobal(tab):Show()
end

function FrameHandler:createInviteTabs()
    local invitingButton = CreateFrame("Button", "$parentInviteTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    invitingButton:SetPoint("LEFT")
    invitingButton:SetSize(56, 24)
    invitingButton:SetText("Inviting")
    invitingButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameInviteTab")
    end)

    local tankButton = CreateFrame("Button", "$parentTankTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    tankButton:SetPoint("LEFT", JP_InviteFrameTitleFrameInviteTabButton, "RIGHT")
    tankButton:SetSize(56, 24)
    tankButton:SetText("Tanks")
    tankButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameTanksTab")
    end)

    local assistButton = CreateFrame("Button", "$parentAssistTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    assistButton:SetPoint("LEFT", JP_InviteFrameTitleFrameTankTabButton, "RIGHT")
    assistButton:SetSize(56, 24)
    assistButton:SetText("Assists")
    assistButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameAssistTab")
    end)

    local importButton = CreateFrame("Button", "$parentImportTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    importButton:SetPoint("LEFT", JP_InviteFrameTitleFrameAssistTabButton, "RIGHT")
    importButton:SetSize(56, 24)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameImportTab")
    end)
end