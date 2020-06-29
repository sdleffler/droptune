local components = dtrequire("components")
local ecs = dtrequire("ecs")
local lume = dtrequire("lib.lume")

local transformers = {
    components.Physics,
    components.Position,
}

local TransformSystem = ecs.System:subtype("droptune.systems.Transform")
do
    function TransformSystem:filter(e)
        return true
    end

    function TransformSystem:onAdd(e)
        local t = love.math.newTransform()
        local fs = lume.chain(transformers)
            :filter(function(c) return e[c] ~= nil end)
            :map(function(c)
                local instance, applyTo = e[c], c.applyTo
                return function(t) applyTo(instance, t) end
            end)
            :result()
        local world = self.world

        function e.getTransform()
            t:reset()
            for _, f in ipairs(fs) do
                f(t)
            end

            return t
        end
    end

    TransformSystem.onChange = TransformSystem.onAdd

    function TransformSystem:onRemove(e)
        e.getTransform = nil
    end
end

return TransformSystem