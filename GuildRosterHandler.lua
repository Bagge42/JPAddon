local _, guildRosterHandler = ...
guildRosterHandler.Handler = {}
local GuildRosterHandler = guildRosterHandler.Handler

local CurrentIdUsed = 1
local CurrentOrderUsed = "asc"
local GuildRoster = {}
local NameToRosterId = {}
local GuildIndex = {}

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
        if rank ~= ALT and rank ~= OFFICERALT then
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

    GuildRoster = guildRoster
end

local function copyGuildRoster()
    local copy = { }
    for memberCount = 1, table.getn(GuildRoster), 1 do
        copy[memberCount] = GuildRoster[memberCount]
    end
    return copy
end

function GuildRosterHandler:getSortedRoster(id)
    if CurrentIdUsed == id then
        if CurrentOrderUsed == "asc" then
            CurrentOrderUsed = "des"
        else
            CurrentOrderUsed = "asc"
        end
    elseif id then
        CurrentIdUsed = id
        CurrentOrderUsed = "asc"
    end
    local sortedRoster = copyGuildRoster()
    table.sort(sortedRoster, function(member1, member2)
        if CurrentOrderUsed == "des" then
            return member1[CurrentIdUsed] > member2[CurrentIdUsed]
        else
            return member1[CurrentIdUsed] < member2[CurrentIdUsed]
        end
    end)
    return sortedRoster
end

function GuildRosterHandler:getRoster()
    return GuildRoster
end

function GuildRosterHandler:getMemberInfo(memberName)
    local rosterId = NameToRosterId[memberName]
    return GuildRoster[rosterId]
end

function GuildRosterHandler:getGuildIndex(memberName)
    return GuildIndex[memberName]
end

