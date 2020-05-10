local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

local CurrentSelection = ""
local EntryIdOfSelection = 0

local function colorBenchButton(selectedPlayer)
    if isBenched(selectedPlayer) then
        getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(0, 1, 0, 0.5)
    else
        getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
    end
end

function selectEntry(entryId)
    if EntryIdOfSelection ~= 0 then
        getglobal(OUTER_FRAME_LIST_ENTRY .. EntryIdOfSelection .. BACKGROUND):Hide()
    end
    local playerInEntry = getglobal(OUTER_FRAME_LIST_ENTRY .. entryId .. PLAYER):GetText()
    if CurrentSelection == playerInEntry then
        getglobal(PLAYER_MANAGEMENT):Hide()
        CurrentSelection = ""
        EntryIdOfSelection = 0
    else
        getglobal(PLAYER_MANAGEMENT):Show()
        getglobal(PLAYER_MANAGEMENT .. "Value"):SetFocus()
        getglobal(OUTER_FRAME_LIST_ENTRY .. entryId .. BACKGROUND):Show()
        CurrentSelection = playerInEntry
        colorBenchButton(playerInEntry)
        EntryIdOfSelection = entryId
    end
end

function isSelected(entryId)
    local playerInEntry = getglobal(OUTER_FRAME_LIST_ENTRY .. entryId .. PLAYER):GetText()
    return playerInEntry == CurrentSelection
end

function benchPlayer()
    local selectedPlayer = getSelectedPlayer()
    changeBenchState(selectedPlayer)
    colorBenchButton(selectedPlayer)
end

function getSelectedPlayer()
    return CurrentSelection
end

