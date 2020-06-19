local prototype = dtrequire("prototype")

local Component = prototype.new()

-- TODO: warn about Component subtyping behavior w.r.t.
-- one-per-type behavior w/ an Entity (subtype considered
-- distinct from supertype)
function Component:subtype(namestring, shortnamestring)
    if not namestring then
        namestring, shortnamestring = prototype.tryNameFromDebugInfo()
    end

    local subty = prototype.Prototype.subtype(self, namestring, shortnamestring)

    function subty.filter(system, e)
        return e[subty]
    end

    return subty
end

local Entity = prototype.new()

-- function Entity:__newindex()
--     error("entities are not arbitrarily writable - use Entity.addComponent")
-- end

function Entity:init(...)
    for _, v in ipairs({...}) do
        self:addComponent(v)
    end
end

function Entity:addComponent(component)
    if component:elementOf(Component) then
        rawset(self, component:prototype(), component)
        component.entity = self
        return component
    else
        error(string.format("%s is not not a component!", tostring(component)))
    end
end

local function cnext(t, k)
    local v
    repeat
        k, v = next(t, k)
        --print(k, v)
        if Component:isSupertypeOf(k) then
            return k, v
        end
    until not k
end

--- Iterate over all components of an entity.
function Entity:iter()
    return cnext, self, nil
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