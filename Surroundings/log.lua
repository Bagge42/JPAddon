Log_History = {}
Date_To_Id = {}
JP_Log_History = {}
_G.JP_Log = {}
JP_Log_Date_To_Id = {}
local Log = _G.JP_Log
local Utils = _G.JP_Utils
local MaximumMembersShown = 24
local MaximumRaidsShown = 30
local LogHistoryIndex = 0
local ZoneIndex = 0
local Icons = {
    ["Onyxia's Lair"] = Ony,
    ["Molten Core"] = MC,
    ["Blackwing Lair"] = BWL,
    ["Ahn'Qiraj"] = AQ,
    ["Naxxramas"] = Naxx,
    ["Orgrimmar"] = "Interface\\ICONS\\Spell_Arcane_TeleportOrgrimmar",
    ["Thunder Bluff"] = "Interface\\ICONS\\Spell_Arcane_TeleportThunderBluff",
    ["Undercity"] = "Interface\\ICONS\\Spell_Arcane_TeleportUnderCity",
    ["Unknown"] = "Interface\\ICONS\\INV_Misc_QuestionMark"
}
local ButtonIdToKeys = {}
local DataEntryIndex = 1
local LatestButtonId

local function getZoneNrIfExist(dateEntry, zone)
    for zoneCount = 1, #dateEntry, 1 do
        local zoneEntry = dateEntry[zoneCount]
        if zoneEntry then
            local dataEntry = zoneEntry[1]
            if dataEntry then
                if dataEntry[1] == zone then
                    return zoneCount
                end
            end
        end
    end
    return nil
end

local function addToSubTable(datestamp, zone, entry)
    local idOfDate = JP_Log_Date_To_Id[datestamp]
    if idOfDate == nil then
        idOfDate = #JP_Log_History + 1
        JP_Log_History[idOfDate] = {}
        JP_Log_Date_To_Id[datestamp] = idOfDate
    end
    local zoneNr = getZoneNrIfExist(JP_Log_History[idOfDate], zone)
    if not zoneNr then
        local zoneNr = #JP_Log_History[idOfDate] + 1
        JP_Log_History[idOfDate][zoneNr] = { [1] = { zone, entry } }
    else
        JP_Log_History[idOfDate][zoneNr][#JP_Log_History[idOfDate][zoneNr] + 1] = { zone, entry }
    end
end

local function sendSyncMsg(zone, dataEntry)
    local msg = LOG_MSG_ENTRY .. "&" .. zone
    for _, data in pairs(dataEntry) do
        msg = msg .. "&" .. data
    end
    Utils:sendOfficerAddonMsg(msg, "GUILD")
end

local function addEntryFromSync(zone, datestamp, timestamp, player, change, total, event, class, executingOfficer)
    local entry = { datestamp, timestamp, player, change, total, event, class, executingOfficer }
    addToSubTable(datestamp, zone, entry)
end

function Log:onSyncAttempt(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (prefix == ADDON_PREFIX) and (event == "CHAT_MSG_ADDON") then
        local _, zone, datestamp, timestamp, player, change, total, event, class, executingOfficer = string.split("&", msg)
        if Utils:isMsgTypeAndNotFromSelf(msg, LOG_MSG_ENTRY, sender) then
            addEntryFromSync(zone, datestamp, timestamp, player, change, total, event, class, executingOfficer)
        end
    end
end

function Log:addEntry(player, change, total, event, class, zone)
    local currentTime = time()
    local datestamp = date("%d/%m/%Y", currentTime)
    local timestamp = date("%H:%M:%S", currentTime)
    local executingOfficer = UnitName("player")
    local entry = { datestamp, timestamp, player, change, total, event, class, executingOfficer }
    addToSubTable(datestamp, zone, entry)
    sendSyncMsg(zone, entry)
end

local function textureNeedsCropping(texture)
    if (texture == Ony) or (texture == MC) or (texture == BWL) or (texture == AQ) or (texture == Naxx) then
        return true
    end
    return false
end

local function attachIcon(button, texture)
    button.icon:SetTexture(texture)
    if textureNeedsCropping(texture) then
        button.icon:SetTexCoord(0, 0.70, 0, 0.75)
    end
end

local function createTexture(button)
    button.icon = button:CreateTexture("$parentIcon", "CENTER")
    button.icon:SetAllPoints(button)
end

function Log:createRaidEntries()
    local initialButton = CreateFrame("Button", "$parentButton1", JP_LogFrameSelectFrame, "JP_RaidSelect")
    initialButton:SetID(1)
    initialButton:SetPoint("TOPLEFT")
    createTexture(initialButton)
    for buttonNr = 2, MaximumRaidsShown, 1 do
        local followingButtons = CreateFrame("Button", "$parentButton" .. buttonNr, JP_LogFrameSelectFrame, "JP_RaidSelect")
        followingButtons:SetID(buttonNr)
        if buttonNr % 5 == 1 then
            followingButtons:SetPoint("TOP", "$parentButton" .. (1 + (floor(buttonNr / 5) - 1) * 5), "BOTTOM")
        else
            followingButtons:SetPoint("LEFT", "$parentButton" .. (buttonNr - 1), "RIGHT")
        end
        createTexture(followingButtons)
    end
    Log:updateRaidEntries()
end

local function clearRaidEntries()
    for entry = 1, MaximumRaidsShown, 1 do
        local button = getglobal("JP_LogFrameSelectFrameButton" .. entry)
        button:SetText("")
        getglobal(button:GetName() .. "Icon"):SetTexture(nil)
        button:Hide()
    end
end

local function getZoneEntryAndUpdateIndexes(raidEntry, zoneKey)
    local zoneEntry = raidEntry[zoneKey]

    if zoneKey == 1 then
        LogHistoryIndex = LogHistoryIndex + 1
        ZoneIndex = 0
    else
        ZoneIndex = ZoneIndex + 1
    end
    return zoneEntry
end

local function getZoneTexture(zone)
    local icon = Icons[zone]
    if icon == nil then
        return Icons["Unknown"]
    else
        return icon
    end
end

function Log:updateRaidEntries()
    clearRaidEntries()
    local LogHistoryIndexBeforeUpdate = LogHistoryIndex
    for raidIndex = 1, MaximumRaidsShown, 1 do
        local logHistoryKey = #JP_Log_History - LogHistoryIndex
        local raidEntry = JP_Log_History[logHistoryKey]
        if raidEntry then
            local logEntryFrame = getglobal("JP_LogFrameSelectFrameButton" .. (raidIndex))
            local zoneKey = #raidEntry - ZoneIndex
            local zoneEntry = getZoneEntryAndUpdateIndexes(raidEntry, zoneKey)
            local firstDataEntry = zoneEntry[1]
            local zoneTexture = getZoneTexture(firstDataEntry[1])
            local date = firstDataEntry[2][1]
            attachIcon(logEntryFrame, zoneTexture)
            logEntryFrame:SetText(date)
            logEntryFrame:Show()
            ButtonIdToKeys[raidIndex] = { logHistoryKey, zoneKey }
        else
            break
        end
    end
    LogHistoryIndex = LogHistoryIndexBeforeUpdate
end

function Log:createEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", JP_LogFrameDisplayFrameList, "JP_LogEntry")
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOP", JP_LogFrameDisplayFrameListChangeHeader, "BOTTOM", -19.5, 0)
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, JP_LogFrameDisplayFrameList, "JP_LogEntry")
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

local function clearEntries()
    for entry = 1, MaximumMembersShown, 1 do
        local listEntry = getglobal("JP_LogFrameDisplayFrameListEntry" .. entry)
        getglobal(listEntry:GetName() .. "Time"):SetText("")
        getglobal(listEntry:GetName() .. PLAYER):SetText("")
        getglobal(listEntry:GetName() .. "Change"):SetText("")
        getglobal(listEntry:GetName() .. "Total"):SetText("")
        getglobal(listEntry:GetName() .. "Event"):SetText("")
    end
end

local function updateEntries(buttonId)
    clearEntries()
    local DataEntryIndexBeforeUpdate = DataEntryIndex
    local keys
    if not buttonId then
        keys = ButtonIdToKeys[LatestButtonId]
    else
        keys = ButtonIdToKeys[buttonId]
        LatestButtonId = buttonId
    end
    local zoneEntries = JP_Log_History[keys[1]][keys[2]]
    for index = 0, MaximumMembersShown - 1, 1 do
        local dataEntry = zoneEntries[DataEntryIndex]
        if dataEntry then
            local data = dataEntry[2]
            local logEntryFrame = getglobal("JP_LogFrameDisplayFrameListEntry" .. (index + 1))
            getglobal(logEntryFrame:GetName() .. "Time"):SetText(data[2])
            local playerFrame = getglobal(logEntryFrame:GetName() .. PLAYER)
            playerFrame:SetText(data[3])
            Utils:setClassColor(playerFrame, data[7])
            getglobal(logEntryFrame:GetName() .. "Change"):SetText(data[4])
            getglobal(logEntryFrame:GetName() .. "Total"):SetText(data[5])
            getglobal(logEntryFrame:GetName() .. "Event"):SetText(data[6])
            logEntryFrame:Show()
            DataEntryIndex = DataEntryIndex + 1
            --        if name == BrowserSelection:getSelectedPlayer() then
            --            getglobal(listEntry:GetName() .. BACKGROUND):Show()
            --        else
            --            getglobal(listEntry:GetName() .. BACKGROUND):Hide()
            --        end
        else
            break
        end
    end
    DataEntryIndex = DataEntryIndexBeforeUpdate
end

function Log:displayFrameNext()
    DataEntryIndex = DataEntryIndex + MaximumMembersShown
    updateEntries()
end

function Log:displayFramePrevious()
    DataEntryIndex = DataEntryIndex - MaximumMembersShown
    updateEntries()
end

function Log:selectFrameNext()
    LogHistoryIndex = LogHistoryIndex + MaximumRaidsShown
    Log:updateRaidEntries()
end

function Log:selectFramePrevious()
    LogHistoryIndex = LogHistoryIndex - MaximumRaidsShown
    Log:updateRaidEntries()
end

function Log:back()
    Log:updateRaidEntries()
    getglobal("JP_LogFrameDisplayFrame"):Hide()
    getglobal("JP_LogFrameSelectFrame"):Show()
end

function Log:raidSelect(buttonId)
    DataEntryIndex = 1
    updateEntries(buttonId)
    getglobal("JP_LogFrameDisplayFrame"):Show()
end

function Log:clearLog(date)
    if date == "Everything" then
        JP_Log_History = {}
        JP_Log_Date_To_Id = {}
    else
        local id = JP_Log_Date_To_Id[date]
        if id then
            JP_Log_History[id] = nil
            JP_Log_Date_To_Id[date] = nil
        end
    end
end

function Log:loadLog(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (prefix == ADDON_PREFIX) and (event == "ADDON_LOADED") then
        if (Utils:getSizeOfTable(Log_History) > Utils:getSizeOfTable(JP_Log_History)) then
            for dateId, table in pairs(Log_History) do
                JP_Log_History[dateId] = table
            end
            for date, id in pairs(Date_To_Id) do
                JP_Log_Date_To_Id[date] = id
            end
            local infoMsg = "Moved your log files to a new table"
            Utils:jpMsg(infoMsg)
        end
    end
end