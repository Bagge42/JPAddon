local _, guildRosterHandler = ...
guildRosterHandler.Handler = {}
local GuildRosterHandler = guildRosterHandler.Handler

local CurrentIdUsed = 1
local CurrentOrderUsed = "asc"
local GuildRoster = {}

local function removeRealmName(nameAndRealm)
    local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*")
    return name
end

function GuildRosterHandler:update()
    if not CanViewOfficerNote() then
        return
    end

    local memberCount = GetNumGuildMembers()
    local guildRoster = {}

    for n = 1, memberCount, 1 do
        local nameAndRealm, rank, rankIndex, _, class, zone, _, officernote, online = GetGuildRosterInfo(n)
        if rank ~= ALT and rank ~= OFFICERALT then
            local name = removeRealmName(nameAndRealm)
            if name ~= "" then
                local isOnline = 0
                if online then
                    isOnline = 1
                end

                if not officernote or officernote == "" then
                    officernote = "<0>"
                end

                local _, _, dkp = string.find(officernote, "<(-?%d*)>")
                if not dkp or not tonumber(dkp) then
                    dkp = 0
                end

                guildRoster[table.getn(guildRoster) + 1] = { name, (1 * dkp), class, rank, isOnline, zone, rankIndex }
            end
        end
    end

    GuildRoster = guildRoster
    GuildRosterHandler:sortRoster()
end

function GuildRosterHandler:sortRoster(id)
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
    table.sort(GuildRoster, function(member1, member2)
        if CurrentOrderUsed == "des" then
            return member1[CurrentIdUsed] > member2[CurrentIdUsed]
        else
            return member1[CurrentIdUsed] < member2[CurrentIdUsed]
        end
    end)
end

function GuildRosterHandler:getRoster()
    return GuildRoster
end

