_G.DkpBrowser = {}
DkpBrowser = _G.DkpBrowser
local GuildRosterHandler = _G.GuildRosterHandler
local BrowserSelection = _G.BrowserSelection
local Utils = _G.Utils

local MaximumMembersShown = 8
local IdsToClasses = { WARRIOR, MAGE, ROGUE, DRUID, HUNTER, SHAMAN, PRIEST, WARLOCK }
local ToggledClasses = {}

local function handleCommand(msg)
    if OuterFrame:IsVisible() then
        OuterFrame:Hide()
    else
        OuterFrame:Show()
    end
end

SLASH_DKP_COMMAND1 = "/jp"
SlashCmdList["DKP_COMMAND"] = function(msg)
    handleCommand(msg)
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

function updateBrowserEntries(sortButtonId)
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
            Utils:setClassColor(playerFrame, rosterEntry[3])
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
    local initialEntry = CreateFrame("Button", "$parentEntry1", OuterFrameList, LIST_ENTRY)
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT", 0, -28)
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, OuterFrameList, LIST_ENTRY)
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
end

function DkpBrowser:updateRoster()
    GuildRosterHandler:update()
    updateBrowserEntries()
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

function DkpBrowser:createFilterButtons()
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

function DkpBrowser:relayCommands()
    Utils:jpMsg(INTRO)
end

function DkpBrowser:classButtonOnClick(id)
    local icon = getglobal("OuterFrameFilterClassButton" .. id .. "Icon")
    if icon:IsDesaturated() then
        icon:SetDesaturated(nil)
        ToggledClasses[IdsToClasses[id]] = true
    else
        icon:SetDesaturated(1)
        ToggledClasses[IdsToClasses[id]] = nil
    end
    updateBrowserEntries()
end

local function setDesaturations(nilOrOne)
    for classCount = 1, 8, 1 do
        local icon = getglobal("OuterFrameFilterClassButton" .. classCount .. "Icon")
        icon:SetDesaturated(nilOrOne)
    end
end

function DkpBrowser:deselectAllClasses()
    for _, class in pairs(IdsToClasses) do
       ToggledClasses[class] = nil
    end
    setDesaturations(1)
    updateBrowserEntries()
end

function DkpBrowser:selectAllClasses()
    for _, class in pairs(IdsToClasses) do
       ToggledClasses[class] = true
    end
    setDesaturations(nil)
    updateBrowserEntries()
end