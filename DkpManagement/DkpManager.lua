_G.DkpManager = {}
local DkpManager = _G.DkpManager
local GuildRosterHandler = _G.GuildRosterHandler
local BrowserSelection = _G.BrowserSelection
local Utils = _G.Utils
local Bench = _G.Bench
local EventQueue = _G.EventQueue

local ButtonIdToIcon = { "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Onyxia", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-MoltenCore", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-BlackwingLair", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-TempleofAhnQiraj", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Naxxramas" }
local IdToButton = {}
local RaidIdToName = { "Ony", "MC", "BWL", "AQ", "Naxx" }
local RaidDkpValues = { ["Ony"] = 12, ["MC"] = 33, ["BWL"] = 27, ["AQ"] = 0, ["Naxx"] = 0 }
local DecayPercentage = 20
local RosterAtDecay = {}

local function attachIcons()
    for raidId = 1, 5, 1 do
        local button = IdToButton[raidId]
        button.icon = button:CreateTexture("$parentIcon", "CENTER")
        button.icon:SetAllPoints(button)
        button.icon:SetTexture(ButtonIdToIcon[raidId])
        button.icon:SetTexCoord(0, 0.70, 0, 0.75)
        if RaidDkpValues[RaidIdToName[raidId]] == 0 then
            button.icon:SetDesaturation(1)
        end
    end
end

function DkpManager:createManagementButtons()
    local initialButton = CreateFrame("Button", "$parentRaidButton1", Management, "RaidDkpButton")
    initialButton:SetID(1)
    initialButton:SetPoint("TOPLEFT", Management, "TOPLEFT", 5, -23)
    IdToButton[1] = initialButton

    for raidCount = 2, 5, 1 do
        local raidButton = CreateFrame("Button", "$parentRaidButton" .. raidCount, Management, "RaidDkpButton")
        raidButton:SetID(raidCount)
        raidButton:SetPoint("LEFT", "$parentRaidButton" .. (raidCount - 1), "RIGHT", 3, 0)
        IdToButton[raidCount] = raidButton
    end
    attachIcons()
end

local function modifyPlayerDkp(name, dkp)
    local playerInfo = GuildRosterHandler:getMemberInfo(name)
    local currentDkp = playerInfo[2]
    local newDkp = currentDkp + dkp

    local newOfficerNote = "<" .. newDkp .. ">"
    local guildIndex = GuildRosterHandler:getGuildIndex(name)
    GuildRosterSetOfficerNote(guildIndex, newOfficerNote)
end

local function collectPlayerNamesFromTablesNoDubs(roster, bench)
    local playerNames = {}
    for rosterCount = 1, table.getn(roster), 1 do
        playerNames[roster[rosterCount][1]] = true
    end
    for benchPlayer, _ in pairs(bench) do
        playerNames[benchPlayer] = true
    end
    return playerNames
end

local function modifyRaidDkp(dkp, bench)
    if Utils:isInRaid() then
        local playerNames = collectPlayerNamesFromTablesNoDubs(GuildRosterHandler:getRaidRoster(), bench)
        for player, _ in pairs(playerNames) do
            modifyPlayerDkp(player, dkp)
        end
        local warningMessage = "Jesus and all participals earned " .. dkp .. " DKP"
        if dkp < 0 then
            local name, _ = UnitName("player")
            warningMessage = name .. " had the audacity to pilfer " .. -dkp .. " DKP from jesus and all participating pals"
        end
        Utils:sendWarningMessage(warningMessage)
    else
        Utils:jpMsg("You must be in a raid!")
    end
end

local function clearDkp()
    local roster = GuildRosterHandler:getRoster()
    for member = 1, table.getn(roster), 1 do
        local newOfficerNote = "<" .. 0 .. ">"
        local guildIndex = GuildRosterHandler:getGuildIndex(roster[member][1])
        GuildRosterSetOfficerNote(guildIndex, newOfficerNote)
    end
end

function DkpManager:raidDkpButtonOnClick(id)
    if id == 5 then
       wtf()
    end
    local value = RaidDkpValues[RaidIdToName[id]]
    local benchAtClickTime = Utils:copyTable(Bench:getBench())
    EventQueue:addEvent(function(event) modifyRaidDkp(event[3], event[4]) end, UNDO_ACTION_RAIDADD, value, benchAtClickTime)
end

local function subWarn(player, dkp)
    local warningMessage = "Subtracted " .. dkp .. " DKP from " .. player
    if Utils:isInRaid() then
        Utils:sendWarningMessage(warningMessage)
    else
        Utils:jpMsg(warningMessage)
    end
end

local function addWarn(player, dkp)
    local warningMessage = "Added " .. dkp .. " DKP to " .. player
    if Utils:isInRaid() then
        Utils:sendWarningMessage(warningMessage)
    else
        Utils:jpMsg(warningMessage)
    end
end

local function adjustPlayerDkp(player, dkp)
    if dkp < 0 then
        subWarn(player, -dkp)
    else
        addWarn(player, dkp)
    end

    modifyPlayerDkp(player, dkp)
end

function DkpManager:adjustDkpOnClick(id)
    local dkp = getglobal(PLAYER_MANAGEMENT .. "Value"):GetNumber()
    local playerName = BrowserSelection:getSelectedPlayer()
    if id == 1 then
        EventQueue:addEvent(function(event) adjustPlayerDkp(event[3], event[4]) end, UNDO_ACTION_ADDED, playerName, dkp)
    else
        EventQueue:addEvent(function(event) adjustPlayerDkp(event[3], event[4]) end, UNDO_ACTION_SUBBED, playerName, -dkp)
    end
end

local function decay()
    RosterAtDecay = Utils:copyTable(GuildRosterHandler:getRoster())
    local rosterSize = table.getn(RosterAtDecay)
    local totalDecayedDkp = 0
    for member = 1, rosterSize, 1 do
        local memberEntry = RosterAtDecay[member]
        local currentDkp = memberEntry[2]
        local decayedDkp = floor(currentDkp * (DecayPercentage / 100))
        if decayedDkp > 0 then
            totalDecayedDkp = totalDecayedDkp + decayedDkp
            modifyPlayerDkp(memberEntry[1], -decayedDkp)
        end
    end
    local actionMsg = UnitName("player") .. " performed a " .. DecayPercentage .. "% DKP decay."
    Utils:sendGuildMessage(actionMsg)
    local amountMsg = "A total of " .. totalDecayedDkp .. " DKP was subtracted from " .. rosterSize .. " players."
    Utils:sendGuildMessage(amountMsg)
end

local function setDkp(player, dkp)
    local newOfficerNote = "<" .. dkp .. ">"
    local guildIndex = GuildRosterHandler:getGuildIndex(player)
    GuildRosterSetOfficerNote(guildIndex, newOfficerNote)
end

local function undoDecay()
    for member = 1, table.getn(RosterAtDecay), 1 do
        local rosterEntry = RosterAtDecay[member]
        setDkp(rosterEntry[1], rosterEntry[2])
    end
    local actionMsg = UnitName("player") .. " undid the decay, all dkp has been restored."
    Utils:sendGuildMessage(actionMsg)
end

local function singlePlayerUndo(player, amount)
    modifyPlayerDkp(player, amount)
    if amount < 0 then
        subWarn(player, -amount)
    else
        addWarn(player, amount)
    end
end

function DkpManager:undo()
    local latestQueuedEvent = EventQueue:getLatestQueuedEvent()
    if latestQueuedEvent == nil then
        return
    end
    local nameOfLatestQueuedEvent = latestQueuedEvent[2]
    if nameOfLatestQueuedEvent == UNDO_ACTION_SUBBED then
        EventQueue:addEvent(function(event) singlePlayerUndo(event[3], event[4]) end, nil, latestQueuedEvent[3], -latestQueuedEvent[4])
    elseif nameOfLatestQueuedEvent == UNDO_ACTION_ADDED then
        EventQueue:addEvent(function(event) singlePlayerUndo(event[3], event[4]) end, nil, latestQueuedEvent[3], -latestQueuedEvent[4])
    elseif nameOfLatestQueuedEvent == UNDO_ACTION_DECAY then
        EventQueue:addEvent(function() undoDecay() end, nil)
    elseif nameOfLatestQueuedEvent == UNDO_ACTION_RAIDADD then
        EventQueue:addEvent(function(event) modifyRaidDkp(event[3], event[4]) end, nil, -latestQueuedEvent[3], latestQueuedEvent[4])
    end
end

function DkpManager:resetPlayerEditBox()
    getglobal(PLAYER_MANAGEMENT .. "Value"):SetNumber("")
end

function DkpManager:addDecayEvent()
    EventQueue:addEvent(function() decay() end, UNDO_ACTION_DECAY)
end

function wtf()
    print("-- DkpManager --")
    printda(DkpManager)
    print("-- GuildRosterHandler --")
    printda(GuildRosterHandler)
    print("-- BrowserSelection --")
    printda(BrowserSelection)
    print("-- Utils --")
    printda(Utils)
    print("-- Bench --")
    printda(Bench)
    print("-- EventQueue --")
    printda(EventQueue)
end

function printda(fd)
    for k,v in pairs(fd) do
        print(type(v))
    end
end