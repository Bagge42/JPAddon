Log_History = {}
_G.Log = {}
local Log = _G.Log
local Utils = _G.Utils
local MaximumMembersShown = 24
local LogIndex = 1

function Log:addEntry(player, change, total, event, class)
    local timestamp = date("%Y/%m/%d %H:%M:%S", time());
    Log_History[table.getn(Log_History) + 1] = { timestamp, player, change, total, event, class }
end

function Log:createEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", LogFrameList, "LogEntry")
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOP", LogFrameListChangeHeader, "BOTTOM", -19.5, 0)
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, LogFrameList, "LogEntry")
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

local function clearEntries()
    for entry = 1, MaximumMembersShown, 1 do
        local listEntry = getglobal("LogFrameListEntry" .. entry)
        getglobal(listEntry:GetName() .. "Time"):SetText("")
        getglobal(listEntry:GetName() .. PLAYER):SetText("")
        getglobal(listEntry:GetName() .. "Change"):SetText("")
        getglobal(listEntry:GetName() .. "Total"):SetText("")
        getglobal(listEntry:GetName() .. "Event"):SetText("")
    end
end

function Log:updateEntries()
    clearEntries()
    for index = 0, MaximumMembersShown - 1, 1 do
        local logEntry = Log_History[LogIndex + index]
        if logEntry then
            local logEntryFrame = getglobal("LogFrameListEntry" .. (index + 1))
            logEntryFrame:Show()
            getglobal(logEntryFrame:GetName() .. "Time"):SetText(logEntry[1])
            local playerFrame = getglobal(logEntryFrame:GetName() .. PLAYER)
            playerFrame:SetText(logEntry[2])
            Utils:setClassColor(playerFrame, logEntry[6])
            getglobal(logEntryFrame:GetName() .. "Change"):SetText(logEntry[3])
            getglobal(logEntryFrame:GetName() .. "Total"):SetText(logEntry[4])
            getglobal(logEntryFrame:GetName() .. "Event"):SetText(logEntry[5])
            --        if name == BrowserSelection:getSelectedPlayer() then
            --            getglobal(listEntry:GetName() .. BACKGROUND):Show()
            --        else
            --            getglobal(listEntry:GetName() .. BACKGROUND):Hide()
            --        end
        else
            break
        end
    end
end

function Log:next()
    LogIndex = LogIndex + MaximumMembersShown
    Log:updateEntries()
end

function Log:previous()
    LogIndex = LogIndex - MaximumMembersShown
    Log:updateEntries()
end

