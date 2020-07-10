local aabb = dtrequire("aabb")
local components = dtrequire("components")
local ecs = dtrequire("ecs")
local lume = dtrequire("lib.lume")

local cpml = dtrequire("lib.cpml")
local vec3, bound3, mat4 = cpml.vec3, cpml.bound3, cpml.mat4

local bounded = {
    components.render.Sprite,
}

local BoundingBoxSystem = ecs.System:subtype("droptune.systems.BoundingBox")
do
    BoundingBoxSystem.active = false

    function BoundingBoxSystem.registerBoundedComponent(component)
        table.insert(bounded, component)
    end

    function BoundingBoxSystem:filter(e)
        return true
    end

    function BoundingBoxSystem:onAdd(e)
        local fs = lume.chain(bounded)
            :filter(function(c) return e[c] ~= nil end)
            :map(function(c)
                local instance, getLocalBoundingBox = e[c], c.getLocalBoundingBox
                return function(bb)
                    return getLocalBoundingBox(instance, bb)
                end
            end)
            :result()

        local world = self.world

        function e:getLocalBoundingBox(bb)
            if #fs == 0 and not bb then
                return bound3.new(vec3(-8, -8, 0), vec3(8, 8, 0))
            end

            for _, f in ipairs(fs) do
                bb = f(bb)
            end

            return bb
        end

        local tmp = mat4()
        function e:getWorldBoundingBox(mat)
            local m = mat or tmp:identity()
            local obb = e:getLocalBoundingBox()
            e:getTransform(m)

            return bound3.at(m * obb.min)
                :extend(m * vec3(obb.min.x, obb.min.y, obb.max.z))
                :extend(m * vec3(obb.min.x, obb.max.y, obb.min.z))
                :extend(m * vec3(obb.min.x, obb.max.y, obb.max.z))
                :extend(m * vec3(obb.max.x, obb.min.y, obb.min.z))
                :extend(m * vec3(obb.max.x, obb.min.y, obb.max.z))
                :extend(m * vec3(obb.max.x, obb.max.y, obb.min.z))
                :extend(m * obb.max)
        end
    end

    BoundingBoxSystem.onChange = BoundingBoxSystem.onAdd
end

return BoundingBoxSystem