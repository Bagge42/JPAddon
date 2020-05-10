local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

function jpMsg(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|c80BE0AFF" .. msg)
end

function sendWarningMessage(msg)
    SendChatMessage(msg, "RAID_WARNING")
end

function removeRealmName(nameAndRealm)
    local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*")
    return name
end

function isInRaid()
    local inRaid = (GetNumGroupMembers() > 0)
    if not inRaid then
        jpMsg("You must be in a raid!")
    end
    return inRaid
end

function getRaidRoster()
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

