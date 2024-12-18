--scripts/utility/physLib/physicsObjects.lua



local PhysicsObjects = PhysLib.PhysicsObjects
local StructureTree = PhysLib.BspTrees.StructureTree
local ObjectTree = PhysLib.BspTrees.ObjectTree

local LinkDefinitions = PhysLib.Definitions.Links
local ObjectDefinitions = PhysLib.Definitions.Objects
local API = PhysLib.API
function PhysicsObjects:Update()
    local objects = self.Objects
    local flattenedObjects = self.FlattenedObjects
    self:CalculateObjectsExtents(objects)

    local collidingWithOtherObjects = {}

    for _, object in pairs(objects) do
        local objectDefinition = object.objectDefinition
        if objectDefinition.CollidesWithOthers then
            
            collidingWithOtherObjects[#collidingWithOtherObjects + 1] = object
        end
    end

    ObjectTree.ObjectsTree = GenerateObjectTree(collidingWithOtherObjects)


    local delta = data.updateDelta
    for i = 1, #flattenedObjects do
        local object = flattenedObjects[i]
        object.lastFramePos.x = object.pos.x
        object.lastFramePos.y = object.pos.y
    end
    for i = 1, #flattenedObjects do
        local object = flattenedObjects[i]
        self:ProcessIntegration(object, delta)
    end
    for i = 1, #collidingWithOtherObjects do
        local object = collidingWithOtherObjects[i]
        self:ProcessObjectCollisions(object, delta)
    end
    for i = 1, #collidingWithOtherObjects do
        local object = collidingWithOtherObjects[i]
        self:ProcessKineticChanges(object)
    end
    for i = 1, #flattenedObjects do
        self:FinalIntegration(flattenedObjects[i], delta)
    end
    for i = 1, #flattenedObjects do
        -- HighlightCapsule(objects[i].lastFramePos, objects[i].pos, objects[i].radius)
        self:ProcessStructureCollisions(flattenedObjects[i], delta)
        -- HighlightCapsule(objects[i].lastFramePos, objects[i].pos, objects[i].radius, Red())
    end
end

function PhysicsObjects:GenerateFlattenedObjectsTable()
    local objects = self.Objects
    local flattenedObjects = {}
    for k, v in pairs(objects) do
        flattenedObjects[#flattenedObjects + 1] = v
    end
    self.FlattenedObjects = flattenedObjects
end


function PhysicsObjects:ProcessIntegration(object, delta)
    local objectPos = object.pos
    object.lastFramePos.x = objectPos.x
    object.lastFramePos.y = objectPos.y



    objectPos.x = objectPos.x + (delta * 0.5 * object.velocity.x)
    objectPos.y = objectPos.y + (delta * 0.5 * object.velocity.y)
    object.velocity.y = object.velocity.y + Gravity * delta
end

function PhysicsObjects:FinalIntegration(object, delta)
    local objectPos = object.pos
    objectPos.x = objectPos.x + (delta * 0.5 * object.velocity.x)
    objectPos.y = objectPos.y + (delta * 0.5 * object.velocity.y)
end

function PhysicsObjects:ProcessObjectCollisions(object, delta)

    local objectResults = ObjectTree:ObjectCast(object)

    local posChange = {}
    local velChange = {}
    for i = 1, #objectResults do
        self:ProcessObjectCollisionResult(object, objectResults[i], posChange, velChange, delta)
    end
    object.posChange = posChange
    object.velChange = velChange
end

function PhysicsObjects:ProcessKineticChanges(object)
    local posChange = object.posChange
    local velChange = object.velChange

    for i = 1, #posChange do
        local posChange = posChange[i]
        local velChange = velChange[i]

        --object.pos.x = object.pos.x + posChange.x
        --object.pos.y = object.pos.y + posChange.y
        object.velocity.x = object.velocity.x + velChange.x
        object.velocity.y = object.velocity.y + velChange.y
    end
    object.posChange = nil
    object.velChange = nil
end

function PhysicsObjects:ProcessObjectCollisionResult(objectA, result, posChange, velChange, delta)
    --delta = 1 / delta
    local objectB = result.object
    local distance = result.distance
    if distance == 0 then return end
    local normal = result.normal

    local displacement = (objectA.radius + objectB.radius - distance)

    local displacementX = displacement * normal.x
    local displacementY = displacement * normal.y

    local posChangeLocal = { x = displacementX / 2, y = displacementY / 2 }

    API:OnObjectCollisionWithObject(objectA.id, objectB.id, result.objectAPos, result.objectBPos, result.normal, result.distance)
    local velocityA = objectA.velocity
    local velocityAX = velocityA.x
    local velocityAY = velocityA.y
    local velocityB = objectB.velocity
    local velocityBX = velocityB.x
    local velocityBY = velocityB.y
    local relativeVelocityX = velocityAX - velocityBX
    local relativeVelocityY = velocityAY - velocityBY

    --local velChangeLocal = {x = relativeVelocityX * normal.x / 2 * normal.x, y = relativeVelocityY * normal.y / 2 * normal.y}
    -- BetterLog(objectA.radius + objectB.radius - distance)
    --velChangeLocal.x = velChangeLocal.x + normal.x * 10 * (objectA.radius + objectB.radius - distance)
    --velChangeLocal.y = velChangeLocal.y + normal.y * 10 * (objectA.radius + objectB.radius - distance)

    local objDefA = objectA.objectDefinition
    local objDefB = objectB.objectDefinition
    local velChangeLocal = {}
    local springX = objDefA.SpringConst * objDefB.SpringConst * displacementX
    local springY = objDefA.SpringConst * objDefB.SpringConst * displacementY
    local dampeningX = objDefA.Dampening * objDefB.Dampening * relativeVelocityX
    local dampeningY = objDefA.Dampening * objDefB.Dampening * relativeVelocityY

    velChangeLocal.x = springX - dampeningX
    velChangeLocal.y = springY - dampeningY


    posChange[#posChange + 1] = posChangeLocal
    velChange[#velChange + 1] = velChangeLocal
end

function PhysicsObjects:ProcessStructureCollisions(object, delta)
    local snapResults, portalResults = StructureTree:CircleCast(object.lastFramePos, object.pos, object.radius)
    
    local posChange = {}
    local velChange = {}

    for i = 1, #snapResults do
        local snapResult = snapResults[i]
        self:ProcessStructureCollisionResult(object, snapResult, posChange, velChange, delta, #snapResults)
    end
    for i = 1, #portalResults do
        local portalResult = portalResults[i]
        self:ProcessPortalCollisionResult(object, portalResult)
    end
    if #snapResults == 0 then return end
    if object.InterpolateThisFrame then
        local testPos = snapResults[1].testPos

        object.pos.x = testPos.x
        object.pos.y = testPos.y
    end
    

    for i = 1, #snapResults do
        local posChange = posChange[i]
        local velChange = velChange[i]

        object.pos.x = object.pos.x + posChange.x
        object.pos.y = object.pos.y + posChange.y
        object.velocity.x = object.velocity.x + velChange.x
        object.velocity.y = object.velocity.y + velChange.y
    end
end

function PhysicsObjects:ProcessPortalCollisionResult(object, result)
    object.InterpolateThisFrame = false

    local nodeA = result.nodeA
    local nodeB = result.nodeB

    local nodeIdA = nodeA.id
    local nodeIdB = nodeB.id

    local destinationA = GetPortalDestinationA(nodeIdA, nodeIdB)
    local destinationB = GetPortalDestinationB(nodeIdA, nodeIdB)

    API:OnObjectTravelthroughPortal(object.id, nodeIdA, nodeIdB, destinationA, destinationB, result.linkT)
    if destinationA == 0 then return end

    local destinationANode = PhysLib.NodesRaw[destinationA]
    local destinationBNode = PhysLib.NodesRaw[destinationB]

    local destinationLink =  { x = destinationBNode.x - destinationANode.x, y = destinationBNode.y - destinationANode.y }
    local destinationLinkLength = math.sqrt(destinationLink.x * destinationLink.x + destinationLink.y * destinationLink.y)
    local destinationLinkNormal = { x = destinationLink.y / destinationLinkLength, y = -destinationLink.x / destinationLinkLength }
    local destinationLinkUnit = { x = destinationLink.x / destinationLinkLength, y = destinationLink.y / destinationLinkLength }

    local originalPortalLink = { x = nodeB.x - nodeA.x, y = nodeB.y - nodeA.y }
    local originalPortalLinkLength = math.sqrt(originalPortalLink.x * originalPortalLink.x + originalPortalLink.y * originalPortalLink.y)
    local originalPortalLinkUnit = { x = originalPortalLink.x / originalPortalLinkLength, y = originalPortalLink.y / originalPortalLinkLength }
    local originalPortalLinkNormal = { x = originalPortalLinkUnit.y, y = -originalPortalLinkUnit.x }

    local lastFramePosToNodePos = { x = object.lastFramePos.x - nodeA.x, y = object.lastFramePos.y - nodeA.y }
    local portalSideSign = Vec2Dot(originalPortalLinkNormal, lastFramePosToNodePos) > 0 and 1 or  -1

    local destinationPos = Vec2Lerp(destinationANode, destinationBNode, result.linkT)
    destinationPos = {x = destinationPos.x - destinationLinkNormal.x * (object.radius + 1) * portalSideSign, y = destinationPos.y - destinationLinkNormal.y * (object.radius + 1) * portalSideSign, z = 0}
    object.pos = destinationPos
    SpawnCircle(destinationPos, 50, White(), 0.04)

    local velocityParallel = Vec2Dot(object.velocity, originalPortalLinkUnit)
    local velocityPerpendicular = Vec2Dot(object.velocity, originalPortalLinkNormal)


    local destinationVelocityX = velocityParallel * destinationLinkUnit.x + velocityPerpendicular * destinationLinkNormal.x
    local destinationVelocityY = velocityParallel * destinationLinkUnit.y + velocityPerpendicular * destinationLinkNormal.y
    local destinationVelocity = { x = destinationVelocityX, y = destinationVelocityY }
    object.velocity = destinationVelocity
    
end


function PhysicsObjects:ProcessStructureCollisionResult(object, result, posChange, velChange, delta, totalCount)
    local objectPos = object.pos


    
    local velocity = object.velocity
    local velocityX = velocity.x
    local velocityY = velocity.y
    local velChangeX = 0
    local velChangeY = 0
    local radius = object.radius
    local linkNormal = result.normal
    local linkUnit = { x = linkNormal.y, y = -linkNormal.x }
    if result.type == 2 then
        linkNormal.x = linkNormal.x / totalCount
        linkNormal.y = linkNormal.y / totalCount
    end                                                                                                            -- A little bit hacky
    local dist = result.distance
    local t = result.t

    local materialSaveName = result.material
    local nodeA = result.nodeA
    local nodeB = result.nodeB
    API:OnObjectCollisionWithLink(object.id, object.pos, nodeA.id, nodeB.id, {x = nodeA.x, y = nodeA.y}, {x = nodeB.x, y = nodeB.y}, t, linkNormal, dist)
    local linkDefinition = LinkDefinitions[materialSaveName]
    if not linkDefinition then linkDefinition = LinkDefinitions[""] LinkDefinitions[materialSaveName] = linkDefinition  end
    local objectDefinition = object.objectDefinition
    local platformVelocity = Vec2Lerp(NodeVelocity(nodeA.id), NodeVelocity(nodeB.id), t)

    platformVelocity.x = platformVelocity.x * 0.5
    platformVelocity.y = platformVelocity.y * 0.5
    -- Shifting frame of reference
    local conveyorSpeed = linkDefinition.ConveyorSpeed
    velocityX = velocityX - platformVelocity.x + conveyorSpeed * linkUnit.x
    velocityY = velocityY - platformVelocity.y + conveyorSpeed * linkUnit.y

    -- Calculating position/velocity change from direct impact
    local velocityPerpendicular = velocityX * linkNormal.x + velocityY * linkNormal.y
    local velocityParallel = velocityX * linkUnit.x + velocityY * linkUnit.y
    local error = radius - dist

    -- Rigid force
    local posChangeLocal = { x = (0.1 + error) * linkNormal.x, y = (0.1 + error) * linkNormal.y }
    local velChangeLocal = { x = -velocityPerpendicular * linkNormal.x, y = -velocityPerpendicular * linkNormal.y }

    -- Gravity friction
    local gravityFriction = -Gravity * linkNormal.y / 1000

    -- Dynamic friction
    local frictionForce = objectDefinition.DynamicFriction * linkDefinition.DynamicFriction * gravityFriction *
    velocityParallel
    local frictionForceX = -frictionForce * linkUnit.x
    local frictionForceY = -frictionForce * linkUnit.y

    -- Add friction to velocity change
    velChangeX = velChangeX + frictionForceX * delta
    velChangeY = velChangeY + frictionForceY * delta

    -- Return to world frame
    velChangeX = velChangeX + platformVelocity.x - conveyorSpeed * linkUnit.x
    velChangeY = velChangeY + platformVelocity.y - conveyorSpeed * linkUnit.y

    velChangeLocal.x = velChangeLocal.x + velChangeX
    velChangeLocal.y = velChangeLocal.y + velChangeY

    -- Apply static friction
    if (math.abs(velocityParallel) < (objectDefinition.StaticFriction * linkDefinition.StaticFriction * gravityFriction)) then
        velChangeLocal.x = velChangeLocal.x - velocityParallel * linkUnit.x
        velChangeLocal.y = velChangeLocal.y - velocityParallel * linkUnit.y
    end

    posChange[#posChange + 1] = posChangeLocal
    velChange[#velChange + 1] = velChangeLocal
    -- objectPos.x = testPos.x + error * normal.x
    -- objectPos.y = testPos.y + error * normal.y
    -- velocity.x = velocity.x - velocityPerpToSurface * normal.x
    -- velocity.y = velocity.y - velocityPerpToSurface * normal.y
end

local defaultObjectDefinition = {

    SpringConst = 3,
    Dampening = 0.45,
    DynamicFriction = 4,
    StaticFriction = 4,
}

function PhysicsObjects:Register(pos, radius, velocity, definitionSaveName, effectPath)
    pos = pos or Vec3(0, 0, 0)
    radius = radius or (50 / 2)
    velocity = velocity or Vec3(0, 0, 0)
    definitionSaveName = definitionSaveName or ""
    local id = PhysicsObjects.globalId
    local Object = {
        pos = pos,
        radius = radius,
        velocity = velocity,
        objectDefinition = ObjectDefinitions[definitionSaveName],
        lastFramePos = { x = 0, y = 0 },
        effectId = SpawnEffect(effectPath, pos),
        extents = {},
        id = id
    }
    local objects = self.Objects
    objects[id] = Object
    PhysicsObjects.globalId = PhysicsObjects.globalId + 1
    self:GenerateFlattenedObjectsTable()
    return Object
end

function PhysicsObjects:Unregister(objectId)
    local objects = self.Objects
    local object = objects[objectId]
    if not object then return false end
    DestroyEffect(object.effectId)
    objects[objectId] = nil
    self:GenerateFlattenedObjectsTable()
    return true
end

function PhysicsObjects:CalculateObjectsExtents(Objects)
    for k, v in pairs(Objects) do
        self:CalculateObjectExtents(v)
    end
end

function PhysicsObjects:CalculateObjectExtents(object)
    local radius = object.radius
    local prevPos = object.lastFramePos
    local pos = object.pos

    local posX = pos.x
    local posY = pos.y
    local prevPosX = prevPos.x
    local prevPosY = prevPos.y

    local minX = (posX < prevPosX and posX or prevPosX) - radius
    local minY = (posY < prevPosY and posY or prevPosY) - radius
    local maxX = (posX > prevPosX and posX or prevPosX) + radius
    local maxY = (posY > prevPosY and posY or prevPosY) + radius

    object.extents = { minX = minX, minY = minY, maxX = maxX, maxY = maxY, center = { x = (minX + maxX) / 2, y = (minY + maxY) / 2 } }
end


function PhysicsObjects:GetObject(objectId)
    return self.Objects[objectId]
end

function PhysicsObjects:GetPosition(objectId)
    return self.Objects[objectId].pos
end

function PhysicsObjects:GetVelocity(objectId)
    return self.Objects[objectId].velocity
end

function PhysicsObjects:GetRadius(objectId)
    return self.Objects[objectId].radius
end

function PhysicsObjects:SetPosition(objectId, pos)
    self.Objects[objectId].pos = pos
end

function PhysicsObjects:SetVelocity(objectId, velocity)
    self.Objects[objectId].velocity = velocity
end

function PhysicsObjects:SetRadius(objectId, radius)
    self.Objects[objectId].radius = radius
end

function PhysicsObjects:GetObjectDefinition(objectId)
    return self.Objects[objectId].objectDefinition
end

function PhysicsObjects:SetObjectDefinition(objectId, objectDefinition)
    self.Objects[objectId].objectDefinition = ObjectDefinitions[objectDefinition]
end