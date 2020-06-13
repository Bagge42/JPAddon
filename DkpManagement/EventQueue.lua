local Jp = _G.Jp
local GuildRosterHandler = Jp.GuildRosterHandler
local Utils = Jp.Utils
local EventQueue = {}
Jp.EventQueue = EventQueue

local EventInProgress = false
local Queue = {}
local LatestEvent = {}

function EventQueue:addEvent(event, eventName, zone, arg1, arg2)
    Queue[table.getn(Queue) + 1] = {event, eventName, zone, arg1, arg2}
    if not EventInProgress then
        EventQueue:executeEvent()
    end
end

function EventQueue:getLatestQueuedEvent()
    local queueSize = table.getn(Queue)
    if queueSize > 0 then
       return Queue[queueSize]
    else
        return Utils:copyTable(LatestEvent)
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

-- Wait function from wowwiki --
local waitTable = {}
local waitFrame
local function jpWait(delay, func, ...)
    if(type(delay)~="number" or type(func)~="function") then
        return false
    end
    if(waitFrame == nil) then
        waitFrame = CreateFrame("Frame","WaitFrame", UIParent)
        waitFrame:SetScript("onUpdate",function (self,elapse)
            local count = #waitTable
            local i = 1
            while(i<=count) do
                local waitRecord = tremove(waitTable,i)
                local d = tremove(waitRecord,1)
                local f = tremove(waitRecord,1)
                local p = tremove(waitRecord,1)
                if(d>elapse) then
                    tinsert(waitTable,i,{d-elapse,f,p})
                    i = i + 1
                else
                    count = count - 1
                    f(unpack(p))
                end
            end
        end)
    end
    tinsert(waitTable,{delay,func,{...}})
    return true
end

local function waitForRosterUpdate()
    GuildRosterHandler:sendUpdateRequest()
    if GuildRosterHandler:waitingForUpdate() then
        jpWait(1, waitForRosterUpdate)
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