local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

local ButtonIdToIcon = { "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Onyxia", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-MoltenCore", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-BlackwingLair", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-TempleofAhnQiraj", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Naxxramas" }
local IdToButton = {}
local RaidIdToName = { "Ony", "MC", "BWL", "AQ", "Naxx" }
local RaidDkpValues = { ["Ony"] = 12, ["MC"] = 33, ["BWL"] = 27, ["AQ"] = 0, ["Naxx"] = 0 }
local DecayPercentage = 20

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

function createManagementButtons()
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
    local playerInfo = GuildRosterHandler:getMemberInfo(name);
    local currentDkp = playerInfo[2]
    local newDkp = currentDkp + dkp

    local warningMessage = ""
    if dkp < 0 then
        warningMessage = "Subtracted " .. -dkp .. " DKP from " .. name
        singlePlayerAction(UNDO_ACTION_SUBBED, name, dkp)
    else
        warningMessage = "Added " .. dkp .. " DKP to " .. name
        singlePlayerAction(UNDO_ACTION_ADDED, name, dkp)
    end
    sendWarningMessage(warningMessage)

    local newOfficerNote = "<" .. newDkp .. ">"
    local guildIndex = GuildRosterHandler:getGuildIndex(name)
    GuildRosterSetOfficerNote(guildIndex, newOfficerNote);
end

local function modifyRaidDkp(dkp)
    if isInRaid(true) then
        local raidRoster = getRaidRoster()
        for raider = 1, table.getn(raidRoster), 1 do
            modifyPlayerDkp(raidRoster[raider][1], dkp)
        end
        raidAddAction(dkp)
        local warningMessage = "Jesus and all participating pals earned " .. dkp .. " DKP"
        sendWarningMessage(warningMessage)
    end
end

local function clearDkp()
    local roster = GuildRosterHandler:getRoster()
    for member = 1, table.getn(roster), 1 do
        local newOfficerNote = "<" .. 0 .. ">"
        local guildIndex = GuildRosterHandler:getGuildIndex(roster[member][1])
        GuildRosterSetOfficerNote(guildIndex, newOfficerNote);
    end
end

function raidDkpButtonOnClick(id)
    if id == 5 then
        clearDkp()
    end
    local value = RaidDkpValues[RaidIdToName[id]]
    modifyRaidDkp(value)
end

local function adjustPlayerDkp(neg)
    local dkp = getglobal(PLAYER_MANAGEMENT .. "Value"):GetNumber()
    if neg then
        dkp = -dkp
    end
    local playerName = getSelectedPlayer()
    modifyPlayerDkp(playerName, dkp)
end

function adjustDkpOnClick(id)
    if id == 1 then
        adjustPlayerDkp(false)
    else
        adjustPlayerDkp(true)
    end
end

function decay()
    local roster = GuildRosterHandler:getRoster()
    local totalDecayedDkp = 0
    for member = 1, table.getn(roster), 1 do
        local memberEntry = roster[member]
        local currentDkp = memberEntry[2]
        local decayedDkp = floor(currentDkp * (DecayPercentage / 100))
        if decayedDkp > 0 then
            totalDecayedDkp = totalDecayedDkp + decayedDkp
            modifyPlayerDkp(memberEntry[1], -decayedDkp)
        end
    end
end