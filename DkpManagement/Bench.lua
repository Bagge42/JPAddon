JP_Current_Bench = {}
local Jp = _G.Jp
local Localization = Jp.Localization
local BrowserSelection = Jp.BrowserSelection
local GuildRosterHandler = Jp.GuildRosterHandler
local Utils = Jp.Utils
local Bench = {}
Jp.Bench = Bench

local MaximumMembersShown = 9
local BenchIndex = 1
local MessageLimit = 255

function isBenched(player)
    return JP_Current_Bench[player] ~= nil
end

local function updateBenchEntries()
    Utils:clearEntries("JP_BenchFrameListEntry", MaximumMembersShown, Localization.PLAYER)
    local entryCounter = 1
    local sortedBench = Utils:getTableWithKeysAsValuesSorted(JP_Current_Bench)
    for memberIndex = BenchIndex, #sortedBench, 1 do
        if entryCounter > MaximumMembersShown then
            return
        end
        local benchEntry = getglobal("JP_BenchFrameListEntry" .. entryCounter)
        benchEntry:Show()
        getglobal(benchEntry:GetName() .. Localization.BACKGROUND):Hide()
        local fontString = getglobal(benchEntry:GetName() .. Localization.PLAYER)
        fontString:SetText(sortedBench[memberIndex])
        Utils:setClassColor(fontString, JP_Current_Bench[sortedBench[memberIndex]])
        entryCounter = entryCounter + 1
    end
end

local function decrementIndexIfNeeded()
    if (BenchIndex > 1) then
        BenchIndex = BenchIndex - 1
    end
end

local function incrementIndexIfNeeded()
    if (BenchIndex + 1 <= Utils:getSize(JP_Current_Bench) - MaximumMembersShown) then
        BenchIndex = BenchIndex + 1
    end
end

local function benchLimitReached(playerToAdd)
    local benchLength = string.len(Localization.BENCH_MSG_SHARE)
    for player, _ in pairs(JP_Current_Bench) do
        benchLength = benchLength + string.len(player) + 1
    end
    if (benchLength + string.len(playerToAdd) + 1 > MessageLimit) then
        Utils:jpMsg("You are prohibited from adding more players to the bench, as adding more players will make it impossible to synchronize the bench properly.")
        return true
    end
    return false
end

local function changeBenchState(player, class)
    if JP_Current_Bench[player] then
        JP_Current_Bench[player] = nil
        decrementIndexIfNeeded()
    else
        if not benchLimitReached(player) then
            JP_Current_Bench[player] = class
            incrementIndexIfNeeded()
        else
            return
        end
    end
    updateBenchEntries()
    return true
end

function Bench:getBench()
    return JP_Current_Bench
end

function Bench:removeFromBench(entryId)
    if not Utils:isOfficer() then
        return
    end

    local player = getglobal("JP_BenchFrameListEntry" .. entryId .. Localization.PLAYER):GetText()
    if changeBenchState(player) then
        if BrowserSelection:getSelectedPlayer() == player then
            BrowserSelection:colorBenchButton(player)
        end
        local msg = Localization.BENCH_MSG_REMOVE .. "&" .. player
        Utils:sendOfficerAddonMsg(msg, "RAID")
    end
end

function Bench:getMaximumMembersShown()
    return MaximumMembersShown
end

function Bench:clearBench()
    JP_Current_Bench = {}
    BenchIndex = 1
    updateBenchEntries()
    getglobal(Localization.PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
end

function Bench:sendClearBenchMsg()
    local msg = Localization.BENCH_MSG_CLEAR
    Utils:sendOfficerAddonMsg(msg, "RAID")
end

local function hideBench()
    getglobal("JP_BenchFrame"):Hide()
    getglobal("JP_OuterFrame"):SetSize(566, 300)
    getglobal("JP_OuterFrameTitleFrame"):SetSize(566, 24)
    JP_Current_Settings["BenchHidden"] = true
end

function Bench:loadBench(event, addonName)
    if addonName == "jpdkp" then
        if not IsInGroup() then
            Bench:clearBench()
        else
            updateBenchEntries()
        end
        if JP_Current_Settings["BenchHidden"] then
            hideBench()
        end
    end
end

function Bench:benchPlayer()
    local selectedPlayer = BrowserSelection:getSelectedPlayer()
    local playerClass = GuildRosterHandler:getPlayerClass(selectedPlayer)
    if changeBenchState(selectedPlayer, playerClass) then
        local msg = Localization.BENCH_MSG_ADD .. "&" .. selectedPlayer .. "&" .. playerClass
        Utils:sendOfficerAddonMsg(msg, "RAID")
        BrowserSelection:colorBenchButton(selectedPlayer)
    end
end

local function requestUpdate()
    local msg = Localization.BENCH_MSG_REQUEST
    Utils:sendAddonMsg(msg, "RAID")
end

local function sendBench(target)
    local msg = Localization.BENCH_MSG_SHARE
    for name, _ in pairs(JP_Current_Bench) do
        msg = msg .. "&" .. name
    end
    Utils:sendAddonMsg(msg, "WHISPER", target)
end

local function onSyncAttempt(prefix, msg, sender)
    if (prefix == Localization.ADDON_PREFIX) then
        if Utils:isSelfRemoveRealm(sender) then
            return
        end

        if Utils:isMsgType(msg, Localization.BENCH_MSG_ADD) then
            local _, player, class = string.split("&", msg)
            changeBenchState(player, class)
        elseif Utils:isMsgType(msg, Localization.BENCH_MSG_REMOVE) then
            local _, player = string.split("&", msg)
            if JP_Current_Bench[player] then
                JP_Current_Bench[player] = nil
                updateBenchEntries()
            end
        elseif Utils:isMsgType(msg, Localization.BENCH_MSG_CLEAR) then
            Bench:clearBench()
        elseif Utils:isMsgType(msg, Localization.BENCH_MSG_REQUEST) then
            if (Utils:getSize(JP_Current_Bench) > 0) then
                sendBench(sender)
            end
        elseif Utils:isMsgType(msg, Localization.BENCH_MSG_SHARE) then
            Bench:clearBench()
            for name, _ in string.gmatch(msg, "([^&]*)") do
                if (name ~= Localization.BENCH_MSG_SHARE) then
                    local class = GuildRosterHandler:getPlayerClass(name)
                    JP_Current_Bench[name] = class
                end
            end
            updateBenchEntries()
        end
    end
end

function Bench:onEvent(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (event == "CHAT_MSG_ADDON") then
        onSyncAttempt(prefix, msg, sender)
    elseif (event == "GROUP_JOINED") then
        Bench:clearBench()
        requestUpdate()
    elseif (event == "GROUP_LEFT") then
        Bench:clearBench()
    end
end

function Bench:showHideBench()
    if not getglobal("JP_BenchFrame"):IsVisible() then
        getglobal("JP_BenchFrame"):Show()
        getglobal("JP_OuterFrame"):SetSize(651, 300)
        getglobal("JP_OuterFrameTitleFrame"):SetSize(651, 24)
        JP_Current_Settings["BenchHidden"] = false
    else
        hideBench()
    end
end

local function newIndexIsValid(delta)
    if (BenchIndex == 1) and (delta < 0) then
        return false
    end
    if (BenchIndex + delta > Utils:getSize(JP_Current_Bench) - MaximumMembersShown + 1) then
        return false
    end
    return true
end

function Bench:onMouseWheel(delta)
    local negativeDelta = -delta
    if newIndexIsValid(negativeDelta) then
        BenchIndex = BenchIndex + negativeDelta
        updateBenchEntries()
    end
end