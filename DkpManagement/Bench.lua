JP_Bench = {}
_G.Bench = {}
local Bench = _G.Bench
local BrowserSelection = _G.BrowserSelection
local MaximumMembersShown = 10
local Utils = _G.Utils

function isBenched(player)
    return JP_Bench[player] ~= nil
end

local function clearBenchEntries()
    for member = 1, MaximumMembersShown, 1 do
        local benchEntry = getglobal("BenchListEntry" .. member)
        getglobal(benchEntry:GetName() .. PLAYER):SetText("")
        benchEntry:Hide()
    end
end

local function updateBenchEntries()
    clearBenchEntries()
    local entryCounter = 1
    for member, class in pairs(JP_Bench) do
        local benchEntry = getglobal("BenchListEntry" .. entryCounter)
        benchEntry:Show()
        getglobal(benchEntry:GetName() .. BACKGROUND):Hide()
        local fontString = getglobal(benchEntry:GetName() .. PLAYER)
        fontString:SetText(member)
        Utils:setClassColor(fontString, class)
        entryCounter = entryCounter + 1
    end
end

local function changeBenchState(player, class)
    if JP_Bench[player] then
        JP_Bench[player] = nil
    else
        JP_Bench[player] = class
    end
    updateBenchEntries()
end

function Bench:getBench()
    return JP_Bench
end

function Bench:removeFromBench(entryId)
    local player = getglobal("BenchListEntry" .. entryId .. PLAYER):GetText()
    changeBenchState(player)
    if BrowserSelection:getSelectedPlayer() == player then
        BrowserSelection:colorBenchButton(player)
    end
end

function Bench:createBenchEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", BenchList, BENCH_ENTRY)
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT")
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, BenchList, BENCH_ENTRY)
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

function Bench:clearBench()
    JP_Bench = {}
    updateBenchEntries()
    getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
end

function Bench:loadBench(event, addonName)
    if addonName == "jpdkp" then
        updateBenchEntries()
    end
end

function Bench:benchPlayer()
    local selectedPlayer = BrowserSelection:getSelectedPlayer()
    changeBenchState(selectedPlayer, GuildRosterHandler:getPlayerClass(selectedPlayer))
    BrowserSelection:colorBenchButton(selectedPlayer)
end