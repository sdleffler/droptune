local lume = dtrequire("lib.lume")

local ecs = dtrequire("ecs")
local editable = dtrequire("editable")
local prototype = dtrequire("prototype")
local _, Component = dtrequire("entity").common()

local PhysicsSystem = dtrequire("systems.Physics")
local PhysicsComponent = Component:subtype({}, "droptune.components.PhysicsComponent")

-- Floating point epsilon for is-default-value comparisons during serialization
local EPSILON = 0.00000001

function PhysicsComponent:init(world, ...)
    assert(world, "PhysicsComponent must have a world with PhysicsSystem!")
    local physicsSystem = PhysicsSystem:getInstance(world)
    assert(physicsSystem, "cannot create PhysicsComponent for world without PhysicsSystem!")
    local physicsWorld = physicsSystem.physicsWorld
    
    self.body = love.physics.newBody(physicsWorld, ...)
end

local function visitCircleShape(shape, v)
    v("point", function(v)
        local x, y = shape:getPoint()
        v(1, x)
        v(2, y)
    end)
    v("radius", shape:getRadius())
end

local function visitPolygonShape(shape, v)
    local points = {shape:getPoints()}
    for i, coord in ipairs(points) do
        v(i, coord)
    end
end

local function visitEdgeOrChainShape(shape, v)
    local points = {shape:getPoints()}
    for i, coord in ipairs(points) do
        v(i, coord)
    end

    local x, y = shape:getNextVertex()
    v("nextVertex", x and y and function(v)
        v(1, x)
        v(2, y)
    end, x ~= nil and y ~= nil)

    local x, y = shape:getPreviousVertex()
    v("previousVertex", x and y and function(v)
        v(1, x)
        v(2, y)
    end, x ~= nil and y ~= nil)
end

local function visitFixtures(fixtures, v)
    for i, fixture in ipairs(fixtures) do
        v(i, function(v)
            local shape = fixture:getShape()
            v("shape", function(v)
                local ty = shape:getType()
                v("type", ty)

                if ty == "circle" then
                    visitCircleShape(shape, v)
                elseif ty == "polygon" then
                    visitPolygonShape(shape, v)
                elseif ty == "edge" or ty == "chain" then
                    visitChainOrEdgeShape(shape, v)
                else
                    -- Impossible as of LOVE 11.3.
                    error("Unrecognized shape type!")
                end
            end)

            local density = fixture:getDensity()
            v("density", density, density == 1)
            local friction = fixture:getFriction()
            v("friction", friction, math.abs(friction - 0.2) < EPSILON) -- EPSILON for float cmp
            local restitution = fixture:getRestitution()
            v("restitution", restitution, restitution == 0.0)

            local sensor = fixture:isSensor()
            v("sensor", sensor, not sensor)

            local categories, mask, group = fixture:getFilterData()
            v("filterData", function(v)
                v("categories", categories)
                v("mask", mask)
                v("group", group)
            end, categories == 1 and mask == 65535 and group == 0)

            local userData = fixture:getUserData()
            v("userData", userData, userData == nil)
        end)
    end
end

ecs.Serde[PhysicsComponent] = {
    serialize = function(self, v)
        local body = self.body

        v("position", function(v)
            local x, y = body:getPosition()
            v(1, x)
            v(2, y)
        end)
        v("angle", body:getAngle())

        do
            local x, y = body:getLinearVelocity()
            v("linearVelocity", function(v) 
                v(1, x)
                v(2, y)
            end, math.abs(x) < EPSILON and math.abs(y) < EPSILON)
        end

        local angularVelocity = body:getAngularVelocity()
        v("angularVelocity", angularVelocity, math.abs(angularVelocity) < EPSILON)

        local linearDamping = body:getLinearDamping()
        v("linearDamping", linearDamping, linearDamping == 0)

        local angularDamping = body:getAngularDamping()
        v("angularDamping", angularDamping, angularDamping == 0)

        local gravityScale = body:getGravityScale()
        v("gravityScale", gravityScale, gravityScale == 1)

        local bodytype = body:getType()
        v("massData", function(v)
            local x, y, mass, inertia = body:getMassData()
            v("point", function(v)
                v(1, x)
                v(2, y)
            end, math.abs(x) < EPSILON and math.abs(y) < EPSILON)
            v("mass", mass)
            v("inertia", inertia)
        end, bodytype == "static")

        local fixtures = body:getFixtures()
        v("fixtures", function(v)
            visitFixtures(fixtures, v)
        end, #fixtures == 0)

        --local joints = body:getJoints()
        -- This is tough because two different bodies will refer to the same
        -- joint. Some sort of deduplication/ID system will need to be used,
        -- similar to entities.
        -- 
        -- It is probably not a good idea or necessary to serialize the joints
        -- attached to a body as part of the body, as recreating the joints can
        -- be done only with all involved bodies.
        --v("joints", "TODO")

        local sleepingAllowed = body:isSleepingAllowed()
        v("sleepingAllowed", sleepingAllowed, sleepingAllowed)

        v("type", bodytype, bodytype == "static")

        local active = body:isActive()
        v("active", active, active)

        local bullet = body:isBullet()
        v("bullet", bullet, not bullet)

        local fixedRotation = body:isFixedRotation()
        v("fixedRotation", fixedRotation, not fixedRotation)

        local userData = body:getUserData()
        v("userData", userData, userData == nil)
    end,

    deserialize = function(world)
        return PhysicsComponent:new(world)
    end,
}

local function makeFixture(body, fixturetable)
    local shapetable = fixturetable.shape
    local shapetype = shapetable.type
    local shape

    if shapetype == "circle" then
        local point = shapetable.point
        shape = love.physics.newCircleShape(point.x, point.y, shapetable.radius)
    elseif shapetype == "polygon" then
        shape = love.physics.newPolygonShape(shapetable)
    elseif shapetype == "edge" or shapetype == "chain" then
        if shapetype == "edge" then
            shape = love.physics.newEdgeShape(unpack(shapetable))
        elseif shapetype == "chain" then
            shape = love.physics.newChainShape(false, shapetable)
        end

        local nextVertex = shapetable.nextVertex
        if nextVertex then
            shape:setNextVertex(unpack(nextVertex))
        end

        local previousVertex = shapetable.previousVertex
        if previousVertex then
            shape:setPreviousVertex(unpack(previousVertex))
        end
    end

    local fixture = love.physics.newFixture(body, shape, fixturetable.density)
    
    local friction = fixturetable.friction
    if friction then
        fixture:setFriction(friction)
    end

    local restitution = fixturetable.restitution
    if restitution then
        fixture:setRestitution(restitution)
    end

    local sensor = fixturetable.sensor
    if sensor then
        fixture:setSensor(sensor)
    end

    local filterData = fixturetable.filterData
    if filterData then
        fixture:setFilterData(
            filterData.categories,
            filterData.mask,
            filterData.group
        )
    end

    local userData = fixturetable.userData
    if userData then
        fixture:setUserData(userData)
    end
end

ecs.Visitor[PhysicsComponent] = {
    entry = function(self, k, v)
        local body = self.body
        if k == "position" then
            body:setPosition(unpack(v))
        elseif k == "angle" then
            body:setAngle(v)
        elseif k == "linearVelocity" then
            body:setLinearVelocity(unpack(v))
        elseif k == "angularVelocity" then
            body:setAngularVelocity(v)
        elseif k == "linearDamping" then
            body:setLinearDamping(v)
        elseif k == "angularDamping" then
            body:setAngularDamping(v)
        elseif k == "gravityScale" then
            body:setGravityScale(v)
        elseif k == "massData" then
            local x, y = unpack(v.point)
            body:setMassData(x, y, v.mass, v.inertia)
        elseif k == "fixtures" then
            for _, fixture in ipairs(v) do
                makeFixture(body, fixture)
            end
        elseif k == "sleepingAllowed" then
            body:setSleepingAllowed(v)
        elseif k == "type" then
            body:setType(v)
        elseif k == "active" then
            body:setActive(v)
        elseif k == "bullet" then
            body:setBullet(v)
        elseif k == "fixedRotation" then
            body:setFixedRotation(v)
        elseif k == "userData" then
            body:setUserData(v)
        end
    end,

    finish = function(self) return self end,
}

editable.registerComponent(PhysicsComponent, {
    updateUI = function(self, Slab)
        if self.body then
            Slab.BeginLayout("PhysicsComponentLayout", {
                Columns = 3,
            })
        
            Slab.SetLayoutColumn(1)
            Slab.Text("Position")
            Slab.Text("Velocity")
        
            local x, y, newX, newY = self.body:getPosition()
            local xv, yv, newXV, newYV = self.body:getLinearVelocity()
        
            Slab.SetLayoutColumn(2)
        
            Slab.Text(" X: ")
            Slab.SameLine()
            if Slab.Input("PhysicsComponentPosX", {
                ReturnOnText = false,
                Text = string.format("%.1f", x),
                NumbersOnly = true,
                W = 75,
            }) then
                newX = Slab.GetInputNumber()
            end
        
            Slab.Text(" X: ")
            Slab.SameLine()
            if Slab.Input("PhysicsComponentVelX", {
                ReturnOnText = false,
                Text = string.format("%.1f", xv),
                NumbersOnly = true,
                W = 75,
            }) then
                newXV = Slab.GetInputNumber()
            end
        
            Slab.SetLayoutColumn(3)
        
            Slab.Text(" Y: ")
            Slab.SameLine()
            if Slab.Input("PhysicsComponentPosY", {
                ReturnOnText = false,
                Text = string.format("%.1f", y),
                NumbersOnly = true,
                W = 75,
            }) then
                newY = Slab.GetInputNumber()
            end
        
            Slab.Text(" Y: ")
            Slab.SameLine()
            if Slab.Input("PhysicsComponentVelY", {
                ReturnOnText = false,
                Text = string.format("%.1f", yv),
                NumbersOnly = true,
                W = 75,
            }) then
                newYV = Slab.GetInputNumber()
            end
        
            Slab.EndLayout()
        
            if newX or newY then
                self.body:setPosition(newX or x, newY or y)
            end
        
            if newXV or newYV then
                self.body:setLinearVelocity(newXV or xv, newYV or yv)
            end
        else
            Slab.Text("Empty. Does this world have a PhysicsSystem?")
        end

        return self
    end,

    updateInteractableShapes = function(self, hc, shapes, camera)
        local x, y = camera:toScreen(self.body:getPosition())
        if not shapes[1] then
            shape = hc:circle(x, y, 4)
            shape.interaction = editable.interactions.DragInteraction:new(
                function(interaction, kind, x, y)
                    if kind == "mouse" then
                        self.body:setPosition(interaction.camera:toWorld(x, y))
                    end
                end,
                1
            )
            shapes[1] = shape
        else
            shapes[1]:moveTo(x, y)
        end

        local tx = love.math.newTransform(x, y, self.body:getAngle())
        local x, y = tx:transformPoint(16, 0)
        if not shapes[2] then
            shape = hc:circle(x, y, 4)
            shape.interaction = editable.interactions.DragInteraction:new(
                function(interaction, kind, x, y)
                    if kind == "mouse" then
                        local pivotx, pivoty = self.body:getPosition()
                        local mousex, mousey = interaction.camera:toWorld(x, y)
                        self.body:setAngle(lume.angle(pivotx, pivoty, mousex, mousey))
                    end
                end,
                1
            )
            shapes[2] = shape
        else
            shapes[2]:moveTo(x, y)
        end
    end,
})

return PhysicsComponent