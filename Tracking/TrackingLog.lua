JP_Consumables_Log = {}
JP_Buff_Log = {}
local Jp = _G.Jp
local Utils = Jp.Utils
local TrackingLog = {}
local Consumables = Jp.Consumables
local Buffs = Jp.Buffs
Jp.TrackingLog = TrackingLog

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

function TrackingLog:onLoad()
    getglobal("JP_ConsFrameTitleFrameText"):SetText(CONS_FRAME_TITLE)
end

local function existRecordingsForDate(table, date)
    if (table[date] == nil) then
        Utils:jpMsg("No recordings for the specified date")
        return false
    end
    return true
end

function TrackingLog:getItemFromLog(date, item)
    if not existRecordingsForDate(JP_Consumables_Log, date) then
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

    Utils:jpMsg(item .. ": ")
    for entry = 1, #initEntries, 1 do
        local itemsUsed = initEntries[entry][2] - postEntries[entry][2]
        local msg = initEntries[entry][1] .. " used " .. itemsUsed
        Utils:jpMsg(msg)
    end
    return true
end

function TrackingLog:getRequiredBuffsFromLog(date)
    local requiredBuffs = Buffs:getRequiredBuffs()
    for _, buff in pairs(requiredBuffs) do
        local callSucceeded = TrackingLog:getBuffFromLog(date, buff)
        if not callSucceeded then
            return
        end
    end
end

function TrackingLog:getBuffFromLog(date, buff)
    if not existRecordingsForDate(JP_Buff_Log, date) then
        return
    end

    if (Buffs:getAbbFromName(buff) == nil) then
        local initialBuff = buff
        buff = Buffs:getNameFromAbb(buff)
        if (buff == nil) then
            Utils:jpMsg(initialBuff .. " was not found in the buff log")
            return
        end
    end

    local buffEntries = JP_Buff_Log[date][buff]
    Utils:jpMsg(buff .. ": ")
    for entry = 1, #buffEntries, 1 do
        local player = buffEntries[entry][1]
        local expirationTime = buffEntries[entry][3]
        local msg = player .. " - Time left in minutes: " .. expirationTime
        Utils:jpMsg(msg)
    end
    return true
end

function TrackingLog:getAllItems(date)
    local requiredCons = Consumables:getRequiredConsumables()
    for con = 1, #requiredCons, 1 do
        local callSucceeded = TrackingLog:getItemFromLog(date, requiredCons[con])
        if not callSucceeded then
            return
        end
    end
end

local function createBuffEntries(datestamp)
    JP_Buff_Log[datestamp] = {}
    for name, _ in pairs(Buffs:getRaidBuffNamesAndIds()) do
        JP_Buff_Log[datestamp][name] = {}
    end
end

local function createDateEntryIfNeeded(datestamp)
    if (JP_Consumables_Log[datestamp] == nil) then
        JP_Consumables_Log[datestamp] = {}
        createBuffEntries(datestamp)
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

function TrackingLog:getInitialCons()
    local msg = REQUEST_INIT_CONS
    Utils:sendOfficerAddonMsg(msg, "RAID")
end

function TrackingLog:getPostRaidCons()
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
        local conCount = GetItemCount(requiredCons[conNr], nil, true)
        if (conCount > 0) then
            msg = msg .. "&" .. Consumables:getAbbFromName(requiredCons[conNr]) .. conCount
        end
    end
    Utils:sendAddonMsg(msg, "RAID")
end

local function sendBuffs()
    local msg = BUFFS
    local currentBuffs = Buffs:getCurrentBuffs()
    for buff = 1, #currentBuffs, 1 do
        local buffInfo = currentBuffs[buff]
        msg = msg .. "&" .. Buffs:getAbbFromName(buffInfo[1]) .. "?" .. buffInfo[2] .. "?" .. buffInfo[3]
    end
    Utils:sendAddonMsg(msg, "RAID")
end

local function insertOrEditBuff(datestamp, sender, name, duration, expirationTime)
    local edited = false
    for entry = 1, #JP_Buff_Log[datestamp][name], 1 do
        if (JP_Buff_Log[datestamp][name][entry][1] == sender) then
            JP_Buff_Log[datestamp][name][entry] = { sender, duration, expirationTime }
            edited = true
        end
    end
    if not edited then
        table.insert(JP_Buff_Log[datestamp][name], { sender, duration, expirationTime })
    end
end

local function addBuff(datestamp, sender, buff)
    local name, duration, expirationTime = string.split("?", buff)
    insertOrEditBuff(datestamp, sender, Buffs:getNameFromAbb(name), duration, expirationTime)
end

local function insertBuffsInLog(msg, msgPrefix, sender)
    local noPrefixMsg = string.gsub(msg, msgPrefix .. "&", "")
    local currentTime = time()
    local datestamp = date("%d/%m/%Y", currentTime)
    for buff in string.gmatch(noPrefixMsg, "([^&]+)") do
        addBuff(datestamp, sender, buff)
    end
end

function TrackingLog:onEvent(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (event == "CHAT_MSG_ADDON") then
        if (prefix == ADDON_PREFIX) then
            local msgPrefix = string.split("&", msg)
            if (msgPrefix == INIT_CONS or msgPrefix == POST_CONS) and Utils:isOfficer() then
                insertInLog(msg, msgPrefix, Utils:removeRealmName(sender))
            elseif (msgPrefix == BUFFS) then
                insertBuffsInLog(msg, msgPrefix, Utils:removeRealmName(sender))
            elseif (msgPrefix == REQUEST_INIT_CONS) then
                sendCons(INIT_CONS)
                sendBuffs()
            elseif (msgPrefix == REQUEST_POST_CONS) then
                sendCons(POST_CONS)
            end
        end
    end
end