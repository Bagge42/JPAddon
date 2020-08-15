local Jp = _G.Jp
local Invite = {}
Jp.Invite = Invite

function Invite:onLoad()
    getglobal("JP_InviteFrameTitleFrameName"):SetText(INVITE_FRAME_TITLE)
end