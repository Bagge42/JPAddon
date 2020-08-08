local Jp = _G.Jp
local Priorities = {}
local Utils = Jp.Utils
Jp.Priorities = Priorities

JP_Priority_List = {}
local MaximumPrioritiesShown = 24
local CurrentSelectedEntry
local PriorityIndex = 0
local CurrentOrderUsed = ASCENDING

local function getSortedPriorities()
    local tableCopy = Utils:getTableWithNoHoles(JP_Priority_List)
        table.sort(tableCopy, function(member1, member2)
        if CurrentOrderUsed == DESCENDING then
            return member1[1] > member2[1]
        else
            return member1[1] < member2[1]
        end
    end)

    return tableCopy
end

local function clearEntries()
    for member = 1, MaximumPrioritiesShown, 1 do
        local listEntry = getglobal("JP_PriorityFrameDisplayFrameListEntry" .. member)
        getglobal(listEntry:GetName() .. "Item"):SetText("")
        getglobal(listEntry:GetName() .. "Priority"):SetText("")
        listEntry:Hide()
    end
end

function jptest()
    for i = 1, 30, 1 do
        JP_Priority_List[Utils:getTableSize(JP_Priority_List) + 1] = { "Hej" .. i, "D" .. i * 2 }
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

function Priorities:onClick()
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
    local withoutBrackets = string.gsub(initialText, "[%[%]]", "")
    local withoutSpacesAtTheEnd = string.gsub(withoutBrackets, '[ \t]+%f[\r\n%z]', '')
    return withoutSpacesAtTheEnd
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
    removeSelection()
    print("edit")
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

--Remove
function Priorities:loadPriorities(event, addonName)
    if (addonName == "jpdkp") then
        updatePriorityList()
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
        modifierFrame:SetPoint("LEFT", "JP_PriorityFrameDisplayFrameListEntry" .. id, "RIGHT")
        modifierFrame:Show()
        clickedEntryBackground:Show()
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