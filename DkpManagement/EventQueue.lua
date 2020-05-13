local _, guildRosterHandler = ...
local GuildRosterHandler = guildRosterHandler.Handler

local EventInProgress = false
local EventQueue = {}
local LatestEvent = {}

function addEvent(event, name, arg1, arg2)
    EventQueue[table.getn(EventQueue) + 1] = {event, name, arg1, arg2}
    if not EventInProgress then
        executeEvent()
    end
end

function getLatestQueuedEvent()
    local queueSize = table.getn(EventQueue)
    if queueSize > 0 then
       return EventQueue[queueSize]
    else
        return copyTable(LatestEvent)
    end
end

function popEvent()
    LatestEvent = EventQueue[1]
    local lengthOfQueue = table.getn(EventQueue)

    if lengthOfQueue > 1 then
        for eventCount = 2, lengthOfQueue, 1 do
            EventQueue[eventCount - 1] = EventQueue[eventCount]
        end
        EventQueue[lengthOfQueue] = nil
    else
        EventQueue[1] = nil
    end
    return LatestEvent
end

local function waitForRosterUpdate()
    GuildRosterHandler:sendUpdateRequest()
    if GuildRosterHandler:waitingForUpdate() then
        jpWait(1, waitForRosterUpdate)
    else
        EventInProgress = false
        if table.getn(EventQueue) > 0 then
           executeEvent()
        end
    end
end

function executeEvent()
    EventInProgress = true
    local event = popEvent()
    event[1](event)
    GuildRosterHandler:requestRosterUpdate()
    waitForRosterUpdate()
end

-- Wait function from wowwiki --
local waitTable = {}
local waitFrame
function jpWait(delay, func, ...)
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