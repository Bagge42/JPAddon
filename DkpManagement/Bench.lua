local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

local Bench = {}
local MaximumMembersShown = 10

function isBenched(player)
    return Bench[player] == true
end

function changeBenchState(player)
    if Bench[player] then
        Bench[player] = nil
    else
        Bench[player] = true
    end
    updateBenchEntries()
end

function getBench()
    return Bench
end

function removeFromBench(entryId)
    local player = getglobal("BenchListEntry" .. entryId .. PLAYER):GetText()
    changeBenchState(player)
    colorBenchButton(player)
end

function createBenchEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", BenchList, BENCH_ENTRY)
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT")
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, BenchList, BENCH_ENTRY)
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

local function clearBenchEntries()
    for member = 1, MaximumMembersShown, 1 do
        local benchEntry = getglobal("BenchListEntry" .. member)
        getglobal(benchEntry:GetName() .. PLAYER):SetText("")
        benchEntry:Hide()
    end
end

function updateBenchEntries()
    clearBenchEntries()
    local entryCounter = 1
    for member, _ in pairs(Bench) do
        local benchEntry = getglobal("BenchListEntry" .. entryCounter)
        benchEntry:Show()
        getglobal(benchEntry:GetName() .. BACKGROUND):Hide()
        local fontString = getglobal(benchEntry:GetName() .. PLAYER)
        fontString:SetText(member)
        setClassColor(fontString, GuildRosterHandler:getPlayerClass(member))
        entryCounter = entryCounter + 1
    end
end

function clearBench()
    Bench = {}
    updateBenchEntries()
    getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
end