local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

function jpMsg(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|c80BE0AFF" .. msg)
end

function sendWarningMessage(msg)
    SendChatMessage(msg, "RAID_WARNING")
end

function sendGuildMessage(msg)
    SendChatMessage(msg, "GUILD")
end

function removeRealmName(nameAndRealm)
    local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*")
    return name
end

function isInRaid()
    return GetNumGroupMembers() > 0
end

function copyTable(tableToCopy)
    local copy = {}
    for k, _ in pairs(tableToCopy) do
        copy[k] = tableToCopy[k]
    end
    return copy
end