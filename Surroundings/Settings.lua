JP_Current_Settings = {}
_G.JP_Settings = {}
local Settings = _G.JP_Settings

function Settings:onSettingsClick()
    if not JP_SettingsFrame:IsVisible() then
        JP_SettingsFrame:Show()
        JP_Management:Hide()
    else
        JP_SettingsFrame:Hide()
        JP_Management:Show()
    end
end