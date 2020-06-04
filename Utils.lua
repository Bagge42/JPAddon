_G.JP_Utils = {}
local Utils = _G.JP_Utils

function Utils:jpMsg(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|c80BE0AFF" .. msg)
end

function Utils:sendWarningMessage(msg)
    SendChatMessage(msg, "RAID_WARNING")
end

function Utils:sendGuildMessage(msg)
    SendChatMessage(msg, "GUILD")
end

function Utils:removeRealmName(nameAndRealm)
    local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*")
    return name
end

function Utils:isInRaid()
    return GetNumGroupMembers() > 0
end

function Utils:copyTable(tableToCopy)
    local copy = {}
    for k, _ in pairs(tableToCopy) do
        copy[k] = tableToCopy[k]
    end
    return copy
end

function Utils:setClassColor(frame, class)
    local r = 0
    local g = 0
    local b = 0
    if class == DRUID then
        r = 1.0
        g = 0.49
        b = 0.04
    elseif class == HUNTER then
        r = 0.67
        g = 0.83
        b = 0.45
    elseif class == MAGE then
        r = 0.41
        g = 0.80
        b = 0.94
    elseif class == PRIEST then
        r = 1
        g = 1
        b = 1
    elseif class == ROGUE then
        r = 1
        g = 0.96
        b = 0.41
    elseif class == SHAMAN then
        r = 0
        g = 0.44
        b = 0.87
    elseif class == WARLOCK then
        r = 0.58
        g = 0.51
        b = 0.79
    else
        r = 0.78
        g = 0.61
        b = 0.43
    end
    frame:SetTextColor(r, g, b)
end

function Utils:getTableSize(table)
    local counter = 0
    for _, _ in pairs(table) do
        counter = counter + 1
    end
    return counter
end

function Utils:isMsgTypeAndNotFromSelf(msg, msgType, sender)
    local type = string.split("&", msg)
    if (type == msgType) and (Utils:removeRealmName(sender) ~= UnitName("player")) then
        return true
    end
    return false
end

function Utils:isOfficer()
    return CanEditOfficerNote()
end

function Utils:sendOfficerAddonMsg(msg, targetChannel)
    if Utils:isOfficer() then
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, msg, targetChannel)
    end
end