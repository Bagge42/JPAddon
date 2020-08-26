JP_Required_Cons_List = {}
local Jp = _G.Jp
local Utils = Jp.Utils
local Consumables = {}
Jp.Consumables = Consumables

local RequiredConsumables = {
    [1] = { "Major Mana Potion", { HEALER, CASTER, HUNTER } },
    [2] = { "Mageblood Potion", { HEALER, CASTER, HUNTER } },
    [3] = { "Nightfin Soup", { HEALER, CASTER, HUNTER } },
    [4] = { "Runn Tum Tuber Surprise", { HEALER, CASTER, HUNTER } },
    [5] = { "Superior Mana Potion", { HEALER, CASTER, HUNTER } },
    [6] = { "Spirit of Zanza", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [7] = { "Greater Nature Protection Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [8] = { "Greater Arcane Protection Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [9] = { "Greater Fire Protection Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [10] = { "Greater Frost Protection Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [11] = { "Greater Shadow Protection Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [12] = { "Brilliant Mana Oil", { HEALER, HUNTER } },
    [13] = { "Brilliant Wizard Oil", { CASTER, HEALER } },
    [14] = { "Limited Invulnerability Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [15] = { "Demonic Rune", { HEALER, CASTER, HUNTER } },
    [16] = { "Dark Rune", { HEALER, CASTER, HUNTER } },
    [17] = { "Goblin Sapper Charge", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [18] = { "Elixir of Poison Resistance", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [19] = { "Flask of Distilled Wisdom", { HEALER, CASTER, HUNTER } },
    [20] = { "Elixir of the Mongoose", { HUNTER, TANK, MELEE } },
    [21] = { "Grilled Squid", { HUNTER, TANK, MELEE } },
    [22] = { "Juju might", { HUNTER, TANK, MELEE } },
    [23] = { "Winterfall Firewater", { HUNTER, TANK, MELEE } },
    [24] = { "Juju power", { HUNTER, TANK, MELEE } },
    [25] = { "Elixir of Giants", { HUNTER, TANK, MELEE } },
    [26] = { "Dense Sharpening Stone", { TANK, MELEE } },
    [27] = { "Elemental Sharpening Stone", { TANK, MELEE } },
    [28] = { "Frost Oil", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [29] = { "Thistle Tea", { MELEE } },
    [30] = { "Major Healing Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [31] = { "Flask of the Titans", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [32] = { "Elixir of Fortitude", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [33] = { "Elixir of Superior Defense", { TANK } },
    [34] = { "Gift of Arthas", { TANK } },
    [35] = { "Rumsey Rum Black Label", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [36] = { "Free Action Potion", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [37] = { "Greater Stoneshield Potion", { TANK } },
    [38] = { "Manual Crowd Pummeler", { TANK } },
    [39] = { "Blessed Sunfruit", { HUNTER, TANK, MELEE } },
    [40] = { "Smoked Desert Dumplings", { HUNTER, TANK, MELEE } },
    [41] = { "Greater Arcane Elixir", { CASTER } },
    [42] = { "Elixir of Greater Firepower", { CASTER } },
    [43] = { "Elixir of Shadow Power", { CASTER } },
    [44] = { "Heavy Runecloth Bandage", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [45] = { "Flask of Supreme Power", { CASTER } },
    [46] = { "Elixir of Frost Power", { CASTER } },
    [47] = { "Juju Ember", { CASTER } },
    [48] = { "Monster Omelet", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [49] = { "Dirge's Kickin' Chimaerok Chops", { HEALER, CASTER, HUNTER, TANK, MELEE } },
    [50] = { "Gordok Green Grog", { HEALER, CASTER, HUNTER, TANK, MELEE } },
}

local Roles = {}
local NameToAbb = {}
local AbbToName = {}

local function getAbb(name)
    local abb = ""
    for match in string.gmatch(name, "%S+") do
        abb = abb .. string.sub(match, 1, 1)
    end
    return abb
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

function Consumables:getRequiredConsumables()
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

function Consumables:clearConsumes()
    JP_Required_Cons_List = {}
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
