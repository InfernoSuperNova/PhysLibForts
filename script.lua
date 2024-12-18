--- forts API ---
dofile("scripts/forts.lua")
dofile(path .. "/BetterLog.lua")

dofile(path .. "/physLib.lua")
dofile(path .. "/math/math.lua")
dofile(path .. "/math/vector.lua")
DebugMode = true


function Load()
    PhysLib:Load()
    Gravity = GetConstant("Physics.Gravity")
end

local frameRan = true
function Update(frame)
    if not frameRan then 
        BetterLog("Update Error detected")
        _G["Update"] = function() end
    end
    frameRan = false
    local startTime = GetRealTime()
    
    PhysLib:Update(frame)
    local endTime = GetRealTime()
    if (endTime - startTime) * 1000 > 35 then 
        -- BetterLog("Error: Runtime limit exceeded, destroying Update for your own sanity")
        -- _G["Update"] = function() end 

    end
    frameRan = true
end

function OnUpdate()
    local startTime = GetRealTime()
    PhysLib:OnUpdate()
    local endTime = GetRealTime()
    if (endTime - startTime) * 1000 > 40 then 
        BetterLog("Error: Runtime limit exceeded, destroying OnUpdate for your own sanity")
        _G["OnUpdate"] = function() end 

    end
end



function OnDeviceCreated(teamId, deviceId, saveName, nodeA, nodeB, t, upgradedId)
    PhysLib:OnDeviceCreated(teamId, deviceId, saveName, nodeA, nodeB, t, upgradedId)
end

function OnGroundDeviceCreated(teamId, deviceId, saveName, pos, upgradedId)
    PhysLib:OnGroundDeviceCreated(teamId, deviceId, saveName, pos, upgradedId)
end

function OnNodeCreated(nodeId, teamId, pos, foundation, selectable, extrusion)
    PhysLib:OnNodeCreated(nodeId, teamId, pos, foundation, selectable, extrusion)
end

function OnNodeDestroyed(nodeId, selectable)
    PhysLib:OnNodeDestroyed(nodeId, selectable)
end

function OnNodeBroken(thisNodeId, nodeIdNew)
    PhysLib:OnNodeBroken(thisNodeId, nodeIdNew)
end

function OnLinkCreated(teamId, saveName, nodeIdA, nodeIdB, pos1, pos2, extrusion)
    PhysLib:OnLinkCreated(teamId, saveName, nodeIdA, nodeIdB, pos1, pos2, extrusion)
end

function OnLinkDestroyed(teamId, saveName, nodeIdA, nodeIdB, breakType)
    PhysLib:OnLinkDestroyed(teamId, saveName, nodeIdA, nodeIdB, breakType)
end