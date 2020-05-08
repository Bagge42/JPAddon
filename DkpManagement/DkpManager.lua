local ButtonIdToIcon = { "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Onyxia", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-MoltenCore", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-BlackwingLair", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-TempleofAhnQiraj", "Interface\\ENCOUNTERJOURNAL\\UI-EJ-DUNGEONBUTTON-Naxxramas" }
local IdToButton = {}

local function attachIcons()
    for raidCount = 1, 5, 1 do
        local button = IdToButton[raidCount]
        button.icon = button:CreateTexture("$parentIcon", "CENTER")
        button.icon:SetAllPoints(button)
        button.icon:SetTexture(ButtonIdToIcon[raidCount])
        button.icon:SetTexCoord(0, 0.70, 0, 0.75)
    end
end

function createManagementButtons()
    local initialButton = CreateFrame("Button", "$parentRaidButton1", Management, "RaidDkpButton")
    initialButton:SetID(1)
    initialButton:SetPoint("TOPLEFT", Management, "TOPLEFT", 5, -23)
    IdToButton[1] = initialButton

    for raidCount = 2, 5, 1 do
        local raidButton = CreateFrame("Button", "$parentRaidButton" .. raidCount, Management, "RaidDkpButton")
        raidButton:SetID(raidCount)
        raidButton:SetPoint("LEFT", "$parentRaidButton" .. (raidCount - 1), "RIGHT", 3, 0)
        IdToButton[raidCount] = raidButton
    end
    attachIcons()
end

function raidDkpButtonOnClick(id)
    print(id)
end

