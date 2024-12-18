local API = PhysLib.API
API.Version = 1

--#region API Functions
function API:StringifyTable(t)
    local type = type(t)
    if type == "table"then
        local str = "{"
        for k, v in pairs(t) do
            str = str .. k .. "=" .. API:StringifyTable(v) .. ","
        end
        str = str .. "}"
        return str
    elseif type == "string" then
        -- TODO IMPLEMENT
    else
        return tostring(t)
    end

end


function APICallBack(callbackPath, result)
    ExecuteInScript(callbackPath, -1, "PhysLib.RV = " .. API:StringifyTable(result))
end


function API:RegisterObjectDefinition(callbackPath, saveName, objectDefinition)
    PhysLib.Definitions.Objects[saveName] = objectDefinition
    API:OnObjectDefinitionRegistered(saveName)
    APICallBack(callbackPath, true)
end

function API:UnregisterObjectDefinition(callbackPath, saveName)
    if not PhysLib.Definitions.Objects[saveName] then 
        APICallBack(callbackPath, false)
        return
    end
    PhysLib.Definitions.Objects[saveName] = nil
    API:OnObjectDefinitionUnregistered(saveName)
    APICallBack(callbackPath, true)
end

function API:GetObjectDefinition(callbackPath, saveName)
    local result = PhysLib.Definitions.Objects[saveName]
    APICallBack(callbackPath, result)
end



function API:RegisterLinkDefinition(callbackPath, saveName, linkDefinition)
    PhysLib.Definitions.Links[saveName] = linkDefinition
    API:OnLinkDefinitionRegistered(saveName)
    APICallBack(callbackPath, true)
end
function API:UnregisterLinkDefinition(callbackPath, saveName)
    if not PhysLib.Definitions.Links[saveName] then 
        APICallBack(callbackPath, false)
        return
    end
    PhysLib.Definitions.Links[saveName] = nil
    API:OnLinkDefinitionUnregistered(saveName)
    APICallBack(callbackPath, true)
end

function API:GetLinkDefinition(callbackPath, saveName)
    local result = PhysLib.Definitions.Links[saveName]
    APICallBack(callbackPath, result)
end

function API:RegisterPhysicsObject(callbackPath, pos, radius, velocity, objectDefinition, effectPath)
    local result = PhysLib.PhysicsObjects:Register(pos, radius, velocity, objectDefinition, effectPath)
    API:OnObjectRegistered(result)
    APICallBack(callbackPath, result)
end

function API:UnregisterPhysicsObject(callbackPath, objectId)
    local result = PhysLib.PhysicsObjects:Unregister(objectId)
    API:OnObjectUnregistered(objectId)
    APICallBack(callbackPath, result)
end

function API:GetObject(callbackPath, objectId)
    local result = PhysLib.PhysicsObjects:Get(objectId)
    APICallBack(callbackPath, result)
end

function API:GetObjectPosition(callbackPath, objectId)
    local result = PhysLib.PhysicsObjects:GetPosition(objectId)
    APICallBack(callbackPath, result)
end

function API:SetObjectPosition(callbackPath, objectId, pos)
    local result = PhysLib.PhysicsObjects:SetPosition(objectId, pos)
    APICallBack(callbackPath, result)
end

function API:GetObjectVelocity(callbackPath, objectId)
    local result = PhysLib.PhysicsObjects:GetVelocity(objectId)
    APICallBack(callbackPath, result)
end

function API:SetObjectVelocity(callbackPath, objectId, velocity)
    local result = PhysLib.PhysicsObjects:SetVelocity(objectId, velocity)
    APICallBack(callbackPath, result)
end

function API:GetObjectRadius(callbackPath, objectId)
    local result = PhysLib.PhysicsObjects:GetRadius(objectId)
    APICallBack(callbackPath, result)
end

function API:SetObjectRadius(callbackPath, objectId, radius)
    local result = PhysLib.PhysicsObjects:SetRadius(objectId, radius)
    APICallBack(callbackPath, result)
end

function API:GetObjectsObjectDefinition(callbackPath, objectId)
    local result = PhysLib.PhysicsObjects:GetObjectDefinition(objectId)
    APICallBack(callbackPath, result)
end
function API:SetObjectsObjectDefinition(callbackPath, objectId, objectDefinition)
    local result = PhysLib.PhysicsObjects:SetObjectDefinition(objectId, objectDefinition)
    APICallBack(callbackPath, result)
end

--#endregion

--#region event subscriber
function API:SubscribeToEvent(callbackPath, apiFunction, callbackFunction)
    local subscribers = API[apiFunction .. "Subscribers"]
    subscribers[#subscribers + 1] = {callbackPath, callbackFunction}
end
--#endregion


--#region API events


API.OnObjectDefinitionRegisteredSubscribers = {}
-- [1] = {"modPath", "callbackName"}
function API:OnObjectDefinitionRegistered(saveName)
    local subscribers = API.OnObjectDefinitionRegisteredSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "('" .. saveName .. "')")
    end
end
API.OnObjectDefinitionUnregisteredSubscribers = {}
function API:OnObjectDefinitionUnregistered(saveName)
    local subscribers = API.OnObjectDefinitionUnregisteredSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "('" .. saveName .. "')")
    end
end
API.OnObjectRegisteredSubscribers = {}
function API:OnObjectRegistered(objectId)
    local subscribers = API.OnObjectRegisteredSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "(" .. objectId .. ")")
    end
end
API.OnObjectUnregisteredSubscribers = {}
function API:OnObjectUnregistered(objectId)
    local subscribers = API.OnObjectUnregisteredSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "(" .. objectId .. ")")
    end
end
API.OnLinkDefinitionRegisteredSubscribers = {}
function API:OnLinkDefinitionRegistered(saveName)
    local subscribers = API.OnLinkDefinitionRegisteredSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "('" .. saveName .. "')")
    end
end
API.OnLinkDefinitionUnregisteredSubscribers = {}
function API:OnLinkDefinitionUnregistered(saveName)
    local subscribers = API.OnLinkDefinitionUnregisteredSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "('" .. saveName .. "')")
    end
end
API.OnObjectCollisionWithObjectSubscribers = {}
function API:OnObjectCollisionWithObject(objectIdA, objectIdB, objectAPos, objectBPos, normal, distance)
    local subscribers = API.OnObjectCollisionWithObjectSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "(" .. objectIdA .. "," .. objectIdB .. "," .. API:StringifyTable(objectAPos) .. "," .. API:StringifyTable(objectBPos) .. "," .. API:StringifyTable(normal) .. "," .. distance .. ")")
    end
end
API.OnObjectCollisionWithLinkSubscribers = {}
function API:OnObjectCollisionWithLink(objectId, objectAPos, nodeIdA, nodeIdB, nodePosA, nodePosB, t, normal, distance)
    local subscribers = API.OnObjectCollisionWithLinkSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "(" .. objectId .. "," .. API:StringifyTable(objectAPos) .. "," .. nodeIdA .. "," .. nodeIdB .. "," .. API:StringifyTable(nodePosA) .. "," .. API:StringifyTable(nodePosB) .. "," .. t .. "," .. API:StringifyTable(normal) .. "," .. distance .. ")")
    end
end
API.OnObjectTravelthroughPortalSubscribers = {}
function API:OnObjectTravelthroughPortal(objectId, nodeEnterIdA, nodeEnterIdB, nodeExitIdA, nodeExitIdB, t)
    local subscribers = API.OnObjectTravelthroughPortalSubscribers
    for i = 1, #subscribers do
        local subscriber = subscribers[i]
        ExecuteInScript(subscriber[1], -1, subscriber[2] .. "(" .. objectId .. "," .. nodeEnterIdA .. "," .. nodeEnterIdB .. "," .. nodeExitIdA .. "," .. nodeExitIdB .. "," .. t .. ")")
    end
end

--#endregion