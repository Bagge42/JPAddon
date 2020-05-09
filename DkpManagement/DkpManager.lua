local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

local ButtonIdToIcon = { "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Onyxia", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-MoltenCore", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-BlackwingLair", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-TempleofAhnQiraj", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Naxxramas" }
local IdToButton = {}
local RaidIdToName = { "Ony", "MC", "BWL", "AQ", "Naxx" }
local RaidDkpValues = { ["Ony"] = 12, ["MC"] = 33, ["BWL"] = 27, ["AQ"] = 0, ["Naxx"] = 1 }

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

local function getRaidRoster()
    local playersInRaid = GetNumGroupMembers()

    local raidRosterTable = {}
    if playersInRaid then
        for playerCount = 1, playersInRaid, 1 do
            local name, _, _, _, _ = GetRaidRosterInfo(playerCount)
            local playerInfo = GuildRosterHandler:getMemberInfo(name)
            raidRosterTable[playerCount] = playerInfo
        end
    end

    return raidRosterTable
end

local function modifyPlayerDkp(name, dkp)
    local playerInfo = GuildRosterHandler:getMemberInfo(name);
    local currentDkp = playerInfo[2]
    local newDkp = currentDkp + dkp

    local newOfficerNote = "<" .. newDkp .. ">"
    local guildIndex = GuildRosterHandler:getGuildIndex(name)
    GuildRosterSetOfficerNote(guildIndex, newOfficerNote);
end

local function isInRaid()
    local inRaid = (GetNumGroupMembers() > 0)
    if not inRaid then
        echo("You must be in a raid!")
    end
    return inRaid
end

local function sendWarningMessage(msg)
    SendChatMessage(msg, "RAID_WARNING")
end

local function modifyRaidDkp(dkp)
    if isInRaid(true) then
        local raidRoster = getRaidRoster()
        for raider = 1, table.getn(raidRoster), 1 do
            modifyPlayerDkp(raidRoster[raider][1], dkp)
        end

        --        for n = 1, table.getn(SOTA_RaidQueue), 1 do
        --            local guildInfo = SOTA_GetGuildPlayerInfo(SOTA_RaidQueue[n][1])
        --
        --            if guildInfo then
        --                SOTA_ApplyPlayerDKP(SOTA_RaidQueue[n][1], dkp)
        --                tidChanges[tidIndex] = { SOTA_RaidQueue[n][1], dkp }
        --                tidIndex = tidIndex + 1
        --            end
        --        end

        --			publicEcho(string.format("%d DKP was added to all players in raid", dkp))
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
    if id == 4 then
        clearDkp()
    end
    local value = RaidDkpValues[RaidIdToName[id]]
    modifyRaidDkp(value)
end