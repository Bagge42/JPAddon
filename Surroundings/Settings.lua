JP_Current_Settings = {}
_G.JP_Settings = {}
local Settings = _G.JP_Settings
local Utils = _G.JP_Utils

function Settings:onSettingsClick()
    local isOfficer = Utils:isOfficer()
    local settings = getglobal("JP_SettingsFrame")
    local management = getglobal("JP_Management")

    if not settings:IsVisible() then
        settings:Show()
        management:Hide()
--        if not isOfficer then
--            getglobal("JP_OuterFrame"):SetSize(651, 300)
--            getglobal("JP_OuterFrameTitleFrame"):SetSize(651, 24)
--            getglobal("JP_BenchFrame"):SetPoint("TOPLEFT", "JP_SettingsFrame", "TOPRIGHT")
--        end
    else
        settings:Hide()
        if isOfficer then
            management:Show()
--        else
--            getglobal("JP_OuterFrame"):SetSize(368, 300)
--            getglobal("JP_OuterFrameTitleFrame"):SetSize(368, 24)
--            getglobal("JP_BenchFrame"):SetPoint("TOPLEFT", "JP_OuterFrameList", "TOPRIGHT", 0, -4)
        end
    end
end