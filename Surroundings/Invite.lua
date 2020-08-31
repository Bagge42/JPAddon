JP_Assist_List = {}

local Jp = _G.Jp
local Invite = {}
local GuildRosterHandler = Jp.GuildRosterHandler
local FrameHandler = Jp.FrameHandler
local BrowserSelection = Jp.BrowserSelection
local Utils = Jp.Utils
local Settings = Jp.Settings
Jp.Invite = Invite

local RaidRoster = {}
local MaximumAssistsShown = 11

local function shouldGiveAssist(player, rank)
    local isOfficer = GuildRosterHandler:isOfficer(player)
    local officersShouldHaveAssist = Settings:getSetting(OFFICER_ASSIST_BOOLEAN_SETTING)
    local isNotAssistAlready = (rank == 0)
    local isOnAssistList = JP_Assist_List[player] ~= nil

    return (isOfficer and officersShouldHaveAssist or isOnAssistList) and isNotAssistAlready
end

local function addRoles(player, rank, role)
    if not UnitIsGroupLeader("player") then
        return
    end

    if shouldGiveAssist(player, rank) then
        PromoteToAssistant(player)
    end
    --    local macroBtn = CreateFrame("Button", "myMacroButton", JP_Management, "SecureActionButtonTemplate")
    --    macroBtn:SetAttribute("type1", "macro") -- left click causes macro
    --    macroBtn:SetAttribute("macrotext1", "/maintank femtofire\n/maintank Støvbiks") -- text for macro on left click
    --    macroBtn:SetPoint("Center")
    --    macroBtn:SetSize(50,50)
    --    macroBtn:Show()
end

local function updateRaidRoster()
    local membersInRaid = GetNumGroupMembers()
    for member = 1, membersInRaid do
        local name, rank, _, _, class, _, _, _, _, role = GetRaidRosterInfo(member)
        if name then
            RaidRoster[name] = class
            addRoles(name, rank, role)
        end
    end
end

local function clearAssistEntries()
    for member = 1, MaximumAssistsShown, 1 do
        local entry = getglobal("JP_InviteFrameAssistTabListEntry" .. member)
        getglobal(entry:GetName() .. PLAYER):SetText("")
        entry:Hide()
    end
end

local function updateAssistEntries()
    clearAssistEntries()
    local sortedEntries = Utils:getSortedTableWhereNameKeyClassValue(JP_Assist_List)
    for memberIndex = 1, #sortedEntries, 1 do
        local entry = getglobal("JP_InviteFrameAssistTabListEntry" .. memberIndex)
        entry:Show()
        getglobal(entry:GetName() .. BACKGROUND):Hide()
        local fontString = getglobal(entry:GetName() .. PLAYER)
        fontString:SetText(sortedEntries[memberIndex])
        Utils:setClassColor(fontString, JP_Assist_List[sortedEntries[memberIndex]])
    end
end

function Invite:onLoad()
    if Utils:selfIsInRaid() then
        updateRaidRoster()
    end
    FrameHandler:createInviteTabButtons()
    FrameHandler:setOnClick("Assist", updateAssistEntries)

    local autoInvSetting = CreateFrame("Frame", "$parentAutoInvSetting", JP_InviteFrameInviteTab, "JP_SettingEntry")
    autoInvSetting:SetPoint("TOP")
    autoInvSetting.text = autoInvSetting:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    autoInvSetting.text:SetPoint("LEFT", 5, 0)
    autoInvSetting.text:SetText(AUTO_INV_SETTING)
    autoInvSetting.checkButton = CreateFrame("CheckButton", "$parentCheckButton", JP_InviteFrameInviteTabAutoInvSetting, "JP_SettingCheckButton")
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
    local lowerCase = string.lower(text)
    return (lowerCase == "inv") or (text == "invite") or (text == "invit") or (text == "invi")
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

local function leaderTextIsValid(text)
    local lowerCase = string.lower(text)
    return (lowerCase == "leader") or (text == "lead")
end

local function shouldPassLeader(text, sender)
    return leaderTextIsValid(text) and GuildRosterHandler:isOfficer(sender)
end

local function masterLooterTextIsValid(masterLooterText)
    local lowerCase = string.lower(masterLooterText)
    return (lowerCase == "ml") or (lowerCase == "masterloot") or (lowerCase == "masterlooter")
end

local function shouldPromoteMasterLooter(masterLooterText, sender)
    return masterLooterTextIsValid(masterLooterText) and GuildRosterHandler:isOfficer(sender)
end

local function uppercaseFirstLetter(text)
    return text:gsub("^%l", string.upper)
end

local function promoteToMasterLooter(playerGiven, sender)
    playerGiven = uppercaseFirstLetter(playerGiven)
    if (playerGiven ~= nil) and givenPlayerIsInMyRaid(playerGiven) then
        SetLootMethod("master", playerGiven)
    else
        SetLootMethod("master", sender)
    end
end

local function splitStringBySpace(text)
    local count = 1
    local first
    local second
    for match in string.gmatch(text, "%S+") do
        if (count == 1) then
            first = match
            count = count + 1
        else
            second = match
        end
    end
    return first, second
end

local function handleWhisper(text, sender)
    if shouldInviteToRaid(text, sender) then
        if shouldConvertToRaid() then
            ConvertToRaid()
        end
        InviteUnit(sender)
    elseif shouldPassLeader(text, sender) then
        PromoteToLeader(sender)
    else
        local masterLooterText, playerGiven = splitStringBySpace(text)
        if shouldPromoteMasterLooter(masterLooterText, sender) then
            promoteToMasterLooter(playerGiven, sender)
        end
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

function Invite:createAssistEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", JP_InviteFrameAssistTabList, "JP_InviteListEntry")
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT")
    for entryNr = 2, MaximumAssistsShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, JP_InviteFrameAssistTabList, "JP_InviteListEntry")
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

function Invite:onListEntryClick(id)
    local player = getglobal("JP_InviteFrameAssistTabListEntry" .. id .. PLAYER):GetText()
    JP_Assist_List[player] = nil
    updateAssistEntries()
end

function Invite:assistButtonClick()
    local selectedPlayer = BrowserSelection:getSelectedPlayer()
    local playerClass = GuildRosterHandler:getPlayerClass(selectedPlayer)
    JP_Assist_List[selectedPlayer] = playerClass
end

function Invite:mainTankButtonClick()
end

function Invite:loadTables(_, addonName)
    if addonName == "jpdkp" then
        updateAssistEntries()
    end
end