local _, guildRosterHandler = ...
guildRosterHandler.Handler = {}
local GuildRosterHandler = guildRosterHandler.Handler

local CurrentIdUsed = 2
local CurrentOrderUsed = DESCENDING
local Roster = {}
local NameToRosterId = {}
local GuildIndex = {}
local GuildRosterNeedsUpdate = true

local function removeRealmName(nameAndRealm)
    local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*")
    return name
end

function GuildRosterHandler:update()
    if not CanViewOfficerNote() then
        return
    end

    local NrOfGuildMembers = GetNumGuildMembers()
    local guildRoster = {}

    for member = 1, NrOfGuildMembers, 1 do
        local nameAndRealm, rank, rankIndex, _, class, zone, _, officernote, online = GetGuildRosterInfo(member)
        if rank ~= ALT and rank ~= OFFICER_ALT then
            local name = removeRealmName(nameAndRealm)
            if name ~= "" then
                local isOnline = 0
                if online then
                    isOnline = 1
                end

                local dkp = 0
                local _, _, dkpInNote = string.find(officernote, "<(-?%d*)>")
                if dkpInNote and tonumber(dkpInNote) then
                    dkp = dkpInNote
                end

                local rosterId = table.getn(guildRoster) + 1
                GuildIndex[name] = member
                NameToRosterId[name] = rosterId
                guildRoster[rosterId] = { name, (1 * dkp), class, rank, isOnline, zone, rankIndex }
            end
        end
    end

    Roster = guildRoster
    GuildRosterNeedsUpdate = false
end

function GuildRosterHandler:getSortedRoster(id)
    if CurrentIdUsed == id then
        if CurrentOrderUsed == ASCENDING then
            CurrentOrderUsed = DESCENDING
        else
            CurrentOrderUsed = ASCENDING
        end
    elseif id then
        CurrentIdUsed = id
        CurrentOrderUsed = ASCENDING
    end
    local sortedRoster = copyTable(Roster)
    table.sort(sortedRoster, function(member1, member2)
        if CurrentOrderUsed == DESCENDING then
            return member1[CurrentIdUsed] > member2[CurrentIdUsed]
        else
            return member1[CurrentIdUsed] < member2[CurrentIdUsed]
        end
    end)
    return sortedRoster
end

function GuildRosterHandler:getRoster()
    return Roster
end

function GuildRosterHandler:requestRosterUpdate()
    GuildRosterNeedsUpdate = true
    GuildRosterHandler:sendUpdateRequest()
end

function GuildRosterHandler:sendUpdateRequest()
    GuildRoster()
end

function GuildRosterHandler:waitingForUpdate()
    return GuildRosterNeedsUpdate
end

function GuildRosterHandler:getMemberInfo(memberName)
    local rosterId = NameToRosterId[memberName]
    if rosterId ~= nil then
        return Roster[rosterId]
    else
        jpMsg(memberName .. " does not seem to be part of your guild")
    end
end

function GuildRosterHandler:getGuildIndex(memberName)
    return GuildIndex[memberName]
end

function GuildRosterHandler:getPlayerClass(player)
    local rosterId = NameToRosterId[player]
    return Roster[rosterId][3]
end

function GuildRosterHandler:getRaidRoster()
    local playersInRaid = GetNumGroupMembers()

    local raidRosterTable = {}
    if playersInRaid > 0 then
        for playerCount = 1, playersInRaid, 1 do
            local name, _, _, _, _ = GetRaidRosterInfo(playerCount)
            local playerInfo = GuildRosterHandler:getMemberInfo(name)
            raidRosterTable[table.getn(raidRosterTable) + 1] = playerInfo
        end
    end

    return raidRosterTable
end

