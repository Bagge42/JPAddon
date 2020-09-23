JP_Assist_List = {}

local Jp = _G.Jp
local Localization = Jp.Localization
local Invite = {}
local GuildRosterHandler = Jp.GuildRosterHandler
local FrameHandler = Jp.FrameHandler
local BrowserSelection = Jp.BrowserSelection
local Utils = Jp.Utils
local Settings = Jp.Settings
Jp.Invite = Invite

local RaidRoster = {}
local MaximumAssistsShown = 11
local MaximumImportsShown = 10
local ImportIndex = 1
local Imports = {}

local function shouldGiveAssist(player, rank)
    local isOfficer = GuildRosterHandler:isOfficer(player)
    local officersShouldHaveAssist = Settings:getSetting(Localization.OFFICER_ASSIST_BOOLEAN_SETTING)
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

local function updateEntries(entries, entryFrameNames, maximumEntriesShown, index)
    local entryCounter = 1
    local sortedEntries = Utils:getTableWithKeysAsValuesSorted(entries)
    for memberIndex = index, #sortedEntries, 1 do
        if entryCounter > maximumEntriesShown then
            return
        end
        local entry = getglobal(entryFrameNames .. entryCounter)
        entry:Show()
        getglobal(entry:GetName() .. Localization.BACKGROUND):Hide()
        local fontString = getglobal(entry:GetName() .. Localization.PLAYER)
        fontString:SetText(sortedEntries[memberIndex])
        Utils:setClassColor(fontString, entries[sortedEntries[memberIndex]])
        entryCounter = entryCounter + 1
    end
end

local function updateAssistEntries()
    local entryFrameName = "JP_InviteFrameAssistTabListEntry"
    Utils:clearEntries(entryFrameName, MaximumAssistsShown, Localization.PLAYER)
    updateEntries(JP_Assist_List, entryFrameName, MaximumAssistsShown, 1)
end

local function updateImportEntries()
    local entryFrameName = "JP_InviteFrameImportTabListEntry"
    Utils:clearEntries(entryFrameName, MaximumImportsShown, Localization.PLAYER)
    updateEntries(Imports, entryFrameName, MaximumImportsShown, ImportIndex)
end


local function removeFromImports(player)
    if (Imports[player] ~= nil) then
        Imports[player] = nil
        updateImportEntries()
    end
end

local function updateRaidRoster()
    RaidRoster = {}
    local membersInRaid = GetNumGroupMembers()
    for member = 1, membersInRaid do
        local name, rank, _, _, class, _, _, _, _, role = GetRaidRosterInfo(member)
        if name then
            RaidRoster[name] = class
            addRoles(name, rank, role)
            removeFromImports(name)
        end
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
    autoInvSetting.text:SetText(Localization.AUTO_INV_SETTING)
    autoInvSetting.checkButton = CreateFrame("CheckButton", "$parentCheckButton", JP_InviteFrameInviteTabAutoInvSetting, "JP_SettingCheckButton")
    autoInvSetting.checkButton:SetPoint("RIGHT")
    autoInvSetting.checkButton.tooltip = "Toggle automatic inviting of guild members. Valid formats: 'Inv', 'inv', 'Invite', 'invite, INV, INVITE'"
    autoInvSetting.checkButton:SetScript("OnClick", function()
        Settings:toggleBooleanSetting(Localization.AUTO_INV_BOOLEAN_SETTING)
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
    return isValidInvFormat(text) and Settings:getSetting(Localization.AUTO_INV_BOOLEAN_SETTING) and GuildRosterHandler:isInGuild(sender) and not givenPlayerIsInMyRaid(sender)
end

local function checkAndInvite(player)
    if IsInGroup() and not Utils:selfIsInRaid() then
        ConvertToRaid()
    end
    if not isBenched(player) and not givenPlayerIsInMyRaid(player) then
        InviteUnit(player)
    end
end

function Invite:massInvite()
    local raiders = GuildRosterHandler:getRaiders()
    for _, name in pairs(raiders) do
        checkAndInvite(name)
    end
end

local function shouldConvertToRaid()
    return (GetNumGroupMembers() == 5) and not Utils:selfIsInRaid() and UnitIsGroupLeader("player")
end

local function leaderTextIsValid(text)
    local lowerCase = string.lower(text)
    return (lowerCase == "leader") or (text == "lead")
end

local function shouldHandLeader(text, sender)
    return leaderTextIsValid(text) and GuildRosterHandler:isOfficer(sender)
end

local function assistTextIsValid(text)
    local lowerCase = string.lower(text)
    return (lowerCase == "assist") or (text == "as")
end

local function shouldHandAssist(text, sender)
    return assistTextIsValid(text) and GuildRosterHandler:isOfficer(sender)
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
    local isInGroup = IsInGroup()
    if shouldInviteToRaid(text, sender) then
        if shouldConvertToRaid() then
            ConvertToRaid()
        end
        InviteUnit(sender)
    elseif isInGroup and shouldHandLeader(text, sender) then
        PromoteToLeader(sender)
    elseif isInGroup and shouldHandAssist(text, sender) then
        PromoteToAssistant(sender)
    elseif isInGroup then
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

function Invite:getMaximumAssistsShown()
    return MaximumAssistsShown
end

function Invite:onAssistEntryClick(id)
    local player = getglobal("JP_InviteFrameAssistTabListEntry" .. id .. Localization.PLAYER):GetText()
    JP_Assist_List[player] = nil
    updateAssistEntries()
end

function Invite:onImportEntryClick(id)
    local player = getglobal("JP_InviteFrameImportTabListEntry" .. id .. Localization.PLAYER):GetText()
    Imports[player] = nil
    updateImportEntries()
end

function Invite:assistButtonClick()
    local selectedPlayer = BrowserSelection:getSelectedPlayer()
    local playerClass = GuildRosterHandler:getPlayerClass(selectedPlayer)
    JP_Assist_List[selectedPlayer] = playerClass
end

function Invite:mainTankButtonClick()
end

function Invite:onAddonLoad(_, addonName)
    if addonName == "jpdkp" then
        updateAssistEntries()
    end
end

local function isNotSelf(name)
    local self = UnitName("player")
    if (name ~= self) then
        return true
    end
    return false
end

function Invite:import()
    Imports = {}
    local editBoxText = getglobal("JP_InviteFrameImportTabFrameEditBox"):GetText()
    for player in string.gmatch(editBoxText, "([^,]*)") do
        local potentialSpacesRemoved = string.gsub(player, "%s+", "")
        local lowerCase = string.lower(potentialSpacesRemoved)
        local firstLetterUpper = uppercaseFirstLetter(lowerCase)
        local class = GuildRosterHandler:getPlayerClass(firstLetterUpper)
        if (class ~= nil) and isNotSelf(firstLetterUpper) then
            Imports[firstLetterUpper] = class
        end
    end
    updateImportEntries()
end

function Invite:inviteImports()
    for player, _ in pairs(Imports) do
        checkAndInvite(player)
    end
end

function Invite:onMouseWheelImports(delta)
    local negativeDelta = -delta
    if Utils:indexIsValidForList(negativeDelta, ImportIndex, MaximumImportsShown, Utils:getSize(Imports)) then
        ImportIndex = ImportIndex + negativeDelta
        updateImportEntries()
    end
end