local components = dtrequire("components")
local ecs = dtrequire("ecs")
local cpml = dtrequire("lib.cpml")
local lume = dtrequire("lib.lume")

local mat4 = cpml.mat4

local transformers = {
    components.Physics,
    components.Position,
}

local TransformSystem = ecs.System:subtype("droptune.systems.Transform")
do
    TransformSystem.active = false

    function TransformSystem:filter(e)
        return true
    end

    function TransformSystem:onAdd(e)
        local fs = lume.chain(transformers)
            :filter(function(c) return e[c] ~= nil end)
            :map(function(c)
                local instance, apply = e[c], c.getTransform
                return function(mat) apply(instance, mat) end
            end)
            :result()

        local finvs = lume.chain(transformers)
            :filter(function(c) return e[c] ~= nil end)
            :map(function(c)
                local instance, apply = e[c], c.getInverseTransform
                return function(mat) apply(instance, mat) end
            end)
            :result()

        local world = self.world

        function e:getTransform(mat)
            mat = mat or mat4.identity()

            for _, f in ipairs(fs) do
                f(mat)
            end

            return mat
        end

        function e:getInverseTransform(mat)
            mat = mat or mat4.identity()

            for _, finv in lume.ripairs(finvs) do
                finv(mat)
            end

            return mat
        end
    end

    TransformSystem.onChange = TransformSystem.onAdd

    function TransformSystem:onRemove(e)
        e.getTransform = nil
    end
end

return TransformSystem