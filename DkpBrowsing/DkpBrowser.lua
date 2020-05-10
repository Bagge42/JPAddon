local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

local MaximumMembersShown = 8
local IdsToClasses = { WARRIOR, MAGE, ROGUE, DRUID, HUNTER, SHAMAN, PRIEST, WARLOCK }
local ToggledClasses = {}

SLASH_DKP_COMMAND1 = "/jp"
SlashCmdList["DKP_COMMAND"] = function(msg)
    handleCommand(msg)
end

function handleCommand(msg)
    if OuterFrame:IsVisible() then
        OuterFrame:Hide()
    else
        OuterFrame:Show()
    end
end

local function setColor(frame, class)
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

local function getToggledRoster(sortButtonId)
    local toggledRoster = {}
    local guildRoster = GuildRosterHandler:getSortedRoster(sortButtonId)
    for member = 1, table.getn(guildRoster), 1 do
        if ToggledClasses[guildRoster[member][3]] then
            toggledRoster[table.getn(toggledRoster) + 1] = guildRoster[member]
        end
    end
    return toggledRoster
end

local function clearEntries()
    for member = 1, MaximumMembersShown, 1 do
        local listEntry = getglobal(OUTER_FRAME_LIST_ENTRY .. member)
        getglobal(listEntry:GetName() .. PLAYER):SetText("")
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

function updateEntries(sortButtonId)
    local toggledRoster
    if sortButtonId ~= nill and tonumber(sortButtonId) then
        toggledRoster = getToggledRoster(sortButtonId)
    else
        toggledRoster = getToggledRoster()
    end
    FauxScrollFrame_Update(OuterFrameListScrollFrame, table.getn(toggledRoster), MaximumMembersShown, 24,
        OUTER_FRAME_LIST_ENTRY, 267, 283)
    clearEntries()
    local numberToFillIn = getNumberOfEntriesToFill(toggledRoster)
    for member = 1, numberToFillIn, 1 do
        local rosterEntry = toggledRoster[member + OuterFrameListScrollFrame.offset]
        local name = rosterEntry[1]
        local dkp = rosterEntry[2]
        local listEntry = getglobal(OUTER_FRAME_LIST_ENTRY .. member)
        if rosterEntry then
            listEntry:Show()
            local playerFrame = getglobal(listEntry:GetName() .. PLAYER)
            playerFrame:SetText(name)
            setColor(playerFrame, rosterEntry[3])
            getglobal(listEntry:GetName() .. AMOUNT):SetText(dkp)
            if name == getSelectedPlayer() then
                getglobal(listEntry:GetName() .. BACKGROUND):Show()
            else
                getglobal(listEntry:GetName() .. BACKGROUND):Hide()
            end
        else
            listEntry:Hide()
        end
    end
end

function createEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", OuterFrameList, LIST_ENTRY)
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT", 0, -28)
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, OuterFrameList, LIST_ENTRY)
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

function updateRoster()
    GuildRosterHandler:update()
    updateEntries()
end

local function attachIcon(button, left, right, top, bottom)
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

function createFilterButtons()
    local initialButton = CreateFrame("Button", "$parentClassButton1", OuterFrameFilter, CLASS_BUTTON)
    initialButton:SetID(1)
    initialButton:SetPoint("LEFT", OuterFrameFilter, "LEFT")
    attachIcon(initialButton, 0, 0.25, 0, 0.25)

    for firstRowCount = 2, 4, 1 do
        local firstImageRow = CreateFrame("Button", "$parentClassButton" .. firstRowCount, OuterFrameFilter, CLASS_BUTTON)
        firstImageRow:SetID(firstRowCount)
        firstImageRow:SetPoint("LEFT", "$parentClassButton" .. (firstRowCount - 1), "RIGHT")
        attachIcon(firstImageRow, 0 + 0.25 * (firstRowCount - 1), 0.25 * firstRowCount, 0, 0.25)
    end

    for secondRowCount = 5, 8, 1 do
        local secondImageRow = CreateFrame("Button", "$parentClassButton" .. secondRowCount, OuterFrameFilter, CLASS_BUTTON)
        secondImageRow:SetID(secondRowCount)
        secondImageRow:SetPoint("LEFT", "$parentClassButton" .. (secondRowCount - 1), "RIGHT")
        attachIcon(secondImageRow, 0 + 0.25 * (secondRowCount - 4 - 1), 0.25 * (secondRowCount - 4), 0.25, 0.50)
    end

    toggleAllFilters()
end

function relayCommands()
    jpMsg(INTRO)
end

function classButtonOnClick(id)
    local icon = getglobal("OuterFrameFilterClassButton" .. id .. "Icon")
    if icon:IsDesaturated() then
        icon:SetDesaturated(nil)
        ToggledClasses[IdsToClasses[id]] = true
    else
        icon:SetDesaturated(1)
        ToggledClasses[IdsToClasses[id]] = nil
    end
    updateEntries()
end