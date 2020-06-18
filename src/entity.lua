local prototype = require("prototype")

local Component = prototype.new("Component")

-- TODO: warn about Component subtyping behavior w.r.t.
-- one-per-type behavior w/ an Entity (subtype considered
-- distinct from supertype)
function Component:subtype(...)
    local subty = prototype.Prototype.subtype(self, ...)

    function subty.filter(system, e)
        return e[subty]
    end

    return subty
end

local Entity = prototype.new()

function Entity:init(...)
    for _, v in ipairs({...}) do
        self:addComponent(v)
    end
end

function Entity:addComponent(component)
    if component:elementOf(Component) then
        self[component:prototype()] = component
        component.entity = self
        return component
    else
        error("not a component!")
    end
end

local e = Entity:new()
local Foo = prototype.new()
local newFoo = Foo:new()
e[Foo] = newFoo
assert(e[Foo] == newFoo)

return {
    Entity = Entity,
    Component = Component,

    -- For convenience w/ unpack
    Entity,
    Component,
}