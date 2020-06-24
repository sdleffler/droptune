local dt = require "src"

local serialized
do
    local Entity, Component = dt.ecs.common()
    local NameComponent = dt.components.NameComponent
    local PhysicsComponent = dt.components.PhysicsComponent

    local world = dt.ecs.World:new(dt.systems.PhysicsSystem:new())
    world:refresh()

    world:addEntity(Entity:new(NameComponent:new("Foo")))
    
    local e = world:addEntity(Entity:new(NameComponent:new("Bar"), PhysicsComponent:new(world)))
    love.physics.newFixture(
        e[PhysicsComponent].body,
        love.physics.newRectangleShape(32, 32)
    )
    
    world:refresh()

    serialized = ""
    local ok, err = xpcall(function()
        world:serializeEntities(function(s) serialized = serialized .. s end)
    end, debug.traceback)

    print(serialized)

    if not ok then
        error("serialized failed with:\n" .. err)
    end
end

do
    local world = dt.ecs.World:new(dt.systems.PhysicsSystem:new())
    world:refresh()

    world:deserializeEntities(serialized)
    world:refresh()
end

function love.load(args)
    logger = dt.log.Logger:new({ minimum = "warn" })
    scenestack = dt.scene.SceneStack:new()
    scenestack:push(dt.editor.EditorScene:new())
end

function love.update(dt)
    logger:push("info", "lol")
    scenestack:message("update", dt)
end

function love.draw()
    scenestack:message("draw", dt)
end