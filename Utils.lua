local Jp = _G.Jp
local Localization = Jp.Localization
local Utils = {}
Jp.Utils = Utils

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

function Utils:selfIsInRaid()
    if IsInGroup() then
        if IsInRaid() then
            return true
        end
    end
    return false
end

function Utils:getTableWithKeysAsValuesSorted(tableToSort)
    local sortedTable = {}

    for key, _ in pairs(tableToSort) do
        sortedTable[#sortedTable + 1] = key
    end
    table.sort(sortedTable, function(member1, member2)
        return member1 < member2
    end)

    return sortedTable
end

function Utils:copy(tableToCopy)
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
    if class == Localization.DRUID then
        r = 1.0
        g = 0.49
        b = 0.04
    elseif class == Localization.HUNTER then
        r = 0.67
        g = 0.83
        b = 0.45
    elseif class == Localization.MAGE then
        r = 0.41
        g = 0.80
        b = 0.94
    elseif class == Localization.PRIEST then
        r = 1
        g = 1
        b = 1
    elseif class == Localization.ROGUE then
        r = 1
        g = 0.96
        b = 0.41
    elseif class == Localization.SHAMAN then
        r = 0
        g = 0.44
        b = 0.87
    elseif class == Localization.WARLOCK then
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

function Utils:getSize(table)
    local counter = 0
    for _, _ in pairs(table) do
        counter = counter + 1
    end
    return counter
end

function Utils:isMsgTypeAndNotFromSelf(msg, msgType, sender)
    local type = string.split("&", msg)
    local selfName = UnitName("player")
    if (type == msgType) and (Utils:removeRealmName(sender) ~= selfName) then
        return true
    end
    return false
end

function Utils:isSelfRemoveRealm(sender)
    local selfName = UnitName("player")
    return (Utils:removeRealmName(sender) == selfName)
end

function Utils:isSelf(sender)
    local selfName = UnitName("player")
    return (selfName == sender)
end

function Utils:isMsgType(msg, msgType)
    local type = string.split("&", msg)
    if (type == msgType) then
        return true
    end
    return false
end

function Utils:isOfficer()
    return CanEditOfficerNote()
end

function Utils:sendOfficerAddonMsg(msg, targetChannel, targetPlayer)
    if Utils:isOfficer() then
        C_ChatInfo.SendAddonMessage(Localization.ADDON_PREFIX, msg, targetChannel, targetPlayer)
    end
end

function Utils:sendAddonMsg(msg, targetChannel, targetPlayer)
    C_ChatInfo.SendAddonMessage(Localization.ADDON_PREFIX, msg, targetChannel, targetPlayer)
end

function Utils:isItemLink(text)
    -- 16 Colons in a message makes it quite certain that the message contains an itemlink
    local _, colonCount = string.gsub(text, ":", "")
    if (colonCount >= 16) and (string.find(text, "item")) then
        return true
    end
    return false
end

function Utils:getCopyWithNoNils(table)
    local copyWithoutNils = {}
    for k, v in pairs(table) do
        if (k ~= nil and v ~= nil) then
            copyWithoutNils[#copyWithoutNils + 1] = v
        end
    end
    return copyWithoutNils
end

-- Wait function from wowwiki --
function Utils:jpWait(delay, func, ...)
    local waitTable = {}
    local waitFrame
    if (type(delay) ~= "number" or type(func) ~= "function") then
        return false
    end
    if (waitFrame == nil) then
        waitFrame = CreateFrame("Frame", "WaitFrame", UIParent)
        waitFrame:SetScript("onUpdate", function(self, elapse)
            local count = #waitTable
            local i = 1
            while (i <= count) do
                local waitRecord = tremove(waitTable, i)
                local d = tremove(waitRecord, 1)
                local f = tremove(waitRecord, 1)
                local p = tremove(waitRecord, 1)
                if (d > elapse) then
                    tinsert(waitTable, i, { d - elapse, f, p })
                    i = i + 1
                else
                    count = count - 1
                    f(unpack(p))
                end
            end
        end)
    end
    tinsert(waitTable, { delay, func, { ... } })
    return true
end

function Utils:createEntries(frameType, parentFrame, frameTemplate, numberOfEntries)
    local initialEntry = CreateFrame(frameType, "$parentEntry1", parentFrame, frameTemplate)
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT")
    for entryNr = 2, numberOfEntries, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, parentFrame, frameTemplate)
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

function Utils:indexIsValidForList(delta, index, maximumEntriesShown, listSize)
    if (index == 1) and (delta < 0) then
        return false
    end
    if (index + delta > listSize - maximumEntriesShown + 1) then
        return false
    end
    return true
end

function Utils:clearEntries(entryFrameNames, maximumEntries, entryText)
    for member = 1, maximumEntries, 1 do
        local entry = getglobal(entryFrameNames .. member)
        getglobal(entry:GetName() .. entryText):SetText("")
        entry:Hide()
    end
end

function Utils:sortByFirstEntryInValue(tableToSort)
    local resultOfSorting = Utils:copy(tableToSort)
    table.sort(resultOfSorting, function(member1, member2)
        return member1[1] < member2[1]
    end)
    return resultOfSorting
end