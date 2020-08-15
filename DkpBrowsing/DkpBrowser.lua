local Jp = _G.Jp
local DkpBrowser = {}
local GuildRosterHandler = Jp.GuildRosterHandler
local BrowserSelection = Jp.BrowserSelection
local Utils = Jp.Utils
local Settings = Jp.Settings
local Bench = Jp.Bench
local Bidding = Jp.Bidding
Jp.DkpBrowser = DkpBrowser

local MaximumMembersShown = 8
local IdsToClasses = { WARRIOR, MAGE, ROGUE, DRUID, HUNTER, SHAMAN, PRIEST, WARLOCK }
local ToggledClasses = {}

local function showHideJp()
    local outerFrame = getglobal("JP_OuterFrame")
    if outerFrame:IsVisible() then
        outerFrame:Hide()
    else
        outerFrame:Show()
        if not Utils:isOfficer() then
            outerFrame:SetSize(368, 300)
            getglobal("JP_Management"):Hide()
            getglobal("JP_OuterFrameTitleFrame"):SetSize(368, 24)
            getglobal("JP_BenchFrame"):SetPoint("TOPLEFT", "JP_OuterFrameList", "TOPRIGHT", 0, -4)
            getglobal("JP_BenchFrameClearBench"):Hide()
            getglobal("JP_OuterFrameTitleFrameInvite"):Hide()
            getglobal("JP_OuterFrameTitleFrameOptions"):Hide()
            getglobal("JP_OuterFrameTitleFrameLog"):SetPoint("RIGHT", "JP_OuterFrameTitleFrameClose", "LEFT")
            getglobal("JP_OuterFrameTitleFramePriorities"):SetPoint("RIGHT", "JP_OuterFrameTitleFrameLog", "LEFT")
            getglobal("JP_OuterFrameTitleFrameNone"):SetPoint("RIGHT", "JP_OuterFrameTitleFramePriorities", "LEFT")
        end
    end
end

SLASH_DKP_COMMAND1 = "/jp"
SlashCmdList["DKP_COMMAND"] = function(msg)
    showHideJp()
end

local function getToggledRoster(sortButtonId)
    local toggledRoster = {}
    local biddingRoundRoster = Bidding:getBidders()
    local guildRoster = GuildRosterHandler:getSortedRoster(sortButtonId, biddingRoundRoster)
    for member = 1, table.getn(guildRoster), 1 do
        if ToggledClasses[guildRoster[member][3]] then
            toggledRoster[table.getn(toggledRoster) + 1] = guildRoster[member]
        elseif biddingRoundRoster[guildRoster[member][1]] then
            toggledRoster[table.getn(toggledRoster) + 1] = guildRoster[member]
        end
    end
    return toggledRoster
end

local function clearEntries()
    for member = 1, MaximumMembersShown, 1 do
        local listEntry = getglobal(OUTER_FRAME_LIST_ENTRY .. member)
        getglobal(listEntry:GetName() .. PLAYER):SetText("")
        getglobal(listEntry:GetName() .. "Bid"):SetText("")
        getglobal(listEntry:GetName() .. AMOUNT):SetText("")
    end
end

local function getNumberOfEntriesToFill(toggledRoster)
    local sizeOfToggledRoster = table.getn(toggledRoster)
    if sizeOfToggledRoster < MaximumMembersShown then
        return sizeOfToggledRoster
    end
    return MaximumMembersShown
end

local function setBidText(player, entry)
    local bid = Bidding:getBid(player)
    if bid then
        getglobal(OUTER_FRAME_LIST_ENTRY .. entry .. "Bid"):SetText(bid)
    end
end

function JP_UpdateBrowserEntries(sortButtonId)
    local toggledRoster
    if sortButtonId ~= nil and tonumber(sortButtonId) then
        toggledRoster = getToggledRoster(sortButtonId)
    else
        toggledRoster = getToggledRoster()
    end
    FauxScrollFrame_Update(JP_OuterFrameListScrollFrame, table.getn(toggledRoster), MaximumMembersShown, 24,
        OUTER_FRAME_LIST_ENTRY, 267, 283)
    clearEntries()
    local numberToFillIn = getNumberOfEntriesToFill(toggledRoster)
    for member = 1, numberToFillIn, 1 do
        local rosterEntry = toggledRoster[member + JP_OuterFrameListScrollFrame.offset]
        local name = rosterEntry[1]
        local dkp = rosterEntry[2]
        local listEntry = getglobal(OUTER_FRAME_LIST_ENTRY .. member)
        if rosterEntry then
            listEntry:Show()
            local playerFrame = getglobal(listEntry:GetName() .. PLAYER)
            playerFrame:SetText(name)
            Utils:setClassColor(playerFrame, rosterEntry[3])
            setBidText(name, member)
            getglobal(listEntry:GetName() .. AMOUNT):SetText(dkp)
            if name == BrowserSelection:getSelectedPlayer() then
                getglobal(listEntry:GetName() .. BACKGROUND):Show()
            else
                getglobal(listEntry:GetName() .. BACKGROUND):Hide()
            end
        else
            listEntry:Hide()
        end
    end
end

function DkpBrowser:createEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", JP_OuterFrameList, LIST_ENTRY)
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT", 0, -28)
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, JP_OuterFrameList, LIST_ENTRY)
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

local function updateRoster()
    GuildRosterHandler:update()
    JP_UpdateBrowserEntries()
end

local function setDesaturations(nilOrOne)
    for classCount = 1, 8, 1 do
        local icon = getglobal("JP_OuterFrameFilterClassButton" .. classCount .. "Icon")
        icon:SetDesaturated(nilOrOne)
    end
end

local function deselectAllClasses()
    for _, class in pairs(IdsToClasses) do
        ToggledClasses[class] = nil
    end
    setDesaturations(1)
    JP_UpdateBrowserEntries()
end

function DkpBrowser:clearOverview()
    Bidding:stopBiddingRound()
    deselectAllClasses()
    getglobal("JP_ManagementPriorityLink"):Hide()
end

local function startBiddingRound(textInWarning)
    if Settings:getSetting(BIDDERS_ONLY_BOOLEAN_SETTING) then
        DkpBrowser:clearOverview()
        if Utils:isItemLink(textInWarning) then
            Bidding:setAuctionInProgress(true)
        end
    end
end

local function addBidder(bidder, amount)
    Bidding:addBidder(bidder, amount)
    if (BrowserSelection:getSelectedPlayer() == bidder) then
        Bidding:setBidInPlayerManagement(bidder)
    end
    local bidHeaderId = getglobal("JP_OuterFrameListBidHeader"):GetID()
    if (GuildRosterHandler:getCurrentSortingId() == bidHeaderId) then
        JP_UpdateBrowserEntries()
    else
        JP_UpdateBrowserEntries(bidHeaderId)
    end
end

local function addBidToEntries()
    for entry = 1, MaximumMembersShown, 1 do
        getglobal(OUTER_FRAME_LIST_ENTRY .. entry .. PLAYER):SetSize(111, 24)
        getglobal(OUTER_FRAME_LIST_ENTRY .. entry .. "Bid"):Show()
        getglobal(OUTER_FRAME_LIST_ENTRY .. entry .. AMOUNT):SetPoint("LEFT", OUTER_FRAME_LIST_ENTRY .. entry .. "Bid", "RIGHT")
    end
end

function DkpBrowser:addBidToOverview()
    getglobal("JP_OuterFrameListPlayerHeader"):SetSize(115, 24)
    getglobal("JP_OuterFrameListBidHeader"):Show()
    getglobal("JP_OuterFrameListAmountHeader"):SetPoint("LEFT", JP_OuterFrameListBidHeader, "RIGHT")
    addBidToEntries()
end

local function removeBidFromEntries()
    for entry = 1, MaximumMembersShown, 1 do
        getglobal(OUTER_FRAME_LIST_ENTRY .. entry .. PLAYER):SetSize(184, 24)
        getglobal(OUTER_FRAME_LIST_ENTRY .. entry .. "Bid"):Hide()
        getglobal(OUTER_FRAME_LIST_ENTRY .. entry .. AMOUNT):SetPoint("LEFT", OUTER_FRAME_LIST_ENTRY .. entry .. PLAYER, "RIGHT", 4, 0)
    end
end

function DkpBrowser:removeBidFromOverview()
    getglobal("JP_OuterFrameListPlayerHeader"):SetSize(189, 24)
    getglobal("JP_OuterFrameListBidHeader"):Hide()
    getglobal("JP_OuterFrameListAmountHeader"):SetPoint("LEFT", JP_OuterFrameListPlayerHeader, "RIGHT")
    removeBidFromEntries()
end

local function isValidInvFormat(text)
    return (text == "inv") or (text == "Inv") or (text == "invite") or (text == "Invite")
end

local function shouldConvertToRaid()
    return (GetNumGroupMembers() >= 5) and not IsInRaid() and UnitIsGroupLeader("player")
end

local function isInRaid(player)
    return UnitInRaid(player)
end

local function shouldInviteToRaid(text, sender)
    return isValidInvFormat(text) and Settings:getSetting(AUTO_INV_BOOLEAN_SETTING) and GuildRosterHandler:isInGuild(sender) and not isInRaid(sender)
end

local function handleWhisper(text, sender)
    if shouldInviteToRaid(text, sender) then
        if shouldConvertToRaid() then
            ConvertToRaid()
        end
        InviteUnit(sender)
    elseif GuildRosterHandler:isInGuild(sender) and Settings:getSetting(BIDDERS_ONLY_BOOLEAN_SETTING) then
        local bidAmount = string.match(text, "%d+")
        if bidAmount then
            addBidder(sender, bidAmount)
        end
    end
end

function DkpBrowser:onEvent(event, ...)
    local text = select(1, ...)
    if (event == "CHAT_MSG_RAID_WARNING") and Utils:isItemLink(text) then
        startBiddingRound(text)
    elseif (event == "CHAT_MSG_RAID") or (event == "CHAT_MSG_RAID_LEADER") then
        if Bidding:auctionInProgress() and Utils:isItemLink(text) then
            local sender = Utils:removeRealmName(select(2, ...))
            addBidder(sender)
        end
    elseif (event == "CHAT_MSG_WHISPER") then
        local sender = Utils:removeRealmName(select(2, ...))
        handleWhisper(text, sender)
    elseif (event == "GUILD_ROSTER_UPDATE") then
        updateRoster()
    elseif (event == "ADDON_LOADED") then
        if Settings:getSetting(BIDDERS_ONLY_BOOLEAN_SETTING) then
            DkpBrowser:addBidToOverview()
        end
    end
end

local function attachClassIcon(button, left, right, top, bottom)
    button.icon = button:CreateTexture("$parentIcon", "CENTER")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    button.icon:SetTexCoord(left, right, top, bottom)
end

local function toggleAllFilters()
    for filter = 1, table.getn(IdsToClasses), 1 do
        ToggledClasses[IdsToClasses[filter]] = true
    end
end

function DkpBrowser:createFilterButtons()
    local initialButton = CreateFrame("Button", "$parentClassButton1", JP_OuterFrameFilter, CLASS_BUTTON)
    initialButton:SetID(1)
    initialButton:SetPoint("LEFT", JP_OuterFrameFilter, "LEFT")
    attachClassIcon(initialButton, 0, 0.25, 0, 0.25)

    for firstRowCount = 2, 4, 1 do
        local firstImageRow = CreateFrame("Button", "$parentClassButton" .. firstRowCount, JP_OuterFrameFilter, CLASS_BUTTON)
        firstImageRow:SetID(firstRowCount)
        firstImageRow:SetPoint("LEFT", "$parentClassButton" .. (firstRowCount - 1), "RIGHT")
        attachClassIcon(firstImageRow, 0 + 0.25 * (firstRowCount - 1), 0.25 * firstRowCount, 0, 0.25)
    end

    for secondRowCount = 5, 8, 1 do
        local secondImageRow = CreateFrame("Button", "$parentClassButton" .. secondRowCount, JP_OuterFrameFilter, CLASS_BUTTON)
        secondImageRow:SetID(secondRowCount)
        secondImageRow:SetPoint("LEFT", "$parentClassButton" .. (secondRowCount - 1), "RIGHT")
        attachClassIcon(secondImageRow, 0 + 0.25 * (secondRowCount - 4 - 1), 0.25 * (secondRowCount - 4), 0.25, 0.50)
    end

    toggleAllFilters()
end

function DkpBrowser:relayCommands()
    Utils:jpMsg(INTRO)
end

function DkpBrowser:classButtonOnClick(id)
    local icon = getglobal("JP_OuterFrameFilterClassButton" .. id .. "Icon")
    if icon:IsDesaturated() then
        icon:SetDesaturated(nil)
        ToggledClasses[IdsToClasses[id]] = true
    else
        icon:SetDesaturated(1)
        ToggledClasses[IdsToClasses[id]] = nil
    end
    JP_UpdateBrowserEntries()
end

function DkpBrowser:selectAllClasses()
    Bidding:stopBiddingRound()
    getglobal("JP_ManagementPriorityLink"):Hide()
    for _, class in pairs(IdsToClasses) do
        ToggledClasses[class] = true
    end
    setDesaturations(nil)
    JP_UpdateBrowserEntries()
end

function DkpBrowser:massInvite()
    local raiders = GuildRosterHandler:getRaiders()
    for _, name in pairs(raiders) do
        if shouldConvertToRaid() then
            ConvertToRaid()
        end
        if not isBenched(name) and not isInRaid(name) then
            InviteUnit(name)
        end
    end
end