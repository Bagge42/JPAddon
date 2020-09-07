local Jp = _G.Jp
local Localization = Jp.Localization
local Utils = Jp.Utils
local GuildRosterHandler = {}
Jp.GuildRosterHandler = GuildRosterHandler

local CurrentIdUsed = 2
local CurrentOrderUsed = Localization.DESCENDING
local Roster = {}
local NameToRosterId = {}
local GuildIndex = {}
local GuildRosterNeedsUpdate = true
local AltRoster = {}
local OfficerRoster = {}

function GuildRosterHandler:update()
    if not CanViewOfficerNote() then
        return
    end

    local NrOfGuildMembers = GetNumGuildMembers()
    local guildRoster = {}

    for member = 1, NrOfGuildMembers, 1 do
        local nameAndRealm, rank, rankIndex, _, class, zone, _, officernote, online = GetGuildRosterInfo(member)
        local isOnline = 0
        if online then
            isOnline = 1
        end
        local name = Utils:removeRealmName(nameAndRealm)
        if rank ~= Localization.ALT and rank ~= Localization.OFFICER_ALT then
            if name ~= "" then
                local dkp = 0
                local _, _, dkpInNote = string.find(officernote, "<(-?%d*)>")
                if dkpInNote and tonumber(dkpInNote) then
                    dkp = dkpInNote
                end

                local rosterId = table.getn(guildRoster) + 1
                GuildIndex[name] = member
                NameToRosterId[name] = rosterId
                guildRoster[rosterId] = { name, (1 * dkp), class, rank, isOnline, zone, rankIndex }

                if (rank == "Officer") or (rank == "Jesus") then
                    OfficerRoster[name] = class
                end
            end
        else
            AltRoster[name] = { class, isOnline }
            if (rank == Localization.OFFICER_ALT) then
                OfficerRoster[name] = class
            end
        end
    end

    Roster = guildRoster
    GuildRosterNeedsUpdate = false
end

local function bid1LargerThanBid2(member1, member2, bids)
    local member1Bid = bids[member1[1]]
    local member2Bid = bids[member2[1]]
    if not member1Bid then
        if not member2Bid then
            return member1[2] > member2[2]
        else
            return false
        end
    elseif not member2Bid then
        return true
    elseif (member2Bid == Localization.FULL_DKP) then
        if (member1Bid == Localization.FULL_DKP) then
            return member1[2] > member2[2]
        else
            return false
        end
    else
        return member1Bid > member2Bid
    end
end

local function sortByBids(roster, bids)
    table.sort(roster, function(member1, member2)
        if CurrentOrderUsed == Localization.DESCENDING then
            return bid1LargerThanBid2(member2, member1, bids)
        else
            return bid1LargerThanBid2(member1, member2, bids)
        end
    end)
end

local function sortByNameOrDkp(roster)
    table.sort(roster, function(member1, member2)
        if CurrentOrderUsed == Localization.DESCENDING then
            return member1[CurrentIdUsed] > member2[CurrentIdUsed]
        else
            return member1[CurrentIdUsed] < member2[CurrentIdUsed]
        end
    end)
end

local function sortRoster(roster, bids)
    local bidHeaderId = getglobal("JP_OuterFrameListBidHeader"):GetID()
    if (CurrentIdUsed == bidHeaderId) then
        return sortByBids(roster, bids)
    else
        return sortByNameOrDkp(roster)
    end
end

function GuildRosterHandler:isOfficer(player)
    return OfficerRoster[player] ~= nil
end

function GuildRosterHandler:getSortedRoster(id, bids)
    if CurrentIdUsed == id then
        if CurrentOrderUsed == Localization.ASCENDING then
            CurrentOrderUsed = Localization.DESCENDING
        else
            CurrentOrderUsed = Localization.ASCENDING
        end
    elseif id then
        CurrentIdUsed = id
        CurrentOrderUsed = Localization.ASCENDING
    end
    local sortedRoster = Utils:copyTable(Roster)
    sortRoster(sortedRoster, bids)
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
        Utils:jpMsg(memberName .. " is not part of the dkp roster")
    end
end

function GuildRosterHandler:getGuildIndex(memberName)
    return GuildIndex[memberName]
end

function GuildRosterHandler:isInGuild(name)
    if GuildRosterHandler:getGuildIndex(name) == nil then
        return false
    end
    return true
end

function GuildRosterHandler:getPlayerClass(player)
    local rosterId = NameToRosterId[player]
    if rosterId then
        return Roster[rosterId][3]
    elseif AltRoster[player] then
        return AltRoster[player][1]
    else
        return
    end
end

function GuildRosterHandler:getRole(player)
    local playerClass = GuildRosterHandler:getPlayerClass(player)
    if (playerClass == Localization.PRIEST or playerClass == Localization.SHAMAN) then
        return Localization.HEALER
    elseif (playerClass == Localization.ROGUE) then
        return Localization.MELEE
    elseif (playerClass == Localization.DRUID) then
        return Localization.HEALER, Localization.TANK
    elseif (playerClass == Localization.WARRIOR) then
        return Localization.MELEE, Localization.TANK
    elseif (playerClass == Localization.MAGE or playerClass == Localization.WARLOCK) then
        return Localization.CASTER
    else
        return Localization.HUNTER
    end
end

function GuildRosterHandler:getOnlinePeople()
    local onlinePlayers = {}
    for _, rosterEntry in pairs(Roster) do
        if (rosterEntry[5] == 1) then
            onlinePlayers[rosterEntry[1]] = true
        end
    end
    for player, rosterEntry in pairs(AltRoster) do
        if (rosterEntry[2] == 1) then
            onlinePlayers[player] = true
        end
    end
    return onlinePlayers
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

function GuildRosterHandler:getCurrentSortingId()
    return CurrentIdUsed
end

local function isRaiderRank(rank)
    return (rank == "Raider") or (rank == "Officer") or (rank == "Jesus")
end

function GuildRosterHandler:getRaiders()
    local raiderTable = {}

    for _, rosterEntry in pairs(Roster) do
        local name = rosterEntry[1]
        local rank = rosterEntry[4]
        if isRaiderRank(rank) then
            raiderTable[table.getn(raiderTable) + 1] = name
        end
    end

    return raiderTable
end
