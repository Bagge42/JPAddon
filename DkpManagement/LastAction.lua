local LastAction
local PlayerInLastAction
local AmountInLastAction
local GuildRosterInLastAction
local BenchInLastAction

function singlePlayerAction(action, player, amount)
    LastAction = action
    PlayerInLastAction = player
    AmountInLastAction = amount
end

function raidAddAction(amount, bench)
    LastAction = UNDO_ACTION_RAIDADD
    AmountInLastAction = amount
    BenchInLastAction = bench
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

function getLastActionBench()
    return BenchInLastAction
end
