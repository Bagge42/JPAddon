local Jp = _G.Jp
local Priorities = {}
local Utils = Jp.Utils
local Settings = Jp.Settings
local GuildRosterHandler = Jp.GuildRosterHandler
Jp.Priorities = Priorities

JP_Priority_List = {}
local MaximumPrioritiesShown = 24
local CurrentSelectedEntry
local PriorityIndex = 0
local CurrentOrderUsed = ASCENDING

local function getSortedPriorities()
    local tableCopy = Utils:getTableWithNoNils(JP_Priority_List)
    table.sort(tableCopy, function(member1, member2)
        if CurrentOrderUsed == DESCENDING then
            return member1[1] > member2[1]
        else
            return member1[1] < member2[1]
        end
    end)

    return tableCopy
end

local function share()
    local priorityList = getSortedPriorities()
    local msg
    for itemCount = 1, #priorityList, 1 do
        if (itemCount == 1) then
            msg = PRIORITY_MSG_SHARE_START .. "&"
        elseif (itemCount == #priorityList) then
            msg = PRIORITY_MSG_SHARE_END .. "&"
        else
            msg = PRIORITY_MSG_SHARE .. "&"
        end
        msg = msg .. priorityList[itemCount][1] .. "&" .. priorityList[itemCount][2]
        Utils:sendOfficerAddonMsg(msg, "GUILD")
    end
    Utils:jpMsg("Shared priorities with all online guild members")
end

local function createPriorityShareButton()
    local shareButton = CreateFrame("Button", "$parentShare", JP_PriorityFrameTitleFrame, "JP_AllClassToggle")
    shareButton:SetText(PRIORITIES_SHARE)
    shareButton:SetSize(105, 24)
    shareButton:SetPoint("Right", JP_PriorityFrameTitleFrameClose, "Left")
    shareButton:HookScript("OnClick", share)
    shareButton:Show()
end

function Priorities:onLoad()
    getglobal("JP_PriorityFrameTitleFrameName"):SetText(PRIORITY_FRAME_TITLE)
    createPriorityShareButton()
end

local function clearEntries()
    for member = 1, MaximumPrioritiesShown, 1 do
        local listEntry = getglobal("JP_PriorityFrameDisplayFrameListEntry" .. member)
        getglobal(listEntry:GetName() .. "Item"):SetText("")
        getglobal(listEntry:GetName() .. "Priority"):SetText("")
        listEntry:Hide()
    end
end

local function updateNextPreviousButtons()
    local previousButton = getglobal("JP_PriorityFrameDisplayFramePrevious")
    local nextButton = getglobal("JP_PriorityFrameDisplayFrameNext")
    if (PriorityIndex == 0) then
        previousButton:Hide()
    else
        previousButton:Show()
    end

    if ((PriorityIndex + MaximumPrioritiesShown) >= Utils:getTableSize(JP_Priority_List)) then
        nextButton:Hide()
    else
        nextButton:Show()
    end
end

local function updatePriorityList()
    clearEntries()
    local sortedPriorities = getSortedPriorities()
    for itemCount = 1, MaximumPrioritiesShown, 1 do
        local listEntry = getglobal("JP_PriorityFrameDisplayFrameListEntry" .. itemCount)
        local priorityEntry = sortedPriorities[itemCount + PriorityIndex]
        if priorityEntry then
            listEntry:Show()
            getglobal(listEntry:GetName() .. "Item"):SetText(priorityEntry[1])
            getglobal(listEntry:GetName() .. "Priority"):SetText(priorityEntry[2])
        end
    end
    updateNextPreviousButtons()
end

function Priorities:deleteAllPrios()
    JP_Priority_List = {}
    updatePriorityList()
end

local function removeTextFromItemLink(itemLink)
    local withoutBrackets = string.gsub(itemLink, "[%[%]]", "")
    local withoutSpacesAtTheEnd = string.gsub(withoutBrackets, '[ \t]+%f[\r\n%z]', '')
    return withoutSpacesAtTheEnd
end

local function linkPriorityIfAny(item, sender)
    local priority
    local itemText = GetItemInfo(item)
    for _, itemPriorityTable in pairs(JP_Priority_List) do
        if (itemPriorityTable[1] == itemText) then
            priority = itemPriorityTable[2]
        end
    end
    if (priority ~= nil) then
        if Settings:getSetting(LINK_PRIO_BOOLEAN_SETTING) and Utils:isSelf(sender) then
            local msg = "Priority: " .. priority
            SendChatMessage(msg, "RAID_WARNING")
        end
        getglobal("JP_ManagementPriorityLink"):Show()
        getglobal("JP_ManagementPriorityLinkItemName"):SetText(itemText)
        getglobal("JP_ManagementPriorityLinkPriority"):SetText(priority)
    else
        getglobal("JP_ManagementPriorityLink"):Hide()
    end
end

function Priorities:onEvent(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    local text = select(1, ...)
    if (event == "CHAT_MSG_RAID_WARNING") and Utils:isItemLink(text) and Jp.Utils:isOfficer() then
        linkPriorityIfAny(text, msg)
    end
    if (event == "CHAT_MSG_ADDON") then
        if (prefix == ADDON_PREFIX) and GuildRosterHandler:isOfficer(Utils:removeRealmName(sender)) then
            local prefix, item, prio = string.split("&", msg)
            if Utils:isSelf(sender) then
                return
            elseif (prefix == PRIORITY_MSG_SHARE_START) then
                JP_Priority_List = {}
                JP_Priority_List[1] = { item, prio }
            elseif (prefix == PRIORITY_MSG_SHARE_END) then
                JP_Priority_List[#JP_Priority_List + 1] = { item, prio }
                updatePriorityList()
            elseif (prefix == PRIORITY_MSG_SHARE) then
                JP_Priority_List[#JP_Priority_List + 1] = { item, prio }
            end
        end
    end
end

function Priorities:onClick()
    if not Utils:isOfficer() then
        getglobal("JP_PriorityFrameDisplayFrameAdd"):Hide()
        getglobal("JP_PriorityFrameTitleFrameShare"):Hide()
    end
    if not getglobal(PRIORITY_FRAME):IsVisible() then
        updatePriorityList()
        getglobal(PRIORITY_FRAME):Show()
    else
        getglobal(PRIORITY_FRAME):Hide()
    end
end

function Priorities:add()
    if not getglobal("JP_PriorityFrameAddFrame"):IsVisible() then
        getglobal("JP_PriorityFrameAddFrame"):Show()
        local itemValue = getglobal("JP_PriorityFrameAddFrameItemValue")
        itemValue:SetFocus()
        itemValue:SetText("")
        getglobal("JP_PriorityFrameAddFramePriorityValue"):SetText("")
    else
        getglobal("JP_PriorityFrameAddFrame"):Hide()
    end
end

local function isValid(string)
    if (string == "") then
        return false
    end

    if (string == nil) then
        return false
    end

    return true
end

local function getListId(item)
    for entry, itemInList in pairs(JP_Priority_List) do
        if (item == itemInList[1]) then
            return entry
        end
    end
    return nil
end

local function insertInPriorityList(item, priority)
    local listId = getListId(item)
    if (listId ~= nil) then
        JP_Priority_List[listId] = { item, priority }
    else
        JP_Priority_List[Utils:getTableSize(JP_Priority_List) + 1] = { item, priority }
    end
end

local function getItemText()
    local initialText = getglobal("JP_PriorityFrameAddFrameItemValue"):GetText()
    return removeTextFromItemLink(initialText)
end

function Priorities:accept()
    local item = getItemText()
    local priority = getglobal("JP_PriorityFrameAddFramePriorityValue"):GetText()
    if (isValid(item) and isValid(priority)) then
        insertInPriorityList(item, priority)
        if getglobal("JP_PriorityFrame"):IsVisible() then
            updatePriorityList()
        end
    end
    getglobal("JP_PriorityFrameAddFrame"):Hide()
end

local function removeSelection()
    getglobal("JP_PriorityFrameDisplayFrameListModifierFrame"):Hide()
    Priorities:selectEntry(CurrentSelectedEntry)
end

local function editClick()
    getglobal("JP_PriorityFrameAddFrame"):Show()
    local itemValue = getglobal("JP_PriorityFrameAddFrameItemValue")
    itemValue:SetFocus()
    local selectedEntryItem = getglobal("JP_PriorityFrameDisplayFrameListEntry" .. CurrentSelectedEntry .. "Item"):GetText()
    itemValue:SetText(selectedEntryItem)
    local selectedEntryPriority = getglobal("JP_PriorityFrameDisplayFrameListEntry" .. CurrentSelectedEntry .. "Priority"):GetText()
    getglobal("JP_PriorityFrameAddFramePriorityValue"):SetText(selectedEntryPriority)
    removeSelection()
end

local function deleteClick()
    local selectedEntryItem = getglobal("JP_PriorityFrameDisplayFrameListEntry" .. CurrentSelectedEntry .. "Item"):GetText()
    local listId = getListId(selectedEntryItem)
    JP_Priority_List[listId] = nil
    removeSelection()
    updatePriorityList()
end

local function createEntryModifiers()
    CreateFrame("Button", "$parentModifierFrame", JP_PriorityFrameDisplayFrameList, "JP_PriorityModifierFrame")
    local edit = CreateFrame("Button", "$parentEdit", JP_PriorityFrameDisplayFrameListModifierFrame, "JP_PriorityModifier")
    edit:SetText("E")
    edit:SetPoint("Left")
    edit:HookScript("OnClick", editClick)
    local delete = CreateFrame("Button", "$parentDelete", JP_PriorityFrameDisplayFrameListModifierFrame, "JP_PriorityModifier")
    delete:SetText("D")
    delete:SetPoint("LEFT", "$parentEdit", "RIGHT")
    delete:SetScript("OnClick", deleteClick)
end

function Priorities:createEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", JP_PriorityFrameDisplayFrameList, "JP_PriorityEntry")
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT", 0, -20)
    for entryNr = 2, MaximumPrioritiesShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, JP_PriorityFrameDisplayFrameList, "JP_PriorityEntry")
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end

    createEntryModifiers()
end

function Priorities:onTab(id)
    local itemEditBox = getglobal("JP_PriorityFrameAddFrameItemValue")
    local priorityEditBox = getglobal("JP_PriorityFrameAddFramePriorityValue")
    if (id == 1) then
        itemEditBox:ClearFocus()
        priorityEditBox:SetFocus()
    else
        itemEditBox:SetFocus()
        priorityEditBox:ClearFocus()
    end
end

function Priorities:selectEntry(id)
    local modifierFrame = getglobal("JP_PriorityFrameDisplayFrameListModifierFrame")
    local clickedEntryBackground = getglobal("JP_PriorityFrameDisplayFrameListEntry" .. id .. BACKGROUND)
    if (id == CurrentSelectedEntry) then
        CurrentSelectedEntry = nil
        clickedEntryBackground:Hide()
        modifierFrame:Hide()
    else
        if CurrentSelectedEntry ~= nil then
            getglobal("JP_PriorityFrameDisplayFrameListEntry" .. CurrentSelectedEntry .. BACKGROUND):Hide()
        end
        if Utils:isOfficer() then
            modifierFrame:SetPoint("LEFT", "JP_PriorityFrameDisplayFrameListEntry" .. id, "RIGHT")
            modifierFrame:Show()
            clickedEntryBackground:Show()
        end
        CurrentSelectedEntry = id
    end
end

function Priorities:itemNameClicked()
    if (CurrentOrderUsed == ASCENDING) then
        CurrentOrderUsed = DESCENDING
    else
        CurrentOrderUsed = ASCENDING
    end
    updatePriorityList()
end

function Priorities:isSelected(id)
    return (CurrentSelectedEntry == id)
end

function Priorities:next()
    PriorityIndex = PriorityIndex + MaximumPrioritiesShown
    updatePriorityList()
end

function Priorities:previous()
    PriorityIndex = PriorityIndex - MaximumPrioritiesShown
    updatePriorityList()
end