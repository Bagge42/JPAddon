local Jp = _G.Jp
local DateEditBox = {}
Jp.DateEditBox = DateEditBox

local DateIndex

local function isDate()

end

function DateEditBox:setCurrentDate(editBoxName)
    local currentTime = time()
    local date = date("%d/%m/%Y", currentTime)
    getglobal(editBoxName):SetText(date)
    DateIndex = currentTime
end

function DateEditBox:incrementDate(editBoxName)
    DateIndex = DateIndex + 86400
    local date = date("%d/%m/%Y", DateIndex)
    getglobal(editBoxName .. "Value"):SetText(date)
end

function DateEditBox:decrementDate(editBoxName)
    DateIndex = DateIndex - 86400
    local date = date("%d/%m/%Y", DateIndex)
    getglobal(editBoxName .. "Value"):SetText(date)
end

function DateEditBox:getDateFromBox(editBoxName)
    local date = getglobal(editBoxName):GetText()
    local day, month, year = string.split("/", date)
    local dateTbl = {
        year = year,
        month = month,
        day = day,
    }
    DateIndex = time(dateTbl)
    return date
end