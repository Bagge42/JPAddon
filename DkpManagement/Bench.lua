local Bench = {}

function isBenched(player)
    return Bench[player] == true
end

function changeBenchState(player)
    if Bench[player] then
        Bench[player] = nil
    else
        Bench[player] = true
    end
end

function getBench()
    return Bench
end