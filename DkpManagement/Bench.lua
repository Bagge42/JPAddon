JP_Bench = {}
local MaximumMembersShown = 10

function isBenched(player)
    return JP_Bench[player] ~= nil
end

function changeBenchState(player, class)
    if JP_Bench[player] then
        JP_Bench[player] = nil
    else
        JP_Bench[player] = class
    end
    updateBenchEntries()
end

function getBench()
    return JP_Bench
end

function removeFromBench(entryId)
    local player = getglobal("BenchListEntry" .. entryId .. PLAYER):GetText()
    changeBenchState(player)
    if getSelectedPlayer() == player then
        colorBenchButton(player)
    end
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
    for member, class in pairs(JP_Bench) do
        local benchEntry = getglobal("BenchListEntry" .. entryCounter)
        benchEntry:Show()
        getglobal(benchEntry:GetName() .. BACKGROUND):Hide()
        local fontString = getglobal(benchEntry:GetName() .. PLAYER)
        fontString:SetText(member)
        setClassColor(fontString, class)
        entryCounter = entryCounter + 1
    end
end

function clearBench()
    JP_Bench = {}
    updateBenchEntries()
    getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
end

function loadBench(event, addonName)
    if addonName == "jpdkp" then
        updateBenchEntries()
    end
end