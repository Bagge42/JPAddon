local Jp = _G.Jp
local GuildRosterHandler = Jp.GuildRosterHandler
local Utils = Jp.Utils
local BrowserSelection = {}
Jp.BrowserSelection = BrowserSelection

local CurrentSelection = ""
local EntryIdOfSelection = 0

function BrowserSelection:selectEntry(entryId)
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
        local playerNameFrame = getglobal(PLAYER_MANAGEMENT .. "PlayerName")
        playerNameFrame:SetText(playerInEntry)
        Utils:setClassColor(playerNameFrame, GuildRosterHandler:getPlayerClass(playerInEntry))
        getglobal(PLAYER_MANAGEMENT .. "Value"):SetFocus()
        getglobal(OUTER_FRAME_LIST_ENTRY .. entryId .. BACKGROUND):Show()
        CurrentSelection = playerInEntry
        BrowserSelection:colorBenchButton(playerInEntry)
        EntryIdOfSelection = entryId
    end
end

function BrowserSelection:isSelected(entryId)
    local playerInEntry = getglobal(OUTER_FRAME_LIST_ENTRY .. entryId .. PLAYER):GetText()
    return playerInEntry == CurrentSelection
end

function BrowserSelection:getSelectedPlayer()
    return CurrentSelection
end

function BrowserSelection:colorBenchButton(selectedPlayer)
    if isBenched(selectedPlayer) then
        getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(0, 1, 0, 0.5)
    else
        getglobal(PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
    end
end
