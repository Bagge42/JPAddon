JP_Current_Bench = {}
local Jp = _G.Jp
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

function Bench:printBench()
    for name, class in pairs(JP_Current_Bench) do
        print(name)
        print(class)
    end
end

local function clearBenchEntries()
    for member = 1, MaximumMembersShown, 1 do
        local benchEntry = getglobal("JP_BenchFrameListEntry" .. member)
        getglobal(benchEntry:GetName() .. PLAYER):SetText("")
        benchEntry:Hide()
    end
end

local function getSortedBench()
    local sortedBench = {}

    for member, _ in pairs(JP_Current_Bench) do
        sortedBench[#sortedBench + 1] = member
    end
    table.sort(sortedBench, function(member1, member2)
        return member1 < member2
    end)

    return sortedBench
end

local function updateBenchEntries()
    clearBenchEntries()
    local entryCounter = 1
    local sortedBench = getSortedBench()
    for memberIndex = BenchIndex, #sortedBench, 1 do
        if entryCounter > MaximumMembersShown then
            return
        end
        local benchEntry = getglobal("JP_BenchFrameListEntry" .. entryCounter)
        benchEntry:Show()
        getglobal(benchEntry:GetName() .. BACKGROUND):Hide()
        local fontString = getglobal(benchEntry:GetName() .. PLAYER)
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
    if (BenchIndex + 1 <= #getSortedBench() - MaximumMembersShown) then
        BenchIndex = BenchIndex + 1
    end
end

local function benchLimitReached(playerToAdd)
    local benchLength = string.len(BENCH_MSG_SHARE)
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

    local player = getglobal("JP_BenchFrameListEntry" .. entryId .. PLAYER):GetText()
    if changeBenchState(player) then
        if BrowserSelection:getSelectedPlayer() == player then
            BrowserSelection:colorBenchButton(player)
        end
        local msg = BENCH_MSG_REMOVE .. "&" .. player
        Utils:sendOfficerAddonMsg(msg, "RAID")
    end
end

function Bench:createBenchEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", JP_BenchFrameList, BENCH_ENTRY)
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT")
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, JP_BenchFrameList, BENCH_ENTRY)
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

function Bench:clearBench()
    JP_Current_Bench = {}
    BenchIndex = 1
    updateBenchEntries()
    getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
end

function Bench:sendClearBenchMsg()
    local msg = BENCH_MSG_CLEAR
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
        local msg = BENCH_MSG_ADD .. "&" .. selectedPlayer .. "&" .. playerClass
        Utils:sendOfficerAddonMsg(msg, "RAID")
        BrowserSelection:colorBenchButton(selectedPlayer)
    end
end

local function requestUpdate()
    local msg = BENCH_MSG_REQUEST
    Utils:sendAddonMsg(msg, "RAID")
end

local function sendBench(target)
    local msg = BENCH_MSG_SHARE
    for name, _ in pairs(JP_Current_Bench) do
        msg = msg .. "&" .. name
    end
    Utils:sendAddonMsg(msg, "WHISPER", target)
end

local function onSyncAttempt(prefix, msg, sender)
    if (prefix == ADDON_PREFIX) then
        if Utils:isSelf(sender) then
            return
        end

        if Utils:isMsgType(msg, BENCH_MSG_ADD) then
            local _, player, class = string.split("&", msg)
            changeBenchState(player, class)
        elseif Utils:isMsgType(msg, BENCH_MSG_REMOVE) then
            local _, player = string.split("&", msg)
            if JP_Current_Bench[player] then
                JP_Current_Bench[player] = nil
                updateBenchEntries()
            end
        elseif Utils:isMsgType(msg, BENCH_MSG_CLEAR) then
            Bench:clearBench()
        elseif Utils:isMsgType(msg, BENCH_MSG_REQUEST) then
            if (Utils:getTableSize(JP_Current_Bench) > 0) then
                sendBench(sender)
            end
        elseif Utils:isMsgType(msg, BENCH_MSG_SHARE) then
            Bench:clearBench()
            for name, _ in string.gmatch(msg, "([^&]*)") do
                if (name ~= BENCH_MSG_SHARE) then
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
    if (BenchIndex + delta > #getSortedBench() - MaximumMembersShown + 1) then
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