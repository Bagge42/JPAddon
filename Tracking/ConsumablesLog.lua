JP_Consumables_Log = {}
local Jp = _G.Jp
local Utils = Jp.Utils
local ConsumablesLog = {}
local Consumables = Jp.Consumables
Jp.ConsumablesLog = ConsumablesLog

local function removeUncommonEntries(initEntries, postEntries)
    local newInit = {}
    local newPost = {}
    for initEntryNr = 1, #initEntries, 1 do
        local postPlayerEntry
        local initPlayerEntry = initEntries[initEntryNr]
        for postEntryNr = 1, #postEntries, 1 do
            if (initPlayerEntry[1] == postEntries[postEntryNr][1]) then
                postPlayerEntry = postEntries[postEntryNr]
            end
        end
        table.insert(newInit, initPlayerEntry)
        if (postPlayerEntry ~= nil) then
            table.insert(newPost, postPlayerEntry)
        else
            table.insert(newPost, { initPlayerEntry[1], 0 })
        end
    end
    return newInit, newPost
end

function ConsumablesLog:onLoad()
    getglobal("JP_ConsFrameTitleFrameText"):SetText(CONS_FRAME_TITLE)
end

function ConsumablesLog:getItemFromLog(date, item)
    if (JP_Consumables_Log[date] == nil) then
        Utils:jpMsg("No recordings for the specified date")
        return
    elseif (JP_Consumables_Log[date][INIT_CONS] == nil) then
        Utils:jpMsg("No initial recordings for the specified date")
        return
    elseif (JP_Consumables_Log[date][POST_CONS] == nil) then
        Utils:jpMsg("No post raid recordings for the specified date")
        return
    end

    if (Consumables:getAbbFromName(item) == nil) then
        local initialItem = item
        item = Consumables:getNameFromAbb(item)
        if (item == nil) then
            Utils:jpMsg(initialItem .. " was not found in the consumable log")
            return
        end
    end

    local initEntries = JP_Consumables_Log[date][INIT_CONS][item]
    local postEntries = JP_Consumables_Log[date][POST_CONS][item]
    initEntries, postEntries = removeUncommonEntries(initEntries, postEntries)

    Utils:jpMsg(item .. " - Format: Player: Amount used")
    for entry = 1, #initEntries, 1 do
        local itemsUsed = initEntries[entry][2] - postEntries[entry][2]
        local msg = initEntries[entry][1] .. ": " .. itemsUsed
        Utils:jpMsg(msg)
    end
    return true
end

function ConsumablesLog:getAllItems(date)
    local requiredCons = Consumables:getRequiredConsumables()
    for con = 1, #requiredCons, 1 do
        local callSucceeded = ConsumablesLog:getItemFromLog(date, requiredCons[con])
        if not callSucceeded then
           return
        end
    end
end

local function createDateEntryIfNeeded(datestamp)
    if (JP_Consumables_Log[datestamp] == nil) then
        JP_Consumables_Log[datestamp] = {}
    end
end

local function createConsEntries(datestamp, prefix)
    local requiredCons = Consumables:getRequiredConsumables()
    for requiredConNr = 1, #requiredCons, 1 do
        JP_Consumables_Log[datestamp][prefix][requiredCons[requiredConNr]] = {}
    end
end

local function createPrefixEntryIfNeeded(datestamp, prefix)
    if (JP_Consumables_Log[datestamp][prefix] == nil) then
        JP_Consumables_Log[datestamp][prefix] = {}
        createConsEntries(datestamp, prefix)
    end
end

function ConsumablesLog:getInitialCons()
    local msg = REQUEST_INIT_CONS
    Utils:sendOfficerAddonMsg(msg, "RAID")
end

function ConsumablesLog:getPostRaidCons()
    local msg = REQUEST_POST_CONS
    Utils:sendOfficerAddonMsg(msg, "RAID")
end

local function createEntriesIfNeeded(datestamp, prefix)
    createDateEntryIfNeeded(datestamp)
    createPrefixEntryIfNeeded(datestamp, prefix)
end

local function insertOrEdit(datestamp, prefix, sender, con, conNr)
    local edited = false
    for entry = 1, #JP_Consumables_Log[datestamp][prefix][con], 1 do
        if (JP_Consumables_Log[datestamp][prefix][con][entry][1] == sender) then
            JP_Consumables_Log[datestamp][prefix][con][entry] = { sender, conNr }
            edited = true
        end
    end
    if not edited then
        table.insert(JP_Consumables_Log[datestamp][prefix][con], { sender, conNr })
    end
end

local function addEntry(datestamp, prefix, sender, conAndConNr)
    local con, conNr
    for match in string.gmatch(conAndConNr, "([^%d]+)") do
        con = match
        con = Consumables:getNameFromAbb(con)
    end
    for match in string.gmatch(conAndConNr, "([%d]+)") do
        conNr = match
    end
    insertOrEdit(datestamp, prefix, sender, con, conNr)
end

local function insertInLog(msg, msgPrefix, sender)
    local noPrefixMsg = string.gsub(msg, msgPrefix .. "&", "")
    local currentTime = time()
    local datestamp = date("%d/%m/%Y", currentTime)
    createEntriesIfNeeded(datestamp, msgPrefix)
    for conAndConNr in string.gmatch(noPrefixMsg, "([^&]+)") do
        addEntry(datestamp, msgPrefix, sender, conAndConNr)
    end
end

local function sendCons(prefix)
    local msg = prefix
    local requiredCons = Consumables:getRequiredConsumables()
    for conNr = 1, #requiredCons, 1 do
        local conCount = GetItemCount(requiredCons[conNr])
        if (conCount > 0) then
            msg = msg .. "&" .. Consumables:getAbbFromName(requiredCons[conNr]) .. conCount
        end
    end
    Utils:sendAddonMsg(msg, "RAID")
end

function ConsumablesLog:onEvent(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (event == "CHAT_MSG_ADDON") then
        if (prefix == ADDON_PREFIX) and Utils:isOfficer() then
            local msgPrefix = string.split("&", msg)
            if (msgPrefix == INIT_CONS or msgPrefix == POST_CONS) then
                insertInLog(msg, msgPrefix, Utils:removeRealmName(sender))
            elseif (msgPrefix == REQUEST_INIT_CONS) then
                sendCons(INIT_CONS)
            elseif (msgPrefix == REQUEST_POST_CONS) then
                sendCons(POST_CONS)
            end
        end
    end
end