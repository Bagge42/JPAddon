local Jp = _G.Jp
local Localization = Jp.Localization
local GuildRosterHandler = Jp.GuildRosterHandler
local Utils = Jp.Utils
local Bidding = Jp.Bidding
local BrowserSelection = {}
Jp.BrowserSelection = BrowserSelection

local CurrentSelection = ""
local EntryIdOfSelection = 0

local function setTrackingButtonsText(playerInEntry)
    getglobal("JP_TrackingFrameTrackingTabSingleInitCons"):SetText(Localization.SINGLE_INIT_CONS_CHECK_BUTTON_TEXT .. "\n" .. playerInEntry)
    getglobal("JP_TrackingFrameTrackingTabSingleInitBuff"):SetText(Localization.SINGLE_INIT_BUFF_CHECK_BUTTON_TEXT .. "\n" .. playerInEntry)
    getglobal("JP_TrackingFrameTrackingTabSingleInitBoth"):SetText(Localization.SINGLE_INIT_CHECK_BUTTON_TEXT .. "\n" .. playerInEntry)
    getglobal("JP_TrackingFrameTrackingTabSinglePost"):SetText(Localization.SINGLE_POST_CHECK_BUTTON_TEXT .. "\n" .. playerInEntry)
end

function BrowserSelection:setTrackingButtonsTextEmpty()
    local emptyText = Localization.SINGLE_CHECK_BUTTON_TEXT_EMPTY
    getglobal("JP_TrackingFrameTrackingTabSingleInitCons"):SetText(emptyText)
    getglobal("JP_TrackingFrameTrackingTabSingleInitBuff"):SetText(emptyText)
    getglobal("JP_TrackingFrameTrackingTabSingleInitBoth"):SetText(emptyText)
    getglobal("JP_TrackingFrameTrackingTabSinglePost"):SetText(emptyText)
end

function BrowserSelection:selectEntry(entryId)
    if EntryIdOfSelection ~= 0 then
        getglobal(Localization.OUTER_FRAME_LIST_ENTRY .. EntryIdOfSelection .. Localization.BACKGROUND):Hide()
    end
    local playerInEntry = getglobal(Localization.OUTER_FRAME_LIST_ENTRY .. entryId .. Localization.PLAYER):GetText()
    if CurrentSelection == playerInEntry then
        getglobal(Localization.PLAYER_MANAGEMENT):Hide()
        CurrentSelection = ""
        EntryIdOfSelection = 0
        BrowserSelection:setTrackingButtonsTextEmpty()
    else
        getglobal(Localization.PLAYER_MANAGEMENT):Show()
        local playerNameFrame = getglobal(Localization.PLAYER_MANAGEMENT .. "PlayerName")
        playerNameFrame:SetText(playerInEntry)
        setTrackingButtonsText(playerInEntry)
        Utils:setClassColor(playerNameFrame, GuildRosterHandler:getPlayerClass(playerInEntry))
        getglobal(Localization.PLAYER_MANAGEMENT .. "Value"):SetFocus()
        Bidding:setBidInPlayerManagement(playerInEntry)
        getglobal(Localization.OUTER_FRAME_LIST_ENTRY .. entryId .. Localization.BACKGROUND):Show()
        CurrentSelection = playerInEntry
        BrowserSelection:colorBenchButton(playerInEntry)
        EntryIdOfSelection = entryId
    end
end

function BrowserSelection:isSelected(entryId)
    local playerInEntry = getglobal(Localization.OUTER_FRAME_LIST_ENTRY .. entryId .. Localization.PLAYER):GetText()
    return playerInEntry == CurrentSelection
end

function BrowserSelection:getSelectedPlayer()
    return CurrentSelection
end

function BrowserSelection:colorBenchButton(selectedPlayer)
    if isBenched(selectedPlayer) then
        getglobal(Localization.PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(0, 1, 0, 0.5)
    else
        getglobal(Localization.PLAYER_MANAGEMENT .. "QueueText"):SetTextColor(1, 0, 0, 0.7)
    end
end
