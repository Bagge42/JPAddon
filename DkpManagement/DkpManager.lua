local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

local ButtonIdToIcon = { "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Onyxia", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-MoltenCore", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-BlackwingLair", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-TempleofAhnQiraj", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Naxxramas" }
local IdToButton = {}

local function attachIcons()
    for raidCount = 1, 5, 1 do
        local button = IdToButton[raidCount]
        button.icon = button:CreateTexture("$parentIcon", "CENTER")
        button.icon:SetAllPoints(button)
        button.icon:SetTexture(ButtonIdToIcon[raidCount])
        button.icon:SetTexCoord(0, 0.70, 0, 0.75)
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

    local raidRosterTable = { }
    if playersInRaid then
        local guildRoster = GuildRosterHandler:getRoster()
        local memberCount = table.getn(guildRoster);
        for playerCount = 1, playersInRaid, 1 do
            local name, _, _, _, _ = GetRaidRosterInfo(playerCount);

            for m = 1, memberCount, 1 do
                local memberEntry = guildRoster[m]
                if name == memberEntry[1] then
                    raidRosterTable[table.getn(raidRosterTable) + 1] = memberEntry;
                end
            end
        end
    end

    return raidRosterTable
end

function raidDkpButtonOnClick(id)
    local guildRoster = GuildRosterHandler:getRoster()
    print(guildRoster[1][1])
end

