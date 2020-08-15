local Jp = _G.Jp
local Invite = {}
local GuildRosterHandler = Jp.GuildRosterHandler
local Utils = Jp.Utils
local Settings = Jp.Settings
Jp.Invite = Invite

local RaidRoster = {}

local function updateRaidRoster()
    local membersInRaid = GetNumGroupMembers()
    for member = 1, membersInRaid do
        local name, _, _, _, class = GetRaidRosterInfo(member)
        RaidRoster[name] = class
    end
end

function Invite:onLoad()
    getglobal("JP_InviteFrameTitleFrameName"):SetText(INVITE_FRAME_TITLE)
    if Utils:selfIsInRaid() then
        updateRaidRoster()
    end

    local autoInvSetting = CreateFrame("Frame", "$parentAutoInvSetting", JP_InviteFrame, "JP_SettingEntry")
    autoInvSetting:SetPoint("TOP", "$parentTitleFrame", "BOTTOM")
    autoInvSetting.text = autoInvSetting:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    autoInvSetting.text:SetPoint("LEFT", 5, 0)
    autoInvSetting.text:SetText(AUTO_INV_SETTING)
    autoInvSetting.checkButton = CreateFrame("CheckButton", "$parentCheckButton", JP_InviteFrameAutoInvSetting, "JP_SettingCheckButton")
    autoInvSetting.checkButton:SetPoint("RIGHT")
    autoInvSetting.checkButton.tooltip = "Toggle automatic inviting of guild members. Valid formats: 'Inv', 'inv', 'Invite', 'invite, INV, INVITE'"
    autoInvSetting.checkButton:SetScript("OnClick", function()
        Settings:toggleBooleanSetting(AUTO_INV_BOOLEAN_SETTING)
    end)
end

local function givenPlayerIsInMyRaid(player)
    return RaidRoster[player] ~= nil
end

local function isValidInvFormat(text)
    return (text == "inv") or (text == "Inv") or (text == "invite") or (text == "Invite") or (text == "INVITE") or (text == "INV")
end

local function shouldInviteToRaid(text, sender)
    return isValidInvFormat(text) and Settings:getSetting(AUTO_INV_BOOLEAN_SETTING) and GuildRosterHandler:isInGuild(sender) and not givenPlayerIsInMyRaid(sender)
end

function Invite:massInvite()
    local raiders = GuildRosterHandler:getRaiders()
    for _, name in pairs(raiders) do
        if IsInGroup() and not Utils:selfIsInRaid() then
            ConvertToRaid()
        end
        if not isBenched(name) and not givenPlayerIsInMyRaid(name) then
            InviteUnit(name)
        end
    end
end

local function shouldConvertToRaid()
    return (GetNumGroupMembers() == 5) and not Utils:selfIsInRaid() and UnitIsGroupLeader("player")
end

local function handleWhisper(text, sender)
    if shouldInviteToRaid(text, sender) then
        if shouldConvertToRaid() then
            ConvertToRaid()
        end
        InviteUnit(sender)
    end
end

function Invite:onEvent(event, ...)
    local text = select(1, ...)
    if (event == "CHAT_MSG_WHISPER") then
        local sender = Utils:removeRealmName(select(2, ...))
        handleWhisper(text, sender)
    elseif (event == "GROUP_ROSTER_UPDATE") then
        updateRaidRoster()
    end
end