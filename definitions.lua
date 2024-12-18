


PhysLib.Definitions.Links = {
    [""] =              {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["bracing"] =       {DynamicFriction = 1,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["armour"] =        {DynamicFriction = 0.2,     StaticFriction = 8,         ConveyorSpeed = 0},
    ["door"] =          {DynamicFriction = 0.2,     StaticFriction = 8,         ConveyorSpeed = 0},
    ["rope"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["fuse"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["shield"] =        {DynamicFriction = 0,       StaticFriction = 0,         ConveyorSpeed = 0},
    ["portal"] =        {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    ["solarpanel"] =    {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = 0},
    --conveyor 1
    ["c1l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -60,        Conveyor = true}, -- left
    ["c1r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  60,        Conveyor = true}, -- right
    ["c1pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -120,       Conveyor = true}, -- left powered
    ["c1pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  120,       Conveyor = true}, -- right powered
    
    --conveyor 2
    ["c2l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -120,       Conveyor = true}, -- left
    ["c2r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  120,       Conveyor = true},
    ["c2pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -240,       Conveyor = true},
    ["c2pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  240,       Conveyor = true},

    -- conveyor 3
    ["c3l"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -240,       Conveyor = true},
    ["c3r"]  =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  240,       Conveyor = true},
    ["c3pl"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed = -480,       Conveyor = true},
    ["c3pr"] =          {DynamicFriction = 4,       StaticFriction = 8,         ConveyorSpeed =  480,       Conveyor = true},
}
PhysLib.Definitions.Objects = {
    [""] =              {springConst = 2.2,         dampening = 0.7,            DynamicFriction = 4,        StaticFriction = 4,         CollidesWithOthers = true}
}
