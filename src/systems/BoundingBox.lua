local aabb = dtrequire("aabb")
local components = dtrequire("components")
local ecs = dtrequire("ecs")
local lume = dtrequire("lib.lume")

local cpml = dtrequire("lib.cpml")
local vec3, bound3 = cpml.vec3, cpml.bound3

local bounded = {
    components.render.Sprite,
}

local BoundingBoxSystem = ecs.System:subtype("droptune.systems.BoundingBox")
do
    BoundingBoxSystem.active = false

    function BoundingBoxSystem:filter(e)
        return true
    end

    function BoundingBoxSystem:onAdd(e)
        local fs = lume.chain(bounded)
            :filter(function(c) return e[c] ~= nil end)
            :map(function(c)
                local instance, getBoundingBox = e[c], c.getBoundingBox
                return function(bb)
                    return getBoundingBox(instance, bb)
                end
            end)
            :result()

        local world = self.world

        function e:getBoundingBox(bb)
            if #fs == 0 and not bb then
                return bound3.new(vec3(-8, -8), vec3(8, 8))
            end

            for _, f in ipairs(fs) do
                bb = f(bb)
            end

            return bb
        end
    end

    BoundingBoxSystem.onChange = BoundingBoxSystem.onAdd

    function BoundingBoxSystem:onRemove(e)
        e.getBoundingBox = nil
    end
end

return BoundingBoxSystem