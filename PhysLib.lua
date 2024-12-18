--scripts/utility/physLib/physLib.lua
--#region class table
PhysLib = {
    Render = {},
    Structures = {},
    BspTrees = {
        ObjectTree = {},
        StructureTree = {},
        Helper = {},
    },
    NodesRaw = {},
    Nodes = {},

    ExistingLinks = {},
    Links = {},
    LinksTree = {},

    PhysicsObjects = {
        Objects = {},
        FlattenedObjects = {},
        ObjectsTree = {},
        globalId = 0
    },
    API = {},
    Definitions = {
        Links = {}
    }
}
--#endregion

--#region class loading
dofile(path .. "/definitions.lua")
dofile(path .. "/structures.lua")
dofile(path .. "/physicsObjects.lua")
dofile(path .. "/render.lua")
dofile(path .. "/bspTrees/helper.lua")
dofile(path .. "/bspTrees/objectTree.lua")
dofile(path .. "/bspTrees/structureTree.lua")
dofile(path .. "/api.lua")
--#endregion

--#region entrypoints
function PhysLib:Load()
    PhysLib.Nodes = {}
    PhysLib.NodesRaw = {}
    PhysLib.ExistingLinks = {}
    PhysLib.Links = {}
    PhysLib.LinksTree = {}

    
    EnumerateStructureLinks(0, -1, "c", true)
    EnumerateStructureLinks(1, -1, "c", true)
    EnumerateStructureLinks(2, -1, "c", true)

    self:UpdateNodeTable()
end

function PhysLib:Update(frame)

    self.Render:BeforePhysicsUpdate()

    self.Structures:UpdateNodePositions()


    -- Update links positions etc
    PhysLib.ExistingLinks = {}
    PhysLib.Links = {}

    EnumerateStructureLinks(0, -1, "d", true)
    EnumerateStructureLinks(1, -1, "d", true)
    EnumerateStructureLinks(2, -1, "d", true)


    self.BspTrees.StructureTree:Subdivide(PhysLib.Links)

    self.PhysicsObjects:Update()

    self.Render:PhysicsUpdate()
end

function PhysLib:OnUpdate()
    self.Render:OnUpdate()
end

--#region events
function PhysLib:OnDeviceCreated(teamId, deviceId, saveName, nodeA, nodeB, t, upgradedId)
    self:Load()
end

function PhysLib:OnGroundDeviceCreated(teamId, deviceId, saveName, pos, upgradedId)
    self:Load()
end

function PhysLib:OnNodeCreated(nodeId, teamId, pos, foundation, selectable, extrusion)
    -- Just assign pos since we're using the x and y directly from that
    pos.links = {}
    pos.id = nodeId
    pos.GetVelocity = function() if pos.velocity then return pos.velocity else
            pos.velocity = NodeVelocity(nodeId)
            return pos.velocity
        end end
    PhysLib.NodesRaw[nodeId] = pos
    self:UpdateNodeTable()
end

function PhysLib:OnNodeDestroyed(nodeId, selectable)
    local node = PhysLib.NodesRaw[nodeId]
    local linkedToNodes = node.links
    for otherLinkedNodeId, otherLink in pairs(linkedToNodes) do
        otherLink.node.links[nodeId] = nil
    end
    PhysLib.NodesRaw[nodeId] = nil
    self:UpdateNodeTable()
end

function PhysLib:OnNodeBroken(thisNodeId, nodeIdNew)
    -- Step 1, clear the links from the things that the node is linked to
    local existingNode = PhysLib.NodesRaw[thisNodeId]
    local linkedToNodes = existingNode.links
    for otherLinkedNodeId, otherLink in pairs(linkedToNodes) do
        otherLink.node.links[thisNodeId] = nil
    end

    -- Step 2, delete the node
    PhysLib.NodesRaw[thisNodeId] = nil
    -- Step 3, add the two nodes as normal
    local nodeA = NodePosition(thisNodeId)
    nodeA.links = {}
    nodeA.id = thisNodeId
    PhysLib.NodesRaw[thisNodeId] = nodeA
    local nodeB = NodePosition(nodeIdNew)
    nodeB.links = {}
    nodeB.id = nodeIdNew
    PhysLib.NodesRaw[nodeIdNew] = nodeB
    -- Step 4, recursively readd links to the nodes
    self:AddLinksRecursive(thisNodeId)
    self:AddLinksRecursive(nodeIdNew)

    self:UpdateNodeTable()
end

function PhysLib:OnLinkCreated(teamId, saveName, nodeIdA, nodeIdB, pos1, pos2, extrusion)
    local nodeA = PhysLib.NodesRaw[nodeIdA]
    local nodeB = PhysLib.NodesRaw[nodeIdB]

    nodeA.links[nodeIdB] = { node = nodeB, material = saveName }
    nodeB.links[nodeIdA] = { node = nodeA, material = saveName }
    self:UpdateNodeTable()
end

function PhysLib:OnLinkDestroyed(teamId, saveName, nodeIdA, nodeIdB, breakType)
    local nodeA = PhysLib.NodesRaw[nodeIdA]
    local nodeB = PhysLib.NodesRaw[nodeIdB]

    nodeA.links[nodeIdB] = nil
    nodeB.links[nodeIdA] = nil
    self:UpdateNodeTable()
end
--#endregion
--#region Events utility

function PhysLib:AddLinksRecursive(nodeId)
    local node = PhysLib.NodesRaw[nodeId]

    local linkCount = NodeLinkCount(nodeId)

    for index = 0, linkCount - 1 do
        local otherNodeId = NodeLinkedNodeId(nodeId, index)
        local otherNode = PhysLib.NodesRaw[otherNodeId]
        local saveName = GetLinkMaterialSaveName(nodeId, otherNodeId)
        node.links[otherNodeId] = { node = otherNode, material = saveName }
        otherNode.links[nodeId] = { node = node, material = saveName }
    end
end


function PhysLib:UpdateNodeTable()
    PhysLib.Nodes = FlattenTable(PhysLib.NodesRaw)
end

--#endregion
--#endregion

--#region Utility
function HighlightExtents(extents, duration, color)
    duration = duration or 0.06
    color = color or White()
    local topLeft = Vec3(extents.minX, extents.minY)
    local topRight = Vec3(extents.maxX, extents.minY)
    local bottomRight = Vec3(extents.maxX, extents.maxY)
    local bottomLeft = Vec3(extents.minX, extents.maxY)




    SpawnLine(topLeft, topRight, color, duration)
    SpawnLine(topRight, bottomRight, color, duration)
    SpawnLine(bottomRight, bottomLeft, color, duration)
    SpawnLine(bottomLeft, topLeft, color, duration)
end

function HighlightCapsule(posA, posB, radius, color)
    color = color or White()
    SpawnCircle(posA, radius, color, 0.06)
    SpawnCircle(posB, radius, color, 0.06)
    local lineUnit = Vec2Normalize({ x = posB.x - posA.x, y = posB.y - posA.y})
    local linePerp = Vec2Perp(lineUnit)
    linePerp = Vec3(linePerp.x, linePerp.y, 0)

    
    SpawnLine({x = posA.x + radius * linePerp.x, y = posA.y + radius * linePerp.y}, {x = posB.x + radius * linePerp.x, y = posB.y + radius * linePerp.y}, color, 0.06)
    SpawnLine({x = posA.x - radius * linePerp.x, y = posA.y - radius * linePerp.y}, {x = posB.x - radius * linePerp.x, y = posB.y - radius * linePerp.y}, color, 0.06)

end
function FlattenTable(input)
    local output = {}
    local index = 0
    for k, v in pairs(input) do
        index = index + 1
        output[index] = v
    end
    return output
end
--#endregion





-- B1 is the initial frame, B2 is the final frame
function CollisionBetweenLinks(A1, A2, B1, B2, Radius)

    -- P is the intersection point between both lines. It can be reused from ClosestPointsBetweenLines function
    local P = A1 - (A2-A1) * (Vec3Dot(A1-B1, A2-A1)*Vec3Dot(B2-B1, B2-B1) - Vec3Dot(A1-B1, B2-B1)*Vec3Dot(A2-A1, B2-B1)) / (Vec2Cross(A2-A1, B2-B1)*Vec2Cross(A2-A1, B2-B1))

    local result = P + Radius * (B1-B2)*Vec3Dot(A2-A1, A2-A1) / Vec3Length((A2-A1)*Vec3Dot(B1-B2, A2-A1) - (B1-B2)*Vec3Dot(A2-A1, A2-A1))

    return result;
end