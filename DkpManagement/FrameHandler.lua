local Jp = _G.Jp
local FrameHandler = {}
local Utils = Jp.Utils
Jp.FrameHandler = FrameHandler

local function hideAll()
    getglobal("JP_SettingsFrame"):Hide()
    getglobal("JP_Management"):Hide()
    getglobal("JP_InviteFrame"):Hide()
    getglobal("JP_TrackingFrame"):Hide()
end

local function showDefaultFrame()
    if Utils:isOfficer() then
        getglobal("JP_Management"):Show()
    end
end

local function toggleCenterFrame(frameName)
    local frame = getglobal(frameName)
    local frameWasVisible = frame:IsVisible()
    hideAll()

    if not frameWasVisible then
        frame:Show()
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
    toggleCenterFrame("JP_TrackingFrame")
end

function FrameHandler:onClose(frameName)
    if (frameName == "JP_SettingsFrameTitleFrameClose") then
        settingsClicked()
    elseif (frameName == "JP_InviteFrameTitleFrameClose") then
        inviteClicked()
    elseif (frameName == "JP_TrackingFrameTitleFrameClose") then
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

local function hideAllTrackingTabs()
    getglobal("JP_TrackingFrameTrackingTab"):Hide()
    getglobal("JP_TrackingFrameBuffTab"):Hide()
    getglobal("JP_TrackingFrameConsTab"):Hide()
end

local function showTab(tab, parent)
    if (parent == "invite") then
        hideAllInviteTabs()
    else
        hideAllTrackingTabs()
    end
    getglobal(tab):Show()
end

function FrameHandler:createInviteTabButtons()
    local invitingButton = CreateFrame("Button", "$parentInviteTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    invitingButton:SetPoint("LEFT")
    invitingButton:SetSize(56, 24)
    invitingButton:SetText("Inviting")
    invitingButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameInviteTab", "invite")
    end)

    local tankButton = CreateFrame("Button", "$parentTankTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    tankButton:SetPoint("LEFT", JP_InviteFrameTitleFrameInviteTabButton, "RIGHT")
    tankButton:SetSize(56, 24)
    tankButton:SetText("Tanks")
    tankButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameTanksTab", "invite")
    end)

    local assistButton = CreateFrame("Button", "$parentAssistTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    assistButton:SetPoint("LEFT", JP_InviteFrameTitleFrameTankTabButton, "RIGHT")
    assistButton:SetSize(56, 24)
    assistButton:SetText("Assists")
    assistButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameAssistTab", "invite")
    end)

    local importButton = CreateFrame("Button", "$parentImportTabButton", JP_InviteFrameTitleFrame, "JP_AllClassToggle")
    importButton:SetPoint("LEFT", JP_InviteFrameTitleFrameAssistTabButton, "RIGHT")
    importButton:SetSize(56, 24)
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        showTab("JP_InviteFrameImportTab", "invite")
    end)
end

function FrameHandler:createTrackingTabButtons()
    local trackingButton = CreateFrame("Button", "$parentTrackingTabButton", JP_TrackingFrameTitleFrame, "JP_AllClassToggle")
    trackingButton:SetPoint("LEFT")
    trackingButton:SetSize(66, 24)
    trackingButton:SetText("Checks")
    trackingButton:SetScript("OnClick", function()
        showTab("JP_TrackingFrameTrackingTab", "tracking")
    end)

    local consButton = CreateFrame("Button", "$parentConsTabButton", JP_TrackingFrameTitleFrame, "JP_AllClassToggle")
    consButton:SetPoint("LEFT", JP_TrackingFrameTitleFrameTrackingTabButton, "RIGHT")
    consButton:SetSize(76, 24)
    consButton:SetText("Consumes")
    consButton:SetScript("OnClick", function()
        showTab("JP_TrackingFrameConsTab", "tracking")
    end)

    local buffButton = CreateFrame("Button", "$parentBuffTabButton", JP_TrackingFrameTitleFrame, "JP_AllClassToggle")
    buffButton:SetPoint("LEFT", JP_TrackingFrameTitleFrameConsTabButton, "RIGHT")
    buffButton:SetSize(50, 24)
    buffButton:SetText("Buffs")
    buffButton:SetScript("OnClick", function()
        showTab("JP_TrackingFrameBuffTab", "tracking")
    end)

    local dmtButton = CreateFrame("Button", "$parentDmtTabButton", JP_TrackingFrameTitleFrame, "JP_AllClassToggle")
    dmtButton:SetPoint("LEFT", JP_TrackingFrameTitleFrameBuffTabButton, "RIGHT")
    dmtButton:SetSize(50, 24)
    dmtButton:SetText("DMT")
    dmtButton:SetScript("OnClick", function()
        showTab("JP_TrackingFrameDmtTab", "tracking")
    end)
end

function FrameHandler:setOnClickTrackingFrameButtons(tab, method)
    getglobal("JP_TrackingFrameTitleFrame" .. tab .. "TabButton"):HookScript("OnClick", method)
    getglobal("JP_OuterFrameTitleFrameTracking"):HookScript("OnClick", method)
end