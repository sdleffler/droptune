local hooks = dtrequire("editor.hooks")
local prototype = dtrequire("prototype")
local tiny = dtrequire("lib.tiny")

local PhysicsSystem = prototype.new()
do
    local oracle = setmetatable({}, {__mode = "k"})

    function PhysicsSystem:init(opts)
        local opts = opts or {}

        tiny.system(self)
        self.filter = dtrequire("components.Physics").filter

        -- We cannot use `self.world`; Tiny uses that to store a reference to
        -- the ECS world.
        self.physicsWorld = love.physics.newWorld(opts.gravityX or 0, opts.gravityY or 0, opts.sleep or true)
        
        if opts.meter then
            love.physics.setMeter(opts.meter)
        end
    end

    function PhysicsSystem:onAddToWorld(world)
        assert(not oracle[world], "world already contains a PhysicsSystem!")
        oracle[world] = self
    end

    function PhysicsSystem:onRemoveFromWorld(world)
        assert(oracle[world], "impossible???")
        oracle[world] = nil
        self.physicsWorld:destroy()
    end

    function PhysicsSystem:onRemove(e)
        e[dtrequire("components.Physics")].body:destroy()
    end

    function PhysicsSystem:update(dt)
        self.physicsWorld:update(dt)
    end

    function PhysicsSystem:getInstance(world)
        return oracle[world]
    end
end

hooks.registerSystem(PhysicsSystem, {
    updateUI = function(self, Slab)
        Slab.Text("TODO. bug sleffy about this shit, they bein' fucking lazy, the nerve of this dipshit")
    end,

    newDefault = function()
        return PhysicsSystem:new()
    end,
})

return PhysicsSystem