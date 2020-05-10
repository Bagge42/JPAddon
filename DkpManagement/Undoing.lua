local LastAction
local PlayerInLastAction
local AmountInLastAction
local GuildRosterInLastAction

local function undoDecay()

end

function undo()
    if LastAction == nil then
        return
    elseif LastAction == UNDO_ACTION_SUBBED or LastAction == UNDO_ACTION_ADDED then
        modifyPlayerDkp(PlayerInLastAction, -AmountInLastAction)
    elseif LastAction == UNDO_ACTION_DECAY then
        undoDecay()
    elseif LastAction == UNDO_ACTION_RAIDADD then
        modifyRaidDkp(-AmountInLastAction)
    end
    LastAction = nil
    PlayerInLastAction = nil
    AmountInLastAction = nil
    GuildRosterInLastAction = nil
end

function singlePlayerAction(action, player, amount)
    LastAction = action
    PlayerInLastAction = player
    AmountInLastAction = amount
end

function raidAddAction(amount)
    LastAction = UNDO_ACTION_RAIDADD
    AmountInLastAction = amount
end

function decayAction(rosterPriorToDecay)
    LastAction = UNDO_ACTION_DECAY
    GuildRosterInLastAction = rosterPriorToDecay
end

