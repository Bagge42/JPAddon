local GuildRoster = {}
local CurrentIdUsed = 1
local CurrentOrderUsed = "asc"
local CurrentSelection = 0
local MaximumMembersShown = 8
local IdsToClasses = { WARRIOR, MAGE, ROGUE, DRUID, HUNTER, SHAMAN, PRIEST, WARLOCK }
local ToggledClasses = {}

SLASH_DKP_COMMAND1 = "/jp"
SlashCmdList["DKP_COMMAND"] = function(msg)
    handleCommand(msg);
end

function handleCommand(msg)
    if OuterFrame:IsVisible() then
        OuterFrame:Hide()
    else
        OuterFrame:Show()
    end
end

function removeRealmName(nameAndRealm)
    local _, _, name = string.find(nameAndRealm, "([^-]*)-%s*")
    return name
end

function updateGuildRoster()
    if not CanViewOfficerNote() then
        return
    end

    local memberCount = GetNumGuildMembers()
    local guildRoster = {}

    for n = 1, memberCount, 1 do
        local nameAndRealm, rank, rankIndex, _, class, zone, _, officernote, online = GetGuildRosterInfo(n)
        local name = removeRealmName(nameAndRealm)
        if name ~= "" then
            local isOnline = 0
            if online then
                isOnline = 1
            end

            if not officernote or officernote == "" then
                officernote = "<0>"
            end

            local _, _, dkp = string.find(officernote, "<(-?%d*)>")
            if not dkp or not tonumber(dkp) then
                dkp = 0
            end

            guildRoster[n] = { name, (1 * dkp), class, rank, isOnline, zone, rankIndex }
        end
    end

    GuildRoster = guildRoster
    sortList()
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

local function getToggledRoster()
    local toggledRoster = {}
    for member = 1, table.getn(GuildRoster), 1 do
        if ToggledClasses[GuildRoster[member][3]] then
            toggledRoster[table.getn(toggledRoster) + 1] = GuildRoster[member]
        end
    end
    return toggledRoster
end

local function clearEntries()
    for member = 1, MaximumMembersShown, 1 do
        local listEntry = getglobal("OuterFrameListEntry" .. member)
        getglobal(listEntry:GetName() .. "Player"):SetText("")
        getglobal(listEntry:GetName() .. "Amount"):SetText("")
    end
end

function updateEntries()
    local toggledRoster = getToggledRoster()
    FauxScrollFrame_Update(OuterFrameListScrollFrame, table.getn(toggledRoster), MaximumMembersShown, 24,
        "OuterFrameListEntry", 267, 283)
    if table.getn(toggledRoster) == 0 then
        clearEntries()
    else
        for member = 1, MaximumMembersShown, 1 do
            local rosterEntry = toggledRoster[member + OuterFrameListScrollFrame.offset]
            local name = rosterEntry[1]
            local dkp = rosterEntry[2]
            local listEntry = getglobal("OuterFrameListEntry" .. member)
            if rosterEntry then
                listEntry:Show()
                local playerFrame = getglobal(listEntry:GetName() .. "Player")
                playerFrame:SetText(name)
                setColor(playerFrame, rosterEntry[3])
                getglobal(listEntry:GetName() .. "Amount"):SetText(dkp)
                if member == CurrentSelection then
                    getglobal(listEntry:GetName() .. "Background"):Show()
                else
                    getglobal(listEntry:GetName() .. "Background"):Hide()
                end
            else
                listEntry:Hide()
            end
        end
    end
end

function createEntries()
    local initialEntry = CreateFrame("Button", "$parentEntry1", OuterFrameList, "ListEntry")
    initialEntry:SetID(1)
    initialEntry:SetPoint("TOPLEFT", 0, -28)
    for entryNr = 2, MaximumMembersShown, 1 do
        local followingEntries = CreateFrame("Button", "$parentEntry" .. entryNr, OuterFrameList, "ListEntry")
        followingEntries:SetID(entryNr)
        followingEntries:SetPoint("TOP", "$parentEntry" .. (entryNr - 1), "BOTTOM")
    end
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
    local initialButton = CreateFrame("Button", "$parentClassButton1", OuterFrameFilter, "ClassButton")
    initialButton:SetID(1)
    initialButton:SetPoint("LEFT", OuterFrameFilter, "LEFT")
    attachIcon(initialButton, 0, 0.25, 0, 0.25)

    for firstRowCount = 2, 4, 1 do
        local firstImageRow = CreateFrame("Button", "$parentClassButton" .. firstRowCount, OuterFrameFilter, "ClassButton")
        firstImageRow:SetID(firstRowCount)
        firstImageRow:SetPoint("LEFT", "$parentClassButton" .. (firstRowCount - 1), "RIGHT")
        attachIcon(firstImageRow, 0 + 0.25 * (firstRowCount - 1), 0.25 * firstRowCount, 0, 0.25)
    end

    for secondRowCount = 5, 8, 1 do
        local secondImageRow = CreateFrame("Button", "$parentClassButton" .. secondRowCount, OuterFrameFilter, "ClassButton")
        secondImageRow:SetID(secondRowCount)
        secondImageRow:SetPoint("LEFT", "$parentClassButton" .. (secondRowCount - 1), "RIGHT")
        attachIcon(secondImageRow, 0 + 0.25 * (secondRowCount - 4 - 1), 0.25 * (secondRowCount - 4), 0.25, 0.50)
    end

    toggleAllFilters()
    if IsInGuild() then
        getglobal("OuterFrame"):RegisterEvent("GUILD_ROSTER_UPDATE")
    end
end

function relayCommands()
    DEFAULT_CHAT_FRAME:AddMessage("|c80BE0AFF" .. INTRO);
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

function sortList(id)
    if CurrentIdUsed == id then
        if CurrentOrderUsed == "asc" then
            CurrentOrderUsed = "des"
        else
            CurrentOrderUsed = "asc"
        end
    elseif id then
        CurrentIdUsed = id
        CurrentOrderUsed = "asc"
    end
    table.sort(GuildRoster, function(member1, member2)
        if CurrentOrderUsed == "des" then
            return member1[CurrentIdUsed] > member2[CurrentIdUsed]
        else
            return member1[CurrentIdUsed] < member2[CurrentIdUsed]
        end
    end)
    updateEntries()
end

function selectEntry(id)
    if CurrentSelection ~= 0 then
        getglobal("OuterFrameListEntry" .. CurrentSelection .. "Background"):Hide()
    end
    if CurrentSelection == id then
        CurrentSelection = 0
    else
        CurrentSelection = id
    end
end

function isSelected(id)
    return id == CurrentSelection
end