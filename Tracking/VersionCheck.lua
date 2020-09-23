JP_Versions = {}

local Jp = _G.Jp
local Localization = Jp.Localization
local VersionCheck = {}
local Utils = Jp.Utils
local GuildRosterHandler = Jp.GuildRosterHandler
local FrameHandler = Jp.FrameHandler
local DateEditBox = Jp.DateEditBox
Jp.VersionCheck = VersionCheck

local playersOnlineAtCheck = {}
local MaximumVersionEntriesShown = 11
local ShownVersionsEntries = {}
local ShownVersionsIndex = 1

local function printVersions(date)
    if (date == nil) then
        date = Utils:getDate()
    end

    local ownVersion = GetAddOnMetadata("Jpdkp", "Version")
    Utils:jpMsg("Following online people has outdated versions:")
    for player, version in pairs(JP_Versions[date]) do
        if (version < ownVersion) then
            Utils:jpMsg(player .. ": " .. version)
        end
    end
    Utils:jpMsg("Following people did not have jpdkp on check:")
    for player, _ in pairs(playersOnlineAtCheck) do
        if (JP_Versions[date][player] == nil) then
            Utils:jpMsg(player)
        end
    end
end

local function getSortedEntries()
    local sortedEntries = {}
    for player, version in pairs(ShownVersionsEntries) do
        table.insert(sortedEntries, { player, version })
    end
    return Utils:sortByEntryInValue(sortedEntries, 2)
end

local function updateVersionEntries()
    Utils:clearEntries("JP_TrackingFrameVersionTabListEntry", MaximumVersionEntriesShown, "Player", "Version")
    local entryCounter = 1
    if (ShownVersionsEntries == nil) then
        return
    end
    local sortedEntries = getSortedEntries()

    for memberIndex = ShownVersionsIndex, #sortedEntries, 1 do
        if entryCounter > MaximumVersionEntriesShown then
            return
        end
        local entry = getglobal("JP_TrackingFrameVersionTabListEntry" .. entryCounter)
        entry:Show()
        getglobal(entry:GetName() .. Localization.BACKGROUND):Hide()
        local player = getglobal(entry:GetName() .. "Player")
        local playerName = sortedEntries[memberIndex][1]
        player:SetText(playerName)
        Utils:setClassColor(player, GuildRosterHandler:getPlayerClass(playerName))
        local version = getglobal(entry:GetName() .. "Version")
        version:SetText(sortedEntries[memberIndex][2])
        entryCounter = entryCounter + 1
    end
end

local function updateShownVersions(date)
    if (date == nil) then
        date = Utils:getDate()
    end
    ShownVersionsEntries = JP_Versions[date]
    updateVersionEntries()
end

function VersionCheck:fetchVersions()
    local date = getglobal("JP_TrackingFrameVersionTabDateFrameValue"):GetText()
    updateShownVersions(date)
end

function VersionCheck:requestCheck()
    local msg = Localization.VERSION_CHECK_REQUEST
    playersOnlineAtCheck = GuildRosterHandler:getOnlinePeople()
    Utils:sendAddonMsg(msg, "GUILD")
    Utils:jpWait(3, printVersions)
    Utils:jpWait(3, updateShownVersions)
end

local function getAndSendVersion()
    local version = GetAddOnMetadata("Jpdkp", "Version")
    local msg = Localization.VERSION .. "&" .. version
    Utils:sendAddonMsg(msg, "GUILD")
end

local function createDateEntry(date)
    JP_Versions[date] = {}
end

local function dateEntryExist(date)
    return JP_Versions[date] ~= nil
end

function VersionCheck:onEvent(msg, sender)
    local msgPrefix, version = string.split("&", msg)
    if (msgPrefix == Localization.VERSION_CHECK_REQUEST) then
        getAndSendVersion()
    elseif (msgPrefix == Localization.VERSION) and Utils:isOfficer() and (sender ~= nil) then
        local date = Utils:getDate()
        if not dateEntryExist(date) then
            createDateEntry(date)
        end
        JP_Versions[date][sender] = version
    end
end

function VersionCheck:getMaximumVersionEntriesShown()
    return MaximumVersionEntriesShown
end

function Jp.VersionCheck:onMouseWheel(delta)
    local negativeDelta = -delta
    if Utils:indexIsValidForList(negativeDelta, ShownVersionsIndex, MaximumVersionEntriesShown, Utils:getSize(ShownVersionsEntries)) then
        ShownVersionsIndex = ShownVersionsIndex + negativeDelta
        updateVersionEntries()
    end
end

local function setCurrentDateVersionTab()
    DateEditBox:setCurrentDate("JP_TrackingFrameVersionTabDateFrameValue")
end

function VersionCheck:onLoad()
    FrameHandler:setOnClickTrackingFrameButtons("Version", setCurrentDateVersionTab)
end

local function printOutOfDateMsg(sender, version)
    local printMsg = "Your Jpdkp is out of date " .. sender .. " has version " .. version
    Utils:jpMsg(printMsg)
end

function VersionCheck:reactToVersionMsg(msg, sender)
    local _, version = string.split("&", msg)
    local ownVersion = GetAddOnMetadata("Jpdkp", "Version")
    if (ownVersion > version) then
        local reponse = Localization.VERSION_RESPOND .. "&" .. ownVersion
        Utils:sendAddonMsg(reponse, "WHISPER", sender)
    elseif (ownVersion < version) then
        printOutOfDateMsg(sender, version)
    end
end

function VersionCheck:printOutOfDateMsg(msg, sender)
    local _, version = string.split("&", msg)
    printOutOfDateMsg(sender, version)
end

function VersionCheck:sendVersion()
    local version = GetAddOnMetadata("Jpdkp", "Version")
    local msg = Localization.VERSION_SEND .. "&" .. version
    Utils:sendAddonMsg(msg, "GUILD")
end

