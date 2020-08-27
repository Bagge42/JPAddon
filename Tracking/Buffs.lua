JP_Required_Buff_List = {}
local Jp = _G.Jp
local Buffs = {}
local Utils = Jp.Utils
Jp.Buffs = Buffs

local BuffCap = 32

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
    ["Spirit of Zandalar"] = 24425
}

local RaidBuffNamesToAbb = {
    ["Rallying Cry of the Dragonslayer"] = "RCotD",
    ["Songflower Serenade"] = "SSe",
    ["Warchief's Blessing"] = "WB",
    ["Sayge's Dark Fortune of Agility"] = "SDFoAg",
    ["Sayge's Dark Fortune of Intelligence"] = "SDFoI",
    ["Sayge's Dark Fortune of Spirit"] = "SDFoSp",
    ["Sayge's Dark Fortune of Stamina"] = "SDFoSta",
    ["Sayge's Dark Fortune of Strength"] = "SDFoStr",
    ["Sayge's Dark Fortune of Armor"] = "SDFoAr",
    ["Sayge's Dark Fortune of Resistance"] = "SDFoR",
    ["Sayge's Dark Fortune of Damage"] = "SDFoD",
    ["Fengus' Ferocity"] = "FF",
    ["Slip'kik's Savvy"] = "SSa",
    ["Mol'dar's Moxie"] = "MM",
    ["Spirit of Zandalar"] = "SoS"
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
    ["SoS"] = "Spirit of Zandalar"
}

local RequiredBuffs = {
    [1] = "Rallying Cry of the Dragonslayer",
    [2] = "Spirit of Zandalar"
}

function Buffs:getRequiredBuffs()
    return JP_Required_Buff_List
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
    Utils:sendOfficerAddonMsg(BUFF_CLEAR, "GUILD")
    local msg = BUFF_SHARE
    for _, buff in pairs(JP_Required_Buff_List) do
        msg = msg .. "&" .. buff
    end
    Utils:sendOfficerAddonMsg(msg, "GUILD")
end

function Buffs:updateBuff(msg)
    for match in string.gmatch(msg, "([^&]*)") do
        if (match ~= BUFF_SHARE) then
            table.insert(JP_Required_Buff_List, match)
        end
    end
end

function Buffs:clearBuffs()
    JP_Required_Buff_List = {}
end