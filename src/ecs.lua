local prototype = dtrequire("prototype")
local tiny = dtrequire("lib.tiny")

local ecs = {}

local Visitor = prototype.newInterface {
    entry = function(self, k, v, default) end,

    -- returns a result
    finish = function(self) end,
}

local Serde = prototype.newInterface {
    -- function visitor(k, v, default)
    serialize = function(visitor) end,

    -- returns a type implementing Visitor
    deserialize = function(world) end,
}

ecs.Visitor = Visitor
ecs.Serde = Serde

local nameToComponent = {}
local componentToName = {}

local Component = prototype.new()
ecs.Component = Component
do
    local function registerComponent(component, name)
        nameToComponent[name] = component
        componentToName[component] = name
    end

    -- TODO: warn about Component subtyping behavior w.r.t.
    -- one-per-type behavior w/ an Entity (subtype considered
    -- distinct from supertype)
    function Component:subtype(table, namestring, shortnamestring)
        if not namestring then
            namestring, shortnamestring = prototype.tryNameFromDebugInfo()
        elseif not shortnamestring then
            shortnamestring = namestring
        end

        local subty = prototype.rawsubtype(self, table, namestring, shortnamestring)
        registerComponent(subty, namestring)

        function subty.filter(system, e)
            return e[subty] ~= nil
        end

        return subty
    end
end

local Entity = prototype.new()
ecs.Entity = Entity
do
    function Entity:init(...)
        for _, v in ipairs({...}) do
            self:addComponent(v)
        end
    end

    function Entity:addComponent(component)
        if component:elementOf(Component) then
            rawset(self, prototype.of(component), component)
            return component
        else
            error(string.format("%s is not not a component!", tostring(component)))
        end
    end

    local function cnext(t, k)
        local v
        repeat
            k, v = next(t, k)
            if Component:isSupertypeOf(k) then
                return k, v
            end
        until not k
    end

    --- Iterate over all components of an entity.
    function Entity:iter()
        return cnext, self, nil
    end
end

local World = prototype.new(tiny.world())
ecs.World = World
do
    function World:init(...)
        self:add(...)
        self:refresh()
    end

    function World:serializeEntities(write)
        local w = write

        local index = {}
        for i, entity in ipairs(self.entities) do
            index[entity] = i
        end

        local indents = 0
        local wentry, wkey, wval, wtable, windents

        function windents()
            w(("    "):rep(indents))
        end

        function wtable(t)
            w("{\n")

            indents = indents + 1
            local serde = Serde[prototype.of(t)]
            if serde then
                serde.serialize(t, wentry)
            elseif type(t) == "function" then
                t(wentry)
            else
                for k, v in next, t, nil do
                    wentry(k, v, false, next(t, k) == nil)
                end

                for i, v in ipairs(t) do
                    wentry(i, v, false)
                end
            end
            indents = indents - 1

            windents()
            w("}")
        end

        function wkey(value)
            if type(value) == "nil" or type(value) == "number" or type(value) == "boolean" then
                w(string.format("[%d]", value))
            elseif type(value) == "string" then
                w(string.format("[%q]", value))
            elseif index[value] then
                w(string.format("[entityid(%d)]", index[value]))
            elseif type(value) == "table" or type(value) == "function" then
                w("[")
                wtable(value)
                w("]")
            else
                error(type(value))
            end
        end

        function wval(value)
            if type(value) == "nil" or type(value) == "number" or type(value) == "boolean" then
                w(tostring(value))
            elseif type(value) == "string" then
                w(string.format("%q", value))
            elseif index[value] then
                w(string.format("entityid(%d)", index[value]))
            elseif type(value) == "table" or type(value) == "function" then
                wtable(value)
            else
                error(type(value))
            end
        end

        function wentry(k, v, default, semi)
            if not default then
                windents()
                wkey(k)
                w(" = ")
                wval(v)
                if semi then
                    w(";\n")
                else
                    w(",\n")
                end
            end
        end

        for i, entity in ipairs(self.entities) do
            w(string.format("entity(%d) ", i))

            if prototype.is(entity, Entity) then
                indents = indents + 1
                w("{\n")
                for component, instance in entity:iter() do
                    wentry(componentToName[component], instance, false)
                end
                w("}\n")
                indents = indents - 1
            else
                wtable(entity)
            end
        end
    end

    local function reconstruct(world, e, components)
        for name, serialized in pairs(components) do
            local component = nameToComponent[name]
            local serde = Serde[component]
            if serde then
                local obj = serde.deserialize(world)
                local visitor = Visitor[prototype.of(obj)]
                local entry, finish = visitor.entry, visitor.finish
                for k, v in pairs(serialized) do entry(obj, k, v) end
                for i, v in ipairs(serialized) do entry(obj, i, v) end
                e:addComponent(finish(obj))
            else
                local instance = component:new()
                for k, v in pairs(serialized) do instance[k] = v end
                for i, v in ipairs(serialized) do instance[i] = v end
                e:addComponent(instance)
            end
        end

        world:addEntity(e)
    end

    function World:deserializeEntities(serialized)
        local entities = {}

        local function entityid(index)
            local e = entities[index]
            if not e then
                e = Entity:new()
                entities[index] = e
            end

            return e
        end

        local function entity(index)
            local e = entityid(index)
            local self = self

            return function(components)
                reconstruct(self, e, components)
            end
        end

        local env = {
            entity = entity,
            entityid = entityid,
        }

        local ok, loaded = loadstring(serialized)
        if not ok then
            error(loaded)
        end

        local ok, result = xpcall(setfenv(ok, env), debug.traceback)
        if not ok then
            error(result)
        end
    end
end

-- Convenient shorthand for importing the two most frequently used types.
function ecs.common()
    return Entity, Component
end

return ecs