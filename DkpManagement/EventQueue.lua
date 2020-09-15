local Jp = _G.Jp
local GuildRosterHandler = Jp.GuildRosterHandler
local Utils = Jp.Utils
local EventQueue = {}
Jp.EventQueue = EventQueue

local EventInProgress = false
local Queue = {}
local LatestEvent = {}

function EventQueue:addEvent(event, eventName, zone, arg1, arg2, arg3)
    Queue[table.getn(Queue) + 1] = {event, eventName, zone, arg1, arg2, arg3}
    if not EventInProgress then
        EventQueue:executeEvent()
    end
end

function EventQueue:getLatestQueuedEvent()
    local queueSize = table.getn(Queue)
    if queueSize > 0 then
       return Queue[queueSize]
    else
        return Utils:copy(LatestEvent)
    end
end

local function popEvent()
    LatestEvent = Queue[1]
    local lengthOfQueue = table.getn(Queue)

    if lengthOfQueue > 1 then
        for eventCount = 2, lengthOfQueue, 1 do
            Queue[eventCount - 1] = Queue[eventCount]
        end
        Queue[lengthOfQueue] = nil
    else
        Queue[1] = nil
    end
    return LatestEvent
end

local function waitForRosterUpdate()
    GuildRosterHandler:sendUpdateRequest()
    if GuildRosterHandler:waitingForUpdate() then
        Utils:jpWait(1, waitForRosterUpdate)
    else
        EventInProgress = false
        if table.getn(Queue) > 0 then
            EventQueue:executeEvent()
        end
    end
end

function EventQueue:executeEvent()
    EventInProgress = true
    local event = popEvent()
    event[1](event)
    GuildRosterHandler:requestRosterUpdate()
    waitForRosterUpdate()
end