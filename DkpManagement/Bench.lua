JP_Current_Bench = {}
_G.JP_Bench = {}
local Bench = _G.JP_Bench
local BrowserSelection = _G.JP_BrowserSelection
local GuildRosterHandler = _G.JP_GuildRosterHandler
local MaximumMembersShown = 10
local Utils = _G.JP_Utils

function isBenched(player)
    return JP_Current_Bench[player] ~= nil
end

local function clearBenchEntries()
    for member = 1, MaximumMembersShown, 1 do
        local benchEntry = getglobal("JP_BenchFrameListEntry" .. member)
        getglobal(benchEntry:GetName() .. PLAYER):SetText("")
        benchEntry:Hide()
    end
end

local function updateBenchEntries()
    clearBenchEntries()
    local entryCounter = 1
    for member, class in pairs(JP_Current_Bench) do
        local benchEntry = getglobal("JP_BenchFrameListEntry" .. entryCounter)
        benchEntry:Show()
        getglobal(benchEntry:GetName() .. BACKGROUND):Hide()
        local fontString = getglobal(benchEntry:GetName() .. PLAYER)
        fontString:SetText(member)
        Utils:setClassColor(fontString, class)
        entryCounter = entryCounter + 1
    end
end

local function changeBenchState(player, class)
    if JP_Current_Bench[player] then
        JP_Current_Bench[player] = nil
    else
        JP_Current_Bench[player] = class
    end
    updateBenchEntries()
end

function Bench:getBench()
    return JP_Current_Bench
end

function Bench:removeFromBench(entryId)
    if not Utils:isOfficer() then
        return
    end

    local player = getglobal("JP_BenchFrameListEntry" .. entryId .. PLAYER):GetText()
    changeBenchState(player)
    if BrowserSelection:getSelectedPlayer() == player then
        BrowserSelection:colorBenchButton(player)
    end
    local msg = BENCH_MSG_REMOVE .. "&" .. player
    Utils:sendOfficerAddonMsg(msg, "RAID")
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
        updateBenchEntries()
        if JP_Current_Settings["BenchHidden"] then
            hideBench()
        end
    end
end

function Bench:benchPlayer()
    local selectedPlayer = BrowserSelection:getSelectedPlayer()
    local playerClass = GuildRosterHandler:getPlayerClass(selectedPlayer)
    changeBenchState(selectedPlayer, playerClass)
    local msg = BENCH_MSG_ADD .. "&" .. selectedPlayer .. "&" .. playerClass
    Utils:sendOfficerAddonMsg(msg, "RAID")
    BrowserSelection:colorBenchButton(selectedPlayer)
end

function Bench:onSyncAttempt(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (prefix == ADDON_PREFIX) then
        if Utils:isMsgTypeAndNotFromSelf(msg, BENCH_MSG_ADD, sender) then
            local _, player, class = string.split("&", msg)
            changeBenchState(player, class)
        elseif Utils:isMsgTypeAndNotFromSelf(msg, BENCH_MSG_REMOVE, sender) then
            local _, player = string.split("&", msg)
            if JP_Current_Bench[player] then
                JP_Current_Bench[player] = nil
                updateBenchEntries()
            end
        elseif Utils:isMsgTypeAndNotFromSelf(msg, BENCH_MSG_CLEAR, sender) then
            Bench:clearBench()
        elseif Utils:isMsgTypeAndNotFromSelf(msg, BENCH_MSG_SHARE, sender) then
            Bench:clearBench()
            for name, _ in string.gmatch(msg, "([^&]*)") do
               if (name ~= BENCH_MSG_SHARE) then
                   JP_Current_Bench[name] = true
               end
            end
            updateBenchEntries()
        end
    end
end

function Bench:shareBench()
    local msg = BENCH_MSG_SHARE
    for name, benchValue in pairs(JP_Current_Bench) do
       if benchValue then
          msg = msg .. "&" .. name
       end
    end
    Utils:sendOfficerAddonMsg(msg, "RAID")
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