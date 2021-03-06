local lume = dtrequire("lib.lume")
local prototype = dtrequire("prototype")
local resource = dtrequire("resource")
local tiny = dtrequire("lib.tiny")

local ecs = {}

local cpml = dtrequire("lib.cpml")
local mat4, vec3 = cpml.mat4, cpml.vec3

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

    function Component.get(name)
        return assert(nameToComponent[name], "no such component " .. name .. "!")
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
    function Entity:init(components)
        if components then
            for k, v in pairs(components) do
                if type(k) == "number" then
                    self:addComponent(v)
                else
                    self:addComponent(k, v)
                end
            end
        end
    end

    function Entity:addComponent(...)
        local component, instance
        if select("#", ...) == 1 then
            instance = ...
            component = prototype.of(instance)
        elseif select('#', ...) == 2 then
            component, instance = ...
        end

        if prototype.subtypes(component, Component) then
            rawset(self, component, instance)
            return instance
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

local System = prototype.new()
ecs.System = System
do
    function System:_tinyInit()
        tiny.system(self)
    end

    function System:init()
        self.children = {}
        self:_tinyInit()
    end

    function System:setParent(parent)
        self.parent = parent
    end
end

local ProcessingSystem = System:subtype()
ecs.ProcessingSystem = ProcessingSystem
do
    function ProcessingSystem:_tinyInit()
        tiny.processingSystem(self)
    end
end

local World = prototype.new(getmetatable(tiny.world()))
ecs.World = World
do
    function World:init(...)
        -- The following entries are copied from tiny.lua.
        -- If we don't do this, we end up with a single globally
        -- shared copy of each of these tables among all Worlds.
        self.entitiesToRemove = {}
        self.entitiesToChange = {}
        self.systemsToAdd = {}
        self.systemsToRemove = {}
        self.entities = {}
        self.systems = {}

        self.pipeline = dtrequire("systems.render.Pipeline"):new()

        self:addDefaultSystems()
        self:add(...)
        self:refresh()

        self.isRendering = false
    end

    function World:addDefaultSystems()
        self:addSystem(dtrequire("systems.Agent"):new())
        self:addSystem(dtrequire("systems.Physics"):new())
        self:addSystem(dtrequire("systems.Transform"):new())
        self:addSystem(dtrequire("systems.BoundingBox"):new())
        self:refresh()
    end

    function World:getPipeline()
        return self.pipeline
    end

    function World:setPipeline(pipeline)
        self.pipeline = pipeline or dtrequire("systems.render.Pipeline"):new()
    end

    function World:getRenderer()
        return self.renderer
    end

    function World:setRenderer(newrenderer)
        if self.renderer then
            self:removeSystem(self.renderer)
        end

        if newrenderer then
            assert(prototype.is(newrenderer, dtrequire("systems.render.Renderer")))
            self.renderer = newrenderer
            self:addSystem(newrenderer)
        end
    end

    function World:draw(pipeline)
        if self.renderer then
            self.renderer:draw(pipeline or self.pipeline)
        end
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
            elseif vec3.is_vec3(value) then
                w(string.format("vec3(%f, %f, %f)", value.x, value.y, value.z))
            else
                print("warning: skipping serialization of ", type(value), " (serializing as nil)")
                w(tostring(nil))
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
            local component = assert(nameToComponent[name], name)
            local serde = Serde[component]
            if serde then
                local obj = serde.deserialize(world)
                local visitor = Visitor[prototype.of(obj)]
                local entry, finish = visitor.entry, visitor.finish
                for k, v in pairs(serialized) do entry(obj, k, v) end
                for i, v in ipairs(serialized) do entry(obj, i, v) end
                e:addComponent(component, finish(obj))
            elseif type(serialized) == "table" then
                local instance = component:new()
                for k, v in pairs(serialized) do instance[k] = v end
                for i, v in ipairs(serialized) do instance[i] = v end
                e:addComponent(component, instance)
            else
                e:addComponent(component, serialized)
            end
        end

        return world:addEntity(e)
    end

    function World:makeLoadEnv()
        local entities, env = {}

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
                return reconstruct(self, e, components)
            end
        end

        local function instance(id, ...)
            local res = resource.get(id)
            if not res then
                error("resource " .. tostring(id) .. " not found!")
            end
            return self:instantiate(res, env, ...)
        end

        local function yieldor(...)
            local args = {...}
            return function(...)
                if coroutine.running() then
                    return coroutine.yield(unpack(args))
                else
                    return ...
                end
            end
        end

        env = {
            entity = entity,
            entityid = entityid,
            instance = instance,
            yieldor = yieldor,

            Entity = Entity,
            Component = Component,

            print = print,
            error = error,
            assert = assert,
            pairs = pairs,
            ipairs = ipairs,
            next = next,
            type = type,
            unpack = unpack,
            select = select,

            mouse = lume.clone(love.mouse),
            keyboard = lume.clone(love.keyboard),
            coroutine = lume.clone(coroutine),
            math = lume.merge(math, love.math),
            table = lume.clone(table),

            vec3 = cpml.vec3.new,
            mat4 = cpml.mat4.new,
            bound3 = cpml.bound3.new,
        }

        return env
    end

    function World:instantiate(serialized, env, ...)
        local f
        if type(serialized) == "string" then
            local ok, loaded = loadstring(serialized)
            if not ok then
                error(loaded)
            end

            f = ok
        elseif type(serialized) == "function" then
            f = serialized
        else
            error("expected string or function")
        end

        local env = lume.merge(self:makeLoadEnv(), env or {})
        local ok, result = xpcall(setfenv(f, env), debug.traceback, ...)
        if not ok then
            error(result)
        end

        return result
    end

    function World:coinstantiate(serialized, env)
        local f
        if type(serialized) == "string" then
            local ok, loaded = loadstring(serialized)
            if not ok then
                error(loaded)
            end

            f = ok
        elseif type(serialized) == "function" then
            f = serialized
        else
            error("expected string or function")
        end

        local env = lume.merge(self:makeLoadEnv(), env or {})
        return coroutine.create(setfenv(f, env))
    end

    function World:deserializeEntities(serialized, ...)
        return self:instantiate(serialized, nil, ...)
    end

    function World:saveToFile(filename)
        local serialized = ""
        self:serializeEntities(function(data)
            serialized = serialized .. data
        end)

        local file = assert(love.filesystem.newFile(filename, "w"))
        assert(file:write(serialized))
        assert(file:flush())
        assert(file:close())
    end
end

-- Convenient shorthand for importing the two most frequently used types.
function ecs.common()
    return Entity, Component
end

return ecs