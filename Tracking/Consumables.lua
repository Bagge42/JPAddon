JP_Required_Cons_List = {}

local Jp = _G.Jp
local Localization = Jp.Localization
local Utils = Jp.Utils
local Consumables = {}
local DateEditBox = Jp.DateEditBox
local FrameHandler = Jp.FrameHandler
Jp.Consumables = Consumables

local MaximumConsShown = 12
local ConsIndex = 1
local ShowInit = false
local ShowPost = false

local RequiredConsumables = {
    [1] = { "Major Mana Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [2] = { "Mageblood Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [3] = { "Nightfin Soup", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [4] = { "Runn Tum Tuber Surprise", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [5] = { "Superior Mana Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [6] = { "Spirit of Zanza", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [7] = { "Greater Nature Protection Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [8] = { "Greater Arcane Protection Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [9] = { "Greater Fire Protection Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [10] = { "Greater Frost Protection Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [11] = { "Greater Shadow Protection Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [12] = { "Brilliant Mana Oil", { Localization.HEALER, Localization.HUNTER } },
    [13] = { "Brilliant Wizard Oil", { Localization.CASTER, Localization.HEALER } },
    [14] = { "Limited Invulnerability Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [15] = { "Demonic Rune", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [16] = { "Dark Rune", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [17] = { "Goblin Sapper Charge", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [18] = { "Elixir of Poison Resistance", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [19] = { "Flask of Distilled Wisdom", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
    [20] = { "Elixir of the Mongoose", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [21] = { "Grilled Squid", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [22] = { "Juju might", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [23] = { "Winterfall Firewater", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [24] = { "Juju power", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [25] = { "Elixir of Giants", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [26] = { "Dense Sharpening Stone", { Localization.TANK, Localization.MELEE } },
    [27] = { "Elemental Sharpening Stone", { Localization.TANK, Localization.MELEE } },
    [28] = { "Frost Oil", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [29] = { "Thistle Tea", { Localization.MELEE } },
    [30] = { "Major Healing Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [31] = { "Flask of the Titans", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [32] = { "Elixir of Fortitude", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [33] = { "Elixir of Superior Defense", { Localization.TANK } },
    [34] = { "Gift of Arthas", { Localization.TANK } },
    [35] = { "Rumsey Rum Black Label", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [36] = { "Free Action Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [37] = { "Greater Stoneshield Potion", { Localization.TANK } },
    [38] = { "Manual Crowd Pummeler", { Localization.TANK } },
    [39] = { "Blessed Sunfruit", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [40] = { "Smoked Desert Dumplings", { Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [41] = { "Greater Arcane Elixir", { Localization.CASTER } },
    [42] = { "Elixir of Greater Firepower", { Localization.CASTER } },
    [43] = { "Elixir of Shadow Power", { Localization.CASTER } },
    [44] = { "Heavy Runecloth Bandage", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [45] = { "Flask of Supreme Power", { Localization.CASTER } },
    [46] = { "Elixir of Frost Power", { Localization.CASTER } },
    [47] = { "Juju Ember", { Localization.CASTER } },
    [48] = { "Monster Omelet", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [49] = { "Dirge's Kickin' Chimaerok Chops", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [50] = { "Gordok Green Grog", { Localization.HEALER, Localization.CASTER, Localization.HUNTER, Localization.TANK, Localization.MELEE } },
    [51] = { "Greater Mana Potion", { Localization.HEALER, Localization.CASTER, Localization.HUNTER } },
}

local Roles = {}
local NameToAbb = {}
local AbbToName = {}

local function abbExist(abb)
    for _, cons in pairs(JP_Required_Cons_List) do
        if (abb == cons[2]) then
            return true
        end
    end
    return false
end

local function renameIfExist(abb)
    local count = 2
    while abbExist(abb) do
        abb = abb .. count
    end
    return abb
end

local function getAbb(name)
    local abb = ""
    for match in string.gmatch(name, "%S+") do
        abb = abb .. string.sub(match, 1, 1)
    end
    return renameIfExist(abb)
end

function Consumables:addonLoaded()
    if (Utils:getTableSize(JP_Required_Cons_List) == 0) then
        for _, consume in pairs(RequiredConsumables) do
            Consumables:addConsumable(consume[1], consume[2])
        end
    end
end

function Consumables:addConsumable(name, roles)
    local abb = getAbb(name)
    table.insert(JP_Required_Cons_List, { name, abb, roles })
end

function Consumables:removeConsumable(name)
    local indexToRemove
    for index, consEntry in pairs(JP_Required_Cons_List) do
        if (consEntry[1] == name) then
            indexToRemove = index
        end
    end
    table.remove(JP_Required_Cons_List, indexToRemove)
end

function Consumables:getConsumableList()
    return JP_Required_Cons_List
end

function Consumables:getNameFromAbb(abb)
    if (Utils:getTableSize(AbbToName) == 0) then
        for _, consumeEntry in pairs(JP_Required_Cons_List) do
            AbbToName[consumeEntry[2]] = consumeEntry[1]
        end
    end
    return AbbToName[abb]
end

function Consumables:getAbbFromName(name)
    if (Utils:getTableSize(NameToAbb) == 0) then
        for _, consumeEntry in pairs(JP_Required_Cons_List) do
            NameToAbb[consumeEntry[1]] = consumeEntry[2]
        end
    end
    return NameToAbb[name]
end

local function createRoleTableIfNeeded(role)
    if (Roles[role] == nil) then
        Roles[role] = {}
        for _, consumeEntry in pairs(JP_Required_Cons_List) do
            for _, consRole in pairs(consumeEntry[3]) do
                if (consRole == role) then
                    table.insert(Roles[role], consumeEntry[1])
                end
            end
        end
    end
end

function Consumables:getRoleConsumables(role)
    createRoleTableIfNeeded(role)
    return Roles[role]
end

function Consumables:shareConsumes()
    Utils:sendOfficerAddonMsg(Localization.CONS_CLEAR, "GUILD")
    for _, consumeInfo in pairs(JP_Required_Cons_List) do
        local msg = Localization.CONS_SHARE
        msg = msg .. "&" .. consumeInfo[1]
        for _, role in pairs(consumeInfo[3]) do
            msg = msg .. "&" .. role
        end
        Utils:sendOfficerAddonMsg(msg, "GUILD")
    end
end

local function isRole(text)
    return (text == Localization.HEALER) or (text == Localization.TANK) or (text == Localization.CASTER) or (text == Localization.MELEE) or (text == Localization.HUNTER)
end

function Consumables:updateConsume(msg)
    local consume = {}
    local roles = {}
    for match in string.gmatch(msg, "([^&]*)") do
        if (match ~= Localization.CONS_SHARE) then
            if isRole(match) then
                table.insert(roles, match)
            elseif (match ~= "") then
                consume[1] = match
                consume[2] = getAbb(match)
            end
        end
    end
    consume[3] = roles
    table.insert(JP_Required_Cons_List, consume)
end

function Consumables:clearCons()
    JP_Required_Cons_List = {}
end

function Consumables:printCons()
    for _, cons in pairs(JP_Required_Cons_List) do
        print(cons[1])
        print(cons[2])
    end
    print(#JP_Required_Cons_List)
end

function Consumables:getMaximumConsShown()
    return MaximumConsShown
end

local function setCurrentDateConsTab()
    DateEditBox:setCurrentDate("JP_TrackingFrameConsTabDateFrameValue")
end

local function getSortedCons()
    local sortedCons = Utils:copyTable(JP_Required_Cons_List)
    table.sort(sortedCons, function(member1, member2)
        return member1[1] < member2[1]
    end)
    return sortedCons
end

local function updateConsEntries()
    Utils:clearEntries("JP_TrackingFrameConsTabListEntry", MaximumConsShown, "Cons")
    local sortedEntries = getSortedCons()
    local entryCounter = 1
    for memberIndex = ConsIndex, #sortedEntries, 1 do
        if entryCounter > MaximumConsShown then
            return
        end
        local entry = getglobal("JP_TrackingFrameConsTabListEntry" .. entryCounter)
        entry:Show()
        getglobal(entry:GetName() .. Localization.BACKGROUND):Hide()
        local fontString = getglobal(entry:GetName() .. "Cons")
        fontString:SetText(sortedEntries[memberIndex][1])
        entryCounter = entryCounter + 1
    end
end

function Consumables:loadTables(_, addonName)
    if addonName == "jpdkp" then
        updateConsEntries()
    end
end

local function toggleInit()
    if (ShowInit == true) then
        ShowInit = false
    else
        ShowPost = false
        getglobal("JP_TrackingFrameConsTabDateFramePost"):SetChecked(false)
        ShowInit = true
    end
end

local function togglePost()
    if (ShowPost == true) then
        ShowPost = false
    else
        ShowInit = false
        getglobal("JP_TrackingFrameConsTabDateFrameInit"):SetChecked(false)
        ShowPost = true
    end
end

function Consumables:getShowInit()
    return ShowInit
end

function Consumables:getShowPost()
    return ShowPost
end

function Consumables:onLoad()
    FrameHandler:setOnClickTrackingFrameButtons("Cons", setCurrentDateConsTab)

    local checkButtonPost = CreateFrame("CheckButton", "$parentPost", JP_TrackingFrameConsTabDateFrame, "JP_TrackingCheckButton")
    checkButtonPost:SetPoint("RIGHT")
    checkButtonPost.tooltip = "Check off this box to print post consumable holdings instead of consumables used."
    checkButtonPost:SetScript("OnClick", function()
        togglePost()
    end)

    local checkButtonInit = CreateFrame("CheckButton", "$parentInit", JP_TrackingFrameConsTabDateFrame, "JP_TrackingCheckButton")
    checkButtonInit:SetPoint("RIGHT", JP_TrackingFrameConsTabDateFramePost, "LEFT")
    checkButtonInit.tooltip = "Check off this box to print initial consumable holdings instead of consumables used."
    checkButtonInit:SetScript("OnClick", function()
        toggleInit()
    end)
end

function Consumables:onMouseWheel(delta)
    local negativeDelta = -delta
    if Utils:indexIsValidForList(negativeDelta, ConsIndex, MaximumConsShown, Utils:getTableSize(JP_Required_Cons_List)) then
        ConsIndex = ConsIndex + negativeDelta
        updateConsEntries()
    end
end