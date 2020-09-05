JP_Consumables_Log = {}
JP_Buff_Log = {}
local Jp = _G.Jp
local Utils = Jp.Utils
local TrackingLog = {}
local Consumables = Jp.Consumables
local Buffs = Jp.Buffs
local BrowserSelection = Jp.BrowserSelection
local GuildRosterHandler = Jp.GuildRosterHandler
local FrameHandler = Jp.FrameHandler
local DateEditBox = Jp.DateEditBox
local DkpManager = Jp.DkpManager
Jp.TrackingLog = TrackingLog

local RequestedInitBuffs
local RequestedInitCons
local CreatedBuffCheck = false
local BuffBonus = 3
local NrOfRequiredBuffs = 2
local TradeTarget
local LootWasFromTrade

function TrackingLog:onLoad()
    FrameHandler:createTrackingTabButtons()
    Buffs:onLoad()
    Consumables:onLoad()
end

local function existRecordingsForDate(table, date)
    if (table[date] == nil) then
        Utils:jpMsg("No recordings for the specified date")
        return false
    end
    return true
end

local function isRecordings(date)
    if not existRecordingsForDate(JP_Consumables_Log, date) then
        return false
    elseif (JP_Consumables_Log[date][INIT_CONS] == nil) then
        Utils:jpMsg("No initial recordings for the specified date")
        return false
    elseif (JP_Consumables_Log[date][POST_CONS] == nil) then
        Utils:jpMsg("No post raid recordings for the specified date")
        return false
    end
    return true
end

function TrackingLog:getItemsFromLog(date, ...)
    if not isRecordings(date) then
        return
    end

    local nrOfItems = select('#', ...)
    for itemCount = 1, nrOfItems do
        local item = select(itemCount, ...)
        TrackingLog:getItemFromLog(date, item)
    end
end

local function printInventoriesForItem(entries)
    for _, playerTable in pairs(entries) do
        local itemsUsed = playerTable[2]
        local msg = playerTable[1] .. " held " .. itemsUsed
        Utils:jpMsg(msg)
    end
end

local function convertToNameNumberTable(indexedTable)
    local newTable = {}
    if indexedTable then
        for _, entry in pairs(indexedTable) do
            newTable[entry[1]] = entry[2]
        end
    end
    return newTable
end

local function insertZeros(table1, table2)
    for key, _ in pairs(table1) do
        if (table2[key] == nil) then
            table2[key] = 0
        end
    end
end

local function isMatchingRole(roleToMatch, name)
    if (roleToMatch == nil) then
        return true
    else
        local playerRole, playerRole2 = GuildRosterHandler:getRole(name)
        return roleToMatch == playerRole or roleToMatch == playerRole2
    end
end

function TrackingLog:onListEntryClick(entryId)
    local cons = getglobal("JP_TrackingFrameConsTabListEntry" .. entryId .. "Cons"):GetText()
    local date = getglobal("JP_TrackingFrameConsTabDateFrameValue"):GetText()
    TrackingLog:getItemFromLog(date, cons)
end

local function getItemNr(initEntries, postEntries, name)
    if Consumables:getShowInit() then
        return initEntries[name]
    elseif Consumables:getShowPost() then
        return postEntries[name]
    else
        return initEntries[name] - postEntries[name]
    end
end

local function getInitAndPostEntriesForItem(date, item)
    local initEntries = JP_Consumables_Log[date][INIT_CONS][item]
    local postEntries = JP_Consumables_Log[date][POST_CONS][item]
    initEntries = convertToNameNumberTable(initEntries)
    postEntries = convertToNameNumberTable(postEntries)
    insertZeros(initEntries, postEntries)
    insertZeros(postEntries, initEntries)
    return initEntries, postEntries
end

function TrackingLog:getItemFromLog(date, item, role)
    if not isRecordings(date) then
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

    local initEntries, postEntries = getInitAndPostEntriesForItem(date, item)

    Utils:jpMsg(item)
    Utils:jpMsg("----------------------------------------")
    local msg = ""
    for name, _ in pairs(initEntries) do
        local itemsUsed = getItemNr(initEntries, postEntries, name)
        local matchRole = isMatchingRole(role, name)
        if (itemsUsed ~= 0) and matchRole then
            msg = msg .. name .. ": " .. itemsUsed .. "  "
        end
    end
    if (msg ~= "") then
        Utils:jpMsg(msg)
    end
    Utils:jpMsg("")
    return true
end

local function iterateThroughConsumes(date, consumes, role)
    for _, item in pairs(consumes) do
        local callSucceeded = TrackingLog:getItemFromLog(date, item, role)
        if not callSucceeded then
            return
        end
    end
end

function TrackingLog:getRole(date, role)
    if (role == nil) then
        Utils:jpMsg("Valid roles: Tank, Melee, Healer, Caster, Hunter")
        return
    end
    local roleConsumes = Consumables:getRoleConsumables(role)
    iterateThroughConsumes(date, roleConsumes, role)
end

function TrackingLog:getRequiredBuffsFromLog()
    local requiredBuffs = Buffs:getRequiredBuffs()
    local date = DateEditBox:getDateFromBox("JP_TrackingFrameBuffTabDateFrameValue")
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
    local requiredCons = Consumables:getConsumableList()
    for con = 1, #requiredCons, 1 do
        local callSucceeded = TrackingLog:getItemFromLog(date, requiredCons[con][1])
        if not callSucceeded then
            return
        end
    end
end

function TrackingLog:getItemsForPlayer(date, player)
    if not isRecordings(date) then
        return
    end

    local requiredCons = Consumables:getConsumableList()
    Utils:jpMsg(player)
    Utils:jpMsg("----------------------------------------")
    for con = 1, #requiredCons, 1 do
        local nameOfCon = requiredCons[con][1]
        local initEntries, postEntries = getInitAndPostEntriesForItem(date, nameOfCon)
        if (initEntries[player] ~= nil) then
            local consUsed = initEntries[player] - postEntries[player]
            Utils:jpMsg(nameOfCon .. ": " .. consUsed)
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
    end
end

local function createConsEntries(datestamp, prefix)
    local requiredCons = Consumables:getConsumableList()
    for requiredConNr = 1, #requiredCons, 1 do
        JP_Consumables_Log[datestamp][prefix][requiredCons[requiredConNr][1]] = {}
    end
end

local function createPrefixEntryIfNeeded(datestamp, prefix)
    if (JP_Consumables_Log[datestamp][prefix] == nil) then
        JP_Consumables_Log[datestamp][prefix] = {}
        createConsEntries(datestamp, prefix)
    end
end

function TrackingLog:getPostRaidConsSilent()
    local msg = REQUEST_POST_CONS
    Utils:sendOfficerAddonMsg(msg, "RAID")
end

local function sendInitRequest()
    local msg = REQUEST_INIT_CONS
    Utils:sendOfficerAddonMsg(msg, "RAID")
end

local function sendConsBuffStatus(cons, buffs)
    local msg = SHOULD_SAVE_CONS_BUFFS .. "&" .. cons .. "&" .. buffs
    Utils:sendOfficerAddonMsg(msg, "RAID")
end

function TrackingLog:getInitialCons()
    sendConsBuffStatus(1, 0)
    sendInitRequest()
    Utils:sendWarningMessage("Pre-raid consumable check performed")
end

function TrackingLog:getInitialBuffs()
    sendConsBuffStatus(0, 1)
    sendInitRequest()
    Utils:sendWarningMessage("Pre-raid buff check performed")
end

function TrackingLog:getInitialConsAndBuffs()
    sendConsBuffStatus(1, 1)
    sendInitRequest()
    Utils:sendWarningMessage("Pre-raid consumable and buff check performed")
end

function TrackingLog:getPostRaidCons()
    TrackingLog:getPostRaidConsSilent()
    Utils:sendWarningMessage("Post-raid consumable check performed")
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

local function getConName(conAndConNr)
    local con
    for match in string.gmatch(conAndConNr, "([^%d]+)") do
        con = match
        con = Consumables:getNameFromAbb(con)
    end
    return con
end

local function addEntry(datestamp, prefix, sender, conAndConNr)
    local con = getConName(conAndConNr)
    local conNr
    for match in string.gmatch(conAndConNr, "([%d]+)") do
        conNr = match
    end
    insertOrEdit(datestamp, prefix, sender, con, conNr)
end

local function removeConsIfUsed(datestamp, msgPrefix, sender, consReported)
    for item, itemInfo in pairs(JP_Consumables_Log[datestamp][msgPrefix]) do
        if not consReported[item] then
            for index, playerInfo in pairs(itemInfo) do
                if (playerInfo[1] == sender) then
                    table.remove(JP_Consumables_Log[datestamp][msgPrefix][item], index)
                end
            end
        end
    end
end

local function insertInLog(msg, msgPrefix, sender)
    if (msgPrefix == INIT_CONS) and (RequestedInitCons == 0) then
        return
    end

    local noPrefixMsg = string.gsub(msg, msgPrefix .. "&", "")
    local currentTime = time()
    local datestamp = date("%d/%m/%Y", currentTime)
    createEntriesIfNeeded(datestamp, msgPrefix)
    local consReported = {}
    for conAndConNr in string.gmatch(noPrefixMsg, "([^&]+)") do
        if (conAndConNr ~= msgPrefix) then
            addEntry(datestamp, msgPrefix, sender, conAndConNr)
            consReported[getConName(conAndConNr)] = true
        end
    end
    removeConsIfUsed(datestamp, msgPrefix, sender, consReported)
end

local function sendCons(prefix)
    local msg = prefix
    local requiredCons = Consumables:getConsumableList()
    for conNr = 1, #requiredCons, 1 do
        local conCount = GetItemCount(requiredCons[conNr][1], nil, true)
        if (conCount > 0) then
            msg = msg .. "&" .. Consumables:getAbbFromName(requiredCons[conNr][1]) .. conCount
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

local function insertOrEditBuff(datestamp, sender, buffName, duration, expirationTime)
    local edited = false
    for entry = 1, #JP_Buff_Log[datestamp][buffName], 1 do
        if (JP_Buff_Log[datestamp][buffName][entry][1] == sender) then
            JP_Buff_Log[datestamp][buffName][entry] = { sender, duration, expirationTime }
            edited = true
        end
    end
    if not edited then
        table.insert(JP_Buff_Log[datestamp][buffName], { sender, duration, expirationTime })
    end
end

local function addBuff(datestamp, sender, buff)
    local name, duration, expirationTime = string.split("?", buff)
    if (name ~= BUFFS) then
        insertOrEditBuff(datestamp, sender, Buffs:getNameFromAbb(name), duration, expirationTime)
    end
end

local function createBuffEntriesIfNeeded(datestamp)
    if (JP_Buff_Log[datestamp] == nil) then
        createBuffEntries(datestamp)
    end
end

local function addDkpForHavingBuffs(datestamp, sender)
    local requiredBuffs = Buffs:getRequiredBuffs()
    local requiredBuffsObtained = {}
    for _, buff in pairs(requiredBuffs) do
        for _, playerInfo in pairs(JP_Buff_Log[datestamp][buff]) do
            if (playerInfo[1] == sender) then
                if (tonumber(playerInfo[3]) >= 60) then
                    table.insert(requiredBuffsObtained, buff)
                end
                break
            end
        end
    end
    if (#requiredBuffsObtained >= NrOfRequiredBuffs) then
        DkpManager:singleDkpAddition(sender, BuffBonus, "Buff bonus")
    end
end

local function handleBuffs(msg, msgPrefix, sender)
    if (RequestedInitBuffs == 0) then
        return
    end
    local noPrefixMsg = string.gsub(msg, msgPrefix .. "&", "")
    local currentTime = time()
    local datestamp = date("%d/%m/%Y", currentTime)
    createBuffEntriesIfNeeded(datestamp)
    for buff in string.gmatch(noPrefixMsg, "([^&]+)") do
        addBuff(datestamp, sender, buff)
    end
    --    addDkpForHavingBuffs(datestamp, sender)
end

local function setCreatedBuffCheck(sender)
    if Utils:isSelf(sender) then
        CreatedBuffCheck = true
    else
        CreatedBuffCheck = false
    end
end

local function consumableIsBeingTracked(cons, consList)
    for index, itemTable in pairs(consList) do
        if (itemTable[1] == cons) then
            return true
        end
    end
    return false
end

local function findLootMethod(lootString)
    if (string.find(lootString, "You receive item")) then
        return TRADE
    elseif (string.find(lootString, "You receive loot")) then
        return PICK_UP
    else
        return CREATE
    end
end

local function findItemNumber(lootString)
    local match = string.match(lootString, "x[0-9]*\.")
    if (match) then
        return string.match(match, "%d+")
    end
    return 1
end

local function reactToLoot(lootString, sender)
    if not Utils:isSelf(sender) then
        return
    end

    local lootMethod = findLootMethod(lootString)
    local itemLink = string.match(lootString, "|%x+|Hitem:.-|h.-|h|r")
    local itemName = GetItemInfo(itemLink)
    local consumablesBeingTracked = Consumables:getConsumableList()
    if consumableIsBeingTracked(itemName, consumablesBeingTracked) then
        local itemNumber = findItemNumber(lootString)
        local msg = INIT_UPDATE .. "&" .. itemName .. "&" .. itemNumber
        if (lootMethod == TRADE) then
            msg = msg .. "&" .. TradeTarget
        end
        Utils:sendAddonMsg(msg, "RAID")
    end
end

local function isCurrentlyTracking(date)
    if (JP_Consumables_Log[date] == nil) then
        return false
    end
    local initCheckDone = JP_Consumables_Log[date][INIT_CONS] ~= nil
    local postCheckDone = JP_Consumables_Log[date][POST_CONS] ~= nil
    return initCheckDone and not postCheckDone
end

local function getSenderIndex(table, value)
    for key, val in pairs(table) do
        if (val[1] == value) then
            return key
        end
    end
end

local function updateInit(msg, msgSender)
    local currentTime = time()
    local date = date("%d/%m/%Y", currentTime)
    if not isCurrentlyTracking(date) then
        return
    end

    local prefix, itemName, itemNumber, itemSender = string.split("&", msg)
    local msgSenderIndex = getSenderIndex(JP_Consumables_Log[date][INIT_CONS][itemName], msgSender)
    if (msgSenderIndex == nil) then
        table.insert(JP_Consumables_Log[date][INIT_CONS][itemName], { msgSender, tonumber(itemNumber) })
    else
        local priorItemHoldings = JP_Consumables_Log[date][INIT_CONS][itemName][msgSenderIndex][2]
        JP_Consumables_Log[date][INIT_CONS][itemName][msgSenderIndex][2] = priorItemHoldings + tonumber(itemNumber)
    end

    if (itemSender ~= nil) then
        local itemSenderIndex = getSenderIndex(JP_Consumables_Log[date][INIT_CONS][itemName], itemSender)
        local itemSenderHoldings = JP_Consumables_Log[date][INIT_CONS][itemName][itemSenderIndex][2]
        JP_Consumables_Log[date][INIT_CONS][itemName][itemSenderIndex][2] = itemSenderHoldings - tonumber(itemNumber)
    end
end

function TrackingLog:onEvent(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (event == "CHAT_MSG_ADDON") then
        if (prefix == ADDON_PREFIX) then
            if sender then
                sender = Utils:removeRealmName(sender)
            end
            local msgPrefix = string.split("&", msg)
            if (msgPrefix == INIT_CONS or msgPrefix == POST_CONS) and Utils:isOfficer() then
                insertInLog(msg, msgPrefix, sender)
            elseif (msgPrefix == BUFFS) and Utils:isOfficer() then
                handleBuffs(msg, msgPrefix, sender)
            elseif (msgPrefix == REQUEST_INIT_CONS) then
                sendCons(INIT_CONS)
                sendBuffs()
            elseif (msgPrefix == SHOULD_SAVE_CONS_BUFFS) and Utils:isOfficer() then
                local _, cons, buffs = string.split("&", msg)
                RequestedInitCons = tonumber(cons)
                RequestedInitBuffs = tonumber(buffs)
                setCreatedBuffCheck(sender)
            elseif (msgPrefix == REQUEST_POST_CONS) then
                sendCons(POST_CONS)
            elseif (msgPrefix == CONS_SHARE) and GuildRosterHandler:isOfficer(sender) then
                Consumables:updateConsume(msg)
            elseif (msgPrefix == CONS_CLEAR) and GuildRosterHandler:isOfficer(sender) then
                Consumables:clearCons()
            elseif (msgPrefix == BUFF_CLEAR) and GuildRosterHandler:isOfficer(sender) then
                Buffs:clearBuffs()
            elseif (msgPrefix == BUFF_SHARE) and GuildRosterHandler:isOfficer(sender) then
                Buffs:updateBuff(msg)
            elseif (msgPrefix == INIT_UPDATE) and Utils:isOfficer() then
                updateInit(msg, sender)
            end
        end
    elseif (event == "ADDON_LOADED") and (prefix == ADDON_PREFIX) then
        Consumables:addonLoaded()
        Buffs:addonLoaded()
    elseif (event == "READY_CHECK") then
        sendCons(POST_CONS)
    elseif (event == "CHAT_MSG_LOOT") then
        reactToLoot(prefix, target)
    elseif (event == "TRADE_SHOW") then
        TradeTarget = UnitName("npc")
    end
end

local function sendWhisperRequest(player)
    local msg = REQUEST_INIT_CONS
    if not player then
        player = BrowserSelection:getSelectedPlayer()
        if (player == "") then
            return
        end
    end
    Utils:sendOfficerAddonMsg(msg, "WHISPER", player)
end

function TrackingLog:requestSingleInitBoth(player)
    sendConsBuffStatus(1, 1)
    sendWhisperRequest(player)
end

function TrackingLog:requestSingleInitBuffs(player)
    sendConsBuffStatus(0, 1)
    sendWhisperRequest(player)
end

function TrackingLog:requestSingleInitCons(player)
    sendConsBuffStatus(1, 0)
    sendWhisperRequest(player)
end

function TrackingLog:requestSinglePostCheck(player)
    local msg = REQUEST_POST_CONS
    if not player then
        player = BrowserSelection:getSelectedPlayer()
        if (player == "") then
            return
        end
    end
    Utils:sendOfficerAddonMsg(msg, "WHISPER", player)
end

function TrackingLog:removeConsEntry(date)
    JP_Consumables_Log[date] = nil
end

function TrackingLog:removeBuffEntry(date)
    JP_Buff_Log[date] = nil
end