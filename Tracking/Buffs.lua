JP_Required_Buff_List = {}

local Jp = _G.Jp
local Localization = Jp.Localization
local Buffs = {}
local Utils = Jp.Utils
local FrameHandler = Jp.FrameHandler
local DateEditBox = Jp.DateEditBox
Jp.Buffs = Buffs

local BuffCap = 32
local MaximumDmtEntriesShown = 11

local RaidBuffNamesToIds = {
    ["Rallying Cry of the Dragonslayer"] = 22888,
    ["Songflower Serenade"] = 15366,
    ["Warchief's Blessing"] = 16609,
    ["Sayge's Dark Fortune of Agility"] = 23736,
    ["Sayge's Dark Fortune of Intelligence"] = 23766,
    ["Sayge's Dark Fortune of Spirit"] = 23738,
    ["Sayge's Dark Fortune of Stamina"] = 23737,
    ["Sayge's Dark Fortune of Strength"] = 23735,
    ["Sayge's Dark Fortune of Armor"] = 23767,
    ["Sayge's Dark Fortune of Resistance"] = 23769,
    ["Sayge's Dark Fortune of Damage"] = 23768,
    ["Fengus' Ferocity"] = 22817,
    ["Slip'kik's Savvy"] = 22820,
    ["Mol'dar's Moxie"] = 22818,
    ["Spirit of Zandalar"] = 24425,
    ["Spirit of Zanza"] = 24382,
}

local RaidBuffNamesToAbb = {
    ["Rallying Cry of the Dragonslayer"] = "Ony",
    ["Songflower Serenade"] = "SF",
    ["Warchief's Blessing"] = "Rend",
    ["Sayge's Dark Fortune of Agility"] = "DMFAgi",
    ["Sayge's Dark Fortune of Intelligence"] = "DMFInt",
    ["Sayge's Dark Fortune of Spirit"] = "DMFSpi",
    ["Sayge's Dark Fortune of Stamina"] = "DMFSta",
    ["Sayge's Dark Fortune of Strength"] = "DMFStr",
    ["Sayge's Dark Fortune of Armor"] = "DMFArm",
    ["Sayge's Dark Fortune of Resistance"] = "DMFRes",
    ["Sayge's Dark Fortune of Damage"] = "DMFDam",
    ["Fengus' Ferocity"] = "DMTA",
    ["Slip'kik's Savvy"] = "DMTC",
    ["Mol'dar's Moxie"] = "DMTS",
    ["Spirit of Zandalar"] = "ZG",
    ["Spirit of Zanza"] = "SoZ",
}

local RaidBuffAbbToName = {
    ["RCotD"] = "Rallying Cry of the Dragonslayer",
    ["SSe"] = "Songflower Serenade",
    ["WB"] = "Warchief's Blessing",
    ["SDFoAg"] = "Sayge's Dark Fortune of Agility",
    ["SDFoI"] = "Sayge's Dark Fortune of Intelligence",
    ["SDFoSp"] = "Sayge's Dark Fortune of Spirit",
    ["SDFoSta"] = "Sayge's Dark Fortune of Stamina",
    ["SDFoStr"] = "Sayge's Dark Fortune of Strength",
    ["SDFoAr"] = "Sayge's Dark Fortune of Armor",
    ["SDFoR"] = "Sayge's Dark Fortune of Resistance",
    ["SDFoD"] = "Sayge's Dark Fortune of Damage",
    ["FF"] = "Fengus' Ferocity",
    ["SSa"] = "Slip'kik's Savvy",
    ["MM"] = "Mol'dar's Moxie",
    ["SoS"] = "Spirit of Zandalar",
    ["Ony"] = "Rallying Cry of the Dragonslayer",
    ["SF"] = "Songflower Serenade",
    ["Rend"] = "Warchief's Blessing",
    ["DMFAgi"] = "Sayge's Dark Fortune of Agility",
    ["DMFInt"] = "Sayge's Dark Fortune of Intelligence",
    ["DMFSpi"] = "Sayge's Dark Fortune of Spirit",
    ["DMFSta"] = "Sayge's Dark Fortune of Stamina",
    ["DMFStr"] = "Sayge's Dark Fortune of Strength",
    ["DMFArm"] = "Sayge's Dark Fortune of Armor",
    ["DMFRes"] = "Sayge's Dark Fortune of Resistance",
    ["DMFDam"] = "Sayge's Dark Fortune of Damage",
    ["DMTA"] = "Fengus' Ferocity",
    ["DMTC"] = "Slip'kik's Savvy",
    ["DMTS"] = "Mol'dar's Moxie",
    ["ZG"] = "Spirit of Zandalar",
    ["SoZ"] = "Spirit of Zanza",
}

local RequiredBuffs = {
    [1] = "Rallying Cry of the Dragonslayer",
    [2] = "Spirit of Zandalar",
    [3] = "Fengus' Ferocity",
    [4] = "Slip'kik's Savvy",
    [5] = "Mol'dar's Moxie",
}

function Buffs:getRequiredBuffs()
    return JP_Required_Buff_List
end

function Buffs:printAbbs()
    for name, abb in pairs(RaidBuffNamesToAbb) do
        local msg = name .. ": " .. abb
        Utils:jpMsg(msg)
    end
end

function Buffs:getRaidBuffNamesAndIds()
    return RaidBuffNamesToIds
end

function Buffs:getAbbFromName(name)
    return RaidBuffNamesToAbb[name]
end

function Buffs:getNameFromAbb(abb)
    return RaidBuffAbbToName[abb]
end

local function checkForBuff(buffId)
    for buffPosition = 1, BuffCap, 1 do
        local buffName, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = UnitAura("player", buffPosition)

        if (spellId == nil) then
            return false, nil, nil
        elseif (spellId == buffId) then
            return true, duration, (expirationTime - GetTime()) / 60
        end
    end
end

function Buffs:addonLoaded()
    if (Utils:getTableSize(JP_Required_Buff_List) == 0) then
        for _, buff in pairs(RequiredBuffs) do
            table.insert(JP_Required_Buff_List, buff)
        end
    end
end

function Buffs:getCurrentBuffs()
    local currentBuffs = {}
    for name, id in pairs(RaidBuffNamesToIds) do
        local hasBuff, duration, expirationTime = checkForBuff(id)
        if hasBuff then
            table.insert(currentBuffs, { name, duration, expirationTime })
        end
    end
    return currentBuffs
end

function Buffs:shareBuffs()
    Utils:sendOfficerAddonMsg(Localization.BUFF_CLEAR, "GUILD")
    for _, buff in pairs(JP_Required_Buff_List) do
        local msg = Localization.BUFF_SHARE
        msg = msg .. "&" .. buff
        Utils:sendOfficerAddonMsg(msg, "GUILD")
    end
end

function Buffs:updateBuff(msg)
    for match in string.gmatch(msg, "([^&]*)") do
        if (match ~= Localization.BUFF_SHARE) then
            table.insert(JP_Required_Buff_List, match)
        end
    end
end

function Buffs:clearBuffs()
    JP_Required_Buff_List = {}
end

local function setCurrentDateBuffTab()
    DateEditBox:setCurrentDate("JP_TrackingFrameBuffTabDateFrameValue")
end

function Buffs:onLoad()
    FrameHandler:setOnClickTrackingFrameButtons("Buff", setCurrentDateBuffTab)
end

function Buffs:printRequiredBuffs()
    for _, buff in pairs(JP_Required_Buff_List) do
        print(buff)
    end
end

function Buffs:loadDmtLists(event, ...)

end

function Buffs:onMouseWheelDmtCrit(delta)

end

function Buffs:getMaximumDmtEntriesShown()
    return MaximumDmtEntriesShown
end

function Buffs:onListEntryClick(frameName)

end
