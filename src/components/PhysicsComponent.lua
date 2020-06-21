local editable = dtrequire("editable")
local _, Component = unpack(dtrequire("entity"))

local PhysicsSystem = dtrequire("systems.PhysicsSystem")
local PhysicsComponent = Component:subtype()

function PhysicsComponent:init(world, ...)
    local physicsSystem = PhysicsSystem:getInstance(world)
    assert(physicsSystem, "cannot create PhysicsComponent for world without PhysicsSystem!")
    local physicsWorld = physicsSystem.world
    
    self.body = love.physics.newBody(physicsWorld, ...)
end

editable.registerComponent(PhysicsComponent, {
    buildUI = function(self, Slab)
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
    end,
})

return PhysicsComponent