local LastAction
local PlayerInLastAction
local AmountInLastAction
local GuildRosterInLastAction

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

function resetLastAction()
    LastAction = nil
    PlayerInLastAction = nil
    AmountInLastAction = nil
    GuildRosterInLastAction = nil
end

function getLastAction()
    return LastAction
end

function getLastActionPlayer()
    return PlayerInLastAction
end

function getLastActionAmount()
    return AmountInLastAction
end

function getLastActionRoster()
    return GuildRosterInLastAction
end

