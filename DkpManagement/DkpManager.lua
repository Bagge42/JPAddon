local Jp = _G.Jp
local Localization = Jp.Localization
local GuildRosterHandler = Jp.GuildRosterHandler
local BrowserSelection = Jp.BrowserSelection
local Utils = Jp.Utils
local Bench = Jp.Bench
local EventQueue = Jp.EventQueue
local Log = Jp.Log
local Settings = Jp.Settings
local Bidding = Jp.Bidding
local DkpManager = {}
Jp.DkpManager = DkpManager

local ButtonIdToIcon = { Localization.ONY_RES, Localization.MC_RES, Localization.BWL_RES, Localization.AQ_RES, Localization.NAXX_RES }
local IdToButton = {}
local RaidIdToName = { Localization.ONY_NAME, Localization.MC_NAME, Localization.BWL_NAME, Localization.AQ_NAME, Localization.NAXX_NAME }
local RaidNameToId = { [Localization.ONY_NAME] = 1, [Localization.MC_NAME] = 2, [Localization.BWL_NAME] = 3, [Localization.AQ_NAME] = 4, [Localization.NAXX_NAME] = 5, }
local RosterAtDecay = {}

local function attachIcons()
    for raidId = 1, 5, 1 do
        local button = IdToButton[raidId]
        button.icon = button:CreateTexture("$parentIcon", "CENTER")
        button.icon:SetAllPoints(button)
        button.icon:SetTexture(ButtonIdToIcon[raidId])
        button.icon:SetTexCoord(0, 0.70, 0, 0.75)
        if Settings:getSetting(RaidIdToName[raidId]) == 0 then
            button.icon:SetDesaturated(1)
        end
    end
end

function DkpManager:settingsLoaded()
    attachIcons()
end

function DkpManager:onLoad()
    getglobal("JP_ManagementTitleFrameClose"):Hide()
    Settings:subscribeToSettingChanges(DkpManager)
end

local function isRaidSetting(settingName)
    for _, raidName in pairs(RaidIdToName) do
        if raidName == settingName then
            return true
        end
    end
    return false
end

function DkpManager:settingChanged(settingName, settingValue)
    if isRaidSetting(settingName) then
        local raidButtonIcon = getglobal("JP_ManagementRaidButton" .. RaidNameToId[settingName] .. "Icon")
        if (settingValue == 0) then
            raidButtonIcon:SetDesaturated(1)
        elseif raidButtonIcon:IsDesaturated() then
            raidButtonIcon:SetDesaturated(false)
        end
    end
end

function DkpManager:createManagementButtons()
    local initialButton = CreateFrame("Button", "$parentRaidButton1", JP_Management, "JP_RaidDkpButton")
    initialButton:SetID(1)
    initialButton:SetPoint("TOPLEFT", JP_Management, "TOPLEFT", 5, -23)
    IdToButton[1] = initialButton

    for raidCount = 2, 5, 1 do
        local raidButton = CreateFrame("Button", "$parentRaidButton" .. raidCount, JP_Management, "JP_RaidDkpButton")
        raidButton:SetID(raidCount)
        raidButton:SetPoint("LEFT", "$parentRaidButton" .. (raidCount - 1), "RIGHT", 3, 0)
        IdToButton[raidCount] = raidButton
    end
    Settings:subscribeToSettings(DkpManager)
end

local function modifyPlayerDkp(name, dkp, event, zone)
    local playerInfo = GuildRosterHandler:getMemberInfo(name)
    local currentDkp = playerInfo[2]
    local newDkp = currentDkp + dkp

    local newOfficerNote = "<" .. newDkp .. ">"
    local guildIndex = GuildRosterHandler:getGuildIndex(name)
    Log:addEntry(name, dkp, newDkp, event, playerInfo[3], zone)
    GuildRosterSetOfficerNote(guildIndex, newOfficerNote)
end

local function getPlayerNamesFromArgsNoDups(roster, bench)
    local playerNames = {}
    for rosterCount = 1, table.getn(roster), 1 do
        playerNames[roster[rosterCount][1]] = true
    end
    for benchPlayer, _ in pairs(bench) do
        playerNames[benchPlayer] = true
    end
    return playerNames
end

local function sendBenchWarning(bench)
    local benchWarning = "Additional players marked as participals: "
    for benchPlayer, _ in pairs(bench) do
        benchWarning = benchWarning .. benchPlayer .. ", "
    end
    benchWarning = benchWarning:sub(1, -3)
    Utils:sendWarningMessage(benchWarning)
end

local function sendRaidDkpWarning(jesusIsInRaid, dkp, nrOfPlayers)
    local warningMessage = ""
    if jesusIsInRaid then
        warningMessage = "Jesus and all " .. (nrOfPlayers - 1)
    else
        warningMessage = "All " .. nrOfPlayers
    end
    warningMessage = warningMessage .. " participals earned " .. dkp .. " DKP"
    if dkp < 0 then
        local name, _ = UnitName("player")
        warningMessage = name .. " had the audacity to pilfer " .. -dkp .. " DKP from jesus and all participating pals"
    end
    Utils:sendWarningMessage(warningMessage)
end

local function modifyRaidDkp(dkp, bench, zone, undo)
    if Utils:selfIsInRaid() then
        local jesusIsInRaid = false
        local playerNames = getPlayerNamesFromArgsNoDups(GuildRosterHandler:getRaidRoster(), bench)
        for player, _ in pairs(playerNames) do
            if undo then
                modifyPlayerDkp(player, dkp, "RaidUndo", zone)
            else
                modifyPlayerDkp(player, dkp, "RaidAdd", zone)
            end
            if player == "Stinkfist" then
                jesusIsInRaid = true
            end
        end
        sendRaidDkpWarning(jesusIsInRaid, dkp, Utils:getSize(playerNames))
        local sizeOfBench = Utils:getSize(bench)
        if sizeOfBench > 0 then
            sendBenchWarning(bench)
        end
    else
        Utils:jpMsg("You must be in a raid!")
    end
end

--local function clearDkp()
--    local roster = GuildRosterHandler:getRoster()
--    for member = 1, table.getn(roster), 1 do
--        local newOfficerNote = "<" .. 0 .. ">"
--        local guildIndex = GuildRosterHandler:getGuildIndex(roster[member][1])
--        GuildRosterSetOfficerNote(guildIndex, newOfficerNote)
--    end
--end

function DkpManager:raidDkpButtonOnClick(id)
    local value = Settings:getSetting(RaidIdToName[id])
    local benchAtClickTime = Utils:copy(Bench:getBench())
    EventQueue:addEvent(function(event) modifyRaidDkp(event[4], event[5], event[3]) end, Localization.UNDO_ACTION_RAIDADD, GetRealZoneText(), value, benchAtClickTime)
end

local function subWarn(player, dkp)
    local warningMessage = "Subtracted " .. dkp .. " DKP from " .. player
    if Utils:selfIsInRaid() then
        Utils:sendWarningMessage(warningMessage)
    else
        Utils:jpMsg(warningMessage)
    end
end

local function addWarn(player, dkp)
    local warningMessage = "Added " .. dkp .. " DKP to " .. player
    if Utils:selfIsInRaid() then
        Utils:sendWarningMessage(warningMessage)
    else
        Utils:jpMsg(warningMessage)
    end
end

local function adjustPlayerDkp(player, dkp, zone, givenEvent)
    local event
    if (givenEvent) then
        event = givenEvent
    else
        event = "Single"
        if dkp < 0 then
            subWarn(player, -dkp)
            event = event .. "Sub"
        else
            addWarn(player, dkp)
            event = event .. "Add"
        end
    end

    modifyPlayerDkp(player, dkp, event, zone)
end

function DkpManager:singleDkpAddition(player, dkp, givenEvent)
    EventQueue:addEvent(function(event) adjustPlayerDkp(event[4], event[5], event[3], event[6]) end, Localization.UNDO_ACTION_ADDED, GetRealZoneText(), player, dkp, givenEvent)
end

function DkpManager:adjustDkpOnClick(id)
    local dkp = getglobal(Localization.PLAYER_MANAGEMENT .. "Value"):GetNumber()
    local playerName = BrowserSelection:getSelectedPlayer()
    if id == 1 then
        EventQueue:addEvent(function(event) adjustPlayerDkp(event[4], event[5], event[3]) end, Localization.UNDO_ACTION_ADDED, GetRealZoneText(), playerName, dkp)
    else
        EventQueue:addEvent(function(event) adjustPlayerDkp(event[4], event[5], event[3]) end, Localization.UNDO_ACTION_SUBBED, GetRealZoneText(), playerName, -dkp)
    end
end

local function decay()
    RosterAtDecay = Utils:copy(GuildRosterHandler:getRoster())
    local rosterSize = table.getn(RosterAtDecay)
    local totalDecayedDkp = 0
    local decayPercentage = Settings:getSetting(Localization.DECAY_SETTING_NAME)
    for member = 1, rosterSize, 1 do
        local memberEntry = RosterAtDecay[member]
        local currentDkp = memberEntry[2]
        local decayedDkp = floor(currentDkp * (decayPercentage / 100))
        if decayedDkp > 0 then
            totalDecayedDkp = totalDecayedDkp + decayedDkp
            modifyPlayerDkp(memberEntry[1], -decayedDkp, "Decay", "Decay")
        else
            Log:addEntry(memberEntry[1], 0, memberEntry[2], "Decay", memberEntry[3], "Decay")
        end
    end
    local actionMsg = UnitName("player") .. " performed a " .. decayPercentage .. "% DKP decay."
    Utils:sendGuildMessage(actionMsg)
    local amountMsg = "A total of " .. totalDecayedDkp .. " DKP was subtracted from " .. rosterSize .. " players."
    Utils:sendGuildMessage(amountMsg)
end

local function setDkp(playerInfo)
    local dkpAfterUndo = playerInfo[2]
    local playerName = playerInfo[1]
    local newOfficerNote = "<" .. dkpAfterUndo .. ">"
    local dkpBeforeUndo = GuildRosterHandler:getMemberInfo(playerName)[2]
    local guildIndex = GuildRosterHandler:getGuildIndex(playerName)
    Log:addEntry(playerName, dkpAfterUndo - dkpBeforeUndo, dkpAfterUndo, "DecayUndo", playerInfo[3], "Decay")
    GuildRosterSetOfficerNote(guildIndex, newOfficerNote)
end

local function undoDecay()
    for member = 1, table.getn(RosterAtDecay), 1 do
        local rosterEntry = RosterAtDecay[member]
        setDkp(rosterEntry)
    end
    local actionMsg = UnitName("player") .. " undid the decay, all dkp has been restored."
    Utils:sendGuildMessage(actionMsg)
end

local function singlePlayerUndo(player, amount, zone)
    local event = "Single"
    if amount < 0 then
        event = event .. "Add"
        subWarn(player, -amount)
    else
        event = event .. "Sub"
        addWarn(player, amount)
    end
    event = event .. "Undo"
    modifyPlayerDkp(player, amount, event, zone)
end

local function raidUndo(dkp, bench, zone)
    modifyRaidDkp(dkp, bench, zone, true)
end

function DkpManager:undo()
    local latestQueuedEvent = EventQueue:getLatestQueuedEvent()
    if latestQueuedEvent == nil then
        return
    end
    local nameOfLatestQueuedEvent = latestQueuedEvent[2]
    if nameOfLatestQueuedEvent == Localization.UNDO_ACTION_SUBBED then
        EventQueue:addEvent(function(event) singlePlayerUndo(event[4], event[5], event[3]) end, nil, latestQueuedEvent[3], latestQueuedEvent[4], -latestQueuedEvent[5])
    elseif nameOfLatestQueuedEvent == Localization.UNDO_ACTION_ADDED then
        EventQueue:addEvent(function(event) singlePlayerUndo(event[4], event[5], event[3]) end, nil, latestQueuedEvent[3], latestQueuedEvent[4], -latestQueuedEvent[5])
    elseif nameOfLatestQueuedEvent == Localization.UNDO_ACTION_DECAY then
        EventQueue:addEvent(function() undoDecay() end, nil, "Decay")
    elseif nameOfLatestQueuedEvent == Localization.UNDO_ACTION_RAIDADD then
        EventQueue:addEvent(function(event) raidUndo(event[4], event[5], event[3]) end, nil, latestQueuedEvent[3], -latestQueuedEvent[4], latestQueuedEvent[5])
    end
end

function DkpManager:resetPlayerEditBox()
    Bidding:stopBiddingRound()
    local editBox = getglobal(Localization.PLAYER_MANAGEMENT .. "Value")
    editBox:SetNumber("")
    editBox:ClearFocus()
end

function DkpManager:addDecayEvent()
    EventQueue:addEvent(function() decay() end, Localization.UNDO_ACTION_DECAY, "Decay")
end

function DkpManager:createDkpSnapshot()
    local guildRoster = GuildRosterHandler:getRoster()
    local zone = GetRealZoneText()
    for memberCount = 1, table.getn(guildRoster), 1 do
        local memberInfo = guildRoster[memberCount]
        Log:addEntry(memberInfo[1], 0, memberInfo[2], "Snapshot", memberInfo[3], zone)
    end
end