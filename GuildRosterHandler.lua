local Jp = _G.Jp
local Utils = Jp.Utils
local GuildRosterHandler = {}
Jp.GuildRosterHandler = GuildRosterHandler

local CurrentIdUsed = 2
local CurrentOrderUsed = DESCENDING
local Roster = {}
local NameToRosterId = {}
local GuildIndex = {}
local GuildRosterNeedsUpdate = true
local AltRoster = {}

function GuildRosterHandler:update()
    if not CanViewOfficerNote() then
        return
    end

    local NrOfGuildMembers = GetNumGuildMembers()
    local guildRoster = {}

    for member = 1, NrOfGuildMembers, 1 do
        local nameAndRealm, rank, rankIndex, _, class, zone, _, officernote, online = GetGuildRosterInfo(member)
        local name = Utils:removeRealmName(nameAndRealm)
        if rank ~= ALT and rank ~= OFFICER_ALT then
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
        else
            AltRoster[name] = class
        end
    end

    Roster = guildRoster
    GuildRosterNeedsUpdate = false
end

local function bid1LargerThanBid2(member1, member2, bids)
    local member1Bid = bids[member1[1]]
    local member2Bid = bids[member2[1]]
    if not member1Bid then
        return false
    elseif not member2Bid then
        return true
    elseif (member2Bid == "Full") then
        if (member1Bid == "Full") then
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
        if CurrentOrderUsed == DESCENDING then
            return bid1LargerThanBid2(member2, member1, bids)
        else
            return bid1LargerThanBid2(member1, member2, bids)
        end
    end)
end

local function sortByNameOrDkp(roster)
    table.sort(roster, function(member1, member2)
        if CurrentOrderUsed == DESCENDING then
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

function GuildRosterHandler:getSortedRoster(id, bids)
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

function GuildRosterHandler:getPlayerClass(player)
    local rosterId = NameToRosterId[player]
    if rosterId then
        return Roster[rosterId][3]
    elseif AltRoster[player] then
        return AltRoster[player]
    else
        return
    end
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

