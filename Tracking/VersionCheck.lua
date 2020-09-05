local Jp = _G.Jp
local VersionCheck = {}
local Utils = Jp.Utils
local GuildRosterHandler = Jp.GuildRosterHandler
Jp.VersionCheck = VersionCheck

local versions = {}
local playersOnlineAtCheck = {}

local function printVersions()
    local ownVersion = GetAddOnMetadata("Jpdkp", "Version")
    Utils:jpMsg("Following online people has outdated versions:")
    for player, version in pairs(versions) do
        if (version < ownVersion) then
            Utils:jpMsg(player .. ": " .. version)
        end
    end
    Utils:jpMsg("Following people did not have jpdkp on check:")
    for player, _ in pairs(playersOnlineAtCheck) do
        if (versions[player] == nil) then
            Utils:jpMsg(player)
        end
    end
end

function VersionCheck:requestCheck()
    local msg = VERSION_CHECK_REQUEST
    playersOnlineAtCheck = GuildRosterHandler:getOnlinePeople()
    Utils:sendAddonMsg(msg, "GUILD")
    Utils:jpWait(3, printVersions)
end

local function getAndSendVersion()
    local version = GetAddOnMetadata("Jpdkp", "Version")
    local msg = VERSION .. "&" .. version
    Utils:sendAddonMsg(msg, "GUILD")
end

function VersionCheck:onEvent(event, ...)
    local prefix, msg, channel, sender, target, zoneChannelID, localID, name, instanceID = ...

    if (event == "CHAT_MSG_ADDON") then
        if (prefix == ADDON_PREFIX) then
            local msgPrefix, version = string.split("&", msg)
            if (msgPrefix == VERSION_CHECK_REQUEST) then
                getAndSendVersion()
            elseif (msgPrefix == VERSION) and Utils:isOfficer() and (Utils:removeRealmName(sender) ~= nil) then
                versions[Utils:removeRealmName(sender)] = version
            end
        end
    end
end